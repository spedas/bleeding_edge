;20170605 Ali
;calculates the minimum level of eflux (noise level) in swia and static over the energy and elevation dimensions
;leaves the time and azimuth (anode) dimensions intact to account for varying geometric factor over time and anodes (attenuators, etc.)

function mvn_pui_min_eflux,eflux

minen=exp(min(alog(eflux),/nan,dim=2)) ;min over energy
minel=exp(min(alog(minen),/nan,dim=3)) ;min over elevation

sief=size(eflux,/dim) ;eflux dimensions

if n_elements(sief) eq 4 then begin ;swia (4D)
  minenel=rebin(minel,sief[0],sief[2],sief[1],sief[3]) ;back to 4D array
  minenel2=transpose(minenel,[0,2,1,3]) ;back to original order of dims (time-energy-azimuth-elevation)
endif

if n_elements(sief) eq 5 then begin ;static (5D)
  minenel=rebin(minel,sief[0],sief[2],sief[4],sief[1],sief[3]) ;back to 4D array
  minenel2=transpose(minenel,[0,3,1,4,2]) ;back to original order of dims (time-energy-azimuth-elevation)
endif

return,minenel2

end

