

;+
;Procedure: THM_SST_ADD_SPINDATA.PRO
;
;Purpose: Adds appropriate spin model data to SST common block structure.
;
;Arguments: 
;    cashe:  structure from common block
;
;Keywords:
;    trange:  Two-element time range of requested data (double)
;    use_eclipse_corrections:  Flag to specify which spin model will be used:
;      0 - No corrections (default)
;      1 - Use partial corrections
;      2 - Use full eclipse corrections
;
;Notes:  To be called within thm_load_sst.
;
;-

pro thm_sst_add_spindata, cache, trange=trange, $
                          use_eclipse_corrections=use_eclipse_corrections

    compile_opt idl2, hidden


  if size(cache,/type) ne 8 then begin
    dprint, dlevel=0, 'Error:  Input must be valid structure.'
    return
  endif
  
  support_suffix = '_sst_part_tmp'
  
  probe = cache.sc_name
  
  
  ; Load support data and initialize spin model
  thm_load_state, probe=probe, trange=trange, suffix=support_suffix, $
                  /get_support_data


  ; Get reference to spin model
  model = spinmodel_get_ptr(probe, use_eclipse_corrections=use_eclipse_corrections)

  if ~obj_valid(model) then return
  
  
  ; Interpolate desired quantities to
  ; given abscissae, and add to data structure
  ;---------------------------------------------------
  if ptr_valid(cache.sif_064_time) then begin
      spinmodel_interp_t, model=model, time = *cache.sif_064_time, $
        eclipse = sif_064_edphi
      ptr_free, cache.sif_064_edphi
      cache.sif_064_edphi = ptr_new( temporary(sif_064_edphi) )
  endif

  if ptr_valid(cache.sef_064_time) then begin
      spinmodel_interp_t, model=model, time = *cache.sef_064_time, $
        eclipse = sef_064_edphi
      ptr_free, cache.sef_064_edphi
      cache.sef_064_edphi = ptr_new( temporary(sef_064_edphi) )
  endif

  if ptr_valid(cache.seb_064_time) then begin
      spinmodel_interp_t, model=model, time = *cache.seb_064_time, $
        eclipse = seb_064_edphi
      ptr_free, cache.seb_064_edphi
      cache.seb_064_edphi = ptr_new( temporary(seb_064_edphi) )  
  endif

  if ptr_valid(cache.sir_001_time) then begin
      spinmodel_interp_t, model=model, time = *cache.sir_001_time, $
        eclipse = sir_001_edphi
      ptr_free, cache.sir_001_edphi
      cache.sir_001_edphi = ptr_new( temporary(sir_001_edphi) )
  endif

  if ptr_valid(cache.ser_001_time) then begin
      spinmodel_interp_t, model=model, time = *cache.ser_001_time, $
        eclipse = ser_001_edphi
      ptr_free, cache.ser_001_edphi
      cache.ser_001_edphi = ptr_new( temporary(ser_001_edphi) )
  endif

  if ptr_valid(cache.sir_006_time) then begin
      spinmodel_interp_t, model=model, time = *cache.sir_006_time, $
        eclipse = sir_006_edphi  
      ptr_free, cache.sir_006_edphi
      cache.sir_006_edphi = ptr_new( temporary(sir_006_edphi) )
  endif

  if ptr_valid(cache.ser_006_time) then begin
      spinmodel_interp_t, model=model, time = *cache.ser_006_time, $
        eclipse = ser_006_edphi
      ptr_free, cache.ser_006_edphi
      cache.ser_006_edphi = ptr_new( temporary(ser_006_edphi) )
  endif

  ; Remove temporary data
  store_data, '*' + support_suffix, /delete

end

