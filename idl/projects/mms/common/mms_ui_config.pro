;+
;NAME:
; mms_ui_config
; 
;PURPOSE:
; A widget that allows the user to set some of the fields in the
; !mms system variable: Also allows the user to set the mms
; configuration text file, and save it
; 
;HISTORY:
; 17-may-2007, jmm, jimm@ssl.berkeley.edu
; 2-jul-2007, jmm, 'Add trailing slash to data directories, if necessary
; 5-may-2008, cg, removed text boxes and replaced with radio buttons or
;                 pulldowns, fixed reset to default
; 11-feb-2009, jmm, restored old version
; 11-jan-2019, egrimes, forked for MMS
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-01-11 12:28:10 -0800 (Fri, 11 Jan 2019) $
;$LastChangedRevision: 26454 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_ui_config.pro $
;-

Pro mms_ui_config_temp_mess, id, text_in, _extra = _extra
  widget_control, id, get_uval = state, /no_copy
  widget_control, state.messw, set_val = text_in
  widget_control, id, set_uval = state, /no_copy
  If(obj_valid(!mms.progobj)) Then $
    !mms.progobj -> update, 0.0, /history_too, text = text_in, _extra = _extra
  Return
End

Pro mms_ui_config_event, event
  widget_control, event.id, get_uval = uval
  Case uval Of
    'LOCALDIR': Begin
      widget_control, event.id, get_val = temp_string
      temp_string = strtrim(temp_string, 2)
      ll = strmid(temp_string, strlen(temp_string)-1, 1)
      If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
      !mms.local_data_dir = temporary(temp_string)
      mms_ui_config_temp_mess, event.top, '!mms.local_data_dir = '+!mms.local_data_dir, /nocomment
    End
    'MIRRORDIR': Begin
      widget_control, event.id, get_val = temp_string
      temp_string = strtrim(temp_string, 2)
      ll = strmid(temp_string, strlen(temp_string)-1, 1)
      If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
      !mms.mirror_data_dir = temporary(temp_string)
      mms_ui_config_temp_mess, event.top, '!mms.mirror_data_dir = '+!mms.mirror_data_dir, /nocomment
    End
    'NDON':Begin
       !mms.no_download = 0
       mms_ui_config_temp_mess, event.top, '!mms.no_download = 0', /nocomment
    end
    'NDOFF':Begin
       !mms.no_download = 1
       mms_ui_config_temp_mess, event.top, '!mms.no_download = 1', /nocomment
    end
    'NUON':Begin
       !mms.no_update = 0
       mms_ui_config_temp_mess, event.top, '!mms.no_update = 0', /nocomment
    end
    'NUOFF':Begin
       !mms.no_update = 1
       mms_ui_config_temp_mess, event.top, '!mms.no_update = 1', /nocomment
    end
    'NDOON':Begin
       !mms.downloadonly = 0
       mms_ui_config_temp_mess, event.top, '!mms.downloadonly = 0', /nocomment
    end
    'NDOOFF':Begin
       !mms.downloadonly = 1
       mms_ui_config_temp_mess, event.top, '!mms.downloadonly = 1', /nocomment
    end
    'VERBOSE': Begin
       widget_control, event.id
       !mms.verbose= event.index
       vmessage='!mms.verbose = '+ string(!mms.verbose)
       mms_ui_config_temp_mess, event.top, vmessage, /nocomment
       ; NB: above sets !mms.verbose for error printing. This is not consistently used, so also set dprint level
       dprint, setdebug=event.index
    end
    'RESET': Begin
      mms_ui_config_temp_mess, event.top, 'Restoring Original Configuration'
      widget_control, event.top, get_uval = state, /no_copy
      !mms = state.mms_cfg_sav
      widget_control, state.localdir, set_val = !mms.local_data_dir
      widget_control, state.mirrordir, set_val = !mms.mirror_data_dir
      if (!mms.no_download eq 0) then $
         widget_control, state.nd_on_button, /set_button $
         else widget_control, state.nd_off_button, /set_button
      if (!mms.no_update eq 0) then $
         widget_control, state.nu_on_button, /set_button $
         else widget_control, state.nu_off_button, /set_button
      if (!mms.downloadonly eq 0) then $
         widget_control, state.ndo_on_button, /set_button $
         else widget_control, state.ndo_off_button, /set_button
      widget_control, state.v_droplist, set_droplist_select = !mms.verbose
      widget_control, event.top, set_uval = state, /no_copy
    End
   'RESETTODEFAULT': Begin
      dir =  mms_config_filedir(/app_query)
      If(dir[0] Ne '') Then Begin
;Is there a trailing slash? Not for linux or windows, not sure about
;Mac
        ll =  strmid(dir, strlen(dir)-1, 1)
        If(ll Eq '/' Or ll Eq '\') Then filex =  dir+'mms_config.txt' $
        Else filex =  dir+'/'+'mms_config.txt'
        fff=file_search(filex)
;Does the file exist? If so, delete it
        If (is_string(fff)) Then file_delete, fff[0], /noexpand_path
      Endif
      mms_ui_config_temp_mess, event.top, 'Restoring Default Configuration'
;No config file, so just run mms_init

      mms_init,  /reset
;Now you need to put the valuse that you have back into the widget
      widget_control,  event.top,  get_uval =  state,  /no_copy
      widget_control,  state.localdir,  set_val =  !mms.local_data_dir
      widget_control,  state.mirrordir,  set_val =  !mms.mirror_data_dir
      if (state.def_values(0) eq 0) then $
         widget_control, state.nd_on_button, /set_button $
         else widget_control, state.nd_off_button, /set_button
      !mms.no_download = state.def_values(0)
      if (state.def_values(1) eq 0) then $
         widget_control, state.nu_on_button, /set_button $
         else widget_control, state.nu_off_button, /set_button
      !mms.no_update = state.def_values(1)      
      if (state.def_values(2) eq 0) then $
         widget_control, state.ndo_on_button, /set_button $
         else widget_control, state.ndo_off_button, /set_button
      !mms.downloadonly = state.def_values(2)
      !mms.verbose = state.def_values(3)
      widget_control, state.v_droplist, set_droplist_select = state.def_values(3)
      widget_control,  event.top,  set_uval =  state,  /no_copy
    End
    'SAVE': Begin
      mms_config_write, !mms
      filex = mms_config_filedir(/app_query)+'/'+'mms_config.txt'
      mms_ui_config_temp_mess, event.top, 'Saved New Configuration file: '+filex
    End
    'EXIT': Begin
      widget_control, event.top, /destroy
    End
  Endcase

Return
End
Pro mms_ui_config

;If !mms does not exist, set it
  mms_init
  mms_cfg_sav = !mms

;Build the widget
  master = widget_base(/col, $
                       title = 'MMS: Configuration Settings', $
                       /align_top)
;widget base for values to set
  vmaster = widget_base(master, /col, /align_left, frame=5)
  vlabel = widget_label(vmaster, value = 'Configuration Settings')

;Widget base for save, reset and exit buttons
  bmaster = widget_base(master, /row, /align_center)
  ll = max(strlen([!mms.local_data_dir, !mms.mirror_data_dir]))+12
;Now create directory text widgets
  lbase = widget_base(vmaster, /row, /align_left)
  localdir = widget_text(lbase, /edit, /all_events, xsiz = ll, $
                         uval = 'LOCALDIR', val = !mms.local_data_dir)
  flabel = widget_label(lbase, value = 'Local data directory')
  rbase = widget_base(vmaster, /row, /align_left)
  mirrordir = widget_text(rbase, /edit, /all_events, xsiz = ll, $
                          uval = 'MIRRORDIR', val = !mms.mirror_data_dir)
  flabel = widget_label(rbase, value = 'Local mirror data directory')
;Next radio buttions
  nd_base = widget_base(vmaster, /row, /align_left)
  nd_label = widget_label(nd_base, value='Download Data: ')
  nd_buttonbase = widget_base(nd_base, /exclusive, /row, uval="ND")
  nd_on_button = widget_button(nd_buttonbase, value='Automatically            ', uval='NDON')
  nd_off_button = widget_button(nd_buttonbase, value='Use Local Data Only', uval='NDOFF')
;  widget_control, nd_on_button, /set_button

  nubase = widget_base(vmaster, /row, /align_left)
  nu_label = widget_label(nubase, value='Update Files:      ')
  nu_buttonbase = widget_base(nubase, /exclusive, /row, uval="NU")
  nu_on_button = widget_button(nu_buttonbase, value='Update if Newer       ', uval='NUON')
  nu_off_button = widget_button(nu_buttonbase, value='Use Local Data Only', uval='NUOFF')
;  widget_control, nu_on_button, /set_button

  ndobase = widget_base(vmaster, /row, /align_left)
  ndo_label = widget_label(ndobase, value='Load Data:         ')
  ndo_buttonbase = widget_base(ndobase, /exclusive, /row, uval="ND")
  ndo_on_button = widget_button(ndo_buttonbase, value='Download and Load ', uval='NDOON')
  ndo_off_button = widget_button(ndo_buttonbase, value='Download Only   ', uval='NDOOFF')
;  widget_control, ndo_on_button, /set_button

  v_base = widget_base(vmaster, /row)
  v_label = widget_label(v_base, value='Verbose (higher value = more comments):      ')
  v_values = ['0', '1', '2','3', '4', '5', '6', '7', '8', '9', '10']
  v_droplist = widget_droplist(v_base, value=v_values, uval='VERBOSE', /align_center)

  ;set up all the initial values
  if (!mms.no_download eq 0) then $
    widget_control, nd_on_button, /set_button $
    else widget_control, nd_off_button, /set_button
  if (!mms.no_update eq 0) then $
    widget_control, nu_on_button, /set_button $
    else widget_control, nu_off_button, /set_button
  if (!mms.downloadonly eq 0) then $
    widget_control, ndo_on_button, /set_button $
    else widget_control, ndo_off_button, /set_button
  widget_control, v_droplist, set_droplist_select=!mms.verbose

;buttons
  savebut = widget_button(bmaster, value = '     Save     ', uvalue = 'SAVE')
  resetbut = widget_button(bmaster, value = '     Reset     ', uvalue = 'RESET')
  reset_to_dbutton =  widget_button(bmaster,  value =  '  Reset to Default   ',  uvalue =  'RESETTODEFAULT')
  exitbut = widget_button(bmaster, value = '    Close     ', uvalue = 'EXIT')

;message widget
  messw = widget_text(master, value = '', xsize = ll, ysize = 1, /scroll)
  def_values=[1,0,0,2]
  
  state = {mms_cfg_sav:mms_cfg_sav, $
          localdir:localdir, mirrordir:mirrordir, $
          nd_on_button:nd_on_button, nd_off_button:nd_off_button, $
          nu_on_button:nu_on_button, nu_off_button:nu_off_button, $
          ndo_on_button:ndo_on_button, ndo_off_button:ndo_off_button, $
          v_values:v_values, v_droplist:v_droplist, messw:messw, $
          def_values:def_values}

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'mms_ui_config', master, /no_block

End


