;+
;Procedure:
;  thm_sst_set_trange
;
;Purpose:
;  Helper function for thm_load_sst.
;  Sets the common block time ranges for applicable data types.
;
;Input:
;  cache: SST data pointer structure from thm_load_sst
;  trange: two element time range
;
;Output:
;  none
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-05-05 18:12:35 -0700 (Mon, 05 May 2014) $
;$LastChangedRevision: 15053 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/thm_sst_set_trange.pro $
;
;-
pro thm_sst_set_trange, cache, trange=trange, use_eclipse_corrections=use_eclipse_corrections

    compile_opt idl2, hidden

  
  probe = cache.sc_name

  ;use same default as file_dailynames if not explicitly set
  if undefined(trange) then trange = timerange()

  ;ensure eclipse correction field is not blank
  if undefined(use_eclipse_corrections) then begin
    eclipse = 0
  endif else begin
    eclipse = use_eclipse_corrections
  endelse

  ;psif
  if ptr_valid(cache.sif_064_time) then begin
    thm_part_trange, probe, 'psif', set={trange:trange,eclipse:eclipse}
  endif
  
  ;psir
  if ptr_valid(cache.sir_001_time) or ptr_valid(cache.sir_006_time) then begin
    thm_part_trange, probe, 'psir', set={trange:trange,eclipse:eclipse}
  endif
  
  ;psef
  if ptr_valid(cache.sef_064_time) then begin
    thm_part_trange, probe, 'psef', set={trange:trange,eclipse:eclipse}
  endif
  
  ;pser
  if ptr_valid(cache.ser_001_time) or ptr_valid(cache.ser_006_time) then begin
    thm_part_trange, probe, 'pser', set={trange:trange,eclipse:eclipse}
  endif
  
  ;pseb
  if ptr_valid(cache.seb_064_time) then begin
    thm_part_trange, probe, 'pseb', set={trange:trange,eclipse:eclipse}
  endif

  

end