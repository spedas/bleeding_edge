;+
;procedure:  thm_crib_esa_bgnd_remove
;
;purpose: Cleanup ESA background.
;
; This demonstrates the cleanup process for your event.
; Note you have to use the get routines I sent you that
; implement the bgnd_remove keyword. You simply replace the
; old ones with these ones in your thm idl directory.
; 
; Crib provided by Vassilis
;
;usage:
; .run thm_crib_esa_bgnd_remove
; 
; SEE ALSO:
;   thm_part_moments
;   thm_part_getspec
;   thm_esa_bgnd_remove
;   get_th?_pe??.pro
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2014-11-24 16:22:50 -0800 (Mon, 24 Nov 2014) $
; $LastChangedRevision: 16294 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/deprecated/thm_crib_esa_bgnd_remove_old.pro $
;
;-
timespan,'8 6 15/08:00',4,/hours
trange=['8 6 15/08:00','8 6 15/12:00']
;
sc='d'
thm_load_state,probe=sc,/get_supp
thm_load_fit,probe=sc,data='fgs',coord='gsm',suff='_gsm'
thm_load_fit,probe=sc,data='fgs',coord='dsl',suff='_dsl'
thm_load_mom,probe=sc ; L2: onboard processed moms
thm_load_esa,probe=sc ; L2: ground processed gmoms, omni spectra
ylim,'thd_pe??_en_eflux',5,30000,1
; load L0 omni spectra, all ESA data in memory
thm_load_esa_pkt,probe=sc

;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; There are various ways of using the keyword /bgnd_remove
; One way is for producing moments and spectra (together in one call)
; Note that this time we did not have full distribution functions - FDFs- at
; full cadence but every 5min, which means we ground velocities will be 5min resolution.
; However we have omni spectra (reduced distribution functions - RDFs) every spin.
; Also note that FDFs are 3s snapshots, not 5min averages, so the statistics are no
; better than 3s cadence FDFs. From those you can produce reasonable temperature
; and density assuming isotropy and also spectra with removed background. See below:
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
trange=['8 6 15/08:00','8 6 15/12:00']
thm_part_moments_old, probe = sc, instrum = 'peir', scpot_suffix = '_pxxm_pot', $
trange=trange,erange=[0,31],mag_suffix = '_fgs_dsl', tplotnames = tn, $
verbose = 2; new names are output into tn
;
calc," 'thd_peir_en_eflux_before'='thd_peir_en_eflux' "
;
thm_part_moments_old, probe = sc, instrum = 'peir', scpot_suffix = '_pxxm_pot', $
trange=trange,erange=[0,31],mag_suffix = '_fgs_dsl', tplotnames = tn, $
verbose = 2, /bgnd_remove ; new names are output into tn
calc," 'thd_peir_en_eflux_after'='thd_peir_en_eflux' "
;
tplot,'thd_peir_en_eflux_before thd_peir_en_eflux_after'

stop

;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; You can do the same thing with full distribution functions FDFs. See below.
; When you look at the spectrum, you can see the subtraction resulted in
; a cleaned up spectrum that still has some noise. The reason is that
; the background was underestimated using the FDFs because each angle
; results in a noisy estimate of the background, which in general has
; high variance and the minimum is below the most likely value.
; The RDFs though have more robust estimates of the background because
; they are averages over all angles.
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
trange=['8 6 15/08:00','8 6 15/12:00']
thm_part_moments_old, probe = sc, instrum = 'peif', scpot_suffix = '_pxxm_pot', $
trange=trange,erange=[0,31],mag_suffix = '_fgs_dsl', tplotnames = tn, $
verbose = 2; new names are output into tn
;
calc," 'thd_peif_en_eflux_before'='thd_peif_en_eflux' "
;
thm_part_moments_old, probe = sc, instrum = 'peif', scpot_suffix = '_pxxm_pot', $
trange=trange,erange=[0,31],mag_suffix = '_fgs_dsl', tplotnames = tn, $
verbose = 2, /bgnd_remove ; new names are output into tn
calc," 'thd_peif_en_eflux_after'='thd_peif_en_eflux' "
;
tplot,'thd_peif_en_eflux_before thd_peif_en_eflux_after'

stop

;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Now lets see how to use the /bgnd_remove keyword for producing ANGULAR
; spectra with thm_part_getspec. (Note you can also do energy spectra
; restricting any look direction.)
;
; First try again to produce a familar spectrum, but with
; the keyword /bgnd_remove. Try FDFs.
; You can see the spectra are identical to what was obtained above
; with a slightly different routine; the underlying implementation is same.
; Here you can restrict the espectrum's angle phi, thera, or pa or gyrophase 
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
trange=['8 6 15/08:00','8 6 15/12:00']
thm_part_getspec_old,probe=sc, trange=trange, theta=[-90,90], phi=[0,360], $
data_type=['peif'], /energy, tplotsuffix='_after2',/bgnd_remove
;
trange=['8 6 15/08:00','8 6 15/12:00']
thm_part_getspec_old,probe=sc, trange=trange, theta=[-90,90], phi=[0,360], $
data_type=['peif'], /energy, tplotsuffix='_after2',/bgnd_remove
;
; Also do RDFs for ions and electrons
;
trange=['8 6 15/08:00','8 6 15/12:00']
thm_part_getspec_old,probe=sc, trange=trange, theta=[-90,90], phi=[0,360], $
data_type=['peir'], /energy, tplotsuffix='_after2',/bgnd_remove
;
trange=['8 6 15/08:00','8 6 15/12:00']
thm_part_getspec_old,probe=sc, trange=trange, theta=[-90,90], phi=[0,360], $
data_type=['peer'], /energy, tplotsuffix='_after2',/bgnd_remove
;
zlim,'thd_peif_en_eflux*',1.e5,1.e7,1 ; fix eflux limits
ylim,'thd_peif_en_eflux*',5.,30000.,1 ; fix energy limits
tplot,'thd_peif_en_eflux_before thd_peif_en_eflux_after thd_peif_en_eflux_after2'
tplot,'thd_peir_en_eflux_before thd_peir_en_eflux_after thd_peir_en_eflux_after2'    
tlimit,trange

stop

;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Now lets implement the bgnd_removal on energy and angular spectra of
; previous plot. I will simply add the keyword /bgnd_remove to the crib1.pro
; so you can compare with that. 
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
thm_part_getspec_old,probe=sc, trange=trange, theta=[-45,45], phi=[0,360], $
data_type=['peif'], start_angle=0, angle='phi', $
tplotsuffix='_eq2', erange=[5000.,15000.], /bgnd_remove
zlim,'thd_peif_an_eflux_phi_eq2',1.e5,1.e7,1
;
thm_part_getspec_old,probe=sc, trange=trange, $
data_type=['peif'], angle='pa', $
tplotsuffix='_eq2', erange=[5000.,15000.], /bgnd_rem
;
thm_part_getspec_old,probe=sc, trange=trange, $
data_type=['peif'], angle='pa', $
tplotsuffix='_eq_norm2', erange=[5000.,15000.],/norm, /bgnd_rem
;
thm_part_getspec_old,probe=sc, trange=trange, theta=[-45,45], phi=[0,360], $
data_type=['peef'], start_angle=0, angle='phi', $
tplotsuffix='_eq2', erange=[2000.,8000.], /bgnd_rem
;
thm_part_getspec_old,probe=sc, trange=trange, $
data_type=['peef'], angle='pa', $
tplotsuffix='_eq2', erange=[2000.,8000.], /bgnd_rem
;
thm_part_getspec_old,probe=sc, trange=trange, $
data_type=['peef'], angle='pa', $
tplotsuffix='_eq_norm2', erange=[2000.,8000.],/norm, /bgnd_rem
;
tplot,'thd_fgs_gsm thd_peir_en_eflux_after2 thd_peif_an_eflux_phi_eq2 ' + $
      'thd_peif_an_eflux_pa_eq2 thd_peif_an_eflux_pa_eq_norm2 thd_peer_en_eflux_after2 ' + $
      'thd_peef_an_eflux_phi_eq2 thd_peef_an_eflux_phi_eq_norm2'
;
tlimit,trange
;

stop

;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Default settings for bgnd_remove can be tweaked using keywords:
; bgnd_type,bgnd_npoints,bgnd_scale
; For example...
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;

thm_part_moments_old, probe = sc, instrum = 'peir', scpot_suffix = '_pxxm_pot', $
  trange=trange,erange=[0,31],mag_suffix = '_fgs_dsl', tplotsuffix='_after3', $
  /bgnd_remove,bgnd_npoints=1,bgnd_scale=1.02,bgnd_type='angle'  ;valid types are 'omni','angle','anode'
  
  tplot,'thd_peir_en_eflux_*'

end
