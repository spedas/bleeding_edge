;+
;Procedure:
;  mms_cotrans_crib
;
;Purpose:
;  Demonstrate usage of mms_cotrans
;
;Notes:
;  See also: mms_qcotrans_crib for coordinate transformations using quaternions
;  
;  Supported coordinate systems:
;    -DMPA
;    -DSL  (currently treated as identical to DMPA)
;    -GSE
;    -GSM
;    -AGSM
;    -SM
;    -GEI
;    -J2000
;    -GEO
;    -MAG
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-07 10:41:31 -0800 (Mon, 07 Nov 2016) $
;$LastChangedRevision: 22323 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_cotrans_crib.pro $
;-

;setup
probe = '1'
level = 'l2'

timespan, '2015-10-16/12', 2, /hour
trange = timerange()

; load data
mms_load_fgm, probe=probe, trange=trange, level=level
mms_load_fpi, probe=probe, trange=trange, level=level, datatype=['dis-moms']

; load support data for transformations
mms_load_mec, probe=probe, trange=trange

; example variables to be transformed
v_name = 'mms'+probe+'_dis_bulkv_gse_fast'
b_name = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'

; transform to GSM
mms_cotrans, [v_name,b_name], out_coord='gsm', out_suffix='_gsm'

tplot, [v_name, v_name, b_name, b_name] + ['','_gsm','','_gsm']

stop ;------------------------------------------------------------

; transform to SM
mms_cotrans, [v_name,b_name], out_coord='sm', out_suffix='_sm'
 
tplot, [v_name, v_name, b_name, b_name] + ['','_sm','','_sm']

stop ;------------------------------------------------------------

; use in_suffix to set the suffix of the input variable name
mms_cotrans, b_name, out_coord='gse', in_suffix='_sm', out_suffix='_gse'

tplot, b_name + ['','_sm','_gse']

stop ;------------------------------------------------------------

; in/out coordinates can be set implicitly with suffix keywords
mms_cotrans, v_name, in_suffix='_sm', out_suffix='_gsm'

tplot, v_name + ['','_sm','_gsm']

end