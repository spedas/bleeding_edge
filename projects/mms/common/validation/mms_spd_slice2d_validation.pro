;+
; NAME:
;         mms_spd_slice2d_validation
;         
; PURPOSE:
;         Creates plots for comparing FPI and HPCA slices 
;         from spd_slice2d for 0-300 eV ions when there's 
;         a bi-directional, field-aligned beam observed by 
;         both instruments around: 2017-09-10/09:32:20
; 
;   
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-04-18 13:21:13 -0700 (Wed, 18 Apr 2018) $
; $LastChangedRevision: 25075 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/validation/mms_spd_slice2d_validation.pro $
;-

output_folder = 'test-hpca-valid-updates/'
trange=['2017-09-10/09:30:20', '2017-09-10/09:34:20']

probe='3'
level='l2'
species='i'
data_rate='fast'

name =  'mms'+probe+'_dis_dist_fast'
bname = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
vname = 'mms'+probe+'_dis_bulkv_gse_fast'

mms_load_mec, trange=trange, probe=probe
mms_load_fgm, probe=probe, trange=trange, level='l2'

mms_load_fpi, /center_measurement, data_rate=data_rate, level=level, datatype='dis-dist', probe=probe, trange=trange
mms_load_fpi, /center_measurement, data_rate=data_rate, level=level, datatype='dis-moms', probe=probe, trange=trange

species = 'hplus'
data_rate = 'srvy'

mms_load_hpca, /center_measurement, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='ion'
mms_load_hpca, /center_measurement, probes=probe, trange=trange, data_rate=data_rate, level=level, datatype='moments'
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------
; case 0: 2017-09-10/09:32:20->09:32:30
time = '2017-09-10/09:32:20'
;---------------------------------------------

name =  'mms'+probe+'_dis_dist_fast'
vname = 'mms'+probe+'_dis_bulkv_gse_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, samples=2, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300])

spd_slice2d_plot, slice, export=output_folder+'fpi_cold0_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
vname = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'
dist = mms_get_dist(name)
  
slice = spd_slice2d(dist, time=time, samples=1, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300])

wi, 1

spd_slice2d_plot, slice, window=1, export=output_folder+'hpca_cold0_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; XZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz', samples=2) 

wi, 2
spd_slice2d_plot, slice, window=2, export=output_folder+'fpi_cold0_xz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz')

wi, 3
spd_slice2d_plot, slice, window=3, export=output_folder+'hpca_cold0_xz_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; YZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz', samples=2)

wi, 4
spd_slice2d_plot, slice, window=4, export=output_folder+'fpi_cold0_yz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz')

wi, 5
spd_slice2d_plot, slice, window=5, export=output_folder+'hpca_cold0_yz_new'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------
; case 1: 2017-09-10/09:32:30->09:32:40
time = '2017-09-10/09:32:30'
;---------------------------------------------

name =  'mms'+probe+'_dis_dist_fast'
vname = 'mms'+probe+'_dis_bulkv_gse_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, window=window, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300], samples=2)

spd_slice2d_plot, slice, export=output_folder+'fpi_cold1_new'


name = 'mms'+probe+'_hpca_hplus_phase_space_density'
vname = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, samples=1, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300])

wi, 1

spd_slice2d_plot, slice, window=1, export=output_folder+'hpca_cold1_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; XZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz', samples=2)

wi, 2
spd_slice2d_plot, slice, window=2, export=output_folder+'fpi_cold1_xz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz')

wi, 3
spd_slice2d_plot, slice, window=3, export=output_folder+'hpca_cold1_xz_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; YZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz', samples=2)

wi, 4
spd_slice2d_plot, slice, window=4, export=output_folder+'fpi_cold1_yz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz')

wi, 5
spd_slice2d_plot, slice, window=5, export=output_folder+'hpca_cold1_yz_new'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------
; case 2: 2017-09-10/09:32:40->09:32:50
time = '2017-09-10/09:32:40'
;---------------------------------------------

name =  'mms'+probe+'_dis_dist_fast'
vname = 'mms'+probe+'_dis_bulkv_gse_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, window=window, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300], samples=2)

spd_slice2d_plot, slice, export=output_folder+'fpi_cold2_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
vname = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, samples=1, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300])

wi, 1

spd_slice2d_plot, slice, window=1, export=output_folder+'hpca_cold2_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; XZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz', samples=2)

wi, 2
spd_slice2d_plot, slice, window=2, export=output_folder+'fpi_cold2_xz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz')

wi, 3
spd_slice2d_plot, slice, window=3, export=output_folder+'hpca_cold2_xz_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; YZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz', samples=2)

wi, 4
spd_slice2d_plot, slice, window=4, export=output_folder+'fpi_cold2_yz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz')

wi, 5
spd_slice2d_plot, slice, window=5, export=output_folder+'hpca_cold2_yz_new'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------
; case 3: 2017-09-10/09:32:50->09:33:00
time = '2017-09-10/09:32:40'
;---------------------------------------------

name =  'mms'+probe+'_dis_dist_fast'
vname = 'mms'+probe+'_dis_bulkv_gse_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, window=window, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300], samples=2)

spd_slice2d_plot, slice, export=output_folder+'fpi_cold3_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
vname = 'mms'+probe+'_hpca_hplus_ion_bulk_velocity'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, samples=1, $
  rotation='bv', mag_data=bname, vel_data=vname, erange=[0, 300])

wi, 1

spd_slice2d_plot, slice, window=1, export=output_folder+'hpca_cold3_new'


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; XZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz', samples=2)

wi, 2
spd_slice2d_plot, slice, window=2, export=output_folder+'fpi_cold3_xz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='xz')

wi, 3
spd_slice2d_plot, slice, window=3, export=output_folder+'hpca_cold3_xz_new'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; YZ

name =  'mms'+probe+'_dis_dist_fast'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz', samples=2)

wi, 4
spd_slice2d_plot, slice, window=4, export=output_folder+'fpi_cold3_yz_new'

name = 'mms'+probe+'_hpca_hplus_phase_space_density'
dist = mms_get_dist(name, trange=trange)

slice = spd_slice2d(dist, time=time, erange=[0, 300], rotation='yz')

wi, 5
spd_slice2d_plot, slice, window=5, export=output_folder+'hpca_cold3_yz_new'


end