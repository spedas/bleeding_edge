;+
; PRO: ADD_BTOT
;
;
;
; PURPOSE: Adds Btot and B_Spin_angle to MagDC structure.
;
; CALLING: add_btot, MagDC
; 	   Pretty simple! 
;                         
; INPUTS: A valid MadDC structure, ie MagDC = get_fa_fields('MagDC, /all).
;       
; KEYWORD PARAMETERS:  	NSMOOTH, set to 0 if you do not want to smooth.
;
; OUTPUTS: Added th MagDC structure.
;
; SIDE EFFECTS: May blow memory.
;
; INITIAL VERSION: REE 96-11-20
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro add_btot, MagDC, nsmooth=nsmooth

; Set up error handling.
catch,err_stat
IF (err_stat ne 0) then BEGIN
    message,!err_string,/continue
    catch,/cancel
    return
ENDIF

; Make sure MagDC is a structure...
IF idl_type(MagDC) ne 'structure' then BEGIN
    message,' Input structure is not a structure!',/continue
    catch,/cancel
    return
ENDIF

; Check that needed tags exsist.
needed_tags = ['comp1', 'comp2', 'comp3']
IF (missing_tags(MagDC,needed_tags) gt 0) then BEGIN
    message,'missing tags!',/continue
    catch,/cancel
    return
ENDIF 

; Set up nsmooth.
if n_elements(nsmooth) eq 0 then nsmooth = 100;

; Make Btot
Btot = sqrt(MagDC.comp1*MagDC.comp1 + MagDC.comp2*MagDC.comp2 + $
            MagDC.comp3*MagDC.comp3)
B_Spin_ang = acos(MagDC.comp3/Btot)


IF (nsmooth gt 1) then BEGIN
    Btot = smooth(Btot,nsmooth)
    B_Spin_ang = smooth(B_Spin_ang,nsmooth)
ENDIF

; Add to structure.
add_str_element, MagDC, 'Btot', Btot
add_str_element, MagDC, 'B_Spin_ang', B_Spin_ang

catch,/cancel
return
end


