;+
;
;NAME:
; thm_crib_twavpol_scm
; 
;Purpose:
; Demonstrate the usage of the wave polarization routines
; for SCM data in magnetic field aligned coordinates.
; 
;NOTES:
;  Shortened version of Olivier Le Contel's <olivier.lecontel@lpp.polytechnique.fr> wave polarization
;  crib(scm_mfa_wpol_ole_fc_crib.pro)
;  Edited for clarity, minor updates - 2016-06-17 af
;
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2016-06-17 16:55:39 -0700 (Fri, 17 Jun 2016) $
; $LastChangedRevision: 21338 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_twavpol_scm.pro $
;-


;===============================================
; 1) Select date, data type, and time interval
;===============================================

  date = '2008-02-26'
  timespan,date,1,/day

;; Select satname
  satname ='d'
;; Select MODE (scf, scp, scw)
  mode = 'scf'
  thscs_mode = 'th'+satname+'_'+mode
;; Select FGM_MODE (fgl or fgh)  
  fgm_mode = 'fgl'
  thscs_fgm_mode ='th'+satname+'_'+fgm_mode+'_dsl'


;; If you want to set up a limited timespan for calibration,
;; you set up a trange array like this:
;; To impose by hand t1 and t2 :

  ;20080129
   ;starting_time='02:24:00.0'
   ;ending_time  ='02:28:00.0'

  ;20080226
  ;scf
   starting_time='04:30:00.0'
   ending_time  ='05:30:00.0'
  ;scp
   ;starting_time='04:50:00.0'
   ;ending_time  ='05:09:00.0'
  ;scw 
   ;starting_time='04:54:49.0'
   ;ending_time  ='04:54:58.0'
   
  ;20070508
  ;thc in scf mode
   ;starting_time='03:32:00.0'
   ;ending_time  ='04:42:00.0'
   
  trange = [date+'/'+starting_time, $
            date+'/'+ending_time]


;===============================================
; 2) Load FGM and ephemeris support data
;===============================================


thm_load_state, probe=satname, /get_support_data

thm_load_fgm,level=2,probe=satname,datatype=fgm_mode,coord='dsl'

;calculate field magnitude from FGM vector
split_vec, thscs_fgm_mode
calc_string = '"'+thscs_fgm_mode+'_m" = sqrt(total("' + thscs_fgm_mode + '"^2,2))'

;example of what the calc call will look like with string names filled in
;calc,'"thd_fgl_m" = sqrt(total("thd_fgl_dsl"^2,2))

dprint, "Making call to calc: " + calc_string
calc,calc_string,/verbose

;tdotp,thscs_fgm_mode+'_'+coord,thscs_fgm_mode+'_'+coord,newname=thscs_fgm_mode+'_m'
;get_data,thscs_fgm_mode+'_m',data=mod2
;store_data,thscs_fgm_mode+'_m',data={x:mod2.x,y:sqrt(mod2.y)}


;==============================================================================
; 3) Get SCM data and SCM header file for customized and diagnostic calibration
;==============================================================================

;; get data within the specified time range

thm_load_scm,probe=satname, level=1,  type='raw',$
			    trange=trange,$
			    /get_support

;; default values of parameters are shown.
;; the '*' appended to mode will get diagnostic parameters
;; (_iano, _dc, _misalign) as well as calibrated output.  Note out_suffix
;; is necessary to get what was former default behavior (_cal on output)
;; To run with different parameters, uncomment and change as you like.
;; Note: the /edge_zero is not a default option, so the output will differ
;; slightly from step 4a) above.

;; Cleanup informations
;; To perform a full cleanup of spin tones (power ripples) and 8/32 Hz tones --> cleanup ='full'
;; cleanup is based on superposed epoch analysis suggested by C. C. Chaston using an averaging window
;; spin tones cleanup corresponds to an averaging window duration exactly equal to the spin period
;; which is fixed in the code (wind_dur_sp = spinper)
;; 8/32 Hz tones cleanup corresponds to an averaging window equal to a multiple of 1s
;; this averaging window duration can be chosen by the keyword wind_dur_1s
;; To perform only a cleanup of spin tones (power ripples) --> cleanup='spin'
;; To perform no cleanup --> comment cleanup keyword

; SCM data
Fmin=0.45
Fmax = 0.

thm_cal_scm, probe=satname, datatype=mode+'*', out_suffix = '_cal', $
             trange=trange, $
;             nk  = nk_input, $
;             mk = 4, $
;             Despin=1, $
             N_spinfit = 1, $
;		          clnup_author = 'ole',$
; 	          cleanup = cleanup_input,$
; 	          wind_dur_spin = 0.5,$
;	            wind_dur_1s = 1.,$
;             Fdet = Fdet, $
;             Fcut = 0.1, $
             Fmin = Fmin, $
             Fmax = Fmax, $
             step = 5, $
             Fsamp=Fsamp,$
             /edge_zero


;===============================================
; 4) Magnetic field-aligned calculations
;===============================================

;Transform into Xgse field aligned coordinates built from time averaged fgm data.
time_av = 3.
avg_data,thscs_fgm_mode,time_av,newname=thscs_fgm_mode+'_av'
tinterpol_mxn,thscs_fgm_mode+'_av',thscs_fgm_mode

;-------------------------------------------------
; This transformation is only valid for data in the 
; same coordinates as the input to thm_fac_matrix_make!
;-------------------------------------------------
thm_fac_matrix_make, thscs_fgm_mode+'_av_interp'
tvector_rotate, thscs_fgm_mode+'_av_interp_fac_mat',thscs_mode+'_cal'

scm_wave = thscs_mode+'_cal_rot'

;clip data into specified range
time_clip,scm_wave,trange[0],trange[1],/replace


;===============================================
; 5) Polarization Analysis
;===============================================
if mode eq 'scf' then nopfft_input     = 32
if mode eq 'scp' then nopfft_input     = 512
if mode eq 'scw' then nopfft_input     = 1024

;-------------------------------------------------
;Warning:
;twavpol/wavpol gives power spectrum in arbitary units,
;this may complicate comparison with other data types(ie onboard FFT).
;-------------------------------------------------
steplength_input = nopfft_input/2
twavpol,scm_wave, error=error, freqline = freqline, timeline = timeline,nopfft=nopfft_input,steplength=steplength_input


;===============================================
; 6) Plot calibrated data, with time in second
;===============================================


tplot_options,'region',[0.,0.,1.,1.]
tplot_options,'charsize',1.


freq_min = Fmin
if mode eq 'scw' then freq_min = 8.

if mode eq 'scf' then freq_max = 4.
if mode eq 'scp' then freq_max = 64.
if mode eq 'scw' then freq_max = 4096.

n_yaxis = 0
if mode eq 'scw' then n_yaxis = 1

ylim,scm_wave +'_powspec',freq_min,freq_max,n_yaxis
ylim,scm_wave +'_degpol',freq_min,freq_max,n_yaxis
ylim,scm_wave +'_waveangle',freq_min,freq_max,n_yaxis
ylim,scm_wave +'_elliptict',freq_min,freq_max,n_yaxis
ylim,scm_wave +'_helict',freq_min,freq_max,n_yaxis


options,thscs_fgm_mode+'_x',ytitle='Bx!C'
options,thscs_fgm_mode+'_y',ytitle='By!C'
options,thscs_fgm_mode+'_z',ytitle='Bz!C'

options,thscs_fgm_mode+'_m','ytitle','B !C!C'
options,thscs_fgm_mode+'_m','color',0
options,thscs_fgm_mode+'_m',labels=['Bt']

options,scm_wave,ytitle='scm !C!C [nT fac]'

options,scm_wave +'_powspec',ztitle='Arbitrary units'
options,scm_wave +'_degpol',ztitle='Deg. Pol.'
options,scm_wave +'_waveangle',ztitle='Wave !C Angle'
options,scm_wave +'_elliptict',ztitle='Ellipticity'
options,scm_wave +'_helict',ztitle='helicity'

options,scm_wave +'_powspec',ytitle='f [Hz]'
options,scm_wave +'_degpol',ytitle='f [Hz]'
options,scm_wave +'_waveangle',ytitle='f [Hz]'
options,scm_wave +'_elliptict',ytitle='f [Hz]'
options,scm_wave +'_helict',ytitle='f [Hz]'

zmin = 1.e-6
zmax = 1.e-2
if mode eq 'scw' then zmin = 1.e-16
if mode eq 'scw' then zmax = 1.e-8

zlim,scm_wave+'_powspec',zmin,zmax,1

tplot,[$
	 thscs_fgm_mode+'_x'$
	,thscs_fgm_mode+'_y'$
	,thscs_fgm_mode+'_z'$
	,thscs_fgm_mode+'_m'$
	, scm_wave $
	,scm_wave+'_powspec' $   
	,scm_wave+'_degpol' $    
	,scm_wave+'_waveangle' $ 
	,scm_wave+'_elliptict' $ 
	,scm_wave+'_helict' $ 
	]
tlimit, trange

end