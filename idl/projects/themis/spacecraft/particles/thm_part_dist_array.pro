;+
;
;Procedure:
;  thm_part_dist_array
;
;Purpose: 
;  Returns an array of pointers to ESA or SST particle distributions.(One pointer for new mode in the time series)  This routine
;  is a wrapper for thm_part_dist, which returns single distributions.
;
;
;Required Keywords:
; PROBE: The THEMIS probe, 'a','b','c','d','e'.
; DATATYPE: Four character string denoting the type of data that you need.
;          ESA Ions (full/reduced/burst)
;            'peif' - Full mode
;            'peir' - Reduced mode
;            'peib' - Burst mode
;          ESA Electrons
;            'peef' - Full
;            'peer' - Reduced
;            'peeb' - Burst 
;          SST Ions 
;            'psif' - Full
;            'psir' - Reduced
;          SST Electrons 
;            'psef' - Full 
;            'pser' - Reduced
;            'pseb' - Burst
; TRANGE: Time range of interest (2 element array, string or numerical).
;         *This keyword may be ommitted if 'timespan is set. If neither 
;          TRANGE nor 'timespan' is set the user will be prompted.
;
;
;Optional Keywords:
; MAG_DATA: Tplot variable containing magnetic field data. The data will be 
;           interpolated to the cadence of the requested particle distribution
;           and added to the returned structures under the tag 'MAGF'.
; VEL_DATA: Tplot variable containing velocity data. The data will be 
;           interpolated to the cadence of the requested particle distribution
;           and added to the returned structures under the tag 'VELOCITY'.
;           If not set V_3D_NEW.PRO will be used instead.
; GET_SUN_DIRECTION: Adds sun direction vector to the returned structures
;           under the tag 'SUN_VECTOR'
; FRACTIONAL_COUNTS: Flag to keep the ESA unit conversion routine from rounding 
;                    to an even number of counts when removing the dead time 
;                    correction (no effect if input data already in counts, 
;                    no effect on SST data). This will only be used by this
;                    code when calculating the bulk velocity with V_3D_NEW.PRO
; 
;ESA Keywords:
;  BGND_REMOVE: Flag to turn on ESA background removal.
;  BGND_TYPE: String naming removal type, e.g. 'angle','omni', or 'anode'.
;  BGND_NPOINTS: Number of lowest values points to average over when determining background.
;  BGND_SCALE: Scaling factor that the background will be multiplied by before it is subtracted.
; 
;SST Keywords:
;  SST_CAL: Flag to use newest SST calibrations
; 
; 
;Examples:  
;  dist_array = thm_part_dist_array(probe='b',datatype='pseb', $
;                 trange='2008-2-26/04:'+['50:00','55:00'])
;           
;  timespan, '2008-2-26/04:50:00', 5, /min
;  dist_array = thm_part_dist_array(probe='b',datatype='psif', $
;                                   vel_data='tplot_vel', $
;                                   mag_data='tplot_mag')
;
; 
;See Also: thm_crib_part_product, thm_part_products
;          thm_crib_part_slice2d, thm_part_slice2d
;          thm_crib_esa_bgnd_remove, thm_esa_bgnd_remove, 
;
;
;Created by Bryan Kerr
;Modified by A. Flores
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-10-05 08:57:54 -0700 (Thu, 05 Oct 2017) $
; $LastChangedRevision: 24116 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_dist_array.pro $
;-

function thm_part_dist_array, format=format, trange=trange, type=type, datatype=datatype, $
                              probe=probe, mag_data=mag_data, vel_data=vel_data, $
                              get_sun_direction=get_sun_direction, $
                              suffix=suffix, err_msg=err_msg, $
                              forceload=forceload, $
                              gettimes=gettimes, sst_cal=sst_cal, $
                              _extra = _extra 

  compile_opt idl2


if keyword_set(type) && ~keyword_set(datatype) then datatype=type

if keyword_set(probe) && keyword_set(datatype) then begin
  probe = strlowcase(probe)
  dtype = strlowcase(datatype)
  format = 'th'+probe+'_'+dtype
endif else if keyword_set(format) then begin
  format = strlowcase(format)
  probe = strmid(format,2,1)
  dtype  = strmid(format,4,4)
endif else begin
  err_msg = 'Must provide PROBE and DATATYPE keywords.'
  dprint, dlevel=1, err_msg
  return, -1
endelse


inst = strmid(dtype,1,1)
species = strmid(dtype,2,1)


; check requested probe
dummy = where(probe eq ['a','b','c','d','e'], yes_probe)
if yes_probe lt 1 then begin
  dprint, dlevel=1, 'Invalid probe: ' + probe
  return, -1
endif

; check requested instrument type
if inst ne 'e' && inst ne 's' then begin
  dprint, dlevel=1, 'Invalid instrument type: ' + inst
  return, -1
endif

; check requested species
if species ne 'e' && species ne 'i' then begin
  dprint, dlevel=1, 'Invalid species: ' + species
  return, -1
endif

; check time range
if keyword_set(trange) then begin
   trd = minmax(time_double(trange))
   tr = time_string(trd)
endif else begin
   trd = timerange()
   tr = time_string(trd)
endelse

; This warning should probabably be in thm_part_load
if inst eq 's' && keyword_set(sst_cal) then begin
  if stregex(dtype, 'ps[ei]r', /bool) then begin
    err_msg = 'Beta SST calibrations only available for full and burst data'
    dprint, dlevel=1, err_msg
    return, -1
  endif
endif


; load L0 data
thm_part_load, probe=probe, datatype=dtype, trange=tr, $
               forceload=forceload, sst_cal=sst_cal, _extra=_extra


; get time indexes of data in requested time range
times = thm_part_dist(format, /times, sst_cal=sst_cal)
if size(times,/type) eq 8 then begin
  err_msg = 'Unable to retrieve times for th'+probe+'_'+dtype+ $
            ' between ' +tr[0]+ ' and ' +tr[1]+ '.' 
  dprint, err_msg
  return, -1
endif


;time correction to point at bin center is applied for ESA, but not for SST
if inst eq 's' then begin
  times += 1.5
endif


;return times if requested
if keyword_set(gettimes) then return, times


; check that data exists in requested range
time_ind = where(times ge trd[0] and times le trd[1], n_times) 
if (size(times,/type) ne 5) or (n_times lt 1) then begin
  err_msg = 'No '+format+' data for time range '+tr[0]+ $
             ' to '+tr[1]+'.' 
  dprint, err_msg
  return, -1
endif 



;interpolate mag data  
if keyword_set(mag_data) then begin

  tinterpol_mxn, mag_data, times[time_ind], /nan_extrapolate, error=success
  
  if success then begin
    get_data, mag_data+'_interp', data=d
    mag = d.y
    add_mag_data = 1b
  endif else begin
    err_msg = 'Unable to interpolate B field data from "'+ mag_data + $
      '". Variable may not exist or may not cover the requested time range.'
    dprint, dlevel=1, err_msg
    return, -1
  endelse

endif



;interpolate velocity data
if keyword_set(vel_data) then begin

  tinterpol_mxn, vel_data, times[time_ind], /nan_extrapolate, error=success

  if success then begin
    get_data, vel_data+'_interp', data=d
    vel = d.y
    add_vel_data = 1b
  endif else begin
    err_msg = 'Unable to interpolate velocity data from "'+ vel_data + $
      '". Variable may not exist or may not cover the requested time range.'
    dprint, dlevel=1, err_msg
    return, -1
  endelse
endif



; Find all mode changes.  This will allow pre-allocation of memory 
; for the data structure arrays and bypass costly concatenations
; in the following for loop.
midx = thm_part_getmodechange(probe, dtype, time_ind, sst_cal=sst_cal, n=nsamples)
if nsamples[0] eq 0 then begin
  dprint, dlevel=0, 'Unknown error determining mode changes.'
  return, -1
end


;Initialize array of pointers to be returned
dist_ptrs = replicate( ptr_new(), n_elements(midx) )



; Loop to create array
for i=0L,n_times-1 do begin


  dat = thm_part_dist(format, index=time_ind[i], sst_cal=sst_cal,mask_tot=mask_tot,enoise_tot=enoise_tot, _extra=_extra)


  ; add mag data to dat structure
  if keyword_set(add_mag_data) then begin
    str_element, /add, dat, 'magf', reform(mag[i,*])
  endif
  
  
  ; add velocity data to dat structure
  if keyword_set(add_vel_data) then begin
    ; add user specified velocity data to data structure
    str_element, /add, dat, 'velocity', reform(vel[i,*])    
  endif else begin
    ; calculate velocity if not specified
    vel=v_3d_new(dat,_extra=_extra) ;*1000. use km/s 
    str_element, /add, dat, 'velocity', vel
  endelse


  ;add placeholder for sun direction vector
  if keyword_set(get_sun_direction) then begin
    str_element, /add, dat, 'sun_vector', replicate(!values.f_nan,3)
  endif
  
  
  ;Assign pointer to pre-allocated structure array for new mode;
  ;otherwise, place structure into existing array.
  mode = where(i eq midx,n)
  if n gt 0 then begin
  
    dprint, dlevel=2,'New mode encountered at '+time_string(dat.time)
    
    current_mode = mode[0]
    
    ;create new pointer with pre-allocated array
    dist_ptrs[current_mode] = ptr_new( replicate(dat, nsamples[current_mode]), /no_copy )
    dist_count = 1
  
  endif else begin
  
    ;place this structure into the current mode's array
    ( *(dist_ptrs[current_mode]) )[dist_count] = temporary(dat)
    dist_count++
  
  endelse
  
  
endfor


;populate sun direction field
if keyword_set(get_sun_direction) then begin
  thm_part_addsun, dist_ptrs, probe=probe, trange=trange
endif


return, dist_ptrs

end
