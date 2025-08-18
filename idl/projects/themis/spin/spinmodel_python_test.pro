;+
; NAME:
;    SPINMODEL_PYTHON_TEST.PRO
;
; PURPOSE:
;   Load several spin models and export them as CDFs for comparison with Python results
;
; CATEGORY:
;   TDAS 
;
; CALLING SEQUENCE:
;   spinmodel_python_test
;
;  INPUTS:
;    probe:             One value from 'a b c d e'
;    trange:            Time range specified as a 2-element string array
;    correction_level:  An integer, 0 1 or 2, denoting the level of eclipse corrections to use
;    cdf_filename:      The name of the output CDF.   This file can be passed to the themis.state.spinmodel.validate_model routine
;                       to perform the python side of the test.
;  OUTPUTS:
;    A CDF file containing the probe, time range, and correction level used, a dump of the spinmodel attributes, and some interpolation 
;    test data to be reproduced in pyspedas.
;
;  KEYWORDS:
;    None.
;
;  PROCEDURE:
;    
;
;  EXAMPLE:
;     spinmodel_python_test, probe='a',trange=['2008-03-23','2008-04-23'],correction_level=2,cdf_filename='tha_30day_corr2.cdf'
;
;Written by: Jim Lewis (jwl@ssl.berkeley.edu)
;
;-

pro spinmodel_python_test,probe=probe,trange=trange,correction_level=correction_level,cdf_filename=cdf_filename

; Store the test parameters as tplot variables
trange_dbl=time_double(trange)
t_sgl=trange_dbl[0]
probe_idx=strpos('abcde',probe)
interval_delta_t = trange_dbl[1]-trange_dbl[0]
interval_days = interval_delta_t / 86400.0D
store_data,'parm_trange',data={x:trange_dbl,y:trange_dbl}
store_data,'parm_probe',data={x:t_sgl,y:probe_idx}
store_data,'parm_correction_level',data={x:t_sgl,y:correction_level}
parm_varlist=['parm_trange','parm_correction_level','parm_probe']

; Load state data and create the spinmodels

thm_load_state,probe=probe,trange=trange,/get_supp,/keep_spin

; Get the spin model object to test
smp=spinmodel_get_ptr(probe,use_ecl=correction_level)

; Make tplot variables from the model parameters
seg_varlist=smp->make_tplot_vars(prefix='seg_')

; Generate some test timestamps for interpolation
tst_times=time_double(trange[0]) + dindgen(1440*interval_days + 5)*60.0D

; Perform interpolation using the spinmodel
smp->interp_t,time=tst_times,spincount=spincount,spinphase=spinphase,spinper=spinper,eclipse_delta_phi=eclipse_delta_phi,t_last=t_last,segflag=segflag

; Save the interpolated quantities as tplot variables
store_data,'interp_times',data={x:tst_times,y:tst_times}
store_data,'interp_spincount',data={x:tst_times,y:spincount}
store_data,'interp_spinphase',data={x:tst_times,y:spinphase}
store_data,'interp_spinper',data={x:tst_times,y:spinper}
store_data,'interp_t_last',data={x:tst_times,y:t_last}
store_data,'interp_eclipse_delta_phi',data={x:tst_times,y:eclipse_delta_phi}
store_data,'interp_segflags',data={x:tst_times,y:double(segflag)}

; Make a list of all the tplot variables, and store them in the output CDF
interp_dq=['times','spincount','spinphase','spinper','t_last','eclipse_delta_phi','segflags']
interp_varlist='interp_'+interp_dq
cdf_varlist=[parm_varlist,seg_varlist,interp_varlist]
tplot2cdf,filename=cdf_filename,tvars=cdf_varlist,/default_cdf_structure
end
