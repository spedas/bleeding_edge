; Diagnostic utility for evaluating spin model performance.
;
; Input: one or two tplot variable names
; Output: A new tplot variable (specified by output keyword)
; Units: Default to radians, convert to degrees with /degrees keyword.
; 
; Input data is assumed to be in DSL coordinates.  If
; two variables are passed, they are assumed to have the
; identical sample count and time tags. No checks are 
; performed...use with caution!
;
; For the one-argument case: output will be the angle between
; the DSL-X axis and each sample vector (after projecting onto
; the spin plane). The angles will be in the interval [0,360) 
; degrees (or equivalent in radians)
;
; For the two-argument case: both arguments are projected onto
; the spin plane, and the output is the angle between the two
; projected vectors.  The result will be in the interval [0, 180]
; degrees (or equivalent in radians).


pro spinplane_angle,v1, v2, output=output, degrees=degrees

; Unit conversion factor

if keyword_set(degrees) then begin
  convert=180.0D/!DPI
endif else begin
  convert=1.0D
endelse

; Get data for first variable
get_data,v1,data=d1
; Project it into the spin plane
proj1=d1.y[*,0:1]

if n_elements(v2) GT 0 then begin
   ; If a second positional argument is present, calculate the
   ; angle between the two sets of vectors after projecting them
   ; onto the spin plane.
   get_data,v2,data=d2
   len1=sqrt(total(proj1*proj1,2))  ; vector lengths for first arg
   proj2=d2.y[*,0:1]
   len2=sqrt(total(proj2*proj2,2))  ; vector lengths for second arg
   dot=total(proj1*proj2,2)         ; 2-d dot product
   costheta=dot/(len1*len2)         ; obtain cos(angle) from dot product
   a=where(costheta LT -1.0D,count)    ; clamp costheta range to [-1, 1]
   if (count GT 0) then costheta[a]=-1.0D
   a=where(costheta GT 1.0D,count)
   if (count GT 0) then costheta[a]=1.0D
   angle=acos(costheta)*convert     ; unit conversion
endif else begin
   ; If only one argument is given, project the vectors onto the spin
   ; plane and return the angles measured from the X axis (in the range
   ; [0, 360) degrees).
   angle=atan(proj1[*,1],proj1[*,0])*convert
endelse

; Shift output range to [0, 360) degrees (or radians equivalent)

a=where(angle LT 0.0D,count)
if (count GT 0 ) then begin
    angle[a] = angle[a] + convert*2.0D*!DPI
endif

; Store result in new tplot variable

store_data,output,data={x:d1.x, y:angle}
end
