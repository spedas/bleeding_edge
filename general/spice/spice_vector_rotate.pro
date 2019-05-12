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
; $LastChangedDate: 2019-05-11 00:00:35 -0700 (Sat, 11 May 2019) $
; $LastChangedRevision: 27221 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spice/spice_vector_rotate.pro $
;-

function spice_vector_rotate,vector,utc,et=et,from_frame,to_frame,check_objects=check_objects,verbose=verbose,qrot=qrot,force_objects=force_objects

if ~keyword_set(qrot) then begin    ;  shortcut if qrot is known  - Be careful when using this shortcut!!!
  ut = time_double(utc)
  et = time_ephemeris(ut,/ut2et)
  dprint,dlevel=3,verbose=verbose,'Obtaining rotation quaternion(s)'
  qrot =  spice_body_att(from_frame,to_frame,ut,/quaternion,check_object=check_objects,force_objects=force_objects,verbose=verbose) 
endif
dprint,dlevel=3,verbose=verbose,'Start Vector Rotations'
vector_prime = quaternion_rotation(vector,qrot,/last_ind)     
dprint,dlevel=3,verbose=verbose,'Done with Rotations'
return,vector_prime
end


