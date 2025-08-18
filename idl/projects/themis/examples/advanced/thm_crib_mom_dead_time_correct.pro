;+
;Name:
;  thm_crib_mom_dead_time_correct
;
;Purpose:
;  Example for use of dead time corrections for on-board moments
;  calculated from ground-based moments.
;
;Notes:
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2017-01-10 11:21:27 -0800 (Tue, 10 Jan 2017) $
;$LastChangedRevision: 22562 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_mom_dead_time_correct.pro $
;-


;Set time span and load on-board moments
;------------------------------------------------------------------
; As of 7-Nov-2014, dead time correction is no longer the default
; for L1 or L2 data, and the /no_dead_time_correction keyword is
; no longer valid.  To enable dead time correction:
;   /dead_time_correct: If set, then calculate dead time correction
;                       based on ESA moments
;            
;
;------------------------------------------------------------------

; As of 7-November-2014, the dead-time correction is no longer the
; default for any load of L1 or L2 moment data. The corrections that
; were included in L2 cdf files are no longer there. All of the
; load_mom commands will work for both L1 and L2

;set time range
timespan, '2011-05-05', 1

;load data
thm_load_mom,  probe = 'b'

;Calculate dead time correction
;------------------------------------------------------------------
;The program THM_APPLY_ESA_MOM_DTC applies a dead time correction to
;On-board ESA moments (TH?_PE?M variavbles) using ground-calculated
;ESA moments, in the program THM_ESA_DTC4MOM. Each ESA ground moment
;is calculated twice, once with no dead-time correction, and once with
;a dead-time correction. The on-board moment is then multiplied by the
;ratio of (dead-time-corrected moment)/(non-dead-time-corrected
;moment). This process can take a while, since the ESA ground moments
;are calculated twice:

;1) Load ESA data, the default is to use full-mode data, but other
;modes can by set using the use_esa_mode keyword to 'f', 'r', or 'b'

;2) Alter the appropriate ESA 3d data structures by setting the dead
;time correction paramater 'DEAD' to 0.

;3) Calculate the moments, as if there is no dead time correction:
;['density', 'flux', 'mftens', 'eflux', 'velocity', 'ptens', 'ptot']
;are the moments calculated.

;4) Reset the DEAD parameter in the 3d data structure to it's original
;value (1.7e-7 it the typical value).

;5) Re-calculate the moments, as if there is a dead time correction,

;6) Obtain the dead-time correction variables for the moments by
;dividing the 'corrrected' variables from step 5 by the 'uncorrected'
;variables from step 3. Now you have a bunch of variables with names
;like: 'thb_peif_density_dtc', or 'thb_peem_velocity_dtc'

;Once THM_ESA_DTC4MOM is finished, the '*_dtc' variables are
;interpolated to the times of the appropriate on-board moments. After
;this step, the on-board moments are multiplied by the dead-time
;corrections and we now have corrected moments.

;the /save_esa keyword saves the ESA variables containing the
;dead-time corrections.
;------------------------------------------------------------------

;calculate dead time corrections
thm_apply_esa_mom_dtc, probe = 'b'

;The moments for density, flux, mftens, eflux, velocity, ptens and
;ptot are corrected for dead time.

;plot some dead time corrections:
tplot, 'thb_pe?f_density_dtc'

stop

;The default behavoir is to overwrite the uncorrected variable, and
;add a tag in its dlimits.data_att structure to alert the correction
;program that the data has already been corrected. So that if you run
;it again, nothing happens, because the data has been corrected.
thm_apply_esa_mom_dtc, probe = 'b'

stop

;If you want to compare corrected with uncorrected values, use the
;out_suffix keyword, this will avoid overwriting the MOM variables:
;------------------------------------------------------------------

;start over, though because the variables are corrected
del_data, '*'

;load data
thm_load_mom,  probe = 'b'

;apply correction
thm_apply_esa_mom_dtc, probe = 'b',  out_suffix = '_corrected'

;plot
tplot,  'thb_pe?m_density*'

stop

;Using the out_suffix keyword, you can also compare different options
;for the correction. As mentioned above, the default is to use ESA
;full-mode data, you can change this using the 'use_esa_mode' keyword
;------------------------------------------------------------------

thm_apply_esa_mom_dtc,  probe = 'b', use_esa_mode = 'r', out_suffix = '_corrected_r'

tplot,  'thb_peim_density*'

stop

tplot, 'thb_pei?_density_dtc*'   ;to compare the different corrections

stop

;The default is to not include corrections for the spacecraft
;potential in the moments when calculating the _dtc variables (because
;photoelectrons affect the dead time). To add sc potential
;corrections, set the /scpot_correct keyword
;------------------------------------------------------------------
thm_apply_esa_mom_dtc,  probe = 'b', /scpot_correct, out_suffix = '_corrected_scpot'

tplot,  'thb_peim_density*'

stop

tplot, 'thb_pei?_density_dtc*'   ;to compare the different corrections

stop


;As of 7-November-2014, these corrections are not the default for L2 MOM
;input. To get corrected values for L2:
;------------------------------------------------------------------
thm_load_mom, probe='b', suffix = '_corrected', /dead_time_correct, level = 2

;If you want to make comparisons, load without corrections
thm_load_mom, probe='b', suffix = '_uncorrected', level = 2


End
