;+
;Purpose:
;   A crib sheet for visualizing MMS 3D distribution function data (L2) 
;   by using an interactive visualization tool, ISEE3D, developed by 
;   Institute for Space-Earth Environmental Research (ISEE), Nagoya University, Japan.
;
;Notes:
;   Please use the latest version of SPEDAS bleeding edges. 
;   Please use both 'bfield' and 'velocity' keywords to run isee3d. 
;
;See also:
;   mms_isee_3d_crib.pro
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-04 15:54:42 -0700 (Fri, 04 Nov 2016) $
;$LastChangedRevision: 22310 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_isee_3d_crib_basic.pro $
;-


;=============================================================
; FPI - L2
;=============================================================

del_data,'*'

;setup
probe = '1'
species = 'i'
data_rate = 'brst'
level = 'l2'

;names of tplot variables that will contain particle data, bfield, and bulk velocity
name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate 
bfield = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
velocity = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate 

;use short time range for data due to high resolution (saves time/memory)
;time range must include at least three sample times
;use longer time range for support data to ensure we have enough to work with
timespan, '2015-10-20/05:56:30', 4, /sec
;timespan, '2015-11-18/02:10:00', 10, /sec

trange = timerange()
support_trange= trange + [-60,60]

;load data into tplot
mms_load_fpi, probe=probe, trange=trange, data_rate=data_rate, level=level, $
              datatype='d'+species+'s-dist'

;load data into standard structures
dist = mms_get_fpi_dist(name, trange=trange)

;convert structures to isee_3d data model
data = spd_dist_to_hash(dist)

;load bfield (cyan vector) and velocity (yellow vector) support data
mms_load_fgm, probe=probe, trange=support_trange, level='l2'
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', $
              probe=probe, trange=support_trange

;once GUI is open select PSD from Units menu
isee_3d, data=data, trange=trange, bfield=bfield, velocity=velocity


stop


;=============================================================
; HPCA - L2
;=============================================================

del_data,'*'

;setup
probe = '1'
data_rate = 'srvy' ;only srvy available for l2
level = 'l2' ;'e'

;names of tplot variables that will contain particle data, bfield, and bulk velocity
tname = 'mms'+probe+'_hpca_hplus_phase_space_density'
bfield = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
velocity = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'

;use short time range for data due to high resolution (saves time/memory)
;time range must include at least three sample times
timespan, '2015-10-20/05:56:30', 1, /min
trange = timerange()

;load data into tplot
mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'

;load data into standard structures
dist = mms_get_hpca_dist(tname)

;convert structures to isee_3d data model
data = spd_dist_to_hash(dist)

;load bfield (cyan vector) and velocity (yellow vector) support data
mms_load_fgm, probe=probe, trange=trange, level='l2'
mms_load_hpca, probes=probe, trange=trange, data_rate=data_rate, level=level, $
               datatype='moments', varformat='*_hplus_ion_bulk_velocity'


;once GUI is open select PSD from Units menu
isee_3d, data=data, trange=trange, bfield=bfield, velocity=velocity


stop



end