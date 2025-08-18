;+
; PROCEDURE:
;     reduce_bfield_dimensions
;
; PURPOSE:
;     This routine reduces a tplot variable with B-field 
;     magnitude (like those found in the MMS FGM files) 
;     to a tplot variable containing only the B-field vector
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-11-19 15:28:17 -0800 (Mon, 19 Nov 2018) $
; $LastChangedRevision: 26152 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/reduce_bfield_dimensions.pro $
;-

pro reduce_bfield_dimensions, tvar, newname=newname, coords=coords
  if undefined(newname) then newname = tvar+'_vec'
  get_data, tvar, data=d, dlimits=dl, limits=l
  if ~undefined(coords) then cotrans_set_coord, dl, coords
  store_data, newname, data={x: d.X, y: [[d.Y[*, 0]], [d.Y[*, 1]], [d.Y[*, 2]]]}, dlimits=dl, limits=l
end