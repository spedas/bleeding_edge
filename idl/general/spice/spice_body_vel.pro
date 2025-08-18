;+
;Function: SPICE_BODY_POS
;
;Purpose:  Returns the velocity of an object relative to an observer.
; This is a wrapper to the cspice routine:  CSPICE_SPKEZR   
;Keywords:
;  check_objects: frame or body name that the routine will check for valid times to prevent crashing.
;
; Author: Davin Larson  
; $LastChangedBy: ali $
; $LastChangedDate: 2020-08-18 18:37:05 -0700 (Tue, 18 Aug 2020) $
; $LastChangedRevision: 29046 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_body_vel.pro $
;-

function spice_body_vel,body_name,obs_name,utc=utc,et=et,frame=frame,ltime=ltime,abcorr=abcorr,check_objects=check_objects,force_objects=force_objects,pos=pos

on_error,2
if not keyword_set(frame) then frame = 'ECLIPJ2000'
if not keyword_set(abcorr) then abcorr = 'NONE'
if n_elements(utc) gt 0 then ut = time_double(utc)
if n_elements(et) eq 0 then et = time_ephemeris(ut,/ut2et)

ns = n_elements(et)
if keyword_set(check_objects) then begin
  time_valid = spice_valid_times(et,object=check_objects,force_objects=force_objects) 
;  printdat,check_objects,time_valid
  ind = where(time_valid ne 0,nind)
  dprint,dlevel=2,verbose=verbose,nind,' Valid times from:',check_objects
endif else begin
 ; nind = ns
  ind = lindgen((nind = ns))
endelse

pos = replicate(!values.d_nan,3,ns)
vel = replicate(!values.d_nan,3,ns)
if arg_present(ltime)  then ltime = replicate(!values.d_nan,ns)
if nind ne 0 then begin
;    cspice_spkpos,body_name,et[ind],frame,abcorr,obs_name, pos2, ltime2
;    pos[*,ind] = pos2
     cspice_spkezr,body_name,et[ind],frame,abcorr,obs_name, pos2vel, ltime2
     pos[*,ind] = pos2vel[0:2,*]
     vel[*,ind] = pos2vel[3:5,*]
     if keyword_set(ltime) then ltime[ind] = ltime2 
endif else dprint,'No Valid SPK frame for: ',check_objects
return,vel
end

