;	@(#)fa_fields_despin.pro	1.19	03/19/98
;+
; PROCEDURE: FA_FIELDS_DESPIN, V58, V12, T1 = t1, T2 = t2, 
;                 PHASE = phase, USE_V158 = Use_V158, 
;                 SHADOW_NOTCH = shadow_notch, 
;                 MAG_NOTCH = mag_notch, STORE=store, SLOW=slow 
;
; PURPOSE: A high-level routine which produces despun DC electric field
;          data for FAST.
;
; INPUT: 
;    V58 -         If blank, program will get V5-V8_S. If you want
;                  to run this program on burst data, use 
;                  V58=get_fa_fields('V5-V8_4k',/all), for example.
;    V12 -         If blank, program will get V1-V2_S
;                  to run this program on burst data, use 
;                  V12=get_fa_fields('V1-V2_4k',/all), for example.
;
; KEYWORDS: 
;    USE_V158       If set, use V158, otherwise V1-V2. DEFAULT = 0
;                   Note: be sure to set this if you supply V1-58!
;
;    SHADOW_NOTCH - Notch out shadow spikes (also known as "sun
;                   spikes"). These are set to NaN's, unless the
;                   Sinterp keyword is set. The default is
;                   SHADOW_NOTCH = 0, in which case the sun spikes are
;                   left alone.
;
;    MAG_NOTCH - Notch out mag pulses. These will be interpolated
;                across, unless the Bnan keyword is set.The default is
;                MAG_NOTCH = 1, so you must say ...,mag_notch=0,... if
;                you want to see the mag spikes.
;
;    STORE -        Store data for tplot.        DEFAULT = 1
;
;    SLOW -         Uses FA_FIELDS_SPINFIT instead
;                      of FF_QUICKFIT.  DEFAULT = 0
;
;    T1, T2 -       Start and stop time, if other than that
;                   contained in V58 and V12, (or if those 
;                   quantities are not defined). 
;
; CALLING: fa_fields_despin,t1='1997-09-27/01:32',t2='1997-09-27/01:34'
;
;       That's easy! Now you can plot E_near_B and E_equatorward.
;
; IMPORTANT! SDT SETUP: Need to have: V5-V8_S, V1-V2_S (or V1-V4_S, V4_S
;                       and V8_S), 1032_spinPhase
;
; OUTPUT: Dat is IDL fields time series data structure with multiple
;         components. This  
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
pro fa_fields_despin, V58, V12, T1 = t1, T2 = t2, PHASE = phase, $
                      USE_V158 = use_v158, $
                      SHADOW_NOTCH = shadow_notch, MAG_NOTCH = mag_notch, $
                      STORE = store, DAT = dat, SLOW = slow,  $
                      Binterp = Binterp, Bnan = Bnan,  $
                      Sinterp = Sinterp, Snan = Snan
; Set up constants.
two_pi = 2.d*!dpi

req_dqds = ['V5-V8_S','V1-V2_S','SMPhase_FieldsSurvey0']
if keyword_set(use_v158) then  $
  req_dqds = ['V1-V4_S','V4_S','V8_S','V5-V8_S','SMPhase_FieldsSurvey0']

if not (missing_dqds(req_dqds,/quiet,absent=absent) eq 0) then begin
    message,'The following required quantities are not in ' + $
      'SDT:',/continue
    print,absent
    return    
endif


; First set up V58.
IF not defined(V58) then BEGIN
    V58 = get_fa_fields('V5-V8_S',t1,t2)
    IF not v58.valid then BEGIN
        print, "FA_FIELDS_DESPIN: STOPPED!"
        print, "Cannot get V5-V8_S. Check SDT setup."
        return
    ENDIF
ENDIF

; Next set up V12.

IF not defined(V12) then BEGIN
    IF not keyword_set(Use_V158) then BEGIN
        V12 = get_fa_fields('V1-V2_S',t1,t2)
    ENDIF ELSE BEGIN
        v12 = get_fa_v158(t1,t2,cutoff=cutoff)
        fa_fields_filter,v58,[0,cutoff]
    ENDELSE

    IF not v12.valid then BEGIN
        print, "FA_FIELDS_DESPIN: STOPPED!"
        print, "Cannot get V1-V2_S. Check SDT setup."
        return
    ENDIF
ENDIF

; Set up the phase.
IF not defined(phase) then BEGIN
    phase = fa_fields_phase(freq=0.01)
    IF not phase.valid then BEGIN
        print, "FA_FIELDS_DESPIN: STOPPED!"
        print, "Cannot get phase. Check SDT setup."
        return
    ENDIF
ENDIF

; Begin the combine process. Do not add to structure. Save some space.
; 
if not keyword_set(use_v158) then begin
    fa_fields_combine,V58,V12,result=v12_dat, /svy
endif else begin
    v12_dat = v12.comp1
endelse


fa_fields_combine, V58, phase, result=Bphase, /interp, delt=100.
fa_fields_combine, V58, phase, tag_2='comp2', result=Sphase, /interp, delt=100.

start_time = v58.start_time
time = v58.time-start_time
v58_dat = v58.comp1
units = v58.units_name
npts=v58.npts

v12name = 'V12'
if keyword_set(use_v158) then v12name = 'V158'


; We now have time, V58_dat, V12_dat, Bphase, and Sphase
; Notch the data
;
; The default is mag_notch = 1, Binterp = 1. Do we need to deactivate
; these? Note that keyword_set() is not used here, because it
; evaluates to zero if a keyword is either undefined or defined to be
; zero. 

if not defined(mag_notch) then mag_notch = 1
if mag_notch eq 0 then begin
    Binterp = 0 & Bnan = 0
endif else begin
    if not defined(Bnan) then bnan = 0
    if not defined(Binterp) then binterp = (bnan eq 0)
    if bnan and binterp then begin
        message,'Can''t both interpolate and NaN mag spikes! Doing ' + $
          'interpolation...',/continue
        binterp = 1 & bnan = 0
    endif
endelse

if not defined(shadow_notch) then shadow_notch = 0
if shadow_notch eq 1 then begin
    if not defined(sinterp) then sinterp = 0
    if not defined(snan) then snan = (sinterp eq 0)
    if snan and sinterp then begin
        message,'Can''t both interpolate and NaN sun spikes! ' + $
          'NaNing...',/continue
        sinterp = 0 & snan = 1
    endif
endif else begin
    sinterp = 0
    snan = 0
endelse

;
; deal with the true/false, keyword_set or not ambiguity...keyword_set
; means not zero, odd integers are true, and NOT flips all the bits. I
; want true/false here...use 0 and 1. 
;
if snan then snan = 1 else snan = 0
if sinterp then sinterp = 1 else sinterp = 0
if bnan then bnan = 1 else bnan = 0
if binterp then binterp = 1 else binterp = 0

notch58 = ff_notch('V58',V58_dat,Bphase=Bphase,Sphase=Sphase, $
                   Binterp=Binterp,Bnan=Bnan, $
                   Sinterp=Sinterp,Snan=Snan)
notch12 = ff_notch(v12name,V12_dat,Bphase=Bphase,Sphase=Sphase, $
                   Binterp=Binterp,Bnan=Bnan, $
                   Sinterp=Sinterp,Snan=Snan)

if not keyword_set(use_v158) then begin
;
; DETERMINE THE ZERO LEVEL AND RATIO AND ADJUST DATA. 
;
    if not keyword_set(slow) then begin
; QUICKFIT 58
        index = where(finite(time) AND finite(V58_dat),n_finite)
        IF (n_finite GT 0) then BEGIN
            phs = time(index)
            dat = v58_dat(index)
            ff_quickfit,dat,phs,es=es58, ec=ec58, $
              phsf=tf58, zero=zero58, per=5.d
        ENDIF

; QUICKFIT 12
        index = where(finite(time) AND finite(V12_dat),n_finite)
        IF (n_finite GT 0) then BEGIN
            phs = time(index)
            dat = v12_dat(index)
            ff_quickfit,dat,phs,es=es12, ec=ec12,  $
              phsf=tf12, zero=zero12, per=5.d
        ENDIF
        phs=0
        dat=0
    endif else begin
        message,'Using slow spinfitter, not recommended for ' + $
          'long intervals (a few minutes max)...',/continue
        fa_fields_spin_ave,v58,interval=.01,slide=.01
        fa_fields_spin_ave,v12,interval=.01,slide=.01
        
        if not $
          ((fa_fields_spinfit(v58,coeff=c58, $
                              interval=2.,slide=0.2,times=tf58)) and $
           (fa_fields_spinfit(v12,coeff=c12, $
                              interval=2.,slide=0.2,times=tf12))) then begin
            message,'Unable to spinfit for gain normalization...life is ' + $
              'tough...',/continue 
            return
        endif
        
        ok = where(finite(reform(c58(0,*))) and finite(reform(c12(0,*))),nok)
        if nok eq 0 then begin
            message,'All spinfit data are NaN!',/continue
            return
        endif
        
        tf12 = tf12(ok) - start_time
        tf58 = tf58(ok) - start_time
        
        zero58 = (reform(c58(4,*)))(ok)
        ec58 = (reform(c58(0,*)))(ok)
        es58 = (reform(c58(1,*)))(ok)
        v58dat = v58.comp1
        zero12 = (reform(c12(4,*)))(ok)
        ec12 = (reform(c12(0,*)))(ok)
        es12 = (reform(c12(1,*)))(ok)
        v12dat = v12.comp1
    endelse 

; FIX THE ZERO LEVEL 58
    index = where(finite(zero58))
    zero = zero58(index)
    zt   = tf58(index)
    ff_dce_fix,V58_dat,time,zero,zt

; DETERMINE RATIO
    etot12 = (es12*es12 + ec12*ec12)
    etot58 = (es58*es58 + ec58*ec58)
    etot12_aligned = ff_interp(tf58, tf12, etot12, delt = 100.)
    ratio = sqrt( etot58 / etot12_aligned )
    index = where(finite(ratio) AND (ratio GT 0.25) AND (ratio LT 2.0), $
                  n_index)

    rat = fltarr(n_elements(tf58))+1.
    rt = tf58
    if n_index gt 0 then begin
        rat = smooth(ratio(index),(n_index/2 < 20) > 2)
        rt = tf58(index)
    endif

; FIX THE ZERO LEVEL AND RATIO OF 12
    index = where(finite(zero12))
    zero = zero12(index)
    zt   = tf12(index)
    ff_dce_fix,V12_dat,time,zero,zt,rat, rt
endif                           ; not keyword_set(use_v158)


;
; DO THE DESPIN
;
dphi = 2.d*!dpi*37.98d/360.d
e1 = v12_dat*cos(Bphase+dphi) - v58_dat*sin(Bphase+dphi)
e2 = v58_dat*cos(Bphase+dphi) + v12_dat*sin(Bphase+dphi)

to_be_stored = ['E_NEAR_B','E_ALONG_V','EFIT_NEAR_B','EFIT_ALONG_V']
ntbs = n_elements(to_be_stored)
for i=0,ntbs-1 do begin
    if find_handle(to_be_stored(i)) ne 0 then $
      store_data,to_be_stored(i),/delete
endfor

; STORE THE DATA IN TPLOT FORMAT
data = {x:time+start_time, y:e1}
store_data,'E_NEAR_B', data=data
dlimit = {spec:0, ystyle:1,  $
          ytitle:'E NEAR B!C!C(mV/m)'}
store_data,'E_NEAR_B', dlimit=dlimit

data = {x:time+start_time, y:e2}
store_data,'E_ALONG_V', data=data
dlimit = {spec:0, ystyle:1, $
          ytitle:'E ALONG V!C!C(mV/m)'}
store_data,'E_ALONG_V', dlimit=dlimit

if not keyword_set(use_v158) then begin
;
; DESPIN AND STORE QUICKFIT DATA
;

; QUICKFIT 58
    index = where(finite(Bphase) AND finite(V58_dat),n_finite)
    IF (n_finite GT 0) then BEGIN
        phs = Bphase(index)+dphi
        dat = v58_dat(index)
        ff_quickfit,dat,phs,es=es58, ec=ec58, phsf=phsf58
    ENDIF

    ind     = where(finite(phsf58))
    phsf58  = phsf58(ind)
    es58    = es58(ind)
    ec58    = ec58(ind)
    tf58    = ff_interp(phsf58, phs, time(index), delt= 100.)

    phs=0
    dat=0

    data = {x:tf58+start_time, y:es58}
    store_data,'EFIT_NEAR_B', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
              ytitle:'EFIT NEAR B!C!C55m (mV/m)',$
              panel_size:3}
    store_data,'EFIT_NEAR_B', dlimit=dlimit

    data = {x:tf58+start_time, y:ec58}
    store_data,'EFIT_ALONG_V', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
              ytitle:'EFIT ALONG V!C!C55m (mV/m)',$
              panel_size:3}
    store_data,'EFIT_ALONG_V', dlimit=dlimit
endif 

return
end



