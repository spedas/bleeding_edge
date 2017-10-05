;+
;Procedure:
;  mms_convert_flux_unit
;
;Purpose:
;  Perform unit conversions for MMS particle data structures
;
;Supported Units:
;  flux   -   # / (cm^2 * s * sr * eV)
;  eflux  -  eV / (cm^2 * s * sr * eV)
;  df_cm  -  s^3 / cm^6
;  df     -  s^3 / km^6
;
;  'df_km' and 'psd' are treated as 'df'
;
;Calling Sequence:
;  mms_convert_flux_units, dist, units=units, output=output
;
;Arguments/Keywords:
;  dist: Single MMS 3D particle data structure
;  units: String specifying output units
;  output: Set to named variable that will hold converted structure  
;  
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-10 08:56:27 -0800 (Fri, 10 Mar 2017) $
;$LastChangedRevision: 22934 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_convert_flux_units.pro $
;-
pro mms_convert_flux_units,dist,units=units,output=output

    compile_opt idl2, hidden

output = dist

species_lc = strlowcase(dist.species)

units_in = strlowcase(dist.units_name)

if undefined(units) then begin
  units = 'eflux'
endif

units_out = strlowcase(units)

if units_in eq units_out then begin
  return
endif

;handle synonymous notations
if units_in eq 'df_km' or units_in eq 'psd' then units_in = 'df'
if units_out eq 'df_km' or units_out eq 'psd' then units_out = 'df'

;get mass of species
case species_lc of
   'i': A=1;H+
   'hplus': A=1;H+
   'heplus': A=4;He+
   'heplusplus': A=4;He++
   'oplus': A=16;O+
   'oplusplus': A=16;O++
   'e': A=1d/1836;e-
   else: message, 'Unknown species: '+species_lc
endcase

;scaling factor between df and flux units
flux_to_df = A^2 * 0.5447d * 1d6

;convert between km^6 and cm^6 for df
cm_to_km = 1d30

;calculation will be kept simple and stable as possible by 
;pre-determining the final exponent of each scaling factor 
;rather than multiplying by all applicable in/out factors
;these exponents should always be integers!
;    [energy, flux_to_df, cm_to_km]
in = [0,0,0]
out = [0,0,0]

;get input/output scaling exponents
case units_in of 
  'flux': in = [1,0,0]
  'eflux': 
  'df': in = [2,-1,0]
  'df_cm': in = [2,-1,1]
  else: message, 'Unknown input units: '+units_in
endcase

case units_out of 
  'flux':out = -[1,0,0]
  'eflux': 
  'df': out = -[2,-1,0]
  'df_cm': out = -[2,-1,1]
  else: message, 'Unknown output units: '+units_out
endcase

exp = in + out

;ensure everything is double prec first for numerical stability
;  -target field won't be mutated since it's part of a structure
output.data = double(dist.data) * double(dist.energy)^exp[0] * (flux_to_df^exp[1] * cm_to_km^exp[2])

output.units_name = strlowcase(units)

END
