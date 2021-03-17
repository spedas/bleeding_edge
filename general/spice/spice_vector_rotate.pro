;+
;Function: SPICE_VECTOR_ROTATE
;Purpose:  Rotate a vector from one frame to another frame
;Usage:   vector_prime = spice_vector_rotate(vector,ut,from_frame,to_frame, check_objects='Frame')
;Inputs:    VECTOR:  3xN array
;           UT:        N array of unix times
;           FROM_FRAME:  String or id - valid SPICE FRAME
;           TO_FRAME:    string or id - valid SPICE FRAME
;Output:    VECTOR_PRIME:  3xN array - vector as measured in the TO_FRAME
;  Note: time is in the last dimension  (not like tplot storage)
; 
; Author: Davin Larson  
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-16 13:35:32 -0800 (Wed, 16 Dec 2020) $
; $LastChangedRevision: 29517 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_vector_rotate.pro $
;-

function spice_vector_rotate,vector,utc,et=et,from_frame,to_frame,check_objects=check_objects,verbose=verbose,qrot=qrot,force_objects=force_objects

test=0
if keyword_set(test) then begin
  dprint,'Running test rotate matrix routine'
  ut = time_double(utc)
  et = time_ephemeris(ut,/ut2et)
  dprint,'Getting rotation matrices'
  rotmat = spice_body_att(from_frame,to_frame,ut,check_object=check_objects,force_objects=force_objects,verbose=verbose) 
  dprint,'Rotating vectors'
  vector_prime = vector*!values.f_nan
  for i=0,n_elements(ut)-1 do begin        ;  This might not  work for a single vector
    vector_prime[*,i] = rotmat[*,*,i] ## vector[*,i]
  endfor
  dprint,'Done'
  return,vector_prime
endif


if ~keyword_set(qrot) then begin    ;  shortcut if qrot is known  - Be careful when using this shortcut!!!
  ut = time_double(utc)
  et = time_ephemeris(ut,/ut2et)
  dprint,dlevel=3,verbose=verbose,'Obtaining rotation quaternion(s)'
  qrot =  spice_body_att(from_frame,to_frame,ut,/quaternion,check_object=check_objects,force_objects=force_objects,verbose=verbose) 
endif else begin
  dprint,'Warning: Using previous version of qrot'
endelse
dprint,dlevel=3,verbose=verbose,'Start Vector Rotations'
vector_prime = quaternion_rotation(vector,qrot,/last_ind)     
dprint,dlevel=3,verbose=verbose,'Done with Rotations'
return,vector_prime
end


