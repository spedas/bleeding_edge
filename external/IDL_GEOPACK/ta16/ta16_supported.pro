;+
; ta16_supported
;
; Purpose: returns 1 if TA16 is supported (geopack version is 10.9 or higher)
;          
;
; Notes:
;   2022-05-23: Geopack DLM v10.9 is a beta version:
;               https://www.korthhaus.com/index.php/idl-software/idl-geopack-dlm/
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-09-16 16:24:34 -0700 (Fri, 16 Sep 2022) $
; $LastChangedRevision: 31096 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta16/ta16_supported.pro $
;-

function ta16_supported

  help, 'geopack', /dlm, output=dlm_about
  result = 0

  if n_elements(dlm_about) gt 1 then begin
    d = strsplit(dlm_about[1], /extract)
    if n_elements(d) gt 1 then begin
      v = strsplit(d[1], '.', /extract)
      if n_elements(v) gt 0 then begin
        v0 = v[0]
        v1 = strsplit(v[1], ',', /extract)
        if v0 gt 10 then begin
          result = 1 ; geopack 11 and over
        endif else begin
          if v0 eq 10 && v1 ge 9 then result = 1 ; geopack 10.9 and over
        endelse
      endif
    endif
  endif

  if result eq 0 then begin
    dprint, "TA16 model is supported only in GEOPACK 10.9 or higher. Please upgrade your GEOPACK version."
    help, 'geopack', /dlm
  endif
  return, result
end