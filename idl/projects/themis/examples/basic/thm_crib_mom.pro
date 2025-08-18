;+
;Procedure:
;  thm_crib_mom
;
;Purpose:
;  Demonstrate basic examples of accessing on-board particle moments data.
;  
;See also:
;  thm_crib_esa
;  thm_crib_sst
;  thm_crib_part_products
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-03-03 15:29:06 -0800 (Tue, 03 Mar 2015) $
;$LastChangedRevision: 17072 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_mom.pro $
;
;-




;------------------------------------------------------------------------------
; Load all partially calibrated (l1) data for a single probe
;------------------------------------------------------------------------------

probe = 'c'

;set time range
trange =  ['2010-02-13', '2010-02-14']

;loead all level 1 data (default)
thm_load_mom, probe=probe, trange=trange

;print list of variables
tplot_names, 'th'+probe+'_p??m*'

;plot some examples
tplot, 'th'+probe+'_p??m_density'

stop


;------------------------------------------------------------------------------
; Load specific l1 data types
;------------------------------------------------------------------------------

probe = 'b'

;set time range
trange =  ['2010-02-13', '2010-02-14']

;load level 1 total (esa + sst) moments for ions and electrons
;this will load all data products for the specified data types
thm_load_mom, probe=probe, trange=trange, datatype='ptim ptem'

;print list of variables
tplot_names, 'th'+probe+'_pt?m*'

;plot examples
tplot, 'th'+probe+ ['_ptim_density','_ptem_velocity']

stop


;------------------------------------------------------------------------------
; Load eclipse-corrected data
;------------------------------------------------------------------------------

probe = 'b'

;time range of eclipse
trange =  '2010-02-13/'+ ['08:30', '10:00']


;load original data
;------------------
; 2012-08-03: By default, the eclipse spin model corrections are not
; applied. For clarity, we'll explicitly set use_eclipse_corrections to 0
; to get a comparison plot, showing how the lack of eclipse spin model
; corrections induces an apparent rotation in the data.

thm_load_mom, probe=probe, trange=trange, suffix='_orig'


;load eclipse-corrected data
;---------------------------
;  use_eclipse_corrections: 0 - no corrections
;                           1 - partial corrections (see notes below)
;                           2 - full corrections
;
; Here we load the original data, but enable the full set of eclipse spin
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

thm_load_mom, probe=probe, trange=trange, use_eclipse_corrections=2, suffix='_corr'


; Plot the data to compare the results before and after the eclipse
; spin model corrections have been applied.  In the uncorrected
; data, the field is clearly rotating in the spin plane, due to
; the spin-up that occurs during the eclipse as the probe and
; booms cool and contract.

tplot, 'th'+probe+'_peim_velocity' + ['_orig','_corr']

stop


;------------------------------------------------------------------------------
; Compare with ground processed moments
;------------------------------------------------------------------------------

; See thm_crib_part_products for more details on ground processed moments

probe='e'

trange =  ['2010-02-13', '2010-02-14']

;load on-board moments
thm_load_mom, probe=probe, trange=trange, datatype='peim'

;load l0 particle data into memory
;  -load full distribution ESA ion data
thm_part_load, probe=probe, datatype='peif', trange=trange

;generate moments from l0 particle data
;  -this routine will automatically use 'th?_pxxm_pot' (loaded with l1 on-board data)
;   to correct for spacecraft potential, usethe mag_name keyword to specify another 
;   tplot variable
thm_part_products, probe=probe, datatype='peif', trange=trange, output='moments'

;ensure plot axes are identical
options, '*density', ylog=1, yrange=[.01,10]
options, '*velocity', yrange=[-100,100]

tplot, 'th'+probe+'_pei?_' + ['density','velocity']

stop


;------------------------------------------------------------------------------
; Load all calibrated (l2) on-board moments for single probe 
;------------------------------------------------------------------------------

;select probe
probe = 'c'

;set time range
trange =  ['2010-02-13', '2010-02-14']

;load all level 2 data products
thm_load_mom, probe=probe, trange=trange, level='l2'

;print list of variables
tplot_names, 'th'+probe+'_p??m*'

;plot examples
tplot, 'th'+probe+ ['_peim_density','_peem_density','_peim_eflux','_peem_eflux']

stop


;------------------------------------------------------------------------------
; Load specific l2 data products
;------------------------------------------------------------------------------

;select probe
probe = 'b'

;set time range
trange =  ['2010-02-13', '2010-02-14']

;load only level 2 ion density and energy flux
thm_load_mom, probe=probe, trange=trange, level='l2', datatype='peim_density peim_eflux'

;print list of variables
tplot_names, 'th'+probe+'_p??m*'

;plot examples
tplot, 'th'+probe+ ['_peim_density','_peim_eflux']

stop


end