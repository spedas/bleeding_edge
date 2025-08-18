;+
;Function: t96
;
;Purpose:  generates an array of model magnetic field vectors from
;          a monotonic time series and an array of 3-d position
;          vectors
;          
;Input:
;         tarray: N array representing the time series in seconds utc since 1970
;         rgsm_array: Nx3 array representing the position series in
;             earth radii (required to be in GSM coordinates)
;
;         The following arguments can either be N length arrays or
;         single values
;         pdyn: Solar wind pressure (nanoPascals) 
;         dsti: DST index(nanoTeslas)
;         yimf: y component of the interplanetary magnetic field
;         zimf: z component of the interplanetary magnetic field
;
;Keywords:
;         period(optional): the amount of time between recalculations of
;             geodipole tilt in seconds(default: 60)  increase this
;             value to decrease run time.  The first period center time (not the start time) is now aligned
;             with the first sample time.  JWL 2021-03-22
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
;         set_tilt: Alternative alternative dipole_tilt value rather than the geopack tilt.
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
;         exact_tilt_times (optional):  Set this keyword to avoid grouping similar times (default 10 minutes) and instead
;              recalculate the dipole tilt at each input time
;                   
;         get_nperiod: Returns the number of periods used for the time interval=  ceil((end_time-start_time)/period)
;                   
;         geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work.
;              
;Returns: an Nx3 length array of field model data (T96 + IGRF) or -1L on failure
;
;Example:
;   mag_array = t96(time_array,pos,pdyn,dsti,yimf,zimf)
;   mag_array = t96(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,period=10)
;   
;Notes:
;  1. Relies on the IDL/Geopack Module provided by Haje Korth JHU/APL
;      and N.A. Tsyganenko NASA/GSFC, if the module is not installed
;      this function will fail.  
;  2. Sums the contribution from the internal field model and the
;      external field model.
;  3. Has a loop with number of iterations = (tarray[n_elements(t_array)]-tarray[0])/period
;      This means that as period becomes smaller the amount time of this
;      function should take will grow quickly.
;  4. Position units are in earth radii, be sure to divide your normal
;      units by 6371.2 km to convert them.
;      6371.2 = the value used in the GEOPACK FORTRAN code for Re
;  5.Find more documentation on the inner workings of the model,
;      any gotchas, and the meaning of the arguments at:
;      http://geo.phys.spbu.ru/~tsyganenko/modeling.html
;      -or-
;      http://ampere.jhuapl.edu/code/idl_geopack.html
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-06-24 16:12:40 -0700 (Thu, 24 Jun 2021) $
; $LastChangedRevision: 30083 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/t96/t96.pro $
;-

function t96, tarray, rgsm_array,pdyn,dsti,yimf,zimf, period = period,$
    add_tilt=add_tilt,get_tilt=get_tilt,set_tilt=set_tilt,get_nperiod=get_nperiod,$
    get_period_times=get_period_times,geopack_2008=geopack_2008, exact_tilt_times=exact_tilt_times

  ;sanity tests, setting defaults
  ; Ensure flags are set to their default values if not provided

  if undefined(geopack_2008) then geopack_2008=0
  if undefined(exact_tilt_times) then exact_tilt_times=0

  if igp_test(geopack_2008=geopack_2008) eq 0 then return, -1L

  if n_elements(tarray) eq 0 then begin 
    dprint, 'tarray must be set'
    return, -1L
  endif

  if n_elements(rgsm_array) eq 0 then begin
    dprint, 'rgsm_array must be set'
    return, -1L
  endif
 
  if n_elements(pdyn) eq 0 then begin
    dprint, 'pdyn must be set'
    return, -1L
  endif
  
  if n_elements(dsti) eq 0 then begin
    dprint, 'dsti must be set'
    return, -1L
  endif

  if n_elements(yimf) eq 0 then begin
    dprint, 'yimf must be set'
    return, -1L
  endif

  if n_elements(zimf) eq 0 then begin
    dprint, 'zimf must be set'
    return, -1L
  endif

  if n_elements(period) eq 0 then period = 60

  if period le 0. then begin
    message, /continue, 'period must be positive'
    return, -1L
  endif

  t_size = size(tarray, /dimensions)

  pdyn_size = size(pdyn, /dimensions)

  dsti_size = size(dsti, /dimensions)

  yimf_size = size(yimf, /dimensions)

  zimf_size = size(zimf, /dimensions)

  r_size = size(rgsm_array, /dimensions)

  if n_elements(t_size) ne 1 then begin
    dprint, 'tarray has incorrect dimensions'
    return, -1L
  endif

  if n_elements(pdyn_size) ne 1 then begin
    dprint, 'pdyn_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(dsti_size) ne 1 then begin
    dprint, 'dsti_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(yimf_size) ne 1 then begin
    dprint, 'yimf_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(zimf_size) ne 1 then begin
    dprint, 'zimf_array has incorrect dimensions'
    return, -1L
  endif
  
  if n_elements(r_size) ne 2 || r_size[1] ne 3 then begin
    dprint, 'rgsm_array has incorrect dimensions'
    return, -1L
  endif

  if t_size[0] ne r_size[0] then begin
    dprint, 'number of times in tarray does not match number of positions in rgsm_array'
    return, -1L
  endif

  if pdyn_size[0] eq 0 then begin
      pdyn_array = replicate(pdyn,t_size)
  endif else if t_size[0] ne pdyn_size[0] then begin
      dprint, 'number of times in tarray does not match number of elements in pdyn_array'
      return, -1L
  endif else pdyn_array = pdyn

  if dsti_size[0] eq 0 then begin
      dsti_array = replicate(dsti,t_size)
  endif else if t_size[0] ne dsti_size[0] then begin
      dprint, 'number of times in tarray does not match number of elements in dsti_array'
      return, -1L
  endif else dsti_array = dsti

  if yimf_size[0] eq 0 then begin
      yimf_array = replicate(yimf,t_size)
  endif else if t_size[0] ne yimf_size[0] then begin
      dprint, 'number of times in tarray does not match number of elements in yimf_array'
      return, -1L
  endif else yimf_array = yimf

  if zimf_size[0] eq 0 then begin
      zimf_array = replicate(zimf,t_size)
  endif else if t_size[0] ne zimf_size[0] then begin
      dprint, 'number of times in tarray does not match number of elements in zimf_array'
      return, -1L
  endif else begin 
      zimf_array = zimf
  endelse

  if n_elements(tarray) gt 1 then begin
    idx = where((tarray[1:t_size[0]-1] - tarray[0:t_size[0]-2]) lt 0,nonmonotone_times)
  
    if nonmonotone_times gt 0 then begin
      dprint,'Warning some times are non monotonic, this may cause unreliable results'
    endif
  endif

;  out_array = dindgen(r_size)

  ;defaults to NaN so it will plot properly in tplot and to prevent
  ;insertion of spurious default dindgen values
  out_array = make_array(r_size, /DOUBLE, VALUE = !VALUES.D_NAN)

  tstart = tarray[0]

  tend = tarray[t_size - 1L]

  i = 0L

  ts = time_struct(tarray)

  if ~exact_tilt_times then begin
    ; The start time is now the center of the first period, rather than the start, so add an extra 1/2 period
    ct = 0.5D + (tend-tstart)/period
    nperiod = ceil(ct)
  endif else nperiod = n_elements(tarray)

  ;I don't think period should be an integer, doesn't allow subsecond periods
  ;period = long(period)
  period = double(period)

  parmod = dblarr(t_size, 10)

  parmod[*, 0] = pdyn_array
  
  parmod[*, 1] = dsti_array

  parmod[*, 2] = yimf_array

  parmod[*, 3] = zimf_array
  
  ;validate parameters related to geodipole_tilt
  if arg_present(get_nperiod) then begin
    get_nperiod = nperiod
  endif
  
  if arg_present(get_tilt) then begin
    get_tilt = dblarr(nperiod)
  endif
  
  ;return the times at the center of each period
  if arg_present(get_period_times) then begin
    if ~exact_tilt_times then begin
      get_period_times = tstart + dindgen(nperiod)*period
    endif else get_period_times=tarray
  endif
  
  if n_elements(add_tilt) gt 0 then begin
    if n_elements(add_tilt) eq 1 then begin
      tilt_value = replicate(add_tilt[0],nperiod)
    endif else if n_elements(add_tilt) eq nperiod then begin
      tilt_value = add_tilt
    endif else if n_elements(add_tilt) eq t_size[0] then begin
      ;resample tilt values to period intervals, using middle of sample
      if ~exact_tilt_times then begin
        period_abcissas = tstart + dindgen(nperiod)*period
      endif else begin
        period_abcissas = tarray
      endelse
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
      if ~exact_tilt_times then begin
        period_abcissas = tstart + dindgen(nperiod)*period
      endif else begin
        period_abcissas = tarray
      endelse
      tilt_value = interpol(set_tilt,tarray,period_abcissas)
    endif else begin
      dprint,'Error: set_tilt values do not match data values or period values'
      return,-1
    endelse
  endif
  
  tilt = 0.0D    ; Ensure tilt is initialized, otherwise may be undefined until some period contains at least one data point
  
  while i lt nperiod do begin

    if exact_tilt_times then begin
      idx = [i]
    endif else begin
      ;find indices of points to be input this iteration
      idx1 = where(tarray ge tstart + i*period - period/2.0D)
      idx2 = where(tarray le tstart + (i+1)*period - period/2.0D)

      idx = ssl_set_intersection(idx1, idx2)
    endelse

    ; If not recomputed for this interval, use the most recent value rather than leaving it untouched
    
    if n_elements(get_tilt) gt 0 then begin
      get_tilt[i] = tilt
    endif

    if idx[0] ne -1L then begin 

      id = idx[0]

      ;recalculate geomagnetic dipole
      if geopack_2008 then begin
        geopack_recalc_08, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endif else begin
        geopack_recalc, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endelse

      rgsm_x = rgsm_array[idx, 0]
      rgsm_y = rgsm_array[idx, 1]
      rgsm_z = rgsm_array[idx, 2]

      ;calculate internal contribution
      if geopack_2008 then begin
        geopack_igrf_gsw_08,rgsm_x, rgsm_y, rgsm_z, igrf_bx, igrf_by,igrf_bz 
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
      geopack_t96, parmod[id, *], rgsm_x, rgsm_y, rgsm_z, t96_bx, t96_by, t96_bz, tilt = tilt

      ;total field
      out_array[idx, 0] = igrf_bx + t96_bx
      out_array[idx, 1] = igrf_by + t96_by
      out_array[idx, 2] = igrf_bz + t96_bz

    endif

    i++

  endwhile

  return, out_array

end

