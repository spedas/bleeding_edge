;+
;Procedure:
;  thm_part_slice2d_orientslice
;
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Performs transformation into user specified coordinates.
;  This transformation is applied after the COORD and ROTATION
;  transformation have been performed.
;
;
;Input:
;  slice_z: (float) 3 vector specifying the slice's normal
;  slice_x: (float) 3 vector to be projected into the slice plane
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
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_orientslice.pro $
;
;-

; Perform rotation from user specified coordinates to the 
; slice plane's coordinates (determined by SLICE_NORM and SLICE_X)
pro thm_part_slice2d_orientslice, vectors=vectors, vbulk=vbulk, bfield=bfield, sunvec=sunvec, $
                                  type=type, slice_x=slice_x, slice_z=slice_z, $
                                  matrix = matrix, fail=fail
                                  
    compile_opt idl2, hidden


  tolerance = 5d-5 ;arbitrary


  ;check z-axis input
  if keyword_set(slice_z) then begin
    if n_elements(slice_z) ne 3 then begin
      fail='Invalid slice normal, please specify a valid 3-vector'
      dprint, dlevel=1, fail
      return
    endif
  endif else begin
    slice_z = [0,0,1d]
  endelse


  ;copy slice normal and normalize
  z = double(slice_z)
  z = z/norm(z)


  ;check x-axis input
  if keyword_set(slice_x) then begin
    if n_elements(slice_x) ne 3 then begin
      fail='Invalid slice x-axis, please specify a valid 3-vector'
      dprint, dlevel=1, fail  
      return
    endif
  ;if x-axis not specified use projection of ordinate closest to the slice plane
  endif else begin
    
    ;get angle between norm and each ordinate
    ord = [ [1,0,0], [0,1,0], [0,0,1]  ]
    angles = (180/!dpi) * acos( [ total(ord[*,0]*z), $
                                  total(ord[*,1]*z), $
                                  total(ord[*,2]*z)  ] )
    
    ;use ordinate that is closest to perpendicular with norm
    dummy = min( abs(angles - 90), ind)
    
    slice_x = ord[*,ind]
  
    dprint, dlevel=4, 'Slice x-axis not set, using projection of default '+ $
                      (['x','y','z'])[ind] + '-axis)'
  endelse
  

  ;normalize vector used to define slice's x-axis
  xp = double(slice_x)
  xp = xp/norm(xp)
  
  
  ;get slice's y axis
  y = crossp(z,xp)
  
  if norm(y) lt tolerance then begin
    fail='Cannot orient slice plane, x-axis and slice '+ $
         'normal are too close to being parallel.'
    dprint, dlevel=1, fail
    return
  endif

  y = y/norm(y)
  
  
  ;get slice's x axis
  x = crossp(y,z)
  
  if norm(x) lt tolerance then begin ;this should never be true
    fail='Cannot orient slice plane due to an unkown error.'
    dprint, dlevel=0, fail
    return
  endif
  
  x = x/norm(x)


  ;get rotation matrix
  ;keep input data from being mutated to double (for performance)
  matrix = float([[x],[y],[z]])
  
  
  ;Transform particle and support vectors
  if keyword_set(vectors) then vectors = matrix ## temporary(vectors)
  if keyword_set(vbulk) then vbulk = matrix ## vbulk
  if keyword_set(bfield) then bfield = matrix ## bfield
  if keyword_set(sunvec) then sunvec = matrix ## sunvec

end
