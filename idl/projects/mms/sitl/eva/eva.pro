;+
; NAME: EVA
;
; PURPOSE: burst-trigger management tool for MMS-SITL 
;
; CALLING SEQUENCE: Type in 'eva' into the IDL console and hit return.
;
; CREATED BY: Mitsuo Oka   Jan 2015
;
;
; $LastChangedBy: moka $
; $LastChangedDate: 2022-02-03 11:55:52 -0800 (Thu, 03 Feb 2022) $
; $LastChangedRevision: 30556 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/eva.pro $
PRO eva_event, event
  @tplot_com
  compile_opt idl2
  widget_control, event.top, GET_UVALUE=wid


  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message,/reset
    return
  endif

  exitcode = 0
  case event.id of
    wid.base        : if strmatch(tag_names(event,/structure_name),'WIDGET_KILL_REQUEST') then exitcode=1
    wid.exit        : exitcode = 1
    wid.mnPref      : begin
      eva_pref, GROUP_LEADER = event.top
      end
    wid.mnHelp_about:begin
      msg = ['EVA for MMS/SITL',' ','Created by Mitsuo Oka at UC Berkeley']
      answer=dialog_message(msg,/info,/center)
      end 
    else:
  endcase

  if exitcode then begin
    tplot_options,'base',-1
    ;obj_destroy, obj_valid()
    idx = where(strmatch(strlowcase(tag_names(wid)),'sitl'),ct)
    if ct eq 1 then begin
      eva_sitl_cleanup
    endif
    del_data,'*'
    widget_control, event.top, /DESTROY
    
    if (!d.flags and 256) ne 0  then begin    ; windowing devices
      str_element,tplot_vars,'options.window',!d.window,/add_replace
      str_element,tplot_vars,'settings.window',!d.window,/add_replace
    endif
  endif else begin
    widget_control, event.top, SET_UVALUE=wid
  endelse
END

PRO eva

  ;////////// INITIALIZE /////////////////////////////////
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif
  
  If(xregistered('eva') ne 0) then begin
    message, /info, 'You are already running EVA.'
    answer = dialog_message('You are already running EVA.',title='EVA (Event Search and Analysisl)',/center)
    return
  endif
  
  vsn=float(strmid(!VERSION.RELEASE,0,3))
  if vsn eq 8.0 then begin
    answer = dialog_message("You are using IDL version 8.0. With IDL 8.0, "+ $
      "TDAS fails to process SST (high energy particle) data. If a system-error message appeared "+ $
      "while using EVA, please punch OK and EVA should continue running but without SST data.",/center)
  endif
  if !VERSION.RELEASE lt 8.2 then begin
    answer = dialog_message("You need IDL version 8.2.3 or higher for EVA",/center)
    return
  endif


  thm_init
  mms_init

  !EXCEPT = 0; stop reporting of floating point errors
  ;use themis bitmap as toolbar icon for newer versions
  if double(!version.release) ge 6.4d then begin
    getresourcepath,rpath
    palettebmp = read_bmp(rpath + 'thmLogo.bmp', /rgb)
    palettebmp = transpose(palettebmp, [1,2,0])
    _extra = {bitmap:palettebmp}
  endif

  ;////////// WIDGET LAYOUT /////////////////////////////////

  scr_dim    = get_screen_size()
  xoffset = scr_dim[0]*0.3-20 > 0.;-650.-286-50. > 0.

  ; Top Level Base
  base = widget_base(TITLE = 'EVA',MBAR=mbar,_extra=_extra,/column,$
    XOFFSET=xoffset, YOFFSET=0,TLB_KILL_REQUEST_EVENTS=1,space=7,resource_name="testWidget")
  str_element,/add,wid,'base',base

  ; menu
  mnFile = widget_button(mbar, VALUE='File', /menu)
  str_element,/add,wid,'mnPref',widget_button(mnFile,VALUE='Preference')
  str_element,/add,wid,'exit',widget_button(mnFile,VALUE='Exit',/separator)
  ;      mnPref_orb = widget_button(mnPref,VALUE='Orbit',/menu)
  ;        str_element,/add,wid,'mnPref_orbs',widget_button(mnPref_orb,VALUE='Show')
  ;        str_element,/add,wid,'mnPref_orbs_hide',-1
  ;        str_element,/add,wid,'mnPref_orbu',widget_button(mnPref_orb,VALUE='Update data')
  mnHelp = widget_button(mbar, VALUE='Help',/menu)
  str_element,/add,wid,'mnHelp_about',widget_button(mnHelp,VALUE='About EVA')

  ;----------------------
  ; GENERAL SETTING (FOR LAYOUT)
  ;----------------------
  xsize_default = 350
  dash_ysize    = 150
  if(!version.os_family eq 'Windows')then begin
    xsize_default = 600
    dash_ysize    = 200
  endif
  ;###############################################
  str_element,/add,wid,'CPWIDTH_DEFAULT',xsize_default
  str_element,/add,wid,'BASEPOS_DEFAULT',0
  ;###############################################
  cfg = mms_config_read()
  idx=where(strmatch(tag_names(cfg),'EVA_CPWIDTH'),ct)
  if ct gt 0 then cpwidth = cfg.EVA_CPWIDTH else cpwidth = wid.CPWIDTH_DEFAULT
  idx=where(strmatch(tag_names(cfg),'EVA_BASEPOS'),ct)
  if ct gt 0 then basepos = cfg.EVA_BASEPOS else basepos = wid.BASEPOS_DEFAULT 
  
  ;---------------------------------
  ;  DATA
  ;---------------------------------
  str_element,/add,wid,'data',eva_data(base,xsize=cpwidth); DATA MODULE
  baseTab = widget_tab(base)
  
  ;---------------------------------
  ;  SITL
  ;---------------------------------
  str_element,/add,wid,'sitl', eva_sitl(baseTab,xsize=cpwidth,dash_ysize=dash_ysize); SITL MODULE

  ;---------------------------------
  ;  SITL (Uplink)
  ;---------------------------------
  str_element,/add,wid,'sitluplink', eva_sitluplink(baseTab, base)
    
  ;---------------------------------
  ;  ORBIT
  ;---------------------------------
  ;str_element,/add,wid,'orbit', cw_orbit(baseTab); ORBIT MODULE

  ; Orbit Module NOTE: set ysize=1 before setting map=0 at line 352 (widget_control, wid.orbit, map=0)

  ;---------------------------------
  ;  SUBMIT
  ;---------------------------------
  str_element,/add,wid,'sitlsubmit',eva_sitlsubmit(base)

  widget_control, base, /REALIZE

  ; initiate modules
  widget_control, wid.sitl,  SET_VALUE=2
  ;widget_control, wid.orbit, SET_VALUE=1

  ; end of initialization
  widget_control, base, SET_UVALUE=wid
  xmanager, 'eva', base, /no_block;, GROUP_LEADER=group_leader
END
