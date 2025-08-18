;+
; FUNCTION aacgmmlong 
; 
; :PURPOSE:
; A wrapper procedure to choose AACGM DLM or IDL-native routines 
; to convert a AACGM MLT to AACGM longitude. Please be aware that 
; this wrapper works with AACGM DLM of ver. 4.0 or older, in which 
; AACGM_MLONG() uses year and second of year (+ mlt) as arguments.   
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
;   mlt:   AACGM MLT to be converted to AACGM longitude.
; 
; :Examples:
;   mlon = aacgmmlong( yr, t0, mlt )
;   
; :HISTORY:
;   2011/10/04: created and got through the initial bug fixes
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-

function aacgmmlong, yr, t0, mlt

;Initialize !sdarn if not defined
help, name='!sdarn',out=out
if out eq '' then sd_init

if !map2d.aacgm_dlm_exists then begin 
  ;print, 'using AACGM_DLM'
  tmlon = aacgm_mlong(yr,t0,mlt)
  tmlon = ( tmlon + 360. ) mod 360.
  mlon = mlt 
  if (size(mlt[0]))[1] eq 4 then begin
    mlon[*] = float( tmlon[*] ) 
  endif else begin
    mlon[*] = tmlon[*] 
  endelse
  return, mlon
  
endif else begin
  cnv_aacgm,0.0,0.0,0.001,mlat0,mlon0,r,err,/geo
  mlon0 = ( mlon0 + 360. ) mod 360.
  mlon=mlt
  mlon[*]=0.
  for i=0L, n_elements(mlon)-1 do begin
    tmlt = ( mlt[i] + 24. ) mod 24.
    mlt0 = calc_mlt(yr[i],t0[i],mlon0)
    mlt0 = ( mlt0 + 24. ) mod 24.
    tmlon = ( (tmlt - mlt0 +24.) mod 24. )/24.*360.
    mlon[i]=tmlon
    ;print, 'cnv_aacgm was executed'
    ;print, glat[i],glon[i],alt[i],'   ',mlat[i],mlon[i],r,err
  endfor
  return, mlon
endelse

return, !values.f_nan ;error 
end

