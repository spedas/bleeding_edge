;+
; PROCEDURE: FF_DESPIN_SVY_LONG, t1 = t1, t2 = t2, 
;	store=store, fmax=fmax,
;	talk=talk, fix_zero=fix_zero, 
;       t_res=t_res, mpot=mpot, sweeps=sweeps
;
; PURPOSE: Produces Eperp and Epar from long wire booms in survey mode.
;
; INPUT: 
;
; KEYWORDS: 
;    STORE -        Store data for tplot.        DEFAULT = 1
;    FIX_ZERO -     Fixes the zero level.        DEFAULT = 0
;    FAMX -         Maximum frequency.           DEFAULT = 10 Hz
;    T_RES -        Resolution of stored data.   DEFAULT = 0.025 s
;    TALK -         Sends messages.              DEFAULT = 0
;    MPOT -         Maximum abs(potential).      DEFAULT = 15
;    SWEEPS -       Start/stop times of sweeps.  DEFAULT = 0
;    T1, T2 -       Start and stop time, if other than that
;                   contained in V58 and V12, (or if those 
;                   quantities are not defined). 
;;
; IMPORTANT! SDT SETUP: Need to have: V5-V8_S, V1-V4_S , V4_S
;                       and V8_S, 1032_spinPhase
;
; OUTPUT:
; 
; NOTES: Dat is IDL fields time series data structure with multiple
;         components. This  
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-
pro ff_despin_svy_long, t1=t1, t2=t2, store=store, fmax=fmax, $
    epar=epar, time=time, eperp=eperp, pot=pot, fix_zero=fix_zero, $
    v14=v14, v58=v58, v5=v5, v8=v8, v4=v4, v1=v1, bad=bad, mpot=mpot, $
    sweeps=sweeps, t_res=t_res  
                      
; SET UP CONSTANTS.
two_pi = 2.d*!dpi
if n_elements(store) EQ 0 then store = 1
if not keyword_set(fmax) then fmax = 10.0
if not keyword_set(t_res) then t_res = 0.25/fmax
if not keyword_set(mpot) then mpot = 15.0

; CHECK SDT SET UP
req_dqds = ['V1-V4_S','V4_S','V8_S','V5-V8_S','SMPhase_FieldsSurvey0']
if not (missing_dqds(req_dqds,/quiet,absent=absent) eq 0) then begin
    message, /info, $
	string( strjoin(absent), $
	format='("The following required quantities are not in SDT:",X,A)')
    return    
endif

; GET ALL OF THE DATA
V58 = get_fa_fields('V5-V8_S',t1,t2)
V14 = get_fa_fields('V1-V4_S',t1,t2)
V8  = get_fa_fields('V8_S',t1,t2)
V4  = get_fa_fields('V4_S',t1,t2)

IF not (V58.valid and V14.valid and V4.valid and V8.valid) then BEGIN
    message, /info, $
	"Unable to get required data (V5-V8_S,V1-V4_S,V8_S,V4_S)."
    return
ENDIF

; GET THE PHASE.
phase = fa_fields_phase(freq=0.01)
IF not phase.valid then BEGIN
    message, /info, "Cannot get phase. Check SDT setup."
    return
ENDIF

; COMBINE THE DATA
time = v58.time
start_time = v58.start_time
units = v58.units_name
npts=v58.npts
v14  = ff_interp(time, v14.time, v14.comp1, delt=1.0)
v4   = ff_interp(time,  v4.time, v4.comp1, delt=1.0)
v8   = ff_interp(time,  v8.time, v8.comp1, delt=1.0)
Bphs = ff_interp(time, phase.time, phase.comp1, delt=100.0)
v58  = v58.comp1

; FILTER THE DATA TO 1/2 NYQUIST OF V4, V8
cof  = digital_filter(0.0,0.125,80.0,15)
cof = cof / total(cof)
v58  = convol(v58,cof,/edge_t)
v14  = convol(v14,cof,/edge_t)
v4   = convol(v4 ,cof,/edge_t)
v8   = convol(v8 ,cof,/edge_t)

; CREATE THE V158 SIGNAL AND OTHER VOLTAGES
c14 = 0.915
c58 = -0.882
c4  = 31.65
c8  = -31.65
b14 = 28.9 / 1000.0
b58 = 55.692 / 1000.0

v158 = c14*v14 + c58*v58 + c4*v4 + c8*v8
v1   = b14*v14 + V4
v5   = b58*v58 + v8

; FIND ALL OF THE BAD POINTS
pot = v1*0.100722 + v5*0.449639 + v8*0.449639
bad = where ( (abs(V1) GT 40.0) OR (abs(V4) GT 40.0) OR $ 
              (abs(V5) GT 40.0) OR (abs(V8) GT 40.0) OR $
              (finite(V58) EQ 0) OR (finite(V158) EQ 0) OR $
              (abs(V58) GT 1600.0)  OR (abs(V158) GT 1600.0) OR $
              (abs(pot) GT mpot), n_bad )

; THROW OUT SWEEPS
nsweeps = n_elements(sweeps)/2
FOR i = 0, nsweeps-1 DO BEGIN
    tbad = where( (time GT sweeps(2*i) ) AND (time LT sweeps(2*i+1) ), ntbad)
    if ntbad GT 0 then bad=[bad,tbad]
    if n_bad EQ 0 AND ntbad GT 0 then bad=tbad
    n_bad = n_bad + ntbad
ENDFOR

; FIX ZERO LEVEL
IF keyword_set(fix_zero) then BEGIN

    if n_bad GT 0 then v58(bad)  = 0.0
    if n_bad GT 0 then v158(bad) = 0.0

    ;DETERMINE THE ZERO LEVEL AND RATIO AND ADJUST DATA. 
    phs   = Bphs mod two_pi
    ind   = where( phs(1:*) LT phs(0:*) )
    n_ind = n_elements(ind)
    z58   = fltarr(n_ind-1)
    z158  = fltarr(n_ind-1)
    t     = dblarr(n_ind-1)

    FOR i=1, n_ind-1 DO BEGIN
        z58(i-1)   = total( v58( ind(i-1)+1:ind(i) ) ) / (ind(i) - ind(i-1) - 1)
        z158(i-1)  = total(v158( ind(i-1)+1:ind(i) ) ) / (ind(i) - ind(i-1) - 1)
        t(i-1)     = time ( ( ind(i-1) + ind(i) ) / 2 )
    ENDFOR

    ; SMOOTH ZERO LEVELS
    cof  = digital_filter(0.0,0.250,60.0,7)
    cof = cof/total(cof)
    z58  = convol(z58, cof, /edge_t)
    z158 = convol(z158,cof, /edge_t)

    ; SUBTRACT ZERO LEVELS
    z58   = ff_interp(time, t,  z58, delt=1000.0)
    z158  = ff_interp(time, t, z158, delt=1000.0)
    v58   = v58 - z58
    v158  = v158 - z158

ENDIF ; END FIX ZERO LEVEL

if n_bad GT 0 then v58(bad)  = !values.f_nan
if n_bad GT 0 then v158(bad) = !values.f_nan

;
; DO THE DESPIN
;
dphi  = 2.d*!dpi*37.98d/360.d
epar  = v158*cos(Bphs+dphi) - v58* sin(Bphs+dphi)
eperp = v58* cos(Bphs+dphi) + v158*sin(Bphs+dphi)

to_be_stored = ['E_NEAR_B','E_ALONG_V', 'POT']
ntbs = n_elements(to_be_stored)
for i=0,ntbs-1 do begin
    if find_handle(to_be_stored(i)) ne 0 then $
      store_data,to_be_stored(i),/delete
endfor

; FILTER THE DATA TO fmax HZ
dat = {time:time, comp1:epar, comp2:eperp, comp3:pot}
fa_fields_filter,dat,[0,fmax], /rec, poles=2

; REDUCE THE DATA
dt = time(npts-1)-time(0)
ipts = round(dt / t_res)
t    = dindgen(ipts)*t_res + time(0)
e_par_r = ff_interp(t, time, dat.comp1, delt=1.0)
e_prp_r = ff_interp(t, time, dat.comp2, delt=1.0)
pot_r   = ff_interp(t, time, dat.comp3, delt=1.0)


; STORE THE DATA IN TPLOT FORMAT
data = {x:t, y:e_par_r}
store_data,'E_NEAR_B', data=data
dlimit = {spec:0, ystyle:1,  $
          ytitle:'E NEAR B!C!C(mV/m)'}
store_data,'E_NEAR_B', dlimit=dlimit

data = {x:t, y:e_prp_r}
store_data,'E_ALONG_V', data=data
dlimit = {spec:0, ystyle:1, $
          ytitle:'E ALONG V!C!C(mV/m)'}
store_data,'E_ALONG_V', dlimit=dlimit

data = {x:t, y:pot_r}
store_data,'POT', data=data
dlimit = {spec:0, ystyle:1, $
          ytitle:'Potential!C!C(V)'}
store_data,'POT', dlimit=dlimit

return
end



