;+
;PROCEDURE:   bindata2d
;PURPOSE:
;  Bins a 3D data set and calculates moments for each bin: mean, standard 
;  deviation, skewness, kurtosis, and mean absolute deviation.  Also 
;  determines the median, upper quartile, lower quartile, minimum, and 
;  maximum.
;
;    skewness: = 0 -> distribution is symmetric about the maximum
;              < 0 -> distribution is skewed to the left
;              > 0 -> distribution is skewed to the right
;
;    kurtosis: = 0 -> distribution is peaked like a Gaussian
;              < 0 -> distribution is less peaked than a Gaussian
;              > 0 -> distribution is more peaked than a Gaussian
;
;USAGE:
;  bindata2d, x, y, z
;INPUTS:
;       x:         The first independent variable (N-element array).
;
;       y:         The second independent variable (M-element array).
;
;       z:         The dependent variable (N x M array).  If any elements
;                  of z are not finite, they are treated as missing data.
;                  They are not included when calculating statistics, and 
;                  they are not included in the distribution (see keyword 
;                  DST below).
;
;KEYWORDS:
;       XBINS:     The number of bins to divide x into.  Takes precedence
;                  over the DX keyword.
;
;       DX:        The X bin size.
;
;       XRANGE:    The range for creating bins.  Default is [min(x),max(x)].
;
;       YBINS:     The number of bins to divide y into.  Takes precedence
;                  over the DY keyword.
;
;       DY:        The Y bin size.
;
;       YRANGE:    The range for creating bins.  Default is [min(y),max(y)].
;
;       RESULT:    A structure containing the moments, median, quartiles, 
;                  minimum, maximum, and the number of points per bin.
;
;       DST:       Stores the distribution for each bin.  Can take a lot of
;                  space.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-05 08:10:18 -0700 (Thu, 05 Jun 2025) $
; $LastChangedRevision: 33369 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/bindata2d.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro bindata2d, x, y, z, xbins=xbins, dx=dx, xrange=xrange, ybins=ybins, $
                      dy=dy, yrange=yrange, result=result, dst=dst

  dodist = keyword_set(dst)
  zgud = finite(z)

; Set up the grid for binning the data

  if not keyword_set(xrange) then xrange = minmax(x)
  xrange = float(xrange)

  if not keyword_set(yrange) then yrange = minmax(y)
  yrange = float(yrange)

  if keyword_set(xbins) then dx = (xrange[1] - xrange[0])/float(xbins) $
                        else xbins = round((xrange[1] - xrange[0])/dx)

  if keyword_set(ybins) then dy = (yrange[1] - yrange[0])/float(ybins) $
                        else ybins = round((yrange[1] - yrange[0])/dy)

  xx = dx*findgen(xbins + 1) + xrange[0]
  yy = dy*findgen(ybins + 1) + yrange[0]

; Make arrays to hold the result

  x_a = ((xx + shift(xx,-1))/2.)[0:(xbins-1)]
  y_a = ((yy + shift(yy,-1))/2.)[0:(ybins-1)]
  z_mean = replicate(!values.f_nan,xbins,ybins)
  z_sdev = z_mean
  z_adev = z_mean
  z_skew = z_mean
  z_kurt = z_mean
  z_medn = z_mean
  z_lqrt = z_mean
  z_uqrt = z_mean
  z_min  = z_mean
  z_max  = z_mean
  z_npts = lonarr(xbins,ybins)

  if (dodist) then begin
    for j=0,(xbins-1) do begin
      for k=0,(ybins-1) do begin
        i = where(x ge xx[j] and x lt xx[j+1] and y ge yy[k] and y lt yy[k+1] and zgud, count)
        z_npts[j,k] = count
      endfor
    endfor
    nmax = max(z_npts)
    z_dist = replicate(!values.f_nan, xbins, ybins, nmax)
  endif

; Calculate the moments

  for j=0,(xbins-1) do begin
    for k=0,(ybins-1) do begin
      i = where(x ge xx[j] and x lt xx[j+1] and y ge yy[k] and y lt yy[k+1] and zgud, count)
      z_npts[j,k] = count
      case (1) of
        count eq 0 : ; do nothing -> leave everything as NaN
        count eq 1 : begin
                       z_mean[j,k] = z[i]

                       z_min[j,k]  = z[i]
                       z_medn[j,k] = z[i]
                       z_max[j,k]  = z[i]
                       if (dodist) then z_dist[j,k,0L] = z[i]
                     end
        count lt 5 : begin
                       mom = moment(z[i], mdev=mdev)
                       z_mean[j,k] = mom[0]
                       z_sdev[j,k] = sqrt(mom[1])
                       z_adev[j,k] = mdev
                       z_skew[j,k] = mom[2]
                       z_kurt[j,k] = mom[3]

                       z_min[j,k]  = min(z[i], max=zmax)
                       z_medn[j,k] = median(z[i])
                       z_max[j,k]  = zmax
                       if (dodist) then z_dist[j,k,0L:(count-1L)] = z[i]
                     end
        else : begin
                 mom = moment(z[i], mdev=mdev)
                 z_mean[j,k] = mom[0]
                 z_sdev[j,k] = sqrt(mom[1])
                 z_adev[j,k] = mdev
                 z_skew[j,k] = mom[2]
                 z_kurt[j,k] = mom[3]

                 med = createboxplotdata(z[i])
                 z_min[j,k]  = med[0]
                 z_lqrt[j,k] = med[1]
                 z_medn[j,k] = med[2]
                 z_uqrt[j,k] = med[3]
                 z_max[j,k]  = med[4]
                 if (dodist) then z_dist[j,k,0L:(count-1L)] = z[i]
               end
      endcase
    endfor
  endfor

  result = { x    : x_a    , $   ; bin center locations in x
             y    : y_a    , $   ; bin center locations in y
             z    : z_mean , $   ; mean value
             sdev : z_sdev , $   ; standard deviation
             adev : z_adev , $   ; absolute deviation
             skew : z_skew , $   ; skewness
             kurt : z_kurt , $   ; kurtosis
             med  : z_medn , $   ; median
             lqrt : z_lqrt , $   ; lower quartile
             uqrt : z_uqrt , $   ; upper quartile
             min  : z_min  , $   ; minimum
             max  : z_max  , $   ; maximum
             dx   : dx     , $   ; bin size in x
             dy   : dy     , $   ; bin size in y
             npts : z_npts    }  ; number of values in each bin

  if (dodist) then str_element, result, 'dist', z_dist, /add

  return

end
