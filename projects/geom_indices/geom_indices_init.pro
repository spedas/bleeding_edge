;+
;NAME: geom_indices_init
;
;DESCRIPTION: Initializes system variables for geomagnetic indices in SPEDAS (!geom_indices).  Can be called
;  from idl_startup or customized for non-standard installations.  
;
;REQUIRED INPUTS:
; none
;
;KEYWORD ARGUMENTS (OPTIONAL):
; RESET:        If set, force
;
;
;STATUS:
;
;EXAMPLE:
;
;REVISION HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-20 16:29:03 -0700 (Mon, 20 Apr 2015) $
;$LastChangedRevision: 17383 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geom_indices/geom_indices_init.pro $
;-

pro geom_indices_init,reset=reset

  compile_opt idl2

  geom_indices_reset = 1

  defsysv,'!geom_indices',exists=exists
  if (not keyword_set(exists)) then begin ;if !geom_indices is not defined
    tmp_struct=file_retrieve(/structure_format)
    str_element,tmp_struct,'remote_data_dir_noaa','',/add
    str_element,tmp_struct,'remote_data_dir_kyoto_ae','',/add
    str_element,tmp_struct,'remote_data_dir_kyoto_dst','',/add
    defsysv,'!geom_indices',tmp_struct
  endif

  ftest = geom_indices_read_config()
  if (keyword_set(reset)) or not (size(ftest, /type) eq 8) then begin ;if it was not saved before or if it is reset
    tmp_struct=file_retrieve(/structure_format)
    str_element,tmp_struct,'remote_data_dir_noaa','',/add
    str_element,tmp_struct,'remote_data_dir_kyoto_ae','',/add
    str_element,tmp_struct,'remote_data_dir_kyoto_dst','',/add

    DEFSYSV, '!geom_indices', EXISTS = giexists
    IF giexists EQ 1 THEN begin
      str_element,!geom_indices,'remote_data_dir_noaa',SUCCESS=s
      if ~s then str_element,!geom_indices,'remote_data_dir_noaa','',/add
      str_element,!geom_indices,'remote_data_dir_kyoto_ae',SUCCESS=s
      if ~s then str_element,!geom_indices,'remote_data_dir_kyoto_ae','',/add
      str_element,!geom_indices,'remote_data_dir_kyoto_dst',SUCCESS=s
      if ~s then str_element,!geom_indices,'remote_data_dir_kyoto_dst','',/add
    ENDIF

    defsysv,'!geom_indices',tmp_struct
    data_dir =  geom_indices_config_filedir()
    data_dir = StrJoin( StrSplit(data_dir, '\\' , /Regex, /Extract, /Preserve_Null), path_sep())
    data_dir = StrJoin( StrSplit(data_dir, '/', /Regex, /Extract, /Preserve_Null), path_sep())
    if STRMID(data_dir, 0, 1, /REVERSE_OFFSET) ne path_sep() then data_dir = data_dir + path_sep()
    !geom_indices.local_data_dir = spd_default_local_data_dir() + 'geom_indices' + path_sep()
    !geom_indices.remote_data_dir_noaa =  'http://themis-data.igpp.ucla.edu/'  ;noaa_load_kp
    !geom_indices.remote_data_dir_kyoto_ae =  'http://wdc.kugi.kyoto-u.ac.jp/' ;kyoto_load_ae
    !geom_indices.remote_data_dir_kyoto_dst = 'http://wdc.kugi.kyoto-u.ac.jp/' ;kyoto_load_dst
    !geom_indices.init = 1
    print,'Resetting !geom_indices to default configuration.'
  endif else begin ;retrieved from saved values
    ctags = tag_names(ftest)
    nctags = n_elements(ctags)
    stags = tag_names(!geom_indices)
    sctags = n_elements(stags)

    For j = 0, nctags-1 Do Begin
      x0 = strtrim(ctags[j])
      x1 = ftest.(j)
      If (size(x1, /type) eq 11) then x1 = '' ;ignore objects
      If(is_string(x1)) Then x1 = strtrim(x1, 2) $
      Else Begin                  ;Odd thing can happen with byte arrays
        If(size(x1, /type) Eq 1) Then x1 = fix(x1)
        x1 = strcompress(/remove_all, string(x1))
      Endelse
      index = WHERE(stags eq x0, count)
      if count EQ 0 then begin
        dir = geom_indices_config_filedir()
        msg='The configuration file '+dir+path_sep()+'geom_indices_config.txt contains invalid or obsolete fields. Would you like a new file automatically generated for you? If not, you will need to modify your existing file before proceeding. Configuration information can be found in the Users Guide.'
        answer = dialog_message(msg, /question)
        if answer EQ 'Yes' then begin
          cmd='del '+dir+'\geom_indices_config.txt'
          spawn, cmd, res, errres
          geom_indices_init
        endif
        return
      endif
      if (count gt 0) and not (size(!geom_indices.(index), /type) eq 11) then !geom_indices.(index) = x1
    endfor
    geom_indices_reset = 0
    print,'Loaded !geom_indices from saved values.'
  endelse

  if geom_indices_reset then geom_indices_write_config ;if i twas just re-loaded from file, we do not re-write the values

  printdat,/values,!geom_indices,varname='!geom_indices'

END
