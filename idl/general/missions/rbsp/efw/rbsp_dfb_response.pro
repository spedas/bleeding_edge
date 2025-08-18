;+
; NAME:
;   rbsp_dfb_response (function)
;
; PURPOSE:
;   Calculate DFB responses at given frequencies. Two modes are suppored. If the
;   sample rate keyword, SAMPLE_RATE, is specified, it will calculate the
;   response of the low-pass output from DFB. If the the filter bank level
;   keyword, FBK_LEVEL, is specified, it will calculate the response of the
;   corresponding filter bank level. 
;
;   Warning: If both keywords are set, FBK_LEVEL is ignored. If neither is set,
;            a NaN will be returned.
;
;   Filter bank level look-up table:
;       Frequency range in Hz  |  Level
;           8192 - 4096        |    1
;           4096 - 2048        |    2
;           2048 - 1024        |    3
;           1024 -  512        |    4
;            512 -  256        |    5
;            256 -  128        |    6
;            128 -   64        |    7
;             64 -   32        |    8
;             32 -   16        |    9
;             16 -    8        |    10
;              8 -    4        |    11
;              4 -    2        |    12
;              2 -    1        |    13
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = rbsp_dfb_response(f, sample_rate = sample_rate, $
;                        fbk_level = fbk_level)
;
; ARGUMENTS:
;   f: (Input, required) A floating array of frequencies at which the responses
;           are calculated.
;
; KEYWORDS:
;   sample_rate: (Input, optional) See PURPOSE.
;   fbk_level: (Input, optional) See PURPOSE.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-08: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; Version:
;
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-09-06 11:42:13 -0700 (Thu, 06 Sep 2012) $
; $LastChangedRevision: 10895 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_dfb_response.pro $
;-


; rbsp_DFB_FIR_transfer uses Cully's code wrote for THEMIS.
function rbsp_DFB_FIR_transfer,omega, noavg = noavg
  compile_opt idl2, hidden

  ; Calculate transfer function of filter 1
  ; with coefficients [-8,0,72,128,72,0,-8]/256
  I = dcomplex(0,1)
  h = (-8)  + $
        72*(cos(2*omega)-I*sin(2*omega)) + $
       128*(cos(3*omega)-I*sin(3*omega)) + $
        72*(cos(4*omega)-I*sin(4*omega)) + $
      (-8)*(cos(6*omega)-I*sin(6*omega))
  h/=256.

  ; Multiply by transfer function of filter 2
  ; with coefficients [1/4, 1/2, 1/4]
  if ~keyword_set(noavg) then begin
      h *= 0.25 + $
            0.5*(cos(  omega)-I*sin( omega)) + $
           0.25*(cos(2*omega)-I*sin(2*omega))
   endif
return,h
end

;------------------------------------------------
; Calculates the transfer function for the DFB filters at a given level
;   Inputs: frequency normalized to sampling Nyquist frequency
;              (i.e. f/4096 or f/8192)
;           filter bank level
;   Output: complex transfer function at given frequencies
;------------------------------------------------
; rbsp_DFB_transfer uses Cully's code wrote for THEMIS.
function rbsp_DFB_transfer,f,level, fbk = fbk
; If fbk set, return filter bank response instead of low-pass filtered signals.
  compile_opt idl2, hidden

  ; Use normalized angular frequency
  omega = f*!dpi
  i_cmplx = dcomplex(0, 1)

  if level eq 0 then return, dcomplexarr(n_elements(f)) + dcomplex(1,0)

  ; For level 1, transfer function is just FIR transfer function
  if level eq 1 and keyword_set(fbk) then begin
    h = exp(-3d*i_cmplx*omega) - rbsp_DFB_FIR_transfer(omega, /noavg)
    return, h
  endif 

  h = rbsp_DFB_FIR_transfer(omega)

  ; For higher levels, multiply by all transfer functions,
  ; making sure to appropiately fold in aliasing
  if ~keyword_set(fbk) then begin
    for i=1,level-1 do h*= rbsp_DFB_FIR_transfer(omega*2^i)
  endif else begin
    for i=1,level-2 do h*= rbsp_DFB_FIR_transfer(omega*2^i)
    h *= exp(-3d*i_cmplx*omega*2^(level-1)) - $
          rbsp_DFB_FIR_transfer(omega*2^(level-1), /noavg)
  endelse

return,h
end

;-------------------------------------------------------------------------------
function rbsp_dfb_response, f, sample_rate = sample_rate, fbk_level = fbk_level
compile_opt idl2

adc_srate = 16384d  ; RBSP ADC sample rate
nyquist = adc_srate * 0.5  ; Highest nyquist from RBSP ADC

if keyword_set(sample_rate) then begin
  print, 'sample rate = ', sample_rate
  level = fix(alog(adc_srate/sample_rate)/alog(2) + 0.4)

  if level lt 0 then begin
    dprint, 'Invalid sample rate. A NaN is returned.'
    return, !values.f_nan
  endif

  resp = rbsp_dfb_transfer(f/nyquist, level)
  return, resp
endif

if keyword_set(fbk_level) then begin
  level = fbk_level
  if level lt 0 then begin
    dprint, 'Invalid filter bank level. A NaN is returned.'
    return, !values.f_nan
  endif

  resp = rbsp_dfb_transfer(f/nyquist, level, /fbk)
  return, resp
endif

dprint, 'Neither sample rate nor FBK level is supplied. A NaN is returned.'
return, !values.f_nan

end

