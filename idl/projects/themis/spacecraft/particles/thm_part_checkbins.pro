
;+
;Procedure:
;  thm_part_checkbins
;
;Purpose:
;  Checks if two particle distribution structures have identical
;  energy, phi, theta, and mass values.
;
;Input:
;  dist1: 3D particle data structure
;  dist2: 3D particle data structure
;  
;Output:
;  return value: (bool) 1 if all fields match, 0 otherwise
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-11-07 18:26:20 -0800 (Fri, 07 Nov 2014) $
;$LastChangedRevision: 16155 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_checkbins.pro $
;
;-
function thm_part_checkbins, dist1, dist2

    compile_opt idl2, hidden

  if undefined(dist2) then return, 1b
  
  if ~array_equal(dist1.phi, dist2.phi)  ||  $
     ~array_equal(dist1.theta, dist2.theta) ||  $
     ~array_equal(dist1.energy, dist2.energy)  ||  $
     dist1.mass ne dist2.mass  $ ;return error for this case?
  then begin
    return, 0b
  endif
  
  return, 1b

end
