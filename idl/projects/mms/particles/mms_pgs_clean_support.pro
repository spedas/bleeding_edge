;+
;Procedure:
;  mms_pgs_clean_support
;
;
;Purpose:
;  Transform and/or interpolate support data to match the particle data.
;
;
;Arguments:
;  times: Array of sample times for particledata
;  probe: String specifying the spacecraft
;
;
;Input Keywords
;  mag_name: String specifying a tplot variable containing magnetic field data
;  sc_pot_name: String specifying a tplot variable containing spacecraft potential data
;  vel_name: String specifying a tplot variable containing velocity data in km/s
;
;
;Output Keywords:
;  mag_out: Array of magnetic field vectors corresponding to TIMES
;  sc_pot_out: Array of spacecraft potential data corresponding to TIMES
;  vel_out: Array of velocity vectors corresponding to TIMES
;
;  
;Notes:
;    
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-08-07 13:36:40 -0700 (Tue, 07 Aug 2018) $
;$LastChangedRevision: 25597 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_pgs_clean_support.pro $
;-

pro mms_pgs_clean_support, times, $
                           probe, $

                           mag_name=mag_tvar_in, $
                           sc_pot_name=sc_pot_tvar_in, $
                           vel_name=vel_tvar_in, $

                           mag_out=mag_out, $
                           sc_pot_out=sc_pot_out, $
                           vel_out=vel_out

    compile_opt idl2, hidden

  

  ; Magnetic field
  ; -----------------------------------------------------------
  ;   -Transform and interpolate magnetic field data if present
  ;   -Ignore & warn if tplot variable is not specified
  ; -----------------------------------------------------------
  if ~undefined(mag_tvar_in) then begin
    if (tnames(mag_tvar_in))[0] ne '' then begin
      ;Sanitize magnetic field data
      mag_temp = mag_tvar_in + '_pgs_temp'
      mms_cotrans,mag_tvar_in,mag_temp,out_coord='gse',probe=probe
      tinterpol_mxn,mag_temp,times,newname=mag_temp,/nan_extrapolate
  
      ;Pass out mag data
      get_data, mag_temp, 0, mag_out
      
      ;Remove temp data
      del_data, mag_temp
      
      dprint,'Using "' + mag_tvar_in + '" as magnetic field for particle calculations.',dlevel=1 
    endif else begin
      dprint, dlevel=1, 'Magnetic field tplot variable not found: "'+mag_tvar_in+'". No field dependent moments will be produced.' 
    endelse
  endif else begin
    if arg_present(mag_tvar_in) then begin
      dprint, dlevel=1, 'No magnetic field specified.  No magnetic field will be used in calibrations.'
    endif
  endelse

  ; Spacecraft Potential
  ; ----------------------------------------------------------
  ;   -Interpolate potential data if present
  ;   -Ignore & warn if tplot variable is not specified
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
      dprint, dlevel=1, 'Spacecraft potential tplot variable not found: "'+sc_pot_tvar_in + '". No spacecraft potential will be used in calibrations.
    endelse
  endif else begin
    if arg_present(sc_pot_tvar_in) then begin
      dprint, dlevel=1, 'No spacecraft potential specified.  No spacecraft potential will be used in calibrations.'
    endif
  endelse
  

  ; Bulk Velocity
  ; ----------------------------------------------------------
  ;   -Interpolate to particle velocity data's time samples
  ;   -Ignore if tplot variable is not specified
  ; ----------------------------------------------------------
  if ~undefined(vel_tvar_in) then begin
    if (tnames(vel_tvar_in))[0] ne '' then begin
      ;Sanitize spacecraft potential
      vel_temp = vel_tvar_in + '_pgs_temp'
      tinterpol_mxn,vel_tvar_in,times,newname=vel_temp,/nan_extrapolate 
    
      ;Pass out velocity data
      get_data, vel_temp, 0, vel_out
      
      ;Remove temp variable
      del_data, vel_temp
      dprint,'Using "' + vel_tvar_in + '" for bulk velocity subtraction.',dlevel=1 
    endif else begin
      dprint, dlevel=1, 'Bulk velocity tplot variable not found: "'+vel_tvar_in + '". No spacecraft potential will be used in calibrations.
    endelse
  endif else begin
    if arg_present(vel_tvar_in) then begin
      dprint, dlevel=1, 'No bulk velocity specified.  Subtraction will not be performed. Use VEL_NAME to specify tplot var.'
    endif
  endelse


  return

end
                         