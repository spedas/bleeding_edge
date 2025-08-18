;+
; NAME:
;    CORRECT_DELTA_PHI_TENSOR.PRO
;
; PURPOSE:  
;    Apply eclipse delta_phi corrections to L1 MOM tensor quantities.
;
; CATEGORY: 
;   TDAS
;
; CALLING SEQUENCE:
;    correct_delta_phi_tensor, tens=mflux, delta_phi=delta_phi
;
;  INPUTS:
;
;  OUTPUTS:
;
;  KEYWORDS:
;     tens: An Nx6 input array representing the xx,yy,zz,xy,xz,yz
;         components of a 3x3 matrix.  (The other three elements
;         are implied by symmetry.)  The data is modified in place.
;     delta_phi: An array of delta_phi correction values, in degrees.
;         The sample counts of tens and delta_phi must match.
;    
;  PROCEDURE:
;
;     For each sample: construct a 3-d rotation matrix corresponding
;     to a delta_phi degree counterclockwise rotation about the
;     DSL-Z axis.  Construct a 3x3 matrix from the 6-element tensor
;     sample.  Apply the rotation by performing matrix multiplication:
;     transpose(rotation) # tensor # rotation
;     Then strip the redundant terms of the result, yielding a
;     modified 6-element representation of the original tensor.
;
;  EXAMPLE:
;
;-


pro correct_delta_phi_tensor,tens=tens, delta_phi=delta_phi

cs=cos(delta_phi*!DPI/180.0D)
sn=sin(delta_phi*!DPI/180.0D)

; map3x3 is a set of indices to convert a 6-element tensor representation to 
; a 3x3 matrix, using symmetry to fill in the three "missing" elements. 
; mapt represents the inverse operation from 3x3 back to 6 elements.

map3x3 = [[0,3,4],[3,1,5],[4,5,2]]
mapt   = [0,4,8,1,2,5]
n = n_elements(tens)/6
; Loop over each sample
for i=0L,n-1 do begin   ; this could easily be speeded up, but it's fast enough now.
    ; Create a column-major rotation matrix using this delta_phi sample
    rot = [[cs[i], sn[i], 0D], [-sn[i], cs[i], 0D], [0D, 0D, 1D]]
    ; Convert the 6-element tensor to a 3x3 matrix
    tens3x3 = reform(tens[i,map3x3],3,3)
    ; Apply the rotation
    ;
    ;
    ;tens3x3_rotated = transpose(rot) # (tens3x3 # rot)
    ; JWL 01/03/2013
    ; The above line made the sinusoidal behavior of the tensor quantities
    ; worse, rather than better, in the eclipse-corrected onboard moments.
    ; The sense of the rotation must have been incorrect in the original
    ; code.  Swapping the transposed and original rotation matrices
    ; in the tensor rotation formula seems to have fixed it, and
    ; also matches the eclipse-corrected ground-computed moments better. 

    tens3x3_rotated = rot # (tens3x3 # transpose(rot))
    ; Convert back to the 6-element representation
    tens[i,*] = tens3x3_rotated[mapt]
endfor
end
