;+
; NAME:
;   EVA_FONT_TEST
;
; PURPOSE:
;   Use this script when the dashboard in EVA's main control panel look corrupted
;   or the font is missing. If you run this script and clicked the DRAW button,
;   you should see a phrase "325 buffers".
;
;   If you do not see the phrase, then something is wrong in IDL. Please try re-booting
;   your computer or re-installing IDL. 
;
;   If you do see the phrase and the script seems working okay, there could be another
;   problem in EVA. Please relaunch IDL, display some data using, say SITL_Quick. Then, 
;   please send me everything you have in the IDL console. 
;
; CREATED BY: Mitsuo Oka   July 2017
;
; $LastChangedBy: moka $
; $LastChangedDate: 2016-09-28 14:25:51 -0700 (Wed, 28 Sep 2016) $
; $LastChangedRevision: 21970 $
; $URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_cmd_load.pro $
;-
PRO eva_font_test_draw, wid
  widget_control, wid.drDash, GET_VALUE=mywindow

  cwhite  = [255B,255B,255B]
  cblack  = [  0B,  0B,  0B]
  
  myview   = obj_new('IDLgrView',VIEWPLANE_RECT=[0,0,1,1], COLOR=cblack)
  myfont   = obj_new('IDLgrFont', 'Helvetica*bold')
  mymodel  = obj_new('IDLgrModel')
  oNsegs   = obj_new('IDLgrText','325 buffers',FONT=myfont,COLOR=cwhite,  LOCATION=[0.3,0.5])
  
  myview ->Add, mymodel
  mymodel ->Add, oNsegs

  str_element,/add,sg,'myview',myview
  str_element,/add,sg,'mymodel',mymodel
  str_element,/add,sg,'myfont',myfont
  str_element,/add,sg,'oNsegs',oNsegs

  mywindow->Draw, sg.myview
END

PRO eva_font_test_erase,wid
  widget_control, wid.drDash, GET_VALUE=mywindow
  mywindow->Erase
END

PRO eva_font_test_event, event
  @tplot_com
  compile_opt idl2
  widget_control, event.top, GET_UVALUE=wid

  case event.id of
    wid.drDash:print,'dashboard detected'
    wid.btnTest:moka_font_test_draw, wid
    wid.btnErase:moka_font_test_erase, wid
    else:
  endcase
  
  widget_control, event.top, SET_UVALUE=wid
END

PRO eva_font_test
  help, !VERSION

  xsize=250
  ysize = 280
  
  scr_dim    = get_screen_size()
  xoffset = scr_dim[0]*0.5 - xsize*0.5 > 0.;-650.-286-50. > 0.
  yoffset = scr_dim[1]*0.5 - ysize*0.5
  
  base = widget_base(TITLE = 'DASHBOARD_TEST',/COLUMN,xoffset=xoffset,yoffset=yoffset)
  str_element,/add,wid,'base',base
  str_element,/add,wid,'drDash', widget_draw(base,graphics_level=2,xsize=xsize,ysize=250,/expose_event)
  bsButton = widget_base(base,/ROW)
    str_element,/add,wid,'btnTest',widget_button(bsButton,VALUE=' DRAW ', xsize=150, ysize=ysize-250)
    str_element,/add,wid,'btnErase',widget_button(bsButton,VALUE=' ERASE ',ysize=ysize-250)
  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid

  xmanager, 'eva_font_test', base, /no_block;, GROUP_LEADER=group_leader
END
