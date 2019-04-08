;+
; FUNCTION aacgmmlt 
; 
; :PURPOSE:
; A wrapper procedure to choose AACGM DLM or IDL-native routines 
; to convert a AACGM longitude to AACGM MLT. Please be aware that 
; this wrapper works with AACGM DLM of ver. 4.0 or older, in which 
; AACGM_MLT() uses year and second of year (+ mlon) as arguments. 
; 
; The wrapper procedures/functions check !sdarn.aacgm_dlm_exists 
; (if not defined, then define it by sd_init) to select appropriate 
; AACGM routines (DLM, or IDL native ones attached to TDAS). 
; 
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
; 
; :Params:
;   yr:     4-digit year for which MLT is calculated.
;   t0:     Second of year for which MLT is calculated.
;   mlon:   AACGM longitude to be converted to MLT.
; 
; :Examples:
;   mlt = aacgmmlt( yr, t0, mlon )
;   
; :HISTORY:
;   2011/10/04: created and got through the initial bug fixes
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-


function aacgmmlt, yr, t0, mlon

;Initialize !sdarn if not defined
help, name='!sdarn',out=out
if out eq '' then sd_init

if !map2d.aacgm_dlm_exists then begin 
  ;print, 'using AACGM_DLM'
  mlt_tmp = aacgm_mlt(yr,t0,mlon)
  mlt = mlon 
  if (size(mlt[0]))[1] eq 4 then begin 
    mlt[*] = float( mlt_tmp[*] )
  endif else begin
    mlt[*] = mlt_tmp[*]
  endelse 
  return, (mlt+24.) mod 24 
  
endif else begin
  mlt=mlon
  mlt[*]=0.
  for i=0L, n_elements(mlon)-1 do begin
    tmlt = calc_mlt(yr[i],t0[i],mlon[i])
    mlt[i]=tmlt
    ;print, 'cnv_aacgm was executed'
    ;print, glat[i],glon[i],alt[i],'   ',mlat[i],mlon[i],r,err
  endfor
  return, (mlt+24.) mod 24 
endelse

return, !values.f_nan ;error 
end


