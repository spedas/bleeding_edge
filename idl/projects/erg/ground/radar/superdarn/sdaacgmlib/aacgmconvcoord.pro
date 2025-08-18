;+
; PROCEDURE aacgmconvcoord
;
; :PURPOSE:
; A wrapper procedure to choose AACGM DLM or IDL-native routines
; to convert (lat,lon) between Geographic coordinates and AACGM.
;
; The wrapper procedures/functions check !sdarn.aacgm_dlm_exists
; (if not defined, then define it by sd_init) to select appropriate
; AACGM routines (DLM, or IDL native ones attached to TDAS).
;
; :Params:
;   glat, glon:   Geographic latitude and longitude.
;   mlat, mlon:   AACGM latitude and longitude.
;   alt:          Altitude for conversion.
;   err:          Error status of coordinate transformation.
;
; :Keywords:
;   TO_AACGM:   Set to convert from geographic to AACGM coordinates.
;   TO_GEO:     Set to convert from AACGM to geographic coordinates.
;
; :Examples:
;   aacgmconvcoord, glat,glon,alt, mlat,mlon,err, /TO_AACGM
;   aacgmconvcoord, mlat,mlon,alt, glat,glon,err, /TO_GEO
;
; :AUTHOR:
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;
; :HISTORY:
;   2011/10/04: created and got through the initial bug fixes
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-

pro aacgmconvcoord, glat,glon,alt,mlat,mlon,err, TO_AACGM=TO_AACGM, TO_GEO=TO_GEO

  ;Initialize !sdarn if not defined
  help, name='!sdarn',out=out
  if out eq '' then sd_init
  
  glon = (glon + 360.) mod 360.
  
  if !map2d.aacgm_dlm_exists then begin
    ;print, 'using AACGM_DLM'
    aacgm_conv_coord, glat,glon,alt,mlat1,mlon1,err1,$
      TO_AACGM=TO_AACGM, TO_GEO=TO_GEO
    mlat = glat & mlon = glat & err = glat
    if (size(glat[0]))[1] eq 4 then begin  ;the arguments are in float
      mlat[*] = float( mlat1[*] ) & mlon[*] = float( mlon1[*] ) & err[*] = float( err1[*] )
    endif else begin
      mlat[*] = double( mlat1[*] ) & mlon[*] = double( mlon1[*] ) & err[*] = double( err1[*] )
    endelse
  endif else begin
    mlat=glat & mlon=glon
    mlat[*]=0. & mlon[*]=0.
    err = fix(glat) & err[*] = 0
    for i=0L, n_elements(glat)-1 do begin
      cnv_aacgm,glat[i],glon[i],alt[i],tmlat,tmlon,r,terr,geo=TO_GEO
      mlat[i]=tmlat & mlon[i]=tmlon & err[i] = fix(terr)
      ;print, 'cnv_aacgm was executed'
      ;print, glat[i],glon[i],alt[i],'   ',mlat[i],mlon[i],r,err
    endfor
  endelse
  
  mlon = (mlon + 360.) mod 360.
  
  return
end


