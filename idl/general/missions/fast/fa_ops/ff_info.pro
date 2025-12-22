;+
; FUNCTION: FF_INFO, dqd, talk=talk, pot=pot, notch=notch
;
; PURPOSE: A utility routine which gives default values for FAST FIELDS. 
;          Examples: potential, notching. USER HOSTILE.
;
; INPUT: 
;       dqd -         USUALLY REQUIRED. A string that starts with:
;                     'V5-V8', 'V1-V2', 'V1-V4', 'V5-V6','V7-V8', or 'V1-V58'
;
; KEYWORDS: 
;       talk -        Messages and descriptions appear on the screen. 
;       pot -         Returns information for forming potentials from 
;                     fields data.
;
; CALLING: ff_notch(/pot)
;
; OUTPUT: A structure that depends on the specific information requested.
;
; INITIAL VERSION: REE 97-04-01
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
function ff_info, dqd, talk=talk, pot=pot, notch=notch

;
; POTENTIAL STRUCTURE.
;
IF keyword_set(pot) then BEGIN
    struc = {boom1:   28.3,  $
             boom4:   0.6,  $
             boom5:   28.0, $
             boom8:   28.0, $
             boom14:  28.9,  $
             boom58: 55.692, $
             cal4: 1.379e-3,  $
             cal8: 1.378e-3,  $
             cal14: -2.760,  $
             cal58: 2.7645, $
             weight1: 0.100722,  $
             weight5: 0.449639,  $
             weight8: 0.449639 }
    
    return, struc
ENDIF

; 
; NOTCH STRUCTURE
;
IF keyword_set(notch) then BEGIN
    struc = -1
    good_dqd = 0
    name = strlowcase(dqd)
    if (strmid(name,0,5) eq 'v5-v8')  then good_dqd='v58'
    if (strmid(name,0,3) eq 'v58')    then good_dqd='v58'
    if (strmid(name,0,5) eq 'v1-v2')  then good_dqd='v12'
    if (strmid(name,0,3) eq 'v12')    then good_dqd='v12'
    if (strmid(name,0,5) eq 'v1-v4')  then good_dqd='v14'
    if (strmid(name,0,5) eq 'v14')    then good_dqd='v14'
    if (strmid(name,0,6) eq 'v1-v58') then good_dqd='v158'
    if (strmid(name,0,4) eq 'v158')   then good_dqd='v158'
    if (strmid(name,0,3) eq 'ne2')    then good_dqd='ne2'
    if (strmid(name,0,3) eq 'ne3')    then good_dqd='ne3'
    if (strmid(name,0,3) eq 'ne6')    then good_dqd='ne6'
    if (strmid(name,0,3) eq 'ne7')    then good_dqd='ne7'
    if (strmid(name,0,3) eq 'ne9')    then good_dqd='ne9'
    if (strmid(name,0,3) eq 'ne10')   then good_dqd='ne10'
    ; blah, blah, blah ...

    IF data_type(good_dqd) ne 7 then BEGIN
        print, "FF_INFO: STOPPED!"
        print, "Dqd name not recognized."
        return, -1
    ENDIF

    ; SET UP AND RETURN APROPRIATE DATA
    
    CASE good_dqd OF

        'v58': BEGIN
        struc = {mag_strt: [330,150], sun_strt: [330,150], mag_ang: 308, $
                 mag_stop: [385,205], sun_stop: [385,205], sun_ang: 210}
        END

        'v14': BEGIN
        struc = {mag_strt: [330,150], sun_strt: [330,150], mag_ang: 218, $
                 mag_stop: [385,205], sun_stop: [385,205], sun_ang: 120}
        END

        'v12': BEGIN
        struc = {mag_strt: [330,150], sun_strt: [330,150], mag_ang: 218, $
                 mag_stop: [385,205], sun_stop: [385,205], sun_ang: 120}
        END

        'v158': BEGIN
        struc = {mag_strt: [ 70,160,250,340], sun_strt: [ 70,160,250,340], $
                 mag_stop: [110,200,290,380], sun_stop: [110,200,290,380], $
                 mag_ang: 218, sun_ang: 120} 
        END

        'ne2': BEGIN
        struc = {mag_strt: [120,300], sun_strt: [120,300], $
                 mag_stop: [240,420], sun_stop: [240,420], $
                 mag_ang: 218, sun_ang: 120} 
        END

        'ne3': BEGIN
        struc = {mag_strt: [120,300], sun_strt: [120,300], $
                 mag_stop: [240,420], sun_stop: [240,420], $
                 mag_ang:  38, sun_ang: 300} 
        END

        'ne6': BEGIN
        struc = {mag_strt: [120,300], sun_strt: [120,300], $
                 mag_stop: [240,420], sun_stop: [240,420], $
                 mag_ang: 314, sun_ang: 210} 
        END

        'ne7': BEGIN
        struc = {mag_strt: [120,300], sun_strt: [120,300], $
                 mag_stop: [240,420], sun_stop: [240,420], $
                 mag_ang: 122, sun_ang:  30} 
        END

        'ne9': BEGIN
        struc = {mag_strt: 0, sun_strt: 0, $
                 mag_stop: 0, sun_stop: 0, $
                 mag_ang: 0, sun_ang: 0} 
        END

        'ne10': BEGIN
        struc = {mag_strt: 0, sun_strt: 0, $
                 mag_stop: 0, sun_stop: 0, $
                 mag_ang: 0, sun_ang: 0} 
        END

    ENDCASE

    return,struc

ENDIF

END
