;+
;Procedure:
;  spd_slice2d_custom_rotation
;
;
;Purpose:
;  Retrieve a user-provided rotation matrix and apply to data as needed.
;
;
;Input:
;  custom_rotation:  3x3 rotation matrix or name to tplot variable containing such matrix
;  trange:  time range of the slice, tplot vars will be averaged over this range
;  determ_tolerance: acceptable tolerance for determ=1, defaults to 1e-6
;
;Output:
;  matrix:  the transformation matrix
;
;
;Input/Output (transformed if present):
;  vectors:  array of particle 3 vectors
;  bfield: b field vector 
;  vbulk: bulk velocity vector
;  sunvec: sun position vector
;
;
;Notes:
;
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2020-05-04 13:37:27 -0700 (Mon, 04 May 2020) $
;$LastChangedRevision: 28663 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_custom_rotation.pro $
;-
pro spd_slice2d_custom_rotation, $ 
                      custom_rotation=custom_rotation, $
                      trange=trange, $
              
                      vectors=vectors, $
                      
                      bfield=bfield, $
                      vbulk=vbulk, $
                      sunvec=sunvec, $
                      
                      matrix=matrix, $
                        
                      determ_tolerance=determ_tolerance, $

                      fail=fail, $
                      perp_vbulk=perp_vbulk
    

    compile_opt idl2, hidden


  if undefined(custom_rotation) then begin
    matrix = [ [1.,0,0], [0,1,0], [0,0,1] ]
    return
  endif
  if undefined(determ_tolerance) then determ_tolerance = 1e-6

  spd_slice2d_get_support, custom_rotation, trange, /matrix, output=matrix
  
  ; In case of [1,3,3] array
  if dimen1(matrix) eq 1 then  matrix = reform(matrix)

  ; Check that the matrix is valid
  if ~array_equal(dimen(matrix),[3,3]) then begin
    fail = 'Invalid custom rotation matrix'
    dprint, dlevel=1, fail
    return
  endif

  if total( finite(matrix,/nan) ) gt 0 then begin
    fail = 'Custom rotation matrix contains non-finite values'
    dprint, dlevel=1, fail
    return
  endif

  ; Check that determ=1
  if abs(determ(matrix)-1) gt determ_tolerance then begin
    fail = 'Custom rotation matrix may not be valid right-handed rotation'
    dprint, dlevel=1, fail
    return
  endif

  ; Prevent data from being mutated to doubles
  matrix = float(matrix)

  dprint, dlevel=4, 'Applying custom rotation'

  ; Transform data and support vectors 
  if ~undefined(vectors) then vectors = matrix ## temporary(vectors)
  if n_elements(vbulk) eq 3 then vbulk = matrix ## vbulk
  if n_elements(perp_vbulk) eq 3 then perp_vbulk = matrix ## perp_vbulk
  if n_elements(bfield) eq 3 then bfield = matrix ## bfield
  if n_elements(sunvec) eq 3 then sunvec = matrix ## sunvec

end
