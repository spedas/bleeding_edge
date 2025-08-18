; NAME: tracers_config_write
;
; PURPOSE: Write a structure (a set of variables) into a configuration file.
;
; NOTES: The variables are additive. If you have your own set of variables
; that you would like to store into the configuration file,
; make a structure "pref" and type-in
;
; IDL> tracers_config_write, pref
;
; The variables can be retrieved by
;
; IDL> cfg = tracers_config_read()
;
; The structure 'cfg' contains your variables in addition to the default variables.
;
; $LastChangedBy: elfin_shared $
; $LastChangedDate: 2025-07-14 22:58:01 -0700 (Mon, 14 Jul 2025) $
; $LastChangedRevision: 33465 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/tracers/common/tracers_config_write.pro $
;
PRO tracers_config_write, pref

  ; Configuration
  cfg = tracers_config_read()                 ; read current config
  cfg = tracers_config_push(pref,cfg,/force)  ; update 'cfg' with 'pref'

  ; Filename
  dir = tracers_config_filedir(/app_query)
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'tracers_config.txt' $
  Else filex = dir+'/'+'tracers_config.txt'

  ; Header
  hhh = [';tracers_config.txt', ';tracers configuration file', ';Created:'+time_string(systime(/sec))]

  ; Write
  openw, nf, filex, /get_lun
  for j = 0, n_elements(hhh)-1 Do printf, nf, hhh[j]
  ctags = tag_names(cfg)
  nctags = n_elements(ctags)
  for j = 0, nctags-1 do begin
    x0 = strtrim(ctags[j])
    x1 = cfg.(j)
    if(is_string(x1)) then begin
      x1 = strtrim(x1, 2)
    endif else begin; Odd thing can happen with byte arrays
      if size(x1, /type) eq 11 && x1 eq !null then continue
      if(size(x1, /type) eq 1) Then x1 = fix(x1)
      x1 = strcompress(/remove_all, string(x1))
    endelse
    printf, nf, x0+'='+x1
  endfor
  close, nf
  free_lun, nf

END
