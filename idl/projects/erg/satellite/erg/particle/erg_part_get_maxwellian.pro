;+
; Function erg_part_get_maxwellian
;
; ene: energy in eV   ( kbt and ene should be given in the same unit )
; n:   number density in /cc
; kbt: thermal energy in eV
; mass_unit: ion/electron mass in the unit of proton mass
;
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-
function erg_part_get_maxwellian, ene, n, kbt, mass_unit=mass_unit

  ;; n : number density in /cc
  ;; kbt : thermal energy in eV
  ;; returned phase space density values in s^3/km^6
  
  if undefined(mass_unit) then begin
    massunit = 1.D / 1836  ;; for electron
  endif else begin
    massunit = double( mass_unit ) ;; for ions
  endelse

  ;; [ s^3/km^6 ]
  return, n * 1D+12 * ( massunit * 0.166152738436 / kbt )^(3.D/2) * exp( -ene/kbt )
end

