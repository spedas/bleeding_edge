
;+
;NAME:
; thm_sst_atten_scale
;PURPOSE:
;
; This routine determines the appropriate attenuator scale factor array based on the SST angle mode and
; the attenuator flags
;  
;Inputs:
;  atten_flags: 4-bit flag indicating which attenuators are engaged
;  data_dims: The return value of dimen(data.data)
; 
;Keywords:
;  scale_factors(optional): 4-element array with the scaling factors for each attenuator pinhole. 
;                           Defaults to 1./64.
; 
;Returns:
;  Scaling factor array
;   
;  
;SEE ALSO:
;  thm_sst_convert_units
;  
;NOTES:
;atten_flags are a 4-bit value for the attenuator flags
;Defined as MSB,Open Equatorial Attenuator,Closed Equatorial Attenuator,Open Polar Attenuator,Closed Polar Attenuator, LSB
;With MSB/LSB not representing actual bits, but as labels to clarify bit order.
;Some examples:
; 0x5: both attenuators closed
; 0xA: both attenuators open
; 0x6: equatorial closed, polar open  (Occurs during stuck atten error on themis D)
; 0xf: Error state. Invalid data.
; 0x9: equatorial open, polar closed (This should never actually happen)
; 
;Under normal circumstances both attenuators are in the same state and the open/closed flags are mutually exclusive.
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-01-03 12:10:47 -0800 (Fri, 03 Jan 2014) $
;$LastChangedRevision: 13737 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_atten_scale.pro $
;-

function thm_sst_atten_scale,atten_flags,data_dims,scale_factors=scale_factors

  compile_opt idl2
  
  atten = dblarr(data_dims)
  
  if (atten_flags and 'f'x) ne 'a'x && (atten_flags and 'f'x) ne '5'x then begin
    dprint,'WARNING Ambiguous attenuator flag found: ' + strtrim(atten_flags,2),dlevel=5 ;this message will spam the console
;    atten[*] = !VALUES.D_NAN ; invalid attenuator state
;    return,atten
  endif
  
  
  if (atten_flags and 'c'x) eq 'c'x || (atten_flags and 'c'x) eq '0'x || $
     (atten_flags and '3'x) eq '3'x || (atten_flags and '3'x) eq '0'x then begin
  
    ;error state, treat as missing data
    atten[*] = !VALUES.D_NAN ; invalid attenuator state
    dprint, dlevel=4,'Attenuator flags are invalid: ' + strtrim(atten_flags,2)
    
  
  endif else if n_elements(data_dims) eq 1 then begin
    ;slow survey reduced distribution
    
    ;spin-plane sensor
    if (atten_flags and 'c'x) eq '8'x then begin ;open
      atten += 2.
    endif else if (atten_flags and 'c'x) eq '4'x then begin ;closed
      atten += 1./32.
    endif else begin
      message,'Illegal attenuator state indicates error in software' ;else case should never happen
    endelse
    
    ;polar sensor
    if (atten_flags and '3'x) eq '2'x then begin ;open
      atten += 2.
    endif else if (atten_flags and '3'x) eq '1'x then begin ;closed
      atten += 1./32.
    endif else begin
      message,'Illegal attenuator state indicates error in software' ;else case should never happen
    endelse
    
    ;for a single angle bin, the average attenuation across all channels is used.
    atten /= 4
  
  
  endif else if data_dims[1] eq 6 then begin
    ;fast survey reduced distribution
   
    ;spin-plane sensor
    if (atten_flags and 'c'x) eq '8'x then begin ;open
      atten[*,2:5] = 1.
    endif else if (atten_flags and 'c'x) eq '4'x then begin ;closed
      atten[*,2:5] = 1./64.
    endif else begin
      message,'Illegal attenuator state indicates error in software' ;else case should never happen
    endelse
    
    ;polar sensor
    if (atten_flags and '3'x) eq '2'x then begin ;open
      atten[*,0:1] = 1.
    endif else if (atten_flags and '3'x) eq '1'x then begin ;closed
      atten[*,0:1] = 1./64.
    endif else begin
      message,'Illegal attenuator state indicates error in software' ;else case should never happen
    endelse
  
  endif else if data_dims[1] eq 64 then begin
    ;full and burst distribution 
  
    ;spin-plane sensor
    if (atten_flags and 'c'x) eq '8'x then begin ;open
      atten[*,32:63] = 1.
    endif else if (atten_flags and 'c'x) eq '4'x then begin ;closed
      atten[*,32:63] = keyword_set(scale_factors)?scale_factors[*,32:63]:1./64.
    endif else begin
      message,'Illegal attenuator state indicates error in software' ;else case should never happen
    endelse
    
    ;polar sensor
    if (atten_flags and '3'x) eq '2'x then begin ;open
      atten[*,0:31] = 1.
    endif else if (atten_flags and '3'x) eq '1'x then begin ;closed
      atten[*,0:31] = keyword_set(scale_factors)?scale_factors[*,0:31]:1/64.
    endif else begin
      message,'Illegal attenuator state indicates error in software' ;else case should never happen
    endelse
    
  endif else begin
  
    atten[*] = !VALUES.D_NAN ; treat unexpected state as missing data
    dprint,'Unexpected SST mode found',data_dims
  
  endelse

  return,atten

end