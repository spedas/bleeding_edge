PRO sppeva_dash_activate
  compile_opt idl2
  common com_dash, com_dash

  widget_control, com_dash.drDash, GET_VALUE=mywindow
  ;======================================================
  
  ;--------------
  ; COLOR
  ;--------------
  window = [240B,240B,240B]
  white  = [255B,255B,255B]
  red    = [255B,  0B,  0B]
  green  = [  0B,255B,  0B]
  blue   = [  0B,  0B,255B]
  yellow = [255B,255B,  0B]
  black  = [  0B,  0B,  0B]
  lightblue= [  0B,204B,255B]
  lightred = [255B,153B,153B]
  
  color={window:window, white:white, red:red, green:green, blue:blue, yellow:yellow, black:black,$
    lightblue:lightblue, lightred:lightred}

  dy = 0.12 ; line height
  
  ;--------------
  ; Current Time
  ;--------------
  cst = time_string(systime(/seconds,/utc));................. current time
  css = ' current time: '+strmid(cst, 5,2)+'/'+strmid(cst, 8,2)+' '+strmid(cst, 11,5) + ' UTC'
  
  ;--------------
  ; MAIN
  ;--------------
  if strmatch(!SPPEVA.COM.MODE,'FLD') then begin
    myview_color = lightblue
    str_mode = ' FIELDS'
  endif else begin
    myview_color = lightred
    str_mode = ' SWEAP'
  endelse
  myview   = obj_new('IDLgrView',VIEWPLANE_RECT=[0,0,1,1], COLOR=myview_color)
  myfont   = obj_new('IDLgrFont', 'Helvetica*bold')
  myfontL  = obj_new('IDLgrFont', 'Helvetica*bold',SIZE=18)
  myfontS  = obj_new('IDLgrFont', 'Helvetica'     ,SIZE=10)
  mymodel  = obj_new('IDLgrModel')
  oSpace   = obj_new('IDLgrText',' ',FONT=myfontS,COLOR=black,   LOCATION=[0, 1-0.5*dy])
  oMode    = obj_new('IDLgrText',str_mode,FONT=myfontL,COLOR=black,   LOCATION=[0, 1-1.5*dy])
  oTime    = obj_new('IDLgrText',css,FONT=myfontS,COLOR=black,   LOCATION=[0, 1-2.5*dy])
  oHH      = obj_new('IDLgrText',' 0 hrs',FONT=myfont,COLOR=black,   LOCATION=[0, 1-4.5*dy])
  oMM      = obj_new('IDLgrText',' 0 min',  FONT=myfont,COLOR=black,   LOCATION=[0, 1-5.5*dy])
  oBL      = obj_new('IDLgrText',' 0 blocks',  FONT=myfont,COLOR=black,   LOCATION=[0, 1-6.5*dy])
  oGb      = obj_new('IDLgrText',' 0 Gbits',  FONT=myfont,COLOR=black,   LOCATION=[0, 1-7.5*dy])
  myview  ->Add, mymodel
  mymodel ->Add, oMode
  mymodel ->Add, oTime
  mymodel ->Add, oHH
  mymodel ->Add, oMM
  mymodel ->Add, oBL
  mymodel ->Add, oGb
  
  ;----------------
  ; DRAW & SAVE
  ;----------------
  str_element,/add,com_dash,'myview',myview
  str_element,/add,com_dash,'mymodel',mymodel
  str_element,/add,com_dash,'myfont',myfont
  str_element,/add,com_dash,'oMode',oMode
  str_element,/add,com_dash,'oTime',oTime
  str_element,/add,com_dash,'oHH',oHH
  str_element,/add,com_dash,'oMM',oMM
  str_element,/add,com_dash,'oBL',oBL
  str_element,/add,com_dash,'oGb',oGb
  str_element,/add,com_dash,'color',color
  str_element,/add,com_dash,'instr','FLD'
  ;======================================================
  mywindow->Draw, myview
END