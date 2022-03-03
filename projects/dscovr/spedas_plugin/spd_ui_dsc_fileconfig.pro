;+
;NAME:
; spd_ui_dsc_fileconfig
;
;PURPOSE:
; A widget that allows the user to set some of the !dsc environmental variables. The user
; can save the changes permanently to file, reset to default values, or cancel any changes
; made since the panel was displayed.
; 
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2022-03-01 19:31:19 -0800 (Tue, 01 Mar 2022) $
; $LastChangedRevision: 30640 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/spedas_plugin/spd_ui_dsc_fileconfig.pro $
;--------------------------------------------------------------------------------

pro spd_ui_dsc_init_struct,state,struct

	compile_opt idl2,hidden

	; Initialize all the widgets on the configuration panel to
	; the reflect the system variables values (!dsc) 

	widget_control,state.localdir,set_value=struct.local_data_dir
	widget_control,state.remotedir,set_value=struct.remote_data_dir
	widget_control,state.plotsdir,set_value=struct.save_plots_dir
	
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
	
	v_idx = where(['0','1','2','4'] eq struct.verbose.toString(),count)
	v_idx = (count gt 0) ? v_idx[0] : 2
	widget_control,state.v_droplist,set_combobox_select=v_idx
end

PRO spd_ui_dsc_fileconfig_event, event

	compile_opt idl2
	
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
				!dsc.local_data_dir = dirName
				widget_control, state.localDir, set_value=dirName             
			ENDIF ELSE BEGIN
				ok = dialog_message('Selection is not a directory',/center)
			ENDELSE

		END

		'LOCALDIR': BEGIN
		
			widget_control, state.localDir, get_value=currentDir
			!dsc.local_data_dir = currentDir

		END

		'REMOTEDIR': BEGIN
		
			widget_control, state.remoteDir, get_value=currentDir
			!dsc.remote_data_dir = currentDir

		END

		'PLOTSBROWSE':BEGIN

			; get the plots save dir text box value
			widget_control, state.plotsdir, get_value=currentDir
			if currentDir ne '' then path = file_dirname(currentDir)
			; call the file chooser window and set the default value
			; to the current value in the local data dir text box
			dirName = Dialog_Pickfile(Title='Choose a Plots Save Directory:', $
				Dialog_Parent=state.master,path=currentDir, /directory, /must_exist)
			; check to make sure the selection is valid
			IF is_string(dirName) THEN BEGIN
				!dsc.save_plots_dir = dirName
				widget_control, state.plotsdir, set_value=dirName
			ENDIF ELSE BEGIN
				ok = dialog_message('Selection is not a directory',/center)
			ENDELSE

		END

		'PLOTSDIR': BEGIN

			widget_control, state.plotsdir, get_value=currentDir
			!dsc.save_plots_dir = currentDir

		END
		
		'NDON': BEGIN

			IF event.select EQ 1 then !dsc.no_download=0 else !dsc.no_download=1

		END

		'NDOFF': BEGIN

			IF event.select EQ 1 then !dsc.no_download=1 else !dsc.no_download=0

		END

		'NUON': BEGIN

			IF event.select EQ 1 then !dsc.no_update=0 else !dsc.no_update=1

		END

		'NUOFF': BEGIN

			IF event.select EQ 1 then !dsc.no_update=1 else !dsc.no_update=0

		END
		
		'VERBOSE': BEGIN

			!dsc.verbose = long(widget_info(state.v_droplist,/combobox_gettext))

		END

		'RESET': BEGIN

			; set the system variable (!dsc) back to the state it was at the 
			; beginning of the window session. This cancels all changes since
			; initialization of the configuration window
			!dsc=state.dsc_cfg_save
			widget_control,state.localdir,set_value=!dsc.local_data_dir
			widget_control,state.remotedir,set_value=!dsc.remote_data_dir
			widget_control,state.plotsdir,set_value=!dsc.SAVE_PLOTS_DIR
			if !dsc.no_download eq 1 then begin
				widget_control,state.nd_off_button,set_button=1
			endif else begin
				widget_control,state.nd_on_button,set_button=1
			endelse  
			if !dsc.no_update eq 1 then begin
				widget_control,state.nu_off_button,set_button=1
			endif else begin
				widget_control,state.nu_on_button,set_button=1
			endelse  
			v_idx = where(['0','1','2','4'] eq struct.verbose.toString(),count)
			v_idx = (count gt 0) ? v_idx[0] : 2
			widget_control,state.v_droplist,set_combobox_select=v_idx
			state.historywin->update,'Resetting controls to saved values.'
			state.statusbar->update,'Resetting controls to saved values.'           

		END
		
		'RESETTODEFAULT': Begin

			; to reset all values to their default values the system
			; variable needs to be reinitialized
			dsc_init,  /reset
			
			; reset the widgets to these values
			widget_control,state.localdir,set_value=!dsc.local_data_dir
			widget_control,state.remotedir,set_value=!dsc.remote_data_dir
			widget_control,state.plotsdir,set_value=!dsc.save_plots_dir
			if !dsc.no_download eq 1 then begin
				widget_control,state.nd_off_button,set_button=1
			endif else begin
				widget_control,state.nd_on_button,set_button=1
			endelse  
			if !dsc.no_update eq 1 then begin
				widget_control,state.nu_off_button,set_button=1
			endif else begin
				widget_control,state.nu_on_button,set_button=1
			endelse  
			widget_control,state.v_droplist,set_combobox_select=!dsc.verbose

			state.historywin->update,'Resetting configuration to default values.'
			state.statusbar->update,'Resetting configuration to default values.'

		END
		
		'SAVE': BEGIN

			; write the values to the text file stored on disk
			; so the values will be set outside of the panel
			; and/or gui
			; these values will also be used each time dsc_init is called
			dsc_write_config 
			state.statusBar->update,'Saved dsc_config.txt'
			state.historyWin->update,'Saved dsc_config.txt'

		END
		
		ELSE:
	ENDCASE
	
	widget_control, event.handler, set_uval = state, /no_copy

Return
END ;--------------------------------------------------------------------------------


PRO spd_ui_dsc_fileconfig, tab_id, historyWin, statusBar

	compile_opt idl2
	
	;check whether the !dsc system variable has been initialized
	defsysv, '!dsc', exists=exists
	if not keyword_set(exists) then dsc_init
	dsc_cfg_save = !dsc
	
	;Build the widget bases
	master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top) 

;widget base for values to set
	vmaster = widget_base(master, /col, /align_left, /align_top)
	top = widget_base(vmaster,/row)

;Widget base for save, reset and exit buttons
	bmaster = widget_base(master, /row, /align_center, ypad=7)
	ll = max(strlen([!dsc.local_data_dir, !dsc.remote_data_dir]))+12

;Now create directory text widgets
	configbase = widget_base(vmaster,/col)

	lbase = widget_base(configbase, /row, /align_left, ypad=5)
	flabel = widget_label(lbase, value = 'Local data directory:    ')
	localdir = widget_text(lbase, /edit, /all_events, xsiz = 50, $
												 uval = 'LOCALDIR', val = !dsc.local_data_dir)
	loc_browsebtn = widget_button(lbase,value='Browse', uval='LOCALBROWSE',/align_center)

	rbase = widget_base(configbase, /row, /align_left, ypad=5)
	flabel = widget_label(rbase, value = 'Remote data directory: ')
	remotedir = widget_text(rbase, /edit, /all_events, xsiz = 50, $
													uval = 'REMOTEDIR', val = !dsc.remote_data_dir)

	pbase = widget_base(configbase, /row, /align_left, ypad=5)
	flabel = widget_label(pbase, value = 'Plots save directory:    ')
	plotsdir = widget_text(pbase, /edit, /all_events, xsiz = 50, $
												uval = 'PLOTSDIR', val = !dsc.save_plots_dir)
	plt_browsebtn = widget_button(pbase,value='Browse', uval='PLOTSBROWSE',/align_center)

;Next radio buttions
	nd_base = widget_base(configbase, /row, /align_left)
	nd_labelbase = widget_base(nd_base,/col,/align_center)
	nd_label = widget_label(nd_labelbase, value='Download Data:',/align_left)
	nd_buttonbase = widget_base(nd_base, /exclusive, column=2, uval="ND",/align_center)
	nd_on_button = widget_button(nd_buttonbase, value='Automatically    ', uval='NDON',/align_left)
	nd_off_button = widget_button(nd_buttonbase, value='Use Local Data Only', uval='NDOFF',/align_left)

	nubase = widget_base(configbase, /row, /align_left)
	nu_labelbase = widget_base(nubase,/col,/align_center)
	nu_label = widget_label(nu_labelbase, value='Update Files:',/align_left)
	nu_buttonbase = widget_base(nubase, /exclusive, column=2, uval="NU",/align_center)
	nu_on_button = widget_button(nu_buttonbase, value='Update if Newer  ', uval='NUON',/align_left)
	nu_off_button = widget_button(nu_buttonbase, value='Use Local Data Only', uval='NUOFF',/align_left)

	v_base = widget_base(configbase, /row, ypad=7)
	v_values = ['0','1','2','4']
	v_label_text = 'Verbosity level (higher number = more output):        '
	v_label = widget_label(v_base, value=v_label_text)
	v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE')

	; buttons to save or reset the widget values
	savebut = widget_button(bmaster, value = '    Save to File     ', uvalue = 'SAVE')
	resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
	reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')

	
	state = { $
		localdir:localdir, remotedir:remotedir, plotsdir:plotsdir, $
		dsc_cfg_save:dsc_cfg_save, $
		nd_on_button:nd_on_button, nd_off_button:nd_off_button, $
		nu_on_button:nu_on_button, nu_off_button:nu_off_button, $
		v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, $
		historyWin:historyWin, tab_id:tab_id, master:master}

	spd_ui_dsc_init_struct,state,!dsc

	widget_control, master, set_uval = state, /no_copy
	widget_control, master, /realize

	;keep windows in X11 from snaping back to 
	;center during tree widget events 
	if !d.NAME eq 'X' then begin
		widget_control, master, xoffset=0, yoffset=0
	endif

	xmanager, 'spd_ui_dsc_fileconfig', master, /no_block
	
END ;--------------------------------------------------------------------------------
