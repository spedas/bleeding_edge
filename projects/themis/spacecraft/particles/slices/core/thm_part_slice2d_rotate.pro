;+
;Procedure:
;  thm_part_slice2d_rotate
;
;Purpose:
;  Helper function for thm_part_slice2d.
;  Performs transformation from coordinates specified by
;  COORD (thm_part_slice2d) to those specified by 
;  ROTATION (thm_part_slice2d).
;
;
;Input:
;  probe: (string) spacecraft designation (e.g. 'a')
;  coord: (string) target coordinates (e.g. 'phigeo')
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
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_rotate.pro $
;
;-
pro thm_part_slice2d_rotate, rotation=rotation, $
               vectors=vectors, bfield=bfield, vbulk=vbulk, sunvec=sunvec, $
               matrix=matrix, $
               fail=fail

    compile_opt idl2, hidden


  ; Create/get rotation matrix
  case strlowcase(rotation) of
    'bv': matrix=thm_cal_rot(bfield,vbulk)
    'be': matrix=thm_cal_rot(bfield,crossp(bfield,vbulk))
    'xy': matrix=thm_cal_rot([1,0,0],[0,1,0])
    'xz': matrix=thm_cal_rot([1,0,0],[0,0,1])
    'yz': matrix=thm_cal_rot([0,1,0],[0,0,1])
    'xvel': matrix=thm_cal_rot([1,0,0],vbulk)
    'perp': matrix=thm_cal_rot(crossp(crossp(bfield,vbulk),bfield),crossp(bfield,vbulk))
    'perp_yz': matrix=thm_cal_rot(crossp(crossp(bfield,[0,1,0]),bfield),crossp(crossp(bfield,[0,0,1]),bfield))
    'perp_xy': matrix=thm_cal_rot(crossp(crossp(bfield,[1,0,0]),bfield),crossp(crossp(bfield,[0,1,0]),bfield))
    'perp_xz': matrix=thm_cal_rot(crossp(crossp(bfield,[1,0,0]),bfield),crossp(crossp(bfield,[0,0,1]),bfield))
    else: begin
      fail = 'Unrecognized rotation: "'+rotation+'".'
      dprint, dlevel=1, fail
      return
    end
  endcase
  
  ; Check that matrix was formed correctly
  if total( finite(matrix,/nan) ) gt 0 then begin
    fail = 'Cannot form rotation matrix, magnetic field and/or bulk velocity variables may contain NaNs.'
    dprint, dlevel=1, fail
    return
  endif
  
  ; Prevent data from being mutated to doubles
  matrix = float(matrix)

  if rotation ne 'xy' then begin
    dprint, dlevel=4, 'Aligning slice plane to ' +rotation
  endif else return
  
  ;Transform particle and support vectors 
  if keyword_set(vectors) then vectors = matrix ## temporary(vectors)
  if keyword_set(vbulk) then vbulk = matrix ## vbulk
  if keyword_set(bfield) then bfield = matrix ## bfield
  if keyword_set(sunvec) then sunvec = matrix ## sunvec

end
