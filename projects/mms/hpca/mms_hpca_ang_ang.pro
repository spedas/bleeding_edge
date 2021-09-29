;+
; PROCEDURE:
;     mms_hpca_ang_ang
; 
; PURPOSE:
;     Create angle-angle and angle-energy plots of HPCA distribution functions
;     
; INPUT:
;     time: time of interest
;     
; KEYWORDS:
;     species: HPCA species; e.g., hplus, oplus, etc (default: hplus)
;     probe: MMS spacecraft # (default: '1')
;     level: data level (default: 'l2')
;     data_rate: instrument data rate (default: brst)
;     energy_range: energy range of figures, in eV (default: full energy range)
;     center_measurement: center the HPCA measurements (default: enabled)
;     flux: plot the flux instead of the distribution function
;     png: save the plots as PNG files
;     postscript: save the plots as PS files 
;     filename_suffix: append a suffix to the plot file names
; 
; NOTES:
;     warning: the data plotted by this routine are not omni-directional, i.e. spin-averaged/spin-summed,
;              so the azimuthal angles will be limited to those in the sample closest to
;              the requested time
;     
;     experimental, email questions to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-09-17 12:04:04 -0700 (Tue, 17 Sep 2019) $
; $LastChangedRevision: 27763 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_ang_ang.pro $
;-

pro mms_hpca_ang_ang, time, species=species, probe=probe, level=level, data_rate=data_rate, energy_range=energy_range, $
    center_measurement=center_measurement, postscript=postscript, png=png, filename_suffix=filename_suffix, flux=flux

  if undefined(time) then begin
    time = gettime(key='Enter time: ')
    trange = time_double(time) + [-300., 300]
  endif else trange = time_double(time) + [-300., 300]
  if undefined(species) then species = 'hplus'
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(energy_range) then energy_range = [0, 40000] ; eV
  if undefined(data_rate) then data_rate = 'brst'
  if undefined(center_measurement) then center_measurement=1b
  if undefined(filename_suffix) then filename_suffix = ''
  if undefined(xsize) then xsize = 550
  if undefined(ysize) then ysize = 450
  
  if ~undefined(postscript) and ~undefined(png) then begin
    dprint, dlevel = 0, 'Error, both PNG and POSTSCRIPT output requested, but can only do one at a time; defaulting to postscript'
    undefine, png
  endif
  
  mms_load_hpca, datatype='ion', level=level, data_rate=data_rate, trange=trange, probe=probe, center_measurement=center_measurement, tplotnames=tplotnames
  
  var = 'mms'+probe+'_hpca_'+species+'_'
  var = keyword_set(flux) ? var+'flux' : var+'phase_space_density'
  get_data, var, data=d, dlimits=dl

  if ~is_struct(d) then begin
    dprint, dlevel = 0, 'Error, no data found.'
    return
  endif
  
  closest_time = find_nearest_neighbor(d.X, time_double(time))
  closest_idx = where(d.X eq closest_time)
  closest_idx = closest_idx-1

  energies = d.V2
  energy_axis = minmax(energies)
  
  idx_of_ens = where(energies ge energy_range[0] and energies le energy_range[1])
  energies = energies[idx_of_ens]
  
  distptr = mms_get_dist(var, single_time=time)

  if ~ptr_valid(distptr) then begin
    dprint, dlevel = 4, 'Error, no data found for this time: '+time_string(time)
    return
  endif
  
  dist = *distptr
  
  units = spd_units_string(strlowcase(dist.units_name))
  
  ; energy-azimuth-elevation
  ; energy-phi-theta
  data_at_ens = dist.data[idx_of_ens, *, *]
  
  ; azimuth-elevation
  ;  phi-theta
  data_summed = total(data_at_ens, 1, /nan)
  
  ; theta is stored as co-latitude
  theta_colat = reform(dist.theta[0, 0, *])

  ; convert to latitude
  theta_flow_direction = 90-theta_colat
  phi = reform(dist.phi[0, *, 0])

  ; deal with gaps due to these data not being spin-summed
  num_phi = 32
  summed_out = dblarr(num_phi+1, n_elements(theta_flow_direction))
  phi_bins = 360.*indgen(num_phi+1)/num_phi

  for theta_idx=0, n_elements(theta_flow_direction)-1 do begin
    for phi_idx=0, n_elements(phi)-1 do begin
      this_bin = find_nearest_neighbor(phi_bins, phi[phi_idx])
      bin_idx = where(phi_bins eq this_bin)
      summed_out[bin_idx, theta_idx] += data_summed[phi_idx, theta_idx]
    endfor
  endfor

  if ~undefined(postscript) then popen, 'azimuth_vs_zenith'+filename_suffix, /landscape else window, 1, xsize=xsize, ysize=ysize
  
  ; angle-angle over the energy range
  plotxyz, window=1, phi_bins, theta_flow_direction, summed_out, /zlog, /noisotropic, xrange=[0, 360], yrange=[0, 180], zrange=zrange, xsize=xsize, ysize=ysize, $
    xtitle='Az flow angle (deg)', $
    ytitle='Zenith flow angle (deg)', $
    ztitle=units, $
    title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff')+' (' + strcompress(string(energy_range[0]) + '-'+string(energy_range[1]), /rem)+ ' eV)'
    
  if ~undefined(png) then makepng, 'azimuth_vs_zenith'+filename_suffix
  if ~undefined(postscript) then pclose
  
  theta_en = total(data_at_ens, 2)

  if ~undefined(postscript) then popen, 'zenith_vs_energy'+filename_suffix, /landscape else window, 2, xsize=xsize, ysize=ysize
  
  ; Zenith vs. energy
  plotxyz, window=2, energies, theta_flow_direction, theta_en, /noisotropic, /zlog, xsize=xsize, ysize=ysize, $
    xtitle='Energy (eV)', $
    ytitle='Zenith flow angle (deg)', $
    ztitle=units, $
    title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff'), $
    /xlog, xrange=energy_axis, yrange=[0, 180.], zrange=zrange, yticks=6
    
  if ~undefined(png) then makepng, 'zenith_vs_energy'+filename_suffix
  if ~undefined(postscript) then pclose
    
  phi_en = total(data_at_ens, 3)
  phi_out = dblarr(n_elements(energies), num_phi+1)
  
  ; deal with gaps due to these data not being spin-summed
  for en_idx=0, n_elements(energies)-1 do begin
    for phi_idx=0, n_elements(phi)-1 do begin
      this_bin = find_nearest_neighbor(phi_bins, phi[phi_idx])
      bin_idx = where(phi_bins eq this_bin)
      phi_out[en_idx, bin_idx] += phi_en[en_idx, phi_idx]
    endfor
  endfor

  if ~undefined(postscript) then popen, 'azimuth_vs_energy'+filename_suffix, /landscape else window, 3, xsize=xsize, ysize=ysize

  ; Azimuth vs. energy
  plotxyz, window=3, energies, phi_bins, phi_out, /noisotropic, /zlog, xsize=xsize, ysize=ysize, $
    xtitle='Energy (eV)', $
    ytitle='Azimuth flow angle (deg)', $
    ztitle=units, $
    title=time_string(closest_time, tformat='YYYY-MM-DD/hh:mm:ss.fff'), $
    /xlog, xrange=energy_axis, yrange=[0, 360.], zrange=zrange, yticks=6

  if ~undefined(png) then makepng, 'azimuth_vs_energy'+filename_suffix
  if ~undefined(postscript) then pclose
end