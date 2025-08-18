;+
;NAME:
; thm_write_config
;PURPOSE:
; Writes the thm_config file
;CALLING SEQUENCE:
; thm_write_config, copy=copy
;INPUT:
; none, the filename is hardcoded, 'thm_config.txt',and is s put in a
; folder given by the routine thm_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/themis/thm_config-4-linux
;OUTPUT:
; the file is written, and a copy of any old file is generated
;KEYWORD:
; copy = if set, the file is read in and a copy with the !stime
;        appended is written out
;HISTORY:
; 17-may-2007, jmm, jimm@ssl.berkeley.edu
; 18-mar-2009, jmm, fixed problem with writing string representations
;                   of byte values
; 10-aug-2011, lphilpott, modified to write a template path to the config file too.
;$LastChangedBy$
;$LastChangedDate$
;$LastChangedRevision$
;$URL$
;-

Pro thm_write_config, copy = copy, _extra = _extra
  otp = -1
;First step is to get the filename
  dir = thm_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'thm_config.txt' $
  Else filex = dir+'/'+'thm_config.txt'

;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = thm_read_config(header = hhh)
  Endif Else Begin
;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then thm_write_config, /copy
    filex_out = filex
    cfg = {local_data_dir:!themis.local_data_dir, $
           remote_data_dir:!themis.remote_data_dir, $
           no_download:!themis.no_download, $
           no_update:!themis.no_update, $
           downloadonly:!themis.downloadonly, $
           verbose:!themis.verbose}
    
    defsysv,'!THM_GUI_NEW',exists=i
    if i then begin
      str_element,cfg,'renderer',!THM_GUI_NEW.renderer,/add
      if in_set('templatepath',strlowcase(tag_names(!THM_GUI_NEW))) then begin
        str_element,cfg,'templatepath',!THM_GUI_NEW.templatepath,/add
      endif
    endif
           
    hhh = [';thm_config.txt', ';THEMIS configuration file', $
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
