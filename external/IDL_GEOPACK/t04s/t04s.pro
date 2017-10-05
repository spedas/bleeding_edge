;+
;Function: t04s
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
;         dsti_array: DST index(nanoTeslas)
;         yimf_array: y component of the interplanetary magnetic field
;         zimf_array: z component of the interplanetary magnetic field
;         w1_array:  index represents a time integral over a storm
;         w2_array:  index represents a time integral over a storm
;         w3_array:  index represents a time integral over a storm
;         w4_array:  index represents a time integral over a storm
;         w5_array:  index represents a time integral over a storm
;         w6_array:  index represents a time integral over a storm
;
;Keywords:
;         period(optional): the amount of time between recalculations of
;             geodipole tilt in seconds(default: 60)  
;             increase this value to decrease run time
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
;         get_nperiod: Returns the number of periods used for the time interval=  ceil((end_time-start_time)/period)
;
;         geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work.
;              
;         IOPGEN (optional): General option flag to pass to geopack_ts04. From Tsyganenko's Fortran:
;                                  IOPGEN=0 - CALCULATE TOTAL FIELD
;                                  IOPGEN=1 - DIPOLE SHIELDING ONLY
;                                  IOPGEN=2 - TAIL FIELD ONLY
;                                  IOPGEN=3 - BIRKELAND FIELD ONLY
;                                  IOPGEN=4 - RING CURRENT FIELD ONLY
;                                  IOPGEN=5 - INTERCONNECTION FIELD ONLY
;
;         IOPT (optional)
;         -  TAIL FIELD FLAG:       IOPT=0  -  BOTH MODES
;                                   IOPT=1  -  MODE 1 ONLY
;                                   IOPT=2  -  MODE 2 ONLY
;
;         IOPB (optional)
;         -  BIRKELAND FIELD FLAG: IOPB=0  -  ALL 4 TERMS
;                                  IOPB=1  -  REGION 1, MODES 1 AND 2
;                                  IOPB=2  -  REGION 2, MODES 1 AND 2
;
;         IOPR (optional)
;         -  RING CURRENT FLAG:    IOPR=0  -  BOTH SRC AND PRC
;                                  IOPR=1  -  SRC ONLY
;                                  IOPR=2  -  PRC ONLY
;              
;Returns: an Nx3 length array of field model data (TS04 + IGRF) or -1L on failure
;
;Example:
;   mag_array = t04s(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,w1_array,w2_array,w3_array,w4_array,w5_array,w6_array)
;   mag_array = t04s(time_array,pos_array,pdyn_array,dsti_array,yimf_array,zimf_array,w1_array,w2_array,w3_array,w4_array,w5_array,w6_array,period=10)
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
;  6. Definition of W1-W6 can be found at:
;      N. A. Tsyganenko and M. I. Sitnov, Modeling the dynamics of the
;      inner magnetosphere during strong geomagnetic storms, J. Geophys. 
;      Res., v. 110 (A3), A03208, doi: 10.1029/2004JA010798, 2005
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-06-04 16:15:16 -0700 (Thu, 04 Jun 2015) $
; $LastChangedRevision: 17809 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/t04s/t04s.pro $
;-

function t04s,tarray,rgsm_array,pdyn,dsti,yimf,zimf,w1,w2,w3,w4,w5,w6, $
    period=period,add_tilt=add_tilt,get_tilt=get_tilt,set_tilt=set_tilt, $
    get_nperiod=get_nperiod,get_period_times=get_period_times,geopack_2008=geopack_2008, $
    iopgen=iopgen, iopt=iopt, iopb=iopb, iopr=iopr

  ;sanity tests, setting defaults
  if igp_test(geopack_2008=geopack_2008) eq 0 then return, -1L
  if not keyword_set(period) then period = 600
  if not keyword_set(iopgen) then iopgen = 0 ; total field by default
  if not keyword_set(iopt) then iopt = 0 ; both modes
  if not keyword_set(iopb) then iopb = 0 ; all 4 terms
  if not keyword_set(iopr) then iopr = 0 ; both SRC and PRC

  if period le 0. then begin
    message, /contiune, 'period must be positive'
    return, -1L
  endif

  t_size = size(tarray, /dimensions)
  pdyn_size = size(pdyn, /dimensions)
  dsti_size = size(dsti, /dimensions)
  yimf_size = size(yimf, /dimensions)
  zimf_size = size(zimf, /dimensions)
  w1_size = size(w1,/dimensions)
  w2_size = size(w2,/dimensions)
  w3_size = size(w3,/dimensions)
  w4_size = size(w4,/dimensions)
  w5_size = size(w5,/dimensions)
  w6_size = size(w6,/dimensions)
  r_size = size(rgsm_array, /dimensions)

  if n_elements(t_size) ne 1 then begin
    message, /continue, 'tarray has incorrect dimensions'
    return, -1L
  endif

  if n_elements(pdyn_size) ne 1 then begin
    message, /continue, 'pdyn has incorrect dimensions'
    return, -1L
  endif

  if n_elements(dsti_size) ne 1 then begin
    message, /continue, 'dsti has incorrect dimensions'
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

  if n_elements(w1_size) ne 1 then begin
    message, /continue, 'w1 has incorrect dimensions'
    return, -1L
  endif

  if n_elements(w2_size) ne 1 then begin
    message, /continue, 'w2 has incorrect dimensions'
    return, -1L
  endif

  if n_elements(w3_size) ne 1 then begin
    message, /continue, 'w3 has incorrect dimensions'
    return, -1L
  endif

  if n_elements(w4_size) ne 1 then begin
    message, /continue, 'w4 has incorrect dimensions'
    return, -1L
  endif

  if n_elements(w5_size) ne 1 then begin
    message, /continue, 'w5 has incorrect dimensions'
    return, -1L
  endif

  if n_elements(w6_size) ne 1 then begin
    message, /continue, 'w6 has incorrect dimensions'
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

  if w1_size[0] eq 0 then begin
      w1_array = replicate(w1,t_size)
  endif else if t_size[0] ne w1_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in w1_array'
      return, -1L
  endif else w1_array = w1

  if w2_size[0] eq 0 then begin
      w2_array = replicate(w2,t_size)
  endif else if t_size[0] ne w2_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in w2_array'
      return, -1L
  endif else w2_array = w2

  if w3_size[0] eq 0 then begin
      w3_array = replicate(w3,t_size)
  endif else if t_size[0] ne w3_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in w3_array'
      return, -1L
  endif else w3_array = w3

  if w4_size[0] eq 0 then begin
      w4_array = replicate(w4,t_size)
  endif else if t_size[0] ne w4_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in w4_array'
      return, -1L
  endif else w4_array = w4

  if w5_size[0] eq 0 then begin
      w5_array = replicate(w5,t_size)
  endif else if t_size[0] ne w5_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in w5_array'
      return, -1L
  endif else w5_array = w5

  if w6_size[0] eq 0 then begin
      w6_array = replicate(w6,t_size)
  endif else if t_size[0] ne w6_size[0] then begin
      message, /continue, 'number of times in tarray does not match number of elements in w6_array'
      return, -1L
  endif else w6_array = w6

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

  ct = (tend-tstart)/period
  nperiod = ceil(ct)+1

  period = double(period)

  parmod = dblarr(t_size, 10)

  parmod[*, 0] = pdyn_array
  parmod[*, 1] = dsti_array
  parmod[*, 2] = yimf_array
  parmod[*, 3] = zimf_array
  parmod[*, 4] = w1_array
  parmod[*, 5] = w2_array
  parmod[*, 6] = w3_array
  parmod[*, 7] = w4_array
  parmod[*, 8] = w5_array
  parmod[*, 9] = w6_array
  
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
        ; the user requested the 2008 version
        geopack_recalc_08, ts[id].year, ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endif else begin
        geopack_recalc, ts[id].year, ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
      endelse

      rgsm_x = rgsm_array[idx, 0]
      rgsm_y = rgsm_array[idx, 1]
      rgsm_z = rgsm_array[idx, 2]

      ;calculate internal contribution
      if ~undefined(geopack_2008) then begin
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
      ;iopt = kp+1

      geopack_ts04, parmod[id, *], rgsm_x, rgsm_y, rgsm_z, t04s_bx, t04s_by, t04s_bz, tilt = tilt, $
        iopgen = iopgen, iopt = iopt, iopb = iopb, iopr = iopr

      ;total field
      out_array[idx, 0] = igrf_bx + t04s_bx
      out_array[idx, 1] = igrf_by + t04s_by
      out_array[idx, 2] = igrf_bz + t04s_bz

    endif

    i++

  endwhile

  return, out_array
end

