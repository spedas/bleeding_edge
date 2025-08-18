;+
;NAME:
;   icon_write_config
;
;PURPOSE:
;   Writes the icon_config file
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-10 10:41:33 -0700 (Thu, 10 May 2018) $
;$LastChangedRevision: 25192 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/config/icon_write_config.pro $
;
;-------------------------------------------------------------------

pro icon_write_config, copy = copy, _extra = _extra
  otp = -1
  ;First step is to get the filename
  dir = icon_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'icon_config.txt' $
  Else filex = dir+'/'+'icon_config.txt'

  ;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = icon_read_config(header = hhh)
  Endif Else Begin
    ;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then icon_write_config, /copy
    filex_out = filex
    cfg = {local_data_dir:!icon.local_data_dir, $
      remote_data_dir:!icon.remote_data_dir, $
      no_download:!icon.no_download, $
      no_update:!icon.no_update, $
      downloadonly:!icon.downloadonly, $
      verbose:!icon.verbose}


    hhh = [';icon_config.txt', ';ICON configuration file', $
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

