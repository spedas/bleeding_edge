;+
;NAME:
; spd_ui_yyy_fileconfig
;
;PURPOSE:
; A widget that allows the user to set some of the !yyy environmental variables. The user
; can save the changes permanently to file, reset to default values, or cancel any changes
; made since the panel was displayed.
; 
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/file_configuration_tab/spd_ui_yyy_fileconfig.pro $
;--------------------------------------------------------------------------------

pro spd_ui_yyy_init_struct,state,struct

  compile_opt idl2,hidden

  ; Initialize all the widgets on the configuration panel to
  ; the reflect the system variables values (!yyy) 

  widget_control,state.localdir,set_value=struct.local_data_dir
  widget_control,state.remotedir,set_value=struct.remote_data_dir
  
  if struct.no_download eq 1 then begin
    widget_control,state.nd_off_button,set_button=1
  endif else begin
    widget_control,state.nd_on_button,set_button=1
  endelse
  
  if struct.no_update eq 1 then begin
    widget_control,state.nu_off_button,set_button=1
  endif else begin
    widget_control,state.nu_on_button,set_button=1
  endelse
  
  widget_control,state.v_droplist,set_combobox_select=struct.verbose

end

PRO spd_ui_yyy_fileconfig_event, event

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
  
    'LOCALBROWSE':BEGIN

      ; get the local data dir text box value
      widget_control, state.localDir, get_value=currentDir
      if currentDir ne '' then path = file_dirname(currentDir)
      ; call the file chooser window and set the default value
      ; to the current value in the local data dir text box
      dirName = Dialog_Pickfile(Title='Choose a Local Data Directory:', $
      Dialog_Parent=state.master,path=currentDir, /directory, /must_exist)
      ; check to make sure the selection is valid
      IF is_string(dirName) THEN BEGIN
          !yyy.local_data_dir = dirName
          widget_control, state.localDir, set_value=dirName             
      ENDIF ELSE BEGIN
          ok = dialog_message('Selection is not a directory',/center)
      ENDELSE

    END

    'LOCALDIR': BEGIN
    
        widget_control, state.localDir, get_value=currentDir
        !yyy.local_data_dir = currentDir

    END

    'REMOTEDIR': BEGIN
    
        widget_control, state.remoteDir, get_value=currentDir
        !yyy.remote_data_dir = currentDir

    END

    'VERBOSE': BEGIN

       !yyy.verbose = long(widget_info(state.v_droplist,/combobox_gettext))

    END

    'RESET': BEGIN

       ; set the system variable (!yyy) back to the state it was at the 
       ; beginning of the window session. This cancels all changes since
       ; initialization of the configuration window
       !yyy=state.yyy_cfg_save
       widget_control,state.localdir,set_value=!yyy.local_data_dir
       widget_control,state.remotedir,set_value=!yyy.remote_data_dir
       if !yyy.no_download eq 1 then begin
          widget_control,state.nd_off_button,set_button=1
       endif else begin
          widget_control,state.nd_on_button,set_button=1
       endelse  
       if !yyy.no_update eq 1 then begin
         widget_control,state.nu_off_button,set_button=1
       endif else begin
         widget_control,state.nu_on_button,set_button=1
       endelse  
       widget_control,state.v_droplist,set_combobox_select=!yyy.verbose
       state.historywin->update,'Resetting controls to saved values.'
       state.statusbar->update,'Resetting controls to saved values.'           

    END
    
   'RESETTODEFAULT': Begin

      ; to reset all values to their default values the system
      ; variable needs to be reinitialized
      yyy_init,  /reset
      
      ; used the stored default values to set the download
      ; and update variables
      !yyy.no_download = state.def_values[0]
      !yyy.no_update = state.def_values[1]      
      !yyy.downloadonly = state.def_values[2]
      !yyy.verbose = state.def_values[3]

      ; reset the widgets to these values
      widget_control,state.localdir,set_value=!yyy.local_data_dir
      widget_control,state.remotedir,set_value=!yyy.remote_data_dir
      if !yyy.no_download eq 1 then begin
         widget_control,state.nd_off_button,set_button=1
      endif else begin
         widget_control,state.nd_on_button,set_button=1
      endelse  
      if !yyy.no_update eq 1 then begin
        widget_control,state.nu_off_button,set_button=1
      endif else begin
        widget_control,state.nu_on_button,set_button=1
      endelse  
      widget_control,state.v_droplist,set_combobox_select=!yyy.verbose

      state.historywin->update,'Resetting configuration to default values.'
      state.statusbar->update,'Resetting configuration to default values.'

    END
    
    'SAVE': BEGIN

      ; write the values to the text file stored on disk
      ; so the values will be set outside of the panel
      ; and/or gui
      ; these values will also be used each time yyy_init is called
      yyy_write_config 
      state.statusBar->update,'Saved yyy_config.txt'
      state.historyWin->update,'Saved yyy_config.txt'

    END
    
    ELSE:
  ENDCASE
  
  widget_control, event.handler, set_uval = state, /no_copy

Return
END ;--------------------------------------------------------------------------------


PRO spd_ui_yyy_fileconfig, tab_id, historyWin, statusBar

  ;check whether the !yyy system variable has been initialized
  defsysv, 'yyy', exists=exists
  if not keyword_set(exists) then yyy_init
  yyy_cfg_save = !yyy
  
  ;Build the widget bases
  master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top) 

;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, /align_top)
  top = widget_base(vmaster,/row)

;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center, ypad=7)
  ll = max(strlen([!yyy.local_data_dir, !yyy.remote_data_dir]))+12

;Now create directory text widgets
  configbase = widget_base(vmaster,/col)

  lbase = widget_base(configbase, /row, /align_left, ypad=5)
  flabel = widget_label(lbase, value = 'Local data directory:    ')
  localdir = widget_text(lbase, /edit, /all_events, xsiz = 50, $
                         uval = 'LOCALDIR', val = !yyy.local_data_dir)
  loc_browsebtn = widget_button(lbase,value='Browse', uval='LOCALBROWSE',/align_center)

  rbase = widget_base(configbase, /row, /align_left, ypad=5)
  flabel = widget_label(rbase, value = 'Remote data directory: ')
  remotedir = widget_text(rbase, /edit, /all_events, xsiz = 50, $
                          uval = 'REMOTEDIR', val = !yyy.remote_data_dir)

;Next radio buttions
  nd_base = widget_base(configbase, /row, /align_left)
  nd_labelbase = widget_base(nd_base,/col,/align_center)
  nd_label = widget_label(nd_labelbase, value='Download Data:',/align_left, xsize=95)
  nd_buttonbase = widget_base(nd_base, /exclusive, column=2, uval="ND",/align_center)
  nd_on_button = widget_button(nd_buttonbase, value='Automatically    ', uval='NDON',/align_left,xsize=120)
  nd_off_button = widget_button(nd_buttonbase, value='Use Local Data Only', uval='NDOFF',/align_left)

  nubase = widget_base(configbase, /row, /align_left)
  nu_labelbase = widget_base(nubase,/col,/align_center)
  nu_label = widget_label(nu_labelbase, value='Update Files:',/align_left, xsize=95)
  nu_buttonbase = widget_base(nubase, /exclusive, column=2, uval="NU",/align_center)
  nu_on_button = widget_button(nu_buttonbase, value='Update if Newer  ', uval='NUON',/align_left,xsize=120)
  nu_off_button = widget_button(nu_buttonbase, value='Use Local Data Only', uval='NUOFF',/align_left)

  v_base = widget_base(configbase, /row, ypad=7)
  v_label = widget_label(v_base, value='Verbose (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE', /align_center)

  ; buttons to save or reset the widget values
  savebut = widget_button(bmaster, value = '    Save to File     ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')

  ;defaults for Cancel:
  def_values=[0,0,0,2]
  
  state = {localdir:localdir, remotedir:remotedir, yyy_cfg_save:yyy_cfg_save, $
           nd_on_button:nd_on_button, nd_off_button:nd_off_button, $
           nu_on_button:nu_on_button, nu_off_button:nu_off_button, $
           v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, $
           def_values:def_values, historyWin:historyWin, tab_id:tab_id}

  spd_ui_yyy_init_struct,state,!yyy

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif

  xmanager, 'spd_ui_yyy_fileconfig', master, /no_block
  
END ;--------------------------------------------------------------------------------



