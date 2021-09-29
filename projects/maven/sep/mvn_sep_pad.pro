;+
;NAME: MVN_SEP_PAD
; function: mvn_sep_pad
;PURPOSE:
;  the purpose of this routine is to calculate pitch angle
; distributions of solar energetic particles.
;  
;Typical CALLING SEQUENCE:
;  pad = mvn_sep_pad(time, mag_tplot)
;TYPICAL USAGE:
;INPUT:
; time in UNIX format
;KEYWORDS:
; 
;WARNING: this program assumes that the magnetic field tplot variable
;and the SEP L2 data
;has already been loaded.  An example would be 'mvn_B_1sec'

function mvn_sep_pad, mag_tplot, pa_resolution = pa_resolution, $
                      tplot_electron = tplot_electron, $
                      tplot_ion = tplot_ion
  if not keyword_set (pa_resolution) then pa_resolution = 10.0; degrees

; first get the ion flux data
; get ion flux data
  get_data,  'mvn_L2_sep1f_ion_flux', data = ion_1F
  get_data,  'mvn_L2_sep2f_ion_flux', data = ion_2F
  get_data,  'mvn_L2_sep1r_ion_flux', data = ion_1R
  get_data,  'mvn_L2_sep2r_ion_flux', data = ion_2R
  
  ion_energy = mean_dims (ion_1f.v, 1)
  n_ion_energy = n_elements (ion_energy)
  
; make tplot variables for ion energy flux
  store_data,'mvn_L2_sep1f_ion_eflux', data = {x: ion_1f.x, y: ion_1f.y*ion_1f.v, v:ion_energy}
  store_data,'mvn_L2_sep1r_ion_eflux', data = {x: ion_1r.x, y: ion_1r.y*ion_1r.v, v:ion_energy}
  store_data,'mvn_L2_sep2f_ion_eflux', data = {x: ion_2f.x, y: ion_2f.y*ion_2f.v, v:ion_energy}
  store_data,'mvn_L2_sep2r_ion_eflux', data = {x: ion_2r.x, y: ion_2r.y*ion_2r.v, v:ion_energy}
  get_data,  'mvn_L2_sep1f_ion_eflux', data = ion_1F
  get_data,  'mvn_L2_sep2f_ion_eflux', data = ion_2F
  get_data,  'mvn_L2_sep1r_ion_eflux', data = ion_1R
  get_data,  'mvn_L2_sep2r_ion_eflux', data = ion_2R


  
; get electron flux data
  get_data,  'mvn_L2_sep1f_elec_flux', data = electron_1F
  get_data,  'mvn_L2_sep2f_elec_flux', data = electron_2F
  get_data,  'mvn_L2_sep1r_elec_flux', data = electron_1R
  get_data,  'mvn_L2_sep2r_elec_flux', data = electron_2R

; make tplot variables for electron energy flux
  electron_energy = mean_dims (electron_1f.v, 1)
  store_data,'mvn_L2_sep1f_electron_eflux', $
             data = {x: electron_1f.x, y: electron_1f.y*electron_1f.v, v:electron_energy}
  store_data,'mvn_L2_sep1r_electron_eflux', $
             data = {x: electron_1r.x, y: electron_1r.y*electron_1r.v, v:electron_energy}
  store_data,'mvn_L2_sep2f_electron_eflux', $
             data = {x: electron_2f.x, y: electron_2f.y*electron_2f.v, v:electron_energy}
  store_data,'mvn_L2_sep2r_electron_eflux', $
             data = {x: electron_2r.x, y: electron_2r.y*electron_2r.v, v:electron_energy}

  get_data,  'mvn_L2_sep1f_electron_eflux', data = electron_1F
  get_data,  'mvn_L2_sep2f_electron_eflux', data = electron_2F
  get_data,  'mvn_L2_sep1r_electron_eflux', data = electron_1R
  get_data,  'mvn_L2_sep2r_electron_eflux', data = electron_2R
  
  n_electron_energy =n_elements (electron_energy)

;; now interpolate sep 2 ions and electrons to sep 1 cadence
  nt1 = n_elements(ion_1F.x)
  nt2 = n_elements(ion_2F.x)
  
  ion_flux_1f = ion_1f.y
  ion_flux_1r = ion_1r.y
  
  ion_flux_2f = fltarr (nt1,n_ion_energy)
  ion_flux_2r = fltarr (nt1,n_ion_energy)
  for J = 0, n_ion_energy -1 do begin  & $
     ion_flux_2f[*, J] = log_interpol(ion_2f.y[*, J], ion_2f.x, ion_1f.x) & $
     ion_flux_2r[*, J] = log_interpol(ion_2r.y[*, J], ion_2r.x, ion_1f.x) & $
     endfor 

  electron_flux_1f = electron_1f.y
  electron_flux_1r = electron_1r.y

  electron_flux_2f = fltarr (nt1,n_electron_energy)
  electron_flux_2r = fltarr (nt1,n_electron_energy)
  for J = 0, n_electron_energy -1 do begin  & $
     electron_flux_2f[*, J] = log_interpol(electron_2f.y[*, J], electron_2f.x, electron_1f.x) & $
     electron_flux_2r[*, J] = log_interpol(electron_2r.y[*, J], electron_2r.x, electron_1f.x) & $
  endfor 
     
; now calculate the pitch angles
  get_data, 'sep_1f_full_fov', data = full_1f
  get_data, 'sep_1r_full_fov', data = full_1r
  get_data, 'sep_2f_full_fov', data = full_2f
  get_data, 'sep_2r_full_fov', data = full_2r
  
  dims_full = size (full_1f.y,/dimensions)
  nphi = dims_full [1]
  ntheta = dims_full[2]

  
; now get the magnetometer data
  get_data,mag_tplot, data = mag

; we need all the quantities (fov, mag) interpolated to the sep data cadence
  
  bx = interpol(mag.y[*,0], mag.x, ion_1F.x,/nan)
  by = interpol(mag.y[*,1], mag.x, ion_1F.x,/nan)
  bz = interpol(mag.y[*,2], mag.x, ion_1F.x,/nan)
  ;bx = mag.y[*,0]
  ;by = mag.y[*,1]
  ;bz = mag.y[*,2]
  b = transpose ([[bx],[by],[bz]])
  bmag = sqrt(bx^2 + by^2 + bz^2)
  nmag = n_elements (bmag)

;calculate the angle between the magnetic field and the fields of
;view.  HOWEVER, note that the direction of the particles is opposite
;to the direction of the field of view!!!!
  nfov = 4
  pa = fltarr(nfov,nphi, ntheta, nt1)
  time = full_1f.x
  count = 0L
  for M = 0,nfov-1 do begin &$
     case M of &$
        0:fovthis = full_1f.y  &$
        1:fovthis = full_1r.y  &$
        2:fovthis = full_2f.y  &$
        3:fovthis = full_2r.y  &$
     endcase &$
        for J = 0,nphi-1 do begin &$
           for L = 0, ntheta -1 do begin &$
              fovx = interpol (fovthis[*, J,L,0],time,ion_1F.x,/nan) &$
              fovy = interpol (fovthis[*, J,L,1],time,ion_1F.x,/nan) &$
              fovz = interpol (fovthis[*, J,L,2],time,ion_1F.x,/nan) &$
              fov = transpose ([[fovx],[fovy],[fovz]]) &$
;; multiply by -1.0 because the field of view is in the opposite
;direction of the particle motion!!
              pa[M,J,L,*] = angle_between_vectors(b,-1.0*fov)/!dtor &$; now it's in degrees
     count++ &$
     print, count*100.0/(nfov*nphi*1.0*ntheta), '% done'& $
     endfor &$
     endfor &$
     endfor

; now to find an evenly spaced array of pitch angles.  The array
; should be similar in resolution to the resolution of the FOV
; division
     dpa = pa_resolution
     npa = 180.0/dpa
     pa_array = array(dpa*0.5, 180.0 - dpa*0.5, npa)
     pa_edges = array(0.0, 180.0,npa+1)
; assume we're going to interpolate everything to sep1
     ion_efluxpa = fltarr(nt1,n_ion_energy, npa)*sqrt(-5.5)
     ion_norm_efluxpa = ion_efluxpa

     electron_efluxpa = fltarr(nt1, n_electron_energy, npa)*sqrt(-5.5)
     
     electron_norm_efluxpa = electron_efluxpa
     
; calculate an array of zeros and ones representing whether a given
; pitch angle bin center is encompassed by one of the four sep FOVs
     fov_indices = intarr(4,npa,nt1)
     count = 0L
     for J = 0, nt1-1 do begin &$
     for M = 0, npa-1 do begin &$
        for L = 0, nfov-1 do begin & $
; is it encompassed?
        yes = total(pa[L,*,*,J] gt pa_edges[m] and pa[L,*,*,J] lt pa_edges[m+1])& $
        fov_indices[L,M,J] = yes gt 0 & $
        count++ &$
        ;print, count*100.0/(nfov*npa*1.0*nmag), ' %' &$
        endfor &$
        endfor &$
        endfor

; now for every energy and pitch angle bin, we have to interpolate
;between the magnetic field cadence
        
     for J = 0, n_ion_energy -1 do begin & $
        for M = 0, npa-1 do begin & $
        ion_efluxpa[*,J, M] = $
        reform((fov_indices [0,M,*]*ion_flux_1f[*, J] + $
                fov_indices [1,M,*]*ion_flux_1r[*, J]+ $
                fov_indices [2,M,*]*ion_flux_2f[*, J] + $
                fov_indices [3,M,*]*ion_flux_2r[*, J])/total (fov_indices [*,M,*],1))& $
        endfor & $
        endfor

        for M = 0, npa-1 do ion_norm_efluxpa[*, *,M] = $
           ion_efluxpa[*,*, M]/mean(ion_efluxpa,dimension =3,/nan)
        
   for J = 0, n_electron_energy -1 do begin & $
        for M = 0, npa-1 do begin & $
        electron_efluxpa[*,J, M] = $
        reform((fov_indices [0,M,*]*electron_flux_1f[*, J] + $
                fov_indices [1,M,*]*electron_flux_1r[*, J]+ $
                fov_indices [2,M,*]*electron_flux_2f[*, J] + $
                fov_indices [3,M,*]*electron_flux_2r[*, J])/total (fov_indices [*,M,*],1))& $
        endfor & $
        endfor

    for M = 0, npa-1 do electron_norm_efluxpa[*, *,M] = $
       electron_efluxpa[*, *,M]/mean(electron_efluxpa,dimension =3,/nan)

; store all of the pitch angle distributions in a structure
    
    result = $
       {time:0.0d, bmso:fltarr(3), pitch_angle:reform (pa_array),  ion_energy: reform (ion_energy), $
        electron_energy: electron_energy, $
        Gyroradius_electron: fltarr(n_electron_energy),$
        gyroradius_proton: fltarr(n_ion_energy),$
        gyroradius_oxygen: fltarr(n_ion_energy),$
        ion_efluxpa:reform (ion_efluxpa[0,*,*]), ion_norm_efluxpa:reform (ion_norm_efluxpa[0,*,*]), $
        electron_efluxpa:reform (electron_efluxpa[0,*,*]), $
        electron_norm_efluxpa:reform (electron_norm_efluxpa[0,*,*])}

    result = replicate (result,nt1)

    result.time = ion_1f.x
    result.bmso = b
    result.pitch_angle = replicate_array (pa_array,nt1)
    result.ion_energy = replicate_array (ion_energy,nt1)
    result.electron_energy = replicate_array (electron_energy,nt1)

    result.gyroradius_electron = $
       gyroradius(bmag##replicate (1.0,n_electron_energy),$
                  1e3*electron_energy#replicate (1.0,nt1),/electron)
    result.gyroradius_proton = $
       gyroradius(bmag##replicate (1.0,n_ion_energy),$
                  1e3*ion_energy#replicate (1.0,nt1),/proton)
    result.gyroradius_oxygen = $
       gyroradius(bmag##replicate (1.0,n_ion_energy),$
                  1e3*ion_energy#replicate (1.0,nt1),/ion, mass = 16)
    
    result.ion_efluxpa = transpose (ion_efluxpa,[1,2,0])
    result.ion_norm_efluxpa = transpose (ion_norm_efluxpa,[1,2,0])
    result.electron_efluxpa = transpose (electron_efluxpa,[1,2,0])
    result.electron_norm_efluxpa = transpose (electron_norm_efluxpa,[1,2,0])
    
   
; make some tplot variables
    if keyword_set (tplot_electron) then begin
       electron_index = value_locate (electron_energy, 30.0)
       store_data,  'sep_electron_normalized_pad_30keV',data = $
                    {x:ion_1f.x,y:reform (electron_norm_efluxpa[*,electron_index,*]),$
                     v:pa_array}, /append
       electron_index = value_locate (electron_energy, 100.0)
       store_data,  'sep_electron_normalized_pad_100keV',data = $
                    {x:ion_1f.x,y:reform (electron_norm_efluxpa[*,electron_index,*]),$
                     v:pa_array}, /append
       electron_index = value_locate (electron_energy, 50.0)
       store_data,  'sep_electron_normalized_pad_50keV',data = $
                    {x:ion_1f.x,y:reform (electron_norm_efluxpa[*,electron_index,*]),$
                     v:pa_array}, /append
       options,'sep_electron_normalized_pad*','spec', 1
       ylim,'sep_electron_normalized_pad*',0, 180.0
       zlim,'sep_electron_normalized_pad*',0, 2.0
       options,'sep_electron_normalized_pad*','ystyle', 1
       options,'sep_electron_normalized_pad*','yticks', 6
       options,'sep_electron_normalized_pad*','yminor', 3
       
       options,'sep_electron_normalized_pad_30keV','ytitle', 'Electron pitch angle !c 30 keV'
       options,'sep_electron_normalized_pad_50keV','ytitle', 'Electron pitch angle !c 50 keV'
       options,'sep_electron_normalized_pad_100keV','ytitle', 'Electron pitch angle !c 100 keV'
       
       options,'sep_electron_normalized_pad*','ztitle', 'Normalized energy flux'
       
       options, 'sep_electron_normalized_pad*','no_interp',1

       store_data,  'sep_electron_pad_30keV',data = $
                    {x:ion_1f.x,y:reform (electron_efluxpa[*,electron_index,*]),$
                     v:pa_array}, /append
       electron_index = value_locate (electron_energy, 100.0)
       store_data,  'sep_electron_pad_100keV',data = $
                    {x:ion_1f.x,y:reform (electron_efluxpa[*,electron_index,*]),$
                     v:pa_array}, /append
       electron_index = value_locate (electron_energy, 50.0)
       store_data,  'sep_electron_pad_50keV',data = $
                    {x:ion_1f.x,y:reform (electron_efluxpa[*,electron_index,*]),$
                     v:pa_array}, /append
       options,'sep_electron_pad*','spec', 1
       ylim,'sep_electron_pad*',0, 180.0
       zlim,'sep_electron_pad*',0, 2.0
       options,'sep_electron_pad*','ystyle', 1
       options,'sep_electron_pad*','yticks', 6
       options,'sep_electron_pad*','yminor', 3
       
       options,'sep_electron_pad_30keV','ytitle', 'Electron pitch angle !c 30 keV'
       options,'sep_electron_pad_50keV','ytitle', 'Electron pitch angle !c 50 keV'
       options,'sep_electron_pad_100keV','ytitle', 'Electron pitch angle !c 100 keV'
       
       options,'sep_electron_pad*','ztitle', 'Energy flux keV/cm!e2!n/s/sr/keV'
       
       options, 'sep_electron_pad*','no_interp',1

    endif
    if keyword_set (tplot_ion) then begin
       ion_index = value_locate (ion_energy, 30.0)
       store_data,  'sep_ion_normalized_pad_30keV',data = $
                    {x:ion_1f.x,y:reform (ion_norm_efluxpa[*,ion_index,*]),v:pa_array}, /append
       ion_index = value_locate (ion_energy, 100.0)
       store_data,  'sep_ion_normalized_pad_100keV',data = $
                    {x:ion_1f.x,y:reform (ion_norm_efluxpa[*,ion_index,*]),v:pa_array}, /append
       ion_index = value_locate (ion_energy, 500.0)
       store_data,  'sep_ion_normalized_pad_500keV',data = $
                    {x:ion_1f.x,y:reform (ion_norm_efluxpa[*,ion_index,*]),v:pa_array}, /append
       ion_index = value_locate (ion_energy, 3000.0)
       store_data,  'sep_ion_normalized_pad_3MeV',data = $
                    {x:ion_1f.x,y:reform (ion_norm_efluxpa[*,ion_index,*]),v:pa_array}, /append
       options,'sep_ion_normalized_pad*','spec', 1
       ylim,'sep_ion_normalized_pad*',0, 180.0
       zlim,'sep_ion_normalized_pad*',0, 2.0
       options,'sep_ion_normalized_pad*','ystyle', 1
       options,'sep_ion_normalized_pad*','yticks', 6
       options,'sep_ion_normalized_pad*','yminor', 3
       
       options,'sep_ion_normalized_pad_30keV','ytitle', 'Ion pitch angle !c 30 keV'
       options,'sep_ion_normalized_pad_100keV','ytitle', 'Ion pitch angle !c 100 keV'
       options,'sep_ion_normalized_pad_500keV','ytitle', 'Ion pitch angle !c 500 keV'
       options,'sep_ion_normalized_pad_3MeV','ytitle', 'Ion pitch angle !c 3 MeV'
       
       options,'sep_ion_normalized_pad*','ztitle', 'normalized flux'
       
       options, 'sep_ion_normalized_pad*','no_interp',1

       store_data,  'sep_ion_pad_30keV',data = $
                    {x:ion_1f.x,y:reform (ion_efluxpa[*,ion_index,*]),v:pa_array}, /append
       ion_index = value_locate (ion_energy, 100.0)
       store_data,  'sep_ion_pad_100keV',data = $
                    {x:ion_1f.x,y:reform (ion_efluxpa[*,ion_index,*]),v:pa_array}, /append
       ion_index = value_locate (ion_energy, 500.0)
       store_data,  'sep_ion_pad_500keV',data = $
                    {x:ion_1f.x,y:reform (ion_efluxpa[*,ion_index,*]),v:pa_array}, /append
       ion_index = value_locate (ion_energy, 3000.0)
       store_data,  'sep_ion_pad_3MeV',data = $
                    {x:ion_1f.x,y:reform (ion_efluxpa[*,ion_index,*]),v:pa_array}, /append
       options,'sep_ion_pad*','spec', 1
       ylim,'sep_ion_pad*',0, 180.0
       zlim,'sep_ion_pad*',0, 2.0
       options,'sep_ion_pad*','ystyle', 1
       options,'sep_ion_pad*','yticks', 6
       options,'sep_ion_pad*','yminor', 3
       
       options,'sep_ion_pad_30keV','ytitle', 'Ion pitch angle !c 30 keV'
       options,'sep_ion_pad_100keV','ytitle', 'Ion pitch angle !c 100 keV'
       options,'sep_ion_pad_500keV','ytitle', 'Ion pitch angle !c 500 keV'
       options,'sep_ion_pad_3MeV','ytitle', 'Ion pitch angle !c 3 MeV'
       
       options,'sep_ion_pad*','ztitle', 'Energy flux keV/cm!e2!n/s/sr/keV'
       
       options, 'sep_ion_pad*','no_interp',1

    endif
  ;options,'mvn_B_1sec_MAVEN_MSO', 'colors', [2,4, 6]
  ;ylim,'mvn_B_1sec_MAVEN_MSO',[-20,20]
  ;options,'mvn_B_1sec_MAVEN_MSO','labels',['Bx','By','Bz']
  ;options,'mvn_B_1sec_MAVEN_MSO','labflag',1
  ;options,'mvn_B_1sec_MAVEN_MSO','ytitle','B_mso'
  return, result
end
  ;tplot,['sep_ion_normalized_pad*keV','sep_electron_normalized_pad*keV','mvn_B_1sec_MAVEN_MSO','Altitude']
  
