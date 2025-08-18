;+
; NAME:
;   rbsp_decimate (procedure)
;
; PURPOSE:
;   Decimate a tplot variable. Be default, the routine only decimate the input
;   data by one level, i.e., sample rate reduced by half.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_decimate, tvar, upper = upper, level = level, newname = newname
;
; ARGUMENTS:
;   tvar: (In, required) Tplot variable to be decimated.
;
; KEYWORDS:
;   upper: (In, optional) If set, the output data's sample rate is no higher
;         than the value of upper.
;   level: (In, optional) Decimation level. Default = 1.
;   newname: (In, optional) A tplot name for the output data. Default = tvar.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-11-03: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-05: Initial release to TDAS. JBT, SSL/UCB.
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2015-09-28 13:02:01 -0700 (Mon, 28 Sep 2015) $
; $LastChangedRevision: 18950 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/rbsp_decimate.pro $
;
;-

pro rbsp_decimate_guts, tarr, Ex, level, newt, newEx
  compile_opt idl2, hidden

  ; Clean time stamp
  dt = median(tarr[1:*] - tarr)
  ;; srate = round(1d / dt)
  srate = 1d / dt
  dt = 1d / srate
  nt = n_elements(tarr)
  t = tarr[0] + dindgen(nt) * dt
;   y = interpol(Ex, tarr, t, /nan)
  y = interp(Ex, tarr, t, /ignore_nan)


  nfilt = 20.
;  nfilt = 10.

  filter = digital_filter(0d, 0.5d, 50, nfilt, /double)
  for i = 1, level do begin
     y = convol(y, filter, /edge_truncate)
     y = y[0:*:2]
     t = t[0:*:2]
  endfor
  newt = t
  newEx = y
end

;-------------------------------------------------------------------------------
pro rbsp_decimate, tvar, upper = upper, level = level, newname = newname

; Level 1 means decimate once, level 2 twice, etc.
; upper indicates the sample rate that the output signal should not exceed.

compile_opt idl2

if n_elements(level) eq 0 then level = 1
if ~keyword_set(newname) then newname = tvar

get_data, tvar, data = d, dl = dl, lim =lim
dt = median(d.x[1:*] - d.x)
srate = 1d / dt
dim = size(d.y, /dim)
if n_elements(dim) gt 1 then ncomp = dim[1] else ncomp = 1
tmin = min(d.x)
tmax = max(d.x)

if keyword_set(upper) then level = round(alog(srate/upper) / alog(2d))

rbsp_btrange, tvar, nb = nb, btr = btr, tind = tind;, tlen = tlen

newx = dblarr(1)
newx[0] = !values.d_nan
newy = dblarr(1, ncomp)
newy[0,*] = !values.d_nan


for ib = 0L, nb-1 do begin
;   print, 'ib = ', ib
  ista = tind[ib, 0]
  iend = tind[ib, 1]
  tarr = d.x[ista:iend]
  nt = n_elements(tarr)
  tmpy = dblarr(nt, ncomp)

;stop
  for ic = 0, ncomp - 1 do begin
;     t0 = systime(/sec)
    Ex = d.y[ista:iend, ic]
    rbsp_decimate_guts, tarr, Ex, level, newt, newEx
    nt2 = n_elements(newt)
    tmpy[0:nt2-1, ic] = newEx
;     print, 'time for component ', ic, ' is: ', systime(/sec) - t0
  endfor
  newx = [newx, newt]
  newy = [newy, tmpy[0:nt2-1,*]]
endfor
newx = newx[1:*]
newy = newy[1:*, *]

ind = where(newx ge tmin and newx le tmax)
newx = newx[ind]
newy = newy[ind, *]

store_data, newname, data ={x:newx, y:newy}, dl = dl, lim = lim

end
