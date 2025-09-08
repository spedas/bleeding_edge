;+
;PROCEDURE: avg_data_python_validate
;
;PURPOSE:
;   Generate test data for Python vs IDL validation tests for avg_data routine.
;   
;
;   Creates a file called avg_data_validate.tplot which should be uploaded into:
;   https://github.com/spedas/test_data
;
;   This file is used by pyspedas tests to confirm that IDL and python results are the same.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-09-07 11:18:10 -0700 (Sun, 07 Sep 2025) $
; $LastChangedRevision: 33603 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/python_validate/avg_data_python_validate.pro $
;-

pro avg_data_python_validate, filename

  del_data, '*'

  trange = ['2010-02-13/00:00:00', '2010-02-13/11:59:59']
  probe = 'b'
  varflux = 'thb_peir_en_eflux'
  idl_avg = varflux + '_avg'

  thm_load_esa, probe=probe, trange=trange, level='l2'
  avg_data, varflux

  if ~keyword_set(filename) then filename = 'avg_data_validate'

  vars =  [varflux, idl_avg]
  ;tplot, vars

  tplot_save, vars, filename=filename

  print, 'End avg_data_python_validate'

end
