;+
;Procedure:
;  thm_crib_fac
;
;Purpose:
;  A crib on showing how to transform into field aligned coordinates DSL coordinates
;
;Notes:
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-03-29 21:53:26 -0700 (Sat, 29 Mar 2025) $
; $LastChangedRevision: 33211 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/fac/fac_matrix_make_python_validate.pro $
;-

;------------------------------------------------------------
; Example of FAC-Xgse matrix generation and rotation
;------------------------------------------------------------

pro fac_matrix_make_python_validate

timespan, '2007-03-23'
del_data,'*'
thm_load_state,probe='c', /get_support_data
thm_load_fgm,probe = 'c', coord = 'gse', level = 'l2'

;smooth the Bfield data appropriately
tsmooth2, 'thc_fgs_gse', 601, newname = 'thc_fgs_gse_sm601'

;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601', other_dim='xgse', newname = 'thc_fgs_gse_sm601_fac_mat_xgse'
thm_fac_matrix_make, 'thc_fgs_gse_sm601', other_dim='xgse', newname = 'thc_fgs_gse_sm601_fac_mat_xgse_thm'
;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_xgse', 'thc_fgs_gse', newname = 'thc_fgs_fac_xgse'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_xgse_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_xgse_thm'

calc," 'diff' = 'thc_fgs_fac_xgse' - 'thc_fgs_fac_xgse_thm'"
tplot,'diff'
stop
;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_fac_xgse']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'



;------------------------------------------------------------
; Example of FAC-Rgeo matrix generation and rotation
;------------------------------------------------------------


;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='rgeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_rgeo'
thm_fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='rgeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_rgeo_thm'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_rgeo', 'thc_fgs_gse', newname = 'thc_fgs_fac_rgeo'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_rgeo_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_rgeo_thm'

calc," 'diff' = 'thc_fgs_fac_rgeo' - 'thc_fgs_fac_rgeo_thm'"
tplot,'diff'
stop

;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_rgeo']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

print, 'Just ran an example of FAC-Rgeo matrix generation and rotation'


;------------------------------------------------------------
; Example of FAC-Phigeo matrix generation and rotation
;------------------------------------------------------------

;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='phigeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_phigeo'
thm_fac_matrix_make,'thc_fgs_gse_sm601',other_dim='phigeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_phigeo_thm'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_phigeo', 'thc_fgs_gse', newname = 'thc_fgs_fac_phigeo'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_phigeo_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_phigeo_thm'

; MISMATCHED!

calc," 'diff' = 'thc_fgs_fac_phigeo' - 'thc_fgs_fac_phigeo_thm'"
tplot,'diff'
stop


;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_fac_phigeo']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

;------------------------------------------------------------
; Example of FAC-mPhigeo matrix generation and rotation
;------------------------------------------------------------

;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='mphigeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_mphigeo'
thm_fac_matrix_make,'thc_fgs_gse_sm601',other_dim='mphigeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_mphigeo_thm'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_mphigeo', 'thc_fgs_gse', newname = 'thc_fgs_fac_mphigeo'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_mphigeo_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_mphigeo_thm'

; MISMATCHED!

calc," 'diff' = 'thc_fgs_fac_mphigeo' - 'thc_fgs_fac_mphigeo_thm'"
tplot,'diff'
stop


;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_fac_phigeo']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'



;------------------------------------------------------------
; Example of FAC-Phism matrix generation and rotation
;------------------------------------------------------------

;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='phism', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_phism'
thm_fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='phism', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_phism_thm'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_phism', 'thc_fgs_gse', newname = 'thc_fgs_fac_phism'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_phism_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_phism_thm'

calc," 'diff' = 'thc_fgs_fac_phism' - 'thc_fgs_fac_phism_thm'"
tplot,'diff'
stop

;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_fac_phism']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'


;------------------------------------------------------------
; Example of FAC-mPhism matrix generation and rotation
;------------------------------------------------------------

;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='mphism', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_mphism'
thm_fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='mphism', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_mphism_thm'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_mphism', 'thc_fgs_gse', newname = 'thc_fgs_fac_mphism'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_mphism_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_mphism_thm'

calc," 'diff' = 'thc_fgs_fac_mphism' - 'thc_fgs_fac_mphism_thm'"
tplot,'diff'
stop

;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_fac_phism']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

;------------------------------------------------------------
; Example of FAC-Ygsm matrix generation and rotation
;------------------------------------------------------------


;make transformation matrix
fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='ygsm', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_ygsm'
thm_fac_matrix_make, 'thc_fgs_gse_sm601',other_dim='ygsm', pos_var_name='thc_state_pos', newname = 'thc_fgs_gse_sm601_fac_mat_ygsm_thm'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_ygsm', 'thc_fgs_gse', newname = 'thc_fgs_fac_ygsm'
tvector_rotate, 'thc_fgs_gse_sm601_fac_mat_ygsm_thm', 'thc_fgs_gse', newname = 'thc_fgs_fac_ygsm_thm'

calc," 'diff' = 'thc_fgs_fac_ygsm' - 'thc_fgs_fac_ygsm_thm'"
tplot,'diff'
stop

;tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_fac_ygsm']
;tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

tvar_list = [ 'thc_fgs_gse', 'thc_fgs_gse_sm601', 'thc_state_pos', $
  'thc_fgs_gse_sm601_fac_mat_xgse', 'thc_fgs_fac_xgse', $
  'thc_fgs_gse_sm601_fac_mat_rgeo', 'thc_fgs_fac_rgeo', $
  'thc_fgs_gse_sm601_fac_mat_phigeo', 'thc_fgs_fac_phigeo', $
  'thc_fgs_gse_sm601_fac_mat_mphigeo', 'thc_fgs_fac_mphigeo', $
  'thc_fgs_gse_sm601_fac_mat_phism', 'thc_fgs_fac_phism', $
  'thc_fgs_gse_sm601_fac_mat_mphism', 'thc_fgs_fac_mphism', $
  'thc_fgs_gse_sm601_fac_mat_ygsm', 'thc_fgs_fac_ygsm',$
  'thc_fgs_gse_sm601_fac_mat_xgse_thm', 'thc_fgs_fac_xgse_thm', $
  'thc_fgs_gse_sm601_fac_mat_rgeo_thm', 'thc_fgs_fac_rgeo_thm', $
  'thc_fgs_gse_sm601_fac_mat_phigeo_thm', 'thc_fgs_fac_phigeo_thm', $
  'thc_fgs_gse_sm601_fac_mat_mphigeo_thm', 'thc_fgs_fac_mphigeo_thm', $
  'thc_fgs_gse_sm601_fac_mat_phism_thm', 'thc_fgs_fac_phism_thm', $
  'thc_fgs_gse_sm601_fac_mat_mphism_thm', 'thc_fgs_fac_mphism_thm', $
  'thc_fgs_gse_sm601_fac_mat_ygsm_thm', 'thc_fgs_fac_ygsm_thm']
 

tplot_save,tvar_list,filename='fac_python_validate'

end
