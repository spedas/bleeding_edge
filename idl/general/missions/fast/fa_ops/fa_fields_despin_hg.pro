;+
; PROCEDURE: FA_FIELDS_DESPIN_HG, V58, V14, phase=phase, spec=spec,
;     save_mem=save_mem, t1=t1, t2=t2, nave=nave, slide=slide, nfft=nfft
;       
;
; PURPOSE: A high level routine which produces despun DC efield
;          data from sdt _16k data in SDT.
;
; INPUT: 
;       V58 -         If blank, program will get V5-V8HG_16k. 
;       V14 -         If blank, program will get V1-V4HG_16k
;
; KEYWORDS: 
;       t1 -          Optional start time.
;       t2 -          Optional end time.
;       save_mem -    BLOWS AWAY ARRAYS THAT ARE NO
;                     LONGER NEEDED                      DEFAULT = 0
;                     DEFAULT = 1 if V58, V14, and phase are not given.
;       spec -        Will create a FFT spectra.         DEFAULT = 0
;       nave -        FFT spectra.        		 DEFAULT = 4
;       slide -       FFT spectra.        		 DEFAULT = 0.5
;       nfft -        FFT spectra.        		 DEFAULT = 1024
;
; CALLING: fa_fields_despin_HG_16k
;       That's easy! Now you can plot E_near_B_HG and E_along_V_HG.
;
; IMPORTANT! SDT SETUP: Need to have: V5-V8HG_16k, V1-V4HG_16k, and
;                       (1048_spinphase or 1048_magphase).
;
; OUTPUT: Dat is IDL fields time series data structure with multiple
;         components. This  
;
; SIDE EFFECTS: Need lots of memory.
;
; INITIAL VERSION: REE 97-03-25
; MODIFICATION HISTORY: 
;			REE 97-07-06 Added spec option.
; Space Sciences Lab, UCBerkeley
; 
;-
pro fa_fields_despin_HG, V58, V14, phase=phase, t1=t1, t2=t2, $
    save_mem=save_mem, spec=spec, nave=nave, slide=slide, $
    nfft=nfft, plot=plot, V14_gain=V14_gain, pole=pole

; Set up constants.
two_pi = 2.d*!dpi
if not keyword_set(V14_gain) then V14_gain=1.0
if n_elements(pole) EQ 0 then pole=200.0
if not keyword_set(V58) AND not keyword_set(V14) AND $
    not keyword_set(phase) then save_mem=1
 
; First set up V58.
IF not keyword_set(V58) then BEGIN
    V58 = get_fa_fields('V5-V8HG_16k',t1,t2,/repair)
    IF V58.valid ne 1 then BEGIN
        message, /info, "Cannot get V5-V8HG_16k. Check SDT setup."
        return
    ENDIF
ENDIF

; Next set up V14.
IF not keyword_set(V14) then BEGIN
    V14 = get_fa_fields('V1-V4HG_16k',t1,t2,/repair)
    IF V14.valid ne 1 then BEGIN
        message, /info, "Cannot get V1-V4_16k. Check SDT setup."
        return
    ENDIF
ENDIF


; Set up the phase.
IF not keyword_set(phase) then BEGIN
    phase = get_fa_fields('SMPhase_1048',/all)
    phase = fa_fields_phase(phase, freq=0.01)
    IF phase.valid ne 1 then BEGIN
        message, /info, "Cannot get 1048 phase. Check SDT setup."
        return
    ENDIF
ENDIF

;
; Begin the combine process. Do not add to structure. Save some space.
; 
time_offset = 0.0d

; Combine V14
fa_fields_combine,V58,V14,result=v14_dat, time_offset=time_offset
if keyword_set(save_mem) then V14 = 0


; Check to see if phases are needed.
fa_fields_combine, V58, phase, result=Bphase, /interp, delt=1000.

; Save some space
start_time = v58.start_time
time = v58.time-start_time
v58_dat = v58.comp1
if keyword_set(save_mem) then v58 = 0

;
; MOVE THE POLE TO 200 Hz.
;
; FIRST REMOVE NANS

dt = 1.d/(32.d*1024.d)
ind = where(finite(v58_dat) EQ 0,nind)
if nind GT 0 then v58_dat(ind) = 0.0
ind = where(finite(v14_dat) EQ 0,nind)
if nind GT 0 then v14_dat(ind) = 0.0
if pole GT 0 then v58_dat = ff_shift_pole(v58_dat, pole, dt) 
if pole GT 0 then v14_dat = ff_shift_pole(v14_dat, pole, dt) 

;
; DO THE DESPIN
;

dphi = 2.d*!dpi*52.02d/360.d
e1 = -v58_dat*cos(Bphase-dphi) - v14_dat*V14_gain*sin(Bphase-dphi)
e2 = -v58_dat*sin(Bphase-dphi) + v14_dat*V14_gain*cos(Bphase-dphi)

; STORE THE DATA IN TPLOT FORMAT
data = {x:time+start_time, y:e1}
store_data,'E_NEAR_B_HG', data=data
dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
          ytitle:'E NEAR B!C!C(mV/m)',$
          panel_size:3}
store_data,'E_NEAR_B_HG', dlimit=dlimit

data = {x:time+start_time, y:e2}
store_data,'E_ALONG_V_HG', data=data
dlimit = {spec:0, ystyle:1, yrange:[-1000.,1000.],  $
          ytitle:'E PERP-SP!C!C(mV/m)',$
          panel_size:3}
store_data,'E_ALONG_V_HG', dlimit=dlimit

if keyword_set(plot) then tplot,['E_NEAR_B_HG','E_ALONG_V_HG']

; 
; OPTIONAL SPECTRA SECTION
;
if not keyword_set(spec) then return

;
; FIRST PARALLEL COMPONENT
;

e16k = {time: time+start_time, units_name: 'mV/m', comp1: e1, valid: 1l,$
        data_name: 'Eparl', project_name: 'FAST', calibrated: 1l}

result = fa_fields_fft(e16k, nave=nave, slide=slide, npts=nfft)

data   = {x:result.time, y:alog10(result.comp1), v:result.yaxis}
store_data,'VLF_EPAR', data=data

options,'VLF_EPAR','spec',1
options,'VLF_EPAR','panel_size',5
options,'VLF_EPAR','ystyle',1
options,'VLF_EPAR','ylog',1
options,'VLF_EPAR','yrange',[0.032, 16.0]
options,'VLF_EPAR','ytitle','LF EnearB!C!C(kHz)'
options,'VLF_EPAR','zstyle',1
options,'VLF_EPAR','zrange',[-14,-4]
options,'VLF_EPAR','ztitle','Log (V/m)!U2!N/Hz'
options,'VLF_EPAR','y_no_interp',1
options,'VLF_EPAR','x_no_interp',1


store_data,'VLF_EPAR_FCH',data=['VLF_EPAR','FCH']
options,'VLF_EPAR_FCH','panel_size',5

;
; NEXT PERP COMPONENT
;

e16k = {time: time+start_time, units_name: 'mV/m', comp1: e2, valid: 1l,$
        data_name: 'Eperp', project_name: 'FAST', calibrated: 1l}

result = fa_fields_fft(e16k, nave=nave, slide=slide, npts=nfft)

data   = {x:result.time, y:alog10(result.comp1), v:result.yaxis}
store_data,'VLF_EPERP', data=data

options,'VLF_EPERP','spec',1
options,'VLF_EPERP','panel_size',5
options,'VLF_EPERP','ystyle',1
options,'VLF_EPERP','ylog',1
options,'VLF_EPERP','yrange',[0.032, 16.0]
options,'VLF_EPERP','ytitle','LF Eperp!C!C(kHz)'
options,'VLF_EPERP','zstyle',1
options,'VLF_EPERP','zrange',[-14,-4]
options,'VLF_EPERP','ztitle','Log (V/m)!U2!N/Hz'
options,'VLF_EPERP','y_no_interp',1
options,'VLF_EPERP','x_no_interp',1


store_data,'VLF_EPERP_FCH',data=['VLF_EPERP','FCH']
options,'VLF_EPERP_FCH','panel_size',5


if keyword_set(plot) then tplot, ['VLF_EPAR_FCH','VLF_EPERP_FCH']
return
end



