; The purpose of this code is to average together SEP electron and ion
; data from all four look directions. 

; It makes three tplot variables:
; MVN_SEP_mean_ion_eflux
; MVN_SEP_mean_electron_eflux
; Attenuator

pro mvn_sep_average_flux, trange = trange,load = load

  if keyword_set (load) then mvn_sep_load, trange = trange, format = 'L2_CDF'
  get_data,  'MVN_SEP1f_ion_eflux', data = ion_1F
  get_data,  'MVN_SEP2f_ion_eflux', data = ion_2F
  get_data,  'MVN_SEP1r_ion_eflux', data = ion_1R
  get_data,  'MVN_SEP2r_ion_eflux', data = ion_2R
  
; get electron flux data
  get_data,  'MVN_SEP1f_electron_eflux', data = electron_1F
  get_data,  'MVN_SEP2f_electron_eflux', data = electron_2F
  get_data,  'MVN_SEP1r_electron_eflux', data = electron_1R
  get_data,  'MVN_SEP2r_electron_eflux', data = electron_2R

  store_data, 'Attenuator', data = ['MVN_SEP1attenuator_state', 'MVN_SEP2attenuator_state']
  options, 'Attenuator', 'colors',[70, 221]
  ylim, 'Attenuator', 0.5, 2.5
  options, 'Attenuator', 'labels',['SEP1', 'SEP2']
  options, 'Attenuator', 'labflag',1
  options, 'Attenuator', 'panel_size', 0.5

; resampled into a single cadence.  Use SEP 1.
; first define variables with the right dimensionality
  electron_eflux_2F = electron_1F.y
  electron_eflux_2R = electron_1f.y
  ion_eflux_2F = ion_1f.y
  ion_eflux_2R = ion_1f.y
   
  for J = 0, n_elements (electron_1F.v[0, *])-1 do begin
     Electron_eflux_2F[*,J] = $
     10.0^interpol (alog10(electron_2F.y[*,J]), electron_2F.x, electron_1F.x, /nan)
     Electron_eflux_2R[*,J] = $
     10.0^interpol (alog10(electron_2R.y[*,J]), electron_2R.x, electron_1R.x, /nan)
  endfor
  for J = 0, n_elements (Ion_1F.v[0. *])-1 do begin
     Ion_eflux_2F[*,J] = $
     10.0^interpol (alog10(Ion_2F.y[*,J]), Ion_2F.x, Ion_1F.x, /nan)
     Ion_eflux_2R[*,J] = $
     10.0^interpol (alog10(Ion_2R.y[*,J]), Ion_2R.x, Ion_1R.x, /nan)
  endfor
 
; calculate average flux
  Electron_eflux_all = [[[electron_1F.y]],[[electron_1R.y]],$
                      [[Electron_eflux_2F]],[[Electron_eflux_2R]]]
  Ion_eflux_all = [[[Ion_1F.y]],[[Ion_1R.y]],$
                      [[Ion_eflux_2F]],[[Ion_eflux_2R]]]

  electron_eflux_mean = mean (electron_eflux_all, dim = 3,/NAN)
  Ion_eflux_mean = mean (Ion_eflux_all, dim = 3,/NAN)
  
  store_data, 'MVN_SEP_mean_ion_eflux', Data = {x:ion_1F.x, y:Ion_eflux_mean, v:Ion_1F.v}
  store_data, 'MVN_SEP_mean_electron_eflux', $
              Data = {x:electron_1F.x, y:Electron_eflux_mean, v:Electron_1F.v}
  
  options,'MVN_SEP_mean*flux', 'spec', 1
  options,'MVN_SEP_mean*flux', 'ylog', 1
  options,'MVN_SEP_mean*flux', 'zlog', 1
  
  options,'MVN_SEP_mean_ion_eflux','ytitle', 'Mean Ions, !C keV'
  options,'MVN_SEP_mean_electron_eflux','ytitle', 'Mean Electrons, !C keV'
  
; z-axis title & limits
   options,'MVN_SEP_mean_*eflux', 'ztitle', 'Diff Flux, !c #/cm2/s/sr/keV'
   ylim, 'MVN_SEP_mean_ion_eflux', 7,1e4, 1
   ylim, 'MVN_SEP_mean_electron_eflux', 10,3e2, 1

   zlim, 'MVN_SEP_mean_ion_eflux', 1, 1e5, 1
   zlim, 'MVN_SEP_mean_electron_eflux', 1, 1e5, 1

end
