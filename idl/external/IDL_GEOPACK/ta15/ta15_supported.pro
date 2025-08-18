;+
; ta15_supported
;
; Purpose: returns 1 if ta15 is supported (geopack version is 10.0 or higher)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2022-05-29 14:11:42 -0700 (Sun, 29 May 2022) $
; $LastChangedRevision: 30836 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/ta15_supported.pro $
;-

function ta15_supported

  help, 'geopack', /dlm, output=dlm_about
  result = 0

  if n_elements(dlm_about) gt 1 then begin
    d = strsplit(dlm_about[1], /extract)
    if n_elements(d) gt 1 then begin
      v = strsplit(d[1], '.', /extract)
      if n_elements(v) gt 0 then begin
        if v[0] ge 10 then result = 1
      endif
    endif
  endif

  if result eq 0 then begin
    dprint, "TA15 models are supported only in GEOPACK 10.0 or higher. Please upgrade your GEOPACK version."
    help, 'geopack', /dlm
  endif

  return, result
end