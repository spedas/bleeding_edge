;+
; PROCEDURE: FA_FIELDS_DSP, dqd_name, dat=dat, all=all, use_HG=use_HG,
;     t1=t1, t2=t2 
;       
;
; PURPOSE: 
;    A high level routine which acquires 
;
; INPUT: 
;       dqd_name -      DSP dqd name or the last part of the name or
;                       a number (see /list option). 
;       		Example: 'V5-V8', 'V58', 'MAG', 'MaG', '58',
;                       'Dsp_V5-V8' or 'DspADC_V5-V8' ALL OK.!
;       		If blank, program will produce DSP OMNI. 
;       SFA14 -         If blank, program will get DSP data.
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       store -       Stores DSP58 and DSP14 as well.    DEFAULT = 0
;                     NOTE: DSP_OMNI ALWAYS STORED!
;       save_mem -    BLOWS AWAY ARRAYS THAT ARE NO
;                     LONGER NEEDED                      DEFAULT = 0
;                     DEFAULT = 1 if DSP58, DSP14, and phase are not given.
;
; CALLING: fa_fields_dsp
;
; IMPORTANT! SDT SETUP: Need to have: Dsp_V5-V8(HG) AND Dsp_V1-V4(HG)
;
; OUTPUT: Stored in tplot.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
;

pro fa_fields_dsp, dqd_name_in, dat=dat, all=all, plot=plot, use_HG=use_HG, $
    t1=t1, t2=t2

; USER FRIENDLY INPUT - LOTS OF CODE!
if NOT keyword_set(dqd_name_in) then dqd_name_in='OMNI'
if keyword_set(use_HG) then use_HG=1 else use_HG=0
dqd_name = dqd_name_in

; CONVERT TO STRING IF NOT STRING
if data_type(dqd_name) GE 1 and data_type(dqd_name) LE 5 then $
    dqd_name  = string(dqd_name)

IF data_type(dqd_name) ne 7 then BEGIN
    message, /info, 'Need to give (last part of) dqd name.'
    return
ENDIF

temp = strlowcase(dqd_name)
ind_o = strpos(temp,'o')
ind_m = strpos(temp, 'm')
if ind_o(0) GE 0 then dqd_name = 'OMNI' else $
if ind_m(0) GE 0 then dqd_name = 'Mag3ac' ELSE BEGIN

    ; FIND OUT IF HG
    test = strpos(temp,'hg')
    if test GE 0 then use_HG = 1

    ; FIND THEN NUMBERS IN THE STRING
    nums = intarr(10) - 1
    for i=1,9 do nums(i) = strpos(temp,strcompress(string(i),/rem))
    ind    = where(nums GE 0, n_ind)
    IF n_ind EQ 0 then BEGIN
        message, /info, 'Bad dqd (num or name).'
        return
    ENDIF
    first  = min(nums(ind), ind_min)
    second = max(nums(ind), ind_max)

    ; RECONSTRUCT DQD NAME
    if first NE second then $
        dqd_name = 'V' + strcompress(string(ind(ind_min)),/rem) $
        + '-V' + strcompress(string(ind(ind_max)),/rem) else $
        dqd_name = 'V' + strcompress(string(ind(ind_min)),/rem) 

    ; SPECIAL CASE V910    
    if ind(ind_max) EQ 1 AND ind(ind_min) EQ 9 then dqd_name = dqd_name + '0' 
    if keyword_set(use_HG) then dqd_name = dqd_name + 'HG'
ENDELSE

; MAKE THE FULL NAME
dqd_name = 'DspADC_' + dqd_name

; DO CASE OMNI
IF dqd_name EQ 'DspADC_OMNI' then BEGIN
    if not keyword_set(all) then store = 0 else store = 1
    ; GET DSP58.
    if use_HG then name = 'DspADC_V5-V8HG' else name = 'DspADC_V5-V8'
    ff_dsp,name,dat=DSP58, store=store, use_HG=use_HG, t1=t1, t2=t2

    ; GET DSP14.
    if use_HG then name = 'DspADC_V1-V4HG' else name = 'DspADC_V1-V4'
    ff_dsp,name,dat=DSP14, store=store, use_HG=use_HG, t1=t1, t2=t2

    ; STOP AND SEND ERROR MESSAGE IF THERE IS NOTHING TO DO
    IF DSP58.valid ne 1 OR DSP14.valid ne 1 then BEGIN
        if DSP58.valid ne 1 then $
            message, /info, "Cannot get DspADC_V5-V8(HG). Check SDT setup."
        if DSP14.valid ne 1 then $
            message, /info, "Cannot get DspADC_V1-V4(HG). Check SDT setup."
        return
    ENDIF

    ; CACLUATE DSP OMNI
    IF DSP58.valid AND DSP14.valid then BEGIN
        npts58 = n_elements(dsp58.time)
        temp   = lindgen(npts58)
        temp2  = ff_interp(dsp14.time, dsp58.time, temp, delt_t=1.e-6, /nearest)
        ind    = where(temp GE 0 AND temp LT npts58, n_ind)
        if (n_ind LE 0) then return
        d58 = dsp58.comp1(temp2(ind),*)
        d14 = dsp14.comp1(ind,*)
        t   = dsp14.time(ind)
        v   = dsp14.yaxis

        ; STORE THE DATA.
        if use_HG then zlim = [-13,-3] else zlim  = [-11,-1]
        name  = 'DSP_OMNI'
        name2 = 'DSP_OMNI_FCH'

        data   = {x:t, y:alog10(d58+d14), v:v}
        store_data,name, data=data

        options,name,'spec',1
        options,name,'panel_size',6
        options,name,'ytitle','LF E OMNI!C!C(kHz)'
        options,name,'zstyle',1
        options,name,'zrange',zlim
        options,name,'ztitle','Log (V/m)!U2!N/Hz'
        options,name,'y_no_interp',1
        options,name,'x_no_interp',1
        ff_ylim,name,[0.064,16.384],/log

        store_data,name2,data=[name,'FCH']
        options,name2,'panel_size',6

        IF keyword_set(plot) then BEGIN
            IF keyword_set(all) then BEGIN
                if(use_HG) then $
                	tplot, $
		[name2,'DSP_V5-V8HG_FCH','DSP_V1-V4HG_FCH'],tran=[t1,t2] $
                else tplot, $
		[name2,'DSP_V5-V8_FCH','DSP_V1-V4_FCH'], tran=[t1,t2]
            ENDIF else tplot,[name2], tran=[t1,t2]
        ENDIF

    ENDIF

ENDIF ELSE BEGIN ; END DQD_NAME='OMNI'

    ; DO ALL OTHER CASES
    ff_dsp,dqd_name, t1=t1, t2=t2, dat=dat, use_HG=use_HG
    IF keyword_set(plot) and dat.valid then tplot, name2, tran=[t1,t2]

ENDELSE

return

END

