;+
;
; OBJECT:
;       general_validation_ut
;
; PURPOSE:
;       This object contains general PySPEDAS validation tests
;
; NOTES:
;       To run:
;         IDL> mgunit, 'general_validation_ut'
;         
; $LastChangedBy: egrimes $
; $LastChangedDate: 2022-04-08 12:53:56 -0700 (Fri, 08 Apr 2022) $
; $LastChangedRevision: 30760 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/python_validation/general_validation_ut__define.pro $
;-

; OMNI data
function general_validation_ut::test_load_omni
  omni_load_data, trange=['2015-10-16', '2015-10-17']
  
  ; notes: 
  ; as of now, the PySPEDAS OMNI load routine doesn't rename to include prefixes
  ;   so we have to do that manually here
  ; the IDL routine loads HRO data by default, and the PySPEDAS routine loads HRO2 data by default
  pyscript = ["from pytplot import tplot_rename", $
    "import pyspedas", $
    "variables = pyspedas.omni.data(trange=['2015-10-16', '2015-10-17'], level='hro')",$
    "for variable in variables: tplot_rename(variable, 'OMNI_HRO_1min_'+variable)"]

  vars = ['OMNI_HRO_1min_BX_GSE', $
          'OMNI_HRO_1min_BY_GSE', $
          'OMNI_HRO_1min_BZ_GSE', $
          'OMNI_HRO_1min_BY_GSM', $
          'OMNI_HRO_1min_BZ_GSM', $
          'OMNI_HRO_1min_flow_speed', $
          'OMNI_HRO_1min_Vx', $
          'OMNI_HRO_1min_Vy', $
          'OMNI_HRO_1min_Vz', $
          'OMNI_HRO_1min_proton_density', $
          'OMNI_HRO_1min_T', $
          'OMNI_HRO_1min_Pressure', $
          'OMNI_HRO_1min_E', $
          'OMNI_HRO_1min_Beta', $
          'OMNI_HRO_1min_AE_INDEX', $
          'OMNI_HRO_1min_AL_INDEX', $
          'OMNI_HRO_1min_AU_INDEX', $
          'OMNI_HRO_1min_SYM_D', $
          'OMNI_HRO_1min_SYM_H', $
          'OMNI_HRO_1min_ASY_D', $
          'OMNI_HRO_1min_ASY_H']

  return, spd_run_py_validation(pyscript, vars)
end

; the setup procedure runs before each test runs
pro general_validation_ut::setup
  del_data, '*'
end

pro general_validation_ut__define
  define = { general_validation_ut, inherits MGutTestCase }
end