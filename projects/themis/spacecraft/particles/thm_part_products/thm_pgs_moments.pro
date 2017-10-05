;+
;Procedure:
;  thm_pgs_moments
;
;Purpose:
;  Calculates moments from a simplified particle data structure.
;
;
;Arguments:
;  data: single sanitized data structure
;  
;  
;Input Keywords:
;  get_error: Flag indicating that error esitmates (sigma) should be returned
;  mag_data: Optional array containing magnetic field vectors for all time samples
;  scpot_data: Optional array containing spacecraft potential data for all time samples
;  index: Index into mag_data/scpot_data specifying which sample to use
;
;Output Keywords:
;  moments: Structure output from moments_3d containing the data.
;  sigma: Structure output from moments_3d containing error estimates.
;
;  
;Notes:
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2017-10-02 11:19:09 -0700 (Mon, 02 Oct 2017) $
;$LastChangedRevision: 24078 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_moments.pro $
;-

pro thm_pgs_moments, data, $
                     moments=moments, $
                     sigma=sigma, $
                     delta_times=delta_times,$ ;integration time variable
                     get_error=get_error, $
                     mag_data=mag_data, $
                     sc_pot_data=sc_pot_data, $
                     index=index, $
                     _extra = _extra

    compile_opt idl2, hidden

  
  ;moments_3d requires the following tags but they are not needed for our purposes
  str_element, data, 'valid', 1b, /add_replace
  str_element, data, 'nenergy', dimen1(data.energy), /add_replace
  
  ;set magnetic field if available
  if ~undefined(mag_data) then data.magf = mag_data[index,*]

  ;set potential if available
  if ~undefined(sc_pot_data) then data.sc_pot = sc_pot_data[index]

  ;calculate moments (and errors)
  if keyword_set(get_error) then begin
    ;pass in scaling factor as keyword since moments_3d is a more general routine
    mom = moments_3d(data, dmoments=dmom, unit_scaling=data.scaling, /no_unit_conv, _extra=_extra)
  endif else begin
    mom = moments_3d(data, /no_unit_conv, _extra=_extra)
  endelse

  ;concatenate moments structures  
  if undefined(moments) then begin
    moments = mom
  endif else begin
    moments = [temporary(moments),mom]
  endelse
    
  ;concatenate sigma structures
  if keyword_set(get_error) then begin
    if undefined(sigma) then begin
      sigma = dmom
    endif else begin
      sigma = [temporary(sigma),dmom]
    endelse
  endif

  ;calculate & concatenate integration times, needed for L2 CDFs, and informational for users
  delta_time=data.end_time-data.time
  if undefined(delta_times) then begin
    delta_times=delta_time
  endif else begin
    delta_times=[temporary(delta_times),delta_time]
  endelse

  return

end
