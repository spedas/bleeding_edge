;+
;NAME:
; mvn_spd_fileconfig
;PURPOSE:
; A widget that allows the user to set parts of the mvn_file_source
; structure. The user can save the changes permanently to file, reset 
; to default values, or cancel any changes made since the panel was
; displayed.
;HISTORY:
; Hacked from api_examples version, jmm, 2014-12-01, jimm@ssl.berkeley.edu 
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-01-11 11:54:21 -0800 (Mon, 11 Jan 2016) $
;$LastChangedRevision: 19709 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_fileconfig.pro $
;--------------------------------------------------------------------------------

pro mvn_spd_init_struct,state,struct

  compile_opt idl2,hidden

  ; Initialize all the widgets on the configuration panel to
  ; the reflect the system variables values (!maven_spd) 

  widget_control,state.localdir,set_value=struct.local_data_dir
  widget_control,state.remotedir,set_value=struct.remote_data_dir

  if struct.no_server eq 1 then begin
    widget_control,state.nd_off_button,set_button=1
  endif else begin
    widget_control,state.nd_on_button,set_button=1
  endelse
  
  widget_control,state.v_droplist,set_combobox_select=struct.verbose

end

PRO mvn_spd_fileconfig_event, event
  
; No sys variable, but a common block
  common mvn_file_source_com,  psource

; Get State structure from top level base
  Widget_Control, event.handler, Get_UValue=state, /No_Copy

; Catch statement to pick up errors
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
     Catch, /Cancel
     Help, /Last_Message, Output = err_msg  
     If(widget_valid(state.statusbar) && widget_valid(state.historywin)) Then Begin
        state.statusbar->update,'Error in File Config.' 
        state.historywin->update,'Error in File Config.'
     Endif
     Widget_Control, event.TOP, Set_UValue=state, /No_Copy
     widget_control, event.top,/destroy
     RETURN
  ENDIF

; get the user value of the widget that caused this event
  Widget_Control, event.id, Get_UValue = uval
; Make desired changes  
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
           psource.local_data_dir = dirName
           widget_control, state.localDir, set_value=dirName             
        ENDIF ELSE BEGIN
           ok = dialog_message('Selection is not a directory',/center)
        ENDELSE
     END
     'LOCALDIR': BEGIN
        widget_control, state.localDir, get_value=currentDir
        psource.local_data_dir = currentDir
     END
     'REMOTEDIR': BEGIN
        widget_control, state.remoteDir, get_value=currentDir
        psource.remote_data_dir = currentDir
     END
     'NDON': BEGIN
        IF event.select EQ 1 then psource.no_server=0 else psource.no_server=1
     END
     'NDOFF': BEGIN
        IF event.select EQ 1 then psource.no_server=1 else psource.no_server=0
     END
     'VERBOSE': BEGIN
        psource.verbose = long(widget_info(state.v_droplist,/combobox_gettext))
     END
     'RESET': BEGIN
; set the system variable (psource) back to the state it was at the 
; beginning of the window session. This cancels all changes since
; initialization of the configuration window
        psource=state.mvn_spd_cfg_save
        widget_control,state.localdir,set_value=psource.local_data_dir
        widget_control,state.remotedir,set_value=psource.remote_data_dir
        if psource.no_server eq 1 then begin
           widget_control,state.nd_off_button,set_button=1
        endif else begin
           widget_control,state.nd_on_button,set_button=1
        endelse  
        widget_control,state.v_droplist,set_combobox_select=psource.verbose
        If(widget_valid(state.statusbar) && widget_valid(state.historywin)) Then Begin
           state.historywin->update,'Resetting controls to saved values.'
           state.statusbar->update,'Resetting controls to saved values.'
        Endif

     END
     'RESETTODEFAULT': Begin
; to reset all values to their default values the system
; variable needs to be reinitialized
        mvn_spd_init,  /reset
; reset the widgets to these values
        widget_control,state.localdir,set_value=psource.local_data_dir
        widget_control,state.remotedir,set_value=psource.remote_data_dir
        if psource.no_server eq 1 then begin
           widget_control,state.nd_off_button,set_button=1
        endif else begin
           widget_control,state.nd_on_button,set_button=1
        endelse  
        widget_control,state.v_droplist,set_combobox_select=psource.verbose
        If(widget_valid(state.statusbar) && widget_valid(state.historywin)) Then Begin
           state.historywin->update,'Resetting configuration to default values.'
           state.statusbar->update,'Resetting configuration to default values.'
        Endif
     END
     'SAVE': BEGIN
; write the values to the text file stored on disk
; so the values will be set outside of the panel
; and/or gui
; these values will also be used each time mvn_spd_init is called
        mvn_spd_write_config 
        If(widget_valid(state.statusbar) && widget_valid(state.historywin)) Then Begin
           state.statusBar->update,'Saved mvn_spd_config.txt'
           state.historyWin->update,'Saved mvn_spd_config.txt'
        Endif
     END
     ELSE:
  ENDCASE
  
  widget_control, event.handler, set_uval = state, /no_copy

  Return
END ;--------------------------------------------------------------------------------


PRO mvn_spd_fileconfig, tab_id, historyWin, statusBar

;check whether the psource system variable has been initialized
;No sys variable, but a common block
  common mvn_file_source_com,  psource

  If(~is_struct(psource)) Then mvn_spd_init
  mvn_spd_cfg_save = psource
  
;Build the widget bases
  If(~keyword_set(tab_id)) Then Begin
     master = widget_base(/col, tab_mode=1,/align_left, /align_top)
     tab_id = master
     statusbar = 0 & historywin = 0
  Endif Else master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top) 

;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, /align_top)
  top = widget_base(vmaster,/row)

;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center, ypad=7)
  ll = max(strlen([psource.local_data_dir, psource.remote_data_dir]))+12

;Now create directory text widgets
  configbase = widget_base(vmaster,/col)

  lbase = widget_base(configbase, /row, /align_left, ypad=5)
  flabel = widget_label(lbase, value = 'Local data directory:    ')
  localdir = widget_text(lbase, /edit, /all_events, xsiz = 50, $
                         uval = 'LOCALDIR', val = psource.local_data_dir)
  loc_browsebtn = widget_button(lbase,value='Browse', uval='LOCALBROWSE',/align_center)

  rbase = widget_base(configbase, /row, /align_left, ypad=5)
  flabel = widget_label(rbase, value = 'Remote data directory: ')
  remotedir = widget_text(rbase, /edit, /all_events, xsiz = 50, $
                          uval = 'REMOTEDIR', val = psource.remote_data_dir)

;Next radio buttions
  nd_base = widget_base(configbase, /row, /align_left)
  nd_labelbase = widget_base(nd_base,/col,/align_center)
  nd_label = widget_label(nd_labelbase, value='Download Data:',/align_left, xsize=95)
  nd_buttonbase = widget_base(nd_base, /exclusive, column=2, uval="ND",/align_center)
  nd_on_button = widget_button(nd_buttonbase, value='Automatically    ', uval='NDON',/align_left,xsize=120)
  nd_off_button = widget_button(nd_buttonbase, value='Use Local Data Only', uval='NDOFF',/align_left)

  v_base = widget_base(configbase, /row, ypad=7)
  v_label = widget_label(v_base, value='Verbose (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE', /align_center)

  ; buttons to save or reset the widget values
  savebut = widget_button(bmaster, value = '    Save to File     ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')

  ;defaults for Cancel:
  def_values=[psource.no_server, psource.verbose]
  
  state = {localdir:localdir, remotedir:remotedir, mvn_spd_cfg_save:mvn_spd_cfg_save, $
           nd_on_button:nd_on_button, nd_off_button:nd_off_button, $
           v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, $
           def_values:def_values, historyWin:historyWin, tab_id:tab_id}

  mvn_spd_init_struct,state,psource

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize

  ;keep windows in X11 from snapping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif

  xmanager, 'mvn_spd_fileconfig', master, /no_block
  
END ;--------------------------------------------------------------------------------



