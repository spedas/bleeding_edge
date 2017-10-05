;+
;NAME:
; istp_write_config
;PURPOSE:
; Writes the istp_config file
;CALLING SEQUENCE:
; istp_write_config, copy=copy
;INPUT:
; none, the filename is hardcoded, 'istp_config.txt',and is  put in a
; folder given by the routine istp_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/themis/istp_config-4-linux
;OUTPUT:
; the file is written, and a copy of any old file is generated
;KEYWORD:
; copy = if set, the file is read in and a copy with the !stime
;        appended is written out
;HISTORY:
; Copied from tt2000_write_config and thm_write_config lphilpott 20-jun-2012
;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-21 16:18:22 -0700 (Thu, 21 Jun 2012) $
;$LastChangedRevision: 10610 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/istp_write_config.pro $
;-

Pro istp_write_config, copy = copy, _extra = _extra
  otp = -1
;First step is to get the filename
  dir = istp_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'istp_config.txt' $
  Else filex = dir+'/'+'istp_config.txt'

;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = istp_read_config(header = hhh)
  Endif Else Begin
;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then istp_write_config, /copy
    filex_out = filex
    cfg = {local_data_dir:!istp.local_data_dir, $
           remote_data_dir:!istp.remote_data_dir, $
           no_download:!istp.no_download, $
           no_update:!istp.no_update, $
           downloadonly:!istp.downloadonly, $
           verbose:!istp.verbose}
               
    hhh = [';istp_config.txt', ';ISTP configuration file', $
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
