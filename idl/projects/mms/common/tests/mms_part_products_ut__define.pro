;+
;
; Unit tests for mms_part_products
;   Note: deprecated, now testing wrapper routine: mms_part_getspec
; 
; **Most tests produce plots that should be checked manually!**
;
; To run:
;     IDL> mgunit, 'mms_part_products_ut'
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-11-09 10:30:15 -0800 (Thu, 09 Nov 2023) $
; $LastChangedRevision: 32224 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_part_products_ut__define.pro $
;-



;+
; Test all outputs 
;-
function mms_part_products_ut::test_all_outputs

  ;test common types
  ;test oplus because it's probably mostly zeros
  species = ['e','i','hplus','oplus']
  success = replicate(0,n_elements(species))

  for i=0, n_elements(species)-1 do begin

    self->load_data, species[i], /support
    
    mms_part_products, self.data, trange=self.trange, /silent, $
                       outputs='energy phi theta pa gyro moments', $
                       mag_name=self.mag, pos_name=self.pos
    
    basic_spectra = self.data+'_'+['energy','phi','theta']
    fac_spectra = self.data+'_'+['pa','gyro']
    moments = self.data+'_'+['density','velocity','ptens']

    success[i] = spd_data_exists([basic_spectra,fac_spectra,moments],self.trange[0],self.trange[1])
    
    tplot, basic_spectra, title=species[i]+' basic spectra'
    makepng, self.prefix+species[i]+'_basic_spectra'+self.suffix
  
    tplot, fac_spectra, title=species[i]+' FAC spectra'
    makepng, self.prefix+species[i]+'_fac_spectra'+self.suffix
  
    tplot, moments, title=species[i]+' moments'
    makepng, self.prefix+species[i]+'_moments'+self.suffix

  endfor
  
  idx = where(~success,n)

  assert, n eq 0, 'Failed to produce one or more ouputs for: '+strjoin(species[idx],' ') 

  return, 1
end


;+
; Test energy limits
;-
function mms_part_products_ut::test_energy_limits

  species = ['i','hplus']

  for i=0, n_elements(species)-1 do begin

    self->load_data, species[i]

    mms_part_products, self.data, trange=self.trange, outputs='energy phi moments', /silent
    mms_part_products, self.data, trange=self.trange, outputs='energy phi moments', energy=[500,12000], suffix='_elim', /silent
  
    energy = self.data+'_energy'+['','_elim']
    phi = self.data+'_phi'+['','_elim']
    dens = self.data+'_density'+['','_elim']

    assert, spd_data_exists([energy,phi,dens],self.trange[0],self.trange[1]), 'Failed to produce one ore more outputs for: '+species[i] 

    tplot, [energy,phi,dens], title='original vs. energy limited outputs'
    makepng, self.prefix+species[i]+'_energy_limits'+self.suffix

  endfor

  return, 1
end



;+
; Test phi limits
;-
function mms_part_products_ut::test_phi_limits

  species = ['i','hplus']

  for i=0, n_elements(species)-1 do begin

    self->load_data, species[i]

    mms_part_products, self.data, trange=self.trange, outputs='energy phi moments', /silent
    mms_part_products, self.data, trange=self.trange, outputs='energy phi moments', phi=[90,270], suffix='_plim', /silent
  
    energy = self.data+'_energy'+['','_plim']
    phi = self.data+'_phi'+['','_plim']
    vel = self.data+'_velocity'+['','_plim']

    assert, spd_data_exists([energy,phi,vel],self.trange[0],self.trange[1]), 'Failed to produce one ore more outputs for: '+species[i] 

    tplot, [energy,phi,vel], title='original vs. phi limited outputs'
    makepng, self.prefix+species[i]+'_phi_limits'+self.suffix

  endfor

  return, 1
end



;+
; Test theta limits
;-
function mms_part_products_ut::test_theta_limits

  species = ['i','hplus']

  for i=0, n_elements(species)-1 do begin

    self->load_data, species[i]

    mms_part_products, self.data, trange=self.trange, outputs='energy theta moments', /silent
    mms_part_products, self.data, trange=self.trange, outputs='energy theta moments', theta=[-45,45], suffix='_tlim', /silent
  
    energy = self.data+'_energy'+['','_tlim']
    theta = self.data+'_theta'+['','_tlim']
    vel = self.data+'_velocity'+['','_tlim']

    assert, spd_data_exists([energy,theta,vel],self.trange[0],self.trange[1]), 'Failed to produce one ore more outputs for: '+species[i] 

    tplot, [energy,theta,vel], title='original vs. theta limited outputs'
    makepng, self.prefix+species[i]+'_theta_limits'+self.suffix

  endfor

  return, 1
end



;+
; Test that unit conversions from all unit types provided in the CDF match
; Only HPCA currently provides multiple units
;-
function mms_part_products_ut::test_unit_transform
  
  self->load_data, 'hplus'

  df_data = 'mms1_hpca_hplus_phase_space_density'
  flux_data = 'mms1_hpca_hplus_flux'

  units = ['flux','eflux','df','df_cm']

  for i=0, n_elements(units)-1 do begin
  
    mms_part_products, df_data, outputs='energy', units=units[i], $
                       trange=self.trange, suffix='_'+units[i]
    mms_part_products, flux_data, outputs='energy', units=units[i], $
                       trange=self.trange, suffix='_'+units[i]

    names = [df_data,flux_data] + '_energy_'+units[i]

    assert, spd_data_exists(names,self.trange[0],self.trange[1]), 'Outputs missing for "'+units[i]+'" units'  

    tplot, names, title='compare output for different input units (plots should be identical)'
    makepng, self.prefix+units[i] + '_energy_spectra'+self.suffix

  endfor

  return, 1
end


;+
; Test FAC variants
;-
function mms_part_products_ut::test_fac_types

  ;just test one from each instrument
  species = ['hplus','e']

  for j=0, n_elements(species)-1 do begin

    self->load_data, species[j], /support

    fac_types = ['mphigeo','phigeo','xgse']
  
    for i=0, n_elements(fac_types)-1 do begin
    
      mms_part_products, self.data, outputs='gyro', fac_type=fac_types[i], $
                         trange=self.trange, suffix='_'+fac_types[i], $
                         pos_name=self.pos, mag_name=self.mag
  
    endfor 
  
    names = self.data+'_gyro_'+fac_types
    
    assert, spd_data_exists(names,self.trange[0],self.trange[1]), 'Failed to produce FAC variants for '+species[j]
  
    tplot, [self.pos,self.mag,names], title='compare gyro plots for different FAC options'
    makepng, self.prefix+species[j]+'_fac_types'+self.suffix

  endfor

  return, 1
end

;+
; Test field aligned limits for energy spectrograms and moments
; Also tests gyro min > max
;-
function mms_part_products_ut::test_implicit_fac

  self.load_data, 'e', 'fast', /support

  mms_part_products, self.data, outputs='energy moments', trange=self.trange, /silent
  mms_part_products, self.data, outputs='energy moments', trange=self.trange, /silent, $
                     pitch=[90,180], suffix='_pitch', mag_name=self.mag, pos_name=self.pos
  mms_part_products, self.data, outputs='energy moments', trange=self.trange, /silent, $
                     gyro=[270,90], suffix='_gyro', mag_name=self.mag, pos_name=self.pos

  dens = self.data+'_density'+['','_mag_pitch','_mag_gyro']
  espec = self.data+'_energy'+['','_pitch','_gyro']
  
  assert, spd_data_exists([dens,espec],self.trange[0],self.trange[1]), 'Failed to produce expected outputs'

  tplot, dens, title='compare original outputs to those with limits on gyrophase or pitch angle'
  makepng, self.prefix+'density_with_fac_limits'+self.suffix
  
  tplot, espec, title='compare original outputs to those with limits on gyrophase or pitch angle'
  makepng, self.prefix+'energy_spec_with_fac_limits'+self.suffix
  
  return, 1
end


;+
; Compare HPCA and FPI data for an identical time range
; Also tests slower "fast" and "srvy" rates
;-
function mms_part_products_ut::test_hpca_vs_fpi

  probe = '1'
  hpca_species = 'hplus'
  fpi_species = 'i'
  
  fpi = 'mms'+probe+'_d'+fpi_species+'s_dist_fast'
  hpca = 'mms'+probe+'_hpca_'+hpca_species+'_phase_space_density'
  fpi_vel = 'mms'+probe+'_d'+fpi_species+'s_bulk'
  
  timespan, '2015-10-20/06:00:00', 10, /min
  trange = timerange()
  
  mms_load_fpi, probe=probe, trange=trange, data_rate='fast', level='l2', datatype='d'+fpi_species+'s-dist'
  
  mms_load_hpca, probe=probe, trange=trange, data_rate='srvy', level='l2', datatype='ion'
  
  mms_part_products, fpi,  trange=trange, outputs=['phi','theta','energy','moments'], /silent
  mms_part_products, hpca, trange=trange, outputs=['phi','theta','energy','moments'], /silent
  
  options, '*_velocity', yrange=[-200,200]

  assert, spd_data_exists(fpi+'_'+['energy','phi','theta','velocity'],trange[0],trange[1]), 'Failed to produce some FPI outputs'
  assert, spd_data_exists(hpca+'_'+['energy','phi','theta','velocity'],trange[0],trange[1]), 'Failed to produce some HPCA outputs'

  tplot, [fpi,hpca] + '_energy', title='compare fpi & hpca outputs'
  makepng, self.prefix+'fpi_hpca_energy_comparison'+self.suffix

  tplot, [fpi,hpca] + '_phi', title='compare fpi & hpca outputs'
  makepng, self.prefix+'fpi_hpca_phi_comparison'+self.suffix

  tplot, [fpi,hpca] + '_theta', title='compare fpi & hpca outputs'
  makepng, self.prefix+'fpi_hpca_theta_comparison'+self.suffix

  tplot, [fpi,hpca] + '_velocity', title='compare fpi & hpca outputs'
  makepng, self.prefix+'fpi_hpca_velocity_comparison'+self.suffix

  return, 1
end


;+
; Compare HPCA products with moments from CDF
;-
function mms_part_products_ut::test_hpca_vs_cdf
  
  self->load_data, 'hplus', /moments

  mms_part_products, self.data, outputs='moments', trange=self.trange, /silent

  names = ['mms1_hpca_hplus_number_density', self.data+'_density', $
           'mms1_hpca_hplus_ion_bulk_velocity', self.data+'_velocity']
  
  assert, spd_data_exists(names,self.trange[0],self.trange[1]), 'Failed to load/produce data for comparison'

  options, names[0:1], yrange=[1,100], /ylog
  options, names[2:3], yrange=[-400,400]

  tplot, names, title='compare hpca outputs with l2 moments'
  makepng, self.prefix+'hpca_cdf_comparison'+self.suffix

  return, 1
end


;+
; Compare FPI products with moments from CDF
;-
function mms_part_products_ut::test_fpi_vs_cdf

  species = ['e','i']

  for i=0, n_elements(species)-1 do begin
  
    self->load_data, species[i], /moments
  
    mms_part_products, self.data, outputs='moments', trange=self.trange, /silent

    vel_name = 'mms1_d'+species[i]+'s_bulkv_dbcs_brst'
   ; join_vec, vel_name + ['x','y','z'] +'_dbcs_brst', vel_name
    
    names = ['mms1_d'+species[i]+'s_numberdensity_brst', self.data+'_density', $
             vel_name, self.data+'_velocity']
    
    assert, spd_data_exists(names,self.trange[0],self.trange[1]), 'Failed to load/produce data for comparison'
  
    options, names[0:1], yrange=[1,100], /ylog
    options, names[2:3], yrange=[-400,400]

    tplot, names, title='compare fpi outputs with l2 moments'
    makepng, self.prefix+'fpi_'+species[i]+'_cdf_comparison'+self.suffix

  endfor

  return, 1
end


;+
; Test probe, species, instrument, and units keywords
;-
function mms_part_products_ut::test_info_keywords

  self->load_data, 'i'

  store_data, self.data, newname='test_var'

  mms_part_products, 'test_var', trange=self.trange, probe='1', species='i', instrument='fpi'

  fpi_success = spd_data_exists('test_var_energy',self.trange[0],self.trange[1])   

  self->load_data, 'hplus'

  store_data, self.data, newname='test_var'

  mms_part_products, 'test_var', trange=self.trange, probe='1', species='hplus', instrument='hpca', input_units='df_cm'

  hpca_success = spd_data_exists('test_var_energy',self.trange[0],self.trange[1])   

  assert, fpi_success and hpca_success, 'Failed to find valid outputs'

  return, 1
end


;+
; Test handling of invalid input data
;-
function mms_part_products_ut::test_invalid_data

  self->load_data, 'i', 'fast'

  store_data, 'test_var', data={x:dindgen(1e3),y:dindgen(1e3)}

  ;should fail gracefully
  mms_part_products
  mms_part_products, 'foo'
  mms_part_products, 0
  mms_part_products, ptr_new()
  mms_part_products, 'test_var'
  mms_part_products, self.data, trange = self.trange + 2 * 24. * 3600, tplotnames=tn

  assert, undefined(tn), 'Unexpected output detected'

  return, 1
end


;+
; Test invalid support data
;-
function mms_part_products_ut::test_invalid_support
  
  self->load_data, 'hplus', 'srvy', /support

  ;shift data outside the time range
  get_data, self.pos, data=d
  d.x += 2 * 24. * 3600
  store_data, self.pos, data=d

  get_data, self.mag, data=d
  d.x += 2 * 24. * 3600
  store_data, self.mag, data=d

  mms_part_products, self.data, trange=self.trange, outputs='pa fac_moments', tplotnames=tn0, /silent
  mms_part_products, self.data, trange=self.trange, outputs='pa fac_moments', tplotnames=tn1, /silent, $
                     mag_name='dummy', pos_name='dummy'
  mms_part_products, self.data, trange=self.trange, outputs='pa fac_moments', tplotnames=tn2, /silent, $
                     mag_name=self.mag, pos_name=self.pos

  assert, undefined(tn0) and undefined(tn1) and ~spd_data_exists(tn2,self.trange[0],self.trange[1]), 'Unexpected output detected'

  return, 1
end


;+
; Test time range with invalid azimuth data
;   -as of 2016-06-07 most of the azimuth data for this data set was all zero
;-
function mms_part_products_ut::test_hpca_bad_azimuth

  probe='1'
  
  trange = mms_get_roi(time_double('2016-02-27/16:00:00'),/next)
  timespan, trange

  mms_load_hpca, probes=probe, trange=trange, datatype='ion', $
                 level='l2', data_rate='brst'
  mms_load_mec, probes=probe, trange=trange, level='l2'
  mms_load_fgm, probes=probe, trange=trange, level='l2'

  name = 'mms1_hpca_hplus_phase_space_density'
  mms_part_products, name, trange=trange, $
                     mag_name='mms1_fgm_b_dmpa_srvy_l2_bvec', $
                     pos_name='mms1_mec_r_eci',outputs='pa'

  assert, spd_data_exists(name+'_pa', trange[0], trange[1]), 'Failed to find expected ouputs'

  tplot, name+'_pa', title='verify pitch angle spectra exists'
  makepng, self.prefix+'hpca_bad_azimuth'+self.suffix

  return, 1
end


;+
; Support routine to load standard test data for a species/rate (instrument implied)
; Clears tplot variables and opens new window
;
; self->load_data, species [,rate] [,/moments] [,/support]
;-
pro mms_part_products_ut::load_data, species, rate, moments=moments, support=support

  self->setup
 
  if in_set(species,['hplus','heplus','heplusplus','oplus','oplusplus']) then begin

    probe = '1'
    if undefined(rate) then rate = 'brst'
    data =  'mms'+probe+'_hpca_'+species+'_phase_space_density'
    
    timespan, '2015-10-20/05:56:30', 5, /min

    mms_load_hpca, probe=probe, data_rate=rate, level='l2', datatype='ion'

    if keyword_set(moments) then begin
      mms_load_hpca, probe=probe, data_rate=rate, level='l2', datatype='moments'
    endif
    
  endif else if species eq 'e' or species eq 'i' then begin

    probe='1'
    if undefined(rate) then rate = 'brst'
    data = 'mms'+probe+'_d'+species+'s_dist_'+rate

    dur = 15d
    if rate eq 'fast' then dur *= 10 $
      else if species eq 'i' then dur *= 4
    timespan, '2016-01-20/19:50:00', dur, /sec

    mms_load_fpi, probe=probe, data_rate=rate, level='l2', datatype='d'+species+'s-dist'
    
    if keyword_set(moments) then begin
      mms_load_fpi, probe=probe, data_rate=rate, level='l2', datatype='d'+species+'s-moms'
    endif
    
  endif else begin
    stop
    message, 'test script error: invalid species'
  endelse

  trange = timerange()

  if keyword_set(support) then begin
    support_trange = trange + [-60,60d]
    mms_load_state, probe=probe, trange=support_trange
    mms_load_fgm, probe=probe, trange=support_trange, level='l2'
  endif

  self.data = data
  self.mag = 'mms'+probe+'_fgm_b_dmpa_srvy_l2_bvec'
  self.pos = 'mms'+probe+'_defeph_pos'
  self.trange = trange

end


function mms_part_products_ut::test_no_regrid

  ;test common types
  ;test oplus because it's probably mostly zeros
  species = ['e','i','hplus','oplus']
  success = replicate(0,n_elements(species))

  for i=0, n_elements(species)-1 do begin

    self->load_data, species[i], /support

    mms_part_products, self.data, trange=self.trange, /silent, $
      outputs='energy phi theta pa gyro moments', $
      mag_name=self.mag, pos_name=self.pos,/no_regrid

    basic_spectra = self.data+'_'+['energy','phi','theta']
    fac_spectra = self.data+'_'+['pa','gyro']
    moments = self.data+'_'+['density','velocity','ptens']

    success[i] = spd_data_exists([basic_spectra,fac_spectra,moments],self.trange[0],self.trange[1])

    tplot, basic_spectra, title=species[i]+' basic spectra'
    makepng, self.prefix+species[i]+'_basic_spectra'+self.suffix

    tplot, fac_spectra, title=species[i]+' FAC spectra'
    makepng, self.prefix+species[i]+'_fac_spectra'+self.suffix

    tplot, moments, title=species[i]+' moments'
    makepng, self.prefix+species[i]+'_moments'+self.suffix

  endfor

  idx = where(~success,n)

  assert, n eq 0, 'Failed to produce one or more ouputs for: '+strjoin(species[idx],' ')

  return, 1
end


;+
; Ensure data is always cleared and window always open
;-
pro mms_part_products_ut::setup
  del_data, '*'
  if (!d.name ne "Z") then window, 0, xs=1100, ys=1000
  tplot_options, 'xmargin', [18,10]
end


function mms_part_products_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  self.prefix = 'mms_part_products_updates/mms_part_products_'
  self.suffix = '_new'
  self->addTestingRoutine, ['mms_part_products', $
                            'spd_pgs_moments', $
                            'mms_pgs_make_theta_spec', $
                            'mms_pgs_make_phi_spec', $
                            'mms_pgs_make_e_spec', $
                            'spd_pgs_v_shift', $
                            'spd_pgs_regrid', $
                            'spd_pgs_do_fac', $
                            'mms_pgs_split_hpca', $
                            'spd_pgs_limit_range']
  self->addTestingRoutine, ['mms_get_dist', $
                            'mms_get_fpi_dist', $
                            'mms_get_hpca_dist'], /is_function
  return, 1
end

pro mms_part_products_ut__define
  define = { mms_part_products_ut, $
             
             data: '', $  ;particle data tvar
             mag: '', $   ;b field tvar
             pos: '', $   ;position tvar
             trange: [0,0d], $  ;time range
             prefix: '', $ ;prefix for output files
             suffix: '', $ ;suffix for output files

             inherits MGutTestCase }

end