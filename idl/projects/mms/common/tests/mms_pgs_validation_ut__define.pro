;+
;
; Unit tests validating MMS plasma tools in Python
; 
;
; To run:
;     IDL> mgunit, 'mms_pgs_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-07-30 11:43:55 -0700 (Fri, 30 Jul 2021) $
; $LastChangedRevision: 30160 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_pgs_validation_ut__define.pro $
;-

function mms_pgs_validation_ut::test_hpca_hplus_brst
  mms_part_getspec, instrument='hpca', trange=['2015-10-16/13:00', '2015-10-16/13:10'], species='hplus', probe=1, data_rate='brst', /silent, output='energy theta phi pa gyro moments'
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(instrument='hpca', output='energy theta phi pa gyro moments', data_rate='brst', trange=['2015-10-16/13:00', '2015-10-16/13:10'], species='hplus', probe=1)"]
  vars = ['mms1_hpca_hplus_phase_space_density_energy', 'mms1_hpca_hplus_phase_space_density_density', 'mms1_hpca_hplus_phase_space_density_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_hpca_oplus_srvy
  mms_part_getspec, instrument='hpca', trange=['2015-10-16/13:00', '2015-10-16/15:00'], species='oplus', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(instrument='hpca', output='energy theta phi pa gyro moments', trange=['2015-10-16/13:00', '2015-10-16/15:00'], species='oplus', probe=1)"]
  vars = ['mms1_hpca_oplus_phase_space_density_energy', 'mms1_hpca_oplus_phase_space_density_density', 'mms1_hpca_oplus_phase_space_density_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_hpca_hplus_srvy
  mms_part_getspec, instrument='hpca', trange=['2015-10-16/13:00', '2015-10-16/15:00'], species='hplus', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(instrument='hpca', output='energy theta phi pa gyro moments', trange=['2015-10-16/13:00', '2015-10-16/15:00'], species='hplus', probe=1)"]
  vars = ['mms1_hpca_hplus_phase_space_density_energy', 'mms1_hpca_hplus_phase_space_density_density', 'mms1_hpca_hplus_phase_space_density_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_fpi_elec_fast_no_pe_corr
  mms_part_getspec, photoelectron_corrections=0, trange=['2015-10-16/13:00', '2015-10-16/15:00'], data_rate='fast', species='e', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(trange=['2015-10-16/13:00', '2015-10-16/15:00'], output='energy theta phi pa gyro moments', data_rate='fast', species='e', probe=1, disable_photoelectron_corrections=True)"]
  vars = ['mms1_des_dist_fast_energy', 'mms1_des_dist_fast_density', 'mms1_des_dist_fast_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_fpi_elec_fast
  mms_part_getspec, trange=['2015-10-16/13:00', '2015-10-16/15:00'], data_rate='fast', species='e', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(trange=['2015-10-16/13:00', '2015-10-16/15:00'], output='energy theta phi pa gyro moments', data_rate='fast', species='e', probe=1)"]
  vars = ['mms1_des_dist_fast_energy', 'mms1_des_dist_fast_density', 'mms1_des_dist_fast_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_fpi_ion_fast
  mms_part_getspec, trange=['2015-10-16/13:00', '2015-10-16/15:00'], data_rate='fast', species='i', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(trange=['2015-10-16/13:00', '2015-10-16/15:00'], output='energy theta phi pa gyro moments', data_rate='fast', species='i', probe=1)"]
  vars = ['mms1_dis_dist_fast_energy', 'mms1_dis_dist_fast_density', 'mms1_dis_dist_fast_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_fpi_elec_burst_no_pe_corr
  mms_part_getspec, photoelectron_corrections=0, trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', species='e', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(trange=['2015-10-16/13:06', '2015-10-16/13:07'], output='energy theta phi pa gyro moments', data_rate='brst', species='e', probe=1, disable_photoelectron_corrections=True)"]
  vars = ['mms1_des_dist_brst_energy', 'mms1_des_dist_brst_density', 'mms1_des_dist_brst_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_fpi_elec_burst
  mms_part_getspec, trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', species='e', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(trange=['2015-10-16/13:06', '2015-10-16/13:07'], output='energy theta phi pa gyro moments', data_rate='brst', species='e', probe=1)"]
  vars = ['mms1_des_dist_brst_energy', 'mms1_des_dist_brst_density', 'mms1_des_dist_brst_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

function mms_pgs_validation_ut::test_fpi_ion_burst
  mms_part_getspec, trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', species='i', probe=1, output='energy theta phi pa gyro moments', /silent
  py_script = ["from pyspedas.mms.particles.mms_part_getspec import mms_part_getspec", "mms_part_getspec(trange=['2015-10-16/13:06', '2015-10-16/13:07'], output='energy theta phi pa gyro moments', data_rate='brst', species='i', probe=1)"]
  vars = ['mms1_dis_dist_brst_energy', 'mms1_dis_dist_brst_density', 'mms1_dis_dist_brst_avgtemp']
  return, spd_run_py_validation(py_script, vars, tol=1e-3)
end

pro mms_pgs_validation_ut::setup
  del_data, '*'
end

pro mms_pgs_validation_ut__define
  define = { mms_pgs_validation_ut, inherits MGutTestCase }
end