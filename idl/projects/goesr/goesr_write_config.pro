;+
;NAME:
; goesr_write_config
; 
;PURPOSE:
; Writes the goesr_config file
; 
;CALLING SEQUENCE:
; goesr_write_config, copy=copy
; 
;INPUT:
; none, the filename is hardcoded, 'goesr_config.txt',and is s put in a
; folder given by the routine thm_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it
;
;OUTPUT:
; the file is written, and a copy of any old file is generated
; 
;KEYWORD:
; copy = if set, the file is read in and a copy with the !stime
;        appended is written out
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2021-09-08 13:44:17 -0700 (Wed, 08 Sep 2021) $
;$LastChangedRevision: 30284 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_write_config.pro $
;-

Pro goesr_write_config, copy = copy, _extra = _extra
  otp = -1
  ;First step is to get the filename
  dir = goesr_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'goesr_config.txt' $
  Else filex = dir+'/'+'goesr_config.txt'

  ;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = goes_read_config(header = hhh)
  Endif Else Begin
    ;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then goes_write_config, /copy
    filex_out = filex
    cfg = {local_data_dir:!goesr.local_data_dir, $
      remote_data_dir:!goesr.remote_data_dir, $
      no_download:!goesr.no_download, $
      no_update:!goesr.no_update, $
      downloadonly:!goesr.downloadonly, $
      verbose:!goesr.verbose}

    hhh = [';goesr_config.txt', ';GOES-R configuration file', $
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
