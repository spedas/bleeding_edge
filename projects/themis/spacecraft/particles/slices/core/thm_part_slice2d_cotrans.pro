;+
;Procedure:
;  thm_part_slice2d_cotrans
;
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Performs coordinate transformations from DSL to requested
;  coordinates (COORD keyword to thm_part_slice2d).
;
;
;Input:
;  probe: (string) spacecraft designation (e.g. 'a')
;  coord: (string) target coordinates (e.g. 'gsm')
;  trange: (double) two element time range for slice
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
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_cotrans.pro $
;
;-


; *Assumes the transformation from the data's native DSL to
;  the requested coords (GSM, GSE) is invariant over the
;  time range of the slice.* 
pro thm_part_slice2d_cotrans, probe=probe, coord=coord, trange=trange, $
                              vectors=vectors, bfield=bfield, vbulk=vbulk, sunvec=sunvec, $
                              matrix=matrix, $
                              fail=fail

    compile_opt idl2, hidden


  ctn = '2dslice_temp_cotrans'
  if stregex(coord, '^dsl$', /bool, /fold_case) then return
  if ~keyword_set(probe) then begin
    fail = 'Cannot determine spacecraft. Coordinate transform canceled.'
    dprint,dlevel=1, fail
    return
  endif
  if ~stregex(coord, '(^gsm$)|(^gse$)', /bool, /fold_case) then begin
    fail = 'Invalid coordinate keyword: '+coord
    dprint,dlevel=1, fail
    return
  endif
  
  probe = strlowcase(probe)

  dprint, dlevel=4, 'Rotating to '+strupcase(coord)+' coordinates'

  ;Load necessary support data (2 min padding at each end)
  thm_load_state, probe=probe, trange = trange + 120*[-1,1], suffix='_'+ctn, $
                  /get_support_data, /keep_spin_data, verbose=0


  ;Transform x,y,z unit vectors to new coordinates
  store_data, ctn, data = {x:replicate(mean(trange),3), $
                           y: [ [1.,0,0], [0,1,0], [0,0,1] ] }, verbose=0
  thm_cotrans, ctn, probe=probe, in_coord='dsl', out_coord=coord, $
               support_suffix='_'+ctn, out_suff='_'+coord


  ;Form transformation matrix from transformed basis
  get_data, ctn+'_'+coord, data=ctd
  if size(ctd,/type) ne 8 then begin
    fail = 'Could not obtain coordinate transform from DSL -> '+strupcase(coord)+ $
           ', STATE data may be absent for the requested period.'
    dprint, dlevel=1, fail
    store_data, '*'+ctn+'*', /delete, verbose=0 ;delete temp vars
    return
  endif
  
  ;columns are dsl x,y,z in new coordinates
  matrix = ctd.y


  ;Transform particle and support vectors 
  ; -transformation will be applied to particle vectors later
  ;  if using geometric method (no "vectors" array)
  if keyword_set(vectors) then vectors = matrix ## temporary(vectors)
  if keyword_set(vbulk) then vbulk = matrix ## vbulk
  if keyword_set(bfield) then bfield = matrix ## bfield
  if keyword_set(sunvec) then sunvec = matrix ## sunvec


  ;Delete temporary tplot data
  store_data, '*'+ctn+'*', /delete, verbose=0

end
