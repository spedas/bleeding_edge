;+
;Procedure:
;  mms_part_getspec_crib
;
;
;Purpose:
;  Basic example on how to use mms_part_getspec to generate particle
;  spectrograms and moments from level 2 MMS HPCA and FPI distributions.
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
;$LastChangedRevision: 31999 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_part_getspec_crib.pro $
;-

;==========================================================
; FPI - L2
;==========================================================

; clear data
del_data,'*'

; use short time range for data due to high resolution
timespan, '2015-10-16/13:05:40', 30, /sec

; generate products
mms_part_getspec, instrument='fpi', probe='1', species='e', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro', 'moments']

; plot spectrograms
tplot, 'mms1_des_dist_brst_'+['energy', 'theta', 'phi', 'pa', 'gyro']
stop

; add number density
tplot, 'mms1_des_dist_brst_density', /add
stop

; note:
; DES moments calculated with mms_part_getspec (PGS) include corrections for photoelectrons 
; using Dan Gershman's model. Note that there may still be slight differences between 
; the PGS moments and the official moments released by the team.
; 
; The official moments released by the team are the scientific
; products you should use in your analysis.
;
;
; The following example shows how to load the FPI moments
; released by the team (des-moms, dis-moms datatypes):
mms_load_fpi, probe='1', data_rate='brst', level='l2', datatype='des-moms'
store_data, 'numberdensity', data='mms1_des_numberdensity_brst mms1_des_dist_brst_density'
tplot, 'numberdensity'

; the following shows how to add the errorflag bars to the spectrograms
; note: the errorflags tplot variable is loaded automatically by mms_part_getspec
tplot, /add, 'mms1_des_errorflags_brst_moms_flagbars_full'
stop

;==========================================================
; FPI - L2, ions, with and without bulk velocity subtracted
;==========================================================

mms_part_getspec, /subtract_bulk, suffix='_bulk', trange=['2015-10-16/13:05:40', '2015-10-16/13:06:40'], probe='1', species='i', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']
mms_part_getspec, trange=['2015-10-16/13:05:40', '2015-10-16/13:06:40'], probe='1', species='i', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']

; plot the spectrograms
tplot, 'mms1_dis_dist_brst_'+['energy', 'energy_bulk', 'pa', 'pa_bulk']
stop

;==========================================================
; FPI - L2, ions, with bulk velocity and distribution error subtracted
;==========================================================

mms_part_getspec, /subtract_bulk, /subtract_error, suffix='_bulk', trange=['2015-10-16/13:05:40', '2015-10-16/13:06:40'], probe='1', species='i', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']

; plot the spectrograms
tplot, 'mms1_dis_dist_brst_'+['energy_bulk', 'pa_bulk']
stop

;==========================================================
; FPI - L2, multi-dimensional PAD variable (pitch angle spectrograms at each energy)
;==========================================================

mms_part_getspec, probe='1', species='e', data_rate='brst', level='l2', output='multipad'

; generate the PAD at the full energy range by leaving off the energy keyword
mms_part_getpad, probe=1, species='e', data_rate='brst'

tplot, 'mms1_des_dist_brst_pad_*eV'
stop

; now generate the PADs at various energy ranges
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[0, 10]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[10, 50]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[50, 100]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[100, 1000]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[1000, 10000]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[10000, 20000]
mms_part_getpad, probe=1, species='e', data_rate='brst', energy=[10000, 30000]

tplot, 'mms1_des_dist_brst_pad_'+['0eV_10eV', '10eV_50eV', '50eV_100eV', '100eV_1000eV', '1000eV_10000eV', '10000eV_20000eV', '10000eV_30000eV'], /add
stop

;==========================================================
; FPI - add B-field and S/C ram direction to the angular spectra
;==========================================================

mms_part_getspec, /add_bfield_dir, /add_ram_dir, probe='1', species='e', data_rate='brst', level='l2', output='phi theta'

tplot, ['mms1_des_dist_brst_phi_with_b', 'mms1_des_dist_brst_theta_with_b', $ ; with B-field direction
        'mms1_des_dist_brst_phi_with_v', 'mms1_des_dist_brst_theta_with_v', $ ; with S/C ram direction
        'mms1_des_dist_brst_phi_with_bv', 'mms1_des_dist_brst_theta_with_bv'] ; with both
stop


;==========================================================
; HPCA - L2
;==========================================================

;clear data
del_data,'*'

timespan, '2016-10-16/13:09', 2, /min

mms_part_getspec, instrument='hpca', probe='1', species='hplus', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro', 'moments']

;generate products (experimental option)
;  The /no_regrid option uses a regular transformation on the HPCA to avoid the more general spherical interpolation
;    The main benefit of the /no_regrid keyword is to reduce the runtime of mms_part_products
;  mms_part_products, name, trange=trange,/no_regrid, $
;                     mag_name=bname, pos_name=pos_name, $ ;required for field aligned spectra
;                     outputs=['energy','phi','theta','pa','gyro','moments']

;plot spectrograms
tplot, 'mms1_hpca_hplus_phase_space_density_'+['energy','theta','phi','pa','gyro']

stop

;plot moments
tplot, 'mms1_hpca_hplus_phase_space_density_'+['density', 'avgtemp']

stop




end