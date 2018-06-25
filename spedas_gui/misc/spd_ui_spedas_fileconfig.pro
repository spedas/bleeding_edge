;+
;NAME:
; spd_ui_spedas_fileconfig
;
;PURPOSE:
; A widget that allows the user to set some of the !spedas environmental variables. The user
; can save the changes permanently to file, reset to default values, or cancel any changes
; made since the panel was displayed.
;
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-06-01 11:07:18 -0700 (Fri, 01 Jun 2018) $
;$LastChangedRevision: 25311 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/misc/spd_ui_spedas_fileconfig.pro $
;--------------------------------------------------------------------------------

PRO spd_ui_fileconfig_load_template, fileName, topid, statusBar

  if(Is_String(fileName)) then begin
    open_spedas_template,template=template,filename=fileName,$
      statusmsg=statusmsg,statuscode=statuscode
    if (statuscode LT 0) then begin
      ok=dialog_message(statusmsg,/ERROR,/CENTER)
      statusBar->Update, 'Error: '+statusmsg
    endif else begin
      !spedas.templatepath = fileName
      tmppathid = widget_info(topid, find_by_uname='TMPPATH')
      widget_control, tmppathid,set_value=filename
      !spedas.windowStorage->setProperty,template=template
    ENDELSE
  ENDIF ELSE BEGIN
    statusBar->Update, 'Failed to load template: invalid filename'
  ENDELSE

END

;--------------------------------------------------------------------------------

pro spd_ui_spedas_init_struct,state,struct

  compile_opt idl2,hidden
  
  ; Initialize all the widgets on the configuration panel to
  ; the reflect the system variables values (!spedas)
  
  widget_control,state.tempdir,set_value=struct.temp_dir
  widget_control,state.browserexe,set_value=struct.browser_exe
  widget_control,state.tempcdfdir,set_value=struct.temp_cdf_dir  
  widget_control,state.geoparamdir,set_value=struct.geopack_param_dir
  ;widget_control,state.v_droplist,set_combobox_select=struct.verbose
  Widget_Control,  state.fixlinux, Set_Button=struct.linux_fix

  if !spedas.templatepath ne '' then begin
    widget_control, state.tmp_button,/set_button
    widget_control, state.tmp_pathbase, sensitive=1
    widget_control, state.tmppath, /editable
    widget_control, state.tmppath, /sensitive, set_value = !spedas.templatepath
  endif else begin
    widget_control, state.tmp_pathbase, sensitive=0
  endelse

end

PRO spd_ui_spedas_fileconfig_event, event

  ; Get State structure from top level base
  Widget_Control, event.handler, Get_UValue=state, /No_Copy
  
  ; get the user value of the widget that caused this event
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    state.statusbar->update,'Error in File Config.'
    state.historywin->update,'Error in File Config.'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  Widget_Control, event.id, Get_UValue = uval
  
  CASE uval OF
    
    'USETMP': BEGIN

      btnid = widget_info(event.top,find_by_uname='TMPBUTTON')
      usetemplate = widget_info(btnid, /button_set)
      widget_control, (widget_info(event.top,find_by_uname='TMPPATHBASE')), sensitive=usetemplate
      if usetemplate then begin
        ; if the user turns on template, then load it
        widget_control, (widget_info(event.top,find_by_uname='TMPPATH')), /editable
        tmppathid = widget_info(event.top, find_by_uname='TMPPATH')
        widget_control, tmppathid, get_value=filename
        if filename ne '' then spd_ui_fileconfig_load_template, filename, event.top, state.statusBar
        state.historywin->update,'Using template ' + filename
      endif else begin
        ; if the user turns off template, close it
        !spedas.templatepath = ''
        !spedas.windowStorage->setProperty,template=obj_new('spd_ui_template')
        state.statusbar->update,'Template disabled.'
        state.historywin->update,'Template disabled.'
      endelse

    END 
    
    'FIXLINUX': BEGIN      
      id = widget_info(event.top, find_by_uname='FIXLINUX')
      linux_fix = widget_info(id,/button_set)  
      !spedas.linux_fix =  fix(linux_fix)   
      spd_ui_fix_performance, !spedas.linux_fix
    END
  
    'BROWSEREXEBTN':BEGIN
    
    ; get the web browser executable file
    widget_control, state.browserexe, get_value=browser_exe
    if browser_exe ne '' then path = file_dirname(browser_exe)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the web browser executable file:', $
      Dialog_Parent=state.master, /must_exist)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.browser_exe = dirName
      widget_control, state.browserexe, set_value=dirName
    ENDIF ELSE BEGIN
      ;ok = dialog_message('No file was selected',/center)
    ENDELSE
    
  END
  
  'BROWSEREXE': BEGIN

    widget_control, state.browserexe, get_value=currentDir
    !spedas.browser_exe = currentDir

  END
  
  'ROOTHELP': BEGIN

    message = 'This field displays the current value of the ROOT_DATA_DIR '+ $
              'environment variable.  If present, most missions will use it '+ $
              'as their default local data directory.'

    spd_ui_message, message, /dialog, /info, title='Root Data Directory' 

  END

  'TEMPCDFDIR': BEGIN

    widget_control, state.tempcdfdir, get_value=currentDir
    !spedas.temp_cdf_dir = currentDir

  END

  'TEMPCDFDIRBTN': BEGIN

    widget_control, state.tempcdfdir, get_value=currentDir
    if currentDir ne '' then path = file_dirname(currentDir)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the directory for CDF files:', $
      Dialog_Parent=state.master, /must_exist, /DIRECTORY)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.temp_cdf_dir = dirName
      widget_control, state.tempcdfdir, set_value=dirName
    ENDIF ELSE BEGIN
      ; ok = dialog_message('Selection is not a directory',/center)
    ENDELSE


  END
  
  'GEOPARAMDIR': BEGIN

    widget_control, state.geoparamdir, get_value=currentDir
    !spedas.geopack_param_dir = currentDir

  END
  
  'GEOPARAMDIRBTN': BEGIN

    widget_control, state.geoparamdir, get_value=currentDir
    if currentDir ne '' then path = file_dirname(currentDir)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the directory for Geopack parameter files:', $
      Dialog_Parent=state.master, /must_exist, /DIRECTORY)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.geopack_param_dir = dirName
      widget_control, state.geoparamdir, set_value=dirName
    ENDIF ELSE BEGIN
     ; ok = dialog_message('Selection is not a directory',/center)
    ENDELSE


  END
  
  
    'TEMPDIR': BEGIN

    widget_control, state.tempDir, get_value=currentDir
    !spedas.temp_dir = currentDir

  END
  
  'TEMPDIRBTN': BEGIN
  
    widget_control, state.tempDir, get_value=currentDir
    if currentDir ne '' then path = file_dirname(currentDir)
    ; call the file chooser window and set the default value
    ; to the current value in the local data dir text box
    dirName = Dialog_Pickfile(Title='Select the directory for temp files:', $
      Dialog_Parent=state.master, /must_exist, /DIRECTORY)
    ; check to make sure the selection is valid
    IF is_string(dirName) THEN BEGIN
      !spedas.temp_dir = dirName
      widget_control, state.tempDir, set_value=dirName
    ENDIF ELSE BEGIN
     ; ok = dialog_message('Selection is not a directory',/center)
    ENDELSE
    
    
  END
  
  'VERBOSE': BEGIN
  
    !spedas.verbose = long(widget_info(state.v_droplist,/combobox_gettext))
    dprint, setverbose=!spedas.verbose
    
  END
  
  'RESET': BEGIN
  
    ; set the system variable (!spedas) back to the state it was at the
    ; beginning of the window session. This cancels all changes since
    ; initialization of the configuration window
    !spedas=state.spedas_cfg_save
    widget_control,state.browserexe,set_value=!spedas.browser_exe
    widget_control,state.tempdir,set_value=!spedas.temp_dir
    widget_control,state.tempcdfdir,set_value=!spedas.temp_cdf_dir
    widget_control,state.geoparamdir,set_value=!spedas.geopack_param_dir
    Widget_Control, state.fixlinux, Set_Button=!spedas.linux_fix
    
    !spedas.templatepath = ''
    widget_control, (widget_info(event.top, find_by_uname='TMPPATH')), set_value=''
    widget_control, (widget_info(event.top, find_by_uname='TMPBUTTON')), set_button=0
    widget_control, (widget_info(event.top, find_by_uname='TMPPATHBASE')), sensitive = 0

    state.spd_ui_cfg_sav = !spedas
    ;state.spedas_cfg_save = !spedas        
    
   ; widget_control,state.v_droplist,set_combobox_select=!spedas.verbose
    state.historywin->update,'Resetting controls to saved values.'
    state.statusbar->update,'Resetting controls to saved values.'
    
  END
  
  
  'TMPBROWSE':BEGIN

  tmppathid = widget_info(event.top, find_by_uname='TMPPATH')
  widget_control, tmppathid, get_value=currentfile
  if currentfile ne '' then path = file_dirname(currentfile)
  fileName = Dialog_Pickfile(Title='Choose SPEDAS Template:', $
    Filter='*.tgt',Dialog_Parent=event.top,file=filestring,path=path, /must_exist,/fix_filter); /fix_filter doesn't seem to make a difference on Windows. Does on unix.
  ; load the template
  spd_ui_fileconfig_load_template, filename, event.top, state.statusBar    

END
  
  'RESETTODEFAULT': Begin
  
    ; to reset all values to their default values the system
    ; variable needs to be reinitialized
    spedas_init,  /reset
    spd_ui_spedas_init_struct, state, !spedas
       
    !spedas.templatepath = ''
    widget_control, (widget_info(event.top, find_by_uname='TMPPATH')), set_value=''
    widget_control, (widget_info(event.top, find_by_uname='TMPBUTTON')), set_button=0
    widget_control, (widget_info(event.top, find_by_uname='TMPPATHBASE')), sensitive = 0
 
    state.spd_ui_cfg_sav = !spedas
    state.spedas_cfg_save = !spedas
    
    state.historywin->update,'Resetting configuration to default values.'
    state.statusbar->update,'Resetting configuration to default values.'
    
  END
  
  'SAVE': BEGIN
  
    ; write the values to the text file stored on disk
    ; so the values will be set outside of the panel
    ; and/or gui
    ; these values will also be used each time spedas_init is called 
    
    spedas_write_config
    state.statusBar->update,'Saved spedas_config.txt'
    state.historyWin->update,'Saved spedas_config.txt'
    
  END
  
  ELSE:
ENDCASE

widget_control, event.handler, set_uval = state, /no_copy

Return
END ;--------------------------------------------------------------------------------


PRO spd_ui_spedas_fileconfig, tab_id, historyWin, statusBar

  ;check whether the !spedas system variable has been initialized
  defsysv, '!spedas', exists=exists
  if not keyword_set(exists) then spedas_init
  spedas_cfg_save = !spedas
  spd_ui_cfg_sav = !spedas
  linux_fix = !spedas.linux_fix 
  
  ;Build the widget bases
  master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top)
  
  ;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, /align_top)
  top = widget_base(vmaster,/row)
  
  ;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center, ypad=7)
 ; ll = max(strlen([!spedas.local_data_dir, !spedas.remote_data_dir]))+12
  
  ;Now create directory text widgets
  configbase = widget_base(vmaster,/col)
  gbase = widget_base(configbase, /row, /align_left, ypad=3)
  genlabel = widget_label(gbase, value = 'General Settings for SPEDAS    ')
  
  lbase = widget_base(configbase, /row, /align_left, ypad=1)
  flabel = widget_label(lbase,  value = 'Web browser executable:  ')
  browserexe = widget_text(lbase, /edit, xsiz = 50, /all_events, uval='BROWSEREXE', val = !spedas.browser_exe)
  loc_browsebtn = widget_button(lbase,value='Browse', uval='BROWSEREXEBTN',/align_center)
  
  rbase = widget_base(configbase, /row, /align_left, ypad=1)
  flabel1 = widget_label(rbase, value = 'Temp directory:  ')
  tempdir = widget_text(rbase, /edit, xsiz = 50, /all_events, uval='TEMPDIR', val = !spedas.temp_dir)
  temp_dirbtn = widget_button(rbase,value='Browse', uval='TEMPDIRBTN', /align_center)

  rbase1 = widget_base(configbase, /row, /align_left, ypad=1)  
  flabel2 = widget_label(rbase1, value = 'Directory for CDAWeb files:  ')
  tempcdfdir = widget_text(rbase1, /edit, xsiz = 50, /all_events, uval='TEMPCDFDIR', val = !spedas.temp_cdf_dir)
  tempcdfdirbtn = widget_button(rbase1,value='Browse', uval='TEMPCDFDIRBTN', /align_center)

  rbase2 = widget_base(configbase, /row, /align_left, ypad=1)
  flabe22 = widget_label(rbase2, value = 'Directory for Geopack params: ')
  geoparamdir = widget_text(rbase2, /edit, xsiz = 50, /all_events, uval='GEOPARAMDIR', val = !spedas.geopack_param_dir)
  geoparamdirbtn = widget_button(rbase2,value='Browse', uval='GEOPARAMDIRBTN', /align_center)
  
  root_base = widget_base(configbase, /row, /align_left, ypad=1)  
  root_label = widget_label(root_base, value='Root Data Directory:  ')
  root_dir_text = widget_text(root_base, xsize=50, value=getenv('ROOT_DATA_DIR'))
  root_dir_help = widget_button(root_base, value=' ? ',uval='ROOTHELP')
  
  ;dynamically ensure label sizes are equal
  label_xsize = 0
  dir_labels = [flabel, flabel1, flabel2, root_label]
  for i=0, n_elements(dir_labels)-1 do begin
    geo = widget_info(dir_labels[i],/geo)
    label_xsize = geo.scr_xsize > label_xsize
  endfor
  for i=0, n_elements(dir_labels)-1 do begin
    widget_control, dir_labels[i], xsize=label_xsize, units=0
  endfor

  v_base = widget_base(configbase, /row, ypad=7)
  v_label = widget_label(v_base, value='Verbose level for tplot (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE', /align_center)
  widget_control, v_droplist, set_combobox_select=!spedas.verbose
  
  n_base = widget_base(configbase,/row,/nonexclusive,uval='FL')
  fixlinux = widget_button(n_base,value=' Fix drawing performance  ',uval='FIXLINUX',uname='FIXLINUX', tooltip="For Linux only, disables STROKED_LINES to improve IDL 8.3 perfomance") 
  Widget_Control, fixlinux, Set_Button=!spedas.linux_fix 
  
  ; buttons to save or reset the widget values
  savebut = widget_button(bmaster, value = '    Save to File     ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')
      
  ; Template
  grtemp_base = widget_base(vmaster,/col,/align_left)
  tmp_base = widget_base(grtemp_base, row=2,/align_left,uname='TMPBASE')
  tmp_labelbase = widget_base(tmp_base, /align_center,/col)
  tmp_label = widget_label(tmp_labelbase, value='Template:            ',/align_left,xsize=97)
  tmp_buttonbase = widget_base(tmp_base,/row,/nonexclusive,uval='TMP',/align_center)
  tmp_button = widget_button(tmp_buttonbase,value='Load Template',uval='USETMP',uname='TMPBUTTON')

  tmp_pathbase = widget_base(tmp_base,/row,/align_center,uname='TMPPATHBASE')
  tmp_label = widget_label(tmp_pathbase, value='',xsize=100)
  tmppath = widget_text(tmp_pathbase, xsize = 56, $
    uval = 'TMPPATH',uname='TMPPATH',/align_center)
  tmp_browsebtn = widget_button(tmp_pathbase,value='Browse', uval='TMPBROWSE',/align_center)
  
  ;defaults for Cancel:
  def_values=['0','0','0','2',0]
  
  state = {spedas_cfg_save:spedas_cfg_save, spd_ui_cfg_sav:spd_ui_cfg_sav, $
    master:master, browserexe:browserexe, tempdir:tempdir, tempcdfdir:tempcdfdir, geoparamdir:geoparamdir, $
    v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, fixlinux:fixlinux, $
    def_values:def_values, historyWin:historyWin, tab_id:tab_id, linux_fix:linux_fix, $
    tmp_pathbase:tmp_pathbase, tmppath:tmppath, tmp_button:tmp_button, tmp_browsebtn:tmp_browsebtn}
    
  spd_ui_spedas_init_struct,state,!spedas
  
  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  
  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif
  
  xmanager, 'spd_ui_spedas_fileconfig', master, /no_block
  
END ;--------------------------------------------------------------------------------



