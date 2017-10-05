;+
;	Batch File: THM_CRIB_FFT
;
;	Purpose:  Demonstrate the loading, calibration, and plotting
;		of THEMIS FFT spectra (ParticleBurst and WaveBurst) data
;
;	Calling Sequence:
;	.run thm_crib_fft, or using cut-and-paste.
;
;	Arguements:
;   None.
;
;	Notes:
;	Disable print statements by calling "dprint,setdebug=-1" before running the crib
;	
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-03-03 15:27:10 -0800 (Tue, 03 Mar 2015) $
; $LastChangedRevision: 17071 $
; $URL $
;-


;------------------------------------------------------------------------------
; FFT FilterBank data load example.
;------------------------------------------------------------------------------

dprint, "--- Start of crib sheet ---"
;start with a clean slate
del_data, '*'

dprint, 'at each stop point type .c to continue with the crib'

stop

; FFT On-Board SpinFit data example.

; set a few TPLOT options.
tplot_title = 'THEMIS FFT Example'
tplot_options, 'title', tplot_title
tplot_options, 'xmargin', [ 15, 10]
tplot_options, 'ymargin', [ 5, 5]

; set the timespan
timespan, '2007-06-23'

;loads all the available data from the day and calibrates it.
;defaults to load l1 data, as l2 quantities are not available at the
;time of this crib's creation
thm_load_fft

;list the available data

tplot_names

dprint, 'heres a list of the data variables we just got'
dprint, 'fft actually has 4 spectral channels, so '
dprint, 'when the data is calibrated a suffix is added to the end'

stop

;------------------------------------------------------------------------------
; Plot the loaded data
;------------------------------------------------------------------------------

;particle burst data from themis A at 16 frequency samples spectra scm2

tplot, 'thc_ffp_16_scm2'

dprint, 'We just plotted the calibrated particle burst data from themis charlie'
dprint, 'This plot is of spectra scm2 at 16 frequency samples'

stop

;------------------------------------------------------------------------------
; Zoom in/out, because particle burst data as very narrow time windows
;------------------------------------------------------------------------------

tlimit, '2007-06-23/07:31:47', '2007-06-23/07:32:20'

dprint, 'now we zoom in'

stop

tlimit, '2007-06-23/00:00:00', '2007-06-24/00:00:00'

dprint, 'now we zoom out'

dprint, 'Note: the plot must be zoomed in quite a bit to see what is going on in the data.  This is typical for most of the fft data.' 

dprint,'If you want to zoom in using the mouse, call the tlimit routine with no arguments(ie "tlimit"). This can be useful for adjusting viewing fft data.'

dprint,'If you want try typing "tlimit" now and using the mouse to zoom in'

stop

;------------------------------------------------------------------------------
; Return a list of valid datatypes/probes
;------------------------------------------------------------------------------

;clear the data

del_data, '*'

;get lists of valid choices for probe and datatypes
thm_load_fft, probe = p,datatype = d, /valid_names

dprint,'Datatypes: ', transpose(d)
dprint,'Probes: ', p
dprint, 'Here is a list of the valid datatype, probe, and level choices we can make'
dprint, 'For FFT not all datatypes will be valid at all times.'

stop

;------------------------------------------------------------------------------
; Load specific datatype and probes
;------------------------------------------------------------------------------


thm_load_fft, probe = ['b','c'], datatype = 'ffw_16_edc34'

tplot_names

tplot, ['thb_ffw_16_edc34', 'thc_ffw_16_edc34']

tlimit, '2007-06-23/07:31:47', '2007-06-23/07:32:20'

dprint, 'just got the waveburst data for themis beta and' 
dprint, 'charlie at 16 frequency samples and plotted them'

stop

;------------------------------------------------------------------------------
; Load support data
;------------------------------------------------------------------------------

;now we load some probe b data with its support data

del_data, '*'

thm_load_fft, probe = 'b', /get_support_data

;and load the uncalibrated data too
thm_load_fft, probe = 'b'

tplot_names

tplot, ['thb_ff?_??_*', 'thb_ff?_??'] 

dprint, 'we just loaded calibrated science data,raw science data, and support data for probe b'

dprint, 'and plotted it(minus the support data which doesnt really plot)'

dprint, 'Note the use of ? wildcards'

stop

;------------------------------------------------------------------------------
; Plot with wave and particle burst together
;------------------------------------------------------------------------------

tplot, ['thb_ffp_16_scm2', 'thb_ffw_16_scm2']

dprint, 'here is some particle burst and wave burst data on the same plot'

stop

dprint, "--- End of crib sheet ---"

end
