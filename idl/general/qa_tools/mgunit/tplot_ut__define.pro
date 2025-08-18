;+
;
; Warning: this file is under development!
;
; Unit tests for tplot functions base on mgunit
;
; see more ditales here: http://michaelgalloy.com/wp-content/uploads/2013/11/testing-with-idl.pdf
; or here: github.com/mgalloy/mgunit
;
; To run:
;     IDL> mgunit, 'general_ut'
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-02-02 11:32:56 -0800 (Fri, 02 Feb 2018) $
; $LastChangedRevision: 24631 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/qa_tools/mgunit/tplot_ut__define.pro $
;-

; --- CDF creatin test ---
function tplot_ut::test_mms_tplot2cdf_basic
  ; load the data for a date
  mms_load_feeps, trange=['2015-12-15', '2015-12-16'], probe=1
  ; save the omni-directional and spin-averaged omni-directional spectra to a new CDF file
  tplot2cdf, filename='test_feeps_intensity_omni.cdf', tvars=['mms1_epd_feeps_srvy_l2_electron_intensity_omni', 'mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin'], /default
  del_data, '*' ; delete the currently loaded tplot variables
  mms_cdf2tplot, 'test_feeps_intensity_omni.cdf' ; load the CDF file that we just saved
  ; and check that the tplot variables were loaded back into SPEDAS via the call to mms_cdf2tplot.
  assert, spd_data_exists('mms1_epd_feeps_srvy_l2_electron_intensity_omni mms1_epd_feeps_srvy_l2_electron_intensity_omni_spin', '2015-12-15', '2015-12-16'), 'Problem with newly created CDF file'
  return, 1
end

function tplot_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  return, 1
end

pro tplot_ut__define
  define = { tplot_ut, inherits MGutTestCase }
end