pro wavelet_python_validate
; Generate test data for Python vs IDL validation tests for wavelet routine

; Test case 1: simple example from wiki

; Set standard colormap for spectrogram plots

thm_init
; Create a tplot variable that contains a wave.
t =  FINDGEN(4000)
time = time_double('2010-01-01') + 10*t
data = sin(2*!pi*t/32.)
data2 = sin(2*!pi*t/64.)
data[1000:3000] = data2[1000:3000]
var = 'sin_wav'
store_data, var, data={x:time, y:data}

; Apply wavelet transformation.
wav_data, var

; Plot the wave and the result of the transformation.
pvar = 'sin_wav_wv_pow'
tplot, [var, pvar]
stop

; Test case 2: adapted from a homework assignment from Vassilis' class

tplot_options, 'xmargin', [15,9]
tplot_options, 'ygap', 0.
options,'*','databar',0

; constants
pi=!PI ; !PI not allowed in calc, so write it into a variable
mu0=4*!PI*1.e-7
Re=6378. ;

; define timerange
timespan,'2008-09-05/08:00:00',12,/hours

; load data
thm_load_state, probe='a', /get_support
thm_load_fgm, probe='a', datatype = 'fgs', level='l2', coord = 'gsm'
thm_load_fgm, probe='a', datatype = 'fgs', level='l2', coord = 'dsl'
tplot, 'tha_fgs_gsm tha_fgs_dsl'

; degap
; remove the spike around 10:23
time_clip, 'tha_fgs_gsm', '2008-09-05/10:22:30', '2008-09-05/10:23:30', /interior_clip, /replace
tdegap,'tha_fgs_gsm',/overwrite
tdeflag,'tha_fgs_gsm','linear',/overwrite
tplot, 'tha_fgs_gsm'

time_clip, 'tha_fgs_dsl', '2008-09-05/10:22:30', '2008-09-05/10:23:30', /interior_clip, /replace
tdegap,'tha_fgs_dsl',/overwrite
tdeflag,'tha_fgs_dsl','linear',/overwrite
tplot, 'tha_fgs_gsm tha_fgs_dsl', title='remove spike'

stop
; ======================================================
;     I. band-pass filter
; ======================================================
; get time resolution
tres, 'tha_fgs_gsm', tresol
fmin = 1/180.
fmax = 1/15.

; first method to do band pass filter
tsmooth2, 'tha_fgs_gsm', ceil(1/fmin/tresol)+1, newname = 'tha_fgs_gsm_lp' ; lowpass: allow <fmax Hz pass thru, 61 points
calc, "'tha_fgs_gsm_hp' = 'tha_fgs_gsm' - 'tha_fgs_gsm_lp'" ; obtain highpass (>fmin Hz) by subtracting lowpass from original data
tsmooth2, 'tha_fgs_gsm_hp', ceil(1/fmax/tresol), newname = 'tha_fgs_gsm_bp' ; second lowpass to obtain fmin<data<fmax bandpass, 5 points
tplot, 'tha_fgs_gsm_bp', title='TH-A FGS Data in GSM Coordinates (Band-pass filtered: 1/180 Hz to 1/15 Hz)'

stop

; second method to do band pass filter
get_data,'tha_fgs_gsm',data=tha_fgs_gsm,dlim=dlim,lim=lim
tha_fgs_gsm_ft = time_domain_filter(tha_fgs_gsm, fmin,fmax) ;
store_data,'tha_fgs_gsm_bp2',data=tha_fgs_gsm_ft,dlim=dlim,lim=lim

; compare two methods
tplot, 'tha_fgs_gsm_bp tha_fgs_gsm_bp2'
stop

; ======================================================
;     II. dynamic power spectrum
; ======================================================

tdpwrspc, 'tha_fgs_gsm', newname='tha_fgs_gsm_dpwrspc'  ; compute dynamic power spectrum
tplot, 'tha_fgs_gsm_?_dpwrspc', title='Dynamic Power Spectrum of TH-A FGS Data in GSM Coordinates'

stop
; ======================================================
;     III. transform to FAV coordinate
; ======================================================
;
; we do coordinate transformation in dsl coordinates
tsmooth2, 'tha_fgs_dsl', ceil(1/fmin/tresol)+1, newname = 'tha_fgs_dsl_lp' ; lowpass: allow <fmax Hz pass thru, 61 points
calc, "'tha_fgs_dsl_hp' = 'tha_fgs_dsl' - 'tha_fgs_dsl_lp'" ; obtain highpass (>fmin Hz) by subtracting lowpass from original data
tsmooth2, 'tha_fgs_dsl_hp', ceil(1/fmax/tresol), newname = 'tha_fgs_dsl_bp' ;second lowpass to obtain fmin<data<fmax bandpass, 5 points

; smooth the Bfield data to get the background field
tsmooth2, 'tha_fgs_dsl', 20*10.0, newname = 'tha_fgs_dsl_sm'  ; 10 min average

; generate transformation matrix
;thm_fac_matrix_make,'tha_fgs_dsl_sm',other_dim='mRgeo',pos_var_name='tha_state_pos',newname='tha_fgs_dsl_sm_fac_mat'  ; generate rotation matrix
thm_fac_matrix_make,'tha_fgs_dsl_sm',other_dim='Xgse',pos_var_name='tha_state_pos',newname='tha_fgs_dsl_sm_fac_mat'  ; generate rotation matrix


; transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'tha_fgs_dsl_sm_fac_mat', 'tha_fgs_dsl_bp', newname='tha_fgs_fac_bp'   ;
options, 'tha_fgs_fac_bp', ytitle='tha_fgs_fac_bp', ysubtitle='[nT FAC]'
tplot, ['tha_fgs_dsl_bp', 'tha_fgs_fac_bp'], title='TH-A FGS Data in Field-Aligned Coordinates'

stop

; ======================================================
;     IV. power spectra of three components
; ======================================================

split_vec, 'tha_fgs_fac_bp'  ; split vector into X (radially inward), Y (azimuthal, westward), Z (field-aligned) components
tplot, ['tha_fgs_fac_bp_x', 'tha_fgs_fac_bp_y', 'tha_fgs_fac_bp_z']
stop

; wavelet method
wav_data, 'tha_fgs_fac_bp_x'  ; dpwrspec of radial component
wav_data, 'tha_fgs_fac_bp_y'  ; dpwrspec of azimuthal component
wav_data, 'tha_fgs_fac_bp_z'  ; dpwrspec of field-aligned component
zlim, 'tha_fgs_fac_bp_?_wv_pow', 1.0e-1,1.0e2, 1
ylim,'tha_fgs_fac_bp_?_wv_pow', 1.0e-3,4.1e-2, 0  ; y axis in linear to be consistent with Sarris. 2010

tplot, 'tha_fgs_fac_bp_?_wv_pow', title = 'Dynamic Power Spectrum with wavelet'
stop

; Run Torrence and Compo's 'wavetest' example, and save the resulting tplot variable wavetest_oowspec for the power spectrum.

wavetest

; Save input and output variables for Python validation

varnames = ['sin_wav', 'sin_wav_wv_pow',$
  'tha_fgs_fac_bp_x', 'tha_fgs_fac_bp_y', 'tha_fgs_fac_bp_z', 'tha_fgs_fac_bp_x_wv_pow', 'tha_fgs_fac_bp_y_wv_pow', 'tha_fgs_fac_bp_z_wv_pow',$
  'wavetest_powspec']
  
tplot_save,varnames,filename='wavelet_test'
end