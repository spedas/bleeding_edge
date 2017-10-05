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
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-01-23 19:30:24 -0800 (Fri, 23 Jan 2015) $
;$LastChangedRevision: 16723 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/spedas_plugin/secs_ui_gen_overplot.pro $
;-

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
  
  CASE uval OF
    'VIEWPLOT': BEGIN
      timeid = widget_info(event.top, find_by_uname='time')
      widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
      if valid then begin
        state.tr_obj->getproperty, starttime=starttime, endtime=endtime
        starttime->getproperty, year=year, month=month, date=date, hour=hour, min=min, sec=sec
        ;round times to 1 minute
        starttime->getproperty, tdouble=t0
        if sec lt 30 then t10=t0-sec else t10=t0+(60-sec) 
        sec=0       
        starttime->setproperty, tdouble=t10
        state.tr_obj->setproperty, starttime=starttime
        starttime->getproperty, tstring=ts
        starttime->getproperty, year=year, month=month, date=date, hour=hour, min=min, sec=sec
        widget_control, timeid, set_value=ts, func_get_value='spd_ui_time_widget_set_value'        
        ; Check which plot
        if state.plot_type[0] EQ 1 then begin
          ; For some reason, the & cannot be sent as part of the URL. So we are going to use a single string variable that will be split by PHP.
          datepath = string(year, format='(I04)') + "/" + string(month, format='(I02)') + "/" + string(date, format='(I02)') + "/"
          filename = 'ThemisSEC'+ string(year, format='(I04)') + string(month, format='(I02)') + string(date, format='(I02)') + "_" + $
            string(hour, format='(I02)') + string(min, format='(I02)') + string(sec, format='(I02)') + '.jpeg'
          url = !secs.remote_data_dir + "Quicklook/" + datepath + "/"+filename
          spd_ui_open_url, url
        endif else begin
          plottime=string(year, format='(I04)') + "-" + string(month, format='(I02)') + "-" + string(date, format='(I02)') + "/" + $
            string(hour, format='(I02)') + ":" + string(min, format='(I02)') + ":" + string(sec, format='(I02)')
          trange=[plottime, plottime]
          if state.plot_type[1] EQ 1 then begin
            state.statusBar->update,'Creating EIC Mosaic Plot'
            state.historyWin->update,'Creating EIC Mosaic Plot'
            eics_ui_overlay_plots, trange=trange, showgeo=state.geolatlon, showmag=state.maglatlon
          endif
          if state.plot_type[2] EQ 1 then begin
            ;state.statusBar->update,'SEC Mosaic Plot not yet available'
            ;state.shistoryWin->update,'SEC Mosaic Plot not yet available'
            seca_ui_overlay_plots, trange=trange, showgeo=state.geolatlon, showmag=state.maglatlon
          endif
        endelse
      endif else begin
        ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
          /center)   
      endelse
     END

     'MAKEPNG': BEGIN
       timeid = widget_info(event.top, find_by_uname='time')
       widget_control, timeid, get_value=valid, func_get_value='spd_ui_time_widget_is_valid'
       if valid then begin
         state.tr_obj->getproperty, starttime=starttime, endtime=endtime
         starttime->getproperty, year=year, month=month, date=date, hour=hour, min=min, sec=sec
        ;round times to 1 minute
        starttime->getproperty, tdouble=t0
        if sec lt 30 then t10=t0-sec else t10=t0+(60-sec) 
        sec=0       
        starttime->setproperty, tdouble=t10
        state.tr_obj->setproperty, starttime=starttime
        starttime->getproperty, tstring=ts
        starttime->getproperty, year=year, month=month, date=date, hour=hour, min=min, sec=sec
        widget_control, timeid, set_value=ts, func_get_value='spd_ui_time_widget_set_value'        
         ; Check which plot
         if state.plot_type[0] EQ 1 then begin
           state.statusBar->update,'PNG files can be downloaded from the web site.'
           state.statusBar->update,'PNG files can be downloaded from the web site.'
           ; For some reason, the & cannot be sent as part of the URL. So we are going to use a single string variable that will be split by PHP.
           datepath = string(year, format='(I04)') + "/" + string(month, format='(I02)') + "/" + string(date, format='(I02)') + "/"
           filename = 'ThemisSEC'+ string(year, format='(I04)') + string(month, format='(I02)') + string(date, format='(I02)') + "_" + $
             string(hour, format='(I02)') + string(min, format='(I02)') + string(sec, format='(I02)') + '.jpeg'
           url = !secs.remote_data_dir + "Quicklook/" + datepath + "/"+filename
           spd_ui_open_url, url
         endif
         plottime=string(year, format='(I04)') + "-" + string(month, format='(I02)') + "-" + string(date, format='(I02)') + "/" + $
           string(hour, format='(I02)') + ":" + string(min, format='(I02)') + ":" + string(sec, format='(I02)')
         trange=[plottime, plottime]
         if state.plot_type[1] EQ 1 then begin
             state.statusBar->update,'Creating EIC Mosaic Plot and png file'
             state.historyWin->update,'Creating EIC Mosaic Plot and png file'
             eics_ui_overlay_plots, trange=trange, /createpng, showgeo=state.geolatlon, showmag=state.maglatlon
         endif
         if state.plot_type[2] EQ 1 then begin
           ;state.statusBar->update,'SEC Mosaic Plot not yet available'
           ;state.shistoryWin->update,'SEC Mosaic Plot not yet available'
           seca_ui_overlay_plots, trange=trange, /createpng, showgeo=state.geolatlon, showmag=state.maglatlon
         endif
       endif else begin
         ok = dialog_message('Invalid start/end time, please use: YYYY-MM-DD/hh:mm:ss', $
           /center)
       endelse
     END

     'QUICKLOOK': BEGIN
       state.plot_type[0]=1
       state.plot_type[1]=0
       state.plot_type[2]=0
     END     
    
     'EICMOSAIC': BEGIN
       state.plot_type[0]=0
       state.plot_type[1]=1
       state.plot_type[2]=0
     END

     'SECMOSAIC': BEGIN
       state.plot_type[0]=0
       state.plot_type[1]=0
       state.plot_type[2]=1
     END

     'GEOLATLON': BEGIN
       if state.geolatlon EQ 1 then state.geolatlon=0 else state.geolatlon=1
     END

     'MAGLATLON': BEGIN
       if state.maglatlon EQ 1 then state.maglatlon=0 else state.maglatlon=1
     END

    'DONE': BEGIN
      state.historyWin->update,'Generate secs overview plot canceled',/dontshow
      state.statusBar->Update,'Generate secs overview plot canceled.'
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      Widget_Control, event.top, /Destroy
      RETURN
    END

    'CHECK_DATA_AVAIL': begin
      spd_ui_open_url, !secs.remote_data_dir+'Quicklook'
    end

    'KEY': begin
      idx=where(state.plot_type EQ 1) 
      spd_ui_overplot_key, state.gui_id, state.historyWin, /modal, secs=idx+1      
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
      trvalsBase = Widget_Base(midBase, /Col, xpad=8)
      keyButtonBase = widget_button(midBase, Value='Plot Keys', UValue='KEY', XSize=80, $
                                    tooltip = 'Displays detailed descriptions of secs overview plot panels.')
    plotLabel = Widget_Label(quickBase, Value='Select Plot Type: ', /align_left)
    plotBase = Widget_Base(quickBase, /Col, xpad=8, /align_left, /exclusive)   
    quicklookButton = Widget_Button(plotBase, Value=' View Quicklook Web Plot ', UValue='QUICKLOOK', $
      uname='quicklook',/align_left)
    eicmosaicButton = Widget_Button(plotBase, Value=' Overplot EICS/THEMIS ASI Mosaics ', $
      UValue='EICMOSAIC', uname='eicmosaic', /align_left)
    secmosaicButton = Widget_Button(plotBase, Value=' Overplot SECA/THEMIS ASI Mosaics ', $
      UValue='SECMOSAIC', uname='secmosaic', /align_left)
    ;displayLabel=Widget_Label(plotBase, Value=' Display Options: ', /align_left)
    labelbase=widget_base(quickBase, /row, xpad=8, /align_left)
    displayLabel=Widget_Label(labelbase, Value=' Display Options: ', /align_left)
    latlonbase=Widget_Base(quickBase, /row, xpad=8, /align_left, /nonexclusive)   
    geoButton=Widget_Button(latlonbase, value=' Show Geographic Lat/Lon ', UValue='GEOLATLON', $
      uname='geolatlon')
    magButton=Widget_Button(latlonbase, value=' Show Magnetic Lat/Lon ', UValue='MAGLATLON', $
      uname='maglatlon')
    goWebBase = Widget_Base(mainBase, /Row, xpad=8, /align_center)
    buttonBase = Widget_Base(mainBase, /row, /align_center)
    davailabilitybutton = widget_button(goWebBase, val = ' Check Data Availability ', $
      uval = 'CHECK_DATA_AVAIL', /align_center, $
      ToolTip = 'Check data availability on the web')
    viewbutton = widget_button(goWebBase, val = ' View Plot ', $
      uval = 'VIEWPLOT', /align_center)
    viewbutton = widget_button(goWebBase, val = ' Make PNG ', $
      uval = 'MAKEPNG', /align_center)
    
; Time range-related widgets
  getresourcepath,rpath
  cal = read_bmp(rpath + 'cal.bmp', /rgb)
  spd_ui_match_background, tlb, cal  

  if ~obj_valid(tr_obj) then begin
    st_text = '2007-03-23/00:00:00.0'
    et_text = '2007-03-24/00:00:00.0'
    tr_obj=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  endif


  timeWidget = spd_ui_time_widget(trvalsBase,statusBar,historyWin,timeRangeObj=tr_obj, $
                                  uvalue='TIME',uname='time', startyear = 1995);, oneday=1 
  

; Main window buttons
  applyButton = Widget_Button(buttonBase, Value='Done', UValue='DONE', XSize=80)

  ;flag denoting successful run
  success = 0

  ;initialize structure to store variables for future calls
  if ~is_struct(data_structure) then begin
    data_structure = { oplot_calls:0, track_one:0b }
  endif

  data_ptr = ptr_new(data_structure)
  plot_type = make_array(3, /integer)
  plot_type[0] = 1
   
  widget_control, geoButton, set_button=1
  widget_control, magButton, set_button=1
  widget_control, quicklookButton, set_button=1
  
  state = {tlb:tlb, gui_id:gui_id, historyWin:historyWin,statusBar:statusBar, $
           tr_obj:tr_obj, plot_type:plot_type, success:ptr_new(success), data:data_ptr, $
           callSequence:callSequence,windowStorage:windowStorage, geolatlon:1, maglatlon:1, $
           loadedData:loadedData}

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
