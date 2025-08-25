;+
;NAME:
;  spd_ui_mva
;
;PURPOSE:
;  Generates the GUI for minimum variance analysis.
;
;HISTORY:
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_mva.pro $
;
;----------------------------------------------
; helper function takes time widget object and  
; adjusts stop time based on the duration
;----------------------------------------------
pro mva_ui_update_time_widget, tr_obj, dur, twidget, event

  tr_obj->getproperty, starttime=starttime, endtime=endtime
  starttime->getproperty, tdouble=st0, sec=sec
  endtime->setproperty, tdouble=st0 + dur
  tr_obj->setproperty, endtime=endtime

  timeid = widget_info(event.top, find_by_uname=twidget)
  widget_control, timeid, set_value=tr_obj, func_get_value='spd_ui_time_widget_set_value'

end

;-------------------------------------------------
; Update the pull down menu widgets whenever an
; instrument is selected
;-------------------------------------------------
pro mva_ui_update_instrument_widgets, state, event

  if event.str NE state.currentinstr then begin

    dtypeid=widget_info(state.tlb, find_by_uname='data')
    coordid=widget_info(state.tlb, find_by_uname='coordinate')

    Case state.mission of
      'THEMIS' : begin 
        widget_control, coordid, set_value=state.thmCoordinateArray
        widget_control, coordid, sensitive=1
        if strpos(event.str, 'Magnetic Field') NE -1 && state.currentinstr NE 'Magnetic Field' then begin
          widget_control, dtypeid, set_value=state.thmMagdataArray
        endif
        if strpos(event.str, 'Electric Field') NE -1 && state.currentinstr NE 'Electric Field' then begin
          widget_control, dtypeid, set_value=state.thmElecdataArray
        endif
        if strpos(event.str, 'Particle Data') NE -1 && state.currentinstr NE 'Particle Field' then begin
          widget_control, dtypeid, set_value=state.thmPartdataArray
          widget_control, coordid, sensitive=0
        endif
        if strpos(event.str, 'Velocity') NE -1 && state.currentinstr NE 'Velocity' then begin
          widget_control, dtypeid, set_value=state.thmVeldataArray
        endif
      end      
      'MMS' : begin
        widget_control, coordid, set_value=state.mmsCoordinateArray
        widget_control, coordid, sensitive=1
        if strpos(event.str, 'Magnetic Field') NE -1 && state.currentinstr NE 'Magnetic Field' then begin
          widget_control, dtypeid, set_value=state.mmsdataArray
        endif
        if strpos(event.str, 'Electric Field') NE -1 && state.currentinstr NE 'Electric Field' then begin
          widget_control, dtypeid, set_value=state.mmsdataArray
        endif
        if strpos(event.str, 'Particle Data') NE -1 && state.currentinstr NE 'Particle Field' then begin
          widget_control, dtypeid, set_value=state.mmsdataArray
          widget_control, coordid, sensitive=0
        endif
        if strpos(event.str, 'Velocity') NE -1 && state.currentinstr NE 'Velocity' then begin
          widget_control, dtypeid, set_value=state.mmsdataArray
        endif
      end
      else:

    Endcase
    
    state.currentinstr = event.str

  endif

end

;------------------------------------------------
; this function will create a matrix based on 
; the mutually exclusive buttons on the gui
;-----------------------------------------------
function mva_ui_get_eigenbuttons, tlb
   
   ; make the array 
   eigenbuttons=make_array(3,3,/double)
   
   ; get button widget ids
   e1xid = widget_info(tlb, find_by_uname='e1x') 
   e1yid = widget_info(tlb, find_by_uname='e1y')
   e1zid = widget_info(tlb, find_by_uname='e1z')
   e2xid = widget_info(tlb, find_by_uname='e2x')
   e2yid = widget_info(tlb, find_by_uname='e2y')
   e2zid = widget_info(tlb, find_by_uname='e2z')
   e3xid = widget_info(tlb, find_by_uname='e3x')
   e3yid = widget_info(tlb, find_by_uname='e3y')
   e3zid = widget_info(tlb, find_by_uname='e3z')
   
   ; get button values
   eigenbuttons[0,0]=widget_info(e1xid, /button_set)
   eigenbuttons[1,0]=widget_info(e1yid, /button_set)
   eigenbuttons[2,0]=widget_info(e1zid, /button_set)
   eigenbuttons[0,1]=widget_info(e2xid, /button_set)
   eigenbuttons[1,1]=widget_info(e2yid, /button_set)
   eigenbuttons[2,1]=widget_info(e2zid, /button_set)
   eigenbuttons[0,2]=widget_info(e3xid, /button_set)
   eigenbuttons[1,2]=widget_info(e3yid, /button_set)
   eigenbuttons[2,2]=widget_info(e3zid, /button_set)

   return, eigenbuttons

end

;--------------------------------------------------
; This function takes the rotation matrix from
; minvar_matrix_make and applies the selectec
; eigen buttons
;--------------------------------------------------
function mva_ui_apply_eigenbuttons, tlb, data

  eigenbuttons = mva_ui_get_eigenbuttons(tlb)
 
  ;eigenvector L
  idx=where(eigenbuttons[*,0] eq 1)
  index=where(data.y[*,0,idx] le 0, ncnt)
  if ncnt GT 0 then data.y[*,0,*]=-data.y[*,0,*]

  ;eigenvector M
  idx=where(eigenbuttons[*,1] eq 1)
  index=where(data.y[*,1,idx] le 0, ncnt)
  if ncnt GT 0 then data.y[*,1,*]=-data.y[*,1,*]

  ;eigenvector N
  idx=where(eigenbuttons[*,2] eq 1)
  index=where(data.y[*,2,idx] le 0, ncnt)
  if ncnt GT 0 then data.y[*,2,*]=-data.y[*,2,*]

  return, data

end

;----------------------------------------------------
; Print the results of the analysis to the results
; text box on the right hand side of the gui
;----------------------------------------------------
pro mva_ui_print_results, state, eigenvectors, eigenvalues, npts, lstruc

  ; Create string array for results text box
  results = make_array(14, /string)
  results[0] = 'Run ' + strtrim(string(state.runCount),1) + '==================================='
  results[1] = 'Satellite: ' + lstruc.satellite
  results[2] = 'Instrument Type: ' + lstruc.instrtype
  results[3] = 'data: ' + lstruc.data
  results[4] = 'Coordinate: ' + lstruc.coordinate
  results[5] = 'Start Time: ' + time_string(lstruc.timeRange[0])
  results[6] = 'Stop Time:  ' + time_string(lstruc.timeRange[1])

  format_eigen = '(f6.3)'
  results[7]='Eigenvalues: '
  eigenstrings=string(eigenvalues, format=format_eigen)
  for i=0,2 do results[7] = results[7] + eigenstrings[i] + ' ' 
  results[8]='L: '
  eigenstrings=string(eigenvectors[*,0,*], format=format_eigen)
  for i=0,2 do results[8] = results[8] + eigenstrings[i] + ' '
  results[9]='M: '
  eigenstrings=string(eigenvectors[*,1,*], format=format_eigen)
  for i=0,2 do results[9] = results[9] + eigenstrings[i] + ' '
  results[10]='N: '
  eigenstrings=string(eigenvectors[*,2,*], format=format_eigen)
  for i=0,2 do results[10] = results[10] + eigenstrings[i] + ' '
  results[11] = 'Data points in analysis: ' + strtrim(string(npts),1)
  results[12] = '==================================================='
  results[13] = ' '
  
  resultid = widget_info(state.tlb, find_by_uname='resulttext')
  widget_control, resultid, get_value=resultstring
  append_array, resultstring, results
  widget_control, resultid, set_value=resultstring 
  
end

; -----------------------------------------------------
;  This function will gather all the values the 
;  user has selected and create a load data structure
;------------------------------------------------------
function mva_ui_get_load_data_structure, tlb, tr_obj

  tr_obj->getproperty, starttime=starttime, endtime=endtime
  starttime->getproperty, tdouble=st0, sec=sec
  endtime->getproperty, tdouble=et0, sec=sec
  trange=[st0,et0]  
  satid=widget_info(tlb, find_by_uname='satellite')
  satname=widget_info(satid, /combobox_gettext)
  probe=strlowcase(strmid(satname,strlen(satname)-1))
  instrid=widget_info(tlb, find_by_uname='instr')
  itype=widget_info(instrid, /combobox_gettext)
  dtypeid=widget_info(tlb, find_by_uname='data')
  dtype=widget_info(dtypeid, /combobox_gettext)
  coordid=widget_info(tlb, find_by_uname='coordinate')
  coord=widget_info(coordid, /combobox_gettext)
  
  load_struct = { timeRange:trange, $
                  satellite:satname, $
                  probe:probe, $
                  instrtype:itype, $
                  data:dtype, $
                  coordinate:coord }
                  
   return, load_struct
   
end

; -------------------------------------------------------
;  This function checks to see if the selected data is
;  already loaded (no point in loading it twice)
; --------------------------------------------------------
function mva_ui_check_loaded_data, load_struct, tvar

  ; retrive time range from GUI to compare
  st = load_struct.timeRange[0]
  et = load_struct.timeRange[1]

  ; check if this tplot variable is loaded
  ; if it is then check that the timeframe is correct
  tn=tnames(tvar)
  if tn EQ '' then begin
    load=1
  endif else begin
    get_data, tn, data=d
    npts = n_elements(d.x)
    if (st GE d.x[0] AND st LE d.x[npts-1]) && (et GE d.x[0] AND et LE d.x[npts-1]) then load=0 else load=1
  endelse

  return, load

end

; -------------------------------------------------------
;  This function handles the loading of data for the 
;  THEMIS Mission
; --------------------------------------------------------
function mva_ui_load_themis, load_struct

   Case load_struct.instrtype of
     'Magnetic Field': begin
        tvar = 'th'+ load_struct.probe + '_' + load_struct.data + '_' + load_struct.coordinate
        load = mva_ui_check_loaded_data(load_struct, tvar)
        thm_load_fgm, trange=load_struct.timeRange, probe=load_struct.probe, level=2, $
          datatype=load_struct.data, coord=load_struct.coordinate
;        tvar = 'th'+ load_struct.probe + '_' + load_struct.data + '_' + load_struct.coordinate
     end
     'Electric Field': begin
        tvar = 'th'+ load_struct.probe + '_' + load_struct.data
        thm_load_efi, trange=load_struct.timeRange, probe=load_struct.probe, level=1, $
          datatype=load_struct.data
;        tvar = 'th'+ load_struct.probe + '_' + load_struct.data
     end
     'Particle Data': begin
       dtype = load_struct.data + '_en_eflux'
       tvar = 'th'+ load_struct.probe + '_' + load_struct.data + '_en_eflux'
       thm_load_esa, trange=load_struct.timeRange, probe=load_struct.probe, $
         datatype=dtype
;       tvar = 'th'+ load_struct.probe + '_' + load_struct.data + '_en_eflux'
     end
     'Velocity': begin
        dtype = load_struct.data + '_velocity_' + load_struct.coordinate
        tvar = 'th'+ load_struct.probe + '_' +dtype
        thm_load_esa, trange=load_struct.timeRange, probe=load_struct.probe, $
          datatype=dtype
;        tvar = 'th'+ load_struct.probe + '_' +dtype
      end
      else:
    endcase

    ; check that data was loaded and if not return err
    if undefined(tvar) OR tnames(tvar) EQ '' then tvar='err'
    
    return, tvar
    
end

; -------------------------------------------------------
;  This function handles the loading of data for the
;  MMS Mission
; --------------------------------------------------------
function mva_ui_load_mms, load_struct

  Case load_struct.instrtype of
    'Magnetic Field': begin
      coordformat = '*'+load_struct.coordinate+'*'
      mms_load_fgm, trange=load_struct.timeRange, probe=load_struct.probe, level='l2', $
        data_rate=load_struct.data, varformat=coordformat
      tvar = 'mms'+ load_struct.probe + '_fgm_b_' + load_struct.coordinate + '_' + load_struct.data + '_l2_bvec'
    end
    'Electric Field': begin
    end
    'Particle Data': begin
    end
    'Velocity': begin
    end
    else:
  endcase
 
  ; check that mms data was in fact loaded
  if undefined(tvar) OR tnames(tvar) EQ '' then tvar='err'

  return, tvar
  
end

;---------------------------------
; MAIN EVENT HANDLER for GUI
;---------------------------------
pro spd_ui_mva_event,event

  compile_opt hidden,idl2

  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
      /noname, /center, title='Error in MVA')

    if is_struct(state) then begin
      ;send error message
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]

      if widget_valid(state.tlb) && obj_valid(state.historyWin) then begin
        spd_gui_error,state.tlb,state.historyWin
      endif

      ;restore state
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy

    endif

    widget_control, event.top,/destroy

    RETURN
  ENDIF

  widget_control, event.handler, Get_UValue=state, /no_copy

  ;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    thm_ui_slice2d_message,'Widget Killed',hw=state.historywin, /dontshow
    widget_control, event.top, set_uval=state, /no_copy
    widget_control, event.top, /destroy
    return
  endif

  ;Options
  widget_control, event.id, get_uvalue = uval

  ;not all widgets are assigned uvalues
  if is_string(uval) then begin

    case uval of

      'SATELLITE': begin
         ; update widgets only if the mission selected has changed
         if event.str NE state.currentSatellite then begin
           dtypeid=widget_info(state.tlb, find_by_uname='data')
           coordid=widget_info(state.tlb, find_by_uname='coordinate')          
           if strpos(event.str, 'THEMIS') NE -1 && state.mission NE 'THEMIS' then begin
              Case state.currentinstr of 
                'Magnetic Field': thmDataArray = state.thmMagdataArray
                'Electric Field': thmDataArray = state.thmElecdataArray
                'Particle Data': thmDataArray = state.thmPartdataArray
                'Velocity': thmDataArray = state.thmVeldataArray
              else:
              endcase              
              widget_control, dtypeid, set_value=thmdataArray
              widget_control, coordid, set_value=state.thmCoordinateArray
              state.mission = 'THEMIS'   
           endif 
           if strpos(event.str, 'MMS') NE -1 && state.mission NE 'MMS' then begin
             widget_control, dtypeid, set_value=state.mmsdataArray
             widget_control, coordid, set_value=state.mmsCoordinateArray
             state.mission = 'MMS'
           endif
           if strpos(event.str, 'Cluster') NE -1 && state.mission NE 'Cluster' then begin
             widget_control, dtypeid, set_value=state.clusterdataArray
             state.mission = 'Cluster'
           endif
           state.currentSatellite = event.str
         endif
      end

      'INSTRUMENT': begin
          mva_ui_update_instrument_widgets, state, event
      end

      'PLOT_DURATION' : begin
        if event.valid then begin
          If (event.value GT 0) Then Begin
            state.plotdur = event.value
            ext_string = strcompress(string(event.value))
            state.statusbar -> update, 'Plot Duration set to '+ext_string
            twidget='time_plot_widget'
            mva_ui_update_time_widget, state.timeRangeObjPlot, state.plotdur, twidget, event
            state.statusbar -> update, 'Stop time in Data section updated based on user specified duration'
          Endif Else Begin
            plotdurid=widget_info(state.tlb, find_by_uname='plotduration')
            widget_control, plotdurid, set_value = state.plotdur
            state.statusbar -> update, 'Invalid or Zero Plot Duration. '
          Endelse
        endif else begin
          plotdurid=widget_info(state.tlb, find_by_uname='plotduration')
          widget_control, plotdurid, set_value = state.plotdur
          state.statusBar->update, 'Invalid or Zero Plot Duration Input.'
        endelse
      end

      'MVA_DURATION' : begin
        if event.valid then begin
          If(event.value GT 0) Then Begin
            state.mvadur = event.value
            ext_string = strcompress(string(event.value))
            state.statusbar -> update, 'Analysis Duration set to '+ext_string
            twidget='time_mva_widget'
            mva_ui_update_time_widget, state.timeRangeObjmva, state.mvadur, twidget, event
            state.statusbar -> update, 'Stop time in Analysis section updated based on user specified duration'            
          Endif Else Begin
            mvadurid=widget_info(state.tlb, find_by_uname='mvaduration')
            widget_control, mvadurid, set_value = state.mvadur
            state.statusbar -> update, 'Invalid or Zero Analysis Duration: '
          Endelse
        endif else begin
          mvadurid=widget_info(state.tlb, find_by_uname='mvaduration')
          widget_control, mvadurid, set_value = state.mvadur
          state.statusBar->update, 'Invalid or Zero Analysis Duration Input.'
        endelse
      end
      
      'TIME_PLOT_WIDGET' : begin
         state.timeRangeObjPlot->getproperty, starttime=starttime, endtime=endtime
         starttime->getproperty, tdouble=st0, sec=sec
         endtime->getproperty, tdouble=et0, sec=sec
         tdiff = long(et0-st0)
         if tdiff NE state.plotdur OR tdiff GT 0 then begin
           ; change plot widgets 
           state.plotdur = tdiff
           plotdurid=widget_info(state.tlb, find_by_uname='plotduration')
           widget_control, plotdurid, set_value = tdiff
           ;and mva widgets but only if time is outside of time plot range
           state.TimeRangeObjmva->getproperty, starttime=starttime, endtime=endtime
           starttime->getproperty, tdouble=st1, sec=sec
           endtime->getproperty, tdouble=et1, sec=sec
           if st1 LT st0 OR st1 GT et0 then begin
              st1=st0
              starttime->setproperty, tdouble=st1
           endif
           if et1 LT st0 OR et1 GT et0 then begin
              et1=et0
              endtime->setproperty, tdouble=et1
           endif
           state.TimeRangeObjmva->setproperty, starttime=startime, endtime=endtime
           state.mvadur = et1-st1
           twidget='time_mva_widget'
           mva_ui_update_time_widget, state.timeRangeObjmva, state.mvadur, twidget, event 
           mvadurid=widget_info(state.tlb, find_by_uname='mvaduration')
           widget_control, mvadurid, set_value = state.mvadur
         endif
      end

      'TIME_MVA_WIDGET' : begin
          state.timeRangeObjMVA->getproperty, starttime=starttime, endtime=endtime
          starttime->getproperty, tdouble=st0, sec=sec
          endtime->getproperty, tdouble=et0, sec=sec
          tdiff = long(et0-st0)
          if tdiff NE state.mvadur then begin
            state.mvadur = tdiff
            mvadurid=widget_info(state.tlb, find_by_uname='mvaduration')
            widget_control, mvadurid, set_value = tdiff
          endif
      end
      
      'PLOT_DATA' : begin

         load_struct=mva_ui_get_load_data_structure(state.tlb, state.timeRangeObjplot)
         Case state.mission of
           'THEMIS' : begin
              tvar = mva_ui_load_themis(load_struct)
           end
           'MMS' : begin
             state.statusbar -> update, 'MVA gui has not yet implemented MMS data'
              ;tvar = mva_ui_load_mms(load_struct)
           end
           'Cluster' : begin
              state.statusbar -> update, 'SPEDAS does not yet have routines to load Cluster data'
           end
           else:
         endcase
                   
         ; plot the data if tvar is defined
         if defined(tvar) && tvar NE 'err' then begin
           tplot,  tvar
           ; set the time frame
           state.timeRangeObjplot->getproperty, starttime=starttime, endtime=endtime
           starttime->getproperty, tdouble=st0, sec=sec
           endtime->getproperty, tdouble=et0, sec=sec
           tlimit, st0, et0
           state.plotWindow = !d.WINDOW
         endif else begin
           ; remove if statement as soon as mms and cluster data have been implemented
           if state.mission EQ 'THEMIS' then state.statusbar -> update, 'Data was not loaded. Check data availability.' 
         endelse
                   
      end
      
      'ANALYZE': begin

        load_struct=mva_ui_get_load_data_structure(state.tlb, state.timeRangeObjmva)

        Case state.mission of
          'THEMIS' : begin
            tvar = mva_ui_load_themis(load_struct)
          end
          'MMS' : begin
            state.statusbar -> update, 'MVA gui has not yet implemented MMS data'
            ;tvar = mva_ui_load_mms(load_struct)
          end
          'Cluster' : begin
            state.statusbar -> update, 'SPEDAS does not yet have routines to load Cluster data'
          end
          else:
        endcase

        ; create the rotation matrix only if data was loaded
        if defined(tvar) && tvar NE 'err' then begin
          tvar_mva_mat = tvar + '_mva_mat'
          tvar_eigen = tvar + '_eigen_val'
          minvar_matrix_make, tvar, tstart=load_struct.timerange[0], tstop=load_struct.timerange[1], $
             newname=tvar_mva_mat, evname=tvar_eigen
          get_data,tvar_mva_mat,data=data
          ; find which eigen buttons were selected and apply to the matrix
          new_data = mva_ui_apply_eigenbuttons(state.tlb, data)
          store_data,tvar_mva_mat,data=new_data
   
          ;rotate the mag data into the LMN coordinate
          tvar_lmn = 'th'+ load_struct.probe + '_' + load_struct.data + '_lmn'
          tvector_rotate,tvar_mva_mat,tvar,newname=tvar_lmn
  
          ; get and print results
          get_data, tvar_lmn, data=d, dlimits=dl, limits=l
          get_data, tvar_eigen, data = d_eigen        
          mva_ui_print_results, state, new_data.y, d_eigen.y, n_elements(d.x), load_struct
          state.runCount = state.runCount+1       
        endif else begin
          ; remove if statement as soon as mms and cluster data have been implemented
          if state.mission EQ 'THEMIS' then state.statusbar -> update, 'Data was not loaded. Check data availability.'
        endelse
               
       end
       
      'PLOT_MVA' : begin

        load_struct=mva_ui_get_load_data_structure(state.tlb, state.timeRangeObjmva)
        Case state.mission of
          'THEMIS' : begin
            tvar = mva_ui_load_themis(load_struct)
          end
          'MMS' : begin
            state.statusbar -> update, 'MVA gui has not yet implemented MMS data'
            ;tvar = mva_ui_load_mms(load_struct)
          end
          'Cluster' : begin
            state.statusbar -> update, 'SPEDAS does not yet have routines to load Cluster data'
          end
          else:
        endcase

        ; create the rotation matrix if data was loaded
        if defined(tvar) && tvar NE 'err' then begin
          tvar_mva_mat = tvar + '_mva_mat'
          tvar_eigen = tvar + '_eigen_val'
          minvar_matrix_make, tvar, tstart=load_struct.timerange[0], tstop=load_struct.timerange[1], $
            newname=tvar_mva_mat, evname=tvar_eigen
          get_data,tvar_mva_mat,data=data
          ; find which eigen buttons were selected and apply to the matrix
          new_data = mva_ui_apply_eigenbuttons(state.tlb, data)
          store_data,tvar_mva_mat,data=new_data
  
          ;rotate the mag data into the LMN coordinate
          tvar_lmn = 'th'+ load_struct.probe + '_' + load_struct.data + '_lmn'
          tvector_rotate,tvar_mva_mat,tvar,newname=tvar_lmn
          ; update labels and coordinate system
          get_data, tvar_lmn, data=d, dlimits=dl, limits=l
          dl.data_att.coord_sys = 'lmn'
          dl.labels = ['bl', 'bm', 'bn']
          dl.ytitle = tvar_lmn
          dl.ysubtitle = '[nT LMN]'
          dl.colors = [6,4,2]
          store_data, tvar_lmn, data=d, dlimits=dl, limits=l
   
          tplot,  [tvar, tvar_lmn]
          ; set the time frame based on the mva widget
          state.timeRangeObjmva->getproperty, starttime=starttime, endtime=endtime
          starttime->getproperty, tdouble=st1, sec=sec
          endtime->getproperty, tdouble=et1, sec=sec
          tlimit, st1, et1
          state.mvaWindow = !d.WINDOW
        endif else begin
          ; remove if statement as soon as mms and cluster data have been implemented
          if state.mission EQ 'THEMIS' then state.statusbar -> update, 'Data was not loaded. Check data availability.' 
        endelse
        
      end

      'ZOOM': begin
         tplot_options, window = state.plotWindow
         tlimit, new_tvars=new_tvars
         zoom_time = new_tvars.options.trange
         ; update duration spinner
         zoom_dur = zoom_time[1] - zoom_time[0]
         if zoom_dur LE 0 then begin
             state.statusbar -> update, 'Invalid time. Stop time is less than start time.'
         endif else begin
           ; update duration spinner
           state.mvadur = zoom_dur
           mvadurid=widget_info(state.tlb, find_by_uname='mvaduration')
           widget_control, mvadurid, set_value = zoom_dur
           ; update the time_object
           stat = state.timeRangeObjmva->SetStartTime(time_string(zoom_time[0]))
           stat = state.timeRangeObjmva->SetEndTime(time_string(zoom_time[1]))
           twidget='time_mva_widget'
           mva_ui_update_time_widget, state.timeRangeObjmva, state.mvadur, twidget, event
         endelse
      end
      
      'HELP': begin
        spd_ui_mva_help, state.tlb
      end
      
      'CLOSE': begin
        Widget_Control, event.top, /destroy
        return
      end

      else:
    endcase
  endif

  Widget_Control, event.handler, Set_UValue=state, /No_Copy

  return

end


pro spd_ui_mva, gui_ID=gui_id, $
                _extra=dummy ;SPEDAS API req

  compile_opt idl2,hidden

  ;load bitmap resources
  getresourcepath,rpath

  if keyword_set(gui_ID) then begin
    tlb = Widget_Base(/col, /Align_Top, /Align_Left, title='MVA GUI', group_leader= gui_id, /floating, $
      /modal, YPad=1, /tlb_kill_request_events, event_pro='spd_ui_mva_event')
  endif else begin
    tlb = Widget_Base(/col, /Align_Top, /Align_Left, title='MVA GUI', YPad=1,event_pro='spd_ui_mva_event') 
    gui_ID=tlb
  endelse
    
  ;***************
  ;    MVA Bases
  ;***************
  mainBase = Widget_Base(tlb, Title='MVA', /row, YPad=1)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center)
  statusBase = Widget_Base(tlb, /Row, /Align_Center)

  leftBase = widget_base(mainBase, ypad=2, /col)
  rightBase = widget_base(mainBase, ypad=1, /col)
  
  ; Bases for Left Side of GUI
  upperBase = widget_base(leftBase, /col) ;, /frame)
  selectBase = widget_base(upperBase, /row)
  satelliteBase = widget_base(selectBase, /col)
  instrBase = widget_base(selectBase, /col)
  dataBase = widget_base(selectBase, /col)
  coordinateBase = widget_base(selectBase, /col)
  timePlotBase = widget_base(upperBase, /row, /frame)
  selectTimeBase = widget_base(timePlotBase, /col)
 
  mvaBase = widget_base(leftBase, /row, /frame)
  mvaTimePlotBase = widget_base(mvaBase, /col)
  mvaTimeBase = widget_base(mvaTimePlotBase, /col)
  vectorBase = widget_base(mvaTimePlotBase, /row)
  eigenBase = widget_base(vectorBase, /col)
  plotmvaBase = widget_base(vectorBase, /col)
  e1Base = widget_base(eigenBase, /row)
  e2Base = widget_base(eigenBase, /row)
  e3Base = widget_base(eigenBase, /row)

  statusBar = obj_new('spd_ui_message_bar', statusbase,  Xsize=105, YSize=1, $
    value='Status information is displayed here.')
  if ~obj_valid(historywin) then begin
    historyWin = Obj_New('SPD_UI_HISTORY', 0L, tlb);dummy history window in absence of gui
  endif
  
  ; 
  ; UPPER LEFT HAND SECTION 
  ; 
  ; create mission/data selection widgets (pulldown menus and titles)
  satelliteLabel = widget_label(satelliteBase, value='Satellite:', /align_left)
  satelliteArray = ['THEMIS-A', 'THEMIS-B', 'THEMIS-C', 'THEMIS-D', 'THEMIS-E', $
              'MMS1', 'MMS2', 'MMS3', 'MMS4', 'Cluster1', 'Cluster2', 'Cluster3', $
              'Cluster4']
  satelliteCombo = widget_combobox(satelliteBase,$
    value=satelliteArray,$
    uvalue='SATELLITE',$
    uname='satellite')
  currentSatellite=satelliteArray[1]
  mission = 'THEMIS'      ; default to THEMIS
  widget_control, satelliteCombo, set_combobox_select = 1 

  instrLabel = widget_label(instrBase, value='Instrument Type:', /align_left)
  instrArray = ['Magnetic Field', 'Electric Field', 'Particle Data', 'Velocity']
  instrCombo = widget_combobox(instrBase,$
    value=instrArray,$
    uvalue='INSTRUMENT',$
    uname='instr')
  currentinstr=instrArray[0]
  
  dataLabel = widget_label(dataBase, value='Data Type:', /align_left)
  thmMagdataArray = ['fgh', 'fgl', 'fgs']
  thmElecdataArray = ['eff', 'efp', 'efw']
  thmPartdataArray = ['peif', 'peir', 'peib', 'peim', 'peef', 'peer', 'peeb', 'peem']
  thmVeldataArray = thmPartdataArray
  
  mmsdataArray = ['srvy', 'brst']
  clusterdataArray = ['5vps', 'full', 'spin']
  dataCombo = widget_combobox(dataBase,$
    value=thmMagdataArray,$
    uvalue='data',$
    uname='data')

  coordinateLabel = widget_label(coordinateBase, value='Coordinate:', /align_left)
  thmCoordinateArray = ['gsm', 'gse', 'dsl']
  mmsCoordinateArray = [ 'dmpa', 'gsm', 'gse']
  coordinateCombo = widget_combobox(coordinateBase,$
    value=thmcoordinateArray,$
    uvalue='COORDINATE',$
    uname='coordinate')
    
    
  ; time widget
  st_text = '2009-02-27/07:50:00'
  et_text = '2009-02-27/07:54:00'
  tr_obj_plot=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  ; set the default date, the setting time above does not work because tr_obj is defined
  stat = tr_obj_plot->SetStartTime(st_text)
  stat = tr_obj_plot->SetEndTime(et_text)
  timePlotWidget = spd_ui_time_widget(selectTimeBase,$
    statusBar,$
    historyWin,$
    oneday=0,$
    timeRangeObj=tr_obj_plot,$
    uvalue='TIME_PLOT_WIDGET',$
    uname='time_plot_widget')

  ; duration spinner
  durBase = widget_base(selectTimeBase, /row)
  durLabel = widget_label(durBase, value='Duration (sec):   ')
  durIncrement = spd_ui_spinner(durBase, $
    Increment=1, Value=240, UValue='PLOT_DURATION', UName='plotduration',min_value=1, $
    tooltip='When the duration is changed, the stop time will be changed to reflect the new duration')
  plotdur = 240
 
  ; plot data button
  plotDataBase = widget_base(timePlotBase, /col,/align_center)
  plotDataButton = widget_button(plotDataBase, value='Plot', uval='PLOT_DATA', $
    tooltip='This button will plot the selected data. Data will automatically loaded (if not already loaded).')
 
  ;
  ; LOWER LEFT HAND SECTION
  ;
  ; create analysis data selection widgets
  ; time widget
  st_text = '2009-02-27/07:51:00'
  et_text = '2009-02-27/07:52:00'
  tr_obj_mva=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  ; set the default date, the setting time above does not work because tr_obj is defined
  stat = tr_obj_mva->SetStartTime(st_text)
  stat = tr_obj_mva->SetEndTime(et_text)
  timeMVAWidget = spd_ui_time_widget(mvaTimeBase,$
    statusBar,$
    historyWin,$
    oneday=0,$
    timeRangeObj=tr_obj_mva,$
    uvalue='TIME_MVA_WIDGET',$
    uname='time_mva_widget')

  ; duration spinner
  durmvaBase = widget_base(mvaTimeBase, /row)
  durmvaLabel = widget_label(durmvaBase, value='Duration (sec):   ')
  durmvaIncrement = spd_ui_spinner(durmvaBase, $
    Increment=1, Value=60, UValue='MVA_DURATION', UName='mvaduration',min_value=1, $
    tooltip='When the duration is changed, the stop time will be changed to reflect the new duration')
  mvadur = 60

  ; eigen values
  e1Label = widget_label(e1Base, value='Eigenvector 1(L):')
  e1ButtonBase = widget_base(e1Base, /row, xpad=7, /exclusive)
  e1XButton = widget_button(e1ButtonBase, value='X', UValue='E1X', UName='e1x', $
    tooltip='This selects the X component of the L vector to be positive')
  e1YButton = widget_button(e1ButtonBase, value='Y', UValue='E1Y', UName='e1y', $
    tooltip='This selects the Y component of the L vector to be positive')
  e1ZButton = widget_button(e1ButtonBase, value='Z', UValue='E1Z', UName='e1z', $
    tooltip='This selects the Z component of the L vector to be positive')
  e2Label = widget_label(e2Base, value='Eigenvector 2(M):')
  e2ButtonBase = widget_base(e2Base, /row, xpad=7, /exclusive)
  e2XButton = widget_button(e2ButtonBase, value='X', UValue='E2X', UName='e2x', $
    tooltip='This selects the X component of the M vector to be positive')
  e2YButton = widget_button(e2ButtonBase, value='Y', UValue='E2Y', UName='e2y', $
    tooltip='This selects the Y component of the M vector to be positive')
  e2ZButton = widget_button(e2ButtonBase, value='Z', UValue='E3Z', UName='e2z', $
    tooltip='This selects the Z component of the M vector to be positive')
  e3Label = widget_label(e3Base, value='Eigenvector 3(N):')
  e3ButtonBase = widget_base(e3Base, /row, xpad=7, /exclusive)
  e3XButton = widget_button(e3ButtonBase, value='X', UValue='E3X', UName='e3x', $
    tooltip='This selects the X component of the N vector to be positive')
  e3YButton = widget_button(e3ButtonBase, value='Y', UValue='E3Y', UName='e3y', $
    tooltip='This selects the Y component of the N vector to be positive')
  e3ZButton = widget_button(e3ButtonBase, value='Z', UValue='E3Z', UName='e3z', $
    tooltip='This selects the Z component of the N vector to be positive')
  widget_control, e1XButton, /set_button
  widget_control, e2YButton, /set_button
  widget_control, e3ZButton, /set_button
  
  ; plot analysis button
  plotmvaBase = widget_base(mvaBase, /col,/align_center)
  zoomButton = widget_button(plotmvaBase, value='Zoom In', uval='ZOOM', $
     tooltip = 'Click this button to zoom in, then on plot left click for start, left click again for stop')
  analysismvaButton = widget_button(plotmvaBase, value='Analyze', uval='ANALYZE', $
     tooltip = 'This button will perform a minimum variance analysis of the data. Results will be displayed in the right hand text box')
  plotmvaButton = widget_button(plotmvaBase, value='Plot Data in New Coordinate System', uval='PLOT_MVA', /dynamic_resize, $ 
     tooltip = 'This button will display 2 plots of the data one in the coordinate system selected above and one in the LMN coordinate system')
  
  ;
  ; RESULTS SECTION
  ;
  resultLabel =  widget_label(rightBase, value='Results:', /align_left, /align_top)
  resultBase = widget_base(rightBase, /col, /frame)
  resultText = widget_text(resultBase, ysize=33, /scroll, uname='resulttext')

  doneButton = widget_button(buttonBase, value='Close', uval='CLOSE', $
    tooltip = 'Click this button when you are done with your analysis. Tplot variables created during this session will be preserved.')
  helpButton = widget_button(buttonBase, value='Help', uval='HELP')
       
  state = {tlb:tlb,$
    timeRangeObjPlot:tr_obj_plot, $
    timeRangeObjmva:tr_obj_mva, $
    statusBar:statusBar, $
    historyWin:historyWin, $
    mission:mission, $
    plotDur:plotdur, $
    mvaDur:mvadur, $
    plotWindow:0, $
    mvaWindow:0, $
    resultsString:[''], $
    runCount:1, $
    thmMagdataArray:thmMagdataArray, $
    thmElecdataArray:thmElecdataArray, $
    thmPartdataArray:thmPartdataArray, $
    thmVeldataArray:thmVeldataArray, $
    mmsdataArray:mmsdataArray, $
    clusterdataArray:clusterdataArray, $
    thmCoordinateArray:thmCoordinateArray, $
    mmsCoordinateArray:mmsCoordinateArray, $    
    currentSatellite:currentSatellite, $
    currentinstr:currentinstr}

  Centertlb, tlb
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_mva', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  heap_gc   ; clean up memory before exit
  
  RETURN

end
