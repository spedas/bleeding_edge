;+
;Function: qvalidate,q,argname,fxname
;
;Purpose: validate inputs for the idl quaternion library
;
;Inputs: q: a 4 element array, or an Nx4 element array, representing quaternion(s)
;        argname: the name of the argument to be used in error messages
;
;Returns: an Nx4 array or -1, it will turn 4 element quaternion arrays
;         into 1x4 element quaternion arrays
;
;Notes: This function is here because I noticed a lot of the error
;checking code was being repeated, and it was making the functions
;long and hard to read
;
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/quaternion/qvalidate.pro $
;-

function qvalidate,q,argname,fxname

compile_opt idl2

;this is to avoid mutating the input variable
qi=q

if(size(/n_dim,qi) eq 0 && qi[0] eq -1) then return,-1 $ 
;check to make sure input has the correct dimensions
else if(size(/n_dim,qi) eq 1) then begin

   if(n_elements(qi) ne 4) then begin
      dprint,'Wrong number of elements in quaternion ' + argname + '. Found when validating input for ' + fxname
      return,-1
   endif

   qi = reform(qi,1,4)
endif else if(size(/n_dim,qi) eq 2) then begin

   s = size(qi,/dimensions)

   if(s[n_elements(s)-1] ne 4) then begin
      dprint,'Dimension 2 of quaternion ' +argname+' must have 4 elements. Found when validating input for ' + fxname
      return,-1
   endif

endif else begin
   dprint,'Quaternion '+argname+' has the wrong number of dimensions. Found when validating input for ' + fxname 
   return,-1
endelse

return, qi

end
