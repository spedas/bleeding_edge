;+
; NAME:
;    SPINMODEL_INTERP_T.PRO
;
; PURPOSE:
;    Given a spin model and time (or array of times), calculate
;    the spin count, spin phase, spin period, and time of last sun pulse
;    for each input time.
;
; CATEGORY:
;   TDAS
;
; CALLING SEQUENCE:
;   spinmodel_interp_t,model=modelptr,time=input_times,$
;      spincount=output_spincount, spinper=output_spinper,$
;      t_last=output_sun_pulse_times, eclipse_delta_phi=delta_phi
;
;  INPUTS:
;    Model: pointer to s spinmodel structure
;    Time: A double precision scalar or array specifying the input times.
;      If the input is a scalar, all outputs will be scalars; otherwise, 
;      all outputs are arrays having the same size as the input times.
;
;  OUTPUTS:
;    spinper: Optional keyword parameter to receive spin period values.
;    tlast: Optional keyword parameter to receive sun pulse time
;       immediately preceding each input time.
;    spincount: Optional keyword parameter to receive count of spins
;       since the start of the model.
;    spinphase: Optional keyword parameter to receive the spin phase
;       (ranging from 0.0 to 360.0 degrees) at each input time.
;    eclipse_delta_phi: Optional keyword parameter to receive
;       deviation (degrees) between the IDPU's spin model and
;       the sunpulse+fgm spin model. Zero in sunlight, non-zero
;       if in eclipse AND FGM "synthetic" sunpulses were used
;       when the spinmodel was created during L0->L1 processing.
;
;  KEYWORDS:
;
;  /MODEL: Required input keyword argument, specifying a pointer to a 
;      spinmodel structure.
;  /TIME: Required input keyword argument specifying a time or array of times.
;  /SPINPER: Optional keyword argument to receive spin period values.
;  /T_LAST:  Optional keyword argument to receive sun pulse times
;  /SPINCOUNT:  Optional keyword argument to receive spin counts
;  /SPINPHASE:  Optional keyword argument to receive spin phase
;
;  PROCEDURE:
;     Find the spinmodel segment containing the input time.
;     Use b and c segment parameters to determine the spin period,
;       spin phase, and spin count at each input time
;     Invert phi(t) function to find sun pulse time immediately preceding
;       each input time.
;  
;  EXAMPLE:
;
;  ; Assume 'input_times' and 'input_spinphase' already exist as a 
;  ; IDL variables -- perhaps obtained from thm_load_state.
;  ;
;  ; Get a pointer to the spin model for probe A
;  modelptr=spinmodel_get_ptr('a')
;   
;  ; Calculate spin phase at each time from spin model
; 
;  spinmodel_interp_t,model=modelptr,time=input_times,spinphase=output_spinphase
;
;  ; Calculate spinphase differences between spin model and state 
;  phi_diff=output_spinphase-input_spinphase
;  
;  ; Fix wraparounds
;
;  i=where(phi_diff GT 180.0D)
;  i2=where(phi_diff LT -180.0D)
;  phi_diff[i] = phi_diff[i] - 360.0D
;  phi_diff[i2] = phi_diff[i2] + 360.0D
;
;  Plot results
;
;  plot,input_times,phi_diff
;  
;-

pro spinmodel_interp_t,model=model,time=time,spincount=spincount,t_last=t_last,$
   spinphase=spinphase,spinper=spinper,segflag=segflag,eclipse_delta_phi=eclipse_delta_phi,$
   use_spinphase_correction=use_spinphase_correction

  if (keyword_set(model) NE 1) then begin
     message,'Required MODEL keyword argument not present.'
  end

  model->interp_t,time=time,spincount=spincount,t_last=t_last,$
      spinphase=spinphase,spinper=spinper,segflag=segflag,eclipse_delta_phi=eclipse_delta_phi,$
      use_spinphase_correction=use_spinphase_correction

end
