;+
;
; Unit tests for mms_python_validation_ut
;
; To run:
;     IDL> mgunit, 'mms_python_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2022-03-31 13:28:35 -0700 (Thu, 31 Mar 2022) $
; $LastChangedRevision: 30738 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_python_validation_ut__define.pro $
;-

function mms_python_validation_ut::test_fpi_errorflags_bars
  mms_load_fpi, datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ['import pyspedas', $
    "pyspedas.mms.fpi(datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16','2015-10-17'])", $
    "from pyspedas.mms.fpi.mms_fpi_make_errorflagbars import mms_fpi_make_errorflagbars", $
    "mms_fpi_make_errorflagbars('mms1_des_errorflags_fast_moms', level='l2')", $
    "mms_fpi_make_errorflagbars('mms1_dis_errorflags_fast_moms', level='l2')"]
  vars = ['mms1_dis_errorflags_fast_moms_flagbars_full', $
    'mms1_dis_errorflags_fast_moms_flagbars_main', $
    'mms1_dis_errorflags_fast_moms_flagbars_mini', $
    'mms1_des_errorflags_fast_moms_flagbars_full', $
    'mms1_des_errorflags_fast_moms_flagbars_main', $
    'mms1_des_errorflags_fast_moms_flagbars_mini']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_compressionloss_bars
  mms_load_fpi, datatype=['des-moms', 'dis-moms'], trange=['2017-07-11/22:34', '2017-07-11/22:34:25'], data_rate='brst', probe=3
  py_script = ['import pyspedas', $
    "pyspedas.mms.fpi(datatype=['des-moms', 'dis-moms'], trange=['2017-07-11/22:34', '2017-07-11/22:34:25'], data_rate='brst', probe=3)", $
    "from pyspedas.mms.fpi.mms_fpi_make_compressionlossbars import mms_fpi_make_compressionlossbars", $
    "mms_fpi_make_compressionlossbars('mms3_dis_compressionloss_brst_moms')", $
    "mms_fpi_make_compressionlossbars('mms3_des_compressionloss_brst_moms')"]
  vars = ['mms3_dis_compressionloss_brst_moms_flagbars', $
    'mms3_des_compressionloss_brst_moms_flagbars']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_lingradest_curl
  trange = ['2015-10-30/05:15:45', '2015-10-30/05:15:48']

  mms_load_fgm, trange=trange, /get_fgm_ephemeris, probes=[1, 2, 3, 4], data_rate='brst', /time_clip

  fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2'
  positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'
  mms_lingradest, fields=fields, positions=positions, suffix='_lingradest'
  
  py_script = ["import pyspedas", $
    "from pyspedas.mms import lingradest", $
    "pyspedas.mms.fgm(trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'], get_fgm_ephemeris=True, probe=[1, 2, 3, 4], data_rate='brst', time_clip=True)", $
    "lingradest(fields=['mms1_fgm_b_gse_brst_l2_bvec','mms2_fgm_b_gse_brst_l2_bvec','mms3_fgm_b_gse_brst_l2_bvec','mms4_fgm_b_gse_brst_l2_bvec'], positions=['mms1_fgm_r_gse_brst_l2','mms2_fgm_r_gse_brst_l2','mms3_fgm_r_gse_brst_l2','mms4_fgm_r_gse_brst_l2'], suffix='_lingradest')"]

  vars = ['Bt_lingradest', $
    'Bx_lingradest', $
    'By_lingradest', $
    'Bz_lingradest', $
    'gradBx_lingradest', $
    'gradBy_lingradest', $
    'gradBz_lingradest', $
    'absCB_lingradest', $
    'CxB_lingradest', $
    'CyB_lingradest', $
    'CzB_lingradest', $
    'jx_lingradest', $
    'jy_lingradest', $
    'jz_lingradest', $
    'curvx_lingradest', $
    'curvy_lingradest', $
    'curvz_lingradest', $
    'Rc_1000km_lingradest']
  return, spd_run_py_validation(py_script, vars, tol=1e-1)
end

function mms_python_validation_ut::test_feeps_gyrophase_electron
   mms_load_feeps, trange=['2017-07-11/22:34', '2017-07-11/22:34:25'], data_rate='brst', probe=3
   mms_feeps_gpd, trange=['2017-07-11/22:34', '2017-07-11/22:34:25'], data_rate='brst', probe=3
   py_script = ["from pyspedas.mms.feeps.mms_feeps_gpd import mms_feeps_gpd", $
                "import pyspedas", $
                "feeps_vars = pyspedas.mms.feeps(data_rate='brst', trange=['2017-07-11/22:34', '2017-07-11/22:34:25'], probe=3)", $
                "mms_feeps_gpd(trange=['2017-07-11/22:34', '2017-07-11/22:34:25'], data_rate='brst', probe=3)"]
   vars = ['mms3_epd_feeps_brst_l2_electron_intensity_50-500keV_gpd']
   return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fac_matrix_make
  mms_load_fgm, trange=['2015-10-16', '2015-10-17']
  fac_matrix_make, 'mms1_fgm_b_gse_srvy_l2_bvec'
  py_script = ['import pyspedas', 'from pyspedas.cotrans.fac_matrix_make import fac_matrix_make', 'pyspedas.mms.fgm()', 'fac_matrix_make("mms1_fgm_b_gse_srvy_l2_bvec")']
  vars = ['mms1_fgm_b_gse_srvy_l2_bvec_fac_mat']
  return, spd_run_py_validation(py_script, vars)
end


function mms_python_validation_ut::test_eis_bsmith_trange_phxtof
  mms_load_eis, trange=['2016-08-25', '2016-08-26'], probe=2, data_rate='srvy', datatype='phxtof', level='l1b'
  ; note: pytplot deflags the data on load
  tdeflag, 'mms2_epd_eis_srvy_l2_phxtof_proton_flux_omni', 'remove_nan', /overwrite
  py_script = ["from pyspedas import mms_load_eis", "mms_load_eis(trange=['2016-08-25', '2016-08-26'], probe=2, data_rate='srvy', datatype='phxtof', level='l1b')"]
  vars = ['mms2_epd_eis_srvy_l2_phxtof_proton_flux_omni']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_tplot_restore_hpca_moments
  mms_load_hpca, datatype='moments', trange=['2015-10-16', '2015-10-17']
  tplot_save, ['mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity'], filename='hpca_moments'
  py_script = ["from pytplot import tplot_restore", "tplot_restore('hpca_moments.tplot')"]
  vars = ['mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_tplot_restore_hpca_df
  mms_load_hpca, datatype='ion', trange=['2015-10-16', '2015-10-16/03:00']
  tplot_save, ['mms1_hpca_hplus_flux', 'mms1_hpca_hplus_phase_space_density'], filename='hpca_df'
  py_script = ["from pytplot import tplot_restore", "tplot_restore('hpca_df.tplot')"]
  vars = ['mms1_hpca_hplus_flux', 'mms1_hpca_hplus_phase_space_density']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_tplot_restore_des_df
  mms_load_fpi, datatype='des-dist', trange=['2015-10-16/12', '2015-10-16/13']
  tplot_save, ['mms3_des_dist_fast'], filename='des_df'
  py_script = ["from pytplot import tplot_restore", "tplot_restore('des_df.tplot')"]
  vars = ['mms3_des_dist_fast']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_data_segment_intervals
  mms_load_brst_segments, trange=['2015-10-16', '2015-10-17'], start_times=brst_starts, end_times=brst_ends
  mms_load_fast_segments, trange=['2015-10-1', '2015-10-31'], start_times=fast_starts, end_times=fast_ends
  mms_load_sroi_segments, trange=['2016-10-1', '2016-10-31'], start_times=sroi_starts, end_times=sroi_ends
  mms_load_sroi_segments, probe=4, trange=['2016-10-1', '2016-10-31'], start_times=sroi_starts, end_times=sroi_ends
  py_script = ["from pyspedas.mms.mms_load_fast_segments import mms_load_fast_segments",$
               "from pyspedas.mms.mms_load_brst_segments import mms_load_brst_segments",$
               "from pyspedas.mms.mms_load_sroi_segments import mms_load_sroi_segments",$
               "i = mms_load_fast_segments(trange=['2015-10-1', '2015-10-31'])",$
               "i = mms_load_sroi_segments(trange=['2016-10-1', '2016-10-31'])",$
               "i = mms_load_sroi_segments(probe=4, trange=['2016-10-1', '2016-10-31'])",$
               "i = mms_load_brst_segments(trange=['2015-10-16', '2015-10-17'])"]
  vars = ['mms_bss_burst', 'mms_bss_fast', 'mms1_bss_sroi', 'mms4_bss_sroi']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_state_ascii
  mms_load_state, trange=['2015-10-16', '2015-10-17'], /ascii, probe=1
  py_script = ["from pyspedas import mms", "mms.state(datatypes=['pos', 'vel', 'spinras', 'spindec'], probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_defeph_pos', 'mms1_defeph_vel', 'mms1_defatt_spindec', 'mms1_defatt_spinras']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_aspoc_default
  mms_load_aspoc, probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_aspoc", "mms_load_aspoc(probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_aspoc_ionc_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fgm_default
  mms_load_fgm, probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_fgm", "mms_load_fgm(probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_fgm_b_gse_srvy_l2', 'mms1_fgm_b_gsm_srvy_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fgm_brst
  mms_load_fgm, data_rate='brst', probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_fgm", "mms_load_fgm(data_rate='brst', probe=4, trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms4_fgm_b_gse_brst_l2', 'mms4_fgm_b_gsm_brst_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fgm_curlometer
  mms_load_fgm, data_rate='brst', probe=[1, 2, 3, 4], trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'], /get_fgm_ephem, /time_clip
  fields = 'mms'+['1', '2', '3', '4']+'_fgm_b_gse_brst_l2'
  positions = 'mms'+['1', '2', '3', '4']+'_fgm_r_gse_brst_l2'

  mms_curl, trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'], fields=fields, positions=positions
  py_script = ["from pyspedas import mms_load_fgm", $
               "from pyspedas.mms import curlometer", $
               "mms_load_fgm(time_clip=True, data_rate='brst', probe=[1, 2, 3, 4], trange=['2015-10-30/05:15:45', '2015-10-30/05:15:48'], get_fgm_ephemeris=True)", $
               "positions = ['mms1_fgm_r_gse_brst_l2', 'mms2_fgm_r_gse_brst_l2', 'mms3_fgm_r_gse_brst_l2', 'mms4_fgm_r_gse_brst_l2']", $
               "fields = ['mms1_fgm_b_gse_brst_l2', 'mms2_fgm_b_gse_brst_l2', 'mms3_fgm_b_gse_brst_l2', 'mms4_fgm_b_gse_brst_l2']", $
               "curlometer(fields=fields, positions=positions)"]
  vars = ['baryb', 'curlB', 'divB', 'jtotal', 'jpar', 'jperp', 'alpha', 'alphaparallel']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_edi_default
; problem with the data on 10/16/15
  mms_load_edi, trange=['2016-10-16','2016-10-17']
  py_script = ["from pyspedas import mms_load_edi", "mms_load_edi(trange=['2016-10-16','2016-10-17'])"]
  vars = ['mms1_edi_e_gse_srvy_l2', 'mms1_edi_e_gsm_srvy_l2', 'mms1_edi_vdrift_gse_srvy_l2', 'mms1_edi_vdrift_gsm_srvy_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_scm_default
  mms_load_scm, trange=['2015-10-15','2015-10-16']
  py_script = ["from pyspedas import mms_load_scm", "mms_load_scm(trange=['2015-10-15','2015-10-16'])"]
  vars = ['mms1_scm_acb_gse_scsrvy_srvy_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_scm_brst
  mms_load_scm, data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_scm", "mms_load_scm(trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', probe=1)"]
  vars = ['mms1_scm_acb_gse_scb_brst_l2', 'mms1_scm_acb_gse_schb_brst_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_scm_dpwrspc_brst
  mms_load_scm, data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  tdpwrspc, 'mms1_scm_acb_gse_scb_brst_l2', nboxpoints=8192, nshiftpoints=8192, bin=1
  py_script = ["from pyspedas import mms_load_scm", $
    "from pyspedas.analysis.tdpwrspc import tdpwrspc", $
    "mms_load_scm(trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst', probe=1)", $
    "tdpwrspc('mms1_scm_acb_gse_scb_brst_l2', nboxpoints=8192, nshiftpoints=8192, binsize=1)"]
  vars = ['mms1_scm_acb_gse_scb_brst_l2_x_dpwrspc', 'mms1_scm_acb_gse_scb_brst_l2_y_dpwrspc', 'mms1_scm_acb_gse_scb_brst_l2_z_dpwrspc']
  return, spd_run_py_validation(py_script, vars, tol=1e-2)
end

function mms_python_validation_ut::test_edp_default
  mms_load_edp, probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_edp", "mms_load_edp(probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_edp_dce_gse_fast_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_edp_brst
  mms_load_edp, data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_edp", "mms_load_edp(data_rate='brst', probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms1_edp_dce_gse_brst_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_dsp_psd
  mms_load_dsp, data_rate='fast', trange=['2015-10-16', '2015-10-17'], datatype=['epsd', 'bpsd'], level='l2'
  py_script = ["from pyspedas import mms_load_dsp", "mms_load_dsp(trange=['2015-10-16', '2015-10-17'], data_rate='fast', datatype=['epsd', 'bpsd'], level='l2')"]
  vars = ['mms1_dsp_epsd_omni', 'mms1_dsp_bpsd_omni_fast_l2']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_mec_default
  mms_load_mec, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_mec", "mms_load_mec(trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_mec_r_gsm', 'mms1_mec_r_gse', 'mms1_mec_r_sm', 'mms1_mec_v_gsm', 'mms1_mec_v_gse', 'mms1_mec_v_sm']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_feeps_srvy_electron
  mms_load_feeps, trange=['2015-10-16','2015-10-17']
  mms_feeps_pad
  py_script = ["from pyspedas import mms_load_feeps, mms_feeps_pad", "mms_load_feeps(trange=['2015-10-16','2015-10-17'])", "mms_feeps_pad()"]
  vars = ['mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', 'mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad', 'mms1_epd_feeps_srvy_l2_electron_intensity_70-600keV_pad_spin']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_feeps_srvy_ion
  mms_load_feeps, datatype='ion', trange=['2015-10-16','2015-10-17']
  mms_feeps_pad, datatype='ion'
  py_script = ["from pyspedas import mms_load_feeps, mms_feeps_pad", "mms_load_feeps(trange=['2015-10-16','2015-10-17'], datatype='ion')", "mms_feeps_pad(datatype='ion')"]
  vars = ['mms1_epd_feeps_srvy_l2_ion_intensity_omni', 'mms1_epd_feeps_srvy_l2_ion_intensity_omni_spin', 'mms1_epd_feeps_srvy_l2_ion_intensity_70-600keV_pad', 'mms1_epd_feeps_srvy_l2_ion_intensity_70-600keV_pad_spin']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_feeps_brst_ion
  mms_load_feeps, data_rate='brst', datatype='ion', trange=['2015-10-16/13:06', '2015-10-16/13:07']
  mms_feeps_pad, data_rate='brst', datatype='ion'
  py_script = ["from pyspedas import mms_load_feeps, mms_feeps_pad", "mms_load_feeps(trange=['2015-10-16/13:06', '2015-10-16/13:07'], datatype='ion', data_rate='brst')", "mms_feeps_pad(data_rate='brst', datatype='ion')"]
  vars = ['mms1_epd_feeps_brst_l2_ion_intensity_omni', 'mms1_epd_feeps_brst_l2_ion_intensity_70-600keV_pad']
  return, spd_run_py_validation(py_script, vars, tol=1e-4)
end

function mms_python_validation_ut::test_feeps_brst_electron
  mms_load_feeps, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07']
  mms_feeps_pad, data_rate='brst'
  py_script = ["from pyspedas import mms_load_feeps", "from pyspedas import mms_feeps_pad", "mms_load_feeps(trange=['2015-10-16/13:06', '2015-10-16/13:07'], data_rate='brst')", "mms_feeps_pad(data_rate='brst')"]
  vars = ['mms1_epd_feeps_brst_l2_electron_intensity_omni', 'mms1_epd_feeps_brst_l2_electron_intensity_70-600keV_pad']
  return, spd_run_py_validation(py_script, vars, tol=1e-5)
end

function mms_python_validation_ut::test_eis_default
  mms_load_eis, datatype=['extof', 'phxtof'], probe=4, trange=['2015-10-16','2015-10-17']
  mms_eis_pad, datatype=['extof', 'phxtof'], probe=4
  py_script = ["from pyspedas import mms_load_eis, mms_eis_pad", "mms_load_eis(datatype=['extof', 'phxtof'], probe=4, trange=['2015-10-16','2015-10-17'])", "mms_eis_pad(datatype=['extof', 'phxtof'], probe=4)"]
  vars = ['mms4_epd_eis_srvy_l2_extof_proton_flux_omni', 'mms4_epd_eis_srvy_l2_phxtof_proton_flux_omni', 'mms4_epd_eis_srvy_l2_extof_proton_flux_omni_spin', 'mms4_epd_eis_srvy_l2_phxtof_proton_flux_omni_spin', 'mms4_epd_eis_srvy_l2_phxtof_46-75keV_proton_flux_omni_pad_spin', 'mms4_epd_eis_srvy_l2_phxtof_46-75keV_proton_flux_omni_pad', 'mms4_epd_eis_srvy_l2_extof_44-979keV_proton_flux_omni_pad', 'mms4_epd_eis_srvy_l2_extof_44-979keV_proton_flux_omni_pad_spin']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_eis_brst
  mms_load_eis, datatype=['extof', 'phxtof'], probe=1, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07']
  mms_eis_pad, datatype=['extof', 'phxtof'], probe=1, data_rate='brst'
  py_script = ["from pyspedas import mms_load_eis, mms_eis_pad", "mms_load_eis(datatype=['extof', 'phxtof'], probe=1, data_rate='brst', trange=['2015-10-16/13:06', '2015-10-16/13:07'])", "mms_eis_pad(datatype=['extof', 'phxtof'], probe=1, data_rate='brst')"]
  vars = ['mms1_epd_eis_brst_l2_phxtof_proton_flux_omni', 'mms1_epd_eis_brst_l2_extof_proton_flux_omni', 'mms1_epd_eis_brst_l2_extof_alpha_flux_omni', 'mms1_epd_eis_brst_l2_extof_oxygen_flux_omni', 'mms1_epd_eis_brst_l2_phxtof_54-76keV_proton_flux_omni_pad', 'mms1_epd_eis_brst_l2_extof_54-897keV_proton_flux_omni_pad']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_default
  mms_load_fpi, datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16','2015-10-17']
  py_script = ["from pyspedas import mms_load_fpi", "mms_load_fpi(datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16','2015-10-17'])"]
  vars = ['mms1_des_energyspectr_omni_fast', 'mms1_dis_energyspectr_omni_fast', 'mms1_dis_bulkv_gse_fast', 'mms1_des_bulkv_gse_fast', 'mms1_des_numberdensity_fast', 'mms1_dis_temppara_fast', 'mms1_dis_tempperp_fast']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_brst
  mms_load_fpi, data_rate='brst', datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07']
  py_script = ["from pyspedas import mms_load_fpi", "mms_load_fpi(data_rate='brst', datatype=['des-moms', 'dis-moms'], probe=1, trange=['2015-10-16/13:06', '2015-10-16/13:07'])"]
  vars = ['mms1_des_energyspectr_omni_brst', 'mms1_des_numberdensity_brst', 'mms1_des_bulkv_gse_brst', 'mms1_dis_energyspectr_omni_brst', 'mms1_dis_bulkv_gse_brst', 'mms1_dis_numberdensity_brst']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_sitl
  mms_load_fpi, probe=4, level='sitl', trange=['2015-12-15', '2015-12-16']
  py_script = ["import pyspedas", "data = pyspedas.mms.fpi(probe=4, level='sitl', trange=['2015-12-15', '2015-12-16'])"]
  vars = 'mms4_fpi_ePitchAngDist_avg'
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_fpi_ql
  mms_load_fpi, probe=4, level='ql', trange=['2020-12-15', '2020-12-16']
  py_script = ["import pyspedas", "data = pyspedas.mms.fpi(probe=4, level='ql', trange=['2020-12-15', '2020-12-16'])"]
  vars = ['mms4_des_PitchAngDist_sum', 'mms4_des_pitchangdist_avg']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_ion
  mms_load_hpca, datatype='ion', probe=1, trange=['2016-10-16','2016-10-16/03:00']
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, probe='1'
  py_script = ["from pyspedas import mms_load_hpca", "from pyspedas.mms.hpca.mms_hpca_calc_anodes import mms_hpca_calc_anodes", "from pyspedas.mms.hpca.mms_hpca_spin_sum import mms_hpca_spin_sum", "mms_load_hpca(datatype='ion', probe=1, trange=['2016-10-16','2016-10-16/03:00'])", "mms_hpca_calc_anodes(fov=[0, 360], probe='1')", "mms_hpca_spin_sum(probe='1')"]
  vars = ['mms1_hpca_hplus_flux_elev_0-360_spin', 'mms1_hpca_heplus_flux_elev_0-360_spin', 'mms1_hpca_heplusplus_flux_elev_0-360_spin', 'mms1_hpca_oplus_flux_elev_0-360_spin']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_brst_ion
  mms_load_hpca, data_rate='brst', datatype='ion', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10']
  mms_hpca_calc_anodes, fov=[0, 360]
  mms_hpca_spin_sum, probe='1'
  py_script = ["from pyspedas import mms_load_hpca", "from pyspedas.mms.hpca.mms_hpca_calc_anodes import mms_hpca_calc_anodes", "from pyspedas.mms.hpca.mms_hpca_spin_sum import mms_hpca_spin_sum", "mms_load_hpca(data_rate='brst', datatype='ion', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10'])", "mms_hpca_calc_anodes(fov=[0, 360], probe='1')", "mms_hpca_spin_sum(probe='1')"]
  vars = ['mms1_hpca_hplus_flux_elev_0-360_spin', 'mms1_hpca_heplus_flux_elev_0-360_spin', 'mms1_hpca_heplusplus_flux_elev_0-360_spin', 'mms1_hpca_oplus_flux_elev_0-360_spin']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_moments
  mms_load_hpca, datatype='moments', probe=1, trange=['2016-10-16','2016-10-16/03:00']
  py_script = ["from pyspedas import mms_load_hpca", "mms_load_hpca(datatype='moments', probe=1, trange=['2016-10-16','2016-10-16/03:00'])"]
  vars = ['mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_scalar_temperature', 'mms1_hpca_oplus_number_density', 'mms1_hpca_oplus_ion_bulk_velocity', 'mms1_hpca_oplus_scalar_temperature']
  return, spd_run_py_validation(py_script, vars)
end

function mms_python_validation_ut::test_hpca_brst_moments
  mms_load_hpca, data_rate='brst', datatype='moments', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10']
  py_script = ["from pyspedas import mms_load_hpca", "mms_load_hpca(data_rate='brst', datatype='moments', probe=1, trange=['2015-10-16/13:05', '2015-10-16/13:10'])"]
  vars = ['mms1_hpca_hplus_number_density', 'mms1_hpca_hplus_ion_bulk_velocity', 'mms1_hpca_hplus_scalar_temperature', 'mms1_hpca_oplus_number_density', 'mms1_hpca_oplus_ion_bulk_velocity', 'mms1_hpca_oplus_scalar_temperature']
  return, spd_run_py_validation(py_script, vars)
end

pro mms_python_validation_ut::setup
  del_data, '*'
end

pro mms_python_validation_ut__define
  define = { mms_python_validation_ut, inherits MGutTestCase }
end