;+
;Procedure:
;  thm_crib_esa 
;
;Purpose:
;  Demonstrate how to get, clean and calibrate SCM data
;
;Original authors:
;  K. Bromund
;  O. Le Contel & P. Robert, CETP
;
;See also:
;  thm_crib_fgm
;  thm_crib_fit
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-12-05 10:32:00 -0800 (Mon, 05 Dec 2016) $
; $LastChangedRevision: 22434 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_scm.pro $
;-



;------------------------------------------------------------------------------
; Load level 1 SCM data
;------------------------------------------------------------------------------

;select probe
probe = 'b'

;set time range
trange = ['2007-03-23','2007-03-24']

;load level 1 SCM data
;  -required support data should be loaded automatically (thm_load_state)
thm_load_scm, probe=probe, trange=trange

;print loaded data products
tplot_names, 'th'+probe+'_sc?'

;plot
tplot, 'th'+probe+'_sc?'

stop


;------------------------------------------------------------------------------
; Load level 2 SCM data
;------------------------------------------------------------------------------

;select probe
probe = 'c'

;set time range
trange = ['2007-03-23','2007-03-24']

;load level 2 data products
thm_load_scm, probe=probe, trange=trange, level=2

;print loaded data products
tplot_names, 'th'+probe+'_sc*'

;plot some examples
tplot, 'th'+probe+'_sc?_gsm'

stop


;------------------------------------------------------------------------------
; Calibrate level 1 data
;------------------------------------------------------------------------------

;Load data
;---------

probe = 'd'

trange = '2007-03-23/' + ['13:58:10','14:02:00']

;support data must be loaded explicitly when loading raw level 1 data
thm_load_state, probe=probe, trange=trange, /get_support

;load level 1 SCM data and support data
thm_load_scm, probe=probe, trange=trange, level=1, type='raw', /get_support

;select datatype 
datatype = 'scp'

;get the raw data in volts (step 1 output) 
thm_cal_scm, probe=probe, datatype=datatype, trange=trange, $
             out_suffix = '_volt', $
             step = 1

;rename support data 
hnames = tnames('*_scp_hed_volt')
for i=0,n_elements(hnames)-1 do copy_data, hnames[i], strmid(hnames[i], 0, strlen(hnames[i])-5)
           
;Calibrate
;---------
;  -the default values of parameters are shown
;  -the '*' appended to datatype will get diagnostic parameters (_iano, _dc, _misalign) as well as calibrated output
;  -out_suffix is necessary to get what was former default behavior
;  -the /edge_zero is not a default option, so the output will differ slightly from default
;
;  Cleanup information
;    To perform a full cleanup of spin tones (power ripples) and 8/32 Hz tones --> cleanup ='full'
;    cleanup is based on superposed epoch analysis suggested by C. C. Chaston using an averaging window
;    spin tones cleanup corresponds to an averaging window duration exactly equal to the spin period
;    which is fixed in the code (wind_dur_sp = spinper)
;    8/32 Hz tones cleanup corresponds to an averaging window equal to a multiple of 1s
;    this averaging window duration can be chosen by the keyword wind_dur_1s
;    To perform only a cleanup of spin tones (power ripples) --> cleanup='spin'
;    To perform no cleanup --> comment cleanup keyword

thm_cal_scm, probe=probe, datatype=datatype+'*', out_suffix = '_cal', $
             trange=trange, $
;             nk  = 512, $
;             mk = 4, $
;             Despin=1, $
;             N_spinfit = 2, $
             cleanup = 'full',$
;             clnup_author = 'ole', $
;             wind_dur_1s = 1.,$
;             wind_dur_spin = 1.,$
;             Fdet = 0., $
;             Fcut = 0.1, $
             Fmin = 0.45, $
;             Fmax = 0., $
;             step = 4, $
             /edge_zero

;rename support data 
hnames = tnames('*_hed_cal')
for i=0,n_elements(hnames)-1 do copy_data, hnames[i], strmid(hnames[i], 0, strlen(hnames[i])-4)
             
;Plot
;---------

varname = 'th'+probe+'_'+datatype

;label the plot with calibration parameter string from metadata
get_data, varname+'_cal', dl = dl

;set plotting options
tplot_options, 'charsize',0.7
tplot_options, 'title', 'SCM calibrated data'
tplot_options, 'subtitle', dl.data_att.str_cal_param

;plot calibrated data
tplot, varname+'_cal', trange=trange

stop


;set plotting options for diagnostic output
tplot_options, 'title', 'SCM calibrated data and diagnostic outputs'
tplot_options, 'subtitle', ''
options, varname+'_iano',psym=2

;plot diagnostic ouput
;  -the raw signal in volts
;  -the raw signal after despin, before cleanup
;  -the raw signal after despin, spin cleanup
;  -the raw signal after despin, spin cleanup and 8/32Hz cleanup
;  -the misalignment angle between the SCM spin-plane antennas
;  -the DC signal removed in the despin step
;  -the anomaly code

tplot, [varname+'_[cidmv]*'], trange=trange

stop


;------------------------------------------------------------------------------
; Load data which shows SCM onboard calibration signal
;------------------------------------------------------------------------------

trange = '2007-03-14/' + ['14:47:52', '14:49:20']
probe = 'd'
datatype = 'scp'

;load level 1 data
thm_load_scm, probe=probe, datatype=datatype+'*', trange=trange, $
              suffix = '_cal', $
              level=1

;plot the SCM self-calibration signal
;  -the signal stops at about 14:49:01    
tplot, 'th'+probe+'_scp_cal', trange=trange

stop


;------------------------------------------------------------------------------
; Show calibration signal in SCS (SCM Sensor) coordinates
;------------------------------------------------------------------------------

trange = '2007-03-14/' + ['14:47:52', '14:49:20']
probe = 'd'
datatype = 'scp'

;support data must be loaded explicitly when loading raw level 1 data
thm_load_state, probe=probe, /get_support_data

;load level 1 raw data
thm_load_scm, probe=probe, datatype=datatype+'*', level=1, type='raw', /get_support, $
             trange=trange

;apply calibrations
thm_cal_scm, probe=probe, datatype=datatype+'*', out_suffix = '_s3', $
             trange=trange, $
             step = 3, $
             /edge_zero

;set plotting options
str_Fsamp = string(dl.data_att.Fsamp ,format='(f5.0)')
options, 'thd_scp_s3', 'ytitle', 'thd scp scs!C'+str_Fsamp+'!C[nT]'
tplot_options, 'title', 'SCM self-calibration signal'

;plot
tplot, ['thd_scp','thd_scp_cal', 'thd_scp_s3']

stop


;zoom in even closer to see the triangle wave
tlimit, ['2007-03-14/14:48:30', '2007-03-14/14:48:31']

stop


end
