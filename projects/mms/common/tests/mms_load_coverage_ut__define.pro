;+
; mms_load_coverage_ut
;  
; This suite tests loading L2 data from the various instruments
; using different tranges throughout the mission; primarily to 
; check for regressions due to file changes/incompatible versions
;
; To run:
;     IDL> mgunit, 'mms_load_coverage_ut'
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2021-08-19 13:57:56 -0700 (Thu, 19 Aug 2021) $
; $LastChangedRevision: 30226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_coverage_ut__define.pro $
;-

function mms_load_coverage_ut::test_load_feeps
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_feeps, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2', datatype='ion'
    assert, spd_data_exists('mms4_epd_feeps_srvy_l2_ion_intensity_omni', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading FEEPS data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_fpi
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_fpi, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2', datatype=['des-moms', 'dis-moms']
    assert, spd_data_exists('mms4_des_energyspectr_omni_fast mms4_dis_energyspectr_omni_fast', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading FPI data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_eis
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_eis, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2'
    assert, spd_data_exists('mms4_epd_eis_srvy_l2_extof_proton_flux_omni', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading EIS data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_fgm
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_fgm, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2'
    assert, spd_data_exists('mms4_fgm_b_gsm_srvy_l2_bvec', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading FGM data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_aspoc
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_aspoc, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2'
    assert, spd_data_exists('mms4_asp1_ionc_l2 mms4_asp2_ionc_l2', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading ASPOC data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_edi
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_edi, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2', datatype='efield'
    assert, spd_data_exists('mms4_edi_e_gsm_srvy_l2', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading EDI data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_hpca
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_hpca, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2', datatype='moments'
    assert, spd_data_exists('mms4_hpca_hplus_number_density', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading HPCA data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_scm
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_scm, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2'
    assert, spd_data_exists('mms4_scm_acb_gse_scsrvy_srvy_l2', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading SCM data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

function mms_load_coverage_ut::test_load_mec
  for m=0, n_elements(self.months_to_test)-1 do begin
    del_data, '*'
    mms_load_mec, probe=4, trange=self.months_to_test[m]+self.days_to_test, level='l2'
    assert, spd_data_exists('mms4_mec_r_eci', self.months_to_test[m]+self.days_to_test[0], self.months_to_test[m]+self.days_to_test[1]), $
      'Problem loading MEC data ('+self.months_to_test[m]+')'
  endfor
  return, 1
end

pro mms_load_coverage_ut::setup
  del_data, '*'
end

function mms_load_coverage_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self.months_to_test = ['2015-12', '2016-01', '2016-02']
  self.days_to_test = ['-15', '-16']
  return, 1
end

pro mms_load_coverage_ut__define
  define = { mms_load_coverage_ut, inherits MGutTestCase, days_to_test: ['-15', '-16'], months_to_test: ['2015-12', '2016-01', '2016-02'] }
end