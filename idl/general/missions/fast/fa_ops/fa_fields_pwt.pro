;+
; PROCEDURE: FA_FIELDS_PWT, pwt, trk, t1=t1, t2=t2, trig_dat=trig_dat
;       
;
; PURPOSE: A high level routine which produces despun SFA
;          data from SFABURST.
;
; INPUT: 
;       pwt -         If blank, program will get "ApId1051" and calibrate. 
;       trk -         If blank, program will get "HfqTrkFrq".
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       trig_dat -    Optional if set, will use 'TRIG_SFATRK'.
;                     NOTE: I DO NOT RECOMMEND USING 'TRIG_SFATRK' UNLESS
;                           'HfqTrkFrq' IS NOT AVAILABLE. DO NOT PUBLISH!
;
; CALLING: fa_fields_pwt
;
; IMPORTANT! SDT SETUP: Need to have: "ApId1051" and "HfqTrkFrq".
;            CAN NOW USE 'TRIG_SFATRK' (SDT: TriggerData/SFATRK)
;
; OUTPUT: Stored in tplot format.
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-07-07
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro fa_fields_pwt, pwt, trk, t1=t1, t2=t2, trig_dat=trig_dat

; GET RAW DATA FROM TRACKER OUTPUT
IF not keyword_set(pwt) then BEGIN
    pwt = get_fa_fields("ApId1051",t1,t2,/rep)
    IF pwt.valid ne 1 then BEGIN
        message, /info, 'Cannot get "ApId1051". Check SDT setup.'
        return
    ENDIF
   pwt.units_name = 'mV/m'
   pwt.calibrated = 1
   pwt.comp1 = pwt.comp1 * 0.08 ; CALIBRATION!
ENDIF

; NEXT SET UP FREQUENCY DATA FROM TRACKER.
delt_t=0.0078
IF not keyword_set(trk) AND not keyword_set(trig_dat) then BEGIN
    trk=get_fa_fields("HfqTrkFrq",t1,t2,/rep)
    IF trk.valid ne 1 then BEGIN
        message, /info, 'Cannot get "HfqTrkFrq". Check SDT setup.'
        return
    ENDIF
ENDIF

; NEXT SET UP FREQUENCY DATA FROM TRACKER.
IF keyword_set(trig_dat) then BEGIN
    trk=get_fa_fields("TRIG_SFATRK",t1,t2,/rep)
    IF trk.valid ne 1 then BEGIN
        message, /info, 'Cannot get "TRIG_SFATRK". Check SDT setup.'
        return
    ENDIF
    print, 'WARNING!!! ' 
    print, 'FREQUENCIES NOT UPDATED OFTEN ENOUGH! '
    print, 'DO NOT PUBLISH!!!' 
    ; CONVERT TO kHz
    trk.comp1 = (9901 - trk.comp1) * 1.04335 + 369.7
    delt_t=10.0
ENDIF

;
; FFT THE PWT DATA.
;
if not keyword_set(npts) then npts = 512
if not keyword_set(slide) then slide = 0.25
if not keyword_set(nave) then nave = 4

PWT = fa_fields_fft(pwt, npts=npts, slide=slide, nave=nave)

;
; COMBINE pwt and trk and fix frequency scale.
;
fa_fields_combine, PWT,trk,result=result,delt_t=delt_t,tag_1='comp1', /talk
freq = fltarr(n_elements(pwt.time),n_elements(pwt.yaxis))

FOR i =0, n_elements(pwt.time)-1 DO BEGIN
    freq(i,*) = PWT.yaxis + result(i) - 9.4 ; CALIBRATION!
ENDFOR

data= {x:PWT.time, y:alog10(PWT.comp1)+1., v:freq}
store_data,'AKR_PWT', data=data
options,'AKR_PWT','spec',1
options,'AKR_PWT','panel_size',5
options,'AKR_PWT','ystyle',1
options,'AKR_PWT','ylog',0
;options,'AKR_PWT','yrange',[16.0, 2000.0]
options,'AKR_PWT','ytitle','PWT!C!C(kHz)'
options,'AKR_PWT','zstyle',1
options,'AKR_PWT','zrange',[-10,-4]
options,'AKR_PWT','ztitle','Log (V/m)!U2!N/Hz'
options,'AKR_PWT','y_no_interp',1
options,'AKR_PWT','x_no_interp',1

store_data,'PWT_FCE',data=['AKR_PWT','FCE']
options,'PWT_FCE','panel_size',5

return
end
