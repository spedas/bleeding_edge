;+
;PROCEDURE:   bindata2d
;PURPOSE:
;  Bins a 3D data set and calculate moments for each bin.  The calculated
;  moments are: mean, standard deviation, skewness, kurtosis, mean absolute
;  deviation, and median.
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
;       x:         The first independent variable.
;
;       y:         The second independent variable.
;
;       z:         The dependent variable (2D array).
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
;       RESULT:    A structure containing the moments, median, and the number
;                  of points per bin.
;
;       DST:       Stores the distribution for each bin.  Can take a lot of
;                  space.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-07-29 14:10:44 -0700 (Thu, 29 Jul 2021) $
; $LastChangedRevision: 30158 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/bindata2d.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro bindata2d, x, y, z, xbins=xbins, dx=dx, xrange=xrange, ybins=ybins, $
                      dy=dy, yrange=yrange, result=result, dst=dst

  dodist = keyword_set(dst)

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
  z_npts = lonarr(xbins,ybins)

  if (dodist) then begin
    for j=0,(xbins-1) do begin
      for k=0,(ybins-1) do begin
        i = where(x ge xx[j] and x lt xx[j+1] and y ge yy[k] and y lt yy[k+1], count)
        z_npts[j,k] = count
      endfor
    endfor
    nmax = max(z_npts)
    z_dist = replicate(!values.f_nan, xbins, ybins, nmax)
  endif

; Calculate the moments

  for j=0,(xbins-1) do begin
    for k=0,(ybins-1) do begin
      i = where(x ge xx[j] and x lt xx[j+1] and y ge yy[k] and y lt yy[k+1], count)
      z_npts[j,k] = count
      case (count) of
        0 :  ; do nothing -> leave everything as NaN
        1 :    z_mean[j,k] = z[i]
        else : begin
                 mom = moment(z[i], mdev=mdev, /nan)
                 z_mean[j,k] = mom[0]
                 z_sdev[j,k] = sqrt(mom[1])
                 z_adev[j,k] = mdev
                 z_skew[j,k] = mom[2]
                 z_kurt[j,k] = mom[3]
                 z_medn[j,k] = median(z[i])
                 if (dodist) then z_dist[j,k,0L:(count-1L)] = z[i]
               end
      endcase
    endfor
  endfor

  result = {x:x_a, y:y_a, z:z_mean, sdev:z_sdev, adev:z_adev, $
            skew:z_skew, kurt:z_kurt, med:z_medn, npts:z_npts}

  if (dodist) then str_element, result, 'dist', z_dist, /add

  return

end
