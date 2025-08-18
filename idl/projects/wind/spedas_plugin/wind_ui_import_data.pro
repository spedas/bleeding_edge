;+
;NAME:
;  wind_ui_import_data
;
;PURPOSE:
;  Modularized gui wind data loader
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:14:31 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/wind/spedas_plugin/wind_ui_import_data.pro $
;
;--------------------------------------------------------------------------------
pro wind_ui_import_data,$
                         loadStruc,$
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

  ;select the appropriate wind load routine
  if instrument eq 'or' then begin
    par_names = 'wi_'+datatype+'_or_'+parameters
    wi_or_load,datatype=datatype,trange=timeRange,varformat='*'
  endif else if instrument eq 'mfi' then begin
    par_names = 'wi_'+datatype+'_mfi_'+parameters
    wi_mfi_load,datatype=datatype,trange=timeRange,varformat='*'
  endif else if instrument eq 'swe' then begin
    par_names = 'wi_swe_' + parameters
    wi_swe_load,datatype=datatype,trange=timeRange,varformat='*'
  endif else if instrument eq '3dp' then begin
    ;CDF_LOAD_VARS crashes for some reason if varformat is '*' for datatype ='ELPD'
    if datatype eq 'elpd' then begin
      wi_3dp_load,datatype='elpd_old',trange=timeRange,varformat='TIME FLUX ENERGY PANGLE INTEG_T EDENS TEMP QP QM QT REDF VSW MAGF'
    endif else begin
      wi_3dp_load,datatype=datatype,trange=timeRange,varformat='*'
    endelse
    par_names = 'wi_3dp_'+datatype+'_'+parameters
  
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
      endif else if stregex(new_vars[i],'GCI',/fold_case,/boolean) then begin
        coordSys = 'gci'
      endif else begin
        coordSys = ''
      endelse
     
      ;Check if data is already loaded, so that it can query user on whether they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue

      result = loadedData->add(new_vars[i],mission='WIND',observatory='WIND',instrument=instrument,coordSys=coordSys)
      
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'WIND: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
    
  if n_elements(to_delete) gt 0 && is_string(to_delete) then begin
    store_data,to_delete,/delete
  endif
     
  if loaded eq 1 then begin
    statusBar->update,'WIND Data Loaded Successfully'
    historyWin->update,'WIND Data Loaded Successfully'
  endif else begin
    statusBar->update,'No WIND Data Loaded.  Data may not be available during this time interval.'
    historyWin->update,'No WIND Data Loaded.  Data may not be available during this time interval.'    
  endelse

end
