;+
;NAME:
; themis_fileconfig
;
;PURPOSE:
; A widget that allows the user to set some of the fields in the
; !themis system variable: Also allows the user to set the THEMIS
; configuration text file, and save it
;
;HISTORY:
; 17-may-2007, jmm, jimm@ssl.berkeley.edu
; 2-jul-2007, jmm, 'Add trailing slash to data directories, if necessary
; 5-may-2008, cg, removed text boxes and replaced with radio buttons or 
;                 pulldowns, fixed reset to default
; 10-aug-2011, lphilpott, Added option to set a template to load on startup of gui. Changed layout of widgets
;              slightly to make things line up in both windows and linux.
; 24-oct-2013 clr, removed graphic buttons and goes wind and istp code. panel is now tabbed
; 
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-06-19 18:59:28 -0700 (Fri, 19 Jun 2015) $
;$LastChangedRevision: 17927 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/themis_fileconfig.pro $
;--------------------------------------------------------------------------------

;SAVE this routine in the event we want to reinstall the graphics buttons
;pro themis_fileconfig_set_draw,state,renderer;;
;
;  if renderer eq 0 && $
;     strlowcase(!VERSION.os_family) eq 'windows' then begin
;    retain = 2
;  endif else begin
;    retain = 1
;  endelse;

;  *state.drawWinPtr->getProperty,current_zoom=cz,virtual_dimensions=virtual_dimensions
;  dimensions = virtual_dimensions / cz 
;  widget_control,*state.drawIdPtr,/destroy
;  *state.drawIdPtr = WIDGET_DRAW(state.graphBase,/scroll,xsize=dimensions[0],ysize=dimensions[1],$
;                            x_scroll_size=state.screenSize[0],y_scroll_size=state.screenSize[1], $
;                            Frame=3, Motion_Event=1, /Button_Event,keyboard_events=2,graphics_level=2,$
;                            renderer=renderer,retain=retain,/expose_events)
;  widget_control,*state.drawIdPtr,get_value=drawWin

  ;replace the cursor on non-windows system
  ;The cursor also needs to be reset when a new window is created.
  ;ATM This only happens when switching between hardware & software render modes and on init
;  if strlowcase(!version.os_family) ne 'windows' then begin
;    spd_ui_set_cursor,drawWin
;  endif
 
;  *state.drawWinPtr = drawWin 
;  state.drawObject->setProperty,destination=drawWin
;  state.drawObject->setZoom,cz
;  state.drawObject->draw
 
 ; drawWin->setCurrentZoom,cz
;  !spedas.renderer = renderer

;end

;--------------------------------------------------------------------------------



PRO themis_fileconfig_init_struct,state,struct

  compile_opt idl2,hidden

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
  
  if struct.downloadonly eq 1 then begin
    widget_control,state.do_on_button,set_button=1
  endif else begin
    widget_control,state.do_off_button,set_button=1
  endelse

  
  widget_control,state.v_droplist,set_combobox_select=struct.verbose

END

;--------------------------------------------------------------------------------

PRO themis_fileconfig_event, event
  ; Get state structure from the base level 
  Widget_Control, event.handler, Get_UValue=state, /No_Copy
 
  ; get the user value of the widget that caused this event
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message
    state.statusbar->update,'Error in File Config.' 
    state.historywin->update,'Error in File Config.'
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  Widget_Control, event.id, Get_UValue = uval
  
  CASE uval OF
  
    'LOCALBROWSE':BEGIN
    
      widget_control, state.localDir, get_value=currentDir
      if currentDir ne '' then path = file_dirname(currentDir)
      dirName = Dialog_Pickfile(Title='Choose a Local Data Directory:', $
      Dialog_Parent=event.top,path=currentDir, /directory); /fix_filter doesn't seem to make a difference on Windows. Does on unix.  
      IF is_string(dirName) THEN BEGIN
          !THEMIS.local_data_dir = dirName
          widget_control, state.localDir, set_value=dirName             
      ENDIF ELSE BEGIN
        ;  ok = dialog_message('Selection is not a directory',/center)
      ENDELSE
     
    END
    
    'LOCALDIR': BEGIN

        widget_control, state.localDir, get_value=currentDir
        !themis.local_data_dir = currentDir

    END
 
     'REMOTEDIR': BEGIN

        widget_control, state.remoteDir, get_value=currentDir
        !themis.remote_data_dir = currentDir

    END

    'NDON': BEGIN

        IF event.select EQ 1 then !themis.no_download=0 else !themis.no_download=1

    END
    
    'NDOFF': BEGIN

        IF event.select EQ 1 then !themis.no_download=1 else !themis.no_download=0

    END
    
    'NUON': BEGIN

        IF event.select EQ 1 then !themis.no_update=0 else !themis.no_update=1

    END
    
    'NUOFF': BEGIN

        IF event.select EQ 1 then !themis.no_update=1 else !themis.no_update=0

    END
    
    'DOON': BEGIN

      IF event.select EQ 1 then !themis.downloadonly=1 else !themis.downloadonly=0

    END

    'DOOFF': BEGIN

      IF event.select EQ 1 then !themis.downloadonly=0 else !themis.downloadonly=1

    END

    'VERBOSE': BEGIN

       !themis.verbose = long(widget_info(state.v_droplist,/combobox_gettext))

    END
    
    
    'RESET': BEGIN
    
      !themis=state.thm_cfg_save
      widget_control,state.localdir,set_value=!themis.local_data_dir
      widget_control,state.remotedir,set_value=!themis.remote_data_dir
      if !themis.no_download eq 1 then begin
         widget_control,state.nd_off_button,set_button=1
      endif else begin
         widget_control,state.nd_on_button,set_button=1
      endelse  
      if !themis.no_update eq 1 then begin
        widget_control,state.nu_off_button,set_button=1
      endif else begin
        widget_control,state.nu_on_button,set_button=1
      endelse  
      if !themis.downloadonly eq 1 then begin
        widget_control, state.do_on_button, set_button=1
      endif else begin
        widget_Control, state.do_off_button, set_button=1
      endelse
      widget_control,state.v_droplist,set_combobox_select=!themis.verbose
      state.historywin->update,'Resetting controls to saved values.'
      state.statusbar->update,'Resetting controls to saved values.'           
               
; Do not delete in case we reinstall  graphics buttons
;      !spedas.renderer = state.spd_ui_cfg_sav.renderer
;      !spedas.templatepath = state.spd_ui_cfg_sav.templatepath
        
;      if !spedas.renderer eq 0 then begin
;        widget_control,state.gr_hard_button,/set_button
;        themis_fileconfig_set_draw,state,0
;      endif else begin
;        widget_control,state.gr_soft_button,/set_button
;        themis_fileconfig_set_draw,state,1
;      endelse

    END
    
   'RESETTODEFAULT': BEGIN

      thm_init,  /reset      
      themis_fileconfig_init_struct,state,!themis
      state.historywin->update,'Resetting configuration to default values.'
      state.statusbar->update,'Resetting configuration to default values.'

;      Do Not delete may reinstall at later date    
;      !spedas.renderer = 1
;      widget_control,state.gr_soft_button,/set_button
;      themis_fileconfig_set_draw,state,1
    END
    
    'SAVE': BEGIN

       thm_write_config
       state.statusBar->update,'Saved thm_config.txt'
       state.historyWin->update,'Saved thm_config.txt'
       
    END

    ELSE:

  ENDCASE
  
  widget_control, event.handler, set_uvalue=state, /NO_COPY

  RETURN
  
END 

;--------------------------------------------------------------------------------

PRO themis_fileconfig, tab_id, historyWin, statusBar

  defsysv, '!themis', exists=exists
  if not keyword_set(exists) then thm_init
  thm_cfg_save = !themis
  
;Build the widget bases
  master = Widget_Base(tab_id, /col, tab_mode=1,/align_left, /align_top) 

;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, /align_top)
  top = widget_base(vmaster,/row)

;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center, ypad=7)
  ll = max(strlen([!themis.local_data_dir, !themis.remote_data_dir]))+12
;Now create directory text widgets

  configbase = widget_base(vmaster,/col)

  lbase = widget_base(configbase, /row, /align_left, ypad=5)
  flabel = widget_label(lbase, value = 'Local data directory:    ')
  localdir = widget_text(lbase, /edit, /all_events, xsiz = ll, $
                         uval = 'LOCALDIR', val = !themis.local_data_dir)
  loc_browsebtn = widget_button(lbase,value='Browse', uval='LOCALBROWSE',/align_center)

  rbase = widget_base(configbase, /row, /align_left, ypad=5)
  flabel = widget_label(rbase, value = 'Remote data directory: ')
  remotedir = widget_text(rbase, /edit, /all_events, xsiz = ll, $
                          uval = 'REMOTEDIR', val = !themis.remote_data_dir)

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

  ;downloadonly option
  do_base = widget_base(configbase, /row, /align_left)
  do_labelbase = widget_base(do_base, /col, /align_center)
  do_label = widget_label(do_labelbase, value='Load into GUI:', /align_left, xsize=95)
  do_buttonbase = widget_base(do_base, /exclusive, column=2, uval='DO',/align_center)
  do_off_button = widget_button(do_buttonbase, value='Load data', uval='DOOFF', /align_left, xsize=120)
  do_on_button = widget_button(do_buttonbase, value='Download Files Only', uval='DOON', /align_left, xsize=120)

;Verbosity
  v_base = widget_base(configbase, /row, ypad=7)
  v_label = widget_label(v_base, value='Verbose (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_Combobox(v_base, value=v_values, uval='VERBOSE', /align_center)


  ;base for graphics and template
  ; Graphics mode
  ; DO NOT delete in case we want to reinstall grahics buttons
;  gr_base = widget_base(grtemp_base, /row, /align_left)
;  gr_labelbase = widget_base(gr_base,/col,/align_center)
;  gr_label = widget_label(gr_labelbase, value='Graphics Mode:   ',xsize=95,/align_left)
;  gr_buttonbase = widget_base(gr_base, /exclusive, column=2, uval="GR",/align_center)
;  gr_hard_button = widget_button(gr_buttonbase, value='Hardware Render     ', uval='GRHARD',xsize=120,/align_left)
;  gr_soft_button = widget_button(gr_buttonbase, value='Software Render   ', uval='GRSOFT',/align_left)
  
;  if !spedas.renderer then begin
;    widget_control,gr_soft_button,/set_button
;  endif else begin
;    widget_control,gr_hard_button,/set_button
;  endelse


;buttons
  savebut = widget_button(bmaster, value = '   Save To File  ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Cancel     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')
 
  ;store these guys in pointers so that they
  ;are easy to return from event handler

  state = { thm_cfg_save:thm_cfg_save, $
          localdir:localdir, remotedir:remotedir, $
          nd_on_button:nd_on_button, nd_off_button:nd_off_button, $
          nu_on_button:nu_on_button, nu_off_button:nu_off_button, $
          do_on_button:do_on_button, do_off_button:do_off_button, $
          v_values:v_values, v_droplist:v_droplist, statusBar:statusBar, $
          historyWin:historyWin, tab_id:tab_id, master:master}

  themis_fileconfig_init_struct,state,!themis

  Widget_Control, master, Set_UValue=state, /No_Copy
  widget_control, master, /realize
  Widget_Control, widget_info(tab_id, /child), Set_UValue=state, /No_Copy

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, master, xoffset=0, yoffset=0
  endif

  xmanager, 'themis_fileconfig', master, /no_block

END ;--------------------------------------------------------------------------------



