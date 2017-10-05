pro spinmodel_crib
;
; This crib sheet assumes that thm_init is already called, and
; the remote and/or local data dirs contain spin model data.

;
;  First demo: load SPIN and STATE CDFs for probe A, all of June 2007.
;
timespan,'07-06-01',30,/days
thm_load_spin
thm_load_state,probe='a',/GET_SUPPORT_DATA

; Pull the state data out into IDL variables
get_data,'tha_state_spinphase',tha_state_time,tha_state_spinphase
get_data,'tha_state_spinper',dummy,tha_state_spinper

; Get a pointer to probe A's spin model
modelptr=spinmodel_get_ptr('a')

; Perform consistency checks on spin model -- for demo purposes only!
; You normally wouldn't do this every time you load spin data.

print,'Performing consistency checks on spin model...please stand by.'
spinmodel_test,modelptr
spinmodel_test,spinmodel_get_ptr('b')
spinmodel_test,spinmodel_get_ptr('c')
spinmodel_test,spinmodel_get_ptr('d')
spinmodel_test,spinmodel_get_ptr('e')

; Use 'spinmodel_interp_t' to calculate spinper and spinphase at each state CDF
; sample time.
;

spinmodel_interp_t,model=modelptr,time=tha_state_time,spinphase=output_spinphase,spinper=output_spinper

; Calculate differences between STATE and SPIN spinphase values, 
; adjusting differences to lie in the range [-180, +180] degrees

phi_diff=output_spinphase-tha_state_spinphase
i1=where(phi_diff GT 180.0D,count)
if (count GT 0) then phi_diff[i1]=phi_diff[i1] - 360.0D
i2=where(phi_diff LT -180.0D,count)
if (count GT 0) then phi_diff[i2]=phi_diff[i2] + 360.0D

; Plot the differences.  You will see a few spikes where the angular difference
; is on the order of a degree or two.  These represent times when a shadow
; happens to span UTC midnight.  The state file samples just before midnight
; are extrapolated from the sunpulse data immediately preceding the 
; shadow entry (since we only do one UTC day at a time). thm_load_spin
; has added the data from the next UTC day, just after shadow exit,
; so it gets interpolated a little differently, accounting for the angular 
; differences.  Everywhere else, the differences between the STATE and SPIN 
; spinphase data are small (but still possibly significant).

store_data,'tha_spinphase_diffs',data={x:tha_state_time,y:phi_diff}
tplot,'tha_spinphase_diffs'
stop

; Plot the differences in spin period.

store_data,'tha_spinper_diffs',data={x:tha_state_time,y:output_spinper-tha_state_spinper}
tplot,'tha_spinper_diffs'
stop

; 
; Next demo: comparison of thm_interpolate_state and spinmodel_interp_t
; results.
;
; Let's look at probe C, June 8 2007.
timespan,'07-06-08',1,/days

; Load the spin model
thm_load_spin,probe='c'
; Test correctness again
spinmodel_test,spinmodel_get_ptr('c')

; Load the state data
thm_load_state,probe='c',/GET_SUPPORT_DATA

; Load some FGM data, so we have some sample times to interpolate.

thm_load_fgm,level='l1',probe='c'

; We will need some TPLOT structures to accomodate thm_interpolate_state.

get_data,'thc_fgl',data=thx_xxx_in
get_data,'thc_state_spinphase',data=thx_spinphase
get_data,'thc_state_spinper',data=thx_spinper

; 
; Here we pass the FGL sample times to spinmodel_interp_t, putting
; the interpolated spin phase and spin period into IDL variables
;

spinmodel_interp_t,model=spinmodel_get_ptr('c'),time=thx_xxx_in.X,spinphase=model_spinphase,spinper=model_spinper

;
; Here is the equivalent call to thm_interpolate_state
;

interp_result=thm_interpolate_state(thx_xxx_in=thx_xxx_in,thx_spinphase=thx_spinphase,thx_spinper=thx_spinper)

;
; Calculate the spinphase differences between STATE and SPIN interpolation
;

phi_diff=model_spinphase-interp_result.Y

; Adjust for possible wrap at 360 deg
i1=where(phi_diff GT 180.0D,count)
if (count GT 0) then phi_diff[i1]=phi_diff[i1] - 360.0D
i2=where(phi_diff LT -180.0D,count)
if (count GT 0) then phi_diff[i2]=phi_diff[i2] + 360.0D

store_data,'thc_spinphase_diffs',data={x:thx_xxx_in.X,y:phi_diff}

;
; Now plot the spinphase differences for a 20-minute range just after probe 
; C emerges  from shadow.  
;
; Compare this plot to Hannes' phase difference plot for the same time
; range:
;
; http://themis-tmserver1.ssl.berkeley.edu/bugzilla/attachment.cgi?id=8
;

timespan,1181320200.0D,20,/minutes
tplot,'thc_spinphase_diffs'
stop

end
