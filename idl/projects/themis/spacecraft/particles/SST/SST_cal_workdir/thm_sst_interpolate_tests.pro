



  del_data,'*'
  heap_gc
  thm_init ;color table & stuffs

  probe = 'd'

  start_time=systime(/sec)

  timespan,'2011-07-29/00:00',1,/day
  ; THD
  ;This amount of data has a tendency to use too much memory
  ;trange=time_double(['2011-07-29/00:00','2011-07-29/23:59:59'])
  ;trange=time_double(['2011-07-29/12:00:00','2011-07-29/23:59:59'])
  ;
  ;shorter time range less memory
  ;trange=time_double(['2011-07-29/04:00:00','2011-07-29/04:30:00'])
  ;trange=time_double(['2011-07-29/12:16:30','2011-07-29/12:45:45'])
 ; trange=time_double(['2011-07-29/12:16:00','2011-07-29/12:45:00'])
  ;trange=time_double(['2011-07-29/12:18:30','2011-07-29/12:22:30'])
  ;trange=time_double(['2011-07-29/12:30:00','2011-07-29/12:45:00'])
  
  trange=time_double(['2011-07-29/13:00:00','2011-07-29/14:00:00'])
 
  ;Note to self:test spherical data with iplot.
  ;
  ;
  ;griddata for spherical interpolation
  sun_bins = dblarr(64)+1 ;allocate variable for bins, with all bins selected
 ; sun_bins[[0,8,16,24,30,32,33,34,40,48,58,55,56]] = 0
 
  sun_bins[[0,8,16,24,32,33,40,47,48,55,56,57]] = 0
  
  dist_psif = thm_part_dist_array(probe=probe,type='psif',trange=trange,/sst_cal,method_clean='manual',sun_bins=sun_bins)
  dist_peif = thm_part_dist_array(probe=probe,type='peif',trange=trange,/bgnd_remove)
  
  thm_part_moments,inst='peif',probe=probe,dist_array=dist_peif,suffix='_orig'
  thm_load_sst,probe='d'
  thm_part_moments,inst='psif',probe=probe,suffix='_old',trange=trange,method_clean='manual',sun_bins=sun_bins
  thm_part_getspec,data_type='psif',probe=probe,suffix='_old',trange=trange,method_clean='manual',sun_bins=sun_bins,angle='phi'

  ;
  ;change into flux units so that data can be compared
  ;don't use eflux because energy variances in SST can make match between SST thetas more troublesome
  thm_part_conv_units,dist_psif,units='flux'
  thm_part_conv_units,dist_peif,units='flux'
  
;  
;  
;this block to test updates to unit conversions 
;extended thm_sst_convert_units to support conversions from several additional unit types. 
;example:allows conversion to flux then to eflux, before this was impossible
;  thm_part_copy,dist_psif,dist_psif2
;  thm_part_conv_units,dist_psif,units='flux'
;  thm_part_conv_units,dist_psif2,units='eflux'
;  ;verify that units differ after first stage of conversion
;  plot,(*dist_psif[0])[0].data-(*dist_psif2[0])[0].data
;  ;verify that units are identical after second stage of conversion
;  thm_part_conv_units,dist_psif,units='eflux'
;  plot,(*dist_psif[0])[0].data-(*dist_psif2[0])[0].data
;; ;verify that logic works all the way to moment calculation and for entire time series 
;;  
;  thm_part_moments,inst='psif',probe='a',suffix='_1',dist_array=dist_psif
;  thm_part_moments,inst='psif',probe='a',suffix='_2',dist_array=dist_psif2
;  calc,'"density_diff"="tha_psif_density_1"-"tha_psif_density_2"'
;stop
;
;

  ;thm_part_conv_units,dist_peif,units='flux'
  
  
  print,time_string(min((*dist_psif[0]).time))
  print,time_string(min((*dist_peif[0]).time))
  
  print,time_string(max((*dist_psif[0]).end_time))
  print,time_string(max((*dist_peif[0]).end_time))
  
  thm_part_time_interpolate,dist_peif,dist_psif,error=time_interp_error
;  print,time_interp_error
;  thm_part_copy,dist_peif,dist_peif_flux
;  thm_part_conv_units,dist_peif,units='eflux',/fractional_counts
;  dist_peif_eflux=dist_peif
;TBD: fractional_counts support for thm_part_moments/thm_part_getspec
  thm_part_conv_units,dist_peif,units='eflux',/fractional_counts
  thm_part_moments,inst='peif',probe=probe,dist_array=dist_peif,suffix='_interp'
  thm_part_conv_units,dist_peif,units='flux',/fractional_counts
  ;TBD generate ESA moments after time interpolation
  ;stop
  
  thm_part_sphere_interpolate,dist_peif,dist_psif,error=sphere_interp_error
  print,sphere_interp_error

  
 ; stop
;    energies = [26000.,28000., 31000.000,       42000.000,       55500.000,       68000.000,       95500.000,       145000.00,       206500.00,       295500.00,       420000.00,       652500.00,$
 ;      1133500.0,       3976500.0,       3976500.0,       3976500.0,       3976500.0,       3976500.0]
 
  energies = [26000.,28000., 31000.000,       42000.000,       55500.000,       68000.000,       95500.000,       145000.00,       206500.00,       295500.00,       420000.00,       652500.00,$
       1133500.0,       3976500.0]
  thm_part_energy_interpolate,dist_psif,dist_peif,energies,error=energy_interp_error
  print,energy_interp_error

  thm_part_moments,inst='psif',probe=probe,suffix='_new',dist_array=dist_psif
  thm_part_getspec,data_type='psif',probe=probe,suffix='_new',dist_array=dist_psif,angle='phi'
;  tplot,'th'+probe+'_psif_en_eflux_new'
  get_data,'th'+probe+'_psif_en_eflux_new',data=d_psif,dlimit=dl,limit=l
  get_data,'th'+probe+'_peif_en_eflux_interp',data=d_peif
  
  store_data,'combined_awesomeness',data={x:d_psif.x,y:[[(reverse(d_peif.y,2))[*,0:30]],[d_psif.y]],v:[[(reverse(d_peif.v,2))[*,0:30]],[d_psif.v]]}
  options,'*',zrange=[1e1,1e7]
  options,'combined_awesomeness',yrange=[1,5e5],/ylog,/spec,/zlog
  options,'thd_psif_en_eflux_*',yrange=[1e4,1e7]
  tplot,['th'+probe+'_psif_en_eflux_' + ['old','new'],'th'+probe+'_peif_en_eflux_orig','combined_awesomeness']
 
  end_time=systime(/sec)
  print,end_time-start_time

  stop
  
  ;TBD: separate routine for SST decontamination.  Manual mode which flags bins with NANs only
  


end