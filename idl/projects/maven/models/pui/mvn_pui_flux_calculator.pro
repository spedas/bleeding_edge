;20170104 Ali
;flux calculator: calculates pickup ion number flux, momentum flux, energy flux, density
;input: nden is pickup ion source neutral density (cm-3)
;output: dphi is pickup ion differential number flux (cm-2 s-1)

function mvn_pui_flux_calculator,nden

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  ifreq=replicate(1.,pui0.np)#pui.model[pui0.msub].ifreq.tot

  dphi=ifreq*(1e2*pui2.dr)*nden; differential number flux (cm-2 s-1)
  deph=pui2.ke*dphi ;differential energy flux (eV cm-2 s-1)
  dmph=(1e5*pui2.mv)*dphi ;differential momentum flux (g cm-1 s-2)
  dnnn=dphi/(1e2*pui2.vtot) ;differential density (cm-3)

  dphide=dphi/abs(pui2.de) ;differential number flux (cm-2 s-1 eV-1)
  dephde=deph/abs(pui2.de) ;differential energy flux (eV cm-2 s-1 eV-1)
  dmphde=dmph/abs(pui2.de) ;differential momentum flux (g cm-1 s-2 eV-1)
  dnnnde=dnnn/abs(pui2.de) ;differential density (cm-3 eV-1)

  ;saving the results into arrays of structures
  pui.model[pui0.msub].params.totphi=total(dphi,1) ;total pickup number flux (cm-2 s-1)
  pui.model[pui0.msub].params.toteph=total(deph,1) ;total pickup energy flux (eV cm-2 s-1)
  pui.model[pui0.msub].params.totmph=total(dmph,1) ;total pickup momentum flux (g cm-1 s-2)
  pui.model[pui0.msub].params.totnnn=total(dnnn,1,/nan) ;total pickup number density (cm-3)
  
  return,dphi
  
end
