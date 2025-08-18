;+
;Procedure:
;  thm_part_addsun
;
;Purpose:
;  Populate sun direction vector field in 3D particle structures.
;  This is meant as a modular solution to the need to add this
;  vector in multiple places/conditions.
;
;Input:
;  ds:  pointer array to particle structures
;  probe:  scalar probe designation
;  trange:  two element time range
;
;Output:
;  none
;
;Notes:
;  The SUN_VECTOR field must already be present in the target structures!
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 17:47:13 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20329 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_addsun.pro $
;-
pro thm_part_addsun, ds, probe=probe, trange=trange

    compile_opt idl2, hidden


  if ~ptr_valid(ds[0]) then begin
    dprint, dlevel=0, 'Invalid input data'
    return
  endif

  ctn = '2dslice_temp_sundir'
  
  ;load spacecraft ephemeris
  thm_load_state, probe=probe, trange=time_double(trange) + 120*[-1,1], suffix='_'+ctn, $
                  /get_support_data
  
  for i=0, n_elements(ds)-1 do begin
  
    ;structure field must already be present
    ;(lest we have to loop over time and rebuild entire array, gahhh)
    if ~in_set('sun_vector',strlowcase(tag_names((*ds[i])[0]))) then begin
      dprint, dlevel=0, 'Data structures do not have appropriate field'
      return
    endif

    ;use center time
    times = ((*ds[i]).time + (*ds[i]).end_time) / 2d

    ;get sun direction by transforming GSE x into DSL
    store_data, ctn, verbose=0, $ 
                data = {x: times, $
                        y: [1.,0,0] ## replicate(1,n_elements(times)) }

    thm_cotrans, ctn, probe=probe, in_coord='gse', out_coord='dsl', $
                 support_suffix='_'+ctn, out_suff='_dsl'
  
    get_data, ctn+'_dsl', data=ctd
    if ~is_struct(ctd) then begin
      dprint, dlevel=0, 'Could not obtain coordinate transform from GSE -> DSL'+ $
                        ', check for error from THM_COTRANS.'
      return
    endif

    ;dimension of structure array (time) must be last
    (*ds[i]).sun_vector = transpose(ctd.y)
  
  endfor


end