;+
;NAME:
;  fast_ui_import_data
;
;PURPOSE:
;  Modularized gui FAST mission data loader/importer
;  Lightly modified version of the ACE loader/importer
;
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-10-24 12:13:12 -0700 (Mon, 24 Oct 2016) $
;$LastChangedRevision: 22190 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/fast/spedas_plugin/fast_ui_import_data.pro $
;
;--------------------------------------------------------------------------------


pro fast_ui_import_data,$
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
  paRange=loadStruc.paRange
  energyRange=loadStruc.energyRange

  loaded = 0

  new_vars = ''

  overwrite_selection=''
  overwrite_count =0

  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif

  tn_before = [tnames('*',create_time=cn_before)]
;  tn_before_time_hash = [tn_before + time_string(double(cn_before),/msec)]
  
  If(instrument Eq 'ESA') Then Begin ;added L2 ESA input, 2016-05-02
     ;translate from 
     typ = ['ies', 'ees', 'ieb', 'eeb']
     jtyp = ['ion_survey', 'electron_survey', 'ion_burst', 'electron_burst']
     parnames_list = ['Ion_eflux_survey', 'Electron_eflux_survey', $
                      'Ion_eflux_burst',  'Electron_eflux_burst', $
                      'Ion_pad_survey', 'Electron_pad_survey', $
                      'Ion_pad_burst', 'Electron_pad_burst']
     parnames_tplot_ed = 'fa_'+['ies_l2_eflux', 'ees_l2_eflux', $
                                'ieb_l2_eflux', 'eeb_l2_eflux']
     ;Add suffixes for distributions
     parange0 = strcompress(string(long(parange)), /remove_all)
     ed_suffix = '_PaFrom'+strjoin(parange0, 'To')
     parnames_tplot_ed = parnames_tplot_ed+ed_suffix
     parnames_tplot_pa = 'fa_'+['ies_l2_pad', 'ees_l2_pad', $
                                'ieb_l2_pad', 'eeb_l2_pad']
     erange0 = strcompress(string(long(energyrange)), /remove_all)
     pa_suffix = '_EnFrom'+strjoin(erange0, 'To')
     parnames_tplot_pa = parnames_tplot_pa+pa_suffix
     parnames_tplot = [parnames_tplot_ed, parnames_tplot_pa]

     par1 = strarr(n_elements(parameters))
     For j = 0, n_elements(parameters)-1 Do Begin
        temp = strlowcase(strsplit(parameters[j], '_', /extract))
        par1[j] = strjoin(temp[[0,2]], '_')
     Endfor
     sstyp = sswhere_arr(jtyp, par1)
     If(sstyp[0] Eq -1) Then Begin
        statusBar->update, 'FAST ESA: Bad datatype: ' + strjoin(par1, ' ')
        historyWin->update, 'FAST ESA: Bad datatype: ' + strjoin(par1, ' ')
        return
     Endif
     fa_esa_load_l2, type=typ[sstyp], trange=timeRange
; Create the tplot variables
     ntyp = n_elements(sstyp)
     tplotnames = ''
     For j = 0, ntyp-1 Do Begin
        dummy='' & dummy1=''
        dummy = fa_esa_l2_pad(typ[sstyp[j]], trange = timeRange, $
                              energy=energyRange, suffix = pa_suffix)
        If(is_string(tnames(dummy))) Then tplotnames = [tplotnames, dummy]
        dummy1 = fa_esa_l2_edist(typ[sstyp[j]], trange = timeRange, $
                                 parange = paRange, suffix = ed_suffix)
        If(is_string(tnames(dummy1))) Then tplotnames = [tplotnames, dummy1]
     Endfor
     sspar = sswhere_arr(parnames_list, parameters)
     par_names = parnames_tplot[sspar]
     If(n_elements(tplotnames) Gt 1) Then tplotnames = tplotnames[1:*] $
     Else Begin
        statusBar->update, 'FAST ESA: No Data Loaded: ' + strjoin(par1, ' ')
        historyWin->update, 'FAST ESA: Data loaded: ' + strjoin(par1, ' ')
        return
     Endelse
  Endif Else Begin
     par_names = 'fa_hr_dcb_' + parameters
     fa_load_mag_hr_dcb,trange=timeRange,tplotnames=tplotnames
  Endelse

  spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  
  if new_vars[0] ne '' then begin
    ;only add the requested new parameters
    new_vars = ssl_set_intersection([par_names],[tplotnames])
    loaded = 1
    ;loop over loaded data
    for i = 0,n_elements(new_vars)-1 do begin
    
      ;Check if data is already loaded, so that it can query user on whether they want to overwrite data
      spd_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue
      
      result = loadedData->add(new_vars[i],mission='FAST',observatory='FAST',instrument=instrument,coordSys=coordSys)
      
      if ~result then begin
        statusBar->update,'Error loading: ' + new_vars[i]
        historyWin->update,'FAST: Error loading: ' + new_vars[i]
        return
      endif
    endfor
  endif
    
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
     
  if loaded eq 1 then begin
    statusBar->update,'FAST Data Loaded Successfully'
    historyWin->update,'FAST Data Loaded Successfully'
  endif else begin
    statusBar->update,'No FAST Data Loaded.  Data may not be available during this time interval.'
    historyWin->update,'No FAST Data Loaded.  Data may not be available during this time interval.'    
  endelse

end
