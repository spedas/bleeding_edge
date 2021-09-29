;+
;
; ene: energy in eV   ( kbt and ene should be given in the same unit )
; df_km: phase space density in [ s^3/km^6 ]
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-
function erg_exponential, x, a

  y = a[0] * exp( a[1] * x ) ;; <-- the fitting function 
  return, [ [ y ], [ exp( a[1]*x ) ], [ a[0] * exp( a[1] * x ) ] ]

end

pro erg_part_maxwellian_fit, ene, df_km, n, kbt, $
                             mass_unit=mass_unit, errors=errors, sigma=sigma, conv=conv

  if undefined(mass_unit) then begin
    massunit = 1.D / 1836  ;; for electron
  endif else begin
    massunit = double( mass_unit ) ;; for ions
  endelse

  ;; Get initial guess
  id = where( df_km gt 0 )
  coefs = linfit( ene[id], alog( df_km[id] ) )
  guess = [ exp(coefs[0]), coefs[1] ]

  ;; Fitting
  a = guess
  for i=0, 4 do begin
    rslt = lmfit( ene, df_km, a, /double, sigma=sigma, measure_errors=errors, $
                  function_name='erg_exponential', conv=conv )
    if conv eq 1 then break
  endfor
  
  kbt = -1.D/a[1] ;; [eV]
  n = a[0] * 1.D-12 * ( -a[1] * massunit * 0.166152738436 )^(-3.D/2) ;; [/cc]
  
  return
end
