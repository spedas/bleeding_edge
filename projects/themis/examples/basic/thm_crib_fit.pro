;+
;	Batch File: THM_CRIB_FIT
;
;	Purpose:  Demonstrate the loading, calibration, and plotting
;		of THEMIS FIT (On-Board E- and B-Field SpinFit) data.
;
;	Calling Sequence:
;	.run thm_crib_fit, or using cut-and-paste.
;
;	Arguements:
;   None.
;
;	Notes:
;   Disable print statements by calling "dprint,setdebug=-1" before running the crib
;
;Written by John Bonnell
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-03-03 15:44:21 -0800 (Tue, 03 Mar 2015) $
; $LastChangedRevision: 17074 $
; $URL $
;-

dprint, "--- Start of crib sheet ---"
;------------------------------------------------------------------------------
; FIT On-Board SpinFit data basic example.
;------------------------------------------------------------------------------
;
; set a few TPLOT options.
tplot_title = 'THEMIS FIT On-Board Spin Fit Examples'
tplot_options, 'title', tplot_title
tplot_options, 'xmargin', [ 15, 10]
tplot_options, 'ymargin', [ 5, 5]

; set the timespan and load the FIT data.
;timespan, '2007-06-30', 1.0, /day
timespan, '2008-05-15', 1.0, /day

thm_load_fit, level=1,datatype=['efs', 'fgs'],/verbose

; set the color table.
loadct2, 39

; the FIT data, as loaded by THM_LOAD_FIT isn't very usable or viewable,
; so run THM_CAL_FIT to break out the E and B fits with useful plotting options.

; plot the calibrated FIT data.
tplot, ['thc_efs', 'thc_fgs']

dprint, 'at each stop point type .c to continue with the crib'

stop

;tlimit, ['2007-06-30/00:45:00', '2007-06-30/16:30:00']
tlimit, ['2008-05-15/10:00:00', '2008-05-15/14:00:00']

dprint, 'now we zoomed in'


stop

tplot, 'th?_fgs th?_efs'

dprint, 'all probes plotted.' 
; Note only probes Charley, Delta, Echo have '
;print, 'booms deployed for good E-Field data.'

stop

;------------------------------------------------------------------------------
;Coordinate Transform
;------------------------------------------------------------------------------

thm_load_state, /get_support_data

thm_cotrans, 'th?_??s', out_suffix='_gsm', out_coord='gsm'

tplot, [ 'thc_efs',     'thc_fgs', $
         'thc_efs_gsm', 'thc_fgs_gsm']

dprint, 'we transformed both efs and fgs to gsm, adding _gsm suffix to result'
stop

thm_load_fit, level=1,datatype=['efs', 'fgs'], coord='gsm', suffix='_gsm'

tplot, [ 'thc_efs',     'thc_fgs', $
         'thc_efs_gsm', 'thc_fgs_gsm']

dprint, 'you can get the same result (with better plot labels) if you load'
dprint, 'specify the coord keyword to thm_load_fit.'
stop

;------------------------------------------------------------------------------
;Level 2 data
;------------------------------------------------------------------------------

thm_load_fgm, datatype=['fgs'],/verbose,  suffix='_l2', level = 'l2'

thm_load_efi, datatype=['*efs'],/verbose, suffix='_l2', level= 'l2'

tplot, ['thc_fgs',  'thc_fgs_dsl_l2','thc_efs','thc_eff_e12_efs_l2']

dprint, 'now we loaded the same data from level 2.'  

dprint, 'Note that the l2 FGM data has a suffix to designate the coordinate.  '

stop

;------------------------------------------------------------------------------
; Examples showing use of eclipse spin model corrections for FIT data
;------------------------------------------------------------------------------
;
; THB passed through a lunar shadow during this flyby.  The eclipse
; occurs between approximately 0853 and 0930 UTC.

timespan,'2010-02-13/08:00',4,/hours

; 2012-08-03: By default, the eclipse spin model corrections are not
; applied. For clarity, we'll explicitly set use_eclipse_corrections to 0
; to get a comparison plot, showing how the lack of eclipse spin model
; corrections induces an apparent rotation in the data.

thm_load_fit,probe='b',level=1,type='calibrated',suffix='_before',use_eclipse_corrections=0

; Here we load the same data, but enable the full set of eclipse spin
; model corrections by setting use_eclipse_corrections to 2.  
;  
; use_eclipse_corrections=1 is not recommended except for SOC processing.
; It omits an important spin phase offset value that is important
; for data types that are despun on board:  particles, moments, and
; spin fits.
;
; Note that calibrated L1 data must be requested in order to use
; the eclipse spin model corrections.  The corrections are not
; yet enabled in the L1->L2 processing.

thm_load_fit,probe='b',level=1,type='calibrated',suffix='_after',use_eclipse_corrections=2

; Plot the data to compare the results before and after the eclipse
; spin model corrections have been applied.  In the uncorrected
; data, the field is clearly rotating in the spin plane, due to
; the spin-up that occurs during the eclipse as the probe and
; booms cool and contract.
;
; The corrections are applied to both EFS and FGS, but the
; effect is much more visible in FGS, so I just plotted that.

tplot,['thb_fgs_before','thb_fgs_after']

dprint, "This plot shows the effect of enabling the eclipse spin model"
dprint, "corrections on FIT (FGS and EFS) data.  The variables with "
dprint, "suffix _before have not had the corrections applied, while"
dprint, "the variables with suffix _after use the eclipse corrections."
dprint, "Without the corrections, a spin phase offset and slow rotation"
dprint, "are visible in the data during the eclipse (0853-0930 UTC), due "
dprint, "to the spin-up that occurs as the probe and booms cool and contract."
dprint, " "
dprint, "--- End of crib sheet ---"
end
