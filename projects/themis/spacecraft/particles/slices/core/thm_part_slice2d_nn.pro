

;+
; 
; Name: thm_part_slice2d_2di.pro
; 
; Purpose:  Helper function for thm_part_slice2d.pro
;           Produces slice using nearest neighbor interpolation.
;
;-
pro thm_part_slice2d_nn, datapoints, velocities, resolution, slice_orient, $
                            part_slice=part_slice, $
                            xgrid=xgrid, ygrid=ygrid, $
                            slice_width=slice_width, $
                            shift=shift, $
                            fail=fail

    compile_opt idl2, hidden


  ; Get slice orienation vectors
  thm_part_slice2d_orientslice, slice_orient, fail=fail, $
                                displacement = displacement, $
                                norm = norm, xvec = xvec
  if keyword_set(fail) then return

  ; Copy to prevent mutation
  shiftcopy = shift

  ; Center of distribution
  center = ( [0,0,1] * displacement)

  ; Create square grid
  velmm = [ [minmax(velocities[*,0])], [minmax(velocities[*,1])], [minmax(velocities[*,1])] ]
  xgrid = interpol(velmm[*,0], resolution)
  ygrid = interpol(velmm[*,1], resolution)

  ; Extract slice from scattered points 
  part_slice = thm_part_slice_extract(datapoints, velocities, resolution, $
                                    center, norm, xvec, slice_width=slice_width, $
                                    xgrid=xgrid, ygrid=ygrid, shift=shiftcopy, $
                                    fail=fail)
  if keyword_set(fail) then return
  
end

