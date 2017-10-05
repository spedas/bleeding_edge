;+
;Function: t01
;
;Purpose:  generates an array of model magnetic field vectors from
;          a monotonic time series and an array of 3-d position
;          vectors
;
;Input:
;         tarray: N array representing the time series in seconds utc since 1970
;         rgsm_array: Nx3 array representing the position series in earth radii (required to be in GSM coordinates)
;         pdyn_array: Solar wind pressure (nanoPascals) 
;         dsti_array: DST index (nanoTeslas)
;         yimf_array: y component of the interplanetary magnetic field
;         zimf_array: z component of the interplanetary magnetic field
;         g1_array:  index describes solar wind conditions in the previous hour
;         g2_array: index describes solar wind conditions in the previous hour
;
;Keywords:
;         period(optional): the amount of time between recalculations of
;             geodipole tilt in seconds(default: 60)  increase this
;             value to decrease run time
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
;         get_nperiod: Returns the number of periods used for the time interval=  ceil((end_time-start_time)/period)
;         
;         storm: Use the storm-time version of the T01 model
;         
;         geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work.
;              
;Returns: an Nx3 length array of field model data (T01 + IGRF) or -1L on failure
;
;Example:
;   mag_array = t01(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,g1_array,g2_array)
;   mag_array = t01(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,g1_array,g2_array,period=10)
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
;  6. Definition of G1 and G2 can be found at: 
;  http://modelweb.gsfc.nasa.gov/magnetos/data-based/Paper220.pdf
;  http://modelweb.gsfc.nasa.gov/magnetos/data-based/Paper219.pdf
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-03-20 12:48:33 -0700 (Fri, 20 Mar 2015) $
; $LastChangedRevision: 17157 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/t01/t01.pro $
;-

function t01, tarray, rgsm_array,pdyn,dsti,yimf,zimf,g1,g2,period = period,$
    add_tilt=add_tilt,get_tilt=get_tilt,set_tilt=set_tilt,get_nperiod=get_nperiod,$
    get_period_times=get_period_times,storm=storm,geopack_2008=geopack_2008

  ;sanity tests, setting defaults

  if igp_test(geopack_2008=geopack_2008) eq 0 then return, -1L

  if ~n_elements(tarray) then begin 
    message, /continue, 'tarray must be set'
    return, -1L
  endif

  if ~n_elements(rgsm_array) then begin
    message, /continue, 'rgsm_array must be set'
    return, -1L
  endif
 
  if ~n_elements(pdyn) then begin
    message, /continue, 'pdyn must be set'
    return, -1L
  endif
  
  if ~n_elements(dsti) then begin
    message, /continue, 'dsti must be set'
    return, -1L
  endif

  if ~n_elements(yimf) then begin
    message, /continue, 'yimf must be set'
    return, -1L
  endif

  if ~n_elements(zimf) then begin
    message, /continue, 'zimf must be set'
    return, -1L
  endif

  if ~n_elements(g1) then begin
    message, /continue, 'g1 must be set'
    return, -1L
  endif

  if ~n_elements(g2) then begin
    message, /continue, 'g2 must be set'
    return, -1L
  endif

  if not keyword_set(period) then period = 60

  if period le 0. then begin
    message, /contiune, 'period must be positive'
    return, -1L
  endif

  t_size = size(tarray, /dimensions)

  pdyn_size = size(pdyn, /dimensions)

  dsti_size = size(dsti, /dimensions)

  yimf_size = size(yimf, /dimensions)

  zimf_size = size(zimf, /dimensions)

  g1_size = size(g1,/dimensions)

  g2_size = size(g2,/dimensions)

  r_size = size(rgsm_array, /dimensions)

  if n_elements(t_size) ne 1 then begin
    message, /continue, 'tarray has incorrect dimensions'
    return, -1L
  endif

  if n_elements(pdyn_size) ne 1 then begin
    message, /continue, 'pdyn_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(dsti_size) ne 1 then begin
    message, /continue, 'dsti_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(yimf_size) ne 1 then begin
    message, /continue, 'yimf_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(zimf_size) ne 1 then begin
    message, /continue, 'zimf_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(g1_size) ne 1 then begin
    message, /continue, 'g1_array has incorrect dimensions'
    return, -1L
  endif

  if n_elements(g2_size) ne 1 then begin
    message, /continue, 'g2_array has incorrect dimensions'
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

  if pdyn_size[0] eq 0 then begin
      pdyn_array = replicate(pdyn,t_size)
  endif else if t_size[0] ne pdyn_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in pdyn_array'
      return, -1L
  endif else pdyn_array = pdyn

  if dsti_size[0] eq 0 then begin
      dsti_array = replicate(dsti,t_size)
  endif else if t_size[0] ne dsti_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in dsti_array'
      return, -1L
  endif else dsti_array = dsti

  if yimf_size[0] eq 0 then begin
      yimf_array = replicate(yimf,t_size)
  endif else if t_size[0] ne yimf_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in yimf_array'
      return, -1L
  endif else yimf_array = yimf

  if zimf_size[0] eq 0 then begin
      zimf_array = replicate(zimf,t_size)
  endif else if t_size[0] ne zimf_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in zimf_array'
      return, -1L
  endif else zimf_array = zimf

  if g1_size[0] eq 0 then begin
      g1_array = replicate(g1,t_size)
  endif else if t_size[0] ne g1_size[0] then begin
       message, /continue, 'number of times in tarray does not match number of elements in g1_array'
      return, -1L
  endif else g1_array = g1

  if g2_size[0] eq 0 then begin
      g2_array = replicate(g2,t_size)
  endif else if t_size[0] ne g2_size[0] then begin
       message, /continue, 'number of times in tarray does not match number of elements in g2_array'
      return, -1L
  endif else g2_array = g2

  if n_elements(tarray) gt 1 then begin
    idx = where((tarray[1:t_size[0]-1] - tarray[0:t_size[0]-2]) lt 0,nonmonotone_times)
  
    if nonmonotone_times gt 0 then begin
      dprint,'Warning some times are non monotonic, this may cause unreliable results'
    endif
  endif

  ;defaults to NaN so it will plot properly in tplot and to prevent
  ;insertion of spurious default dindgen values
  out_array = make_array(r_size, /DOUBLE, VALUE = !VALUES.D_NAN)

  tstart = tarray[0]

  tend = tarray[t_size - 1L]

  i = 0L

  ts = time_struct(tarray)

  ct = (tend-tstart)/period
  nperiod = ceil(ct)+1

  period = double(period)

  parmod = dblarr(t_size, 10)

  parmod[*, 0] = pdyn_array
  
  parmod[*, 1] = dsti_array

  parmod[*, 2] = yimf_array

  parmod[*, 3] = zimf_array

  parmod[*, 4] = g1_array

  parmod[*, 5] = g2_array

;validate parameters related to geodipole_tilt
  if arg_present(get_nperiod) then begin
    get_nperiod = nperiod
  endif
  
  if arg_present(get_tilt) then begin
    get_tilt = dblarr(nperiod)
  endif
  
  ;return the times at the center of each period
  if arg_present(get_period_times) then begin
    get_period_times = tstart + dindgen(nperiod)*period+period/2.
  endif
  
  if n_elements(add_tilt) gt 0 then begin
    if n_elements(add_tilt) eq 1 then begin
      tilt_value = replicate(add_tilt[0],nperiod)
    endif else if n_elements(add_tilt) eq nperiod then begin
      tilt_value = add_tilt
    endif else if n_elements(add_tilt) eq t_size[0] then begin
      ;resample tilt values to period intervals, using middle of sample
      period_abcissas = tstart + dindgen(nperiod)*period+period/2
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
      period_abcissas = tstart + dindgen(nperiod)*period+period/2
      tilt_value = interpol(set_tilt,tarray,period_abcissas)
    endif else begin
      dprint,'Error: set_tilt values do not match data values or period values'
      return,-1
    endelse
  endif

  while i lt nperiod do begin

    ;find indices of points to be input this iteration
    idx1 = where(tarray ge tstart + i*period)
    idx2 = where(tarray le tstart + (i+1)*period)

    idx = ssl_set_intersection(idx1, idx2)

    if idx[0] ne -1L then begin 

      id = idx[0]

      ;recalculate geomagnetic dipole
      if ~undefined(geopack_2008) then begin
        geopack_recalc_08, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endif else begin
        geopack_recalc, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endelse

      rgsm_x = rgsm_array[idx, 0]
      rgsm_y = rgsm_array[idx, 1]
      rgsm_z = rgsm_array[idx, 2]

      ;calculate internal contribution
      if ~undefined(geopack_2008) then begin
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
      geopack_t01, parmod[id, *], rgsm_x, rgsm_y, rgsm_z, t01_bx, t01_by, t01_bz, tilt = tilt, storm = storm

      ;total field
      out_array[idx, 0] = igrf_bx + t01_bx
      out_array[idx, 1] = igrf_by + t01_by
      out_array[idx, 2] = igrf_bz + t01_bz

    endif

    i++

  endwhile

return, out_array

end

