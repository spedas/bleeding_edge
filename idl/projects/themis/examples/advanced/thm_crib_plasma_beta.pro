;Calculate plasma beta using CALC process and THEMIS ESA level 2 data,
;and FGM FGS data

;Load data
timespan, '2022-05-01'
thm_load_esa, level = 'l2', probe = 'a'

;Level 2 ESA data includes magnetic field data in the file, this
;allows the use of the calc process without interpolation. THe
;following can be used in the SPD_GUI. The more advanced calculation,
;using both electron and ion data, and FGS magnetic field, rqeuires
;interpolation.

;Use calc procedure to get ion pressure. The units of density in ESA
;L2 data are 1/cm^3. The units of temperature are eV, so the pressure
;units are eV/cm^3.

calc, '"tha_peif_pressure" = "tha_peif_avgtemp"*"tha_peif_density"'

;Use calc procedure to get total B field
calc, '"tha_peif_btotal" = sqrt(total("tha_peif_magf"^2, 2))'

;Use calc to get magnetic pressure. Units of pressure in THEMIS data
;are eV/cm^3, magnetic pressure is B^2/2*Mu_0, where Mu_0 = 1.25664e-6
;in SI units (H/m), or 12.566 (4pi) in cgs units.
;It is easiest to use cgs; then magnetic pressure is B^2/8*pi, where
;B is in Gauss.  1 Gauss = 1.e5 nT, so that P = B(nT)^2/(8*pi*1e10) in
;ergs/cm^3, and P = B(nT)^2/(8*pi*1e10*1.6e02-12) in eV/cm3.

;The value of mu_0 to use then is 4*!pi*1e10*1.602e-12 = 0.2013
mu_0 = 4.0*!pi*1.602e-2
print, mu_0

;cast the constant value into a string, to input to calc procedure
mu_01 = strtrim(string(2.0*mu_0), 2)
print, mu_01

;If you are using calc from the GUI, it is easier to type in the constant
calc, '"tha_peif_b_pressure" = "tha_peif_btotal"^2/0.402627'

;Then divide for Beta
calc, '"tha_peif_plasma_beta" = "tha_peif_pressure"/"tha_peif_b_pressure"'

tplot, ['tha_peif_pressure','tha_peif_b_pressure','tha_peif_plasma_beta']

stop

;Next a more complicated calculation caclulates total pressure, ions
;plus electrons, and uses THEMIS FGM data to
thm_load_fgm, level = 'l2', probe = 'a'

;use calc procedure to get total pressure for full mode electrons plus
;ions,
calc, '"tha_pe?f_pressure" = "tha_pe?f_avgtemp"*"tha_pe?f_density"'

;Level 2 FGS files include variables for B field magnitude
calc, '"tha_fgs_pressure" = "tha_fgs_btotal"^2/'+mu_01

;total electron plus ion pressure. The interp keyword will 
;interpolate to the peif_pressure time array
calc, '"tha_esa_pressure" = "tha_peif_pressure"+"tha_peef_pressure"', /interp

;finally do the ratio, interpolate again
calc, '"tha_esa_plasma_beta" = "tha_esa_pressure"/"tha_fgs_pressure"', /interp

;Add options
options, '*pressure*', ylog = 1
options, '*pressure*', ysubtitle = '[eV/cm^3]'
options, '*beta', ytitle = 'Plasma Beta'

tplot, ['tha_esa_pressure', 'tha_fgs_pressure', 'tha_esa_plasma_beta']

End
