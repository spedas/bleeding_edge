;+
;NAME:
;  goes_ui_import_data
;
;PURPOSE:
;  Modularized gui goes data loader
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goes/spedas_plugin/goes_ui_import_data.pro $
;
;--------------------------------------------------------------------------------

pro goes_ui_import_data,     $
                      loadStruc,        $
                      loadedData,       $
                      statusBar,        $
                      historyWin,       $
                      parent_widget_id, $
                      replay=replay,    $                      
                      overwrite_selections=overwrite_selections                            

  compile_opt hidden,idl2

  probe = loadStruc.probe
  dataType = loadStruc.datatype
  resType = loadStruc.restype
  timeRange = loadStruc.timeRange
  
  instrument = dataType
  loaded = 0
  
  goesmintime = '1995-01-01'
  ; allow the user to load data up until the current time
  goesmaxtime = time_string(systime(/seconds))

  new_vars = ''

  overwrite_selection='' 
  overwrite_count =0

  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  ; check that the requested time falls within our valid range
  if time_double(goesmaxtime) lt time_double(timerange[0]) || $
     time_double(goesmintime) gt time_double(timerange[1]) then begin
     statusBar->update,'No GOES Data Loaded, GOES data is only available between ' + goesmintime + ' and ' + goesmaxtime
     historyWin->update,'No GOES Data Loaded,  GOES data is only available between ' + goesmintime + ' and ' + goesmaxtime
     return
  endif
    
  tn_before = [tnames('*',create_time=cn_before)]

  if resType eq 'full' then begin
      goes_load_data, trange = timeRange, probes = probe, datatype = datatype
  endif else if resType eq '1-m' then begin
      goes_load_data, trange = timeRange, probes = probe, datatype = datatype, /avg_1m
  endif else if resType eq '5-m' then begin
      goes_load_data, trange = timeRange, probes = probe, datatype = datatype, /avg_5m
  endif

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
      result = loadedData->add(new_vars[i],mission='GOES',observatory='G'+probe,instrument=strupcase(datatype))
      
      ; report errors to the status bar and add them to the history window
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'GOES: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
  
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
     
  if loaded eq 1 then begin
    statusBar->update,'GOES Data Loaded Successfully'
    historyWin->update,'GOES Data Loaded Successfully'
  endif else begin
    statusBar->update,'No GOES Data Loaded'
    historyWin->update,'No GOES Data Loaded'
  endelse

end
