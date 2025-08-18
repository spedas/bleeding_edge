
;+
;
;PURPOSE:
;  Fetch required spin model data for time tagging of ESA
;  common block structures.
;
;INPUT:
;  model: valid object reference to spin model 
;  time: decommutated header time from ESA packet file 
;
;OUTPUT:
;  adjusted_time: start time of the spin containing heading time
;                 (not in unix time)
;  spin_period: spin period in seconds
;  delta_phi: deviation between IDPU & SP+FGM models (degrees)
;
;NOTES:
;
;
;-
pro thm_esa_spin_adjust, model=model, time=time, $
                         adjusted_time=adjusted_time, $
                         spin_period=spin_period, $
                         eclipse_dphi=eclipse_dphi

  if ~obj_valid(model) then return

  t0 = time_double('2001-1-1/0') ;shift to/from unix time
    
  ;get model variables
  spinmodel_interp_t, model = model, time = t0 + time, $
                      t_last = model_last_pulse, $ ; SP time immediately preceding each input time
;                      spincount = model_count, $   ; count of spins since model start
                      eclipse = model_edphi, $     ; deviation between IDPU & SP+FGM models (deg)
;                      spinphase = model_phase, $   ; phase at each input time
                      spinper = model_per          ; spin period values
  
  if arg_present(adjusted_time) then begin
    ;spin model uses unix times
    model_last_pulse -= t0  
  
    ;time since last pulse
    time_offset = time - model_last_pulse
    
    ;get start time of closest spin
    adjusted_time = model_last_pulse + round(time_offset/model_per) * model_per
    
    ;subtract 1 period if necessary to get current spin 
    if adjusted_time gt time then adjusted_time -= model_per
  endif
  
  if arg_present(spin_period) then spin_period = model_per
  
  if arg_present(eclipse_dphi) then eclipse_dphi = model_edphi

end
