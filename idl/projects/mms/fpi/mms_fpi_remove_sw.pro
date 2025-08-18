;+
; PROCEDURE:
;         mms_fpi_remove_sw
;
; PURPOSE:
;         Removes the solar wind component from the FPI ion distribution data     
;         
; KEYWORDS:
;         probe: spacecraft probe # (default: 1)
;         trange: time range (if the dist keyword isn't specified)
;         dist: distribution structures (optional)
;         data_rate: data rate (fast by default)
;         cal_moment: calculate moments
;         interpolate: interpolate the sw hole
;         create_tplot: create tplot variables of moments and Vsw
;         dvr: ?
;         mag_name: 
;         sc_pot_name: name of tplot variable containing the spacecraft potential data
;         newdist: set to a named variable to output the new distribution structure
;         moment_output: output the moments
;         vsw_output: output the solar wind velocity
;         quiet: flag to disable printing out the processing status
;         
; NOTES:
;       Originally by Terry Liu (UCLA); minor updates by Eric Grimes
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL:  $
;-

pro mms_fpi_remove_sw,$ ;;remove sw ions and output new distribution
                  probe=probe,trange=trange,data_rate=data_rate,dist=dist,$   ;input: either probe, time interval, data_rate (fast by default), or the distribution dist as a structure
                  cal_moment=cal_moment,interpolate=interpolate,create_tplot=create_tplot,$ ;; set to calculate moments, interpolate the sw hole, and create tplot variables of moments and Vsw
                  dvr=dvr,mag_name=mag_name,sc_pot_name=sc_pot_name,$ ;set velocity radius to remove sw (Vsw by default)
                  newdist=newdist,moment_output=moment_output,vsw_output=vsw_output,$         ;output: new distribution (structure), moments and Vsw (structure, if set cal_moment, can be used to create tplot variables or conduct other calculation)
                  quiet=quiet

  ; the following are only used if the DF data isn't provided directly
  if undefined(data_rate) then data_rate='fast'
  if undefined(level) then level = 'l2'
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)

  if ~keyword_set(dist) then begin
    
    name_i =  'mms'+probe+'_dis_dist_'+data_rate
  
    mms_load_fpi, data_rate=data_rate, level=level, datatype='dis-dist', probe=probe, trange=trange, min_version='2.2.0'
  
    temp = mms_get_dist(name_i, trange=trange)
    
    dist = *temp[0]
  endif else begin
    
    probe = dist[0].spacecraft
    
    dt = dist[0].end_time - dist[0].time
    
    if dt gt 4 then data_rate = 'fast' else data_rate = 'brst'
    ;;probably add something when there is no data
  endelse
  
  
  
  num = n_elements(dist)
  newdist = dist
  
  vsw = fltarr(num,3)
  
  
  for i=0,num-1 do begin
  
    dist0 = dist[i]
    
    if ~keyword_set(quiet) then begin
      dprint, dlevel=2, 'processing '+time_string(dist0.time,/sql)
    endif
    
    ind  = where(dist0.energy gt 100)  ;;only consider >100 eV to ignore 1 count noise
    peak = max(dist0.data[ind],indm)  ;;obtain peak eflux/psd to locate SW
    indp = ind[indm]                  ;;index of peak eflux/psd
  
    energy = dist0.energy
    phi    = dist0.phi
    theta  = dist0.theta
  
    ;;remove sw
    energyp = energy[indp]
    phip    = phi[indp]
    thetap  = theta[indp]
  
    vx = sqrt(energy*1.6e-19/1.67e-27*2)*1e-3*cos(theta/180.*!pi)*cos(phi/180.*!pi)
    vy = sqrt(energy*1.6e-19/1.67e-27*2)*1e-3*cos(theta/180.*!pi)*sin(phi/180.*!pi)
    vz = sqrt(energy*1.6e-19/1.67e-27*2)*1e-3*sin(theta/180.*!pi)
  
    vxp = sqrt(energyp*1.6e-19/1.67e-27*2)*1e-3*cos(thetap/180.*!pi)*cos(phip/180.*!pi)
    vyp = sqrt(energyp*1.6e-19/1.67e-27*2)*1e-3*cos(thetap/180.*!pi)*sin(phip/180.*!pi)
    vzp = sqrt(energyp*1.6e-19/1.67e-27*2)*1e-3*sin(thetap/180.*!pi)
  
    vsw[i,*]=[vxp,vyp,vzp]
  
    dv   = sqrt((vx-vxp)^2+(vy-vyp)^2+(vz-vzp)^2)
    dvhe = sqrt((vx-vxp*sqrt(2.))^2+(vy-vyp*sqrt(2.))^2+(vz-vzp*sqrt(2.))^2)  ;;He
  
    if ~keyword_set(dvr) then vr=norm([vxp,vyp,vzp]) else vr=dvr
    ;vr=norm([vxp,vyp,vzp])
    
    indsw = where(dv le Vr or dvhe le Vr)
  
    dist0.data[indsw] = 0d
  
    ;;remove noise around origin, which significantly affect foreshock ion calculation
    indo=where(energy le 50)
    dist0.data[indo] = 0d
  
    if keyword_set(interpolate) then begin
      ;spherically interpolate across sun bins
      newdata = dist0.data
      for j=0,31 do begin
        ind_angle = where(dv[j,*,*] gt 200 and dvhe[j,*,*] gt 200,num_angle)
  
        if num_angle gt 0 then begin
          phi_m = fltarr(num_angle)
          for k=0,num_angle-1 do phi_m[k] = phi[j,ind_angle[k] mod 32, ind_angle[k]/32]
          
          theta_m = fltarr(num_angle)
          for k=0,num_angle-1 do theta_m[k] = theta[j,ind_angle[k] mod 32, ind_angle[k]/32]
          
          data_m = dblarr(num_angle)
          for k=0,num_angle-1 do data_m[k] = dist0.data[j,ind_angle[k] mod 32, ind_angle[k]/32]
          
          newdata[j,*,*] = griddata(phi_m,theta_m,data_m,$
            /sphere,/degrees,xout=reform(dist0.phi[j,*,*]),yout=reform(dist0.theta[j,*,*]),method='InverseDistance');,triangles=triangles)
        endif
  
      endfor
  
      dist0.data=newdata
    endif
    
    if keyword_set(cal_moment) then begin  
       ;  mms_convert_flux_units,dist0,units='eflux',output=dist_eflux
       mms_pgs_clean_data,dist0,output=clean_data,units='eflux'
       mms_pgs_clean_support, dist0.time, probe, mag_name=mag_name, sc_pot_name=sc_pot_name, mag_out=mag_data, sc_pot_out=sc_pot_data
       ;;calculate moments
       spd_pgs_moments, clean_data, moments=moments, delta_times=delta_times, mag_data=mag_data, sc_pot_data=keyword_set(internal_photoelectron_corrections) ? 0 : sc_pot_data, index=0; , _extra = ex
  
    endif
    
    newdist[i]=dist0
    
  endfor
  
  if ~undefined(moments) then moment_output=moments
  vsw_output={x:dist.time,y:vsw}
  
  if keyword_set(create_tplot) then begin
    
    name_i =  'mms'+probe+'_dis_dist_'+data_rate
    
    if ~undefined(moments) then begin
      store_data,name_i+'_density_nosw',data={x:moments.time,y:moments.density}
      store_data,name_i+'_velocity_nosw',data={x:moments.time,y:transpose(moments.velocity)}
      store_data,name_i+'_avgtemp_nosw',data={x:moments.time,y:moments.avgtemp}
      store_data,name_i+'_magt3_nosw',data={x:moments.time,y:transpose(moments.magt3)}
      options,name_i+'_velocity_nosw',colors=[2,4,6]
      options,name_i+'_magt3_nosw',colors=[2,4,6]
    endif 
    store_data,name_i+'_velocity_sw',data=vsw_output
    options,name_i+'_velocity_sw',colors=[2,4,6]
  endif

end





