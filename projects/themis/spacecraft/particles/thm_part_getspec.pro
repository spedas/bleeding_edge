;+
;PROCEDURE: thm_part_getspec
;PURPOSE:
;  Generate spectra from particle data
;  Provides different angular view and angle restriction options in spacecraft and fac coords
;
;Inputs:
; Argument descriptions inline below.
;
;Outputs:
; Argument descriptions inline below
;
;Keywords:
; Argument description inline below
;
;Notes:
; Old version in particles/deprecated
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-15 13:39:33 -0700 (Wed, 15 Mar 2017) $
;$LastChangedRevision: 22971 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_getspec.pro $
;-

;helper function to rename outputs from thm_part_products to the old naming style
pro thm_pgs_tplot_rename,in_names,probe,datatype,units,suffix,an_tnames=an_tnames,en_tnames=en_tnames

  compile_opt idl2,hidden
  
  prefix = 'th'+probe+'_'+datatype+'_'
  
  ;energy rename
  new_name = prefix+strlowcase(units)+'_energy'+suffix
  idx = where(strmatch(in_names,new_name,/fold_case),c)
  if c ge 1 then begin ;if c is gt 1 line below will fail, but it should
    old_name = prefix+'en_'+strlowcase(units)+suffix
    
    tplot_rename,new_name,old_name
    
    en_tnames = array_concat(old_name,en_tnames)
  endif 

  ;phi rename
  new_name = prefix+strlowcase(units)+'_phi'+suffix
  idx = where(strmatch(in_names,prefix+strlowcase(units)+'_phi'+suffix,/fold_case),c)
  if c ge 1 then begin ;if c is gt 1 line below will fail, but it should
    old_name=prefix+'an_'+strlowcase(units)+'_phi'+suffix ;name used in older version of thm_part_getspec
    
    tplot_rename,new_name,old_name
    
    an_tnames = array_concat(old_name,an_tnames)
  endif
  
  ;theta rename
  new_name = prefix+strlowcase(units)+'_theta'+suffix
  idx = where(strmatch(in_names,prefix+strlowcase(units)+'_theta'+suffix,/fold_case),c)
  if c ge 1 then begin ;if c is gt 1 line below will fail, but it should
    old_name = prefix+'an_'+strlowcase(units)+'_theta'+suffix ;name used in older version of thm_part_getspec
    
    tplot_rename,new_name,old_name
     
    an_tnames = array_concat(old_name,an_tnames)
  endif
  
  ;pitch angle rename
  new_name = prefix+strlowcase(units)+'_pa'+suffix
  idx = where(strmatch(in_names,prefix+strlowcase(units)+'_pa'+suffix,/fold_case),c)
  if c ge 1 then begin ;if c is gt 1 line below will fail, but it should
    old_name = prefix+'an_'+strlowcase(units)+'_pa'+suffix ;name used in older version of thm_part_getspec
    
    tplot_rename,new_name,old_name
    
    an_tnames = array_concat(old_name,an_tnames)
  endif

  new_name = prefix+strlowcase(units)+'_gyro'+suffix
  idx = where(strmatch(in_names,prefix+strlowcase(units)+'_gyro'+suffix,/fold_case),c)
  if c ge 1 then begin ;if c is gt 1 line below will fail, but it should
    old_name = prefix+'an_'+strlowcase(units)+'_gyro'+suffix ;name used in older version of thm_part_getspec
    
    tplot_rename,new_name,old_name
   
    an_tnames = array_concat(old_name,an_tnames)  
  endif

end

pro thm_part_getspec,$
                              probes=probes,$ ;The requested spacecraft ('a','b','c','d','e','f') (or list)

                              instrument_types=instruments,$ ;The requested data type
                              data_type=data_type,$ ; The requested data type(same as instrument_type, added for consistency)
                              datatypes=datatypes,$ ;The requested data type(all these options backwards compatible to all the various options)
                              trange=trange,$ ;required for now
                               
                              erange=erange,$ ;energy range
                              energy=energy,$ ;set to select energy spectrogram production
                              
                              phi=phi_in,$ ;angle limit 2-element array [min,max], in degrees, spacecraft spin plane
                              theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
                              pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
                              gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase
  
                              angle=angle,$ ;select the angular spectrum
  
                              start_angle=start_angle, $ ;control the starting angle when plotting
   
                              outputs=outputs,$ ;list of requested output types (simpler than the angle=angle & /energy setup from before
  
                              units=units,$ ;scalar unit conversion for data
  
                              regrid=regrid, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)
                              ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
  
                              suffix=suffix, $ ;tplot suffix to apply when generating outputs
  
                              datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)
  
                              get_error=get_error, $ ;flag to return *_sigma variables
  
                              ;gui-related keywords disabled for now(uniform error helper?)
                              gui_statusBar=gui_statusBar, $
                              gui_historyWin=gui_historyWin, $
                              
                              other_dim=other_dim,$ ;for now, default only
  
                              method_clean=method_clean,$ ;enable sun decontamination
                              sun_bins=sun_bins,$ ;set decontamination bins, 64-element 0-1 array
  
                              dist_array=dist_array, $ ;use to pass in data from thm_part_dist_array, useful if you want to modify the data before spectra generation
  
                              error=error,$ ;indicate error to calling routine 1=error,0=success
  
                              en_tnames=en_tnames,$
                              an_tnames=an_tnames,$
  
                              ;these keywords are deprecated
                              normalize=normalize,$
                              bins2mask=bins2mask,$
                              badbins2mask=badbins2mask,$ 
                              enoise_bins=enoise_bins,$
                              autoplot=autoplot, $ --automatically plot data(otherwise just produces output variables)
                              
                              sst_cal=sst_cal,$ ;for the automatic load
                                
                              get_support_data=get_support_data,$
                                
                              forceload=forceload, $ --force data load(otherwise will try to use previously loaded data), (not implemented in new wrapper)
                             
                              mag_suffix=mag_suffix,$
       
                             _extra=ex ;TBD: consider implementing as _strict_extra

  compile_opt idl2

  twin = systime(/sec)

  error=1
  dprint,dlevel=0,"WARNING: This routine is now a wrapper.  For new code, we recommend using the core routine thm_part_products.pro, see thm_crib_part_products.pro for examples."
 
  if keyword_set(normalize) then begin
    message,'ERROR: Keyword normalize is fully deprecated.'
  endif
  
  if keyword_set(bins2mask) then begin
    message,'ERROR: Keyword bins2mask is fully deprecated.  Use sun_bins for sst sun decontamination, and dist_array otherwise'
  endif
  
  if keyword_set(badbins2mask) then begin
    message,'ERROR: Keyword badbins2mask is fully deprecated.  Use sun_bins for sst sun decontamination, and dist_array otherwise'
  endif
  
  if keyword_set(enoise_bins) then begin
    message,'ERROR: enoise_bins is fully deprecated.  Use sun_bins for sst sun decontamination'
  endif
  
  if keyword_set(autoplot) then begin
    message,'ERROR: Keyword autoplot is fully deprecated.  Use an_tnames keyword & tplot to display data products'
  endif
  
 

  if keyword_set(method_clean) then begin
    if strlowcase(method_clean) eq 'automatic' then begin
      dprint,dlevel=1,'Automatic SST decontamination method no longer supported, Defaulting to manual with good default.'
    endif
    sst_method_clean='manual'
  endif
  
  ;new code uses bin number instead of 0-1 array
  if keyword_set(sun_bins) then begin
    sst_sun_bins = where(~sun_bins)
  endif
  
  if ~keyword_set(suffix) then begin
    suffix = ''
  endif
  
  ;----------------------------------------------------------------------------
  ;Convert string inputs
  ;  -The logic here should match that from the original thm_part_getspec
  ;----------------------------------------------------------------------------
  
 
  ;Probes
  ;------------
  valid_probes = ['a','b','c','d','e']
  if is_string(probes) then begin
    probes_lc = strfilter(valid_probes, probes, /fold_case, delimiter=' ')
    probes_lc = strlowcase(probes_lc)
    if probes_lc[0] eq '' then begin
      dprint, dlevel=1, 'Input did not contain a valid probe designation.'
      return
    endif
  endif else begin
    dprint, dlevel=1, 'Input did not contain a valid probe designation.'
    return
  endelse
  
  ;Data types
  ;------------
  valid_datatypes = ['peif','peef','psif','psef','peir','peer', $
    'psir','pser','peib','peeb','pseb']
  if is_string(data_type) then datatypes = data_type
  if is_string(instruments) then datatypes = instruments
  
  if is_string(datatypes) then begin
    datatypes_lc = strfilter(valid_datatypes, datatypes, /fold_case, delimiter=' ')
    datatypes_lc = strlowcase(datatypes_lc)
    if datatypes_lc[0] eq '' then begin
      dprint, dlevel=1, 'Input did not include a valid data type.'
      return
    endif
  endif else begin
    dprint, dlevel=1, 'Input did not include a valid data type.'
    return
  endelse
  
  if keyword_set(theta) then begin
    if n_elements(theta) lt 2 then begin
      dprint,'Error, theta keyword should have 2 elements.',dlevel=1
      return
    endif
    
    if theta[1] lt theta[0] then begin
      dprint,'Error: theta keyword max less than theta min',dlevel=1
      return
    endif
    
    if theta[0] lt -90 || theta[1] gt 90 then begin
      dprint,'Error: theta must be between -90 & 90',dlevel=1
      return
    endif
  endif
  
  if keyword_set(phi_in) then begin
    if n_elements(phi_in) lt 2 then begin
      dprint,'Error: phi keyword should have 2 elements.',dlevel=1
      return
    endif
    
    ;Ranges greater than 360 will no longer produce extended plots.
    ;This ensures that the range is modified in a way that will 
    ;still include all data and be plotted along the same y axis.
    ;This could be done in thm_part_products but would break the
    ;functional separation between start_angle and phi limits for 
    ;that code.
    if max(phi_in) - min(phi_in) gt 360. then begin
      phi = [0,360]
      if undefined(start_angle) then start_angle = min(phi_in) 
    endif else begin
      phi = phi_in
    endelse
    
    ;NOTE: this doesn't wrap phis the way the old one did. 
    ; I think that this should probably be handled at the lower level

  endif
  
  if keyword_set(pitch) then begin
    if n_elements(pitch) lt 2 then begin
      dprint,'Error, pitch keyword should have 2 elements.',dlevel=1
      return
    endif
    
    if pitch[1] lt pitch[0] then begin
      dprint,'Error: pitch keyword max less than pitch min',dlevel=1
      return
    endif
    
    if pitch[0] lt 0 || pitch[1] gt 180 then begin
      dprint,'Error: pitch must be between 0 & 180',dlevel=1
      return
    endif
  endif
  
  if keyword_set(gyro) then begin
    if n_elements(gyro) lt 2 then begin
      dprint,'Error: gyro keyword should have 2 elements.',dlevel=1
      return
      
      if max(gyro_in) - min(gyro_in) gt 360. then begin
        gyro = [0,360]
        if undefined(start_angle) then start_angle = min(gyro_in) 
      endif else begin
        gyro = gyro_in
      endelse
      
      ;NOTE: this doesn't wrap gyros the way the old one did.
      ; I think that this should probably be handled at the lower level
    endif
    
  endif
  
  if ~keyword_set(trange) then begin
    trange = timerange()
  endif
    
  if keyword_set(energy) then begin
    outputs = array_concat('energy',outputs)
  endif
  
  if keyword_set(angle) then begin
    outputs = array_concat(strsplit(angle,' ',/extract),outputs)
  endif else if ~keyword_set(angle) then begin
    outputs = array_concat('phi',outputs)
  endif
  
  if ~keyword_set(units) then begin
    units_lc = 'eflux' 
  endif else begin
    units_lc = strlowcase(units)
  endelse
  
  ;so we don't actually concatenate onto variables from a previous call
  undefine,an_tnames
  undefine,en_tnames
  undefine,out_names
  
  if keyword_set(dist_array) then begin ;multiple probes/data types doesn't make sense if dist_array is used
    
    if n_elements(probes_lc) gt 1 then begin
      message,'Error: dist_array keyword cannot be used with multiple probes
    endif
    
    if n_elements(datatypes_lc) gt 1 then begin
      message,'Error: dist_array keyword cannot be used with multiple datatypes
    endif
    
    thm_part_products,probe=probes_lc[0],datatype=datatypes_lc[0],trange=trange,$
      energy=erange,phi=phi,theta=theta,gyro=gyro,pitch=pitch,$
      outputs=outputs,units=units_lc,regrid=regrid,suffix=suffix,$
      datagap=datagap,get_error=get_error,gui_statusbar=gui_statusbar,$
      gui_historywin=gui_historywin,fac_type=fac_type,$
      mag_name='th'+probes_lc[0]+'_fgs',$
      sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,$ 
      dist_array=dist_array,$
      error=error_dev,$
      start_angle=start_angle,$
      tplotnames=tplotnames,$
      sst_cal=sst_cal
      
    if (error_dev) then begin
      return
    endif  
    
    ;expand single-dimension y axes to two dimensions to match old code
    thm_pgs_expand_yaxis, tplotnames
    
    ;rename variables to use only naming system
    thm_pgs_tplot_rename,tplotnames,probes_lc[0],datatypes_lc[0],units_lc,suffix,an_tnames=an_tnames,en_tnames=en_tnames
      
  endif else begin
  
    for i = 0,n_elements(probes_lc)-1 do begin
      for j = 0,n_elements(datatypes_lc)-1 do begin
        
        ;themis state needed for pretty much everything
        thm_load_state, probe = probes_lc[i], trange = trange, /get_support_data
        
        thm_load_fit, probe=probes_lc[i], trange=trange, datatype='fgs', level='l1', $
          coord='dsl', /get_support_data
 
        ;load particle data
        thm_part_load,probe=probes_lc[i],datatype=datatypes_lc[j],trange=trange,sst_cal=sst_cal,_extra=ex
        
            
        thm_part_products,probe=probes_lc[i],datatype=datatypes_lc[j],trange=trange,$
                             energy=erange,phi=phi,theta=theta,gyro=gyro,pitch=pitch,$
                             outputs=outputs,units=units_lc,regrid=regrid,suffix=suffix,$
                             datagap=datagap,get_error=get_error,gui_statusbar=gui_statusbar,$
                             gui_historywin=gui_historywin,fac_type=fac_type,$
                             sst_sun_bins=sst_sun_bins,sst_method_clean=sst_method_clean,$ 
                             mag_name='th'+probes_lc[i]+'_fgs',$
                             dist_array=dist_array,$
                             error=error_dev,$
                             start_angle=start_angle,$
                             tplotnames=tplotnames,$
                             sst_cal=sst_cal,$
                             _extra=ex
                                   
        if (error_dev) then begin
          return
        endif

        ;expand single-dimension y axes to two dimensions to match old code
        thm_pgs_expand_yaxis, tplotnames
        
        ;rename variables to use only naming system
        thm_pgs_tplot_rename,tplotnames,probes_lc[i],datatypes_lc[j],units_lc,suffix,an_tnames=an_tnames,en_tnames=en_tnames

      endfor
    endfor
    
  endelse
  
  dprint,'Runtime: ',systime(/sec) - twin,' secs' 
  error=0
end