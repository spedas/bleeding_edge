;+
; PROCEDURE: FF_DESPIN_HSBM, hsbm, phase=phase, t1=t1, t2=t2, pole=pole,
;             epar=epar, eperp=eperp, eax=eax, bsc=bsc, three_d=three_d,
;             b_ang=b_ang
;       
; PURPOSE: ROUTINE TO GET HSBM IN FIELD-ALIGNED COORDINATES.
;
; INPUT: 
;       hsbm -        OPTIONAL. 
;
; KEYWORDS: 
;       phase -       OPTIONAL. WILL GET 1032 PHASE.
;       t1 -          HIGHLY RECOMMENDED! Start time.
;       t2 -          HIGHLY RECOMMENDED! End time.
;       pole -        OPTIONAL. High-pass pole. Default = 300 Hz.
;       three_d -     OPTIONAL. Performs 3_d despin.
;       b_ang -       OPTIONAL. Angle between Bo and spion plane.
;       freqe -       OPTIONAL. Passband for hsbm e.
;       freqb -       OPTIONAL. Passband for hsbm b.
;       store -       OPTIONAL. Stores data for tplot.
;       plot -        OPTIONAL. Plots data.
;       mode -        OPTIONAL. Provide mode if you have it - saves time.
;       delta_t -     OPTIONAL. Corrects timing error by adding to time.
;
; CALLING: ff_despin_hsbm, t1=t1, t2=t2
;
; SDT: NEED (1) One hsbm.comp*, (2) 1032_spin_phase, (3) 1032_mode.
;
; OUTPUT: hsbm is IDL fields time series data structure.
;       epar -        OUTPUT. Parallel electric field.
;       eperp -       OUTPUT. Perpendicular electric field in spin plane.
;       eax -         OUTPUT. Axial perpendicular electric field.
;       bsc -         OUTPUT. Search Coil.
;       time -        OUTPUT. 
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-12-23
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_despin_hsbm, hsbm, phase=phase, t1=t1, t2=t2, pole=pole, b_ang=b_ang, $
         epar=epar, eperp=eperp, eax=eax, bsc=bsc, three_d=three_d, $
         freqe=freqe, freqb=freqb, store=store, time=time, mode=mode, $
         delta_t=delta_t, phs=phs, plot=plot, v12_fudge=v12_fudge

; SET UP CONSTANTS.
two_pi = 2.d*!dpi
if not keyword_set(v12_fudge) then v12_fudge=1.d

; GET MODE
IF not keyword_set(mode) then BEGIN
    mode = get_fields_mode(t1, t2)
    mode = mode.comp1(0)
ENDIF

; IF HSBM IS NOT SET, THEN GET THE DATA.
IF not keyword_set(hsbm) then BEGIN
    hsbm = get_fa_fields('HSBM_Data', t1, t2, rep=0)
ENDIF
ff_dat_to_ptr,hsbm
ff_reduce, hsbm, t1, t2
if hsbm.calibrated NE 1 then fa_fields_hsbmcal, hsbm, mode=mode
*hsbm.comp1 = *hsbm.comp1*v12_fudge

; CORRECT TIME
if keyword_set(delta_t) then *hsbm.time = *hsbm.time + delta_t
time = *hsbm.time

; SHIFT POLES
if n_elements(pole) EQ 0 then pole = 300.0
IF keyword_set(pole) then BEGIN
    *hsbm.comp1 = ff_shift_pole(*hsbm.comp1, pole, 5.e-7)
    *hsbm.comp2 = ff_shift_pole(*hsbm.comp2, pole, 5.e-7)
    *hsbm.comp4 = *hsbm.comp4 - (total(*hsbm.comp4) / hsbm.npts)
    *hsbm.comp4 = ff_shift_pole(*hsbm.comp4, pole, 5.e-7)
ENDIF

; CALCULATE THE ANGLE BETWEEN B AND SPIN AXIS
IF keyword_set(three_d) AND not keyword_set(b_ang) then BEGIN
    fa_fields_cyclotron,t1=t1-100, t2=t2+100
    get_data, 'B_SP_ang', data=data
    b_ang = ff_interp((*hsbm.time)(0), data.x, data.y) * !dpi / 180.d
ENDIF

; SETUP THE PHASE
IF not keyword_set(phase) then BEGIN
    phase = get_fa_fields('SMPhase_FieldsSurvey0',t1-100.,t2+100.)
    phase = fa_fields_phase(phase, freq=0.1)
ENDIF

; INTERPOLATE THE PHASE
phs = ff_interp(hsbm.time, phase.time, phase.comp1, delt=1000.0)

; DO THE DESPIN

dphi  = 2.d*!dpi*52.d/360.d
cosphi =  cos(*phs-dphi) 
sinphi =  sin(*phs-dphi) 
epar  = -(*hsbm.comp2) * cosphi - (*hsbm.comp1) * sinphi
eperp = -(*hsbm.comp2) * sinphi + (*hsbm.comp1) * cosphi

; DO 3D DESPIN IF NECESSARY
IF keyword_set(three_d) and keyword_set(b_ang) then BEGIN
;    epar  = epar * cos(b_ang(0)) - (*hsbm.comp4) * sin(b_ang(0))
	ez = epar*cos( b_ang[ 0]) - (*hsbm.comp4)*sin( b_ang[ 0])
    eax   = cos(b_ang(0)) * (*hsbm.comp4)  + sin(b_ang(0)) *epar
	epar = ez
ENDIF ELSE eax = *hsbm.comp4

bsc = *hsbm.comp3

; PERFORM FILTERING
IF keyword_set(freqe) then BEGIN
    dat = {time: (*hsbm.time), comp1: epar}
    fa_fields_filter, dat, freqe, poles = 4, /rec
    epar = dat.comp1

    dat = {time: (*hsbm.time), comp1: eperp}
    fa_fields_filter, dat, freqe, poles = 4, /rec
    eperp = dat.comp1

    dat = {time: (*hsbm.time), comp1: eax}
    fa_fields_filter, dat, freqe, poles = 4, /rec
    eax = dat.comp1
ENDIF

IF keyword_set(freqb) then BEGIN
    dat = {time: (*hsbm.time), comp1: bsc}
    fa_fields_filter, dat, freqb, poles = 4, /rec
    bsc = dat.comp1
ENDIF

; STORE THE DATA IN TPLOT FORMAT
IF keyword_set(store) then BEGIN
    data = {x:time, y:epar}
    store_data,'E_NEAR_B_HSBM', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-300.,300.],  $
          ytitle:'E NEAR B!C!C(mV/m)',$
          panel_size:3}
    store_data,'E_NEAR_B_HSBM', dlimit=dlimit

    data = {x:time, y:eperp}
    store_data,'E_PERP_HSBM', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-300.,300.],  $
          ytitle:'E PERP (SP)!C!C(mV/m)',$
          panel_size:3}
    store_data,'E_PERP_HSBM', dlimit=dlimit

    data = {x:time, y:eax}
    store_data,'E_AXIAL_HSBM', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-800.,800.],  $
          ytitle:'E AXIAL!C!C(mV/m)',$
          panel_size:3}
    store_data,'E_AXIAL_HSBM', dlimit=dlimit

    data = {x:time, y:bsc}
    store_data,'B_HSBM', data=data
    dlimit = {spec:0, ystyle:1, yrange:[-0.02,0.02],  $
          ytitle:'B 21"!C!C(nT)',$
          panel_size:3}
    store_data,'B_HSBM', dlimit=dlimit
ENDIF

if keyword_set(plot) and keyword_set(store) then $
    tplot,['E_NEAR_B_HSBM','E_PERP_HSBM','E_AXIAL_HSBM','B_HSBM']

IF keyword_set(plot) and not keyword_set(store) THEN BEGIN
    !p.multi = [0,1,4,0,0]
    plot,*hsbm.time-(*hsbm.time)(0),epar
    plot,*hsbm.time-(*hsbm.time)(0),eperp
    plot,*hsbm.time-(*hsbm.time)(0),eax
    plot,*hsbm.time-(*hsbm.time)(0),bsc
ENDIF


phs=phs

return
end



