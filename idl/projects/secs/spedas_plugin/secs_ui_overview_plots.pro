;+
; NAME:
;  secs_ui_overview_plots
;
; PURPOSE:
;  Widget wrapper for secs_overview_plots used to view secs quicklook plots on the web
;
; CALLING SEQUENCE:
;  success = secs_ui_overview_plots(gui_id, historyWin, oplot_calls, callSequence,$
;                                windowStorage,windowMenus,loadedData,drawObject)
;
; INPUT:
;  gui_id:  The id of the main GUI window.
;  historyWin:  The history window object.
;  oplot_calls:  The number calls to secs_ui_gen_overplot
;  callSequence: object that stores sequence of procedure calls that was used to load data
;  windowStorage: standard windowStorage object
;  windowMenus: standard menu object
;  loadedData: standard loadedData object
;  drawObject: standard drawObject object
;  
;
; OUTPUT:
;  none
;  
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/spedas_plugin/secs_ui_overview_plots.pro $
;-
function secs_ui_time_string, tr_obj, event, tenseconds=tenseconds
  ; function takes time widget object round the time to one minute or to ten seconds
  ; pit the value back to the object 
  ; and return structure of the strings of the start date
  
  tr_obj->getproperty, starttime=starttime 
  starttime->getproperty, tdouble=t0, sec=sec
  
  if keyword_set(tenseconds) then begin
    t0 -= sec
    sec -= sec mod 10
    t0 += sec    
  endif else begin  
  ;round times to 1 minute   
    if sec lt 30 then t0 -= sec else t0 += 60-sec
  endelse
  
  starttime->setproperty, tdouble=t0
  tr_obj->setproperty, starttime=starttime
  
  starttime->getproperty, tstring=ts, year=year, month=month, date=date, hour=hour, min=mins, sec=sec
  timeid = widget_info(event.top, find_by_uname='time')
  widget_control, timeid, set_value=ts, func_get_value='spd_ui_time_widget_set_value'
  
  str = [string(year, format='(I04)'), string([month,date,hour,mins,sec],format='(I02)')]
  dstr = {y:str[0],m:str[1],d:str[2],hh:str[3],mm:str[4],ss:str[5],tstr:ts}
  return, dstr
end

function secs_ui_time_isvalud, event
  ; Check if the time is valud  
  timeid = widget_info(event.top, find_by_uname='time')
  widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
  return, valid
end

pro secs_ui_overview_plots_event, event

  Compile_Opt hidden
 
  Widget_Control, event.TOP, Get_UValue=state, /No_Copy

  ;Put a catch here to insure that the state remains defined
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    
    spd_ui_sbar_hwin_update, state, err_msg, /error, err_msgbox_title='Error while generating SECS overview plot'
    
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    widget_control, event.top,/destroy
    RETURN
  ENDIF
  
  ;kill request block
  IF (Tag_Names(event, /Structure_Name) EQ 'WIDGET_KILL_REQUEST') THEN BEGIN  

    dprint,  'Generate SECS overview plots widget killed' 
    state.historyWin->Update,'SECS_UI_overview_PLOTS: Widget killed' 
    Widget_Control, event.TOP, Set_UValue=state, /No_Copy
    Widget_Control, event.top, /Destroy
    RETURN 
  ENDIF
  
  Widget_Control, event.id, Get_UValue=uval
  
  state.historywin->update,'SECS_UI_overview_PLOTS: User value: '+uval  ,/dontshow
  
  ; check system variable !secs
  defsysv,'!secs',exists=exists
  if not(exists) then secs_init
   
  CASE uval OF
    'CHECK_DATA_AVAIL': BEGIN
        ; Todo: Check the folder availability  before open the website      
        ; For some reason, the & cannot be sent as part of the URL. So we are going to use a single string variable that will be split by PHP.        
        if secs_ui_time_isvalud(event) then begin        
          state.statusBar->update,'JPEG files can be downloaded from the web site.'
          state.historyWin->update,'JPEG files can be downloaded from the web site.'
          stime = secs_ui_time_string(state.tr_obj, event)
          datepath = stime.y  + "/" + stime.m + "/" + stime.d  + "/"        
          url = !secs.remote_data_dir + "Quicklook/" + datepath          
          spd_ui_open_url, url
        endif
     END
     
     'WEBPLOT': BEGIN      
      ; Todo: Check the jpeg folder availability before open the website
       if secs_ui_time_isvalud(event) then begin   
         stime = secs_ui_time_string(state.tr_obj, event)
         datepath = stime.y  + "/" + stime.m + "/" + stime.d  + "/"
         filename = 'ThemisSEC'+ stime.y  + stime.m + stime.d + "_" + stime.hh + stime.mm + stime.ss + '.jpeg'
         url = !secs.remote_data_dir + "Quicklook/" + datepath + "/" + filename 
         spd_ui_open_url, url
       endif
      END

     'VIEWPLOT': BEGIN       
       if secs_ui_time_isvalud(event) then begin
         stime = secs_ui_time_string(state.tr_obj, event, /tenseconds)
         plottime=stime.y  + "-" + stime.m  + "-" + stime.d  + "/" + stime.hh  + ":" + stime.mm  + ":" + stime.ss 
         trange=[plottime, plottime]                 
         IF state.pngbutton THEN png_str = ' and png file' ELSE png_str = ''
         widget_control,widget_info(event.top, FIND_BY_UNAME='plottype'),GET_VALUE=plot_type
         CASE plot_type OF
           0: begin
               state.statusBar->update,'Creating EIC Mosaic Plot' + png_str
               state.historyWin->update,'Creating EIC Mosaic Plot' + png_str
               eics_overlay_plots, trange=trange, createpng=state.pngbutton, showgeo=state.geolatlon, showmag=state.maglatlon, dynscale=state.dynscale
           end
           1: begin
             state.statusBar->update,'Creating SEC Mosaic Plot' + png_str
             state.historyWin->update,'Creating SEC Mosaic Plot' + png_str
             seca_overlay_plots, trange=trange, createpng=state.pngbutton, showgeo=state.geolatlon, showmag=state.maglatlon, dynscale=state.dynscale
           end
         endcase
       endif
     END
     
    'GEOLATLON': BEGIN
       state.geolatlon = event.select
     END
     'MAGLATLON': BEGIN
       state.maglatlon = event.select
     END
     'DYNSCLE': BEGIN
       state.dynscale = event.select
     END
     'MAKEPNG': BEGIN
       state.pngbutton = event.select
     END
     
    'CLOSE': BEGIN
      state.historyWin->update,'Generate secs overview plot canceled',/dontshow
      state.statusBar->Update,'Generate secs overview plot canceled.'
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END
    
    'KEY': begin     
      spd_ui_overplot_key, state.gui_id, state.historyWin, /modal, /secs      
    end
    
    ELSE: 
  ENDCASE
  Widget_Control, event.top, Set_UValue=state, /No_Copy

  RETURN
end


pro secs_ui_overview_plots, gui_id = gui_id, $
                          history_window = historyWin, $
                          status_bar = statusbar, $
                          call_sequence = callSequence, $
                          time_range = tr_obj, $
                          window_storage = windowStorage, $
                          loaded_data = loadedData, $
                          data_structure = data_structure, $
                          _extra = _extra

  compile_opt idl2

  err_xxx = 0
  Catch, err_xxx
  IF(err_xxx Ne 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output=err_msg
    FOR j = 0, N_Elements(err_msg)-1 DO Begin
      print, err_msg[j]
      If(obj_valid(historywin)) Then historyWin -> update, err_msg[j]
    Endfor
    Print, 'Error--See history'
    ok = error_message('An unknown error occured starting widget to generate SECS overview plots. ', $
         'See console for details.', /noname, /center, title='Error while generating SECS overview plots')
    spd_gui_error, gui_id, historywin
    RETURN
  ENDIF
  
  tlb = widget_base(/col, title='View SECS Overview Plots', group_leader=gui_id, $
          /floating, /base_align_center, /tlb_kill_request_events, /modal)

; Base skeleton          
  mainBase = widget_base(tlb, /col, /align_center, tab_mode=1, space=4)
    txtBase = widget_base(mainbase, /Col, /align_center)
    quickBase = widget_base(mainBase, Frame=1, /Col)
    midBase = widget_base(quickBase, /Row)
      trvalsBase = Widget_Base(midBase, /Col, xpad=0) ; time selector      
      midBaseButtons = Widget_Base(midBase, /Col) ; Button column      
      keyButtonBase = widget_button(midBaseButtons, Value='Plot Keys', UValue='KEY', YSize=60, $
                                    tooltip = 'Displays detailed descriptions of secs overview plot panels.')                                                                        
      davailabilitybutton = widget_button(midBaseButtons, val = ' Data Availability ', $
                                            uval = 'CHECK_DATA_AVAIL', $
                                            ToolTip = 'Browse the website to check data availability')
                                            
    plotLabel = Widget_Label(quickBase, Value='Select Plot Type: ', /align_left)
    
    
    plotBaseValues = [' Overplot EICS/THEMIS ASI Mosaics ', ' Overplot SECA/THEMIS ASI Mosaics ']
    plotBaseGroup = CW_BGROUP(quickBase, plotBaseValues, /exclusive, /Col, xpad=8, set_value=0, UNAME='plottype',UVAL='PLOTTYPE')

    labelbase=widget_base(quickBase, row=2, /align_left)    
    displayLabel=Widget_Label(labelbase, Value=' Plot Options: ', /align_left)        
    latlonbase=Widget_Base(labelbase, row=2, xpad=8,/align_left, /nonexclusive)    
    geoButton=Widget_Button(latlonbase, value=' Show Geographic Lat/Lon ', UValue='GEOLATLON',uname='geolatlon')
    magButton=Widget_Button(latlonbase, value=' Show Magnetic Lat/Lon ', UValue='MAGLATLON', uname='maglatlon')      
    dynscaleButton=Widget_Button(latlonbase, value=' Use dynamic scaling ', UValue='DYNSCLE', uname='dynscale')
    pngButton=Widget_Button(latlonbase, value=' Make PNG ', UValue='MAKEPNG', uname='makepng')
    
    ; TODO: strech the width of the field
    webplotbase=widget_base(quickBase, /row, /align_left,/frame)
    webplottext=widget_label(webplotbase, value=' Alternatively, you can view the plot on the web. ')
    webplotbutton=widget_button(webplotbase, value='Web Plot', UValue='WEBPLOT', uname='webplot')    
    
    
    ;goWebBase = Widget_Base(mainBase, /Row,  /align_center)    
    buttonBase = Widget_Base(mainBase, /row, xpad=8, /align_center)
    viewbutton = widget_button(buttonBase, val = ' View Plot ', uval = 'VIEWPLOT', /align_center)
    applyButton = Widget_Button(buttonBase, Value='Close', UValue='CLOSE', XSize=80)
    
; Time range-related widgets
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  st_text = '2015-03-17/13:00:00'
  et_text = '2015-03-18/00:00:00'
  if ~obj_valid(tr_obj) then begin    
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif
  ; set the default date, the setting time above does not work because tr_obj is defined
  stat = tr_obj->SetStartTime(st_text)
  stat = tr_obj->SetEndTime(et_text)

  timeWidget = spd_ui_time_widget(trvalsBase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                  uvalue='TIME',uname='time', startyear = 2007, oneday=1) 

  ;flag denoting successful run
  success = 0

  ;initialize structure to store variables for future calls
  if ~is_struct(data_structure) then begin
    data_structure = { oplot_calls:0, track_one:0b }
  endif

  data_ptr = ptr_new(data_structure)
   
  ; to trick the time widget we will hide unused fields
  widget_control,widget_info(tlb,  FIND_BY_UNAME='oneday'),MAP=0
  widget_control,widget_info(tlb,  FIND_BY_UNAME='stopbase'),MAP=0
   
  widget_control, geoButton, set_button=1
  widget_control, magButton, set_button=1
  widget_control, pngButton, set_button=0
  widget_control, dynscaleButton, set_button=0

  
  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           tr_obj:tr_obj,  success:ptr_new(success), data:data_ptr, $ ; plot_type:plot_type - excluded
           callSequence:callSequence,windowStorage:windowStorage, $
           geolatlon:1, maglatlon:1, pngbutton:0, dynscale:0, loadedData:loadedData}

  Centertlb, tlb         
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'secs_ui_overview_plots', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  RETURN
end

