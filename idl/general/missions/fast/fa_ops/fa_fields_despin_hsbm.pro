;+
; PROCEDURE: FA_FIELDS_DESPIN_HSBM, hsbm, phase=phase
;       
;
; PURPOSE: A high level routine which produces despun DC efield
;          data from sdt HSBM data in SDT.  This routine can also
;          project three-dimensional HSBM data into a field-aligned
;          coordinate system.
;
; INPUT: 
;       hsbm -        REQUIRED. 
;
; KEYWORDS: 
;       phase -       REQUIRED
;       three_d, if set, then B_ANG is used to take the axial and
;       despun spin plane fields into a field-aligned coordinate
;       system.
;
;       b_ang, float, angle between spin plane and local magnetic field,
;       degrees.
;
; CALLING: fa_fields_despin_hsbm, hsbm, phase=phase
;
;
; OUTPUT: Dat is IDL fields time series data structure with multiple
;         components. This  
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-05-23
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
;
; v. 1.1 John Bonnell, UCBSSL, February 26, 2001.
; fixed error in THREE_D transformation code 
; (old version overwrote one spin plane component before it could be
; used in both transformation equations).
;
;-
pro fa_fields_despin_hsbm, hsbm, phase=phase, three_d=three_d, b_ang=b_ang

; Set up constants.
two_pi = 2.d*!dpi

;
; Begin the combine process. Do not add to structure. Save some space.
; 

; Check to see if phases are needed.
fa_fields_combine, hsbm, phase, result=Bphase, /interp, delt=1000.

;
; DO THE DESPIN
;

dphi = 2.d*!dpi*52.d/360.d
e1 = -hsbm.comp2*cos(Bphase-dphi) - hsbm.comp1*sin(Bphase-dphi)
e2 = -hsbm.comp2*sin(Bphase-dphi) + hsbm.comp1*cos(Bphase-dphi)

; DO 3D DESPIN IF DESIRED
IF keyword_set(three_d) and keyword_set(b_ang) then BEGIN
;    e1 = e1*cos(b_ang(0)) - hsbm.comp4*sin(b_ang(0))
	ez = e1*cos( b_ang[ 0]) - hsbm.comp4*sin( b_ang[ 0])
    e3 = cos(b_ang(0))*hsbm.comp4  + sin(b_ang(0))*e1
	e1 = ez

    data = {x:hsbm.time, y:e3}
    store_data,'E_AXIAL_HSBM', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-300.,300.],  $
          ytitle:'E AXIAL!C!C(mV/m)',$
          panel_size:3}
    store_data,'E_AXIAL_HSBM', dlimit=dlimit
ENDIF

 

; STORE THE DATA IN TPLOT FORMAT
data = {x:hsbm.time, y:e1}
store_data,'E_NEAR_B_HSBM', data=data
dlimit = {spec:0, ystyle:1, yrange:[-300.,300.],  $
          ytitle:'E NEAR B!C!C(mV/m)',$
          panel_size:3}
store_data,'E_NEAR_B_HSBM', dlimit=dlimit

data = {x:hsbm.time, y:e2}
store_data,'E_PERP_HSBM', data=data
dlimit = {spec:0, ystyle:1, yrange:[-300.,300.],  $
          ytitle:'E PERP (SP)!C!C(mV/m)',$
          panel_size:3}
store_data,'E_PERP_HSBM', dlimit=dlimit

if keyword_set(three_d) and keyword_set(b_ang) then  $
    tplot,['E_NEAR_B_HSBM','E_PERP_HSBM', 'E_AXIAL_HSBM'] else $
    tplot,['E_NEAR_B_HSBM','E_PERP_HSBM']

return
end



