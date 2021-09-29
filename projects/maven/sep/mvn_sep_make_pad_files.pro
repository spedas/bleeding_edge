; the purpose of this script is to make IDL save files of pitch angle
; distributions for all the SEP data, based on one second data from
; MAG.

pro mvn_sep_make_pad_files, time_range, out_path = out_path, version = version,$
  Revision = revision

  kernels =mvn_spice_kernels(trange = time_range,/load,/all)
  mvn_mag_load, 'L2_1SEC',trange = time_range,spice_frame = 'MAVEN_MSO'
  
  if not keyword_set (version) then message, 'must define a version number'
  if not keyword_set (revision) then message, 'must define a revision number'
  
  if not keyword_set (out_path) then out_path = $
     '/disks/data/maven/data/sci/sep/l2_pad/'

; sometimes this doesn't load properly, so need to call leap second initializer
  cdf_leap_second_init
  
; load up level II SEP and SEP ancillary data
  ndim = size(time_range, /n_dimensions)
  dims = size(time_range,/dimensions)
  if ndim eq 2 then begin
     for J = 0, dims[1]-1 do begin
        mvn_sep_load,trange=time_range[*,J],verbose=verbose,/ancillary
        mvn_sep_load,trange=time_range[*,J],verbose=verbose,/L2
     endfor
  endif else begin
     mvn_sep_load,trange=time_range,verbose=verbose,/ancillary
     mvn_sep_load,trange=time_range,verbose=verbose,/L2
  endelse
  
; get spacecraft altitude
  
  get_data, 'mvn_pos_mso', data = MSO
  altitude = SQRT(total (MSO.y^2, 2))-3390.0
  store_data, 'Altitude', data = {x:MSO.x,y: altitude}
  ylim,'Altitude', 0,7000,0
  options, 'Altitude','ytitle', 'Alt, km'

; local time
  get_data, 'mvn_slt', data = slt
 
; get ion flux data
  get_data,  'mvn_L2_sep1f_ion_flux', data = ion_1F
  get_data,  'mvn_L2_sep2f_ion_flux', data = ion_2F
  get_data,  'mvn_L2_sep1r_ion_flux', data = ion_1R

  get_data,  'mvn_L2_sep2r_ion_flux', data = ion_2R
  
  ion_energies = mean_dims (ion_1f.v, 1)
  nen = n_elements (ion_energies)
  
; make tplot variables for ion energy flux
  store_data,'mvn_L2_sep1f_ion_eflux', data = {x: ion_1f.x, y: ion_1f.y*ion_1f.v, v:ion_energies}
  store_data,'mvn_L2_sep1r_ion_eflux', data = {x: ion_1r.x, y: ion_1r.y*ion_1r.v, v:ion_energies}
  store_data,'mvn_L2_sep2f_ion_eflux', data = {x: ion_2f.x, y: ion_2f.y*ion_2f.v, v:ion_energies}
  store_data,'mvn_L2_sep2r_ion_eflux', data = {x: ion_2r.x, y: ion_2r.y*ion_2r.v, v:ion_energies}
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
  electron_energies = reform (electron_1f.v [0,*])
  store_data,'mvn_L2_sep1f_electron_eflux', $
             data = {x: electron_1f.x, y: electron_1f.y*electron_1f.v, v:electron_energies}
  store_data,'mvn_L2_sep1r_electron_eflux', $
             data = {x: electron_1r.x, y: electron_1r.y*electron_1r.v, v:electron_energies}
  store_data,'mvn_L2_sep2f_electron_eflux', $
             data = {x: electron_2f.x, y: electron_2f.y*electron_2f.v, v:electron_energies}
  store_data,'mvn_L2_sep2r_electron_eflux', $
             data = {x: electron_2r.x, y: electron_2r.y*electron_2r.v, v:electron_energies}

; set the plots to spectrum with logarithmic Y and Z (color) axes
  options,'mvn_L2_sep*eflux', 'spec', 1
  options,'mvn_L2_sep*eflux', 'ylog', 1
  options,'mvn_L2_sep*eflux', 'zlog', 1

; make y-axis titles
  options,'mvn_L2_sep1f_ion_eflux','ytitle', '1F ions, !C keV'
  options,'mvn_L2_sep2f_ion_eflux','ytitle', '2F ions, !C keV'
  options,'mvn_L2_sep1r_ion_eflux','ytitle', '1R ions, !C keV'
  options,'mvn_L2_sep2r_ion_eflux','ytitle', '2R ions, !C keV'
  options,'mvn_L2_sep1f_electron_eflux','ytitle', '1F elec,!C keV'
  options,'mvn_L2_sep2f_electron_eflux','ytitle', '2F elec,!C keV'
  options,'mvn_L2_sep1r_electron_eflux','ytitle', '1R elec,!C keV'
  options,'mvn_L2_sep2r_electron_eflux','ytitle', '2R elec,!C keV'

; z-axis title & limits
  options,'mvn_L2_sep*eflux', 'ztitle', 'Diff Eflux, !c keV/cm2/s/sr/keV'
  zlim, 'mvn_L2_sep*_eflux', 1e1,2e5, 1
  ylim, 'mvn_L2_sep*ion_eflux', 7,1e4, 1
  ylim, 'mvn_L2_sep*electron_eflux', 7,4e2, 1

; make a tplot variable for both attenuators
  store_data, 'Attenuator', data = ['mvn_sep1attenuator_state', 'mvn_sep2attenuator_state']
  options, 'Attenuator', 'colors',[70, 221]
  ylim, 'Attenuator', 0.5, 2.5

; exclude all data were the attenuator is closed
  get_data,'mvn_sep1attenuator_state', data = att1
  get_data,'mvn_sep2attenuator_state', data = att2

; get the field of view information, for the time cadence
  get_data, 'sep_1f_fov_mso', data = FOV_1F

; Calculate  the pitch angle of every field of view and store a tplot
; variablex

; Calculate the pitch angle distributions
  
  pad_B1sec = mvn_sep_pad('mvn_B_1sec_MAVEN_MSO')
  ;if finite(max(pad_B1sec.time)
  if not keyword_set (out_directory) then out_directory = $
        '/disks/data/maven/data/sci/sep/l2_pad/'
  


  version_string = numbered_filestring(version, digits = 2)
  revision_string = numbered_filestring(revision, digits = 2)
  
 
; make a file for every day
  ndays = ceil((max(pad_B1sec.time,/nan) - min(pad_B1sec.time,/nan))/86400)
  if ndays gt 7 then ndays = 7
; make the filename strings
  for J = 0, ndays - 1 do begin
     day = min(pad_B1sec.time,/nan) + 86400.0*J
     year_string = time_string(day, tformat = 'YYYY')
     month_string = time_string(day,tformat = 'MM')
     date_string = time_string(day,tformat = 'DD')
     sav_file_name = out_path + 'sav/'+year_string+'/'+ month_string +'/'+$
                     'mvn_sep_l2_pad_' + year_string+ month_string + date_string + $
                     '_v'+version_string +'_r'+revision_string +'.sav'
     indices = where(pad_B1sec.time ge day and pad_B1sec.time lt day+86400.0)
     pad = pad_B1sec[indices]
     save, pad,file =sav_file_name
     print, 'Saving '+sav_file_name + '...'
  endfor
  
end
  
