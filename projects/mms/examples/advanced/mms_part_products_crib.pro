;+
;Procedure:
;  mms_part_products_crib
;
;
;Purpose:
;  Basic example on how to use mms_part_getspec to generate particle
;  spectrograms and moments from level 2 MMS HPCA and FPI distributions.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-05-03 15:55:00 -0700 (Wed, 03 May 2017) $
;$LastChangedRevision: 23266 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_part_products_crib.pro $
;-


;==========================================================
; FPI - L2
;==========================================================

; clear data
del_data,'*'

; use short time range for data due to high resolution
timespan, '2015-10-16/13:05:40', 30, /sec

; generate products
mms_part_getspec, instrument='fpi', probe='1', species='e', data_rate='brst', level='l2', outputs=['phi', 'theta', 'energy', 'pa', 'gyro']

; plot spectrograms
tplot, 'mms1_des_dist_brst_'+['energy','theta','phi','pa','gyro']

stop

; the following shows how to add the errorflag bars to the spectrograms
; note: the errorflags tplot variable is loaded automatically by mms_part_getspec
tplot, 'mms1_des_errorflags_brst_dist_flagbars_dist', /add
stop

;plot moments
; !!!!!! words of caution <------ by egrimes, 4/7/2016:
; While you can use mms_part_getspec/mms_part_products to generate particle moments for FPI from
; the distributions, these calculations are currently missing several important
; components, including photoelectron removal and S/C potential corrections.
; The official moments released by the team include these, and are the scientific
; products you should use in your analysis
;
;
; The following example shows how to load the FPI moments
; released by the team (des-moms, dis-moms datatypes):
mms_load_fpi, probe='1', data_rate='brst', level='l2', datatype='des-moms'
tplot, 'mms1_des_numberdensity_brst'

; add the errorflags bar to the top of the plot
tplot, /add, 'mms1_des_errorflags_brst_moms_flagbars_full'
stop



;==========================================================
; HPCA - L2
;==========================================================

;clear data
del_data,'*'

timespan, '2015-10-16/13:02:30', 5, /min

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