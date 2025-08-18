
;+
;Procedure:
; spd_slice2d_collate
;
;
;Purpose:
; Collate data aggregated as spd_slice2d_get_data loops over input
; Data aggregation continues until a change in energy or angle 
; bins occurs (mode change or other) or aggregation completes.  
; At those points this procedure is called to average the data, 
; concatenate data to output variables, and clear the appropriate 
; variables for the next loop.
; 
;
;
;Input:
;  data_t: summed data for all bins
;  weight_t: summed weights for all bins
;  
;  rad_in: radial coords
;  phi_in: phi coords
;  theta_in: theta coords
;  
;  dr_in: radial bin widths
;  dp_in: phi bin widths
;  dt_in: theta bin widths
;  
;
;Output:
;  data_out: averaged data
;
;  rad_out: radian coords
;  phi_out: phi coords
;  theta_out: theta corods
;
;  dr_out: radian bin widths
;  dp_out: phi bin widths
;  dt_out: theta bin widths
;  
;  fail:  string output message, set if error occurs
;
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-26 12:33:55 -0700 (Mon, 26 Mar 2018) $
;$LastChangedRevision: 24954 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_collate.pro $
;-
pro spd_slice2d_collate, data_t = data_t, $
                         weight_t = weight_t, $
                         
                         rad_in = rad_in, $
                         phi_in = phi_in, $
                         theta_in = theta_in, $
                         
                         dr_in = dr_in, $
                         dp_in = dp_in, $
                         dt_in = dt_in, $
                         
                         data_out = data_out, $
                         
                         rad_out = rad_out, $
                         phi_out = phi_out, $
                         theta_out = theta_out, $
                         
                         dr_out = dr_out, $
                         dp_out = dp_out, $
                         dt_out = dt_out, $
                         
                         sum_samples=sum_samples, $

                         fail=fail

    compile_opt idl2, hidden

  if ~keyword_set(sum_samples) then begin
    ;Average data over number of time samples containing valid measurements
    data_ave = temporary(data_t) / (weight_t > 1)
  endif else data_ave = temporary(data_t) ; the user requested to sum the samples rather than to average

  ;Remove bins with no valid data.
  ;Each distribution may have a different set of bins active
  ;so this should be done after the data is averaged.
  valid = where(weight_t gt 0, nvalid)
  if nvalid gt 0 then begin
    data_ave = data_ave[valid]
    rad_in = rad_in[valid]
    phi_in = phi_in[valid]
    theta_in = theta_in[valid]
    if keyword_set(dr_in) then begin
      dr_in = dr_in[valid]
      dp_in = dp_in[valid]
      dt_in = dt_in[valid]
    endif
  endif else begin
    fail = 'No valid data in distribution(s).  '+ $
      'This is may be due to stringent energy limits, '+ $
      'count threshold, or other constraints.'
    dprint, dlevel=1, fail
    return
  endelse


  ;Concatenate data and coordinates
  data_out = array_concat(temporary(data_ave),data_out)

  rad_out = array_concat(temporary(rad_in),rad_out)
  phi_out = array_concat(temporary(phi_in),phi_out)
  theta_out = array_concat(temporary(theta_in),theta_out)

  dr_out = array_concat(temporary(dr_in),dr_out)
  dp_out = array_concat(temporary(dp_in),dp_out)
  dt_out = array_concat(temporary(dt_in),dt_out)


  ;This prevents the previous iterations' data and coordinates from being reused.
  ;This block should remain regardless of temporary() usage above.
  if ~undefined(data_t) then undefine, data_t
  if ~undefined(weight_t) then undefine, weight_t
  if ~undefined(rad_in) then undefine, rad_in
  if ~undefined(phi_in) then undefine, phi_in
  if ~undefined(theta_in) then undefine, theta_in
  if ~undefined(dr_in) then undefine, dr_in
  if ~undefined(dp_in) then undefine, dp_in
  if ~undefined(dt_in) then undefine, dt_in
  

end
                               
