pro mvn_sta_convert_units, data, units, scale=scale

cc3d=findgen(256)

if n_params() eq 0 then return

if strupcase(units) eq strupcase(data.units_name) then return

n_m = data.nmass
n_e = data.nenergy						; number of energies
nbins=data.nbins						; number of bins
energy = data.energy          					; in eV                (n_e,nbins,n_m)
gf = data.geom_factor*data.gf*data.eff
dt = data.integ_t
mass = data.mass*data.mass_arr
dead = data.dead						; dead time array usec for STATIC
bkg = data.bkg							; background array usec for STATIC

; get COUNTS
tmp = data.cnts

; take out dead time correction
; kgh 2025-02-10 -- this is not needed because we always start with counts 
; taking it out bc it will cause an error if a structure is converted more than once
;if strupcase(data.units_name) ne 'COUNTS' and strupcase(data.units_name) ne 'RATE' then tmp = tmp/dead

; if physical units, remove background
case strupcase(units) of
'COMPRESSED' :  tmp=tmp
'COUNTS' :  tmp=tmp
'RATE'   :  tmp=tmp
'CRATE'  :  tmp=tmp
'EFLUX'  :  tmp = tmp-bkg
'FLUX'   :  tmp = tmp-bkg
'DF'     :  tmp = tmp-bkg
endcase

; dead time correct data if not counts or rate
if strupcase(units) ne 'COUNTS' and strupcase(units) ne 'RATE' then tmp=tmp*dead

scale = 0
case strupcase(units) of
  'COMPRESSED' :  scale = 1.
  'COUNTS' :  scale = 1.d
  'RATE'   :  scale = 1.d/(dt)
  'CRATE'  :  scale = 1.d/(dt)
  'EFLUX'  :  scale = 1.d/(dt * gf)
  'FLUX'   :  scale = 1.d/(dt * gf * energy)
  'DF'     :  scale = 1.d/(dt * gf * energy^2 * 2./mass/mass*1e5 )
  else: begin
    message,'Undefined units: '+units
    return
  end
endcase


; scale to new units
data.units_name = units
if find_str_element(data,'ddata') ge 0 then data.ddata = scale * tmp^.5
data.data = scale * tmp

return
end



