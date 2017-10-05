;+
;Procedure:
;  thm_crib_fac
;
;Purpose:
;  A crib on showing how to transform into field aligned coordinates DSL coordinates
;
;Notes:
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-01 13:40:39 -0700 (Fri, 01 May 2015) $
; $LastChangedRevision: 17469 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_fac.pro $
;-

;------------------------------------------------------------
; Example of FAC-Xgse matrix generation and rotation
;------------------------------------------------------------

timespan, '2007-03-23'

thm_load_state,probe='c', /get_support_data
thm_load_fgm,probe = 'c', coord = 'dsl', level = 'l2'

;smooth the Bfield data appropriately
tsmooth2, 'thc_fgs_dsl', 601, newname = 'thc_fgs_dsl_sm601'

;make transformation matrix
thm_fac_matrix_make, 'thc_fgs_dsl_sm601', other_dim='xgse', newname = 'thc_fgs_dsl_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_dsl_sm601_fac_mat', 'thc_fgs_dsl', newname = 'thc_fgs_facx'

tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_facx']
tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

print, 'Just ran an example of FAC-Xgse matrix generation and rotation'

stop

;------------------------------------------------------------
; Example of FAC-Rgeo matrix generation and rotation
;------------------------------------------------------------

timespan, '2007-03-23'

thm_load_state,probe='c', /get_support_data
thm_load_fgm,probe = 'c', coord = 'dsl', level = 'l2'

;smooth the Bfield data appropriately
tsmooth2, 'thc_fgs_dsl', 601, newname = 'thc_fgs_dsl_sm601'

;make transformation matrix
thm_fac_matrix_make, 'thc_fgs_dsl_sm601',other_dim='rgeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_dsl_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_dsl_sm601_fac_mat', 'thc_fgs_dsl', newname = 'thc_fgs_geo'

tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_geo']
tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

print, 'Just ran an example of FAC-Rgeo matrix generation and rotation'

stop

;------------------------------------------------------------
; Example of FAC-Phigeo matrix generation and rotation
;------------------------------------------------------------

timespan, '2007-03-23'

thm_load_state,probe='c', /get_support_data
thm_load_fgm,probe = 'c', coord = 'dsl', level = 'l2'

;smooth the Bfield data appropriately
tsmooth2, 'thc_fgs_dsl', 601, newname = 'thc_fgs_dsl_sm601'

;make transformation matrix
thm_fac_matrix_make, 'thc_fgs_dsl_sm601',other_dim='phigeo', pos_var_name='thc_state_pos', newname = 'thc_fgs_dsl_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_dsl_sm601_fac_mat', 'thc_fgs_dsl', newname = 'thc_fgs_facphi'

tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_facphi']
tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

print, 'Just ran an example of FAC-Phigeo matrix generation and rotation'

stop

;------------------------------------------------------------
; Example of FAC-Phism matrix generation and rotation
;------------------------------------------------------------

timespan, '2007-03-23'

thm_load_state,probe='c', /get_support_data
thm_load_fgm,probe = 'c', coord = 'dsl', level = 'l2'

;smooth the Bfield data appropriately
tsmooth2, 'thc_fgs_dsl', 601, newname = 'thc_fgs_dsl_sm601'

;make transformation matrix
thm_fac_matrix_make, 'thc_fgs_dsl_sm601',other_dim='phism', pos_var_name='thc_state_pos', newname = 'thc_fgs_dsl_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_dsl_sm601_fac_mat', 'thc_fgs_dsl', newname = 'thc_fgs_facphi'

tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_facphi']
tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

print, 'Just ran an example of FAC-Phism matrix generation and rotation'

stop

;------------------------------------------------------------
; Example of FAC-Ygsm matrix generation and rotation
;------------------------------------------------------------

timespan, '2007-03-23'

thm_load_state,probe='c', /get_support_data
thm_load_fgm,probe = 'c', coord = 'dsl', level = 'l2'

;smooth the Bfield data appropriately
tsmooth2, 'thc_fgs_dsl', 601, newname = 'thc_fgs_dsl_sm601'

;make transformation matrix
thm_fac_matrix_make, 'thc_fgs_dsl_sm601',other_dim='ygsm', pos_var_name='thc_state_pos', newname = 'thc_fgs_dsl_sm601_fac_mat'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'thc_fgs_dsl_sm601_fac_mat', 'thc_fgs_dsl', newname = 'thc_fgs_facy'

tplot, ['thc_fgs_dsl', 'thc_fgs_dsl_sm601', 'thc_fgs_facy']
tlimit,'2007-03-23/10:00:00','2007-03-23/13:00:00'

print, 'Just ran an example of FAC-Ygsm matrix generation and rotation'

stop

;------------------------------------------------------------
; Correct non-monotonic timestamps.
;   -If the timestamps of your data are not monotonic you may have 
;    problems doing rotation.  This code sorts and removes duplicates.
;------------------------------------------------------------

timespan,'2008-03-01'

thm_load_state,probe='e', /get_support_data
thm_load_fgm,probe='e',coord='dsl', level = 'l2'

get_data,'the_fgs_dsl',data=d

idx = sort(d.x)

d.x = d.x[idx]
d.y = d.y[idx,*]

idx = where(d.x[1L:n_elements(d.x)-1L]-d.x[0L:n_elements(d.x)-2L] gt 0.) 

d2 = {x:d.x[idx],y:d.y[idx,*]}

store_data,'the_fgs_dsl',data=d2

tsmooth2, 'the_fgs_dsl', 601, newname = 'the_fgs_sm'

thm_fac_matrix_make, 'the_fgs_sm', other_dim='xgse', newname = 'the_fgs_fac'

;transform Bfield vector (or any other) vector into field aligned coordinates
tvector_rotate, 'the_fgs_fac', 'the_fgs_sm', newname = 'the_fgs_rot'

tplot, ['the_fgs_dsl','the_fgs_rot']

stop

end
