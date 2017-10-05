
;+
;Procedure: THM_SST_ADD_SPINDATA2.PRO
;
;Purpose: Add appropriate spin model data to L1 SST data
;         loaded via thm_load_sst2.pro.
;
;Arguments: 
;    dts: Structure from thm_load_sst2.pro (thm_load_sst2_cdfivars)
;        containing pointers to time varying quatities for a single
;        data type.
;
;Keywords:
;    use_eclipse_corrections:  Flag to specify which spin model will be used:
;      0 - No corrections (default)
;      1 - Use partial corrections
;      2 - Use full eclipse corrections
;
;Notes:  To be called within thm_load_sst2.
;        Assumes STATE data has already been loaded.
;
;-

pro thm_sst_add_spindata2, dts, use_eclipse_corrections=use_eclipse_corrections

    compile_opt idl2, hidden


  if size(dts,/type) ne 8 then begin
    dprint, dlevel=0, 'Error:  Input must be valid structure.'
    return
  endif

  if ~ptr_valid(dts.times) then begin
    return
  end
  
  
  probe = (*dts.dat3d).spacecraft[0]


  ; Get reference to spin model
  model = spinmodel_get_ptr(probe, use_eclipse_corrections=use_eclipse_corrections)
  
  if ~obj_valid(model) then return

  
  ;Interpolate desired quatities to given abscissa
  spinmodel_interp_t, model=model, time = *dts.times, $
                      eclipse = eclipse_dphi


  ;Set pointer
  ptr_free, dts.edphi
  dts.edphi = ptr_new(eclipse_dphi)
  

end
