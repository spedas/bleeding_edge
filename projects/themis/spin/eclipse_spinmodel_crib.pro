pro eclipse_spinmodel_crib

; Feb 13 is the date of a lunar shadow interval for TH-B. The
; eclipse interval is approcimately 09:00-10:00 UTC on that date.
; 
; This is currently the only date for which an FGM-enhanced spin model 
; is available.
;
; Currently the enhanced state CDFs are only available in the
; qa_jwl directory (/disks/themisdata/qa_jwl)
;

timespan,'2010-02-13',1,/day
thm_load_state,probe='b',/get_supp

; Get an array of times to pass to the spinmodel routines

get_data,'thb_state_pos',data=d
input_times=d.x

; Get a spinmodel pointer
smp=spinmodel_get_ptr('b')

; Calculate the spin model spinphase, spin period, and eclipse delta-phi
; for each input time
spinmodel_interp_t,model=smp,time=input_times,spinphase=spinphase,spinper=spinper,eclipse_delta_phi=eclipse_delta_phi

; Make some tplot variables
store_data,'thb_test_spinphase',data={x:input_times, y:spinphase}
store_data,'thb_test_spinper',data={x:input_times, y:spinper}
store_data,'thb_test_delta_phi',data={x:input_times, y:eclipse_delta_phi}

; Plot the data.  Note that the IDPU spin model and FGM spin model
; differ by almost 2 spins by the end of the eclipse.  

tplot,['thb_test_spinphase','thb_test_spinper','thb_test_delta_phi']
end
