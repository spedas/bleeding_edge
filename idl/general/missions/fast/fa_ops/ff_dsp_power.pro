;+
; PROCEDURE: FF_DSP_POWER, f_range=f_range  
;
; PURPOSE: 
;  computes integrated spectral density in a given frequency interval
;  using DSP electric and magnetic field data and stores it in TPLOT
;  variables.
;
; INPUT: 
; DSP data is assumed to be stored in TPLOT 
; (DSP_OMNI and DSP_Mag3ac); 
; run FA_FIELDS_DSP prior to running this procedure.
;
; KEYWORDS: 
;   f_range
;   float[ 2], Optional frequency range for integration, kHz
;   (default: 3-16.5 kHz).
;
;   store
;   if set, store integrated spectral density as a TPLOT quantity.
;   if set to a string, use that string as the name of the TPLOT quantity.
;
;   mag
;   if set, compute integrated spectral density of the magnetic field
;   using Mag3ac data.
;
; CALLING SEQUENCE: FF_DSP_POWER
;
; OUTPUT: Stored in tplot (default names: DSP_POWER and DSP_MAG_POWER).
;
; NOTES
;  Integrated spectral density of the electric field is stored in (V/m)^2.
;  Integrated spectral density of the magnetic field is converted 
;  to energy density (joule/m^3 = B^2/(2*mu_0)) before storage.
;
; INITIAL VERSION: REE 99-01-13
; MODIFICATION HISTORY: 
; Space Sciences Lab, UCBerkeley
; 
;-

pro ff_dsp_power, f_range=f_range, mag=mag, power=power, store=store

;
; DO MAG CASE FIRST
;
IF keyword_set(mag) then BEGIN

    ; GET THE DATA
    get_data, 'DSP_Mag3ac', data=data

    ; CHECK F_RANGE KEYWORD
    if not keyword_set(f_range) then f_range = [3.000, 16.5]
    mu0 = 4.0*!pi*1.e-7
    c = 3.0e8

    ; SET START AND STOP
    df = data.v(1) - data.v(0)
    start = long((f_range(0))/df + 0.5) > 0
    stop  = long((f_range(1))/df + 0.5) > 0
    start = start < (n_elements(data.v)-1)
    stop  = stop < (n_elements(data.v)-1)

    ; CALCULATE POWER
    power = fltarr(n_elements(data.x))*!values.f_nan
    for i=0, n_elements(data.x)-1 do $
        power(i) = total(10.0^(data.y(i,start:stop)))*df*0.5e-18/mu0

    ; SHIFT POWER TO CORRECT TIMING ERROR
    power = [power(1:*),0]

    ; STORE THE RESULTS IN TPLOT
    IF keyword_set(store) then BEGIN
        data = {x:data.x, y:power}
        store_data, 'DSP_MAG_POWER', data=data
        options,'DSP_MAG_POWER','spec',0
        options,'DSP_MAG_POWER','panel_size',4
        ff_ylim, 'DSP_MAG_POWER',[1.0e-18,1.0e-10], /log
        options,'DSP_MAG_POWER','ytitle','B Energy Density!C!CLog (J/m!U3!N)'
    ENDIF


    return
ENDIF

;
; DO E-FIELD
;

; GET THE DATA
get_data, 'DSP_OMNI', data=data

; CHECK F_RANGE KEYWORD
if not keyword_set(f_range) then f_range = [3.000, 16.5]

; SET START AND STOP
df = data.v(1) - data.v(0)
start = long((f_range(0))/df + 0.5) > 0
stop  = long((f_range(1))/df + 0.5) > 0
start = start < (n_elements(data.v)-1)
stop  = stop < (n_elements(data.v)-1)

; CALCULATE POWER
power = fltarr(n_elements(data.x))*!values.f_nan
for i=0, n_elements(data.x)-1 do $
    power(i) = total(10.0^(data.y(i,start:stop)))*df*32.0

; SHIFT POWER TO CORRECT TIMING ERROR
power = [power(1:*),0]

; STORE THE RESULTS IN TPLOT
IF keyword_set(store) then BEGIN
    data = {x:data.x, y:power}
    if data_type(store) EQ 7 then name = store else name = 'DSP_POWER'
    store_data, name, data=data
    options, name,'spec',0
    options, name,'panel_size',4
    options, name,'ytitle','LF Power!C!CLog (V/m)!U2!N'
    ff_ylim, name,[1.0e-8,1.0e-0], /log
ENDIF

return
end
