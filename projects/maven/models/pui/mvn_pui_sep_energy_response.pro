;20160930 Ali
;convolves incident energies with the SEP energy response matrix to get SEP-measured energies
;use the keyword plot_response to plot the energy response matrix

pro mvn_pui_sep_energy_response,plot_response=plot_response

@mvn_pui_commonblock.pro ;common mvn_pui_common

if keyword_set(plot_response) then sormd=100 else sormd=pui0.sormd
seprm=replicate(0.,sormd,sormd) ;sep oxygen energy response matrix
for inc=0,sormd-1 do for dep=0,sormd-1 do seprm[dep,inc]=.040*exp(-((dep-.9*inc+40.)/14.)^2) ;Gaussian response, fit to GEANT4 simulations

seprm[0:9,*]=0 ;sep electronic noise threshold = 11 keV
sepde=total(seprm,1) ;sep pickup oxygen detection efficiency
seprm*=replicate(1.,sormd)#sepde ;this makes the response matrix look more realistic!
seprm[where(seprm lt 1e-10,/null)]=1e-10
sepde=total(seprm,1)

if keyword_set(plot_response) then begin
  p=plot(100.*sepde,xrange=[20,100],yrange=[0,100],xtitle='Incident O+ Energy (keV)',ytitle='% of Incident Particles',title='SEP Oxygen Energy Response')
  p=image(100.*transpose(seprm[0:99,0:99]),max_value=8.,margin=.1,axis_style=2,rgb_table=34,xtitle='Incident O+ Energy (keV)',ytitle='Deposited Energy (keV)',title='SEP Oxygen Energy Response')
  p=colorbar(orientation=1,title='% of incident particles')
  return
endif

;  sepet=[[6,10,11,13,14,17,20,24,30,37,47,60,77,100,130,169,220,288,378,495], $ ;SEP1BO flight 3 table
;         [6,10,11,12,14,16,20,24,29,36,46,58,75,97 ,126,164,214,280,367,481]]   ;SEP2BO

for sepn=0,1 do begin
  if ~finite(pui1.sepet[sepn].sepbo[0]) then begin
    bmap=mvn_sep_get_bmap(9,sepn+1); SEP bmap flight3
    pui1.sepet[sepn].sepbo=bmap[128:157].nrg_meas_avg
  endif
  sepet=round(sqrt(pui1.sepet[sepn].sepbo[0:-2]*pui1.sepet[sepn].sepbo[1:-1])) ;sep energy edges (keV)

  sepeb=replicate(0.,pui0.sopeb,pui0.nt) ;sep energy binning
  sepflux=seprm#pui.model[pui0.msub].fluxes.sep[sepn].incident_rate; sep differential flux (/[cm2 s keV]) after convolved with energy response
  for i=0,18 do begin ;binning the energy response convolved flux according to sep energy table
    sepeb[i+1,*]=total(sepflux[sepet[i]:sepet[i+1]-1,*],1)
  endfor
  
  ;reducing the count rates by a factor of 100 when the SEP attenuator is closed
  sepattfac=(99.*pui.data.sep[sepn].att)-98. ;1->1, 2->100
  sepattfac2=transpose(rebin([sepattfac],[pui0.nt,pui0.sopeb])) ;adjusting the dimensions to sepeb
  pui.model[pui0.msub].fluxes.sep[sepn].model_rate=sepeb/sepattfac2
endfor

end