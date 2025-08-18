;+
;PROCEDURE:   bindata
;PURPOSE:
;  Bins a 2D data set and calculates moments for each bin: mean, standard 
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
;  bindata, x, y
;INPUTS:
;       x:         The independent variable.
;
;       y:         The dependent variable.  If any elements of y are not
;                  finite, they are treated as missing data.  They are
;                  not included when calculating statistics, and they are
;                  not included in the distribution (see keyword DST below).
;
;KEYWORDS:
;       XBINS:     The number of bins to divide x into.  Takes precedence
;                  over the DX keyword.
;
;       DX:        The bin size.
;
;       XRANGE:    The range for creating bins.  Default is [min(x),max(x)].
;
;       RESULT:    A structure containing the moments, median, quartiles, 
;                  minimum, maximum, and the number of points per bin.
;
;       DST:       Stores the distribution for each bin.  Can take a lot of
;                  space but allows detailed inspection of statistics.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-07-31 15:56:27 -0700 (Thu, 31 Jul 2025) $
; $LastChangedRevision: 33517 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/bindata.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro bindata, x, y, xbins=xbins, dx=dx, xrange=xrange, result=result, dst=dst

  dodist = keyword_set(dst)
  ygud = finite(y)

; Set up the grid for binning the data

  if not keyword_set(xrange) then xrange = minmax(x)
  xmin = min(xrange, max=xmax)

  if keyword_set(xbins) then dx = (xmax - xmin)/float(xbins) $
                        else xbins = round((xmax - xmin)/dx)

  xx = dx*findgen(xbins + 1) + xmin

; Make arrays to hold the result

  x_a = ((xx + shift(xx,-1))/2.)[0:(xbins-1)]
  y_mean = replicate(!values.f_nan, xbins)
  y_sdev = y_mean
  y_adev = y_mean
  y_skew = y_mean
  y_kurt = y_mean
  y_medn = y_mean
  y_lqrt = y_mean
  y_uqrt = y_mean
  y_min  = y_mean
  y_max  = y_mean
  y_npts = lonarr(xbins)

  if (dodist) then begin
    for j=0,(xbins-1) do begin
      i = where(x ge xx[j] and x lt xx[j+1] and ygud, count)
      y_npts[j] = count
    endfor
    nmax = max(y_npts)
    y_dist = replicate(!values.f_nan, xbins, nmax)
  endif

  for j=0,(xbins-1) do begin
    i = where(x ge xx[j] and x lt xx[j+1] and ygud, count)
    y_npts[j] = count
    case (1) of
      count eq 0 : ; do nothing -> leave everything as NaN
      count eq 1 : begin
                     y_mean[j] = y[i]

                     y_min[j]  = y[i]
                     y_medn[j] = y[i]
                     y_max[j]  = y[i]
                     if (dodist) then y_dist[j,0L] = y[i]
                   end
      count lt 5 : begin
                     mom = moment(y[i], mdev=mdev)
                     y_mean[j] = mom[0]
                     y_sdev[j] = sqrt(mom[1])
                     y_adev[j] = mdev
                     y_skew[j] = mom[2]
                     y_kurt[j] = mom[3]

                     y_min[j]  = min(y[i], max=ymax)
                     y_medn[j] = median(y[i])
                     y_max[j]  = ymax
                     if (dodist) then y_dist[j,0L:(count-1L)] = y[i]
                   end
      else : begin
               mom = moment(y[i], mdev=mdev)
               y_mean[j] = mom[0]
               y_sdev[j] = sqrt(mom[1])
               y_adev[j] = mdev
               y_skew[j] = mom[2]
               y_kurt[j] = mom[3]

               med = createboxplotdata(y[i])
               y_min[j]  = med[0]
               y_lqrt[j] = med[1]
               y_medn[j] = med[2]
               y_uqrt[j] = med[3]
               y_max[j]  = med[4]
               if (dodist) then y_dist[j,0L:(count-1L)] = y[i]
             end
    endcase
  endfor

  result = { x    : x_a    , $   ; bin center locations in x
             y    : y_mean , $   ; mean value
             sdev : y_sdev , $   ; standard deviation
             adev : y_adev , $   ; absolute deviation
             skew : y_skew , $   ; skewness
             kurt : y_kurt , $   ; kurtosis
             med  : y_medn , $   ; median
             lqrt : y_lqrt , $   ; lower quartile
             uqrt : y_uqrt , $   ; upper quartile
             min  : y_min  , $   ; minimum
             max  : y_max  , $   ; maximum
             dx   : dx     , $   ; bin size in x
             npts : y_npts    }  ; number of values in each bin

  if (dodist) then str_element, result, 'dist', y_dist, /add

  return

end
