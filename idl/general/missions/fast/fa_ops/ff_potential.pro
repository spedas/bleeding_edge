;+
; FUNCTION: FF_POTENTIAL, V58, V8, V14, V4, save_mem=save_mem
;       
;
; PURPOSE: 
; Estimate spacecraft floating potential using spin plane
; spin plane electric field data and potential differences.
;
; INPUT: 
;       V58 -         If blank, program will get V5-V8_S /all,/rep. 
;                     To run this program on burst data, use 
;                     V58=get_fa_fields('V5-V8_4k',/all).
;       V8 -          If blank, program will get V8_S /all,/rep. User can
;                     supply structure if wanted. 
;       V14 -         If blank, program will get V1-V4_S, /all,/rep. 
;                     To run this program on burst data, use 
;                     V58=get_fa_fields('V1-V4_4k',/all).
;       V4 -          If blank, program will get V4_S /all, /rep. User can
;                     supply structure if wanted. 
;
; KEYWORDS: 
;       save_mem      CAREFUL! If set, this will blow away V58, V14, V8,
;                     and V4 after they are no longer needed. 
;
; CALLING: pot = fa_potential()
;       That's easy! Now you the S/C potential.
;
; IMPORTANT! SDT SETUP: Need to have: V5-V8_S, V1-V4_S, V4_S, and V8_S. 
;
; OUTPUT: pot is IDL fields time series data structure with one
;         component. 
;
; SIDE EFFECTS: As with all fields pro's this pro need lots of memory.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
function ff_potential, V58, V8, V14, V4, save_mem=save_mem

; First set up V58.
IF not keyword_set(V58) then BEGIN
    V58 = get_fa_fields('V5-V8_S',/all,/repair)
    IF V58.valid ne 1 then BEGIN
        message, /info, "Cannot get V5-V8_S. Check SDT setup."
        return, -1
    ENDIF
ENDIF

; Next set up V8.
IF not keyword_set(V8) then BEGIN
    V8 = get_fa_fields('V8_S',/all,/repair)
    IF V8.valid ne 1 then BEGIN
        message, /info, "Cannot get V8_S. Check SDT setup."
        return, -1
    ENDIF
ENDIF

; Next set up V14.
IF not keyword_set(V14) then BEGIN
    V14 = get_fa_fields('V1-V4_S',/all,/repair)
    IF V14.valid ne 1 then BEGIN
        message, /info, "Cannot get V1-V4_S. Check SDT setup."
        return, -1
    ENDIF
ENDIF

; Next set up V4.
IF not keyword_set(V4) then BEGIN
    V4 = get_fa_fields('V4_S',/all,/repair)
    IF V4.valid ne 1 then BEGIN
        message, /info, "Cannot get V4_S. Check SDT setup."
        return, -1
    ENDIF
ENDIF

;
; COMBINE THE DATA TO MATCH THE V58 TIME ARRAY.
; 
fa_fields_combine, V58,V8, result=v8_dat,  /interp, delt=5.0
if keyword_set(save_mem) then v8 = 0
fa_fields_combine, V58,V14,result=v14_dat, /svy
if keyword_set(save_mem) then v14 = 0
fa_fields_combine, V58,V4, result=v4_dat,  /interp, delt=5.0
if keyword_set(save_mem) then v4 = 0

;
; DETERMINE THE ZERO LEVEL AND RATIO AND ADJUST DATA. 
;

pot_info = ff_info(/pot)

;
; CALCULATE V1
;
v14_to_volts = abs(pot_info.cal4 * pot_info.boom14 * 2.0 / pot_info.cal14)
v1_dat = v14_dat * v14_to_volts + v4_dat
v14_dat = 0
v4_dat = 0

;
; CALCULATE V5
;
v58_to_volts = abs(pot_info.cal8 * pot_info.boom58 * 2.0 / pot_info.cal58)
v5_dat = v58.comp1 * v58_to_volts + v8_dat

;
; COMBINE
;
pot_dat = -float(v1_dat*pot_info.weight1 + $
                 v5_dat*pot_info.weight5 + v8_dat*pot_info.weight8)

v1_dat = 0
v5_dat = 0

;
; MAKE STRUCTURE
;

pot =                 { data_name:		'SC_POTENTIAL',  $
                        valid:			1l, 		 $
                        project_name:		'FAST', 	 $
                        units_name:		'Volts', 	 $
                        calibrated:		1l, 		 $
                        start_time:		v58.start_time,  $
                        end_time:		v58.end_time,    $
                        npts:			v58.npts, 	 $
                        ncomp:			1l, 		 $
                        depth:			1l,		 $
                        time:			v58.time,	 $
                        notch:			v58.notch,	 $
                        comp1:			pot_dat,         $
                        header_bytes:		bytarr(1) }
pot.notch = finite(pot_dat)
if keyword_set(save_mem) then v58 = 0

return, pot

end
