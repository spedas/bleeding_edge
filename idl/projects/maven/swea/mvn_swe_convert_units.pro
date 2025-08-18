;+
;PROCEDURE: 
;	mvn_swe_convert_units
;PURPOSE:
;	Convert units for SPEC, PAD, and 3D data.
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_convert_units, data, units, SCALE=SCALE
;INPUTS: 
;	Data: A 3D, PAD, or SPEC data structure for SWEA
;	Units: Units to convert the structure to.  Recognized units are:
;            COUNTS : raw counts, uncorrected for deadtime
;            RATE   : raw count rate, uncorrected for deadtime
;            CRATE  : count rate, corrected for deadtime
;            FLUX   : differential number flux (1/cm^2-s-ster-eV)
;            EFLUX  : differential energy flux (eV/cm^2-s-ster-eV)
;            E2FLUX : energy flux per energy bin (eV/cm^2-s-ster-bin)
;            DF     : distribution function (1/(cm^3-(km/s)^3))
;KEYWORDS:
;	SCALE: Returns the array of conversion factors used
;OUTPUTS:
;	Returns the same data structure in the new units
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-03-15 12:42:31 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26814 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_convert_units.pro $
;
;-

pro mvn_swe_convert_units, data, units, scale=scale

  compile_opt idl2

  if (n_params() eq 0) then return

  if (strupcase(units) eq strupcase(data[0].units_name)) then return

  c = 2.99792458D5                ; velocity of light [km/s]
  mass = (5.10998910D5)/(c*c)     ; electron rest mass [eV/(km/s)^2]
  m_conv = 2D5/(mass*mass)        ; mass conversion factor (flux to distribution function)

; Get information from input structure

  energy  = data.energy           ; [eV]
  denergy = data.denergy          ; [eV]
  gf      = data.gf*data.eff      ; energy/angle dependent GF with MCP efficiency [cm2-ster-eV/eV]
  dt      = data[0].integ_t       ; integration time [sec] per energy/angle bin (unsummed)
  dt_arr  = data.dt_arr           ; #energies * #anodes per bin for rate and dead time corrections
  dtc     = data.dtc              ; dead time correction: 1. - (raw count rate)*dead

; The dead time correction (dtc) is stored separately in the data structure.
; This makes it possible to convert back and forth between units with and without 
; the dead time correction applied.

; Use the same energy scale factor for adjacent energy steps that are binned.
; (This is not needed for denergy, which is used only for units of e2flux.)

  n_a = 1
  n_e = 64
  grp = replicate(0, n_elements(data))

  str_element, data[0], 'nbins', n_a
  str_element, data[0], 'nenergy', n_e
  str_element, data, 'group', grp

  if (n_e gt 1) then begin
    indx = where(grp eq 1, count)
    if (count gt 0) then begin
      unity = replicate(1.,2)
      energy1 = reform(energy[*,*,indx], n_e, n_a*count)
      for i=0,(n_e-1),2 do energy1[i:(i+1),*] = unity # average(energy1[i:(i+1),*],1)
      energy[*,*,indx] = reform(energy1, n_e, n_a, count)
    endif

    indx = where(grp eq 2, count)
    if (count gt 0) then begin
      unity = replicate(1.,4)
      energy1 = reform(energy[*,*,indx], n_e, n_a*count)
      for i=0,(n_e-1),4 do energy1[i:(i+3),*] = unity # average(energy1[i:(i+3),*],1)
      energy[*,*,indx] = reform(energy1, n_e, n_a, count)
    endif
  endif

; Calculate the conversion factors

  case strupcase(data[0].units_name) of 
    'COUNTS' : scale = 1D				                          ; Raw counts			
    'RATE'   : scale = 1D*dt*dt_arr				                  ; Raw counts/sec
    'CRATE'  : scale = 1D*dtc*dt*dt_arr				              ; Corrected counts/sec
    'E2FLUX' : scale = 1D*dtc*dt*dt_arr*gf / denergy              ; eV/cm^2-sec-sr
    'EFLUX'  : scale = 1D*dtc*dt*dt_arr*gf 		                  ; eV/cm^2-sec-sr-eV
    'FLUX'   : scale = 1D*dtc*dt*dt_arr*gf * energy		          ; 1/cm^2-sec-sr-eV
    'DF'     : scale = 1D*dtc*dt*dt_arr*gf * energy^2. * m_conv   ; 1/(cm^3-(km/s)^3)
    else     : begin
                 print, 'Unknown starting units: ',data[0].units_name
	             return
               end
  endcase

  case strupcase(units) of
    'COUNTS' : scale = scale * 1D
    'RATE'   : scale = scale * 1D/(dt * dt_arr)
    'CRATE'  : scale = scale * 1D/(dtc * dt * dt_arr)
    'E2FLUX' : scale = scale * 1D/(dtc * dt * dt_arr * gf / denergy)
    'EFLUX'  : scale = scale * 1D/(dtc * dt * dt_arr * gf)
    'FLUX'   : scale = scale * 1D/(dtc * dt * dt_arr * gf * energy)
    'DF'     : scale = scale * 1D/(dtc * dt * dt_arr * gf * energy^2 * m_conv)
    else     : begin
                 print, 'Unknown units: ',units
                 return
               end
  endcase

; Scale to new units

  data.units_name = units
  data.data = data.data * scale
  data.var = data.var * (scale*scale)
  data.bkg = data.bkg * scale

  return

end
