;+
;NAME:
;  mvn_kp_ui_import_data
;
;PURPOSE:
;  Modularized gui MAVEN KP mission data loader/importer
;  Lightly modified version of the ACE loader/importer
;
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-01-11 11:57:33 -0800 (Mon, 11 Jan 2016) $
;$LastChangedRevision: 19710 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_kp_ui_import_data.pro $
;
;--------------------------------------------------------------------------------


Pro mvn_kp_ui_import_data, loadStruc, $
                           loadedData,$
                           statusBar,$
                           historyWin,$
                           parent_widget_id,$ ;needed for appropriate layering and modality of popups
                           replay=replay,$
                           overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 
                         
  compile_opt hidden,idl2

  mvn_spd_init

  instrument=loadStruc.instrument[0]
  parameters=loadStruc.parameters
  timeRange=loadStruc.timeRange
  loaded = 0

  new_vars = ''

  overwrite_selection=''
  overwrite_count =0

  if ~keyword_set(replay) then begin
     overwrite_selections = ''
  endif

  tn_before = [tnames('*',create_time=cn_before)]
;  tn_before_time_hash = [tn_before + time_string(double(cn_before),/msec)]

  mvn_qlook_load_kp, trange=timeRange, tvars=tplotnames

  If(is_string(tplotnames)) Then Begin

     spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  
     if new_vars[0] ne '' then begin
    ;only add the requested new parameters
        new_vars = ssl_set_intersection([instrument+parameters],[tplotnames])
        loaded = 1
    ;loop over loaded data
        for i = 0,n_elements(new_vars)-1 do begin
                                ;Check if data is already loaded, so that it can query user on whether they want to overwrite data
           spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                       replay=replay,overwrite_selections=overwrite_selections
           if strmid(overwrite_selection, 0, 2) eq 'no' then continue
           result = loadedData->add(new_vars[i],mission='MAVEN',observatory='MAVEN',instrument=instrument,coordSys=coordSys)
           if ~result then begin
              statusBar->update,'Error loading: ' + new_vars[i]
              historyWin->update,'MAVEN KP: Error loading: ' + new_vars[i]
              return
           endif
        endfor
     endif
     if to_delete[0] ne '' then begin
        store_data,to_delete,/delete
     endif
  Endif Else loaded = 0
  if loaded eq 1 then begin
    statusBar->update,'MAVEN KP Data Loaded Successfully'
    historyWin->update,'MAVEN KP Data Loaded Successfully'
  endif else begin
    statusBar->update,'No MAVEN KP Data Loaded.  Data may not be available during this time interval.'
    historyWin->update,'No MAVEN KP Data Loaded.  Data may not be available during this time interval.'    
  endelse
end
