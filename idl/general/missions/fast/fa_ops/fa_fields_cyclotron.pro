;+
;PROCEDURE:   FA_FIELDS_CYCLOTRON, mag, filt=filt, t1=t1, t2=t2
;		       
;PURPOSE:   Stores as tplot arrays:
;		(1) electron cyclotron frequency 	FCE
;		(2) H+ cyclotron frequency 		FCH
;		(3) He+ cyclotron frequency 		FCHe
;		(4) O+ cyclotron frequency 		FCO
;		(5) |B|					B_abs
;		(6) B to Spin plane angle		B_SP_ang
; 
;INPUT:   
;	mag - NOT NEEDED. PROGRAM WILL GET IF NOT SUPPLIED.
;             Fast DQD = 'MagDC' 
;
; KEYWORDS: 
;       filt    - Filter frequency in Hz. DEFAULT = 0.1
;       t1      - Begin time.
;       t2      - End time.
;
; USE: fa_fields_cyclotron
;
; ASSUMPTIONS: 
;;
;CREATED BY:	REE, 97-05-13
;FILE:  fa_fields_cyclotron.pro
;VERSION:  0.0
;LAST MODIFICATION:  
;-
pro fa_fields_cyclotron, mag, filt=filt, t1=t1, t2=t2

two_pi    = !dpi*2.d
; Set up error handling.
catch,err_stat
IF (err_stat ne 0) then BEGIN
    message,!err_string,/continue
    catch,/cancel
    return
ENDIF

; Make sure mag is a structure...
IF idl_type(mag) ne 'structure' then BEGIN
    if (n_elements(t1) gt 0) or (n_elements(t2) gt 0) then $
        mag = get_fa_fields('MagDC', t1, t2, /rep ) $
        else mag = get_fa_fields('MagDC', /all, /rep)
    IF mag.valid ne 1 then BEGIN
        message,' Input not valid! Check SDT setup - need MagDC.',/continue
        catch,/cancel
        return
    ENDIF
ENDIF

; Check that needed tags exsist.
needed_tags = ['comp1', 'comp2', 'comp3']
IF (missing_tags(mag,needed_tags) gt 0) then BEGIN
    message,'missing tags!',/continue
    catch,/cancel
    return
ENDIF 

; Make Babs
B_abs = sqrt(mag.comp1*mag.comp1 + mag.comp2*mag.comp2 + $
            mag.comp3*mag.comp3)
B_SP_ang = asin(mag.comp3/B_abs) * 360.d  / two_pi


; Smooth the data.
if n_elements(filt) ne 1 then filt = 0.1
IF (filt gt 0) then BEGIN
    dat = {time: mag.time, comp1: B_abs, comp2: B_SP_ang}
    fa_fields_filter,dat,[0.0,filt], /rec
    B_abs    = dat.comp1
    B_SP_ang = dat.comp2
    dat = 0
ENDIF

; Set up constants.
me        = 0.910956e-30
e         = 1.602192e-19
mh        = 1.672610e-27
mhe       = 6.681694e-27
mo        = 2.654554e-26

; Correct time for recursive filter.
time = mag.time
if (filt gt 0) then time = time - 2.d/(filt*two_pi)

data   = {x:time, y:B_abs*e*1.e-12/me/two_pi }
store_data,'FCE', data=data
options,'FCE','color',255

data   = {x:time, y:B_abs*e*1.e-12/mh/two_pi }
store_data,'FCH', data=data
options,'FCH','color',255

data   = {x:time, y:B_abs*e*2.e-12/mh/two_pi }
store_data,'FCH2', data=data
options,'FCH2','color',255

data   = {x:time, y:B_abs*e*3.e-12/mh/two_pi }
store_data,'FCH3', data=data
options,'FCH3','color',255

data   = {x:time, y:B_abs*e*4.e-12/mh/two_pi }
store_data,'FCH4', data=data
options,'FCH4','color',255

data   = {x:time, y:B_abs*e*1.e-12/mhe/two_pi }
store_data,'FCHe', data=data
options,'FCHe','color',255

data   = {x:time, y:B_abs*e*1.e-12/mo/two_pi }
store_data,'FCO', data=data
options,'FCO','color',255

data   = {x:time, y:B_abs }
store_data,'B_abs', data=data

data   = {x:time, y:B_SP_ang }
store_data,'B_SP_ang', data=data

message, /info, $
  'FCE, FCH, FCHe, FCO (kHz), B_abs (nT), B_SP_ang (degrees) in tplot.'

return

END
