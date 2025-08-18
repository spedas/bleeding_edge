;+
; Purpose: Wrapper to thm_part_products, to be called during replay by spd_ui_call_sequence  Modularizes
; some operations. 
; 
; Inputs:    probe,$
;            dtype,$
;            trange, $
;            start_angle,$
;            suffix,$ 
;            outputs, $
;            phi,$
;            theta,$
;            pitch,$
;            gyro, $
;            energy,$
;            regrid, $
;            fac_type,$
;            sst_cal, $
;            sst_method_clean, $
;            statusbar,$
;            historyWin,$
;            loadedData
; 
;
;
;Version:
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
; $LastChangedRevision: 14326 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_part_getspec_replay.pro $
;-

pro spd_ui_part_getspec_replay, probe,$
                                dtype,$
                                trange, $
                                start_angle,$
                                suffix,$ 
                                outputs, $
                                phi,$
                                theta,$
                                pitch,$
                                gyro, $
                                energy,$
                                regrid, $
                                fac_type,$
                                sst_cal, $
                                sst_method_clean, $
                                statusbar,$
                                historyWin,$
                                loadedData
 
  compile_opt hidden
 
  ;This craziness with the time hash is to identify new variables, so they can be added
  ;Because some variables may be replaced, we need to incorporate creation times, and
  ;this method, though somewhat opaque, is vectorized
  tn_before = tnames('*',create_time=cn_before)
  
  ;support data only needed for FAC transformations
  if in_set('pa',outputs) or in_set('gyro',outputs) then begin
    thm_load_state, probe=probe, trange=trange, /get_support
    thm_load_fit, probe=probe, trange=trange, datatype='fgs', level='l1', coord='dsl'
  endif
  
  ;load particle data
  thm_part_load, probe=probe, datatype=dtype, trange=trange, sst_cal=sst_cal
  
  ;if energy limits are off this variable should be a scalar
  if n_elements(energy) eq 1 then energy = energy[0]
  
  thm_part_products, probe=probe, datatype=dtype, trange=trange, $
              start_angle=start_angle, suffix=suffix, outputs=outputs, $
              phi=phi, theta=theta, pitch=pitch, gyro=gyro, energy=energy, $
              fac_type=fac_type, regrid=regrid, tplotnames=tplotnames, $
              sst_cal=sst_cal, sst_method_clean=sst_method_clean, $
              gui_statusBar=statusbar, gui_historyWin=historyWin
              
  spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
  
  if keyword_set(tplotnames) then begin
    for i=0, n_elements(tplotnames)-1L do begin
      if ~loadedData->add(tplotnames[i]) then begin
        historywin->update,'Failed to add data: ' + tplotnames[i] + ' after getspec replay'
        statusbar->update,'Failed to add data: ' + tplotnames[i] + ' after getspec replay'
        return
      endif
    endfor
  endif
   
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
              
end
