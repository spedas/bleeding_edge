;+
;NAME:
; spedas_write_config
;
;PURPOSE:
; Writes the spedas_config file
;
;CALLING SEQUENCE:
; spedas_write_config, copy=copy
;
;INPUT:
; none, the filename is hardcoded, 'spedas_config.txt',and is  put in a
; folder given by the routine spedas_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/spedas/spedas_config-4-linux
;
;OUTPUT:
; the file is written, and a copy of any old file is generated
;
;KEYWORD:
; copy = if set, the file is read in and a copy with the !stime
;        appended is written out
;
;HISTORY:
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spedas_write_config.pro $
;-

Pro spedas_write_config, copy = copy, _extra = _extra

  ;First step is to get the filename
  ;For this example the directory name has been hard coded
  dir = spedas_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'spedas_config.txt' $
  Else filex = dir+PATH_SEP()+'spedas_config.txt'

  ;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = spedas_read_config(header = hhh)
  Endif Else Begin
    ;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then spedas_write_config, /copy
    filex_out = filex
    if ~keyword_set(!spedas) then begin
     ; tmp_struct=file_retrieve(/structure_format)
      tmp_struct = create_struct('browser_exe', '', 'temp_dir', '', $
                   'temp_cdf_dir', '','geopack_param_dir', '', 'linux_fix', 0)
;      str_element,tmp_struct,'browser_exe','',/add
;      str_element,tmp_struct,'temp_dir','',/add
;      str_element,tmp_struct,'temp_cdf_dir','',/add
;      str_element,tmp_struct,'linux_fix',0,/add
      ;str_element,tmp_struct,'temp_cdf_dir','',/add
      defsysv,'!spedas',tmp_struct
    endif
    cfg = !spedas
    defsysv, '!spedas', exists=spd_gui_exists
    if spd_gui_exists then begin
      str_element,cfg,'renderer',!spedas.renderer,/add
      if in_set('templatepath',strlowcase(tag_names(!spedas))) then begin
        str_element,cfg,'templatepath',!spedas.templatepath,/add
      endif
    endif

    hhh = [';spedas_config.txt', ';spedas configuration file', $
    ';Created:'+time_string(systime(/sec))]
  Endelse

  ;You need to be sure that the directory exists
  xdname = file_dirname(filex_out)
  If(xdname Ne '') Then file_mkdir, xdname
  ;Write the file
  openw, unit, filex_out, /get_lun
  For j = 0, n_elements(hhh)-1 Do printf, unit, hhh[j]
  ctags = tag_names(cfg)
  nctags = n_elements(ctags)
  For j = 0, nctags-1 Do Begin
    x0 = strtrim(ctags[j])
    x1 = cfg.(j)

    If (size(x1, /type) eq 11) then x1 = '' ;ignore objects
    if (size(x1, /type) eq 10) then x1 = '' ;ignore pointers
    
    If(is_string(x1)) Then x1 = strtrim(x1, 2) $
    Else Begin                  ;Odd thing can happen with byte arrays
      If(size(x1, /type) Eq 1) Then x1 = fix(x1)
      x1 = strcompress(/remove_all, string(x1))
    Endelse

    printf, unit, x0+'='+x1
  Endfor

  free_lun, unit
  Return
End
