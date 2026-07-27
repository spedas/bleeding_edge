;+
;PROCEDURE: thm_scpot_python_validate
;
;PURPOSE:
;   Generate test data for Python vs IDL validation tests for THEMIS spacecraft potential routines.
;   
;
;   Creates a file called avg_data_validate.tplot which should be uploaded into:
;   https://github.com/spedas/test_data
;
;   This file is used by pyspedas tests to confirm that IDL and python results are the same.
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-07-23 22:12:53 -0700 (Thu, 23 Jul 2026) $
; $LastChangedRevision: 34670 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/python_validate/thm_scpot_python_validate.pro $
;-

function thm_scpot_validate_single_probe,probe=probe,trange=trange
  thm_load_esa, probe=probe, trange=trange, level='l2'
  get_data,'th'+probe+'_peer_density',data=dens_e
  get_data,'th'+probe+'_peir_density',data=dens_i
  get_data,'th'+probe+'_peer_avgtemp',data=temp_e
  get_data,'th'+probe+'_peer_sc_pot',data=scpot

  scpot_dens = thm_scpot2dens(scpot.y, scpot.x,  temp_e.y, temp_e.x, dens_e.y, dens_e.x, dens_i.y, dens_i.x, probe)
  store_data,'th'+probe+'_scpot2dens',data={x:scpot.x, y:scpot_dens}

  thm_scpot2dens_opt_n, probe=probe, datatype_esa='peer',trange=trange
  vars = ['th'+probe+'_scpot2dens', 'th'+probe+'_peer_density_npot']
  return, vars
end
   


pro thm_scpot_python_validate, filename

  del_data, '*'

  trange = ['2014-09-22','2014-09-23']
  a_vars = thm_scpot_validate_single_probe(probe='a',trange=trange)
  b_vars = thm_scpot_validate_single_probe(probe='b',trange=trange)
  c_vars = thm_scpot_validate_single_probe(probe='c',trange=trange)
  d_vars = thm_scpot_validate_single_probe(probe='d',trange=trange)
  e_vars = thm_scpot_validate_single_probe(probe='e',trange=trange)


  if ~keyword_set(filename) then filename = '/tmp/thm_scpot_validate'

  vars =  [a_vars, b_vars, c_vars, d_vars, e_vars]

  
  print,vars
  
  tplot, vars

  tplot_save, vars, filename=filename

  print, 'End thm_scpot_python_validate'

end
