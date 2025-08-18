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
;   spinmodel->interp_t,time=input_times,$
;      spincount=output_spincount, spinper=output_spinper,$
;      t_last=output_sun_pulse_times, segflag=output_segflag, eclipse_delta_phi=delta_phi
;
;  INPUTS:
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
;  model->interp_t,time=input_times,spinphase=output_spinphase
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

; Helper routine to apply spin phase corrections
pro thm_spinmodel::adjust_spinphase,time=time,spinphase=spinphase

self->get_info,start_time=start_time,end_time=end_time

min_time = min(time,/nan,max=max_time)

if start_time-min_time gt 60*60 || max_time - end_time gt 60*60 then begin
  dprint,'NON-FATAL-ERROR: spinmodel(from state file) failed to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
endif

corr_times=*( self.spincorr_times )
corr_vals=*( self.spincorr_vals )
corr_count=n_elements(corr_times)
first_corr_time=corr_times[0]
first_corr_val= corr_vals[0]

last_corr_time=corr_times[corr_count-1]
last_corr_val= corr_vals[corr_count-1]

; Interpolate corrections using input_times

; Special case: if only one correction is available, e.g. when only
; a single day is loaded in thm_load_state, then that value applies for 
; all time. (interpol needs at least two points or it will bomb).

if (corr_count LT 2) then begin
   interp_correction=replicate(first_corr_val,n_elements(time))
endif else begin
   interp_correction=interpol(corr_vals,corr_times,time)
endelse

; For times before & after spinmodel time range, use nearest
; neighbor instead of extrapolation

idx=where(time LT first_corr_time,count)
if (count GT 0) then interp_correction[idx] = first_corr_val

idx=where(time GE last_corr_time,count)
if (count GT 0) then interp_correction[idx] = last_corr_val

; Apply corrections

corr_spinphase = spinphase - interp_correction

; Map to range [0.0,360.0) deg

idx=where(corr_spinphase LT 0.0D,count)
if (count GT 0) then corr_spinphase[idx] = corr_spinphase[idx] + 360.0D

idx=where(corr_spinphase GE 360.0D,count)
if (count GT 0) then corr_spinphase[idx] = corr_spinphase[idx] - 360.0D

; Pass corrected spin phase back to caller

spinphase = corr_spinphase
end

pro thm_spinmodel::interp_t,time=time,spincount=spincount,t_last=t_last,$
   spinphase=spinphase,spinper=spinper,segflag=segflag,eclipse_delta_phi=eclipse_delta_phi,$
   use_spinphase_correction=use_spinphase_correction

  sp = self.segs_ptr
  if (ptr_valid(sp) NE 1) then begin
    message,'Spinmodel segment pointer is invalid.'
  end

  if (keyword_set(time) NE 1) then begin
     message,'Required TIME keyword argument not present.'
  end

  if (n_elements(use_spinphase_correction) EQ 0) then begin
     use_spinphase_correction=1
     dprint,dlevel=4,'Defaulting to use V03 spin phase correction.'
  end
 
  segs = (*sp)[self->findseg_t(time)]
  segment_interp_t,segs,time,my_spincount,my_t_last,my_spinphase,my_spinper,my_segflag,my_eclipse_delta_phi,mask=3

  if keyword_set(use_spinphase_correction) then begin
    dprint,dlevel=4,'Using spinphase correction'
    self->adjust_spinphase,time=time,spinphase=my_spinphase
  endif else begin
    dprint,dlevel=4,'Not using spinphase correction'
  endelse

  if (arg_present(spincount) EQ 1) then spincount=my_spincount
  if (arg_present(t_last) EQ 1)    then t_last=my_t_last
  if (arg_present(spinphase) EQ 1) then spinphase=my_spinphase
  if (arg_present(spinper) EQ 1)   then spinper=my_spinper
  if (arg_present(segflag) EQ 1)   then segflag=my_segflag
  if (arg_present(eclipse_delta_phi) EQ 1)   then eclipse_delta_phi=my_eclipse_delta_phi

  ; endelse
end
