
;+
;Procedure:
;  erg_pgs_limits_range
;
;Purpose:
;  Applies phi, theta, and energy limits to data structure(s) by
;  turning off the corresponding bin flags.
;
;
;Input:
;  data: single sanitized data structure
;  phi: phi min/max (min>max allowed)
;  theta: theta min/max
;  energy: energy min/max
;
;
;Output:
;  Turns off all bins that do not intersect the specified limits.
;
;
;Notes:
;  
;
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-

pro erg_pgs_limit_range, data, phi=phi, theta=theta, energy=energy, no_ang_weighting=no_ang_weighting

  compile_opt idl2, hidden
  
  if ~keyword_set(no_ang_weighting) then no_ang_weighting = 0
  
  ;Apply phi limits
  if keyword_set(phi) then begin
    
    ;phi can be in any order
    p = phi
        
    ;;get min/max phi values for all bins
    if ~no_ang_weighting then begin
      phi_min = (data.phi - 0.5*data.dphi) 
      phi_max = (data.phi + 0.5*data.dphi) mod 360.
    endif else begin
      phi_min = (data.phi - 0) 
      phi_max = (data.phi + 0) mod 360.
    endelse
    
    ;wrap negative values
    ltz = where(phi_min lt 0, nltz)
    if nltz gt 0 then phi_min[ltz] += 360
    
    ;the code below and the phi spectrogram code 
    ;assume maximums at 360 are not wrapped to 0
    zm = where(phi_max eq 0, nzm)
    if nzm gt 0 then phi_max[zm] = 360
    
    ;find which bins were wrapped back into [0,360]
    wrapped = phi_min gt phi_max
    
    ;determine which bins intersect the specified range
    if p[0] gt p[1] then begin
      in_range = ( ((phi_min lt p[1]) or (phi_max gt p[0]))  or  wrapped )
    endif else begin
      in_range = ( (phi_min lt p[1]) and (phi_max gt p[0]) )  or  $
                 ( wrapped and ((phi_min lt p[1]) or (phi_max gt p[0])) )
    endelse

    data.bins = data.bins and in_range
    
  endif
  
  
  ;Apply theta limits
  if keyword_set(theta) then begin
  
    t = minmax(theta)
    
    ;;get min/max angle theta values for all bins
    if ~no_ang_weighting then begin
      theta_min = data.theta - 0.5*data.dtheta
      theta_max = data.theta + 0.5*data.dtheta
    endif else begin
      theta_min = data.theta - 0*data.dtheta
      theta_max = data.theta + 0*data.dtheta
    endelse
    
    ;determine which bins intersect the specified range
    data.bins = data.bins and (theta_min lt t[1]) and (theta_max gt t[0])
  
  endif
  
  
  ;Apply energy limits
  if keyword_set(energy) then begin
  
    e = minmax(energy)
    
    ;since energies are regular no bin width is tracked
    data.bins = data.bins and (data.energy ge e[0]) and (data.energy le e[1])
     
  endif
  
  
end
