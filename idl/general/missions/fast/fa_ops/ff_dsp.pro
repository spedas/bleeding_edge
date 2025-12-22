;+
; PROCEDURE: FF_DSP, dqd_name, dat=dat, store=store, use_HG=use_HG
;     t1=t1, t2=t2 
;       
; PURPOSE: A low level routine which produces OMNI DSP data for plotting.
;  Use FA_FIELDS_DSP for general work.
;       
; INPUT: 
;       dqd_name -    A valid SDT dqd name. 
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       store -       Stores data.    DEFAULT = 1
;
; OUTPUT: Stored as tplot quantity or:
;       dat -         The IDL data structure.
;       use_HG -      Indicates is data is high gain.
;
; CALLING: ff_dsp, 'DspADC_V5-V8'
;
; OUTPUT: Stored in tplot.
;
; INITIAL VERSION: REE 97-11-25
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
;

pro ff_dsp, dqd_name, dat=dat, store=store, t1=t1, t2=t2, use_HG=use_HG

; GET DATA
IF not keyword_set(dat) then BEGIN
    dat = get_fa_fields(dqd_name,t1,t2,/rep,/quiet)
    IF dat.valid ne 1 and NOT keyword_set(use_HG) then BEGIN
        dat = get_fa_fields((dqd_name+'HG'),t1,t2,/rep,/quiet)
        if dat.valid then use_HG = 1
        if dat.valid then dqd_name = dqd_name + 'HG'
    ENDIF
ENDIF

; STOP AND SEND ERROR MESSAGE IF THERE IS NOTHING TO DO
IF dat.valid ne 1 then BEGIN
    print, "FF_DSP: STOPPED!"
    print, 'Cannot get ', dqd_name,'(HG). Check SDT setup.'
    return
ENDIF

if n_elements(store) LE 0 then store = 1

; STORE THE DATA
IF keyword_set(store) then BEGIN

    ; ESTABLISH NAMES
    short_name = strmid(dqd_name,7,5)
    name  = 'DSP_' + short_name
    name2 = name + '_FCH'

    ; ESTABLISH ZLIM AND TITLES
    zlim = [-11,-1]
    ytit = 'LF E!C!C(kHz)'
    ztit = 'Log (V/m)!U2!N/Hz'
    IF (short_name EQ 'V1-V2') OR (short_name EQ 'V3-V4') OR $
       (short_name EQ 'V5-V6') OR (short_name EQ 'V7-V8') then BEGIN
        zlim = [-10,0]
        ytit = 'LF E 5m!C!C(kHz)'
    ENDIF
    IF (short_name EQ 'V9-V1') then BEGIN
        zlim = [-10,0]
        ytit = 'LF E Ax!C!C(kHz)'
    ENDIF
    if (short_name EQ 'V1-V4') OR (short_name EQ 'V5-V8') then $
	zlim = [-11,-1]
    if (short_name EQ 'V1-V4') then ytit = 'LF E 29m!C!C(kHz)'
    if (short_name EQ 'V5-V8') then ytit = 'LF E 55m!C!C(kHz)'
    IF (short_name EQ 'Mag3a') then BEGIN
        zlim = [-13,-5]
        ztit = 'Log nT!U2!N/Hz'
        ytit = 'LF B 21"!C!C(kHz)'
    ENDIF
    if (use_HG) then zlim = zlim - 2

    ; STORE THE DATA
    data   = {x:dat.time, y:alog10(dat.comp1), v:dat.yaxis}
    store_data,name, data=data

    options,name,'spec',1
    options,name,'panel_size',6
    options,name,'ytitle',ytit
    options,name,'zstyle',1
    options,name,'zrange',zlim
    options,name,'ztitle',ztit
    options,name,'y_no_interp',1
    options,name,'x_no_interp',1
    ff_ylim,name,[0.064,16.384],/log

    store_data,name2,data=[name,'FCH']
    options,name2,'panel_size',6

    ; GIVE MESSAGE
	message, /info, $
	string( name2, name, $
	format='(A,X,"and",X,A,X,"stored as TPLOT quantities.")')

    if NOT keyword_set(t1) then t1 = dat.time(0)
    if NOT keyword_set(t2) then t2 = dat.time(n_elements(dat.time)-1)

ENDIF

return
end

