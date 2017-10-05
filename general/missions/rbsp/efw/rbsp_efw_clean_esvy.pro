;+
; NAME:
;   rbsp_efw_clean_esvy (procedure)
;
; PURPOSE:
;   Clean the axial component of EFW esvy data type.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_efw_clean_esvy, tvar, newname = newname, $
;     notch = notch, phase_tolerance = phase_tol, $
;     ind_spike = ind_spike, threshold = thres, $
;     sc = sc, tper = tper, tphase = tphase
;
; ARGUMENTS:
;   tvar: (In, required) Tplot name of esvy data.
;
; KEYWORDS:
;   newname: (In, optional) Tplot name for cleaned data. Default is something
;         like 'rbspa_esvy_clean'.
;   notch: (In, optional) Number of data points to be notched. Default = 43.
;   phase_tolerance: (In, optional) Spin phase tolerance for locating spikes in
;         the axial component. Default = 5 (degree)
;   ind_spike: (Out, optional) A named variable to return the found spikes to.
;   threhold: (In, optional) Threshold for finding extrema when locating spikes.
;         Default = 1.
;   sc: (In, optional) Spacecraft name. Default = strmid(tvar, 4, 1)
;   tper: (In, optional) Tplot name of spin period data. Default is something
;         like 'rbspa_spinper'.
;   tphase: (In, optional) Tplot name of spin phase data. Default is something
;         like 'rbspa_spinphase'.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-10-12: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-12: Initial release in TDAS. JBT, SSL/UCB.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-12 14:34:49 -0800 (Mon, 12 Nov 2012) $
; $LastChangedRevision: 11226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_clean_esvy.pro $
;
;-

pro rbsp_efw_clean_esvy, tvar, newname = newname, $
  notch = notch, phase_tolerance = phase_tol, $
  ind_spike = ind_spike, threshold = thres, $
  sc = sc, tper = tper, tphase = tphase

compile_opt idl2

if n_elements(notch) ne 1 then notch = 43
if n_elements(newname) ne 1 then $
  newname = strmid(tvar, 0, 6) + 'esvy_clean'

get_data, tvar, data = data, dlim = dlim, lim = lim
nt = n_elements(data.x)

v56 = data.y[*,2]
v56 = interp(v56, data.x, data.x, /ignore_nan)

if n_elements(thres) eq 0 then thres = 1d

dprint, 'Finding spikes...'
iex = jbt_extrema(v56, /min, thres = thres)

con1 = intarr(nt)  ; CON for CONdition
con1[iex] = 1

if ~keyword_set(sc) then sc = strmid(tvar, 4, 1)
rbx = 'rbsp' + sc + '_'
; phase = rbsp_interp_spin_phase(sc, data.x, tper = tper, tphase = tphase, $
;   newname = rbx + 'phase')
phase = rbsp_interp_spin_phase(sc, data.x, tper = tper, tphase = tphase)
if n_elements(phase) ne nt then begin
  dprint, 'Spin phase data not available. Abort.'
  return
endif


if n_elements(phase_tol) eq 0 then phase_tol = 5d
ind = where(phase ge 45-phase_tol and phase le 45+phase_tol)
con2 = intarr(nt)
con2[ind] = 1

ind = where(phase ge 225-phase_tol and phase le 225+phase_tol)
con3 = intarr(nt)
con3[ind] = 1

con = con1 *  (con2 + con3)
ind_spike = where(con)

; Account for middle square wave.
dind = ind_spike[1:*] - ind_spike
interval = median(dind)
con_new = [con, intarr(interval)]  ; pad to aviod wrapping in shift
con_new += shift(con_new, interval/2)
con = con_new[0:nt-1]

; Extend spike range
dprint, 'Finding areas to notch...'
con_new = [con, intarr(notch)]
tmp = con_new
for i = 1, notch do begin
  tmp = shift(tmp, 1)
  con_new += tmp
endfor
con = con_new[notch/2:notch/2+nt]
con = con[0:nt-1]

; Notch
ind = where(con)
v56[ind] = !values.f_nan
dprint, 'Notching finished. Storing data...'

; Check
; store_data, rbx + 'v56', data = {x:data.x, y:data.y[*,2]}
; store_data, rbx + 'spike', data = {x:data.x[ind_spike], y:data.y[ind_spike,2]}
; options, rbx + 'spike', psym = 2, colors = [6]
; store_data, rbx + 'spike2', data = rbx + ['v56', 'spike']
; 
; store_data, rbx + 'axb', data = {x:data.x, y:[[data.y[*,2]], [v56]]}
; options, rbx + 'axb', colors = [0, 6]
; tplot, rbx + ['axb', 'spike2', 'phase']

; return

; stop

data.y[*,2] = v56

store_data, newname, data = data, dlim = dlim, lim = lim

end
