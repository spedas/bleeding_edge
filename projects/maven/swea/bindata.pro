;+
;PROCEDURE:   bindata
;PURPOSE:
;  Bins a 2D data set and calculates moments for each bin.  The calculated
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
;  bindata, x, y
;INPUTS:
;       x:         The independent variable.
;
;       y:         The dependent variable.
;
;KEYWORDS:
;       XBINS:     The number of bins to divide x into.  Takes precedence
;                  over the DX keyword.
;
;       DX:        The bin size.
;
;       XRANGE:    The range for creating bins.  Default is [min(x),max(x)].
;
;       RESULT:    A structure containing the moments, median, and the number
;                  of points per bin.
;
;       DST:       Stores the distribution for each bin.  Can take a lot of
;                  space but allows detailed inspection of statistics.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-07-29 14:10:44 -0700 (Thu, 29 Jul 2021) $
; $LastChangedRevision: 30158 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/bindata.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro bindata, x, y, xbins=xbins, dx=dx, xrange=xrange, result=result, dst=dst

  dodist = keyword_set(dst)

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
  y_npts = lonarr(xbins)

  if (dodist) then begin
    for j=0,(xbins-1) do begin
      i = where(x ge xx[j] and x lt xx[j+1], count)
      y_npts[j] = count
    endfor
    nmax = max(y_npts)
    y_dist = replicate(!values.f_nan, xbins, nmax)
  endif

  for j=0,(xbins-1) do begin
    i = where(x ge xx[j] and x lt xx[j+1], count)
    y_npts[j] = count
    case (count) of
      0 :  ; do nothing -> leave everything as NaN
      1 :    y_mean[j] = y[i]
      else : begin
               mom = moment(y[i], mdev=mdev, /nan)
               y_mean[j] = mom[0]
               y_sdev[j] = sqrt(mom[1])
               y_adev[j] = mdev
               y_skew[j] = mom[2]
               y_kurt[j] = mom[3]
               y_medn[j] = median(y[i])
               if (dodist) then y_dist[j,0L:(count-1L)] = y[i]
             end
    endcase
  endfor

  result = {x:x_a, y:y_mean, sdev:y_sdev, adev:y_adev, $
            skew:y_skew, kurt:y_kurt, med:y_medn, npts:y_npts}

  if (dodist) then str_element, result, 'dist', y_dist, /add

  return

end
