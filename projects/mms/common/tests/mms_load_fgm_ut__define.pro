;+
;
; Unit tests for mms_load_fgm
;
; To run:
;     IDL> mgunit, 'mms_load_fpi_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fgm_ut__define.pro $
;-

function mms_load_fpi_ut::test_varformat_array_still_flagged
  mms_load_fgm, level='l2', data_rate='srvy', varformat=['*fgm_b_gsm_srvy_l2*', '*fgm_b_gse_srvy_l2*']
  get_data, 'mms1_fgm_flag_srvy_l2', data=flags
  get_data, 'mms1_fgm_b_gsm_srvy_l2_bvec', data=flagged
  assert, ~finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
    'Problem with removing flags in mms_load_fgm (varformat == array)'
  assert, spd_data_exists('mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2 mms1_fgm_flag_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading FGM data with varformat keyword - data not being deflagged?'
  return, 1
end

function mms_load_fgm_ut::test_varformat_still_flagged
  mms_load_fgm, probes=1, level='l2', data_rate='srvy', instrument='fgm', varformat='*fgm_b_gsm_srvy_l2*'
  get_data, 'mms1_fgm_flag_srvy_l2', data=flags
  get_data, 'mms1_fgm_b_gsm_srvy_l2_bvec', data=flagged
  assert, ~finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
    'Problem with removing flags in mms_load_fgm (varformat == string)'
  assert, spd_data_exists('mms1_fgm_b_gsm_srvy_l2 mms1_fgm_flag_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading FGM data with varformat - deflagging broken?'
  return, 1
end

function mms_load_fgm_ut::test_small_brst_interval
    mms_load_fgm, probe=2, level='l2', data_rate='brst', trange=['2015-12-15/10:49', '2015-12-15/10:50']
    assert, spd_data_exists('mms2_fgm_b_gse_brst_l2_bvec mms2_fgm_b_gsm_brst_l2_bvec mms2_fgm_b_bcs_brst_l2_bvec', '2015-12-15/10:49', '2015-12-15/10:50'), $
      'Problem loading FGM data for a small burst interval'
    return, 1
end

function mms_load_fgm_ut::test_get_ephemeris
    mms_load_fgm, probe=2, level='l2', /get_fgm_ephemeris
    assert, spd_data_exists('mms2_fgm_r_gsm_srvy_l2_vec mms2_fgm_r_gse_srvy_l2 mms2_fgm_r_gsm_srvy_l2 mms2_fgm_r_gse_srvy_l2_mag', '2015-12-15', '2015-12-16'), $
      'Problem getting the ephemeris vars from the FGM CDFs'
    return, 1
end

function mms_load_fgm_ut::test_multi_data_rates
    mms_load_fgm, probe=1, level='l2', data_rate=['srvy', 'brst']
    assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2_bvec mms1_fgm_b_dmpa_srvy_l2_bvec', '2015-12-15', '2015-12-16'), $
      'Problem loading FGM data using an array of data rates'
    return, 1
end

function mms_load_fgm_ut::test_load_time_clip
    mms_load_fgm, probe=1, level='l2', trange=['2015-12-15/04:00', '2015-12-15/05:00'], /time_clip, suffix='_clipped'
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec_clipped', '2015-12-15/04:00', '2015-12-15/05:00'), $
      'Problem with time clipping FGM data'
    assert, ~spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec_clipped', '2015-12-15/03:00', '2015-12-15/04:00'), $
      'Problem with time clipping FGM data'
      assert, ~spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec_clipped', '2015-12-15/05:00', '2015-12-15/06:00'), $
      'Problem with time clipping FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_ql
    mms_load_fgm, probe=1, level='ql', instrument='dfg'
    assert, spd_data_exists('mms1_dfg_srvy_dmpa', '2015-12-15', '2015-12-16'), 'Problem loading QL DFG data'
    return, 1
end

function mms_load_fgm_ut::test_load
    mms_load_fgm, probe=1, level='l2'
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2 mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_largeL2
    mms_load_fgm, probe=1, level='L2'
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2 mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_no_split
    mms_load_fgm, probe=1, level='l2', /no_split
    assert, ~spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec mms1_fgm_b_gsm_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem with /no_split_vars keyword'
    return, 1
end

function mms_load_fgm_ut::test_multi_probe
    mms_load_fgm, probes=[1, 2, 3, 4], level='l2'
    assert, spd_data_exists('mms1_fgm_b_gsm_srvy_l2_bvec mms2_fgm_b_gsm_srvy_l2_bvec mms3_fgm_b_gsm_srvy_l2_bvec mms4_fgm_b_gsm_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading FGM data for multiple spacecraft'
    return, 1
end

function mms_load_fgm_ut::test_multi_probe_mixed_type
    mms_load_fgm, probes=['1', 2, 3, '4']
    assert, spd_data_exists('mms1_fgm_b_gsm_srvy_l2_bvec mms2_fgm_b_gsm_srvy_l2_bvec mms3_fgm_b_gsm_srvy_l2_bvec mms4_fgm_b_gsm_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading FGM data for multiple spacecraft'
    return, 1
end

function mms_load_fgm_ut::test_load_spdf
    mms_load_fgm, level='l2', probe=1, /spdf
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2 mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data from SPDF'
    return, 1
end

function mms_load_fgm_ut::test_load_brst
  mms_load_fgm, probe=1, level='l2', data_rate='brst'
  assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2 mms1_fgm_b_gse_brst_l2 mms1_fgm_b_gsm_brst_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
  return, 1
end

function mms_load_fgm_ut::test_load_brst_caps
  mms_load_fgm, probe=1, level='l2', data_rate='BRST'
  assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2_bvec mms1_fgm_b_gse_brst_l2_bvec mms1_fgm_b_gsm_brst_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
  return, 1
end

function mms_load_fgm_ut::test_load_brst_spdf
  mms_load_fgm, level='l2', data_rate='brst', probe=1, /spdf
  assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2 mms1_fgm_b_gse_brst_l2 mms1_fgm_b_gsm_brst_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 burst FGM data from SPDF'
  return, 1
end

function mms_load_fgm_ut::test_load_brst_spdf_caps
    mms_load_fgm, probe=1, level='l2', data_rate='BRST', /spdf
    assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2_bvec mms1_fgm_b_gse_brst_l2_bvec mms1_fgm_b_gsm_brst_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_suffix
    mms_load_fgm, level='l2', probe=3, suffix='_suffixtest'
    assert, spd_data_exists('mms3_fgm_b_gsm_srvy_l2_bvec_suffixtest mms3_fgm_b_dmpa_srvy_l2_suffixtest', '2015-12-15', '2015-12-16'), 'Problem with L2 FGM suffix test'
    return, 1
end

function mms_load_fgm_ut::test_load_coords
    mms_load_fgm, level='l2', probe=2
    assert, cotrans_get_coord('mms2_fgm_b_gsm_srvy_l2_bvec') eq 'gsm', 'Problem with coordinate system in L2 FGM data'
    assert, cotrans_get_coord('mms2_fgm_b_gse_srvy_l2_bvec') eq 'gse', 'Problem with coordinate system in L2 FGM data'
    assert, cotrans_get_coord('mms2_fgm_b_dmpa_srvy_l2_bvec') eq 'dmpa', 'Problem with coordinate system in L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_trange
    mms_load_fgm, trange=['2015-12-10', '2015-12-20'], level='l2', probe=1
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec', '2015-12-11', '2015-12-20'), 'Problem with trange keyword while loading FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_brst_spdf_suffix
    mms_load_fgm, probe=1, level='l2', data_rate='brst', /spdf, suffix='brstdata'
    assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2_bvecbrstdata mms1_fgm_b_gse_brst_l2_bvecbrstdata mms1_fgm_b_gsm_brst_l2_bvecbrstdata', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data from SPDF with suffix keyword'
    return, 1
end

function mms_load_fgm_ut::test_load_fgm_cdf_filenames
    mms_load_fgm, probe=1, level='l2', /spdf, suffix='_fromspdf', cdf_filenames=spdf_filenames
    mms_load_fgm, probe=1, level='l2', suffix='_fromsdc', cdf_filenames=sdc_filenames
    assert, array_equal(strlowcase(spdf_filenames), strlowcase(sdc_filenames)), 'Problem with cdf_filenames keyword (SDC vs. SPDF)'
    return, 1
end

function mms_load_fgm_ut::test_keep_flagged
    mms_load_fgm, probe=1, level='l2', /keep_flagged
    get_data, 'mms1_fgm_flag_srvy_l2', data=flags
    get_data, 'mms1_fgm_b_gsm_srvy_l2_bvec', data=flagged
    assert, finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
      'Problem with keep_flagged keyword in mms_load_fgm'
    return, 1
end

function mms_load_fgm_ut::test_remove_flagged_default
    mms_load_fgm, probe=4, level='l2'
    get_data, 'mms4_fgm_flag_srvy_l2', data=flags
    get_data, 'mms4_fgm_b_gsm_srvy_l2_bvec', data=flagged
    assert, ~finite(flagged.y[(where(flags.Y ne 0))[0], 0]), $
      'Problem with removing flags in mms_load_fgm'
    return, 1
end

function mms_load_fgm_ut::test_load_l2pre_dfg
    mms_load_fgm, instrument='dfg', level='l2pre', probe=1
    assert, spd_data_exists('mms1_dfg_b_dmpa_srvy_l2pre_bvec mms1_dfg_b_gse_srvy_l2pre_bvec mms1_dfg_b_bcs_srvy_l2pre_bvec', '2015-12-15', '2015-12-16'), $
      'Problem loading L2pre DFG data'
    return, 1
end

function mms_load_fgm_ut::test_load_l2pre_afg
  mms_load_fgm, instrument='afg', level='l2pre', probe=1
  assert, spd_data_exists('mms1_afg_b_dmpa_srvy_l2pre_bvec mms1_afg_b_gse_srvy_l2pre_bvec mms1_afg_b_bcs_srvy_l2pre_bvec', '2015-12-15', '2015-12-16'), $
    'Problem loading L2pre AFG data'
  return, 1
end
pro mms_load_fgm_ut::setup
    del_data, '*'
    timespan, '2015-12-15', 1, /day
    ; create a connection to the LASP SDC with team member access
    mms_load_data, login_info='test_auth_info_team.sav', instrument='fgm'
end

function mms_load_fgm_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_fgm', 'mms_split_fgm_data', 'mms_fgm_fix_metadata', 'mms_split_fgm_eph_data']
  return, 1
end

pro mms_load_fgm_ut__define

    define = { mms_load_fgm_ut, inherits MGutTestCase }
end