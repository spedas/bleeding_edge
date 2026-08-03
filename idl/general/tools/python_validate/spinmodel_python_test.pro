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
;trange_dbl=time_double(trange)
trange=['2008-03-23','2008-04-24']
trange_dbl = time_double(trange)
probe='a'
correction_level=2
t_sgl=trange_dbl[0]
probe_idx=strpos('abcde',probe)
interval_delta_t = trange_dbl[1]-trange_dbl[0]
interval_days = interval_delta_t / 86400.0D
store_data,'parm_trange',data={x:trange_dbl,y:trange_dbl}
store_data,'parm_probe',data={x:t_sgl,y:[probe_idx]}
store_data,'parm_correction_level',data={x:t_sgl,y:[correction_level]}
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

; Test eclipse spin model (vector) correction with some FGM data during eclipses

timespan,'2026-01-01',2,/days
thm_load_fgm, probe='b', level=2
thm_autoload_support,vname='thb_fgs_dsl',probe_in='b',/spinmodel
sm_spin=spinmodel_get_ptr('b', use_eclipse_corrections=2)
sm_wave=spinmodel_get_ptr('b', use_eclipse_corrections=1)

get_data,'thb_fgs_dsl',data=d, dl=dl
times=d.x
y=d.y
x_in = d.y[0,*]
y_in = d.y[1,*]
z_in = d.y[2,*]
spinmodel_interp_t,model=sm_spin,time=times,eclipse_delta_phi=delta_phi
correct_delta_phi_vector,xyz_in=y,delta_phi=delta_phi
store_data,'thb_fgs_dsl_corrected',data={x:d.x, y:y},dl=dl

get_data,'thb_fgl_dsl',data=d, dl=dl
times=d.x
y=d.y
x_in = d.y[0,*]
y_in = d.y[1,*]
z_in = d.y[2,*]
spinmodel_interp_t,model=sm_wave,time=times,eclipse_delta_phi=delta_phi
correct_delta_phi_vector,xyz_in=y,delta_phi=delta_phi
store_data,'thb_fgl_dsl_corrected',data={x:d.x, y:y},dl=dl

sm_varlist=['thb_fgs_dsl', 'thb_fgs_dsl_corrected', 'thb_fgl_dsl', 'thb_fgl_dsl_corrected']

all_varlist=[]
append_array,all_varlist,cdf_varlist
append_array,all_varlist,sm_varlist

thm_load_mom, probe='b', level=2


tens_vars = tnames('*tens')
tens_corrected_vars = tens_vars + '_corrected'

for i=0,n_elements(tens_vars)-1 do begin
  v=tens_vars[i]
  get_data,v,data=d,dl=dl
  tval=d.y
  spinmodel_interp_t,model=sm_spin,time=d.x,eclipse_delta_phi=delta_phi
  correct_delta_phi_tensor,tens=tval,delta_phi=delta_phi
  store_data,v+'_corrected',data={x:d.x,y:tval},dl=dl  
  
endfor

append_array,all_varlist,tens_vars
append_array,all_varlist,tens_corrected_vars

tplot2cdf,filename=cdf_filename,tvars=all_varlist,/default_cdf_structure
end
