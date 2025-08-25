;+
; NAME: SPP EVA
;
; PURPOSE: burst-trigger management tool for SPP
;
; CALLING SEQUENCE: Type in 'SPPEVA' into the IDL console and hit return.
;
; CREATED BY: Mitsuo Oka   Sep 2018
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/sppeva.pro $
;-


PRO sppeva_event, event
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
      sppeva_pref, GROUP_LEADER = event.top
      end
    wid.mnHelp_about:begin
      msg = ['##### SPP EVA #####',' ']
      vrs = spd_read_current_version()
      if size(vrs,/type) ne 7 then begin
        msg = [msg, 'Your SPEDAS version: N/A',' ']
        msg = [msg, 'The SPEDAS version will be displayed if called from ']
        msg = [msg, 'a copy of the bleeding-edge zip instead of svn repo.']
      endif else begin
        msg = [msg, 'Your SPEDAS version: '+ v]
      endelse
      msg = [msg, ' ', 'Created by Mitsuo Oka at UC Berkeley']
      answer=dialog_message(msg,/info,/center)
      end
    else:
  endcase

  if exitcode then begin
    tplot_options,'base',-1
    obj_destroy, obj_valid()
    tn=tnames('*',ct)
    ;if ct gt 0 then del_data,'*'
    widget_control, event.top, /DESTROY
    if (!d.flags and 256) ne 0  then begin    ; windowing devices
      str_element,tplot_vars,'options.window',!d.window,/add_replace
      str_element,tplot_vars,'settings.window',!d.window,/add_replace
    endif
  endif else begin
    widget_control, event.top, SET_UVALUE=wid
  endelse
END

PRO sppeva
  compile_opt idl2
  
  ;////////// INITIALIZE /////////////////////////////////
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif

  If(xregistered('sppeva') ne 0) then begin
    message, /info, 'You are already running SPP_EVA.'
    answer = dialog_message('You are already running SPP_EVA.',title='SPP_EVA',/center)
    return
  endif

  if !VERSION.RELEASE lt 8.4 then begin
    answer = dialog_message("You need IDL version 8.4 or higher for SPP_EVA",/center)
    return
  endif

  !EXCEPT = 0; stop reporting of floating point errors

  spd_graphics_config,colortable=colortable
  
  ;////////// WIDGET LAYOUT /////////////////////////////////

  scr_dim    = get_screen_size()
  xoffset = 0;scr_dim[0]*0.3 > 0.;-650.-286-50. > 0.

  sppeva_init
  
  ;----------------
  ; Top Level Base
  ;----------------
  base = widget_base(TITLE = 'SPP_EVA',MBAR=mbar,_extra=_extra,/column,$
    XOFFSET=xoffset, YOFFSET=0,TLB_KILL_REQUEST_EVENTS=1,space=7)
  str_element,/add,wid,'base',base

  ;-----------------
  ; menu
  ;-----------------
  mnFile = widget_button(mbar, VALUE='File', /menu)
  str_element,/add,wid,'mnPref',widget_button(mnFile,VALUE='Preference')
  str_element,/add,wid,'exit',widget_button(mnFile,VALUE='Exit',/separator)
  mnHelp = widget_button(mbar, VALUE='Help',/menu)
  str_element,/add,wid,'mnHelp_about',widget_button(mnHelp,VALUE='About SPP_EVA')

  ;-----------------
  ;  MAIN PANEL
  ;-----------------
  str_element,/add,wid,'spp_data',sppeva_data(base);,xsize=cpwdith); DATA MODULE
  str_element,/add,wid,'spp_dash',sppeva_dash(base);
  str_element,/add,wid,'spp_sitl',sppeva_sitl(base);,xsize=cpwdith); SITL MODULE
    
  ;--------------
  ; REALIZE
  ;--------------
  
  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid
  xmanager, 'sppeva', base, /no_block;, GROUP_LEADER=group_leader
  
  ;--------------
  ; DASHBOARD
  ;--------------
  sppeva_dash_activate
END
