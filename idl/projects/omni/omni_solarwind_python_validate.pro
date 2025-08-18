;+
; Procedure:
;  omni_solarwind_python_validate
;
; Purpose:
;  Create a savefile with OMNI solar wind variables.
;  The savefile can be loaded into Python using PySPEDAS to verify that the Python results match the IDL results.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2025-04-13 15:12:57 -0700 (Sun, 13 Apr 2025) $
;$LastChangedRevision: 33257 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_solarwind_python_validate.pro $
;-

pro omni_solarwind_python_validate

  ; load solarwind for 2050, should produce default values only
  del_data, '*'
  trange = ['2050-01-01', '2050-01-01 23:59:59']
  omni_solarwind_load, trange=trange, prefix='omni',  suffix='_idl_default'
  print, tnames()

  ; load solarwind for 2020, HRO dataset
  del_data, 'OMNI_HRO*'
  trange = ['2020-01-01', '2020-01-01 23:59:59']
  omni_solarwind_load, trange=trange, prefix='omni', suffix='_idl_2020'
  print, tnames()

  ; load solarwind for 2021, HRO2 dataset
  del_data, 'OMNI_HRO*'
  trange = ['2021-01-01', '2021-01-01 06:00:00']
  omni_solarwind_load, trange=trange, prefix='omni', suffix='_idl_2021', /hro2
  print, tnames()

  ; Save the data
  ; The following will save a file 'solarwind_python_validate.tplot' in the IDL working dir
  del_data, 'OMNI_HRO*'
  tn = tnames('omni*')
  tplot_save, tn, filename='solarwind_python_validate'
  ; Names saved: omni_BZ_idl_default omni_P_idl_default omni_BZ_idl_2020 omni_P_idl_2020 omni_BZ_idl_2021 omni_P_idl_2021
  print, "Names saved:", tn

end