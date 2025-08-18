;+ THIS MODULE CONTAINS TWO SUBROUTINES
;       pro mygauss() and function brl_find511()
;
;
;  
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; evaluate gaussian + linear model for use with curvefit()
; 
; model is f(x) = a[0]*exp(-((x-a[1])/a[2])^2) + a[3]x + a[4]
;
; INPUT: x is where the model is to be evaluated
;        a is the current list of 5 parameter values; these
;          must be initialized by the caller
;
; OUTPUT: f is evaluated as a linear+gaussian model
;        pder is a list of 5 partial derivatives of f wrt a
;
; WARNING: for speed, no checks for foolish function evaluation
;        requests. Caller is responsible! For instance,
;        if one sets a[2]=0 or (x-a[1])/a[2]=1000 for some x,
;        expect error msgs and/or nonsense output.
;-

pro mygauss, x, a, f, pder

  cnt = n_elements(x)
  z = (x-a[1])/a[2]
  temp = exp(-z*z)
  hold = (a[0]*2./a[2])*temp*z

  f = a[0]*temp + a[3]*x + a[4]
  pder = [[temp], [hold], [hold*z], [x], [fltarr(cnt)+1.]]

end
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;
;+ find the slow spectrum bin value of the 511 line
;
; INPUT: slo list of 256 slow spectrum count rates (counts/second)
;        the slo list should not be normalized by bin widths
;
; OUTPUT: bin value for the 511 peak (usually not an integer)
;         -1 on failure (511 peak not found)
;
; OPTIONS: offset=offset low bdy for 511 search region (default is 100)
;          err=err 1-sigma uncertainties for each slo value;
;                  this should be should be a list of
;                  sqrt(# of counts)/(integration time in seconds)
;
; ACTION: limit the search to a reasonable part of the
;         entire spectrum. Fit a line to the two endpoints
;         of the search region, and subtract off the line.
;         Then find the midpoint position of the list of
;         values exceeding 50% of the max residual. That
;         becomes a start guess for the peak location,
;         modeled by a line+Gaussian. Amplitude and width are
;         hard-coded typical values. Fit model to data and
;         get best fit peak location. If the fit looks good,
;         return its position; else return -1 to signal failure.
;
; HISTORY: first version working 31Dec2012/mm
;
; FUTURE: might need to adjust testing for valid 511 peak
;
; EXAMPLE: peak = brl_find511(spec, offset=95)
;          peak = brl_find511(spec, err=sigmas)
;-

function brl_find511, slow, offset=offset, err=err

if n_elements(slow) ne 256 then return, -1
if (not keyword_set(err)) then err=fltarr(256)+1.
if (not keyword_set(offset)) then offset=100

widths=[intarr(64)+1,intarr(32)+2,intarr(32)+4,intarr(32)+8, $
  intarr(32)+16,intarr(32)+32,intarr(32)+64]
x= [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, $
    11.5, 12.5, 13.5, 14.5, 15.5, 16.5, 17.5, 18.5, 19.5, 20.5, $
    21.5, 22.5, 23.5, 24.5, 25.5, 26.5, 27.5, 28.5, 29.5, 30.5, $
    31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5, 39.5, 40.5, $
    41.5, 42.5, 43.5, 44.5, 45.5, 46.5, 47.5, 48.5, 49.5, 50.5, $
    51.5, 52.5, 53.5, 54.5, 55.5, 56.5, 57.5, 58.5, 59.5, 60.5, $
    61.5, 62.5, 63.5, 65, 67, 69, 71, 73, 75, 77, 79, 81, $
    83, 85, 87, 89, 91, 93, 95, 97, 99, 101, 103, 105, $
    107, 109, 111, 113, 115, 117, 119, 121, 123, 125, $
    127, 130, 134, 138, 142, 146, 150, 154, 158, 162, $
    166, 170, 174, 178, 182, 186, 190, 194, 198, 202, $
    206, 210, 214, 218, 222, 226, 230, 234, 238, 242, $
    246, 250, 254, 260, 268, 276, 284, 292, 300, 308, $
    316, 324, 332, 340, 348, 356, 364, 372, 380, 388, $
    396, 404, 412, 420, 428, 436, 444, 452, 460, 468, $
    476, 484, 492, 500, 508, 520, 536, 552, 568, 584, $
    600, 616, 632, 648, 664, 680, 696, 712, 728, 744, $
    760, 776, 792, 808, 824, 840, 856, 872, 888, 904, $
    920, 936, 952, 968, 984, 1000, 1016, 1040, 1072, 1104, $
    1136, 1168, 1200, 1232, 1264, 1296, 1328, 1360, 1392, $
    1424, 1456, 1488, 1520, 1552, 1584, 1616, 1648, 1680, $
    1712, 1744, 1776, 1808, 1840, 1872, 1904, 1936, 1968, $
    2000, 2032, 2080, 2144, 2208, 2272, 2336, 2400, 2464, $
    2528, 2592, 2656, 2720, 2784, 2848, 2912, 2976, 3040, $
    3104, 3168, 3232, 3296, 3360, 3424, 3488, 3552, 3616, $
    3680, 3744, 3808, 3872, 3936, 4000, 4064] 

; nominal range for 511 line
  width=25
  select=indgen(width)+offset
  y = slow[select]/widths[select]
  x = x[select]
  err = err[select]/widths[select]
  usersym,[-.5,.5,.5,-.5,-.5],[-.5,-.5,.5,.5,-.5],/fill

; describe a line through endpoints of the selected range
  y1 = y[0]
  y2 = y[width-1]
  x1 = x[0]
  x2 = x[width-1]
  m = (y2-y1)/(x2-x1)
  b = y1 - m*x1

;
; find approximate peak location after subtracting linear bkgd
;
  peakregion = y - (m * x + b)
  apex=max(peakregion)
  higharea=where(peakregion gt 0.5*apex,cnt)
  if (cnt lt 2) then return, -1
  peaklocation = x[floor(median(higharea))]

  guess=[1., peaklocation, 10., m, b]
  yfit=curvefit(x,y,1./err^2,guess, $
       chisq=chisq,sigma,function_name='mygauss',status=stat)
  if (guess[2] gt 20 or guess[0] lt 0.2) then return, -1

;  some diagnostics (might need to adjust above tests)
;
;  print,guess
;  plot,x,y,psym=8,yrange=[0,3]
;  oplot,x,yfit
;  oploterr,x,y,err

  return,guess[1]

end
