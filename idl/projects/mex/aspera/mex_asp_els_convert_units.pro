;+
;
;PROCEDURE:       MEX_ASP_ELS_CONVERT_UNITS
;
;PURPOSE:         
;                 Converts units for MEX/ASPERA-3 (ELS) data.
;
;INPUTS:          A data structure for ELS and unit name to convert the structure to.
;
;KEYWORDS:
;
;     UNITS:      Returns the array of conversion factors used.
;
;CREATED BY:      Takuya Hara on 2018-01-30.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-04 13:51:13 -0700 (Wed, 04 Apr 2018) $
; $LastChangedRevision: 24995 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_els_convert_units.pro $
;
;-
PRO mex_asp_els_convert_units, data, units, scale=scale
  COMPILE_OPT idl2
  IF (N_PARAMS() EQ 0) THEN RETURN
  IF STRUPCASE(units) EQ STRUPCASE(data.units_name) THEN RETURN

  energy = data.energy
  gf     = data.gf
  dt     = data.integ_t
  mass   = data.mass

  CASE STRUPCASE(data.units_name) OF
     'COUNTS' :  scale = 1.d                                         ; Counts
     'RATE'   :  scale = 1.d * dt                                    ; Counts/sec
     'CRATE'  :  scale = 1.d * dt                                    ; Counts/sec, deadtime corrected
     'EFLUX'  :  scale = 1.d * dt * gf                               ; eV/cm^2-sec-sr-eV
     'FLUX'   :  scale = 1.d * dt * gf * energy                      ; 1/cm^2-sec-sr-eV
     'DF'     :  scale = 1.d * dt * gf * energy^2 * 2./mass/mass*1e5 ; 1/(cm^3-(km/s)^3)
     ELSE: BEGIN
        dprint, 'Unknown starting units: ', data.units_name
        RETURN
     END 
  ENDCASE

  CASE STRUPCASE(units) OF
     'COUNTS' :  scale = scale * 1.d
     'RATE'   :  scale = scale * 1.d / (dt)
     'CRATE'  :  scale = scale * 1.d / (dt)
     'EFLUX'  :  scale = scale * 1.d / (dt * gf)
     'FLUX'   :  scale = scale * 1.d / (dt * gf * energy)
     'DF'     :  scale = scale * 1.d / (dt * gf * energy^2 * 2./mass/mass*1e5 )
     ELSE: BEGIN
        dprint, 'Undefined units: ' + units
        RETURN
     END 
  ENDCASE 

  ; scale to new units
  data.units_name = units
  data.data = data.data * scale
  RETURN
END
