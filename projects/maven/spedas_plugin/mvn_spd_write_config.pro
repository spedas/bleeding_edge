;+
;NAME:
; mvn_spd_write_config
;PURPOSE:
; Writes the mvn_spd_config file
;CALLING SEQUENCE:
; mvn_spd_write_config, copy=copy
;INPUT:
; none, the filename is hardcoded, 'mvn_spd_config.txt',and is put in a
; folder given by the routine mvn_spd_config_filedir, that uses the IDL
; routine app_user_dir to create/obtain it: my linux example:
; /disks/ice/home/jimm/.idl/mvn_spd/mvn_spd_config-4-linux
;OUTPUT:
; the file is written, and a copy of any old file is generated
;KEYWORD:
; copy = if set, the file is read in and a copy with the !stime
;        appended is written out
;HISTORY:
; 2014-12-01, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-01-11 11:54:21 -0800 (Mon, 11 Jan 2016) $
;$LastChangedRevision: 19709 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_write_config.pro $
;-

Pro mvn_spd_write_config, copy = copy, _extra = _extra

  compile_opt idl2,hidden

; No sys variable, but a common block
  common mvn_file_source_com,  psource

  otp = -1
;First step is to get the filename
  dir = mvn_spd_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'mvn_spd_config.txt' $
  Else filex = dir+'/'+'mvn_spd_config.txt'

;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = mvn_spd_read_config(header = hhh)
  Endif Else Begin
;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then mvn_spd_write_config, /copy
    filex_out = filex
    cfg = {local_data_dir:psource.local_data_dir, $
           remote_data_dir:psource.remote_data_dir, $
           no_server:psource.no_server, $
           verbose:psource.verbose, $
           last_version:psource.last_version}
    
    hhh = [';mvn_spd_config.txt', ';MAVEN SPD PLUGIN configuration file', $
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
