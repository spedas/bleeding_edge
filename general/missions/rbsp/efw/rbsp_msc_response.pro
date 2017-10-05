;+
; NAME:
;   rbsp_msc_response (function)
;
; PURPOSE:
;   Calculate the transmittance of the search-coil magnetometer.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   response = rbsp_msc_response(f, probe, component)
;
; ARGUMENTS:
;   f: (Input, required) A floating array of frequencies at which the responses
;           are calculated.
;
;   probe: (Input, required) RBSP probe name. It should be 'a' or 'b'.
;
;   component: (Input, required) Component name. Valid names are:
;         'Bu', 'Bv', 'Bw'.
;
; KEYWORDS:
;   None.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-09-04: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; Version:
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2014-02-25 12:02:41 -0800 (Tue, 25 Feb 2014) $
; $LastChangedRevision: 14431 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_msc_response.pro $
;-

;-------------------------------------------------------------------------------
function rbsp_msc_response_phasediff, f, params
compile_opt idl2, hidden

p = params
x = f
scale = p[0]
f0 = dcomplex(p[1])
L = p[2]
power = p[3]
offset = p[4]
const = p[5]

model = scale / (const + ((x - f0) / L)^power) + offset
return, model
end


;-------------------------------------------------------------------------------
; function rbsp_msc_response, f, probe, component, phase_only = phase_only
function rbsp_msc_response, f, probe, component

; valid compoonents: 'Bu', 'Bv', 'Bw'
; valid probes: 'a', 'b'

compile_opt idl2

nf = n_elements(f)
resp = dcomplexarr(nf)

; Parameters for modeling <10 Hz phase difference.
scale = 157.32677d
f0 = 1.9991079d
L = 1.455342d
power = 1.030599d
offset = 1.7069729d
const = 1.6960361d
params = [scale, f0, L, power, offset, const]

I = dcomplex(0, 1)

; Parameters from gain curve fit.
if strcmp(probe, 'a', /fold) and strcmp(component, 'Bu', /fold) then $
  pfit = [311.25643d, 0.88488388d, 14.628155d, 0.93996525d, 0.94158105d, $
    1.0682462d]

if strcmp(probe, 'a', /fold) and strcmp(component, 'Bv', /fold) then $
  pfit = [354.31116d, 0.94341905d, 16.480396d, 0.98034734d, 1.0204213d, $
    1.1179060d]

if strcmp(probe, 'a', /fold) and strcmp(component, 'Bw', /fold) then $
  pfit = [364.76290d, 0.84507290d, 17.129188d, 0.86224392d, 0.89285911d, $
    1.1173237d]

if strcmp(probe, 'b', /fold) and strcmp(component, 'Bu', /fold) then $
  pfit = [263.79074d, 0.80486690d, 12.384525d, 0.94432396d, 0.90910942d, $
    1.0326275d]

if strcmp(probe, 'b', /fold) and strcmp(component, 'Bv', /fold) then $
  pfit = [325.28814d, 0.86382945d, 16.006148d, 0.97501435d, 0.98429503, $
    1.0819645d]

if strcmp(probe, 'b', /fold) and strcmp(component, 'Bw', /fold) then $
  pfit = [302.51760d, 0.79271244d, 15.408950d, 0.85025770d, 0.84073427, $
    1.0783752d]



;Get mu-metal square can conversion factor (nT/V)
x = rbsp_efw_get_gain_results()
freqtmp = x.cal_cit.freq_cit
if probe eq 'a' then begin
	if component eq 'Bu' then valstmp = x.cal_cit.scmu_a_cit.stimcoil_nt2v
	if component eq 'Bv' then valstmp = x.cal_cit.scmv_a_cit.stimcoil_nt2v
	if component eq 'Bw' then valstmp = x.cal_cit.scmw_a_cit.stimcoil_nt2v
endif else begin
	if component eq 'Bu' then valstmp = x.cal_cit.scmu_b_cit.stimcoil_nt2v
	if component eq 'Bv' then valstmp = x.cal_cit.scmv_b_cit.stimcoil_nt2v
	if component eq 'Bw' then valstmp = x.cal_cit.scmw_b_cit.stimcoil_nt2v
endelse


;--------------------------
; Positive frequencies
ind = where(f ge 0, nind)
if nind gt 0 then begin
  tmp_f = f[ind]
  
  ;interpolate nT/V curves to f
  ntv = interpol(valstmp,freqtmp,tmp_f)
  
  
  phasediff = rbsp_msc_response_phasediff(tmp_f, params)
  phasefactor = exp(I * phasediff * !dtor)

  p = pfit
  x = tmp_f
  tmp_resp2 = -p[5] * 1d / (1d + I * (x / p[0])^p[1])  $ ; low-pass
       * I * (x/p[2])^p[3] / (1d + I * (x/p[2])^p[4]) ; highpass
  tmp_resp = tmp_resp2 * phasefactor / ntv
  resp[ind] = tmp_resp
  
endif

;--------------------------
; Negative frequencies
ind = where(f lt 0, nind)
if nind gt 0 then begin
  tmp_f = -f[ind]

  ;interpolate nT/V curves to f
  ntv = interpol(valstmp,freqtmp,abs(tmp_f))


  phasediff = rbsp_msc_response_phasediff(tmp_f, params)
  phasefactor = exp(I * phasediff * !dtor)

  p = pfit
  x = tmp_f
  tmp_resp2 = -p[5] * 1d / (1d + I * (x / p[0])^p[1])  $ ; low-pass
       * I * (x/p[2])^p[3] / (1d + I * (x/p[2])^p[4]) ; highpass
  tmp_resp = tmp_resp2 * phasefactor / ntv
  resp[ind] = conj(tmp_resp)
endif

; if keyword_set(phase_only) then begin
;   phase = atan(resp, /phase)
;   return, exp(I * phase)
; endif else return, resp

return, resp

end

