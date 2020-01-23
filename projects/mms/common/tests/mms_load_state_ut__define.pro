;+
;
; Unit tests for mms_load_state
;
; To run:
;     IDL> mgunit, 'mms_load_state_ut'
;     
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-01-22 15:01:05 -0800 (Wed, 22 Jan 2020) $
; $LastChangedRevision: 28212 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_state_ut__define.pro $
;-

function mms_load_state_ut::test_j2000_conversion
  mms_load_state, probe='1', datatype='pos', trange=['2015-09-01', '2015-09-02']
  cotrans, 'mms1_defeph_pos', 'mms1_defeph_gei', /j20002gei
  cotrans, 'mms1_defeph_gei', 'mms1_defeph_j2000', /gei2j2000

  get_data, 'mms1_defeph_pos', data=dj2000, dlimits=dlj2000, limits=lj2000
  get_data, 'mms1_defeph_j2000', data=dj20001, dlimits=dlj20001, limits=lj20001

  j2000_mag = sqrt(total(dj2000.y^2,2))
  j20001_mag = sqrt(total(dj20001.y^2,2))

  assert, array_equal(minmax(abs(j2000_mag-j20001_mag)) le 1e-4, [1, 1]), 'Problem with J2000 conversion'
  return, 1
end

; regression test for the MMS/THEMIS/RBSP orbit plots 
function mms_load_state_ut::test_orbit_plots
    ; download the latest orbits plot
    orbitplot = spd_download(remote_file = 'http://themis.ssl.berkeley.edu/themisdata/thg/l0/asi/'+time_string(systime(1)-2*86400., tformat='YYYY/MM')+'/orbit_multi_mission_'+time_string(systime(1)-2*86400., tformat='YYYY-MM-DD')+'_0024.gif')
    read_gif, orbitplot[0], orbitimage, r, g, b
    wherenot255 = where(orbitimage[400:600, 530:630] ne 255) ; should be the part of the plot with the MMS labels
    ; check if the space where the MMS labels are supposed to be are all white (if so, the MMS labels aren't there)
    assert, is_array(wherenot255), 'Problem with orbit plots?'
    return, 1
end

; regression test for bug reported by Tai, 5/3/2016
function mms_load_state_ut::test_coords_correct_for_eci
  mms_load_state, probes=[1, 4], suffix='_teststate'
  assert, cotrans_get_coord('mms1_defeph_pos_teststate') eq 'j2000', 'Problem with the coordinate system of ephemeris data'
  assert, cotrans_get_coord('mms4_defeph_pos_teststate') eq 'j2000', 'Problem with the coordinate system of ephemeris data'
  assert, cotrans_get_coord('mms4_defeph_vel_teststate') eq 'j2000', 'Problem with the coordinate system of velocity data'
  assert, cotrans_get_coord('mms4_defeph_vel_teststate') eq 'j2000', 'Problem with the coordinate system of velocity data'
  return, 1
end

function mms_load_state_ut::test_load_def
  mms_load_state, probe=1, level='def'
  assert, spd_data_exists('mms1_defeph_pos mms1_defeph_vel mms1_defatt_spinras mms1_defatt_spindec', '2015-12-15', '2015-12-16'), 'Problem loading Def State data'
  return, 1
end

function mms_load_state_ut::test_load_pred
  mms_load_state, probe=1, level='pred'
  assert, spd_data_exists('mms1_predeph_pos mms1_predeph_vel mms1_predatt_spinras mms1_predatt_spindec', '2015-12-15', '2015-12-16'), 'Problem loading Pred State data'
  return, 1
end

function mms_load_state_ut::test_load_eph_only
  mms_load_state, probe=1, level='def', /ephemeris_only
  assert, spd_data_exists('mms1_defeph_pos mms1_defeph_vel','2015-12-15', '2015-12-16'), 'Problem loading only ephemeris State data'
  return, 1
end

function mms_load_state_ut::test_load_att_only
  mms_load_state, probe=1, level='def', /attitude_only
  assert, spd_data_exists('mms1_defatt_spinras mms1_defatt_spindec','2015-12-15', '2015-12-16'), 'Problem loading only attitude State data'
  return, 1
end

function mms_load_state_ut::test_multi_probe_star
  mms_load_state, probes='*'
  assert, spd_data_exists('mms1_defeph_pos mms2_defeph_vel mms3_defatt_spinras mms4_defatt_spindec', '2015-12-15', '2015-12-16'), 'Problem loading state data for multiple spacecraft'
  return, 1
end
function mms_load_state_ut::test_multi_probe
  mms_load_state, probes=[1, 2, 3, 4], level='def'
  assert, spd_data_exists('mms1_defeph_pos mms2_defeph_vel mms3_defatt_spinras mms4_defatt_spindec', '2015-12-15', '2015-12-16'), 'Problem loading state data for multiple spacecraft'
  return, 1
end

function mms_load_state_ut::test_multi_probe_mixed_type
  mms_load_state, probes=['1', 2, 3, '4']
  assert, spd_data_exists('mms1_defeph_pos mms2_defeph_vel mms3_defatt_spinras mms4_defatt_spindec', '2015-12-15', '2015-12-16'), 'Problem loading state data with mixed probe types'
  return, 1
end

function mms_load_state_ut::test_load_dtypes
  mms_load_state, probe=1, datatypes='pos' 
  assert, spd_data_exists('mms1_defeph_pos', '2015-12-15', '2015-12-16'), 'Problem loading data type position'
  return, 1
end

function mms_load_state_ut::test_load_dtypes_caps
  mms_load_state, probe=1, datatypes='SPINRAS'
  assert, spd_data_exists('mms1_defatt_spinras', '2015-12-15', '2015-12-16'), 'Problem loading state data types spinras'
  return, 1
end

function mms_load_state_ut::test_load_suffix
  mms_load_state, probe=1, datatypes=['pos', 'vel'], suffix='_test'
  assert, spd_data_exists('mms1_defeph_pos_test mms1_defeph_vel_test', '2015-12-15', '2015-12-16'), 'Problem loading state data using suffix keyword'
  return, 1
end

function mms_load_state_ut::test_trange_pred
  mms_load_state, trange=['2015-12-10', '2015-12-20'], probe=1, datatypes='spindec', level='pred'
  assert, spd_data_exists('mms1_predatt_spindec', '2015-12-11', '2015-12-20'), 'Problem with trange keyword while loading predicted state data'
  assert, ~spd_data_exists('mms1_defatt_spindec', '2015-12-11', '2015-12-20'), 'Problem with trange keyword while loading predicted state data'
  return, 1
end

function mms_load_state_ut::test_trange_no_def_data
  mms_load_state, trange=['2040-07-30', '2040-07-31'], probe=1, datatypes='pos', level='def'
  assert, ~spd_data_exists('mms1_defeph_pos', '2040-07-30', '2040-07-31'), 'Problem with pred_or_def keyword while loading definitive state data'
  assert, ~spd_data_exists('mms1_predeph_pos', '2040-07-30', '2040-07-31'), 'Problem with pred_or_def keyword while loading definitive state data'
  return, 1
end

function mms_load_state_ut::test_trange_def
  start_date = systime(/seconds) + 86400.*10.
  stop_date = start_date + 86400.
  mms_load_state, trange=[start_date, stop_date], probe=1, datatypes='pos', level='def'
  assert, ~spd_data_exists('mms1_defeph_pos', start_date, stop_date), 'Problem with trange keyword while loading definitive state data'
  assert, spd_data_exists('mms1_predeph_pos', start_date, stop_date), 'Problem with trange keyword while loading definitive state data'
  return, 1
end

function mms_load_state_ut::test_trange_pred_or_def
  start_date = systime(/seconds) + 86400.*10.
  stop_date = start_date + 86400.
  mms_load_state, trange=[start_date, stop_date], probe=1, datatypes='pos', level='def', pred_or_def=0
  assert, ~spd_data_exists('mms1_defeph_pos', start_date, stop_date), 'Problem with pred_or_def keyword while loading definitive state data'
  assert, ~spd_data_exists('mms1_predeph_pos', start_date, stop_date), 'Problem with pred_or_def keyword while loading definitive state data'
  return, 1
end   

function mms_load_state_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_state', 'mms_get_state_data']
  return, 1
end

pro mms_load_state_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

pro mms_load_state_ut__define
  define = { mms_load_state_ut, inherits MGutTestCase }
end