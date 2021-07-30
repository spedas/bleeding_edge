;+
;
;  Name: CALCULATE_LSHELL
;  
;  Purpose: Calculates the l shell value given spacecraft position data in GSM coordinates
;  
;  Inputs: Spacecraft position vector, an array of [time, x, y, z]
;          where time is double precision, and x, y, z, are in GSM coordinates and have units in RE
;
;  Outputs: The l shell value, or -1L on failure
;
;  Usage: lshell = calculate_lshell(pos_gsm_re)
;  
;  See Also: tkm2re.pro, thm_crib_calculate_lshell.pro
;
;  History:
;
;  Notes: This routine requires IDL geopack routines, returns -1L if not installed
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/calculate_lshell.pro $
;-

FUNCTION calculate_lshell, gsm_re, geopack_2008=geopack_2008

    compile_opt idl2


 if igp_test(geopack_2008=geopack_2008) eq 0 then return, -1L
 
 
  lshell=make_array(n_elements(gsm_re[0,*]), /double)
  
  FOR i=0,n_elements(gsm_re[0,*])-1 do begin
  
    time=time_struct(gsm_re[0,i])
     
    ;recalculate geomagnetic dipole
    geopack_recalc, time.year, time.doy, time.hour, time.min, time.sec, tilt=tilt
    
    ;trace field line from position to equator
    geopack_trace, gsm_re[1,i], gsm_re[2,i], gsm_re[3,i], 1, 0, out_foot_x, $
        out_foot_y, out_foot_z,/igrf,/equator,/refine,rlim=60.0D
  
    ;calculate radial distance at equator
    lshell[i] = sqrt(out_foot_x^2+out_foot_y^2+out_foot_z^2)
  
  ENDFOR
  
  RETURN, lshell

END