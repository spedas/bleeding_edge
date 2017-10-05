;+
;Procedure:
;  thm_part_slice2d_fac
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Retrieves transformation matrix into field alligned
;  coordinate systems.
;
;
;Input:
;  probe: (string) spacecraft designation (e.g. 'a')
;  coord: (string) target coordinates (e.g. 'phigeo')
;  trange: (double) two element time range for slice
;  mag_data: (string) name of tplot variable containing magnetic field data
;  vectors: (float) N x 3 array of velocity vectors
;  bfield: (float) magnetic field 3-vector
;  vbulk: (float) bulk velocity 3-vector
;  sunvec: (float) spacecraft-sun direction 3-vector
;
;
;Output:
;  If 2d or 3d interpolation are being used then this will transform
;  the velocity vectors and support vectors into the target coordinate system.
;  The transformation matrix will be passed out via the MATRIX keyword.
;
;
;Notes:
;  This assumes the transformation does not change substantially over the 
;  time range of the slice. 
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_fac.pro $
;
;-
pro thm_part_slice2d_fac, probe=probe, coord=coord, trange=trange, mag_data=mag_data, $
                          vectors=vectors, bfield=bfield, vbulk=vbulk, sunvec=sunvec, $
                          matrix=matrix, $
                          fail=fail

    compile_opt idl2, hidden


  ctn = '2dslice_temp_fac'
  if ~keyword_set(probe) then begin
    fail = 'Cannot determine spacecraft. FAC transform canceled.'
    dprint,dlevel=1, fail
    return
  endif

  if ~keyword_set(mag_data) || ~keyword_set(tnames(mag_data)) then begin
    fail = 'Cannot perform FAC transformation without B-field data. '+ $
           'Use MAG_DATA keyword to pass in valid tplot variable.'
    dprint, dlevel=1, fail
    return 
  endif

  probe = strlowcase(probe)

  dprint, dlevel=4, 'Rotating to field aligned coordinates using '+coord

  ;Get averaged bfield data
  ; -This is done separately here because dlimits are needed
  get_data, mag_data, dlimits = mdl ;will need dlimits later
  bvector = thm_dat_avg(mag_data, trange[0], trange[1], /interp)
  if total(finite(bvector,/nan)) gt 0 then begin
    fail = 'Cannot perform FAC transformation.  The data in '+ $
           mag_data+' is out of range.'
    dprint, dlevel=1, fail
    return
  endif
  
  ;Store averaged bfield data for thm_fac_matrix_make
  store_data, 'th'+probe+ctn+'_bfield', verbose=0, dlimits=mdl, $
               data = {x:mean(trange), y: reform(bvector,1,n_elements(bvector))} 

  ;Load necessary support data (5 min padding at each end)
  thm_load_state, probe=probe, trange = trange + 300*[-1,1], $ ;, suffix='_'+ctn, $
                  /get_support_data, /keep_spin_data, verbose=0


  ;Create matrix
  thm_fac_matrix_make, 'th'+probe+ctn+'_bfield', other_dim=coord, $
                       pos_var_name='th'+probe+'_state_pos', $ ;_'+ctn, $
                       newname = ctn+'_mat'

  ;Get transormation matrix from tplot variable
  get_data, ctn+'_mat', data=ctd
  if size(ctd,/type) ne 8 then begin
    fail = 'Could not obtain FAC ('+coord+') transform'+ $
           ', STATE data may be absent for the requested period.'
    dprint, dlevel=1, fail
    store_data, '*'+ctn+'*', /delete, verbose=0 ;delete temp vars
    return
  endif
  
  ;matrix must be transposed to perform dsl->fac for ## operator
  matrix = transpose(ctd.y)

  
  ;Transform particle and support vectors
  if keyword_set(vectors) then vectors = matrix ## temporary(vectors)
  if keyword_set(vbulk) then vbulk = matrix ## vbulk
  if keyword_set(bfield) then bfield = matrix ## bfield ;todo: should == [0,0,1]
  if keyword_set(sunvec) then sunvec = matrix ## sunvec

  ;Delete temporary tplot data
  store_data, '*'+ctn+'*', /delete, verbose=0

end
