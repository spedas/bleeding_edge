;the prurpose of this routine is to take an array of structures of SEP
;pad data and turn it into tplot variables
pro mvn_sep_pad_load_tplot, pad
  ; make some tplot variables
  
  electron_energy = mean(pad.electron_energy,dim=2,/nan)
  electron_index = value_locate (pad[0].electron_energy, 30.0)
  store_data,  'SEP_electron_normalized_pad_30keV',data = $
                 {x:pad.time,y:transpose (pad.electron_norm_efluxpa[electron_index,*]),v:pad[0].pitch_angle}, /append
  electron_index = value_locate (pad[0].electron_energy, 100.0)
  store_data,  'SEP_electron_normalized_pad_100keV',data = $
                 {x:pad.time,y:transpose (pad.electron_norm_efluxpa[electron_index,*]),v:pad[0].pitch_angle}, /append
  electron_index = value_locate (pad[0].electron_energy, 50.0)
  store_data,  'SEP_electron_normalized_pad_50keV',data = $
                 {x:pad.time,y:transpose (pad.electron_norm_efluxpa[electron_index,*]),v:pad[0].pitch_angle}, /append
  
  options,'SEP_electron_normalized_pad*','spec', 1
  ylim,'SEP_electron_normalized_pad*',0, 180.0
  zlim,'SEP_electron_normalized_pad*',0, 2.0
  options,'SEP_electron_normalized_pad*','ystyle', 1
  options,'SEP_electron_normalized_pad*','yticks', 6
  options,'SEP_electron_normalized_pad*','yminor', 3
  
  options,'SEP_electron_normalized_pad_30keV','ytitle', 'Electron pitch angle !c 30 keV'
  options,'SEP_electron_normalized_pad_50keV','ytitle', 'Electron pitch angle !c 50 keV'
  options,'SEP_electron_normalized_pad_100keV','ytitle', 'Electron pitch angle !c 100 keV'
  
  options,'SEP_electron_normalized_pad*','ztitle', 'normalized flux'
  
  options, 'SEP_electron_normalized_pad*','no_interp',1
  tplot,'SEP_electron_normalized_pad*keV'
  
 ion_index = value_locate (pad[0].ion_energy, 30.0)
  store_data,  'SEP_ion_normalized_pad_30keV',data = $
                 {x:pad.time,y:transpose (pad.ion_norm_efluxpa[ion_index,*]),v:pad[0].pitch_angle}, /append
  ion_index = value_locate (pad[0].ion_energy, 50.0)
  store_data,  'SEP_ion_normalized_pad_50keV',data = $
                 {x:pad.time,y:transpose (pad.ion_norm_efluxpa[ion_index,*]),v:pad[0].pitch_angle}, /append
    ion_index = value_locate (pad[0].ion_energy, 100.0)
  store_data,  'SEP_ion_normalized_pad_100keV',data = $
                 {x:pad.time,y:transpose (pad.ion_norm_efluxpa[ion_index,*]),v:pad[0].pitch_angle}, /append
     ion_index = value_locate (pad[0].ion_energy, 300.0)
  store_data,  'SEP_ion_normalized_pad_300keV',data = $
                 {x:pad.time,y:transpose (pad.ion_norm_efluxpa[ion_index,*]),v:pad[0].pitch_angle}, /append
ion_index = value_locate (pad[0].ion_energy, 1000.0)
  store_data,  'SEP_ion_normalized_pad_1MeV',data = $
                 {x:pad.time,y:transpose (pad.ion_norm_efluxpa[ion_index,*]),v:pad[0].pitch_angle}, /append
ion_index = value_locate (pad[0].ion_energy, 3000.0)
  store_data,  'SEP_ion_normalized_pad_3MeV',data = $
                 {x:pad.time,y:transpose (pad.ion_norm_efluxpa[ion_index,*]),v:pad[0].pitch_angle}, /append
  options,'SEP_ion_normalized_pad*','spec', 1
  ylim,'SEP_ion_normalized_pad*',0, 180.0
  zlim,'SEP_ion_normalized_pad*',0, 2.0
  options,'SEP_ion_normalized_pad*','ystyle', 1
  options,'SEP_ion_normalized_pad*','yticks', 6
  options,'SEP_ion_normalized_pad*','yminor', 3
  
  options,'SEP_ion_normalized_pad_30keV','ytitle', 'Ion !c pitch angle !c 30 keV'
  options,'SEP_ion_normalized_pad_50keV','ytitle', 'Ion !c pitch angle !c 50 keV'
  options,'SEP_ion_normalized_pad_100keV','ytitle', 'Ion !c pitch  angle !c 100 keV'
  options,'SEP_ion_normalized_pad_300keV','ytitle', 'Ion !c pitch  angle !c 300 keV'
  options,'SEP_ion_normalized_pad_3MeV','ytitle', 'Ion !c pitch  angle !c 3 MeV'
  options,'SEP_ion_normalized_pad_1MeV','ytitle', 'Ion !c pitch  angle !c 1 MeV'
  
  options,'SEP_ion_normalized_pad*','ztitle', 'normalized flux'
  
  options, 'SEP_ion_normalized_pad*','no_interp',1
  options,'mvn_B_1sec_MAVEN_MSO', 'colors', [2,4, 6]
  ylim,'mvn_B_1sec_MAVEN_MSO',[-20,20]
  options,'mvn_B_1sec_MAVEN_MSO','labels',['Bx','By','Bz']
  options,'mvn_B_1sec_MAVEN_MSO','labflag',1
  options,'mvn_B_1sec_MAVEN_MSO','ytitle','B_mso'

end
