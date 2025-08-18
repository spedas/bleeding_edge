; Note that this function produces an output that goes from 0 to 360
; degrees, clockwise when looking toward a planet in GSE or MSO or VSO
; coordinates. The perfect example of this is IMF clock angle

; note that, due to its cyclical and limited range nature, error in 
; clock angle must be calculated by interpolating from Monte Carlo simulations

;note that dclock is an OUTPUT.  All other arguments and keywords are inputs.

function clock_angle, by, bz, dby = dby, dbz = dbz, dclock = dclock
  magnitude = sqrt(by*by + bz*bz)
  clock = (by gt 0)*acos(bz/magnitude)/!dtor + $
              (by le 0)*(360.0 - acos(bz/magnitude)/!dtor)

  if keyword_set (dby) and keyword_set (dbz) then begin
     error = sqrt(dby*dby + dbz*dbz)
     quadrature_error = error/magnitude
     location_routine = routine_dir()
     clock_angle_error_file = location_routine + 'clock_angle_error.sav'
     restore, clock_angle_error_file
     dclock = interpol (clock_angle.clock_angle_error, clock_angle.quadrature_error, quadrature_error)
  endif
  return, clock
end

