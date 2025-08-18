;+
;Function: spice_body_att
;Purpose:  retrieve the rotation (array or quaternion) to transfer from one frame to another frame
;  This routine is is basically a wroapper for the routine cspice_pxform. cspice_pxform can fail if there are time intervals missing from the kernels.
;  This routine can check for those missing intervals (using the check_objects keyword) and complete the task successfully.
;  Note: time is in the last dimension  (not like tplot storage)
; ;
; Author: Davin Larson  
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-05-16 13:19:05 -0700 (Thu, 16 May 2019) $
; $LastChangedRevision: 27248 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_body_att.pro $
;-

function spice_body_att,from,to,utc,quaternion=quaternion,baserot=baserot,fix_qsign=fix_qsign,rel2start=rel2start,check_objects=check_objects,force_objects=force_objects,verbose=verbose
ut = time_double(utc)
et = time_ephemeris(ut,/ut2et)

ns = n_elements(et)
if keyword_set(check_objects) then begin
  time_valid = spice_valid_times(et,object=check_objects,tol=tol,force_objects=force_objects) 
 ; printdat,check_objects,time_valid
  ind = where(time_valid ne 0,nind)
  dprint,dlevel=2,verbose=verbose,nind,' Valid times from:',check_objects
endif else begin
 ; nind = ns
  ind = lindgen((nind = ns))
endelse

res = replicate(!values.d_nan,3,3,ns)
if nind ne 0 then begin
;     cspice_pxform,spice_bod2s(from),spice_bod2s(to),et[ind],temp    ; 3 element position? (online documentation is misleading)
     dprint,dlevel=3,verbose=verbose,'Starting cspice_pxform for ',nIND, ' time steps'
     cspice_pxform,from,to,et[ind],temp    ; 3 element position? (online documentation is misleading)
     dprint,dlevel=3,verbose=verbose,'Completed cspice_pxform'
 ;    cspice_spkpos,body_name,et[ind],frame,abcorr,obs_name, pos2, ltime2
     res[*,*,ind] = temp
endif else dprint,verbose=verbose,'No Valid CK frame for: ',check_objects


if keyword_set(quaternion) then begin
   dprint,dlevel=3,verbose=verbose,'Calculating Quaternions'
   if keyword_set(rel2start) then baserot = transpose(res[*,*,0])
   res = spice_m2q(res,fix_qsign=fix_qsign,baserot = baserot)
endif
return,res
end


