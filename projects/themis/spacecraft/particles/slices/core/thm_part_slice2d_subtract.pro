;+
;Procedure:
;  thm_part_slice2d_subtract
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Subtracts bulk velocity vector from velocity array.
;
;
;Input:
;  vectors: (float) N x 3 array of particle vectors
;  vbulk: (float) bulk velocity 3-vector
;  vel_data: (string) name of tplot variable containing bulk velocity data 
;
;
;Output:
;  none, modifies vectors
;
;
;Notes:
;  This shift should NOT be applied when using the geometric method.
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_subtract.pro $
;
;-

; Helper Function
; Subtracts bulk velocity vector from vectors array
; todo: fix for geo
pro thm_part_slice2d_subtract, vectors=vectors, vbulk=vbulk, vel_data=vel_data

    compile_opt idl2, hidden

  if keyword_set(vel_data) then begin
    dprint, dlevel=4,'Velocity used for subtraction is '+vel_data
  endif else begin
    dprint, dlevel=4, 'Velocity used for subtraction is V_3D'
  endelse

  vectors[*,0] = vectors[*,0] - vbulk[0]
  vectors[*,1] = vectors[*,1] - vbulk[1]
  vectors[*,2] = vectors[*,2] - vbulk[2]
  

end