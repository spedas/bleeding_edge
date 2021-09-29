;+
;NAME:
;  spd_ui_mdd_std
;
;PURPOSE:
;  Generates the GUI for minimum variance analysis.
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/ace/spedas_plugin/ace_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro mdd_ui_update_time_widget, tr_obj, dur, twidget, event
  ; takes time widget object and adjusts stop time based on the duration

  tr_obj->getproperty, starttime=starttime, endtime=endtime
  starttime->getproperty, tdouble=st0, sec=sec
  endtime->setproperty, tdouble=st0 + dur
  tr_obj->setproperty, endtime=endtime

  timeid = widget_info(event.top, find_by_uname=twidget)
  widget_control, timeid, set_value=tr_obj, func_get_value='spd_ui_time_widget_set_value'

end

; ----------------------------------------------------------
;  This procedure will update the widgets associated
;  with THEMIS when the user selects/changes in the GUI.
;  Pulldown menus in the satellite selection section change
;  depending on the type of data selected/
;-----------------------------------------------------------
pro mdd_ui_update_thm_instrument, state, event

  if event.str NE state.thmStructure.instr then begin

    ; get the id associated with the THEMIS data and coordinate pulldown menus
    dtypeid=widget_info(state.tlb, find_by_uname='thm_data')
    coordid=widget_info(state.tlb, find_by_uname='thm_coordinate')

    widget_control, coordid, set_value=state.thmCoordinateArray
    widget_control, coordid, sensitive=1
    ; update the menu values based on the type of data selected
    if strpos(event.str, 'Magnetic Field') NE -1 && state.thmStructure.instr NE 'Magnetic Field' then $
      widget_control, dtypeid, set_value=state.thmMagdataArray
    if strpos(event.str, 'Electric Field') NE -1 && state.thmStructure.instr NE 'Electric Field' then $
       widget_control, dtypeid, set_value=state.thmElecdataArray
    if strpos(event.str, 'Velocity') NE -1 && state.thmStructure.instr NE 'Velocity' then $
       widget_control, dtypeid, set_value=state.thmVeldataArray

    state.thmStructure.instr = event.str
    state.statusbar -> update, 'Instrument type updated to '+event.str+'.'

  endif

end

; ----------------------------------------------------------
;  This procedure will update the widgets associated
;  with MMS when the user selects/changes in the GUI 
;  Pulldown menus in the satellite selection section change
;  depending on the type of data selected/
;-----------------------------------------------------------
pro mdd_ui_update_mms_instrument, state, event

  if event.str NE state.mmsStructure.instr then begin

    ; get the id associated with the MMS data and coordinate pulldown menus
    dtypeid=widget_info(state.tlb, find_by_uname='mms_data')
    coordid=widget_info(state.tlb, find_by_uname='mms_coordinate')

    ; update the menu values based on the type of data selected
    if strpos(event.str, 'Magnetic Field') NE -1 && state.mmsStructure.instr NE 'Magnetic Field' then begin
       widget_control, dtypeid, set_value=state.mmsMagdataArray
       widget_control, coordid, set_value=state.mmsMagCoordArray
    endif
    if strpos(event.str, 'Electric Field') NE -1 && state.mmsStructure.instr NE 'Electric Field' then begin
       widget_control, dtypeid, set_value=state.mmsElecdataArray
       widget_control, coordid, set_value=state.mmsElecCoordArray
    endif
    if strpos(event.str, 'Velocity') NE -1 && state.mmsStructure.instr NE 'Velocity' then begin
      widget_control, dtypeid, set_value=state.mmsVeldataArray
      widget_control, coordid, set_value=state.mmsVelCoordArray
    endif
    ;widget_control, coordid, sensitive=1

    state.mmsStructure.instr = event.str
    state.mmsStructure.dtype = dtypeid
    state.mmsStructure.coord = coordid
    state.statusbar -> update, 'Instrument type updated to '+event.str+'.'

  endif

end

; ----------------------------------------------------------
;  This procedure prints the results of the MDD analysis in  
;  the large text box on the right hand side of the GUI
;-----------------------------------------------------------
pro mdd_ui_print_results, state, lstruc

  a=dblarr(1,3,3)
  format_eigen = '(f8.3)'

  ; get eigen vectors from the tplot variables and create the rotation matrix
  get_data,'Eigenvector_max',data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
  a[0,0,*]=[mean(data.y[index,0],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,1],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,2],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2)]
  get_data,'Eigenvector_mid',data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
  a[0,1,*]=[mean(data.y[index,0],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,1],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,2],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2)]
  get_data,'Eigenvector_min',data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
  a[0,2,*]=[mean(data.y[index,0],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,1],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,2],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2)]
  get_data,'lamda',data=data  
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1], npts)
  sqr_roots = [mean(data.y[index,0],/nan), mean(data.y[index,1],/nan), mean(data.y[index,2],/nan)]  ;,format='(a,3f8.3,a)'

  sqr_root_strs = string(sqr_roots, format=format_eigen)
  max_strs = string(a[0,0,*], format=format_eigen)
  mid_strs = string(a[0,1,*], format=format_eigen)
  min_strs = string(a[0,2,*], format=format_eigen)
  f1str = state.xyzstrings[state.analysisStructure.f1]
  f2str = state.xyzstrings[state.analysisStructure.f2]
  f3str = state.xyzstrings[state.analysisStructure.f3]

  ; Create string array for results text box
  results = make_array(14, /string)
  results[0] = 'MDD Run ' + strtrim(string(state.mddCount),1) + '==================================='
  results[1] = 'Start Time: ' + time_string(state.analysisStructure.tRange[0])
  results[2] = 'Stop Time:  ' + time_string(state.analysisStructure.tRange[1])
  results[3] = 'Duration (sec): ' + strtrim(string(state.mdddur),1)
  results[4] = 'Data points in analysis: ' + strtrim(string(npts),1)
  results[5] = 'fl = ' + f1str + ', f2 = ' + f2str + ', f3 = ' + f3str
  results[6] = 'Square roots of Eigenvalues: '
  results[7] = sqr_root_strs[0] + ', ' + sqr_root_strs[1] + ', ' + sqr_root_strs[2]
  results[8] = 'Eigenvectors ('+ lstruc.coordinate + '): '
  results[9] = 'Max: (' + max_strs[0] + ',  ' + max_strs[1] + ',  ' + max_strs[2] + ')'
  results[10] = 'Mid: (' + mid_strs[0] + ',  ' + mid_strs[1] + ',  ' + mid_strs[2] + ')'
  results[11] = 'Min: (' + min_strs[0] + ',  ' + min_strs[1] + ',  ' + min_strs[2] + ')'
  results[12] = '==================================================='
  results[13] = ' '

  ; get whatever text is currently displayed and append the new results 
  ; to it. that way no previously displayed data is lost.
  resultid = widget_info(state.tlb, find_by_uname='resulttext')
  widget_control, resultid, get_value=resultstring
  append_array, resultstring, results
  widget_control, resultid, set_value=resultstring

  ; save the mva rotation matrix for use later 
  store_data,'mva_mat',data={x:average(time_double(state.analysisStructure.tRange)),y:a}
  state.statusbar -> update, 'MDD analysis printed in results text box.'

end

; ----------------------------------------------------------
;  This procedure prints the results of the STD analysis in
;  the large text box on the right hand side of the GUI
;-----------------------------------------------------------
pro std_ui_print_results, state, lstruc

  a=dblarr(1,3,3)
  format_eigen = '(f7.3)'

  ; get eigen vectors from the tplot variables
  get_data, 'V_max', data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
  v_max=[mean(data.y[index,0],/nan), mean(data.y[index,1],/nan), mean(data.y[index,2],/nan)]
  get_data, 'V_mid', data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
  v_mid=[mean(data.y[index,0],/nan), mean(data.y[index,1],/nan), mean(data.y[index,2],/nan)]
  get_data, 'V_min', data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
  v_min=[mean(data.y[index,0],/nan), mean(data.y[index,1],/nan), mean(data.y[index,2],/nan)]
  get_data,'lamda',data=data
  index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1], npts)

  max_strs = string(v_max, format=format_eigen)
  mid_strs = string(v_mid, format=format_eigen)
  min_strs = string(v_min, format=format_eigen)

  ; Create string array for results text box
  results = make_array(12, /string)
  results[0] = 'STD Run ' + strtrim(string(state.stdCount),1) + '==================================='
  results[1] = 'delta_t (sec) = '+ strtrim(string(state.analysisStructure.deltaT),1)
  results[2] = 'Start Time: ' + time_string(state.analysisStructure.tRange[0])
  results[3] = 'Stop Time:  ' + time_string(state.analysisStructure.tRange[1])
  results[4] = 'Duration (sec): ' + strtrim(string(state.mdddur),1)
  results[5] = 'Data points in analysis: ' + strtrim(string(npts),1)
  results[6] = 'Velocity along the Eigenvectors ('+ lstruc.coordinate + '): '
  results[7] = 'Max: (' + max_strs[0] + ',  ' + max_strs[1] + ',  ' + max_strs[2] + ')'
  results[8] = 'Mid: (' + mid_strs[0] + ',  ' + mid_strs[1] + ',  ' + mid_strs[2] + ')'
  results[9] = 'Min: (' + min_strs[0] + ',  ' + min_strs[1] + ',  ' + min_strs[2] + ')'
  results[10] = '==================================================='
  results[11] = ' '

  ; get whatever text is currently displayed and append the new results
  ; to it. that way no previously displayed data is lost.
  resultid = widget_info(state.tlb, find_by_uname='resulttext')
  widget_control, resultid, get_value=resultstring
  append_array, resultstring, results
  widget_control, resultid, set_value=resultstring
  state.statusbar -> update, 'STD analysis printed in results text box.'

end

; -----------------------------------------------------
;  This function will gather all the values the
;  user has selected and create a load data structure
;------------------------------------------------------
function mdd_ui_get_load_data_structure, state, use_mdd_time=use_mdd_time

  if keyword_set(use_mdd_time) then begin
    state.timeRangeObjmdd->getproperty, starttime=starttime, endtime=endtime
    starttime->getproperty, tdouble=st0, sec=sec
    endtime->getproperty, tdouble=et0, sec=sec
  endif else begin
    state.timeRangeObjplot->getproperty, starttime=starttime, endtime=endtime
    starttime->getproperty, tdouble=st0, sec=sec
    endtime->getproperty, tdouble=et0, sec=sec
  endelse
  trange=[st0,et0]

  ; this structure will contain information about the data that is or will 
  ; be loaded
  load_structs = { timeRange:trange, $
    satellite:'', $
    probe:'', $
    instrtype:'', $
    data:'', $
    coordinate:'' }

  ; find selected satellites
  thmid=widget_info(state.tlb, find_by_uname='thm_probes')
  widget_control, thmid, get_value=thmsats
  mmsid=widget_info(state.tlb, find_by_uname='mms_probes')
  widget_control, mmsid, get_value=mmssats
  if n_elements(mmssats) eq 5 then mmssats=mmssats[0:3]
  thmidx = where(thmsats EQ 1, thmcnt)
  mmsidx = where(mmssats EQ 1, mmscnt)
  totalcnt = thmcnt + mmscnt
  if totalcnt LT 4 then begin
    state.statusbar -> update, 'You must select at least 4 satellites.'
    return, -1
  endif

  load_structs = replicate(load_structs, totalcnt)

  ; get themis selections
  if thmcnt GT 0 then begin
    instrid=widget_info(state.tlb, find_by_uname='thm_instr')
    thmitype=widget_info(instrid, /combobox_gettext)
    dtypeid=widget_info(state.tlb, find_by_uname='thm_data')
    thmdtype=widget_info(dtypeid, /combobox_gettext)
    coordid=widget_info(state.tlb, find_by_uname='thm_coordinate')
    thmcoord=widget_info(coordid, /combobox_gettext)
    load_structs[0:thmcnt-1].satellite='THEMIS'
    load_structs[0:thmcnt-1].probe=strlowcase(state.thmProbes[thmidx])
    load_structs[0:thmcnt-1].instrtype=thmitype
    load_structs[0:thmcnt-1].data=thmdtype
    load_structs[0:thmcnt-1].coordinate=thmcoord
  endif

  ; get mms selections
  if mmscnt GT 0 then begin
    instrid=widget_info(state.tlb, find_by_uname='mms_instr')
    mmsitype=widget_info(instrid, /combobox_gettext)
    dtypeid=widget_info(state.tlb, find_by_uname='mms_data')
    mmsdtype=widget_info(dtypeid, /combobox_gettext)
    coordid=widget_info(state.tlb, find_by_uname='mms_coordinate')
    mmscoord=widget_info(coordid, /combobox_gettext)
    load_structs[thmcnt:totalcnt-1].satellite='MMS'
    load_structs[thmcnt:totalcnt-1].probe=state.mmsProbes[mmsidx]
    load_structs[thmcnt:totalcnt-1].instrtype=mmsitype
    load_structs[thmcnt:totalcnt-1].data=mmsdtype
    load_structs[thmcnt:totalcnt-1].coordinate=mmscoord
  endif

  return, load_structs

end

; -----------------------------------------------------
;  This function will gather all the current values the
;  user has selected and create a load data structure
;------------------------------------------------------
pro mdd_ui_update_analysis_structure, state, use_mdd_time=use_mdd_time

  mdd_options=['X','Y','Z']
  dimen_options=['1D','2D','3D']
  b_options=['Bt', 'Bx', 'By', 'Bz']
  if keyword_set(use_mdd_time) then begin
    state.timeRangeObjmdd->getproperty, starttime=starttime, endtime=endtime
    starttime->getproperty, tdouble=st0, sec=sec
    endtime->getproperty, tdouble=et0, sec=sec
    state.analysisStructure.trange=[st0,et0]
  endif else begin
    state.timeRangeObjplot->getproperty, starttime=starttime, endtime=endtime
    starttime->getproperty, tdouble=st0, sec=sec
    endtime->getproperty, tdouble=et0, sec=sec
    state.analysisStructure.trange=[st0,et0]    
  endelse

  ; find selected satellites
  thmid=widget_info(state.tlb, find_by_uname='thm_fields')
  widget_control, thmid, get_value=thmsats
  thmsats=state.analysisStructure.thmsats
  mmsid=widget_info(state.tlb, find_by_uname='mms_fields')
  widget_control, mmsid, get_value=mmssats
  mmssats=state.analysisStructure.mmssats
  thmidx = where(thmsats EQ 1, thmcnt)
  mmsidx = where(mmssats EQ 1, mmscnt)
  totalcnt = thmcnt + mmscnt
  if totalcnt LT 4 then begin
    state.statusbar -> update, 'You must select at least 4 satellites.'
    return
  endif     
  f1id=widget_info(state.tlb, find_by_uname='F1')
  widget_control, f1id, get_value=f1
  state.analysisStructure.f1=f1 ;mdd_options[f1]
  f2id=widget_info(state.tlb, find_by_uname='F2')
  widget_control, f2id, get_value=f2
  state.analysisStructure.f2=f2 ;mdd_options[f2]
  f3id=widget_info(state.tlb, find_by_uname='F3')
  widget_control, f3id, get_value=f3
  state.analysisStructure.f3=f3 ;mdd_options[f3]

  fieldsid=widget_info(state.tlb, find_by_uname='fields')
  widget_control, fieldsid, get_value=fields
  idx = where(fields EQ 1, ncnt)
  if ncnt EQ 0 then begin
     fields = [1,0,0,0]
     widget_control, fieldsid, set_value=fields
  endif
  this_b_opt = ['','','','']
  idx = where(fields EQ 1, ncnt)
  this_b_opt[idx]=b_options[idx] 
  state.analysisStructure.fields=this_b_opt

  dtid=widget_info(state.tlb, find_by_uname='deltat')
  widget_control, dtid, get_value=deltat
  state.analysisStructure.deltaT=deltat
  dimid=widget_info(state.tlb, find_by_uname='dimensionality')
  widget_control, dimid, get_value=dimensionality
  state.analysisStructure.dimensionality=dimen_options[dimensionality]
  
end

; -------------------------------------------------------
;  This function checks to see if the selected data is
;  already loaded (no point in loading it twice)
; --------------------------------------------------------
function mdd_ui_check_loaded_data, state, load_structs, tvar
  
  ; retrive time range from GUI to compare 
  st = state.analysisStructure.trange[0]
  et = state.analysisStructure.trange[1]

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
;  This function checks to see if the selected data is
;  already loaded (no point in loading it twice)
; --------------------------------------------------------
pro mdd_ui_update_yrange, state, update=update

   if ~keyword_set(update) then update = 1 else update = update
   
   ;set widgets to sensitive
   yvarid = widget_info(state.tlb, find_by_uname='yrange_var')
   yminid = widget_info(state.tlb, find_by_uname='yrange_min')
   ymaxid = widget_info(state.tlb, find_by_uname='yrange_max')
   widget_control, yvarid, sensitive=1
   widget_control, yminid, sensitive=1
   widget_control, ymaxid, sensitive=1
 
   yvar=widget_info(yvarid, /combobox_gettext)
   Case yvar of
     'Eigenvalue': get_data, 'lamda', data=d
     'Vmax': get_data, 'Eigenvector_max_c', data=d
     'Vmid': get_data, 'Eigenvector_mid_c', data=d
     'Vmin': get_data, 'Eigenvector_min_c', data=d
     else: begin
       state.statusbar -> update, 'There is no Loaded data for tplot variable '+yvar+'.'
       return
     end
   Endcase    

   if size(d[0], /type) EQ 8 then begin
     state.yrangeStructure.ymin = min(d.y)
     state.yrangeStructure.ymax = max(d.y)
   endif else begin
     state.statusbar -> update, 'There is no Loaded data for tplot variable '+yvar+'.'
     return   
   endelse
 
   if update then begin
     widget_control, yminid, set_value=string(state.yrangeStructure.ymin)
     widget_control, ymaxid, set_value=string(state.yrangeStructure.ymax) 
   endif
       
end

; -------------------------------------------------------
;  This function checks to see if the selected data is
;  already loaded (no point in loading it twice)
; --------------------------------------------------------
pro mdd_ui_apply_yrange, state, std=std

  if ~keyword_set(update) then update = 1 else update = update

  yvarid = widget_info(state.tlb, find_by_uname='yrange_var')
  yminid = widget_info(state.tlb, find_by_uname='yrange_min')
  ymaxid = widget_info(state.tlb, find_by_uname='yrange_max')
  
  ; get var name and min and max values
  yvar=widget_info(yvarid, /combobox_gettext)
  widget_control, yminid, get_value=ymin
  widget_control, ymaxid, get_value=ymax

  if ~keyword_set(std) then begin  
    Case yvar of
      'Eigenvalue': begin
        ylim, 'lamda_c', double(ymin),double(ymax)
        options, 'lamda_c', ystyle=1
      end
      'Vmax': begin
        ylim, 'Eigenvector_max_c', double(ymin), double(ymax)
        options, 'Eigenvector_max_c', ystyle=1
      end
      'Vmid': begin
        ylim, 'Eigenvector_mid_c', double(ymin),double(ymax)
        options, 'Eigenvector_mid_c', ystyle=1
      end
      'Vmin': begin
        ylim, 'Eigenvector_min_c', double(ymin),double(ymax)
        options, 'Eigenvector_min_c', ystyle=1
      end
      else: begin
        state.statusbar -> update, 'There is no Loaded data for tplot variable '+yvar+'.'
        return
      end
    Endcase
  endif else begin
    Case yvar of
      'Eigenvalue': begin
        ylim, 'lamda_c', double(ymin),double(ymax)
        options, 'lamda_c', ystyle=1
      end
      'Vmax': begin
        ylim, 'V_max_c', double(ymin), double(ymax)
        options, 'V_max_c', ystyle=1
      end
      'Vmid': begin
        ylim, 'V_mid_c', double(ymin),double(ymax)
        options, 'V_mid_c', ystyle=1
      end
      'Vmin': begin
        ylim, 'V_min_c', double(ymin),double(ymax)
        options, 'V_min_c', ystyle=1
      end
      else: begin
        state.statusbar -> update, 'There is no Loaded data for tplot variable '+yvar+'.'
        return
      end 
    Endcase   
  endelse
  
end

; -------------------------------------------------------
;  This function loads data for THEMIS
; --------------------------------------------------------
function mdd_ui_load_themis, state, load_structs

  Case load_structs.instrtype of
    'Magnetic Field': begin
      tvar = 'th'+ load_structs.probe + '_' + load_structs.data + '_' + load_structs.coordinate
      load = mdd_ui_check_loaded_data(state, load_structs, tvar)
      if load then begin
        thm_load_fgm, trange=load_structs.timeRange, probe=load_structs.probe, level=2, $
          datatype=load_structs.data, coord=load_structs.coordinate
        tvar = 'th'+ load_structs.probe + '_' + load_structs.data + '_' + load_structs.coordinate
        state.statusbar -> update, 'Loaded data '+tvar+'.'
      endif
    end
    'Electric Field': begin
      tvar = 'th'+ load_structs.probe + '_' + load_structs.data
      load = mdd_ui_check_loaded_data(state, load_structs, tvar)
      if load then begin
        thm_load_efi, trange=load_structs.timeRange, probe=load_structs.probe, level=1, $
          datatype=load_structs.data
        tvar = 'th'+ load_structs.probe + '_' + load_structs.data
        state.statusbar -> update, 'Loaded data '+tvar+'.'
      endif
    end
    'Velocity': begin
      dtype = load_structs.data + '_velocity_' + load_structs.coordinate
      tvar = 'th'+ load_structs.probe + '_' +dtype
      load = mdd_ui_check_loaded_data(state, load_structs, tvar)
      if load then begin
        thm_load_esa, trange=load_structs.timeRange, probe=load_structs.probe, $
          datatype=dtype
        tvar = 'th'+ load_structs.probe + '_' +dtype
        state.statusbar -> update, 'Loaded data '+tvar+'.'
      endif
    end
    else:
  endcase

  ; check that data was loaded
  if undefined(tvar) OR tnames(tvar) EQ '' then begin
    tvar='err'
    state.statusbar -> update, 'Problems loading THEMIS data.'    
  endif 

  return, tvar

end


;--------------------------------------------------------
; This procedure handles plotting the data by extracting
; the individual parameters
; -------------------------------------------------------
pro mdd_ui_plot_fields, state

  ; split the components 
  split_vec, state.loadedTvars
  ; create new tplot vars for the 4 s/c
  midx = where(state.analysisStructure.mmssats EQ 1, mcnt)
  if mcnt EQ 4 then bt=tnames('*_'+state.mmsStructure.coord+'_'+state.mmsStructure.dtype+'*_btot') $
     else bt=tnames('*_btot')

  store_data, 'Bt', data=bt
  bx=tnames('*_x')
  store_data, 'Bx', data=bx
  by=tnames('*_y')
  store_data, 'By', data=by
  bz=tnames('*_z')
  store_data, 'Bz', data=bz

  all_fields = ['Bt','Bx','By','Bz']

  options,['Bt','Bx','By','Bz'],labels=['SC1','SC2','SC3','SC4'],colors=['x','r','b','g'],labflag=1
  options,'Bt',ytitle='Bt'
  options,'Bx',ytitle='Bx'
  options,'By',ytitle='By'
  options,'Bz',ytitle='Bz'

  ; set the time frame
  state.timeRangeObjplot->getproperty, starttime=starttime, endtime=endtime
  starttime->getproperty, tdouble=st0, sec=sec
  endtime->getproperty, tdouble=et0, sec=sec

  
  ; plot the data
  tplot, all_fields, trange=[st0,et0]

  state.plotWindow = !d.WINDOW
  state.statusbar -> update, 'Created plot for requested data.'

end

; -------------------------------------------------------
;  This function handles the loading of data for the
;  MMS Mission
; --------------------------------------------------------
function mdd_ui_load_mms, state, load_structs

  Case load_structs.instrtype of
    'Magnetic Field': begin
      tvar = 'mms'+ load_structs.probe + '_fgm_b_' + load_structs.coordinate + '_' + load_structs.data + '_l2_bvec'
      load = mdd_ui_check_loaded_data(state, load_structs, tvar)
      if load then begin
        mms_load_fgm, trange=load_structs.timeRange, probes=load_structs.probe, data_rate=load_structs.data, $
          level='l2', get_support_data=0
        state.statusbar -> update, 'Loaded data '+tvar+'.'
      endif
    end
    'Electric Field': begin
      tvar = 'mms'+ load_structs.probe + '_dce_' + load_structs.coordinate + '_' + load_structs.data + '_l2'
      load = mdd_ui_check_loaded_data(state, load_structs, tvar)
      if load then begin
        mms_load_edp, trange=load_structs.timeRange, probes=load_structs.probe, data_rate=load_structs.data, $
          varformat=tvar, level='l2', get_support_data=0
      endif
      state.statusbar -> update, 'Loaded data '+tvar+'.'
    end
    'Velocity': begin
      state.statusbar -> update, 'MMS Velocity data option not yet implemented.'
    end
    else:
  endcase

  ; check that data was loaded
   if undefined(tvar) OR tnames(tvar) EQ '' then begin
    tvar='err'
    state.statusbar -> update, 'Problems loading MMS data.'
  endif else begin
    state.mmsStructure.dtype = load_structs.data
    state.mmsStructure.coord = load_structs.coordinate
  endelse
  
  return, tvar

end

; -------------------------------------------------------
;  This procedure handles the loading of science data 
; --------------------------------------------------------
pro mdd_ui_load_data, state, load_structs

  npts = n_elements(load_structs)
  tvars=make_array(npts, /string)
  for i=0,npts-1 do begin
    if load_structs[i].satellite EQ 'THEMIS' then tvars[i]=mdd_ui_load_themis(state, load_structs[i])
    if load_structs[i].satellite EQ 'MMS' then tvars[i]=mdd_ui_load_mms(state, load_structs[i])
  endfor 
  state.loadedTvars = tvars 

end

; -------------------------------------------------------
;  This function handles the loading of position data
; --------------------------------------------------------
pro mdd_ui_load_pos, state, load_structs

  npts = n_elements(load_structs)
  tpos=make_array(npts, /string)
  for i=0,npts-1 do begin

    if load_structs[i].satellite EQ 'MMS' then begin
      tpos_name = 'mms'+ load_structs[i].probe + '_mec_r_' + load_structs[i].coordinate
      load = mdd_ui_check_loaded_data(state, load_structs, tpos_name)
      if load then begin
        mms_load_mec, probe=load_structs[i].probe,datatype='epht89d', $
          trange=load_structs[i].timeRange, varformat=tpos_name
        state.statusbar -> update, 'Loaded MMS data '+tpos_name+'.'
      endif
      tpos[i] = tnames(tpos_name)
    endif 

    if load_structs[i].satellite EQ 'THEMIS' then begin
      tpos_name = 'th'+ load_structs[i].probe + '_state_pos_' + load_structs[i].coordinate
      load = mdd_ui_check_loaded_data(state, load_structs, tpos_name)
      if load then begin
        thm_load_state, trange=load_structs[i].timeRange, probe=load_structs[i].probe, $
          datatype='pos', coord=load_structs[i].coordinate, suffix='_'+load_structs[i].coordinate
          varnames = tpos_name
        state.statusbar -> update, 'Loaded THEMIS data '+tpos_name+'.'
      endif
      tpos[i] = tnames(tpos_name)
    endif

    if undefined(tpos[i]) or tpos[i] EQ '' then begin 
      tpos[i]='err'
      state.statusbar -> update, 'Problems loading data '+tpos_name+'.'
    endif 

  endfor

  state.loadedTpos = tpos

end

;-------------------------
;-------------------------
; START of EVENT HANDLER 
;------------------------- 
;-------------------------
pro spd_ui_mdd_std_event,event

  compile_opt hidden,idl2

  ; Catch any unknown errors that aren't handled
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
      /noname, /center, title='Error in MDD')
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

      'MMS_PROBES': begin
        probeId = widget_info(state.tlb, find_by_uname='mms_probes')
        if event.value EQ 4 && event.select EQ 1 then begin
          probeId = widget_info(state.tlb, find_by_uname='mms_probes')
          widget_control, probeId, set_value=[1,1,1,1,1]
        endif
      end

      'THM_INSTRUMENT': begin
        mdd_ui_update_thm_instrument, state, event
      end

      'MMS_FIELDS': begin
        if event.value EQ 4 && event.select EQ 1 then begin
          probeId = widget_info(state.tlb, find_by_uname='mms_fields')
          widget_control, probeId, set_value=[1,1,1,1,1]
        endif
      end

      'MMS_INSTRUMENT': begin
        mdd_ui_update_mms_instrument, state, event
      end

      'PLOT_DURATION' : begin
        if event.valid then begin
          If (event.value GT 0) && is_numeric(event.value) Then Begin
            state.plotdur = event.value
            ext_string = strcompress(string(event.value))
            state.statusbar -> update, 'Plot Duration set to '+ext_string
            twidget='time_plot_widget'
            mdd_ui_update_time_widget, state.timeRangeObjPlot, state.plotdur, twidget, event
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

      'MDD_DURATION' : begin
        if event.valid then begin
          If(event.value GT 0) && is_numeric(event.value) Then Begin
            state.mdddur = event.value
            ext_string = strcompress(string(event.value))
            state.statusbar -> update, 'Analysis Duration set to '+ext_string
            twidget='time_mdd_widget'
            mdd_ui_update_time_widget, state.timeRangeObjmdd, state.mdddur, twidget, event
            state.statusbar -> update, 'Stop time in Analysis section updated based on user specified duration'
          Endif Else Begin
            mdddurid=widget_info(state.tlb, find_by_uname='mddduration')
            widget_control, mdddurid, set_value = state.mdddur
            state.statusbar -> update, 'Invalid or Zero Analysis Duration: '
          Endelse
        endif else begin
          mdddurid=widget_info(state.tlb, find_by_uname='mddduration')
          widget_control, mdddurid, set_value = state.mdddur
          state.statusBar->update, 'Invalid or Zero Analysis Duration Input.'
        endelse
      end

      'TIME_PLOT_WIDGET' : begin
        ; TO DO need to check that the starttime is less than the stoptime before changing the duration
        state.timeRangeObjPlot->getproperty, starttime=starttime, endtime=endtime
        starttime->getproperty, tdouble=st0, sec=sec
        endtime->getproperty, tdouble=et0, sec=sec
        tdiff = long(et0-st0)
        if tdiff LE 0 then begin
          state.statusbar -> update, 'The duration is negative for the time entered.'
        endif else begin
          if tdiff NE state.plotdur OR tdiff GT 0 then begin
            ; change plot widgets
            state.plotdur = tdiff
            plotdurid=widget_info(state.tlb, find_by_uname='plotduration')
            widget_control, plotdurid, set_value = tdiff
            ;and mdd widgets but only if time is outside of time plot range
            state.TimeRangeObjmdd->getproperty, starttime=starttime, endtime=endtime
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
            state.TimeRangeObjmdd->setproperty, starttime=startime, endtime=endtime
            state.mdddur = et1-st1
            twidget='time_mdd_widget'
            mdd_ui_update_time_widget, state.timeRangeObjmdd, state.mdddur, twidget, event
            state.statusbar -> update, 'Start/Stop time set from '+time_string(st1)+' to '+time_string(et1)
            mdddurid=widget_info(state.tlb, find_by_uname='mddduration')
            widget_control, mdddurid, set_value = state.mdddur
          endif 
        endelse
      end

      'TIME_MDD_WIDGET' : begin
        state.timeRangeObjMDD->getproperty, starttime=starttime, endtime=endtime
        starttime->getproperty, tdouble=st0, sec=sec
        endtime->getproperty, tdouble=et0, sec=sec
        tdiff = long(et0-st0)
        if tdiff LE 0 then begin
          state.statusbar -> update, 'The duration is negative for the time entered. Please adjust the start or stop time.'
        endif else begin
          if tdiff NE state.mdddur then begin
            state.mdddur = tdiff
            mdddurid=widget_info(state.tlb, find_by_uname='mddduration')
            widget_control, mdddurid, set_value = tdiff
          endif
        endelse
      end

      'PLOT_DATA' : begin
         load_structs=mdd_ui_get_load_data_structure(state)
         mdd_ui_load_data, state, load_structs
         didx = where(state.loadedTvars NE 'err', ncnt)
         if ncnt GE 4 then begin
            mdd_ui_update_analysis_structure, state
            mdd_ui_plot_fields, state
         endif else begin
           state.statusBar->update, 'Not all data was loaded. At least 4 satellites data must be loaded.'          
         endelse
       end

      'CALC_MDD' : begin
         load_structs=mdd_ui_get_load_data_structure(state)
         mdd_ui_load_data, state, load_structs
         mdd_ui_load_pos, state, load_structs         
         mdd_ui_update_analysis_structure, state
         MDD_STD_for_gui, state.Loadedtpos, state.loadedTvars, trange=state.analysisStructure.trange, $
            fl1=state.analysisStructure.f1, fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3     
         mdd_ui_print_results, state, load_structs
         mdd_ui_update_yrange, state, /update
         state.statusbar -> update, 'MDD analysis performed and results displayed.'
         state.mddCount = state.mddCount + 1
      end
      
      'PLOT_MDD' : begin
        load_structs=mdd_ui_get_load_data_structure(state)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3
        mdd_ui_update_yrange, state, /update     
        idx = where(state.analysisStructure.fields NE '', ncnt)
        if ncnt EQ 0 then begin
           B_opt = ['Bt']
        endif else begin
           B_opt = state.analysisStructure.fields[idx]
        endelse
        MDD_STD_plot,files=files,trange=state.analysisStructure.trange,mode=state.analysisStructure.dimensionality, $
          B_opt=state.analysisStructure.fields
        state.statusbar -> update, 'MDD analysis performed and plotted.'
      end

      'CALC_STD' : begin
        load_structs=mdd_ui_get_load_data_structure(state)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3, delta_t=state.analysisStructure.deltat, $
          /std
        std_ui_print_results, state, load_structs
        mdd_ui_update_yrange, state, /update
        state.statusbar -> update, 'STD analysis performed and results displayed.'
        state.stdCount = state.stdCount + 1 
      end

      'PLOT_STD' : begin
        load_structs=mdd_ui_get_load_data_structure(state)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3, delta_t=state.analysisStructure.deltat, $
          /std
        mdd_ui_update_yrange, state, /update
        idx = where(state.analysisStructure.fields NE '', ncnt)
        if ncnt EQ 0 then begin
           B_opt = ['Bt']
        endif else begin
           B_opt = state.analysisStructure.fields[idx]
        endelse
        MDD_STD_plot,files=files,trange=state.analysisStructure.trange,mode=state.analysisStructure.dimensionality, $
          B_opt=B_Opt, delta_t=state.analysisStructure.deltat,/std
        state.statusbar -> update, 'STD analysis performed and plotted.'
      end

      'YRANGE_VAR' : mdd_ui_update_yrange, state, /update
        
      'REPLOT_MDD' : begin
        load_structs=mdd_ui_get_load_data_structure(state)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state
        mdd_ui_apply_yrange, state
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3
        ;mdd_ui_update_yrange, state, /update
        MDD_STD_plot,files=files,trange=state.analysisStructure.trange,mode=state.analysisStructure.dimensionality, $
          B_opt=state.analysisStructure.fields
        state.statusbar -> update, 'MDD analysis performed and plotted.'
      end

      'REPLOT_STD' : begin
        load_structs=mdd_ui_get_load_data_structure(state)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state
        mdd_ui_apply_yrange, state, /std
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3, delta_t=state.analysisStructure.deltat, $
          /std
        ;mdd_ui_update_yrange, state, /update
        MDD_STD_plot,files=files,trange=state.analysisStructure.trange,mode=state.analysisStructure.dimensionality, $
          B_opt=B_Opt, delta_t=state.analysisStructure.deltat,/std
        state.statusbar -> update, 'STD analysis performed and plotted.'
      end
          
      'CALC_MEAN_DIR' : begin
        load_structs=mdd_ui_get_load_data_structure(state, /use_mdd_time)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state, /use_mdd_time
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3, delta_t=state.analysisStructure.deltat
        mdd_ui_print_results, state, load_structs
        state.statusbar -> update, 'Mean directions calculated and results displayed.'
        state.mddCount = state.mddCount + 1
      end
      
      'CALC_MEAN_VEL' : begin
        load_structs=mdd_ui_get_load_data_structure(state, /use_mdd_time)
        mdd_ui_load_data, state, load_structs
        mdd_ui_load_pos, state, load_structs
        mdd_ui_update_analysis_structure, state, /use_mdd_time
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3, delta_t=state.analysisStructure.deltat, $
          /std
        std_ui_print_results, state, load_structs
        state.statusbar -> update, 'Mean velocities calculated and results displayed.'
        state.stdCount = state.stdCount + 1
      end
      
      'NEW_PLOT' : begin
        mva_tvar = tnames('mva_mat')
        load_structs=mdd_ui_get_load_data_structure(state)
        ; check if data has been loaded 
        if mva_tvar NE 'mva_mat' or state.loadedTvars[0] eq '' then begin
          mdd_ui_load_data, state, load_structs
          mdd_ui_load_pos, state, load_structs
          mdd_ui_update_analysis_structure, state
        endif
        MDD_STD_for_gui, state.loadedTpos, state.loadedTvars, trange=state.analysisStructure.trange, fl1=state.analysisStructure.f1, $
          fl2=state.analysisStructure.f2, fl3=state.analysisStructure.f3
        ; get eigen vectors from the tplot variables
        a=dblarr(1,3,3)
        get_data,'Eigenvector_max',data=data
        index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
        a[0,0,*]=[mean(data.y[index,0],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,1],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,2],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2)]
        get_data,'Eigenvector_mid',data=data
        index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
        a[0,1,*]=[mean(data.y[index,0],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,1],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,2],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2)]
        get_data,'Eigenvector_min',data=data
        index=where(data.x ge state.analysisStructure.tRange[0] and data.x le state.analysisStructure.tRange[1])
        a[0,2,*]=[mean(data.y[index,0],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,1],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2), mean(data.y[index,2],/nan)/sqrt(mean(data.y[index,0])^2+mean(data.y[index,1])^2+mean(data.y[index,2])^2)]
        store_data,'mva_mat',data={x:average(time_double(state.analysisStructure.tRange)),y:a}
        rotated_tvars = state.loadedTvars + '_bvec_rot'
        for i = 0, n_elements(state.loadedTvars)-1 do $
          tvector_rotate, 'mva_mat', state.loadedTvars[i], newname=rotated_tvars[I]
        split_vec, rotated_tvars
        coord=load_structs.coordinate
        data_rate=load_structs.data
        tnx=tnames(rotated_tvars+'_x')
        tny=tnames(rotated_tvars+'_y')
        tnz=tnames(rotated_tvars+'_z')
        tnt=tnames('*'+load_structs[0].coordinate+'_'+load_structs[0].data+'_l2_btot')
        store_data, 'Bmax_'+load_structs[0].coordinate+'_'+load_structs[0].data, data=tnx
        store_data, 'Bmid_'+load_structs[0].coordinate+'_'+load_structs[0].data, data=tny
        store_data, 'Bmin_'+load_structs[0].coordinate+'_'+load_structs[0].data, data=tnz
        options,'Bmax_'+load_structs[0].coordinate+'_'+load_structs[0].data,ytitle='Bmax'
        options,'Bmid_'+load_structs[0].coordinate+'_'+load_structs[0].data,ytitle='Bmid'
        options,'Bmin_'+load_structs[0].coordinate+'_'+load_structs[0].data,ytitle='Bmin' 
        options,['Bmax_'+load_structs[0].coordinate+'_'+load_structs[0].data, $
                 'Bmid_'+load_structs[0].coordinate+'_'+load_structs[0].data, $
                 'Bmin_'+load_structs[0].coordinate+'_'+load_structs[0].data], $
                 labels=['SC1','SC2','SC3','SC4'],colors=['x','r','b','g'],labflag=1
        store_data,'Bt',data=tnt
        tplot,['Bt','Bmax_'+load_structs[0].coordinate+'_'+load_structs[0].data, $
               'Bmid_'+load_structs[0].coordinate+'_'+load_structs[0].data, $
               'Bmin_'+load_structs[0].coordinate+'_'+load_structs[0].data], trange=load_structs[0].timeRange       
        state.statusbar -> update, 'Data plotted in new coordinate system.'
      end
      
      'HELP': begin
        spd_ui_mdd_help, state.tlb
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

;--------------------------------------------
; START to build GUI
;--------------------------------------------
pro spd_ui_mdd_std, gui_ID=gui_id, $
  _extra=dummy ;SPEDAS API req

  compile_opt idl2,hidden

  ;load bitmap resources
  getresourcepath,rpath

  if keyword_set(gui_ID) then begin
    tlb = Widget_Base(/col, /Align_Top, /Align_Left, title='Minimum Directional Derivative (MDD) and Spatio-Temporal Difference (STD)', group_leader= gui_id, /floating, $
      /modal, YPad=1, /tlb_kill_request_events, event_pro='spd_ui_mdd_event')
  endif else begin
    tlb = Widget_Base(/col, /Align_Top, /Align_Left, title='Minimum Directional Derivative (MDD) and Spatio-Temporal Difference (STD)', YPad=1,event_pro='spd_ui_mdd_event')
    gui_ID=tlb
  endelse

  ;***************
  ;    MDD Bases
  ;***************
  ;  mainBase = Widget_Base(tlb, Title='MDD', /row, YPad=1)
  mainBase = Widget_Base(tlb, Title='MDD', /col, YPad=1)
  buttonBase = Widget_Base(tlb, /Row, /Align_Center)
  statusBase = Widget_Base(tlb, /Row, /Align_Center)

  ; Upper base widgets are for mission and instrument selections
  upperBase = widget_base(mainBase, /col) ;, /frame)
  selectBase = widget_base(upperBase, /row)
  satellitesBase = widget_base(selectBase, /col)
  satLabelBase=widget_base(satellitesBase, /row)
  satellitesLabel = widget_label(satLabelBase, value='Satellites (you must select at least 4):', /align_left)
  mmsBase = widget_base(satellitesBase, /row)
  themisBase = widget_base(satellitesBase, /row)
  clusterBase = widget_base(satellitesBase, /row)
  instrBase = widget_base(selectBase, /col, xpad=10)
  instrLabelBase=widget_base(instrBase, /row)
  instrLabel = widget_label(instrLabelBase, value='Instrument Type:', /align_left)

  dataBase = widget_base(selectBase, /col, xpad=10)
  dataLabelBase=widget_base(dataBase, /row)
  dataLabel = widget_label(dataLabelBase, value='Data Type:', /align_left)

  coordinateBase = widget_base(selectBase, /col, xpad=10)
  coordinateLabelBase = widget_base(coordinateBase, /row)
  thmcoordinateLabel = widget_label(coordinateLabelBase, value='Coordinate:', /align_left)

  ; Lower base widgets are for the analysis (left) and results (right)
  lowerBase = widget_base(mainBase, /row)
  leftBase = widget_base(lowerBase, ypad=2, /col)
  rightBase = widget_base(lowerBase, ypad=1, /col)
  
  mddBase = widget_base(leftBase, /col, /frame)
  timePlotBase = widget_base(mddBase, /row)
  selectTimeBase = widget_base(timePlotBase, /col)
  calcOptionsBase = widget_base(mddBase, /row, /align_center, /frame, xpad=167)
  calcOptionslabel = widget_label(calcOptionsBase, value='Calculate/Plot Options', /align_center)
  fieldBase = widget_base(mddBase, /row, /align_center, /frame, xpad=167)
  fieldlabel = widget_label(fieldBase, value='Field Plotted in Panel 1', /align_center)

  fieldSatBase = widget_base(mddBase, /row)
  satellitesBase2 = widget_base(fieldSatBase, /col, /frame)
  mmsBase2 = widget_base(satellitesBase2, /row)
  themisBase2 = widget_base(satellitesBase2, /row)
  clusterBase2 = widget_base(satellitesBase2, /row)
  fieldButtonBase = widget_base(fieldSatBase, /col, /frame, xpad=10)

  optionsBase = widget_base(mddBase, /row)
  mddOptionsBase = widget_base(optionsBase, /col, /frame)
  mddOptionsLabelBase = widget_base(mddOptionsBase, /row)
  mddOptionsLabel = widget_label(mddOptionsLabelBase, value = 'MDD Options:', /align_left)
  stdOptionsBase = widget_base(optionsBase, /col, /frame)
  stdOptionLabelBase = widget_base(stdOptionsBase, /row)
  stdOptionsLabel = widget_label(stdOptionLabelBase, value = 'STD Options:', /align_left)
  f123Base = widget_base(mddOptionsBase, /col)
  f1Base = widget_base(f123Base, /row)
  f2Base = widget_base(f123Base, /row)
  f3Base = widget_base(f123Base, /row)
  mddOptionsButtonBase = widget_base(f123Base, /row)

  deltaBase = widget_base(stdOptionsBase, /row, ypad=5)
  dimensionBase = widget_base(stdOptionsBase, /row)
  dimensionButtonBase = widget_base(dimensionBase, /col)
  dimensionPlotBase = widget_base(dimensionBase,  /row, /align_center)
  dimensionLabel = widget_label(dimensionButtonBase, value = 'Dimensionality:', /align_left)
 
  yrangeBase = widget_base(mddBase, /col, /frame, uvalue='yrange')
  yrangeLabel = widget_label(yrangeBase, value = 'Y Axis Range: ', /align_left)
     
;  mddTimeCalcBase = widget_base(mddBase, /row, /frame)
  mddTimeCalcBase = widget_base(leftBase, /row, /frame)
  mddTimeBase = widget_base(mddTimeCalcBase, /col)
  mddTimeButtonBase = widget_base(mddTimeCalcBase, /col, /align_center)

  statusBar = obj_new('spd_ui_message_bar', statusbase,  Xsize=120, YSize=1, $
    value='Status information is displayed here.')
  if ~obj_valid(historywin) then begin
    historyWin = Obj_New('SPD_UI_HISTORY', 0L, tlb);dummy history window in absence of gui
  endif

  ;
  ; UPPER LEFT HAND SECTION
  ;
  ; create mission/data selection widgets (pulldown menus and titles)
  mmsLabel = widget_label(mmsBase, value='MMS:      ', /align_left)
  mmsProbes = ['1', '2', '3', '4', 'All']
  mmsSelections = fix([1,1,1,1,0])    ; default to MMS selections
;  mmsSelections = fix([0,0,0,0,0])    ; default to MMS selections
  mmsButtons = CW_BGROUP(mmsBase, mmsProbes, /row, /nonexclusive, set_value=mmsSelections, uval='MMS_PROBES', uname='mms_probes')
  themisLabel = widget_label(themisBase, value='THEMIS: ', /align_left)
  thmProbes = ['A', 'B', 'C', 'D', 'E']
  thmSelections = fix([0,0,0,0,0])    ; temporarily default to MMS selections
;  thmSelections = fix([1,0,1,1,1])    ; temporarily default to MMS selections
  themisButtons = CW_BGROUP(themisBase, thmProbes, /row, /nonexclusive, set_value=thmSelections, uval='THM_PROBES', uname='thm_probes')
  clusterLabel = widget_label(clusterBase, value='Cluster:    ', /align_left)
  clusterProbes = ['1', '2', '3', '4', 'All']
  clusterSelections = fix([0,0,0,0,0])    ; default to MMS selections
  clusterButtons = CW_BGROUP(clusterBase, clusterProbes, /row, /nonexclusive, set_value=clusterSelections, UNAME='CLUSTER_PROBES')
  widget_control, clusterButtons, sensitive=0
  
  instrArray = ['Magnetic Field', 'Electric Field', 'Velocity']

  mmsinstrBase = widget_base(instrBase, /row, ypad=6)
  mmsinstrCombo = widget_combobox(mmsinstrBase,$
    value=instrArray,$
    uvalue='MMS_INSTRUMENT',$
    uname='mms_instr')
  currentinstr=instrArray[0]

  thminstrBase = widget_base(instrBase, /row, ypad=6)
  thminstrCombo = widget_combobox(thminstrBase,$
    value=instrArray,$
    uvalue='THM_INSTRUMENT',$
    uname='thm_instr')
  currentinstr=instrArray[0]

  clusterinstrBase = widget_base(instrBase, /row, ypad=6)
  clusterinstrCombo = widget_combobox(clusterinstrBase,$
    value=instrArray,$
    uvalue='CLUSTER_INSTRUMENT',$
    uname='cluster_instr')
  currentinstr=instrArray[0]

  ;  dataLabel = widget_label(dataBase, value='Data Type:', /align_left)
  thmMagdataArray = ['fgh', 'fgl', 'fgs']
  thmElecdataArray = ['eff', 'efp', 'efw']
  thmVeldataArray = ['peif', 'peir', 'peib', 'peim', 'peef', 'peer', 'peeb', 'peem']

  ;mmsdataArray = ['srvy', 'brst']
  mmsMagdataArray = ['brst', 'srvy']
  mmsElecdataArray = ['brst', 'fast', 'slow', 'srvy']
  mmsVeldataArray = ['brst', 'fast']
  clusterdataArray = ['5vps', 'full', 'spin']

  mmsdataBase = widget_base(dataBase, /row, ypad=6)
  mmsdataCombo = widget_combobox(mmsdataBase,$
    value=mmsMagdataArray,$
    uvalue='MMS_DATA',$
    uname='mms_data',$
    xsize=70)

  thmdataBase = widget_base(dataBase, /row, ypad=6)
  thmdataCombo = widget_combobox(thmdataBase,$
    value=thmMagdataArray,$
    uvalue='THM_DATA',$
    uname='thm_data',$
    xsize=70)

  clusterdataBase = widget_base(dataBase, /row, ypad=6)
  clusterdataCombo = widget_combobox(clusterdataBase,$
    value=clusterdataArray,$
    uvalue='CLUSTER_DATA',$
    uname='cluster_data',$
    xsize=70)

  thmCoordinateArray = ['gsm', 'gse', 'dsl']
  mmsMagCoordArray = ['gsm', 'gse', 'dbcs']
  mmsElecCoordArray = ['gse', 'dsl']
  mmsVelCoordArray = ['gsm', 'gse', 'dbcs'] 
  clusterCoordinateArray = ['gsm', 'gse']

  mmscoordinateBase=widget_base(coordinateBase, /row, ypad=6)
  mmscoordinateCombo = widget_combobox(mmscoordinateBase,$
    value=mmsMagCoordArray,$
    xsize=70,$
    uvalue='MMS_COORDINATE',$
    uname='mms_coordinate')

  thmcoordinateBase=widget_base(coordinateBase, /row, ypad=6)
  thmcoordinateCombo = widget_combobox(thmcoordinateBase,$
    value=thmcoordinateArray,$
    xsize=70,$
    uvalue='THM_COORDINATE',$
    uname='thm_coordinate')

  clustercoordinateBase=widget_base(coordinateBase, /row, ypad=6)
  clustercoordinateCombo = widget_combobox(clustercoordinateBase,$
    value=clustercoordinateArray,$
    xsize=70,$
    uvalue='CLUSTER_COORDINATE',$
    uname='cluster_coordinate')

  ; time widget
  st_text = '2015-11-24/11:07:48'
  et_text = '2015-11-24/11:08:08'
  plotdur = time_double(et_text)-time_double(st_text)
  plotTime=time_double([st_text, et_text])
;  st_text = '2015-11-24/00:00:00'
;  et_text = '2015-11-25/00:00:00'
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
    Increment=1, Value=plotdur, UValue='PLOT_DURATION', UName='plotduration',min_value=1., $
    tooltip='When the duration is changed, the stop time will be changed to reflect the new duration')

  ; plot data button
  plotDataBase = widget_base(timePlotBase, /col,/align_center, xpad=50)
  plotDataButton = widget_button(plotDataBase, value='Plot', uval='PLOT_DATA', xsize =100)

  ;
  ; LOWER LEFT HAND SECTION
  ;
  ; create analysis data selection widgets
  ; time widget
  mmsLabel = widget_label(mmsBase2, value='MMS:      ', /align_left)
  mmsFieldSelections = mmsSelections
  mmsButtons = CW_BGROUP(mmsBase2, mmsProbes, /row, /nonexclusive, set_value=mmsSelections, $
    uval='MMS_FIELDS', uname='mms_fields')
  themisLabel = widget_label(themisBase2, value='THEMIS: ', /align_left)
  thmFieldSelections = thmSelections
  themisButtons = CW_BGROUP(themisBase2, thmProbes, /row, /nonexclusive, set_value=thmSelections, $
    uval='THM_FIELDS', uname='thm_fields')
  clusterLabel = widget_label(clusterBase2, value='Cluster:    ', /align_left)
  clusterFieldSelections = fix([0,0,0,0,0])    ; default to MMS selections
  clusterButtons = CW_BGROUP(clusterBase2, clusterProbes, /row, /nonexclusive, set_value=clusterFieldSelections, $
    uval='CLUSTER_FIELDS', uname='cluster_fields')
  widget_control, clusterButtons, sensitive=0
  
  fields = [' Field (Total)', ' Field (X Component)', ' Field (Y Component)',' Field (Z Component)']
  fieldStrings = ['Bt', 'Bx', 'By', 'Bz']
  fieldSelections = ['Bt']
  fieldsButtons = CW_BGROUP(fieldButtonBase, fields, /col, /nonexclusive, set_value=[1,0,0,0], UNAME='fields')

  f1Label = widget_label(f1Base, value='f1 (Max): ', /align_left)
  xyzStrings = ['X', 'Y', 'Z']
  f1buttons = CW_BGROUP(f1Base, xyzStrings, /row, /exclusive, set_value=0, UNAME='F1')
  f2Label = widget_label(f2Base, value='f2 (Mid): ', /align_left)
  f2buttons = CW_BGROUP(f2Base, xyzStrings, /row, /exclusive, set_value=1, UNAME='F2')
  f3Label = widget_label(f3Base, value='f3 (Min): ', /align_left)
  f3buttons = CW_BGROUP(f3Base, xyzStrings, /row, /exclusive, set_value=2, UNAME='F3')

  mddOptionsCalcButton = widget_button(mddOptionsButtonBase, value='Calculate', uval='CALC_MDD', xsize =100, $
    tooltip='This button will perform the MDD calculations')
  mddoptionsplotButton = widget_button(mddOptionsButtonBase, value='Plot', uval='PLOT_MDD', xsize =100, $
    tooltip='This button will plot the results of the MDD analysis')

  deltaLabel = widget_label(deltaBase, value='Delta t (sec):   ')
  deltaIncrement = spd_ui_spinner(deltaBase, $
    Increment=1, Value=1.0, UValue='DeltaT', UName='deltat',min_value=1, $
    tooltip='The delta t in seconds will be used by the calculation')
  deltaCalcButton = widget_button(deltaBase, value='Calculate', uvalue='CALC_STD', uname='calc_std', $
    tooltip='This button will perform the STD analysis')

  dimenStrings = ['1-D', '2-D', '3-D (Default)']
  dimenButtons = CW_BGROUP(dimensionButtonBase, dimenStrings, /col, /exclusive, set_value=2, UNAME='dimensionality')
  dimenPlotButtons = widget_button(dimensionPlotBase, value='Plot', uvalue='PLOT_STD', uname='plot_std', $
    xsize=100,tooltip='This button will plot the results of the STD analysis')

  varComboBase = widget_base(yrangeBase, /row, ypad=3)
  varLabel = widget_label(varComboBase, value='Select Variable: ', /align_left)
  varArray = ['Eigenvalue', 'Vmax', 'Vmid', 'Vmin']
  varCombo = widget_combobox(varComboBase,$
    value=varArray,$
    uvalue='YRANGE_VAR',$
    uname='yrange_var', $
    sensitive=0)
  currentvar=varArray[0]
  yRangeMinBase = widget_base(varComboBase, /row, xpad=6)
  yRangeMinLabel = widget_label(yRangeMinBase, value='Min: ')
  yRangeMinText = widget_text(yRangeMinBase, value='0.0', /editable, uvalue='YRANGE_MIN', uname='yrange_min', $
    sensitive=0, xsize=15)
  yRangeMaxBase = widget_base(varComboBase, /row, xpad=4)
  yRangeMaxLabel = widget_label(yRangeMaxBase, value='Max: ')
  yRangeMaxText = widget_text(yRangeMaxBase, value='0.0', /editable, uvalue='YRANGE_MAX', uname='yrange_max', $
     sensitive=0, xsize=15)
  yrangeStructure = { varNames: ['lamba', 'Eigenvector_max', 'Eigenvector_mid', 'Eigenvector_min'], $
                      ymin: 0., $
                      ymax: 0. }

  replotBase = widget_base(yrangeBase, /row, ypad=3, xpad=75)
  replotMDD = widget_button(replotBase, value='Replot MDD Results', uvalue='REPLOT_MDD', uname='replot_mdd', xsize=120, $
    tooltip = 'This button will replot the MDD results with the Yaxis range specified in the min/max text boxes')
  replotMDD = widget_button(replotBase, value='Replot STD Results', uvalue='REPLOT_STD', uname='replot_std', xsize=120, $
    tooltip = 'This button will replot the STD results with the Yaxis range specified in the min/max text boxes')
  
  st_text = '2015-11-24/19:40:00'
  et_text = '2015-11-24/19:42:00'
  plotdur = time_double(et_text)-time_double(st_text)
  mddTime=time_double([st_text, et_text])
  tr_obj_mdd=obj_new('spd_ui_time_range',starttime=st_text,endtime=et_text)
  ; set the default date, the setting time above does not work because tr_obj is defined
  stat = tr_obj_mdd->SetStartTime(st_text)
  stat = tr_obj_mdd->SetEndTime(et_text)
  timeMDDWidget = spd_ui_time_widget(mddTimeBase,$
    statusBar,$
    historyWin,$
    oneday=0,$
    timeRangeObj=tr_obj_mdd,$
    uvalue='TIME_MDD_WIDGET',$
    uname='time_mdd_widget')

  ; duration spinner
  durmddBase = widget_base(mddTimeBase, /row)
  durmddLabel = widget_label(durmddBase, value='Duration (sec):   ')
  mdddur = plotdur
  durmddIncrement = spd_ui_spinner(durmddBase, $
    Increment=1, Value=mdddur, UValue='MDD_DURATION', UName='mddduration',min_value=1)

  calcMeanDirBase = widget_base(mddTimeButtonBase, /row, ypad=12, xpad=20)
  calcMeanDirButton = widget_button(calcMeanDirBase, value='Calculate Mean Directions', uvalue='CALC_MEAN_DIR', uname = 'calc_mean_dir')
  calcMeanVelBase = widget_base(mddTimeButtonBase, /row, ypad=12, xpad=20)
  calcMeanVelButton = widget_button(calcMeanVelBase, value='Calculate Mean Velocities', uvalue='CALC_MEAN_VEL', uname = 'calc_mean_vel')
  
  ;
  ; RESULTS SECTION
  ;
  resultLabel =  widget_label(rightBase, value='Results:', /align_left, /align_top)
  resultBase = widget_base(rightBase, /col, /frame)
  resultText = widget_text(resultBase, xsize=50, ysize=54, /scroll, uname='resulttext')
  plotResBase = widget_base(rightBase, /col, /align_center, ypad=5)
  plotResButton = widget_button(plotResBase, value='Plot Data in New Coordinate System', uval='NEW_PLOT', uname='new_plot')
  
  doneButton = widget_button(buttonBase, value='Close', uval='CLOSE', xsize=75)
  helpButton = widget_button(buttonBase, value='Help', uval='HELP', xsize=75)

  ; create a structure for each mission with default selections
  thmStructure = { sats:thmSelections, instr:'Magnetic Field', dtype:'fgh', coord:'gsm', satFields:thmFieldSelections}
  mmsStructure = { sats:mmsSelections, instr:'Magnetic Field', dtype:'srvy', coord:'dmpa', satFields:mmsFieldSelections }
  loadedTvars = make_array(4, /string)
  loadedTpos = make_array(4, /string)
  analysisStructure = { trange:mddTime, thmsats:thmSelections, mmssats:mmsSelections, $
      fields:['Bt', '', '', ''], f1:0, f2:1, f3:2, deltaT:fix(1), dimensionality:'3D' }

  state = {tlb:tlb,$
    timeRangeObjPlot:tr_obj_plot, $
    timeRangeObjmdd:tr_obj_mdd, $
    statusBar:statusBar, $
    historyWin:historyWin, $
    plotDur:plotdur, $
    mddDur:mdddur, $
    plotWindow:0, $
    mddWindow:0, $
    resultsString:[''], $
    mddCount:1, $
    stdCount:1, $
    thmProbes:thmProbes, $
    mmsProbes:mmsProbes, $
    thmMagdataArray:thmMagdataArray, $
    thmElecdataArray:thmElecdataArray, $
    thmVeldataArray:thmVeldataArray, $
    mmsMagdataArray:mmsMagdataArray, $
    mmsElecdataArray:mmsElecdataArray, $
    mmsVeldataArray:mmsVeldataArray, $
    clusterdataArray:clusterdataArray, $
    thmCoordinateArray:thmCoordinateArray, $
    mmsMagCoordArray:mmsMagCoordArray, $
    mmsElecCoordArray:mmsElecCoordArray, $
    mmsVelCoordArray:mmsVelCoordArray, $
    clusterCoordinateArray:clusterCoordinateArray, $
    thmStructure:thmStructure, $
    mmsStructure:mmsStructure, $     
    loadedTvars:loadedTvars, $
    loadedTpos:loadedTpos, $
    xyzstrings:xyzstrings, $
    yrangeStructure:yrangeStructure, $    
    analysisStructure:analysisStructure }

  Centertlb, tlb
  Widget_Control, tlb, Set_UValue=state, /No_Copy
  Widget_Control, tlb, /Realize

  ;keep windows in X11 from snaping back to
  ;center during tree widget events
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  XManager, 'spd_ui_mdd_std', tlb, /No_Block

  ;if pointer or struct are not valid the original structure will be unchanged
  if ptr_valid(data_ptr) && is_struct(*data_ptr) then begin
    data_structure = *data_ptr
  endif

  heap_gc   ; clean up memory before exit

  return

end
