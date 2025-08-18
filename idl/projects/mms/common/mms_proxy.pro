;+
;NAME:    mms_proxy
;
;PURPOSE:
;   (1) To set a proxy and establish a connection to SDC, on the fly.
;   (2) To store/delete proxy information into/from a configuration file.
;
;NOTE:
;   If the proxy requires proxy_username and proxy_password, then the user
;   needs to use this program everytime he/she needs to access SDC because
;   we do not store a password.
;
;KEYWORDS:
;
;HISTORY:
; 2015-07-20, moka, Created
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-07-20 22:46:29 -0700 (Mon, 20 Jul 2015) $
; $LastChangedRevision: 18189 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_proxy.pro $
;-
PRO mms_proxy_event, ev
  compile_opt idl2
  widget_control, ev.top, GET_UVALUE=wid

  exitcode = 0
  case ev.id of
    wid.fldAuth: str_element,/add,wid,'prox.auth',long(ev.value)
    wid.fldHost: str_element,/add,wid,'prox.host',ev.value
    wid.fldPort: str_element,/add,wid,'prox.port',ev.value
    wid.fldUser: str_element,/add,wid,'prox.user',ev.value[0]
    wid.txPass: begin 

      ;Handle character insertion (type=0)
      if ev.type eq 0 then begin
        ; Insert the character at the proper location.
        widget_control, ev.id, /use_text_select, set_value = '*'
        ; Update the current insertion point in the text widget.
        widget_control, ev.id, set_text_select=ev.offset + 1
        ; Store password
        str_element,/add,wid,'prox.pass', wid.prox.pass + string(ev.ch)
      endif

      ;Handle character deletion (type=2)
      if ev.type eq 2 then begin
        ;Get current password length.
        widget_control, ev.id, get_value=text
        text = text[0] ;returned value is a string array
        oldLength = strlen(text)
        ;Get new length. Note, deletion event may include more than one character.
        newLength = oldLength - ev.length
        ;Replace text with approapriate number of *s.
        if newLength eq 0 then widget_control, ev.id, set_value = ''  $
        else widget_control, ev.id, set_value = replicate('*', newLength)
        ;Update value of stored password.
        str_element,/add,wid,'prox.pass',strmid(wid.prox.pass,0,newLength)
        ;widget_control, ev.top, get_uvalue=info
        ;(*info.ptr).password = strmid((*info.ptr).password, 0, newLength)
        ;Reset the text insertion point in the text widget.
        widget_control, ev.id, set_text_select=ev.offset
      endif

      end
    wid.btnClose: exitcode=1
    wid.btnExecute: begin
      print, wid.prox.auth
      print, wid.prox.host
      print, wid.prox.port
      print, wid.prox.user
      print, wid.prox.pass
      
      r = get_mms_sitl_connection($
        group_leader = ev.top,$
        PROXY_AUTHENTICATION = wid.prox.auth,$
        PROXY_HOSTNAME = wid.prox.host[0], $
        PROXY_PORT = wid.prox.port, $
        PROXY_USERNAME = wid.prox.user,$
        PROXY_PASSWORD = wid.prox.pass)

      end
    else:
  endcase

  if exitcode then begin
    widget_control, ev.top, /DESTROY
  endif else begin
    widget_control, ev.top, SET_UVALUE=wid
  endelse
END

PRO mms_proxy
  compile_opt idl2
  
  ;-----------
  ; INITIALIZE
  ;-----------
  xsize = 350
  ysize = 480
  xbtnsize = 80
  dimscr = get_screen_size()
  prox = {auth:3L, host:'example.org', port:'80', user:'', pass:''}
  str_element,/add,wid,'prox',prox
  
  ;-----------
  ; BASE
  ;-----------
  base = widget_base(TITLE = 'MMS_PROXY',/column,$
    XSIZE=xsize,XOFFSET=dimscr[0]*0.5-xsize*0.5,YOFFSET=dimscr[1]*0.5-ysize*0.5)
  str_element,/add,wid,'base',base

  ;-----------
  ; ELEMENTS
  ;-----------
  str_element,/add,wid,'fldAuth',cw_field(base,VALUE=strtrim(string(prox.auth),2),/ALL_EVENTS,TITLE='Proxy Authentication: ',tab_mode=1)
  str_element,/add,wid,'fldHost',cw_field(base,VALUE=prox.host,/ALL_EVENTS,TITLE='Proxy Hostname: ',tab_mode=1)
  str_element,/add,wid,'fldPort',cw_field(base,VALUE=prox.port,/ALL_EVENTS,TITLE='Proxy Port:     ',tab_mode=1)
  str_element,/add,wid,'fldUser',cw_field(base,VALUE=prox.user,/ALL_EVENTS,TITLE='Proxy Username: ',tab_mode=1)
  pwbase = widget_base(base, row=1,tab_mode=1)
  str_element,/add,wid,'bsPass', widget_label(pwbase, value='Proxy Password: ')
  str_element,/add,wid,'txPass', widget_text(pwbase, /all_events, editable=0, tab_mode=1)
  
  baseButton = widget_base(base,/row,/align_center)
  str_element,/add,wid,'btnExecute', widget_button(baseButton,VALUE='Execute',XSIZE=xbtnsize)
  str_element,/add,wid,'btnClose', widget_button(baseButton,VALUE='Close',XSIZE=xbtnsize)
  
  ;-----------
  ; FINALIZE
  ;-----------
  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid
  xmanager, 'mms_proxy', base, /no_block
  
END
