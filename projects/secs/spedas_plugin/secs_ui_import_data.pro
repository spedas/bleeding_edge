;+
;NAME:
;  secs_ui_import_data
;
;PURPOSE:
;  Modularized SPEDAS/GUI secs data loader
;
;
;HISTORY:
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2017-10-26 21:47:26 -0700 (Thu, 26 Oct 2017) $
;$LastChangedRevision: 24225 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/spedas_plugin/secs_ui_import_data.pro $
;
;--------------------------------------------------------------------------------

pro secs_ui_import_data,     $
                      loadStruc,        $
                      loadedData,       $
                      statusBar,        $
                      historyWin,       $
                      parent_widget_id, $
                      replay=replay,    $                      
                      overwrite_selections=overwrite_selections                            

  compile_opt hidden,idl2

  dataType = loadStruc.datatype
  timeRange = loadStruc.timeRange
 
  instrument = dataType
  loaded = 0
  
  secsmintime = '2007-01-01'
  ; allow the user to load data up until the current time
  secsmaxtime = time_string(systime(/seconds))

  new_vars = ''

  overwrite_selection='' 
  overwrite_count =0

  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; check that the requested time falls within our valid range
  if time_double(secsmaxtime) lt time_double(timerange[0]) || $
     time_double(secsmintime) gt time_double(timerange[1]) then begin
     statusBar->update,'No SECS Data Loaded, SECS data is partially available between ' + secsmintime + ' and ' + secsmaxtime
     historyWin->update,'No SECS Data Loaded,  SECS data is partially available between ' + secsmintime + ' and ' + secsmaxtime
     return
  endif
    
  tn_before = [tnames('*',create_time=cn_before)]

  secs_load_data, trange = timeRange, datatype = datatype

  if undefined(to_delete) then begin
      spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  endif 

  if new_vars[0] ne '' then begin
    loaded = 1
   
    ; loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin
     
      ; check if data is already loaded, if so query the user on whether 
      ; they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                           replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue

      ; this statement adds the variable to the loadedData object
      if strpos(new_vars[i],'eic') NE -1 then instrument='eics' else instrument='seca'
      result = loadedData->add(new_vars[i],mission='SECS', observatory='none', instrument=instrument, isYaxis=0)
      
      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'SECS: Error loading: ' + new_vars[i]
        historyWin->update,'SECS: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
  
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
     
  if loaded eq 1 then begin
    statusBar->update,'SECS Data Loaded Successfully'
    historyWin->update,'SECS Data Loaded Successfully'
  endif else begin
    statusBar->update,'No SECS Data Loaded'
    historyWin->update,'No SECS Data Loaded'
  endelse

end
