;+
;
;PROCEDURE:       VEX_ASP_ELS_CONVERT_UNITS
;
;PURPOSE:         Converts units for the VEX/ASPERA-4/ELS data.
;
;INPUTS:
; 
;      DATA:      Data structure for VEX/ASPERA-4/ELS data.
;
;     UNITS:      Units to convert the structure to. Recognized units are:
;
;                 COUNTS : raw counts
;                 RATE   : raw counts rate
;                 FLUX   : differential number flux (1/cm^2-s-ster-eV)                
;                 EFLUX  : differential energy flux (eV/cm^2-s-ster-eV)
;                 DF     : distribution function    (1/(cm^3-(km/s)^3))
;
;KEYWORDS:
;
;     SCALE:      Returns the array of conversion factors used.
;
;OUTPUTS:         Returns the same data structure in the new units.
;
;CREATED BY:      Takuya Hara on 2023-06-30.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-07-02 16:49:00 -0700 (Sun, 02 Jul 2023) $
; $LastChangedRevision: 31925 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_convert_units.pro $
;
;-
PRO vex_asp_els_convert_units, data, units, scale=scale, verbose=verbose

  COMPILE_OPT idl2

  IF (N_PARAMS() EQ 0) THEN RETURN
  IF units.toupper() EQ (data[0].units_name).toupper() THEN RETURN

  c = 2.99792458D5              ; velocity of light [km/s]
  mass = (5.10998910D5)/(c*c)   ; electron rest mass [eV/(km/s)^2]
  m_conv = 2D5/(mass*mass)      ; mass conversion factor (flux to distribution function)

  ; Get information from input structure
  energy  = data.energy         ; [eV]
  aa      = 0.87d0              ; the active anode area ratio
  gf      = data.gf * aa        ; energy/angle dependent G-factor [cm2-ster-eV/eV]
  dt      = 3.6d0 / 128.d0      ; accumulation time [sec] per energy/angle bin (unsummed)
  
  cnts    = data.cnts
  
  ; Calculate the conversion factors
  CASE units.toupper() OF
     'COUNTS' : scale = 1D                                 ; Raw counts
     'RATE'   : scale = 1D / (dt)                          ; Raw counts/sec
     'EFLUX'  : scale = 1D / (dt * gf)                     ; eV/cm^2-sec-sr-eV
     'FLUX'   : scale = 1D / (dt * gf * energy)            ;  1/cm^2-sec-sr-eV
     'DF'     : scale = 1D / (dt * gf * energy^2 * m_conv) ;  1/(cm^3-(km/s)^3)
     ELSE     : BEGIN
        dprint, dlevel=2, verbose=verbose, 'Unknown units: ', units
        RETURN
     END
  ENDCASE

;  CASE (data[0].units_name).toupper() OF
;     'COUNTS' : scale = 1D                                ; Raw counts			
;     'RATE'   : scale = 1D * dt                           ; Raw counts/sec
;     'EFLUX'  : scale = 1D * dt * gf                      ; eV/cm^2-sec-sr-eV
;     'FLUX'   : scale = 1D * dt * gf * energy             ; 1/cm^2-sec-sr-eV
;     'DF'     : scale = 1D * dt * gf * energy^2. * m_conv ; 1/(cm^3-(km/s)^3)
;     ELSE     : BEGIN
;        dprint, dlevel=2, verbose=verbose, 'Unknown starting units: ', data[0].units_name
;        RETURN
;     END 
;  ENDCASE 

;  CASE units.toupper() OF
;     'COUNTS' : scale = scale * 1D
;     'RATE'   : scale = scale * 1D / (dt)
;     'EFLUX'  : scale = scale * 1D / (dt * gf)
;     'FLUX'   : scale = scale * 1D / (dt * gf * energy)
;     'DF'     : scale = scale * 1D / (dt * gf * energy^2 * m_conv)
;     ELSE     : BEGIN
;        dprint, dlevel=2, verbose=verbose, 'Unknown units: ', units
;        RETURN
;     END
;  ENDCASE 

  ; Scale to new units
  data.units_name = units
  data.data = (cnts - data.bkg) * scale > 0.
  ;data.data = data.data * scale
  RETURN
END 
