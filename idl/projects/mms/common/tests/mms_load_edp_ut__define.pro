;+
;
; Unit tests for mms_load_edp
;
; To run:
;     IDL> mgunit, 'mms_load_edp_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-06-09 14:30:40 -0700 (Tue, 09 Jun 2020) $
; $LastChangedRevision: 28771 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_edp_ut__define.pro $
;-

; the following is a regression test for a bug that occurs with the L2 HFESP CDFs
function mms_load_edp_ut::test_load_hfesp_cdf_bug
    trange = mms_get_roi('2016-02-28/16:00:00',/next)
    mms_load_edp,trange=trange,probes=4,level='l2',data_rate='srvy',datatype='hfesp'
    assert, spd_data_exists('mms4_edp_hfesp_srvy_l2', trange[0], trange[1]), $
      'Problem loading the EDP HFESP data during regression test'
    get_data, 'mms4_edp_hfesp_srvy_l2', data=hfesp_data
    assert, n_elements(hfesp_data.V) eq 322, 'Problem with HFESP regression test'
    return, 1
end

function mms_load_edp_ut::test_load
  mms_load_edp
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms2_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data'
  assert, spd_data_exists('mms3_edp_dce_dsl_fast_l2 mms4_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data'
  return, 1
end

function mms_load_edp_ut::test_multi_probe
  mms_load_edp, probes=[1, 2]
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms2_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data multiprobe'
  return, 1
end

function mms_load_edp_ut::test_multi_probe_mixed_type
  mms_load_edp, probes=['1', 2, 3, '4']
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms2_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data mixed probe type'
  assert, spd_data_exists('mms3_edp_dce_dsl_fast_l2 mms4_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data mixed probe type'
  return, 1
end

function mms_load_edp_ut::test_load_l1a
  mms_load_edp, probe=1, level='l1a'
  assert, ~spd_data_exists('mms1_edp_dce_sensor', '2015-12-15', '2015-12-16'), 'Problem loading l1a edp data'
  return, 1
end

function mms_load_edp_ut::test_load_l1b
  mms_load_edp, probe=1, level='l1b'
  assert, spd_data_exists('mms1_edp_dce_sensor mms1_edp_dcv_sensor', '2015-12-15', '2015-12-16'), 'Problem loading l1b edp data'
  return, 1
end

function mms_load_edp_ut::test_load_l2
  mms_load_edp, probe=1, level='l2'
  assert, spd_data_exists('mms1_edp_dce_gse_fast_l2 mms1_edp_dce_dsl_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading l2 edp data'
  assert, ~spd_data_exists('mms2_edp_dce_gse_fast_l2 mms1_edp_dcv_sensor', '2015-12-15', '2015-12-16'), 'Problem loading l2 edp data'
  return, 1
end

function mms_load_edp_ut::test_load_l2a
  mms_load_edp, probe=1, level=['l2a']
  assert, ~spd_data_exists('mms1_edp_dce_par_epar_fast_l2 mms1_edp_dce_dsl_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading l2a edp data'
  return, 1
end

function mms_load_edp_ut::test_load_l2pre_l2a
  mms_load_edp, probe=1, level=['l2pre', 'l2']
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2pre mms1_edp_dce_par_epar_fast_l2pre', '2015-12-15', '2015-12-16'), 'Problem loading l2pre and l2 edp data'
  assert, spd_data_exists('mms1_edp_dce_gse_fast_l2 mms1_edp_dce_dsl_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading l2pre and l2 edp data'
  return, 1
end

function mms_load_edp_ut::test_load_ql
  mms_load_edp, probe=1, level='ql'
  assert, spd_data_exists('mms1_edp_dce_xyz_dsl mms1_edp_dce_xyz_fac mms1_edp_dce_xyz_res_dsl mms1_edp_dce_xyz_err', '2015-12-15', '2015-12-16'), 'Problem loading ql edp data'
  return, 1
end

function mms_load_edp_ut::test_default_level
  mms_load_edp, probe=1
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms1_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data'
  return, 1
end

function mms_load_edp_ut::test_load_invalid_level
  mms_load_edp, probe=1, level='xxxx'
  assert, ~spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms1_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading ql edp data (invalid level)'
  return, 1
end

function mms_load_edp_ut::test_load_brst
  mms_load_edp, probe=1, data_rate='brst'
  assert, spd_data_exists('mms1_edp_dce_dsl_brst_l2 mms1_edp_dce_par_epar_brst_l2', '2015-12-15', '2015-12-16'), 'Problem loading brst edp data'
  return, 1
end

function mms_load_edp_ut::test_load_brst_ql
  mms_load_edp, probe=1, data_rate='brst', level='ql'
  assert, spd_data_exists('mms1_edp_dce_xyz_dsl mms1_edp_dce_xyz_fac', '2015-12-15', '2015-12-16'), 'Problem loading brst and ql edp data'
  return, 1
end

function mms_load_edp_ut::test_load_fast_caps
  mms_load_edp, probe=1, level='l2', data_rate='FAST'
  assert, spd_data_exists('mms1_edp_dce_gse_fast_l2 mms1_edp_dce_dsl_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading FAST (caps) edp data'
  return, 1
end

function mms_load_edp_ut::test_load_fast_multi_level
  mms_load_edp, probe=1, level=['l2', 'l2a', 'l2pre'], data_rate='FAST'
  assert, spd_data_exists('mms1_edp_dce_gse_fast_l2 mms1_edp_dce_dsl_fast_l2 mms1_edp_dce_dsl_fast_l2pre', '2015-12-15', '2015-12-16'), 'Problem loading multiple levels edp data'
  assert, ~spd_data_exists('mms1_edp_dce_xyz_dsl', '2015-12-15', '2015-12-16'), 'Problem loading multiple levels edp data'
  return, 1
end

function mms_load_edp_ut::test_load_slow
  mms_load_edp, probe=1, data_rate='slow'
  assert, spd_data_exists('mms1_edp_dce_dsl_slow_l2', '2015-12-15', '2015-12-16'), 'Problem loading slow edp data'
  return, 1
end

function mms_load_edp_ut::test_load_slow_l1b
  mms_load_edp, probe=1, data_rate='slow', level='l1b'
  assert, spd_data_exists('mms1_edp_dce_sensor mms1_edp_dcv_sensor', '2015-12-15', '2015-12-16'), 'Problem loading fast edp data'
  assert, ~spd_data_exists('mms1_edp_dce_dsl_slow_l2pre mms1_edp_dce_par_epar_slow_l2pre', '2015-12-15', '2015-12-16'), 'Problem loading slow l1b edp data'
  return, 1
end

; problem with the data in this test
;function mms_load_edp_ut::test_load_slow_sitl
;  mms_load_edp, probe=1, data_rate='slow', level='sitl', trange=['2016-03-01', '2016-03-02']
;  assert, spd_data_exists('mms1_edp_dce_dsl_slow_l2pre mms1_edp_dce_par_epar_slow_l2pre', '2016-04-01', '2016-04-02'), 'Problem loading slow sitl edp data'
;  return, 1
;end

function mms_load_edp_ut::test_load_srvy
  mms_load_edp, probe=1, data_rate='srvy', level='l1b'
  assert, spd_data_exists('mms1_edp_dce_sensor mms1_edp_dcv_sensor', '2015-12-15', '2015-12-16'), 'Problem loading srvy edp data'
  return, 1
end

function mms_load_edp_ut::test_load_srvy_l1b
  mms_load_edp, probe=1, data_rate='srvy', level='l1b'
  assert, spd_data_exists('mms1_edp_dce_sensor mms1_edp_dcv_sensor', '2015-12-15', '2015-12-16'), 'Problem loading srvy l1b edp data'
  return, 1
end

function mms_load_edp_ut::test_load_srvy_l2
  mms_load_edp, probe=1, level='l2', data_rate='srvy', datatype='hfesp'
  assert, spd_data_exists('mms1_edp_hfesp_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading srvy l2 edp data'
  return, 1
end

function mms_load_edp_ut::test_load_dce
  mms_load_edp, probe=1, datatype='dce'
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms1_edp_dce_par_epar_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading dce edp data'
  return, 1
end

function mms_load_edp_ut::test_load_dcv
  mms_load_edp, probe=1, datatype=['dce'], level='l1b', data_rate='brst'
  assert, spd_data_exists('mms1_edp_dcv_sensor', '2015-12-15', '2015-12-16'), 'Problem loading dcv edp data'
  return, 1
end

function mms_load_edp_ut::test_load_suffix
  mms_load_edp, probe=3, data_rate='srvy', level='l1b', suffix='_suffixtest'
  assert, spd_data_exists('mms3_edp_dce_sensor_suffixtest mms3_edp_dcv_sensor_suffixtest', '2015-12-15', '2015-12-16'), 'Problem loading edp data with suffix'
  return, 1
end

function mms_load_edp_ut::test_trange
  mms_load_edp, trange=['2015-12-10', '2015-12-20'], probe=1
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms1_edp_dce_par_epar_fast_l2', '2015-12-10', '2015-12-20'), 'Problem loading edp data with trange keyword'
  return, 1
end

function mms_load_edp_ut::test_timeclip
  mms_load_edp, probe=1, time_clip=['2015-12-15 04:00:00', '2015-12-15 08:00:00']
  assert, spd_data_exists('mms1_edp_dce_dsl_fast_l2 mms1_edp_dce_par_epar_fast_l2', '2015-12-10', '2015-12-20'), 'Problem loading edp data with time clip keyword'
  return, 1
end

function mms_load_edp_ut::test_load_spdf
  mms_load_edp, probe=1, /spdf
  assert, spd_data_exists('mms1_edp_dce_gse_fast_l2', '2015-12-15', '2015-12-16'), 'Problem loading edp data from SPDF'
  return, 1
end

function mms_load_edp_ut::test_load_edp_cdf_filenames
  mms_load_edp, probe=1, /spdf, suffix='_fromspdf', cdf_filenames=spdf_filenames, level='l2'
  mms_load_edp, probe=1, suffix='_fromsdc', cdf_filenames=sdc_filenames, level='l2'
  assert, spd_data_exists('mms1_edp_dce_gse_fast_l2_fromspdf', '2015-12-15', '2015-12-16'), 'Problem loading edp data with from spdf cdf filenames'
  assert, array_equal(strlowcase(spdf_filenames), strlowcase(sdc_filenames)), 'Problem with cdf_filenames keyword (SDC vs. SPDF) for edp data'
  return, 1
end

function mms_load_edp_ut::test_load_edp_coord
  mms_load_edp, probe=1, datatype='dce'
  assert, cotrans_get_coord('mms1_edp_dce_dsl_fast_l2') eq 'dsl', 'Problem with coordinate system in data'
  return, 1
end

function mms_load_edp_ut::test_all_datatypes
  mms_load_edp, probe=2, datatype='*'
  assert, spd_data_exists('mms2_edp_dce_dsl_fast_l2 mms2_edp_scpot_fast_l2 mms2_edp_dcv_fast_l2', '2015-12-15', '2015-12-16'), $
    'Problem loading EDP data with datatype="*"'
  return, 1
end

pro mms_load_edp_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_load_edp_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_edp', 'mms_edp_fix_metadata']
  return, 1
end

pro mms_load_edp_ut__define

  define = { mms_load_edp_ut, inherits MGutTestCase }
end