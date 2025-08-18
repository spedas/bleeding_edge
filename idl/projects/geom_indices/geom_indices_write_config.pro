;+
;NAME: geom_indices_write_config
;
;DESCRIPTION:
;  Writes the geom_indices_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'geom_indices_config.txt', and is put in a folder
;   given by the routine 'geom_indices_config_filedir', that uses the IDL routine
;   app_user_dir to create/obtain it:
; e.g. (MacOS X)
;   /Users/username/.idl/spedas/geom_indices_config-4_darwin
;
;KEYWORD ARGUMENTS (OPTIONAL):
; COPY:         If set, make a copy, creating a new file whose filename
;       is timestamped with an appended !STIME.
;
;OUTPUT
; the file is written, and a copy of any old file is generated
;
;STATUS:
;
;TO BE ADDED: n/a
;
;EXAMPLE:
;
;REVISION HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-11-05 11:21:52 -0800 (Wed, 05 Nov 2014) $
;$LastChangedRevision: 16138 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geom_indices/geom_indices_write_config.pro $
;-

PRO geom_indices_write_config, copy=copy, _extra=_extra

  ;First step is to get the filename
  ;For this example the directory name has been hard coded
  dir = geom_indices_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'geom_indices_config.txt' $
  Else filex = dir+PATH_SEP()+'geom_indices_config.txt'

  ;If we are copying the file, get a filename, header and old configuration
  If(keyword_set(copy)) Then Begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
      '_'+strmid(xt, 11, 2)+strmid(xt, 14, 2)+strmid(xt, 17, 2)
    filex_out = filex+'_'+ttt
    cfg = geom_indices_read_config(header = hhh)
  Endif Else Begin
    ;Does the file exist? If is does then copy it
    If(file_search(filex) Ne '') Then geom_indices_write_config, /copy
    filex_out = filex
    if ~keyword_set(!geom_indices) then begin
      tmp_struct=file_retrieve(/structure_format)
      str_element,tmp_struct,'remote_data_dir_noaa','',/add
      str_element,tmp_struct,'remote_data_dir_kyoto_ae','',/add
      str_element,tmp_struct,'remote_data_dir_kyoto_dst','',/add
      defsysv,'!geom_indices',tmp_struct
    endif
    cfg = !geom_indices

    hhh = [';geom_indices_config.txt', ';geom_indices configuration file', $
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

    If(is_string(x1)) Then x1 = strtrim(x1, 2) $
    Else Begin                  ;Odd thing can happen with byte arrays
      If(size(x1, /type) Eq 1) Then x1 = fix(x1)
      x1 = strcompress(/remove_all, string(x1))
    Endelse

    printf, unit, x0+'='+x1
  Endfor

  free_lun, unit
  Return

END



