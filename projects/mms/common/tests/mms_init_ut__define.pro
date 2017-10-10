;+
;
; Unit tests for mms_init
; --> should also validate no conflicts with other init routines:
;  mms_init, thm_init, wind_init, omni_init, istp_init, ace_init, rbsp_spice_init
;  stereo_init, goes_init, fa_init, barrel_init, poes_init
;  elf_init, sd_init, geom_indices_init, iug_init, juno_init, mvn_spd_init
;
; To run:
;     IDL> mgunit, 'mms_init_ut'
; 
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-09 09:19:08 -0700 (Mon, 09 Oct 2017) $
; $LastChangedRevision: 24128 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_init_ut__define.pro $
;-

function mms_init_ut::test_root_data_dir
  current_root_data_dir = getenv('ROOT_DATA_DIR')
  current_mms_data_dir = getenv('MMS_DATA_DIR')
  new_root_data_dir = '/root_data_dir/'
  setenv, "ROOT_DATA_DIR="+new_root_data_dir
  setenv, "MMS_DATA_DIR=" ; so MMS_DATA_DIR doesn't override ROOT_DATA_DIR
  mms_init, /reset
  assert, !mms.local_data_dir eq new_root_data_dir + 'mms/', 'Problem with ROOT_DATA_DIR environment variable'
  setenv, "ROOT_DATA_DIR="+current_root_data_dir
  setenv, "MMS_DATA_DIR="+current_mms_data_dir
  mms_init, /reset
  return, 1
end

function mms_init_ut::test_mms_data_dir
  current_mms_data_dir = getenv('MMS_DATA_DIR')
  new_mms_data_dir = '/mms_data_dir/'
  setenv, "MMS_DATA_DIR="+new_mms_data_dir
  mms_init, /reset
  assert, !mms.local_data_dir eq new_mms_data_dir, 'Problem with MMS_DATA_DIR environment variable'
  setenv, "MMS_DATA_DIR="+current_mms_data_dir ; reset the current MMS_DATA_DIR so this test doesn't clobber the current settings
  mms_init, /reset
  return, 1
end

function mms_init_ut::test_reset
  mms_init, /reset, local_data_dir='/'
  assert, !mms.local_data_dir eq '/', 'Problem resetting local_data_dir with mms_init'
  mms_init, /reset
  return, 1
end

pro mms_init_ut::setup
  del_data, '*'
  timespan, '2015-12-15', 1, /day
end

function mms_init_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0

  return, 1
end

pro mms_init_ut__define
  define = { mms_init_ut, inherits MGutTestCase }
end