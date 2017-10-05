;+
;Procedure:
;  thm_crib_esa_bgnd_remove
;
;Purpose:
;  Demonstrate examples of background contamination removel from ESA particle data.
;
;Notes:
;  This crib is an updated version of Vassilis's original thm_crib_esa_bgnd_remove.
;       
;See also:
;  thm_crib_esa
;  thm_crib_part_products
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-04 16:23:01 -0700 (Mon, 04 May 2015) $
;$LastChangedRevision: 17472 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_esa_bgnd_remove.pro $
;-


;---------------------------------------------------------------------------
; Settings for background removal can be tweaked using keywords:
;   
;   BGND_REMOVE: This keyword switches background removal on/off.  It is set by
;                default for most routines but usage varies.  See examples below.
;   BGND_TYPE: This specifies the method by which the background is determined.
;                "anode" - The data is divided into 16 theta bins. A background
;                           value is calculated for each bin.
;                "omni" - A background value is calculated for each energy.
;                "angle" - A background value is calculated for each look direction
;   BGND_NPOINTS: Specifies the number of smallet points to average over to 
;                 determine the background for a region.
;   BGND_SCALE: Arbitrary factor to multiply the background by before it is 
;               subtracted.
;
; Defaults values:
;   bgnd_type = "anode"
;   bgnd_npoints = 3
;   bgnd_scale = 1.
;
;---------------------------------------------------------------------------


;---------------------------------------------------------------------------
; Generate particle data products for comparison
;---------------------------------------------------------------------------

;time range
timespan,'8 6 15/08:00',4,/hours
trange=['8 6 15/08:00','8 6 15/12:00']

;probe
probe = 'd'

;load support data & comparison data
;  -by default thm_part_products will look for tplot variables containing:
;    spacecraft potential:  "th?_pxxm_pot"
;    magnetic field:        "th?_fgs"
thm_load_state, probe=probe, /get_support  ;ephemeris
thm_load_fit, probe=probe, data='fgs', coord='dsl'  ;b field
thm_load_fit, probe=probe, data='fgs', coord='gsm', suffix='_gsm' ;bfield
thm_load_mom, probe=probe ; L2: onboard processed moms, spacecraft potential
thm_load_esa, probe=probe ; L2: ground processed gmoms, omni spectra


;---------------------------------------------------------------------------
; There are various ways of using the keyword /bgnd_remove
; One way is for producing moments and spectra (together in one call)
; Note that this time we did not have full distribution functions - FDFs- at
; full cadence but every 5min, which means we ground velocities will be 5min resolution.
; However we have omni spectra (reduced distribution functions - RDFs) every spin.
; Also note that FDFs are 3s snapshots, not 5min averages, so the statistics are no
; better than 3s cadence FDFs. From those you can produce reasonable temperature
; and density assuming isotropy and also spectra with removed background. See below:
;---------------------------------------------------------------------------


;load uncalibrated (l0) particle data into memory 
thm_part_load, probe=probe, datatype='pe??'


;generate spectrograms
;  -removal on by default when using thm_part_products
thm_part_products, probe=probe, datatype='peir', trange=trange, $
                   esa_bgnd_remove=0, $
                   suffix='_before' 

thm_part_products, probe=probe, datatype='peir', trange=trange, $ 
                   suffix='_after'

thm_part_products, probe=probe, datatype='peir', trange=trange, $
                   bgnd_npoints=1, bgnd_scale=1.02, bgnd_type='angle' 
                   suffix='_after2'


zlim,'thd_peir_eflux_energy*',1.e5,1.e7,1 ; fix eflux limits
ylim,'thd_pe??_en_eflux*',5,30000,1


tplot, 'thd_peir_eflux_energy*'


stop


;---------------------------------------------------------------------------
; You can do the same thing with full distribution functions FDFs. See below.
; When you look at the spectrum, you can see the subtraction resulted in
; a cleaned up spectrum that still has some noise. The reason is that
; the background was underestimated using the FDFs because each angle
; results in a noisy estimate of the background, which in general has
; high variance and the minimum is below the most likely value.
; The RDFs though have more robust estimates of the background because
; they are averages over all angles.
;---------------------------------------------------------------------------

;disable background removal for comparison
thm_part_products, probe=probe, datatype='peif', trange=trange, $ 
                   sc_pot_name='thd_pxxm_pot', mag_name='_fgs_dsl', $
                   suffix='_before', esa_bgnd_remove=0

thm_part_products, probe=probe, datatype='peif', trange=trange, $ 
                   sc_pot_name='thd_pxxm_pot', mag_name='_fgs_dsl', $
                   suffix='_after'

zlim,'thd_peif_eflux_energy*',1.e5,1.e7,1 ; fix eflux limits
;ylim,'thd_peif_eflux_energy*',5.,30000.,1 ; fix energy limits

tplot, 'thd_peif_eflux_energy_before thd_peif_eflux_energy_after'

stop


;---------------------------------------------------------------------------
; Background removal for angular spectra.
;---------------------------------------------------------------------------

;peif phi
thm_part_products, probe=probe, datatype='peif', trange=trange, $
                   theta=[-45,45], phi=[0,360], energy=[5000.,15000.], $
                   output='phi', suffix='_before', esa_bgnd_remove=0

thm_part_products, probe=probe, datatype='peif', trange=trange, $
                   theta=[-45,45], phi=[0,360], energy=[5000.,15000.], $
                   output='phi', suffix='_after'

;peif pitch angle
thm_part_products, probe=probe, datatype='peif', trange=trange, $
                   energy=[5000.,15000.], output='pa', suffix='_before', $
                   esa_bgnd_remove=0

thm_part_products, probe=probe, datatype='peif', trange=trange, $
                   energy=[5000.,15000.], output='pa', suffix='_after'

;peef phi
thm_part_products, probe=probe, datatype='peef', trange=trange, $
                   theta=[-45,45], phi=[0,360], energy=[2000.,8000.], $
                   output='phi', suffix='_before', esa_bgnd_remove=0

thm_part_products, probe=probe, datatype='peef', trange=trange, $
                   theta=[-45,45], phi=[0,360], energy=[2000.,8000.], $
                   output='phi', suffix='_after'
                   

zlim,'thd_peif_eflux_*',1.e5,1.e7,1 ; fix eflux limits

tplot, 'thd_fgs_gsm  thd_peif_eflux_phi*  thd_peif_eflux_pa* thd_peef_eflux_phi*'

stop


end
