
; Returns Energy Flux given the energy
function mvn_sep_particle_eflux,energy,param=param

common mvn_sep_fluxfit_com, response,  energies,  par,b,c,d,e,f
if keyword_set(param) then par=param



return,flux

end
