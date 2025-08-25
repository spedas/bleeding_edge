;+
; NAME: SPPEVA_DASH
;
; PURPOSE: An SPPEVA module for dashboard
;
; CREATED BY: Mitsuo Oka   Sep 2018
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/dashboard/sppeva_dash.pro $
;-

FUNCTION sppeva_dash_event, event
  compile_opt idl2
  
  print,'*************'
END

FUNCTION sppeva_dash, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, XSIZE = xsize, YSIZE = ysize
  compile_opt idl2
  common com_dash, com_dash

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for eva_sitl'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'sppeva_dash'

  ;--------------------
  ; BASE
  ;--------------------

  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, /column,/frame,$
    EVENT_FUNC = "sppeva_dash_event", $
    FUNC_GET_VALUE = "sppeva_dash_get_value", $
    PRO_SET_VALUE = "sppeva_dash_set_value", $
    XSIZE = xsize, YSIZE = ysize)
  str_element,/add,wid,'base',base

  geo = widget_info(parent,/geometry)
  str_element,/add,wid,'drDash', widget_draw(base,graphics_level=2,xsize=geo.xsize,ysize=150);,/expose_event)

  com_dash = wid
  
  ; Save out the initial wid structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=wid, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, base
END