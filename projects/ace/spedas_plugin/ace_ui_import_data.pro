;+
;NAME:
;  ace_ui_import_data
;
;PURPOSE:
;  Modularized gui ace data loader
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/ace/spedas_plugin/ace_ui_import_data.pro $
;
;--------------------------------------------------------------------------------


pro ace_ui_import_data,$
                         loadStruc, $
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  ;needed for appropriate layering and modality of popups
                         replay=replay,$
                         overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 
                         
  compile_opt hidden,idl2

  instrument=loadStruc.instrument[0]
  datatype=loadStruc.datatype[0]
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

  par_names = 'ace_'+datatype+'_'+instrument+'_'+parameters

  ;select the appropriate ace load routine
  if instrument eq 'mfi' then begin
    ace_mfi_load,datatype=datatype,trange=timeRange,varformat='*'
  endif else if instrument eq 'swe' then begin
    ace_swe_load,datatype=datatype,trange=timeRange
  endif
  
  spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  
  if new_vars[0] ne '' then begin
    ;only add the requested new parameters
    new_vars = ssl_set_intersection([par_names],[new_vars])
    loaded = 1
    ;loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin
    
      if stregex(new_vars[i],'gse',/fold_case,/boolean) then begin
        coordSys = 'gse'
      endif else if stregex(new_vars[i],'gsm',/fold_case,/boolean) then begin
        coordSys = 'gsm'
      endif else if stregex(new_vars[i],'rtn',/fold_case,/boolean) then begin
        coordSys = 'rtn'
      endif else begin 
        coordSys = ''
      endelse
      
      ;Check if data is already loaded, so that it can query user on whether they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue
      
      result = loadedData->add(new_vars[i],mission='ACE',observatory='ACE',instrument=instrument,coordSys=coordSys)
      
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'ACE: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
    
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
     
  if loaded eq 1 then begin
    statusBar->update,'ACE Data Loaded Successfully'
    historyWin->update,'ACE Data Loaded Successfully'
  endif else begin
    statusBar->update,'No ACE Data Loaded.  Data may not be available during this time interval.'
    historyWin->update,'No ACE Data Loaded.  Data may not be available during this time interval.'    
  endelse

end
