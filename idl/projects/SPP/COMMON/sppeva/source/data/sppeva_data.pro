;+
; NAME: SPPEVA_DATA
;
; PURPOSE: An SPPEVA module for data handling (load, plot, etc.)
;
; CREATED BY: Mitsuo Oka   Sep 2018
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/data/sppeva_data.pro $
;-


FUNCTION sppeva_data_paramSetsAll, dir

  ;---------------
  ; DIRECTORY
  ;---------------
  if undefined(dir) then begin
    ; 'dir' produces the directory name with a path separator character that can be OS dependent.
    dir = file_search(ProgramRootDir(/twoup)+'parameterSets',/MARK_DIRECTORY,/FULLY_QUALIFY_PATH); directory
  endif

  ;---------------
  ; Filenames
  ;---------------
  filenames_tmp = file_search(dir,'*',/FULLY_QUALIFY_PATH,count=cmax); full path to the files
  filenames = strmid(filenames_tmp,strlen(dir),1000); extract filenames only

  ;---------------
  ; DropDown Menu
  ;---------------
  drpDownMenu = ['dummy']
  for c=0,cmax-1 do begin; for each file
    tmp = strjoin(strsplit(filenames[c],'_',/extract),' '); replace '_' with ' '
    drpDownMenu = [drpDownMenu, strmid(tmp,0,strlen(tmp)-4)]; remove file extension .txt etc.
  endfor

  return, {filenames:filenames, drpDownMenu:drpDownMenu[1:*]}
END

FUNCTION sppeva_data_event, event
  @tplot_com
  compile_opt idl2
  
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message,/reset
    return, {ID:event.handler, TOP:event.top, HANDLER:0L }
  endif
  parent=event.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  
  tr_old = !SPPEVA.COM.STRTR

  
  case event.id of
    wid.fldStartTime: begin
      widget_control, event.id, GET_VALUE=new_time;get new eventdate
      !SPPEVA.COM.STRTR = [new_time, tr_old[1]]
      ;str_element,/add,wid,'start_time',new_time
      ;str_element,/add,wid,'trangeChanged',1
    end
    wid.fldEndTime: begin
      widget_control, event.id, GET_VALUE=new_time;get new eventdate
      !SPPEVA.COM.STRTR = [tr_old[0], new_time]
      ;str_element,/add,wid,'end_time',new_time
      ;str_element,/add,wid,'trangeChanged',1
    end
    wid.drpOrbit: begin
      stime = wid.orbHist.stime[event.index]
      etime = wid.orbHist.etime[event.index]
      !SPPEVA.COM.STRTR = [stime,etime]
      widget_control, wid.fldStartTime, SET_VALUE=stime; update GUI field
      widget_control, wid.fldEndTime,   SET_VALUE=etime
      end
    wid.calStartTime: begin
      print,'EVA: ***** EVENT: calStartTime *****'
      otime = obj_new('spd_ui_time')
      otime->SetProperty,tstring=tr_old[0]
      spd_ui_calendar,'EVA Calendar',otime,event.top, startyear = 2018
      otime->GetProperty,tstring=tstring         ; get tstring
      !SPPEVA.COM.STRTR = [tstring, tr_old[1]]
      widget_control, wid.fldStartTime, SET_VALUE=tstring; update GUI field
      obj_destroy, otime
    end
    wid.calEndTime: begin
      print,'EVA: ***** EVENT: calEndTime *****'
      otime = obj_new('spd_ui_time')
      otime->SetProperty,tstring=tr_old[1]
      spd_ui_calendar,'EVA Calendar',otime,event.top, startyear = 2018
      otime->GetProperty,tstring=tstring
      !SPPEVA.COM.STRTR = [tr_old[0], tstring]
      widget_control, wid.fldEndTime, SET_VALUE=tstring
      obj_destroy, otime
    end
    wid.bgType: begin
      !SPPEVA.COM.TYPETR = event.VALUE
      orbHist = sppeva_load_events(ephem=event.VALUE)
      widget_control, wid.drpOrbit, SET_VALUE = orbHist.ORBSET
      str_element,/add,wid,'orbHist',orbHist
    end
    wid.drpSet: begin
      print,'EVA: ***** EVENT: drpSet *****'
      !SPPEVA.COM.parameterset = wid.paramSetsAll.Filenames[event.index]
;      fname = wid.paramlist.paramFileList[event.id]
;      fname_broken=strsplit(fname,'/',/extract,count=count)
;      fname_param = fname_broken[count-1]
;      result = read_ascii(fname,template=eva_data_template(),count=count)
;      if count gt 0 then begin
;        str_element,/add,state,'paramlist',result.param
;        print, 'EVA: reading '+fname_param
;      endif else begin; if parameterSet list invalid
;        msg = 'The selected parameter-set is not valid. Check the file: '+fname_param
;        result = dialog_message(msg,/center)
;        print,'EVA: '+msg
;      endelse


      end
;    wid.fldCommDay: begin
;      widget_control, event.id, GET_VALUE=strNewDay
;      !SPPEVA.COM.COMMDAY = strNewDay
;      end
    wid.load:begin
      sppeva_load,force=0, paramlist=paramlist
      geo = widget_info(event.top,/geometry)
      sppeva_plot, paramlist, parent_xsize=geo.xsize
    end
    wid.loadforce:begin
      sppeva_load,force=1, paramlist=paramlist
      geo = widget_info(event.top,/geometry)
      sppeva_plot, paramlist, parent_xsize=geo.xsize
    end
    else:
  endcase

  sppeva_dash_update
  widget_control, stash, SET_UVALUE=wid, /NO_COPY
  RETURN, { ID:parent, TOP:event.top, HANDLER:0L }
END

FUNCTION sppeva_data, parent, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, XSIZE = xsize, YSIZE = ysize
  compile_opt idl2

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for eva_data'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'sppeva_data'

  ;--------------------
  ; STRUCTURE
  ;--------------------

;  wid = { $
;    ;start_time: strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)+'/00:00:00',$
;    ;end_time  : strmid(time_string(systime(/seconds,/utc)-86400.d*4.d),0,10)+'/24:00:00',$
;    start_time: '1995-06-10/00:00:00',$
;    end_time:   '1995-06-12/24:00:00',$
;    trangeChanged: 0}
  
  ;!SPPEVA.COM.STRTR = ['1995-06-10/00:00:00','1995-06-12/24:00:00']
  ;!SPPEVA.COM.STRTR = ['2018-10-02/03:00:00','2018-10-02/17:00:00']
  ;!SPPEVA.COM.STRTR = ['2018-11-01/00:00:00','2018-11-12/24:00:00']
  !SPPEVA.COM.STRTR = ['2018-11-10/00:00:00','2018-11-13/24:00:00']
  
  ;--------------------
  ; BASE
  ;--------------------

  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, /column,$
    EVENT_FUNC = "sppeva_data_event", $
    FUNC_GET_VALUE = "sppeva_data_get_value", $
    PRO_SET_VALUE = "sppeva_data_set_value", $
    XSIZE = xsize, YSIZE = ysize)
    
  str_element,/add,wid,'base',base
    
  ;--------------------
  ; START & STOP TIMES
  ;--------------------

  ; orbHist = sppeva_orbit_history()
  orbHist = sppeva_load_events()
  bsTR = widget_base(base, /column, /frame)
    str_element,/add,wid,'lblOrbit',widget_label(bsTR,VALUE='Pre-defined Time Range')
    str_element,/add,wid,'bgType',CW_BGROUP(bsTR,['Encounter','Ephem'], /ROW, /EXCLUSIVE,SET_VALUE=!SPPEVA.COM.TYPETR)
    str_element,/add,wid,'drpOrbit',widget_droplist(bsTR,VALUE=orbHist.orbSet,TITLE='',SENSITIVE=1)
    str_element,/add,wid,'orbHist',orbHist
  
  ; calendar icon
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, base, cal

  baseStartTime = widget_base(base,/row, SPACE=0, YPAD=0)
  lblStartTime = widget_label(baseStartTime,VALUE='Start Time',/align_left,xsize=70)
  str_element,/add,wid,'fldStartTime',cw_field(baseStartTime,VALUE=!SPPEVA.COM.STRTR[0],TITLE='',/ALL_EVENTS,XSIZE=20)
  str_element,/add,wid,'calStartTime',widget_button(baseStartTime,VALUE=cal)

  baseEndTime = widget_base(base,/row)
  lblEndTime = widget_label(baseEndTime,VALUE='End Time',/align_left,xsize=70)
  str_element,/add,wid,'fldEndTime',cw_field(baseEndTime,VALUE=!SPPEVA.COM.STRTR[1],TITLE='',/ALL_EVENTS,XSIZE=20)
  str_element,/add,wid,'calEndTime',widget_button(baseEndTime,VALUE=cal)

  
  
  ;------------
  ; PARAMETER SETS
  ;------------
  paramSetsAll = sppeva_data_paramSetsAll()
  str_element,/add,wid,'paramSetsAll',paramSetsAll
  bsCtrl = widget_base(base, /COLUMN,/align_center, space=0, ypad=0)
  str_element,/add,wid,'lblPS',widget_label(bsCtrl,VALUE='Parameter Set')
  str_element,/add,wid,'drpSet',widget_droplist(bsCtrl,VALUE=wid.paramSetsAll.drpDownMenu,$
    TITLE='',DYNAMIC_RESIZE=strmatch(!VERSION.OS_FAMILY,'Windows'))
  ;str_element,/add,wid,'fldCommDay',cw_field(bsCtrl,VALUE=!SPPEVA.COM.COMMDAY,TITLE='Commissioning Day ',/ALL_EVENTS,xsize=10)
  
  !SPPEVA.COM.PARAMETERSET = paramSetsAll.FILENAMES[0]

  ;------------
  ; LOAD
  ;------------
  baseLoad = widget_base(base,/row);,/align_center)
  str_element,/add,wid,'load',widget_button(baseLoad, VALUE = 'LOAD', XSIZE=150,YSIZE=30)
  str_element,/add,wid,'loadforce',widget_button(baseLoad, VALUE = ' FORCE RELOAD ',YSIZE=30,$
    TOOLTIP='Clear the static memory and force reloading all tplot variables.')
    
  ; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=wid, /NO_COPY

  ; Return the base ID of your compound widget.  This returned
  ; value is all the user will know about the internal structure
  ; of your widget.
  RETURN, base
END  