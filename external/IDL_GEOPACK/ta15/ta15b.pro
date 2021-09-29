;+
;Function: ta15b
;
;Purpose:  generates an array of model magnetic field vectors from
;          a monotonic time series and an array of 3-d position
;          vectors
;
;Input:
;         tarray: N array representing the time series in seconds utc since 1970
;         rgsm_array: Nx3 array representing the position series in
;             earth radii (required to be in GSM coordinates)
;         The following arguments can either be N length arrays or
;         single values
;         pdyn_array: Solar wind pressure (nanoPascals)
;         yimf_array: y component of the interplanetary magnetic field
;         zimf_array: z component of the interplanetary magnetic field
;         xind_array: B-index parameter (see Boynton et al., 2011)
;
;Keywords:
;         period(optional): the amount of time between recalculations of
;             geodipole tilt in seconds(default: 60)
;             increase this value to decrease run time
;             By default, the center (not the start) of the first period is now aligned with the start time.
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
;         set_tilt: Alternative dipole_tilt value rather than the geopack tilt.
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
;
;Returns: an Nx3 length array of field model data (TS07 + IGRF) or -1L on failure
;
;Example:
;   mag_array = ts07(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,w1_array,w2_array,w3_array,w4_array,w5_array,w6_array)
;   mag_array = ts07(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,w1_array,w2_array,w3_array,w4_array,w5_array,w6_array,period=10)
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
;      
;
;  See Boynton 2011 for details:
;  https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2010JA015505
;;
;  TA15B and TA15N model description:
;  https://geo.phys.spbu.ru/~tsyganenko/TA15_Model_description.pdf
;  
;  The B-index calculation is implemented in omni2bindex.pro
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/ta15b.pro $
;-

function ta15b,tarray,rgsm_array,pdyn,yimf,zimf,xind, $
  period=period,add_tilt=add_tilt,get_tilt=get_tilt,set_tilt=set_tilt, $
  get_nperiod=get_nperiod,get_period_times=get_period_times,geopack_2008=geopack_2008, $
  exact_tilt_times=exact_tilt_times

  ;sanity tests, setting defaults
  ; Ensure flags are set to their default values if not provided

  if undefined(geopack_2008) then geopack_2008=0
  if undefined(exact_tilt_times) then exact_tilt_times=0
  if ta15_supported() eq 0 then return, -1L
  if igp_test(geopack_2008=geopack_2008) eq 0 then return, -1L
  if not keyword_set(period) then period = 600
 

  if period le 0. then begin
    message, /continue, 'period must be positive'
    return, -1L
  endif

  t_size = size(tarray, /dimensions)
  pdyn_size = size(pdyn, /dimensions)
  yimf_size = size(yimf, /dimensions)
  zimf_size = size(zimf, /dimensions)
  xind_size = size(xind,/dimensions)
  r_size = size(rgsm_array, /dimensions)

  if n_elements(t_size) ne 1 then begin
    message, /continue, 'tarray has incorrect dimensions'
    return, -1L
  endif

  if n_elements(pdyn_size) ne 1 then begin
    message, /continue, 'pdyn has incorrect dimensions'
    return, -1L
  endif

  if n_elements(yimf_size) ne 1 then begin
    message, /continue, 'yimf has incorrect dimensions'
    return, -1L
  endif

  if n_elements(zimf_size) ne 1 then begin
    message, /continue, 'zimf has incorrect dimensions'
    return, -1L
  endif

  if n_elements(xind_size) ne 1 then begin
    message, /continue, 'xind has incorrect dimensions'
    return, -1L
  endif


  if n_elements(r_size) ne 2 || r_size[1] ne 3 then begin
    message, /continue, 'rgsm has incorrect dimensions'
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

  if xind_size[0] eq 0 then begin
    xind_array = replicate(xind,t_size)
  endif else if t_size[0] ne xind_size[0] then begin
    message, /continue, 'number of times in tarray does not match number of elements in xind_array'
    return, -1L
  endif else xind_array = xind


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

  period = double(period)

  parmod = dblarr(t_size, 10)

  parmod[*, 0] = pdyn_array
  parmod[*, 1] = yimf_array
  parmod[*, 2] = zimf_array
  parmod[*, 3] = xind_array

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

  ; find start, end years and download parameter files
  time_start = strmid(time_string(tarray[0]), 0, 4)
  time_end = strmid(time_string(tarray[n_elements(tarray)-1]), 0, 4)


  tilt = 0.0D    ;  ensure tilt is always defined
  
  while i lt nperiod do begin
 
    ; Default to most recently calculated tilt, if not points exist in this period
    if n_elements(get_tilt) gt 0 then begin
      get_tilt[i] = tilt
    endif

    if exact_tilt_times then begin
      idx = [i]
    endif else begin
      ;find indices of points to be input this iteration
      idx1 = where(tarray ge tstart + i*period - period/2.0D)
      idx2 = where(tarray le tstart + (i+1)*period - period/2.0D)

      idx = ssl_set_intersection(idx1, idx2)
    endelse

    if idx[0] ne -1L then begin
      id = idx[0]

      ;recalculate geomagnetic dipole
      if geopack_2008 then begin
        ; the user requested the 2008 version
        geopack_recalc_08, ts[id].year, ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endif else begin
        geopack_recalc, ts[id].year, ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endelse

      rgsm_x = rgsm_array[idx, 0]
      rgsm_y = rgsm_array[idx, 1]
      rgsm_z = rgsm_array[idx, 2]

      ;calculate internal contribution
      if geopack_2008 then begin
        ; Geopack 2008 uses the GSW coordinate system instead of GSM
        geopack_igrf_gsw_08, rgsm_x, rgsm_y, rgsm_z, igrf_bx, igrf_by, igrf_bz
      endif else begin
        geopack_igrf_gsm, rgsm_x, rgsm_y, rgsm_z, igrf_bx, igrf_by, igrf_bz
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
 
      geopack_ta15b, parmod[id, *], rgsm_x, rgsm_y, rgsm_z, ta15b_bx, ta15b_by, ta15b_bz, tilt=tilt

      ;total field
      out_array[idx, 0] = igrf_bx + ta15b_bx
      out_array[idx, 1] = igrf_by + ta15b_by
      out_array[idx, 2] = igrf_bz + ta15b_bz

    endif

    i++

  endwhile

  return, out_array
end

