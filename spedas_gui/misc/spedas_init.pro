;+
;PROCEDURE:  spedas_init
;
;PURPOSE:    Initializes system variables for spedas data.
;            Can be called from idl_startup to set custom locations.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-03 13:50:06 -0800 (Thu, 03 Dec 2015) $
;$LastChangedRevision: 19523 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spedas_init.pro $
;-

pro spedas_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, use_spdf = use_spdf, no_color_setup

  compile_opt idl2

  spedas_reset = 1

  defsysv,'!spedas',exists=exists
  if (not keyword_set(exists)) then begin ;if !spedas is not defined
    tmp_struct = {browser_exe: '', $    ; location of the local browser executable
                  temp_dir: '', $
                  temp_cdf_dir: '', $
                  linux_fix: 0b, $
                  renderer:1B,$  ;OS specific rendering options should go here
                  guiId:0L,  $ ; the widget id of the main gui, needed as an input to command line.
                  drawObject:obj_new(),$ ;draw object, so that command line can interface with gui
                  windowStorage:obj_new(),$ ; window_storage object, so that command line can interface with gui
                  loadedData:obj_new(), $ ; loaded_data object, so that command line can interface with gui
                  windowMenus:obj_new(), $ ; the window menu object, so that the command line can update the gui window menu
                  historyWin:obj_new(), $ ; the history window object, so that we can log the tplot_gui
                  templatePath:'',$; add the the template path if user specifies one
                  verbose: 2, $ ; verbosity level for SPEDAS
                  oplot_calls:ptr_new(0) };kluge for spd_ui_overplot to prevent overwriting user data, uses an incrementing counter
                  
    defsysv,'!spedas',tmp_struct
  endif

  ftest = spedas_read_config()
  if (keyword_set(reset)) or not (size(ftest, /type) eq 8) then begin ;if it was not saved before or if it is reset
    tmp_struct = {browser_exe: '', $    ; location of the local browser executable
                  temp_dir: '', $
                  temp_cdf_dir: '', $
                  linux_fix: 0b, $
                  renderer:1B,$  ;OS specific rendering options should go here
                  guiId:0L,  $ ; the widget id of the main gui, needed as an input to command line.
                  drawObject:obj_new(),$ ;draw object, so that command line can interface with gui
                  windowStorage:obj_new(),$ ; window_storage object, so that command line can interface with gui
                  loadedData:obj_new(), $ ; loaded_data object, so that command line can interface with gui
                  windowMenus:obj_new(), $ ; the window menu object, so that the command line can update the gui window menu
                  historyWin:obj_new(), $ ; the history window object, so that we can log the tplot_gui
                  templatePath:'',$; add the the template path if user specifies one
                  verbose: 2, $ ; verbosity level for SPEDAS
                  oplot_calls:ptr_new(0) };kluge for spd_ui_overplot to prevent overwriting user data, uses an incrementing counter

    defsysv,'!spedas',tmp_struct
    data_dir =  spd_default_local_data_dir()
    data_dir = StrJoin( StrSplit(data_dir, '\\' , /Regex, /Extract, /Preserve_Null), path_sep())
    data_dir = StrJoin( StrSplit(data_dir, '/', /Regex, /Extract, /Preserve_Null), path_sep())    
    if STRMID(data_dir, 0, 1, /REVERSE_OFFSET) ne path_sep() then data_dir = data_dir + path_sep()
   ; !spedas.local_data_dir = data_dir
    !spedas.temp_dir =  data_dir + 'temp' + path_sep()
    !spedas.temp_cdf_dir =  data_dir + 'cdaweb' + path_sep()
    !spedas.browser_exe = ''
    !spedas.linux_fix = 0
    ;!spedas.init = 1
    print,'Resetting !spedas to default configuration.'
  endif else begin ;retrieved from saved values
    ctags = tag_names(ftest)
    nctags = n_elements(ctags)
    stags = tag_names(!spedas)
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
         dir = spedas_config_filedir()
         dir = strjoin(strsplit(dir, '/', /regex, /extract, /preserve_null), path_sep())
         msg=['The configuration file '+dir+'\spedas_config.txt contains invalid or obsolete fields.', '', 'Would you like a new file automatically generated for you?','', $
         'If not, you will need to modify your existing file before proceeding. Configuration information can be found in the Users Guide.']
         answer = dialog_message(msg, /question)
         if answer EQ 'Yes' then begin
            if strlowcase(!version.os_family) eq 'windows' then begin
                cmd='del '+dir+'\spedas_config.txt'
            endif else begin
                cmd='rm '+dir+'/spedas_config.txt'
            endelse
            spawn, cmd, res, errres
            spedas_init
         endif
         return
      endif 
      if (count gt 0) and not (size(!spedas.(index), /type) eq 11 || size(!spedas.(index), /type) eq 10) then !spedas.(index) = x1
    endfor
    spedas_reset = 0
    print,'Loaded !spedas from saved values.'
  endelse

  if spedas_reset then spedas_write_config ;if i twas just re-loaded from file, we do not re-write the values

  dprint, setverbose=!spedas.verbose
  printdat,/values,!spedas,varname='!spedas'
  
end
