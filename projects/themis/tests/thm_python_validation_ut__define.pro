;+
;
; OBJECT:
;       thm_python_validation_ut
;
; PURPOSE:
;       This object uses MGUnit to validate THEMIS data products loaded in Python match those loaded in IDL
;
; NOTES:
;       To run:
;         IDL> mgunit, 'thm_python_validation_ut'
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-11-06 14:28:35 -0800 (Fri, 06 Nov 2020) $
; $LastChangedRevision: 29340 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/tests/thm_python_validation_ut__define.pro $
;-

function thm_python_validation_ut::test_l2_efi_probed
  thm_load_efi, probe='d', level='l2', trange=['2015-10-16', '2015-10-17']
  
  pyscript = ["import pyspedas", $
    "pyspedas.themis.efi(probe='d', level='l2', trange=['2015-10-16', '2015-10-17'])"]
  vars = ['thd_efs_dot0_dsl', 'thd_efs_q_mag', 'thd_efs_q_pha', 'thd_eff_dot0_dsl', 'thd_eff_q_mag', 'thd_eff_q_pha', 'thd_eff_e12_efs', 'thd_eff_e34_efs']

  return, spd_run_py_validation(pyscript, vars)
end


;function thm_python_validation_ut::test_l2_fgm
;  thm_load_fgm, level='l2', trange=['2015-10-16', '2015-10-17']
;  
;  pyscript = ["import pyspedas", $
;    "pyspedas.themis.fgm(level='l2', trange=['2015-10-16', '2015-10-17'])"]
;  vars = ['']
;  
;  return, spd_run_py_validation(pyscript, vars)
;end

; the setup procedure runs before each test runs
pro thm_python_validation_ut::setup
  del_data, '*'
end

pro thm_python_validation_ut__define
  define = { thm_python_validation_ut, inherits MGutTestCase }
end