;+
;
; Unit tests for hapi_load_data
;
; To run:
;     IDL> mgunit, 'hapi_load_data_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-08-20 11:53:54 -0700 (Mon, 20 Aug 2018) $
; $LastChangedRevision: 25664 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/hapi/hapi_load_data_ut__define.pro $
;-

function hapi_load_data_ut::test_load_cdaweb
  hapi_load_data, server='https://cdaweb.gsfc.nasa.gov/hapi', dataset='MMS2_MEC_SRVY_L2_EPHTS04D', trange=['2015-12-15', '2015-12-16']
  assert, spd_data_exists('mms2_mec_r_gsm mms2_mec_v_gsm', '2015-12-15', '2015-12-16'), 'Problem loading MMS data via CDAWeb'
  return, 1
end

pro hapi_load_data_ut::setup
  del_data, '*'
end

function hapi_load_data_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['hapi_load_data']
  return, 1
end

pro hapi_load_data_ut__define
  define = { hapi_load_data_ut, inherits MGutTestCase }
end