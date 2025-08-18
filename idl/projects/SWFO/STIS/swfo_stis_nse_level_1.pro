;+
;  FUNCTION swfo_stis_nse_level_1
;  
;  PURPOSE:
; Input:
;   strcts: structure(s) containing:
;    -noise_res or noise_bits (AKA nse_noise_bits)
;    -histogram (AKA nse_histogram):
;       60 x N_time array containing counts
;       read out from noise measurement in 10 bins
;       for 6 detectors.
; Output:
;   output: structure with renamed tag 
;KEYWORDS:
;  from_l0b: If set, will use nse_noise_bits and nse_histogram
;            from structure.
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-27 18:12:48 -0700 (Thu, 27 Mar 2025) $
; $LastChangedRevision: 33207 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_nse_level_1.pro $

function swfo_stis_nse_level_1,strcts,format=format, from_l0b=from_l0b


  output = !null
  nd = n_elements(strcts)
  for i=0l,nd-1 do begin
    str = strcts[i]

    if keyword_set(from_l0b) then ddata = str.nse_histogram else ddata = str.histogram
    p= replicate(swfo_stis_nse_find_peak(),6)

    if keyword_set(from_l0b) then begin
      noise_res=ishft(str.nse_noise_bits,-8) and 7u
    endif else noise_res = str.noise_res
    noise_scale = 2.^(fix(noise_res) - 3)
    ;printdat,str
    ;printdat,noise_scale

    x = (findgen(10)-4.5) * noise_scale
    d = reform(ddata,10,6)
    for j=0,5 do begin
      ;p[j] = swfo_stis_nse_find_peak(d[*,j],x)
        p[j] = swfo_stis_nse_find_peak(d[0:8,j],x[0:8])   ; ignore end channel
    endfor

    ; Unused mapid:
    ; dprint,dlevel=4,p.s
    ; mapid = 3
    ; str_element,str,'mapid',mapid

    if keyword_set(from_l0b) then begin
      ; Return prepended columns:
      noise = { $
        noise_res:noise_res,  $
        noise_total:p.a  ,            $
        noise_baseline:p.x0  ,  $
        noise_sigma:p.s}
    endif else begin
      noise = {  $
        time: str.time, $
        ;met: str.met, $
        ;tdiff: str.time_diff, $
        duration: str.duration, $
        ;ccode:ccode,  $
        ;mapid:mapid,  $
        noise_period:str.noise_period,  $
        noise_res:str.noise_res,  $
        total:p.a  ,            $
        baseline:p.x0  ,  $
        sigma:p.s,  $
        ;data:d, $
        ;cfactor:cfactor, $
        valid:1 , $
        gap: str.gap  }
    endelse

    if nd eq 1 then   return, noise
    if i  eq 0 then   output = replicate(noise,nd) else output[i] = noise

  endfor

  return,output
end
