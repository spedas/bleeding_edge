;+
; PROCEDURE: FA_FIELDS_SFA, SFA58, SFA14, store=store,
;     save_mem=save_mem, t1=t1, t2=t2, burst=burst, 
;       
;
; PURPOSE: A high level routine which produces OMNI SFA data for plotting.
;
; INPUT: 
;       SFA58 -         If blank, program will get V5-V8HG_16k. 
;       SFA14 -         If blank, program will get V1-V4HG_16k
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       mag -         Does magnetometer data only.
;       store -       Store data as a tplot file.        DEFAULT = 1
;                     If store > 1 then all data stored.
;       burst -       Get burst data.                    DEFAULT = 0
;       save_mem -    BLOWS AWAY ARRAYS THAT ARE NO
;                     LONGER NEEDED                      DEFAULT = 0
;                     DEFAULT = 1 if V58, V14, and phase are not given.
;
; CALLING: fa_fields_sfa
;
; IMPORTANT! SDT SETUP: Need to have: SfaBurst_V5-V8, (SfaBurst_V1-V4
;                        or SfaBurst_V1-V2)
;
; OUTPUT: Stored in tplot.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
;

pro fa_fields_sfa, V58, V14, store=store, $
    t1=t1, t2=t2, save_mem=save_mem, burst=burst, mag=mag, fix12=fix12

if not keyword_set(SFA58) AND not keyword_set(SFA14) then save_mem=1
if n_elements(store) EQ 0 then store=1

;
; DO MAG CASE FIRST
;
IF keyword_set(mag) then BEGIN

    ; DO MAG BURST
    IF keyword_set(burst) then BEGIN
        SFA_MAG = get_fa_fields('SfaBurst_Mag3AC',t1,t2,/rep)
        IF SFA_MAG.valid ne 1 then BEGIN
            message, /info, "Cannot get SfaBurst_Mag3AC. Check SDT setup."
            return
        ENDIF
    ENDIF ELSE BEGIN 
    ; MAG SURVEY CASE
        SFA_MAG = get_fa_fields('SfaAve_Mag3AC',t1,t2,/rep)
        IF SFA_MAG.valid ne 1 then BEGIN
            message, /info, "Cannot get SfaAve_Mag3AC. Check SDT setup."
            return
        ENDIF
    ENDELSE

    ; STORE THE DATA.
    if keyword_set(burst) then name = 'SFA_MAG_B'  else name='SFA_MAG'
    zlim  = [-12,-6]
    if keyword_set(burst) then name2 = 'SFA_MAG_B_FCE'  else name2='SFA_MAG_FCE'

    data   = {x:SFA_MAG.time, y:alog10(SFA_MAG.comp1), v: SFA_MAG.yaxis}
    store_data,name, data=data

    options,name,'spec',1
    options,name,'panel_size',5
    options,name,'ystyle',1
    options,name,'ylog',1
    options,name,'yrange',[16.0, 2000.0]
    options,name,'ytitle','HF B!C!C(kHz)'
    options,name,'zstyle',1
    options,name,'zrange',zlim
    options,name,'ztitle','Log (nT!U2!N/Hz)'
    options,name,'y_no_interp',1
    options,name,'x_no_interp',1
    options,name,'yticks',1
    options,name,'ytickname',['10!A2!N','10!A3!N']
    options,name,'ytickv',[100.,1000.]

    store_data,name2,data=[name,'FCE']
    options,name2,'panel_size',5

    return
ENDIF


; 
; SFA OMNI CASE
;

; DO BURST CASE
IF keyword_set(burst) then BEGIN

    ; GET SFA58.
    IF not keyword_set(SFA58) then BEGIN
        SFA58 = get_fa_fields('SfaBurst_V5-V8',t1,t2,/rep)
        IF SFA58.valid ne 1 then BEGIN
            message, /info, "Cannot get SfaBurst_V5-V8. Check SDT setup."
            return
        ENDIF
    ENDIF

    ; GET SFA14.
    IF not keyword_set(SFA14) then BEGIN
        SFA14 = get_fa_fields('SfaBurst_V1-V4',t1,t2,/rep)
        if SFA14.valid ne 1 then use12=1 else use12=0
        if keyword_set(use12) then $
            SFA14 = get_fa_fields('SfaBurst_V1-V2',t1,t2,/rep)
        IF SFA14.valid ne 1 then BEGIN
            message, /info, "Cannot get SfaBurst_V1-V4 or SfaBurst_V1-V2."
            message, /info, "Check SDT setup."
            return
        ENDIF
    ENDIF

ENDIF ELSE BEGIN ; SURVEY CASE

    ; GET SFA58.
    IF not keyword_set(SFA58) then BEGIN
        SFA58 = get_fa_fields('SfaAve_V5-V8',t1,t2,/rep)
        IF SFA58.valid ne 1 then BEGIN
            message, /info, "Cannot get SfaAve_V5-V8. Check SDT setup."
            return
        ENDIF
    ENDIF

    ; GET SFA14.
    IF not keyword_set(SFA14) then BEGIN
        SFA14 = get_fa_fields('SfaAve_V1-V4',t1,t2,/rep)
        if SFA14.valid ne 1 then use12=1 else use12=0
        if keyword_set(use12) then $
            SFA14 = get_fa_fields('SfaAve_V1-V2',t1,t2,/rep)
        IF SFA14.valid ne 1 then BEGIN
            message, /info, "Cannot get SfaAve_V1-V4 or SfaAve_V1-V2."
            message, /info, "Check SDT setup."
            return
        ENDIF
    ENDIF

ENDELSE

if keyword_set(use12) AND keyword_set(fix12) then $
    SFA14.comp1 = SFA14.comp1*fix12

;
; IMPORTANT NOTE!
; 
; Since SFA's are all in one APID, I assume no combining is necessary.
;

; STORE THE DATA.
if keyword_set(burst) then name = 'SFAB_OMNI'  else name='SFA_OMNI'
if use12              then zlim  = [-14,-6]    else zlim  = [-15,-7]
if keyword_set(burst) then name2 = 'SFAB_FCE'  else name2='SFA_FCE'

IF (store GT 0) then BEGIN
    data   = {x:SFA58.time, y:alog10(SFA58.comp1 + SFA14.comp1), v:SFA58.yaxis}
    store_data,name, data=data

    options,name,'spec',1
    options,name,'panel_size',5
    options,name,'ystyle',1
    options,name,'ylog',1
    options,name,'yrange',[16.0, 2000.0]
    options,name,'ytitle','HF E OMNI!C!C(kHz)'
    options,name,'zstyle',1
    options,name,'zrange',zlim
    options,name,'ztitle','Log (V/m)!U2!N/Hz'
    options,name,'y_no_interp',1
    options,name,'x_no_interp',1
    options,name,'yticks',1
    options,name,'ytickname',['10!A2!N','10!A3!N']
    options,name,'ytickv',[100.,1000.]

    store_data,name2,data=[name,'FCE']
    options,name2,'panel_size',5
ENDIF

IF (store GT 1) then BEGIN

    ; STORE SFA58
    if keyword_set(burst) then name = 'SFAB_58' else name='SFA_58'
    if keyword_set(burst) then name2 = 'SFAB_58_FCE' else name2='SFA_58_FCE'

    data   = {x:SFA58.time, y:alog10(SFA58.comp1), v:SFA58.yaxis}
    store_data,name, data=data

    options,name,'spec',1
    options,name,'panel_size',5
    options,name,'ystyle',1
    options,name,'ylog',1
    options,name,'yrange',[16.0, 2000.0]
    options,name,'ytitle','HF E 55m!C!C(kHz)'
    options,name,'zstyle',1
    options,name,'zrange',[-15,-7]
    options,name,'ztitle','Log (V/m)!U2!N/Hz'
    options,name,'y_no_interp',1
    options,name,'x_no_interp',1
    options,name,'yticks',1
    options,name,'ytickname',['10!A2!N','10!A3!N']
    options,name,'ytickv',[100.,1000.]

    store_data,name2,data=[name,'FCE']
    options,name2,'panel_size',5

    ; STORE SFA14
    if keyword_set(burst) then name = 'SFAB_14' else name='SFA_14'
    if keyword_set(burst) then name2 = 'SFAB_14_FCE' else name2='SFA_14_FCE'
    ytitle = 'HF E 29m!C!C(kHz)'

    IF (use12) then BEGIN
        if keyword_set(burst) then name = 'SFAB_12' else name='SFA_12'
        if keyword_set(burst) then name2='SFAB_12_FCE' else name2='SFA_12_FCE'
        ytitle = 'HF E 5m!C!C(kHz)'
    ENDIF

    data   = {x:SFA14.time, y:alog10(SFA14.comp1), v:SFA14.yaxis}
    store_data,name, data=data

    options,name,'spec',1
    options,name,'panel_size',5
    options,name,'ystyle',1
    options,name,'ylog',1
    options,name,'yrange',[16.0, 2000.0]
    options,name,'ytitle',ytitle
    options,name,'zstyle',1
    options,name,'zrange',zlim
    options,name,'ztitle','Log (V/m)!U2!N/Hz'
    options,name,'y_no_interp',1
    options,name,'x_no_interp',1
    options,name,'yticks',1
    options,name,'ytickname',['10!A2!N','10!A3!N']
    options,name,'ytickv',[100.,1000.]

    store_data,name2,data=[name,'FCE']
    options,name2,'panel_size',5

ENDIF

return

END

