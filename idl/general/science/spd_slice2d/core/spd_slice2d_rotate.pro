;+
;Procedure:
;  spd_slice2d_rotate
;
;Purpose:
;  Helper function for spd_slice2d.
;  Performs transformation to coordinates specified by ROTATION option.
;  This is done after the CUSTOM_ROTATION is applied.
;
;
;Input:
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
;$LastChangedBy: egrimes $
;$LastChangedDate: 2022-03-08 13:25:16 -0800 (Tue, 08 Mar 2022) $
;$LastChangedRevision: 30661 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_rotate.pro $
;
;-
pro spd_slice2d_rotate, rotation=rotation, $
               vectors=vectors, bfield=bfield, vbulk=vbulk, sunvec=sunvec, $
               matrix=matrix, $
               fail=fail, perp_vbulk=perp_vbulk

    compile_opt idl2, hidden


  ; Check for presense of required support data
  req_bfield = in_set( strlowcase(rotation), ['bv','be','perp','perp2','perp_xy','perp_xz','perp_yz', 'b_exb', 'perp1-perp2'] )
  req_vbulk = in_set( strlowcase(rotation), ['bv','be','xvel','perp','perp2', 'b_exb', 'perp1-perp2'] )

  if n_elements(bfield) ne 3 && req_bfield then begin
    fail = ~undefined(bfield) ? 'Invalid magnetic field data provided' : $
           '"'+rotation+'" rotation requires magnetic field data; use MAG_DATA keyword to specify vector or tplot variable'
    dprint, dlevel=1, fail
    return
  endif

  if n_elements(vbulk) ne 3 && req_vbulk then begin
    fail = ~undefined(vbulk) ? 'Invalid bulk velocity provided' : $ 
           '"'+rotation+'" rotation requires bulk velocity data; use VEL_DATA keyword to specify vector or tplot variable'
    dprint, dlevel=1, fail
    return
  endif

  ; Create/get rotation matrix
  case strlowcase(rotation) of
    'bv': matrix=spd_cal_rot(bfield,vbulk)
    'be': matrix=spd_cal_rot(bfield,crossp(bfield,vbulk)) ; [B, BxV] (this is the parallel - perp 2 plane)
    'xy': matrix=spd_cal_rot([1,0,0],[0,1,0])
    'xz': matrix=spd_cal_rot([1,0,0],[0,0,1])
    'yz': matrix=spd_cal_rot([0,1,0],[0,0,1])
    'xvel': matrix=spd_cal_rot([1,0,0],vbulk)
    'perp': matrix=spd_cal_rot(crossp(crossp(bfield,vbulk),bfield),crossp(bfield,vbulk)) ; perp 2 - perp 1 plane; should be: [(BxV)xB, BxV]
    'perp1-perp2': matrix=spd_cal_rot(crossp(bfield,vbulk), crossp(crossp(bfield,vbulk),bfield)) ; perp 1 - perp 2 plane; should be: [BxV, (BxV)xB]
    ;'perp2': matrix=spd_cal_rot(crossp(-crossp(vbulk, bfield),bfield),crossp(vbulk, bfield)) ; [(-VxB)xB, VxB] from some testing, keeping it here for now in case I need to get back to it
    'perp_yz': matrix=spd_cal_rot(crossp(crossp(bfield,[0,1,0]),bfield),crossp(crossp(bfield,[0,0,1]),bfield))
    'perp_xy': matrix=spd_cal_rot(crossp(crossp(bfield,[1,0,0]),bfield),crossp(crossp(bfield,[0,1,0]),bfield))
    'perp_xz': matrix=spd_cal_rot(crossp(crossp(bfield,[1,0,0]),bfield),crossp(crossp(bfield,[0,0,1]),bfield))
    'b_exb': matrix=spd_cal_rot(bfield,crossp(crossp(bfield, vbulk), bfield)) ; [B, (BxV)xB] (this is the parallel - perp 2 plane)
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
  if ~undefined(vectors) then vectors = matrix ## temporary(vectors)
  if n_elements(vbulk) eq 3 then vbulk = matrix ## vbulk
  if n_elements(perp_vbulk) eq 3 then perp_vbulk = matrix ## perp_vbulk
  if n_elements(bfield) eq 3 then bfield = matrix ## bfield
  if n_elements(sunvec) eq 3 then sunvec = matrix ## sunvec

end
