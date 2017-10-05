;+
;Function: t89
;
;Purpose:  generates an array of model magnetic field vectors from
;          a monotonic time series and an array of 3-d position
;          vectors
;
;Input:
;         tarray: N array representing the time series in seconds utc since 1970
;         rgsm_array: Nx3 array representing the position series in earth radii (required to be in GSM coordinates)
;    
;Keywords:
;         kp(optional): the requested value of the kp parameter(default: 2) 
;           kp can also be an array, if it is an array it should be an
;           N length array(you should interpolate your values onto the tarray)
;           Also kp values passed in can only be integers. any pluses
;           or minuses will be ignored, because the Tsyganenko model
;           ignores plus and minuses on kp values
;
;         period(optional): the amount of time between recalculations of
;             geodipole tilt and application of a new kp value 
;             in seconds,increase this value to decrease run time(default: 600) 
;         
;         igrf_only(optional): Set this keyword to turn off the t89 component of
;           the model and return only the igrf component
;
;         add_tilt:  Increment the default dipole tilt used by the model with
;                    a user provided tilt in degrees.  Result will be produced with TSY_DEFAULT_TILT+ADD_TILT
;                    Value can be set to an N length array an M length array or a single element array. 
;                    N is the number of time elements for the data.  M is the number of periods in the time interval.(determined by the period keyword)
;                    If single element is provided the same correction will be applied to all periods.   
;                    If an N length array is provided, the data will be re-sampled to an M length array. Consequently, if
;                    the values change quickly, the period may need to be shortened. 
;         
;         get_tilt: Returns the dipole_tilt parameter used for each period. 
;                   Returned value has a number of elements equal to the value returned by get_nperiod
;         
;         set_tilt: Use alternative dipole_tilt value rather than the geopack tilt.
;                   This input can be an M length array, and N length array or a single elemnt.
;                   Value can be set to an N length array an M length array or a single element array. 
;                   N is the number of time elements for the data.  M is the number of periods in the time interval.(determined by the period keyword)
;                   If an N length array is provided, the data will be re-sampled to an M length array. Consequently, if
;                   the values change quickly, the period may need to be shortened. 
;                   Notes:
;                       1) set_tilt will cause add_tilt to be ignored
;                       2) Due to this routine adding IGRF to the returned field, you cannot use set_tilt = 0 and give input 
;                           position values in SM coordinates; input position values are required to be in GSM coordinates due to the
;                           IGRF calculation
;                   
;         get_nperiod: Returns the number of periods used for the time interval=  ceil((end_time-start_time)/period)
;
;         geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work. 
;
;Returns: 
;    an Nx3 length array of field model data (T89 + IGRF) or -1L on failure
;
;Example:
;   mag_array = t89(time_array,pos_array)
;   mag_array = t89(time_array,pos_array,kp=5,rlength=10)
;   
;Notes:
;  1. Relies on the IDL/Geopack Module provided by Haje Korth JHU/APL
;      and N.A. Tsyganenko NASA/GSFC, if the module is not installed
;      this function will fail.  
;  2. Sums the contribution from the internal field model (IGRF) and the
;      external field model (t89).
;  3. Has a loop with number of iterations = (tarray[n_elements(t_array)]-tarray[0])/period
;      This means that as period becomes smaller the amount time of this
;      function should take will grow quickly.
;  4. Position units are earth radii, be sure to divide your normal
;      units by 6371.2 km to convert them.
;      6371.2 = the value used in the GEOPACK FORTRAN code for Re
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-03-20 12:48:33 -0700 (Fri, 20 Mar 2015) $
; $LastChangedRevision: 17157 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/t89/t89.pro $
;-

function t89, tarray, rgsm_array, kp=kp, period=period, igrf_only=igrf_only,$
    add_tilt=add_tilt,get_tilt=get_tilt,set_tilt=set_tilt,get_nperiod=get_nperiod,$
    get_period_times=get_period_times, geopack_2008=geopack_2008

  ;sanity tests, setting defaults

  if igp_test(geopack_2008=geopack_2008) eq 0 then return, -1L

  if n_elements(tarray) eq 0 then begin 
    message, /continue, 'tarray must be set'
    return, -1L
  endif

  if n_elements(rgsm_array) eq 0 then begin
    message, /continue, 'rgsm_array must be set'
    return, -1L
  endif

  ;convert inputs into double precision to ensure consistency of calculations
  tarray2 = double(tarray)

  rgsm_array2 = double(rgsm_array)

  if n_elements(kp) eq 0 then kp = 2.0D

  if size(kp,/n_dim) eq 0 then kp_array = make_array(n_elements(tarray2),/DOUBLE,value=kp)

  if size(kp,/n_dim) eq 1 then begin
      if n_elements(kp) ne n_elements(tarray2) then begin
          message,/continue,'kp must have the same number of elements as tarray if it is being passed as an array'
          return,-1L
      endif else kp_array = kp
  endif

  if size(kp,/n_dim) gt 1 then begin
      message,/continue,'kp must have 0 or 1 dimensions'
      return,-1L
  endif

  kp_idx_low = where(kp_array lt 0)

  if kp_idx_low[0] ne -1L then begin
      message, /continue, 'Kp has value less than 0'
      return, -1L
  endif

  kp_idx_high = where(kp_array gt 6)

  if kp_idx_high[0] ne -1L then begin
      message, /continue, 'Kp has value greater than 6'
      return, -1L
  endif

  if not keyword_set(period) then period2 = 600.0D  $
  else period2 = double(period)

  if period2 le 0. then begin
    message, /contiune, 'period must be positive'
    return, -1L
  endif

  t_size = size(tarray2, /dimensions)

  r_size = size(rgsm_array2, /dimensions)

  if n_elements(t_size) ne 1 then begin
    message, /continue, 'tarray has incorrect dimensions'
    return, -1L
  endif

  if n_elements(r_size) ne 2 || r_size[1] ne 3 then begin
    message, /continue, 'rgsm_array has incorrect dimensions'
    return, -1L
  endif

  if t_size[0] ne r_size[0] then begin
    message, /continue, 'number of times in tarray does not match number of positions in rgsm_array'
    return, -1L
  endif

  if n_elements(tarray2) gt 1 then begin
    idx = where((tarray2[1:t_size[0]-1] - tarray2[0:t_size[0]-2]) lt 0,nonmonotone_times)
  
    if nonmonotone_times gt 0 then begin
      dprint,'Warning some times are non monotonic, this may cause unreliable results'
    endif
  endif


  ;defaults to NaN so it will plot properly in tplot and to prevent
  ;insertion of spurious default dindgen values
  out_array = make_array(r_size, /DOUBLE, VALUE = !VALUES.D_NAN)

  tstart = tarray2[0]

  tend = tarray2[t_size - 1L]

  i = 0L

  ;this generates a time struct for every time in the time array
  ;generally only a subset will be accessed
  ts = time_struct(tarray2)

  ;calculate the number of loo iterations
  ct = (tend-tstart)/period2
  nperiod = ceil(ct) + 1

  if arg_present(get_nperiod) then begin
    get_nperiod = nperiod
  endif
  
  if arg_present(get_tilt) then begin
    get_tilt = dblarr(nperiod)
  endif
  
   ;return the times at the center of each period
  if arg_present(get_period_times) then begin
    get_period_times = tstart + dindgen(nperiod)*period2+period2/2.
  endif
  
  if n_elements(add_tilt) gt 0 then begin
    if n_elements(add_tilt) eq 1 then begin
      tilt_value = replicate(add_tilt[0],nperiod)
    endif else if n_elements(add_tilt) eq nperiod then begin
      tilt_value = add_tilt
    endif else if n_elements(add_tilt) eq t_size[0] then begin
      ;resample tilt values to period intervals, using middle of sample
      period_abcissas = tstart + dindgen(nperiod)*period2+period2/2
      tilt_value = interpol(add_tilt,tarray,period_abcissas)
    endif else begin
      dprint,'Error: add_tilt values do not match data values or period values'
      return,-1
    endelse
  endif
  
  if n_elements(set_tilt) gt 0 then begin
    if n_elements(set_tilt) eq 1 then begin
      tilt_value = replicate(set_tilt[0],nperiod)
    endif else if n_elements(set_tilt) eq nperiod then begin
      tilt_value = set_tilt
    endif else if n_elements(set_tilt) eq t_size[0] then begin
      ;resample tilt values to period intervals, using middle of sample
      period_abcissas = tstart + dindgen(nperiod)*period2+period2/2
      tilt_value = interpol(set_tilt,tarray,period_abcissas)
    endif else begin
      dprint,'Error: set_tilt values do not match data values or period values'
      return,-1
    endelse
  endif
  
  while i lt nperiod do begin

    ;find indices of points to be input this iteration
    idx1 = where(tarray2 ge tstart + i*period2)
    idx2 = where(tarray2 le tstart + (i+1)*period2)

    idx = ssl_set_intersection(idx1, idx2)

    if idx[0] ne -1L then begin 

      id = idx[0]

      ;recalculate geomagnetic dipole
      if ~undefined(geopack_2008) then begin
        geopack_recalc_08, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endif else begin
        geopack_recalc, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endelse

      rgsm_x = rgsm_array2[idx, 0]
      rgsm_y = rgsm_array2[idx, 1]
      rgsm_z = rgsm_array2[idx, 2]

      ;calculate internal contribution
      if ~undefined(geopack_2008) then begin
        geopack_igrf_gsw_08, rgsm_x, rgsm_y, rgsm_z, igrf_bx, igrf_by,igrf_bz 
      endif else begin
        geopack_igrf_gsm,rgsm_x, rgsm_y, rgsm_z, igrf_bx, igrf_by,igrf_bz 
      endelse

      ;account for user tilt.
      if n_elements(tilt_value) gt 0 then begin
        if n_elements(set_tilt) gt 0 then begin
          tilt = tilt_value[i]
        endif else if n_elements(add_tilt) gt 0 then begin
          tilt = tilt+tilt_value[i]
        endif
      endif
      
      if n_elements(get_tilt) gt 0 then begin
        get_tilt[i] = tilt
      endif

      ;calculate external contribution
      ;iopt = kp+1
      geopack_t89, kp_array[id]+1, rgsm_x, rgsm_y, rgsm_z, t89_bx, t89_by, t89_bz, tilt = tilt
      
      ;total field   
      if keyword_set(igrf_only) then begin
        out_array[idx, 0] = igrf_bx
        out_array[idx, 1] = igrf_by
        out_array[idx, 2] = igrf_bz
      endif else begin
        out_array[idx, 0] = igrf_bx + t89_bx
        out_array[idx, 1] = igrf_by + t89_by
        out_array[idx, 2] = igrf_bz + t89_bz
      endelse

    endif

    i++

  endwhile

return, out_array

end

