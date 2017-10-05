;+
;Procedure:
;  thm_pgs_clean_support
;
;
;Purpose:
;  Transform and/or interpolate support data to match the particle data.
;
;
;Arguments:
;  times: Array of sample times for particledata
;  probe: String specifying the spacecraft
;  mag_tvar_in: String specifying a tplot variable containing magnetic field data
;  sc_pot_tvar_in: String specifying a tplot variable containing spacecraft potential data
;  
;
;Output Keywords:
;  mag_out: Array of magnetic field vectors corresponding to TIMES
;  sc_pot_out: Array of spacecraft potential data corresponding to TIMES
;
;  
;Notes:
;  If no valid tplot variables are specified for:
;    magnetic field - vector will be [0,0,0] at all times
;    spacecraft potential - will be 0
;    
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-01-28 10:33:29 -0800 (Wed, 28 Jan 2015) $
;$LastChangedRevision: 16765 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_clean_support.pro $
;-

pro thm_pgs_clean_support, times, $
                           probe, $
                           mag_tvar_in, $
                           sc_pot_tvar_in, $
                           mag_out=mag_out, $
                           sc_pot_out=sc_pot_out

    compile_opt idl2, hidden

  

  ; Magnetic field
  ; -----------------------------------------------------------
  ;   -Transform and interpolate magnetic field data if present
  ;   -Ignore if tplot variable is not specified
  ; -----------------------------------------------------------
  if ~undefined(mag_tvar_in) then begin
    if (tnames(mag_tvar_in))[0] ne '' then begin
      ;Sanitize magnetic field data
      mag_temp = mag_tvar_in + '_pgs_temp'
      thm_cotrans,mag_tvar_in,mag_temp,out_coord='dsl',probe=probe
      tinterpol_mxn,mag_temp,times,newname=mag_temp,/nan_extrapolate
  
      ;Pass out mag data
      get_data, mag_temp, 0, mag_out
      
      ;Remove temp data
      del_data, mag_temp
      
      dprint,'Using "' + mag_tvar_in + '" as magnetic field for particle calculations.',dlevel=1 
    endif else begin
      dprint, dlevel=1, 'Magnetic field tplot variable not found: '+mag_tvar_in
    endelse
  endif else begin
    dprint, dlevel=1, 'No magnetic field specified.  No magnetic field will be used in calibrations.'
  endelse


  ; Spacecraft Potential
  ; ----------------------------------------------------------
  ;   -Interpolate potential data if present
  ;   -Ignore if tplot variable is not specified
  ; ----------------------------------------------------------
  if ~undefined(sc_pot_tvar_in) then begin
    if (tnames(sc_pot_tvar_in))[0] ne '' then begin
      ;Sanitize spacecraft potential
      sc_pot_temp = sc_pot_tvar_in + '_pgs_temp'
      tinterpol_mxn,sc_pot_tvar_in,times,newname=sc_pot_temp,/nan_extrapolate 
    
      ;Pass out potential data
      get_data, sc_pot_temp, 0, sc_pot_out
      
      ;Remove temp variable
      del_data, sc_pot_temp
      dprint,'Using "' + sc_pot_tvar_in + '" as spacecraft potential for particle calculations.',dlevel=1 
    endif else begin
      dprint, dlevel=1, 'Spacecraft potential tplot variable not found: '+sc_pot_tvar_in + '. No spacecraft potential will be used in calibrations.
    endelse
  endif else begin
    dprint, dlevel=1, 'No spacecraft potential specified.  No spacecraft potential will be used in calibrations.'
  endelse
  

  return

end
                         