;+
;FUNCTION: 
; spd_cal_rot(v1,v2)
;
;INPUT: 
; v1: 3 component vector,   
; v2: 3 component vector,
   
;PURPOSE:
; Returns a rotation matrix that rotates v1,v2 to the x-y plane
; v1 is rotated to the x-axis and v2 into the x-y plane
;
;NOTES: 
; Function normally called by "add_df2d.pro" to rotate
; velocities into the plane of Vsw and B
;
;CREATED BY:
; J.McFadden
;
;LAST MODIFICATION:
; 95-9-13   J.McFadden
; 15-9-08   A.Flores - forked
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_cal_rot.pro $
;-
function spd_cal_rot,v1,v2

  compile_opt idl2, hidden

a=v1/(total(v1^2))^.5
d=v2/(total(v2^2))^.5
c=crossp(a,d)
c=c/(total(c^2))^.5
b=-crossp(a,c)
b=b/(total(b^2))^.5

rotinv = dblarr(3,3)
rotinv[0,*] = a
rotinv[1,*] = b
rotinv[2,*] = c

rot = invert(rotinv)
 
return, rot
end


