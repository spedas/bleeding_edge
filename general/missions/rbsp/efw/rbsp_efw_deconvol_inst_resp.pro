;+
; NAME:
;   rbsp_efw_deconvol_inst_resp (function)
;
; PURPOSE:
;   De-convolve instrument responses for RBSP EFW data, including search-coil
;   data that are channeled into EFW. It will return a tplot data structure. 
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = rbsp_efw_deconvol_inst_resp(data, probe, datatype)
;
; ARGUMENTS:
;   data: (Input, required) A tplot data structure, i.e., a structure with the
;         form {x:time_array, y:[nt, 3]}.
;
;   probe: (Input, required) RBSP probe name. It should be 'a' or 'b'.
;
;   datatype: (Input, required) Data type name. Valid names are:
;         'eb2', 'mscb1', 'mscb2'.
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
;   2012-08-23: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2013-06-21: JBT. 
;         1. Added support to eb1.
;         2. Removed hard-wired sample rate.
;	2014-06-01: AWB
;		  Checks to be sure that block length is greater than kernel length
;		  Not doing this can cause blk_con to fail for short bursts. 
;
;
; Version:
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2014-09-17 14:33:45 -0700 (Wed, 17 Sep 2014) $
; $LastChangedRevision: 15817 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_deconvol_inst_resp.pro $
;-


;-------------------------------------------------------------------------------
function rbsp_efw_deconvol_inst_resp_eb2, data, probe, datatype

compile_opt idl2, hidden

; Determine sample rate

tarr = data.x
E = data

dt_arr = tarr[1:*] - tarr
dt = median(dt_arr)
srate = double(round(1d / dt))

; Setup kernel for deconvolving EFI response that includes
;   boom response
;   AC high-pass filter
;   anti-aliasing Bessel filter response
;   ADC interleaving timing
fsample = srate
kernel_length = 1024L
df = fsample / double(kernel_length)
f = dindgen(kernel_length)*df
f[kernel_length/2+1:*] -= double(kernel_length) * df
spb_resp = rbsp_efw_boom_response(f, 'SPB', rsheath = 50d6)
axb_resp = rbsp_efw_boom_response(f, 'AXB', rsheath = 50d6)
hipass_resp = rbsp_ac_highpass_response(f)
bessel_resp = rbsp_anti_aliasing_response(f)
adcresp_12 = rbsp_adc_response(f, 'E12AC')
adcresp_34 = rbsp_adc_response(f, 'E34AC')
adcresp_56 = rbsp_adc_response(f, 'E56AC')
E12_resp = 1d / (spb_resp * hipass_resp * bessel_resp * adcresp_12)
E34_resp = 1d / (spb_resp * hipass_resp * bessel_resp * adcresp_34)
E56_resp = 1d / (axb_resp * hipass_resp * bessel_resp * adcresp_56)



; E12_resp[0] = 0
; E34_resp[0] = 0
; E56_resp[0] = 0

; Remove NaNs.
ind = where(finite(E12_resp, /nan), nind)
if nind gt 0 then E12_resp[ind] = 0

ind = where(finite(E34_resp, /nan), nind)
if nind gt 0 then E34_resp[ind] = 0

ind = where(finite(E56_resp, /nan), nind)
if nind gt 0 then E56_resp[ind] = 0
; Transfer kernel into time domain: take inverse FFT and center
E12_resp = shift((fft(E12_resp,1)), kernel_length/2) / kernel_length
E34_resp = shift((fft(E34_resp,1)), kernel_length/2) / kernel_length
E56_resp = shift((fft(E56_resp,1)), kernel_length/2) / kernel_length

rbsp_btrange, data, tind = tind, nbursts = nbursts, /structure

; START LOOP OVER INDIVIDUAL BURSTS
FOR ib=0L, nbursts-1 DO BEGIN

  ista = tind[ib, 0]
  iend = tind[ib, 1]

  ; BREAK OUT DATA
  t  = tarr[ista:iend]
  Ex = E.y[ista:iend,0]
  Ey = E.y[ista:iend,1]
  Ez = E.y[ista:iend,2]
  nt_burst = n_elements(t)

  if nt_burst lt kernel_length then begin
     dprint, 'Burst #', string(ib, form='(I0)'), ' is too short. Skipping...'
     print, ''
     continue
  endif

  ; Check NaNs
  indx = where(finite(Ex), nindx)
  indy = where(finite(Ey), nindy)
  indz = where(finite(Ez), nindz)
  if nindx le nt_burst/2. or nindy le nt_burst/2. or nindz le nt_burst/2. $
    then begin
    dprint, 'Burst #', string(ib, form='(I0)'), ' has too many NaNs. ', $
      'Skipping...'
    continue
  endif
  if nindx le nt_burst then Ex = interpol(Ex[indx], t[indx], t)
  if nindy le nt_burst then Ey = interpol(Ey[indy], t[indy], t)
  if nindz le nt_burst then Ez = interpol(Ez[indz], t[indz], t)
  Exf = Ex 
  Eyf = Ey 
  Ezf = Ez 
  b_length = 8 * kernel_length
 


 while b_length gt nt_burst do b_length /= 2
;   print, 'b_length = ', b_length

  ; Remove NaNs
  indx = where(finite(Exf), nindx)
  indy = where(finite(Eyf), nindy)
  indz = where(finite(Ezf), nindz)
  if nindx ne nt_burst then Exf = interpol(Exf[indx], t[indx], t)
  if nindy ne nt_burst then Eyf = interpol(Eyf[indy], t[indy], t)
  if nindz ne nt_burst then Ezf = interpol(Ezf[indz], t[indz], t)

  ;-- Zero-pad data to account for edge wrap
  Exf = [Exf, fltarr(kernel_length/2)]
  Eyf = [Eyf, fltarr(kernel_length/2)]
  Ezf = [Ezf, fltarr(kernel_length/2)]

  ;-- Deconvolve transfer function
  if b_length gt kernel_length then begin
     Exf = shift(blk_con(E12_resp, Exf, b_length=b_length),-kernel_length/2)
     Eyf = shift(blk_con(E34_resp, Eyf, b_length=b_length),-kernel_length/2)
     Ezf = shift(blk_con(E56_resp, Ezf, b_length=b_length),-kernel_length/2)
  endif

  ;-- Remove the padding
  Exf = Exf[0:nt_burst-1]
  Eyf = Eyf[0:nt_burst-1]
  Ezf = Ezf[0:nt_burst-1]

  ; SAVE E DATA
  E.y[ista:iend,0]    = Exf
  E.y[ista:iend,1]    = Eyf
  E.y[ista:iend,2]    = Ezf

ENDFOR

return, E

end

;-------------------------------------------------------------------------------
function rbsp_efw_deconvol_inst_resp_eb1, data, probe, datatype

compile_opt idl2, hidden

; Determine sample rate

tarr = data.x
E = data

dt_arr = tarr[1:*] - tarr
dt = median(dt_arr)
srate = double(round(1d / dt))

; Setup kernel for deconvolving EFI response that includes
;   boom response
;   AC high-pass filter
;   anti-aliasing Bessel filter response
;   ADC interleaving timing
fsample = srate
kernel_length = 1024L
df = fsample / double(kernel_length)
f = dindgen(kernel_length)*df
f[kernel_length/2+1:*] -= double(kernel_length) * df
spb_resp = rbsp_efw_boom_response(f, 'SPB', rsheath = 50d6)
axb_resp = rbsp_efw_boom_response(f, 'AXB', rsheath = 50d6)
hipass_resp = 1d
bessel_resp = rbsp_anti_aliasing_response(f)
adcresp_12 = rbsp_adc_response(f, 'E12DC')
adcresp_34 = rbsp_adc_response(f, 'E34DC')
adcresp_56 = rbsp_adc_response(f, 'E56DC')
E12_resp = 1d / (spb_resp * hipass_resp * bessel_resp * adcresp_12)
E34_resp = 1d / (spb_resp * hipass_resp * bessel_resp * adcresp_34)
E56_resp = 1d / (axb_resp * hipass_resp * bessel_resp * adcresp_56)
; E12_resp[0] = 0
; E34_resp[0] = 0
; E56_resp[0] = 0

; Remove NaNs.
ind = where(finite(E12_resp, /nan), nind)
if nind gt 0 then E12_resp[ind] = 0

ind = where(finite(E34_resp, /nan), nind)
if nind gt 0 then E34_resp[ind] = 0

ind = where(finite(E56_resp, /nan), nind)
if nind gt 0 then E56_resp[ind] = 0
; Transfer kernel into time domain: take inverse FFT and center
E12_resp = shift((fft(E12_resp,1)), kernel_length/2) / kernel_length
E34_resp = shift((fft(E34_resp,1)), kernel_length/2) / kernel_length
E56_resp = shift((fft(E56_resp,1)), kernel_length/2) / kernel_length

rbsp_btrange, data, tind = tind, nbursts = nbursts, /structure

; START LOOP OVER INDIVIDUAL BURSTS
FOR ib=0L, nbursts-1 DO BEGIN

  ista = tind[ib, 0]
  iend = tind[ib, 1]

  ; BREAK OUT DATA
  t  = tarr[ista:iend]
  Ex = E.y[ista:iend,0]
  Ey = E.y[ista:iend,1]
  Ez = E.y[ista:iend,2]
  nt_burst = n_elements(t)

  if nt_burst lt kernel_length then begin
     dprint, 'Burst #', string(ib, form='(I0)'), ' is too short. Skipping...'
     print, ''
     continue
  endif

  ; Check NaNs
  indx = where(finite(Ex), nindx)
  indy = where(finite(Ey), nindy)
  indz = where(finite(Ez), nindz)
  if nindx le nt_burst/2. or nindy le nt_burst/2. or nindz le nt_burst/2. $
    then begin
    dprint, 'Burst #', string(ib, form='(I0)'), ' has too many NaNs. ', $
      'Skipping...'
    continue
  endif
  if nindx le nt_burst then Ex = interpol(Ex[indx], t[indx], t)
  if nindy le nt_burst then Ey = interpol(Ey[indy], t[indy], t)
  if nindz le nt_burst then Ez = interpol(Ez[indz], t[indz], t)
  Exf = Ex 
  Eyf = Ey 
  Ezf = Ez 
  b_length = 8 * kernel_length
  while b_length gt nt_burst do b_length /= 2
;   print, 'b_length = ', b_length

  ; Remove NaNs
  indx = where(finite(Exf), nindx)
  indy = where(finite(Eyf), nindy)
  indz = where(finite(Ezf), nindz)
  if nindx ne nt_burst then Exf = interpol(Exf[indx], t[indx], t)
  if nindy ne nt_burst then Eyf = interpol(Eyf[indy], t[indy], t)
  if nindz ne nt_burst then Ezf = interpol(Ezf[indz], t[indz], t)

  ;-- Zero-pad data to account for edge wrap
  Exf = [Exf, fltarr(kernel_length/2)]
  Eyf = [Eyf, fltarr(kernel_length/2)]
  Ezf = [Ezf, fltarr(kernel_length/2)]

	;-- Deconvolve transfer function
	if b_length gt kernel_length then begin
		Exf = shift(blk_con(E12_resp, Exf, b_length=b_length),-kernel_length/2)
		Eyf = shift(blk_con(E34_resp, Eyf, b_length=b_length),-kernel_length/2)
		Ezf = shift(blk_con(E56_resp, Ezf, b_length=b_length),-kernel_length/2)
	endif

  ;-- Remove the padding
  Exf = Exf[0:nt_burst-1]
  Eyf = Eyf[0:nt_burst-1]
  Ezf = Ezf[0:nt_burst-1]

  ; SAVE E DATA
  E.y[ista:iend,0]    = Exf
  E.y[ista:iend,1]    = Eyf
  E.y[ista:iend,2]    = Ezf

ENDFOR

return, E

end



;-------------------------------------------------------------------------------
function rbsp_efw_deconvol_inst_resp_mscb, data, probe, datatype, $
  srate = srate

compile_opt idl2, hidden

tarr = data.x
E = data

dt_arr = tarr[1:*] - tarr
dt = median(dt_arr)
srate = double(round(1d / dt))

print, ''
dprint, datatype, ': sample rate = ', srate
print, ''


; Setup kernel for deconvolving SCM response that includes
;   search-coil transmittance
;   AC high-pass filter
;   anti-aliasing Bessel filter response
;   ADC interleaving timing
fsample = srate
kernel_length = 1024L
df = fsample / double(kernel_length)
f = dindgen(kernel_length)*df
f[kernel_length/2+1:*] -= double(kernel_length) * df

; MSC Transmittance
Bu_resp = rbsp_msc_response(f, probe, 'Bu')
Bv_resp = rbsp_msc_response(f, probe, 'Bv')
Bw_resp = rbsp_msc_response(f, probe, 'Bw')

bessel_resp = rbsp_anti_aliasing_response(f)

adcresp_u = rbsp_adc_response(f, 'MSCU')
adcresp_v = rbsp_adc_response(f, 'MSCV')
adcresp_w = rbsp_adc_response(f, 'MSCW')

E12_resp = 1d / (Bu_resp * bessel_resp * adcresp_u)
E34_resp = 1d / (Bv_resp * bessel_resp * adcresp_v)
E56_resp = 1d / (Bw_resp * bessel_resp * adcresp_w)


; Remove NaNs.
ind = where(finite(E12_resp, /nan), nind)
if nind gt 0 then E12_resp[ind] = 0

ind = where(finite(E34_resp, /nan), nind)
if nind gt 0 then E34_resp[ind] = 0

ind = where(finite(E56_resp, /nan), nind)
if nind gt 0 then E56_resp[ind] = 0


; Transfer kernel into time domain: take inverse FFT and center
E12_resp = shift((fft(E12_resp,1)), kernel_length/2) / kernel_length
E34_resp = shift((fft(E34_resp,1)), kernel_length/2) / kernel_length
E56_resp = shift((fft(E56_resp,1)), kernel_length/2) / kernel_length

rbsp_btrange, data, tind = tind, nbursts = nbursts, /structure

; START LOOP OVER INDIVIDUAL BURSTS
FOR ib=0L, nbursts-1 DO BEGIN

  ista = tind[ib, 0]
  iend = tind[ib, 1]

  ; BREAK OUT DATA
  t  = tarr[ista:iend]
  Ex = E.y[ista:iend,0]
  Ey = E.y[ista:iend,1]
  Ez = E.y[ista:iend,2]
  nt_burst = n_elements(t)


  if nt_burst lt kernel_length then begin
     dprint, 'Burst #', string(ib, form='(I0)'), ' is too short. Skipping...'
     print, ''
     continue
  endif

  ; Check NaNs
  indx = where(finite(Ex), nindx)
  indy = where(finite(Ey), nindy)
  indz = where(finite(Ez), nindz)
  if nindx le nt_burst/2. or nindy le nt_burst/2. or nindz le nt_burst/2. $
    then begin


    dprint, 'Burst #', string(ib, form='(I0)'), ' has too many NaNs. ', $
      'Skipping...'
    continue
  endif
  if nindx le nt_burst then Ex = interpol(Ex[indx], t[indx], t)
  if nindy le nt_burst then Ey = interpol(Ey[indy], t[indy], t)
  if nindz le nt_burst then Ez = interpol(Ez[indz], t[indz], t)
  Exf = Ex 
  Eyf = Ey 
  Ezf = Ez 


  b_length = 8 * kernel_length
  while b_length gt nt_burst do b_length /= 2
;   print, 'b_length = ', b_length


  ; Remove NaNs
  indx = where(finite(Exf), nindx)
  indy = where(finite(Eyf), nindy)
  indz = where(finite(Ezf), nindz)
  if nindx ne nt_burst then Exf = interpol(Exf[indx], t[indx], t)
  if nindy ne nt_burst then Eyf = interpol(Eyf[indy], t[indy], t)
  if nindz ne nt_burst then Ezf = interpol(Ezf[indz], t[indz], t)

  ;-- Zero-pad data to account for edge wrap
  Exf = [Exf, fltarr(kernel_length/2)]
  Eyf = [Eyf, fltarr(kernel_length/2)]
  Ezf = [Ezf, fltarr(kernel_length/2)]


	;-- Deconvolve transfer function
	if b_length gt kernel_length then begin


	  Exf = shift(blk_con(E12_resp, Exf, b_length=b_length),-kernel_length/2)
	  Eyf = shift(blk_con(E34_resp, Eyf, b_length=b_length),-kernel_length/2)
	  Ezf = shift(blk_con(E56_resp, Ezf, b_length=b_length),-kernel_length/2)
	endif

  ;-- Remove the padding
  Exf = Exf[0:nt_burst-1]
  Eyf = Eyf[0:nt_burst-1]
  Ezf = Ezf[0:nt_burst-1]

  ; SAVE E DATA
  E.y[ista:iend,0]    = Exf
  E.y[ista:iend,1]    = Eyf
  E.y[ista:iend,2]    = Ezf

ENDFOR

return, E

end


;-------------------------------------------------------------------------------
function rbsp_efw_deconvol_inst_resp, data, probe, datatype

compile_opt idl2

; vdatatypes=['esvy', 'vsvy', 'magsvy', 'eb1', 'vb1', 'mscb1', 'eb2', 'vb2', $
;   'mscb2']
; if total(strcmp(vdatatypes, strlowcase(datatype[0]))) ne 1 then begin
;   dprint, 'Invalid data type. No action performed. Abort.'
;   return, data
; endif

case strlowcase(datatype[0]) of
  'eb2': return, rbsp_efw_deconvol_inst_resp_eb2(data, probe, datatype)
  'eb1': return, rbsp_efw_deconvol_inst_resp_eb1(data, probe, datatype)

  'mscb2': return, rbsp_efw_deconvol_inst_resp_mscb(data, probe, datatype)
  'mscb1': return, rbsp_efw_deconvol_inst_resp_mscb(data, probe, datatype)

  else: begin
      print, ''
      dprint, 'Invalid data type. No action performed. Abort.'
      print, ''
      return, !values.d_nan
    end
endcase


end
