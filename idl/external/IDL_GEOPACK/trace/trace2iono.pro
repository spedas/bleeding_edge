;+
;Procedure: trace2iono
;
;Purpose: Generates a model field line footprint from an array of given
;         positions and times,will also trace field lines at the user's request
;         This program will always use the refined foot point mappings(a
;         modification made by Vassilis Angelopoulos to provide more accurate
;         mappings of foot points) unless you request the standard mapping;
;
;Input:
;         tarray: N length array storing the position times in seconds utc since 1970
;
;         in_pos_array: Nx3 array representing the position series (in
;         km gsm by default)
;
;         out_foot_array: named variable in which to store the footprints
;         calculated by this function(will be an Nx3 array) will be returned
;         (in RE gsm by default)
;
;Keywords:
;         out_trace_array(optional): named variable in which to store the traces of
;             field lines leading to footprints. Because traces are of variable
;             length, the returned array will be of dimensions NxDx3
;             D is the maximum number of vectors in any of the traces.
;             Shorter traces will have NaNs filling the space at the end
;             of the array  
;
;         in_coord(optional): set this keyword to a string indicating the
;             coordinate system input position data is in.
;             (can be 'gei','geo','gse','gsm',or 'sm' default: gsm)
;
;         out_coord(optional): set this keyword to a string indicating the
;             coordinate system output data should be in.
;             (can be 'gei','geo','gse','gsm',or 'sm' default: gsm)
;
;         internal_model(optional): set this keyword to a string
;             indicating the internal model that should be used in tracing
;             (can be 'dip' or 'igrf' default:igrf)
;
;         external_model(optional): set this keyword to a string
;             indicating the external model that should be used in tracing
;             (can be 'none', 't89', 't96', 't01', 't04s','ts07', 'ta15b', 'ta15n', 'ta16'
;              default: none)
;
;         SOUTH(optional): set this keyword to indicate that fields
;             should be traced towards the southern hemisphere. By default
;             they trace north.
;         
;         KM(optional): set this keyword to indicate that input
;             and output will be in KM not RE
; 
;         par(optional): parameter input for the external field model
;             if using t89 then it should be an N element array containing 
;             kp values or a single kp value, if using t96,t01,t04s it
;             should be an N x 10 element array of parmod values or a 10
;             element array or a 1x10 element array. At the moment if an
;             external model is set and this is not set an error will be thrown.
;           
;         period(optional): the amount of time between recalculations of
;             geodipole tilt and input of new model parameters in
;             seconds (default: 60)  increase this value to decrease run time
;             if field line traces are requested this parameter is
;             ignored and new model parameters are input on each
;             iteration
;
;         error(optional): named variable in which to return the error state
;             of the procedure.  1 for success, 0 for failure
;         
;         standard_mapping(optional): Set to use Tsyganenko's
;             unmodified version instead of the Angelopoulos's 
;             refined version
;             
;         R0(optional):  radius of a sphere (in re), defining the inner boundary of the tracing region
;         (usually, earth's surface or the ionosphere, where r0~1.0)
;         if the field line reaches that sphere from outside, its inbound tracing is
;         terminated and the crossing point coordinates xf,yf,zf  are calculated.
;         (units are km if /km is set)
;
;         RLIM(optional) - radius of a sphere (in re), defining the outer boundary of the tracing region;
;         if the field line reaches that boundary from inside, its outbound tracing is
;         terminated and the crossing point coordinates xf,yf,zf are calculated.(default 60 RE)
;         (units are km if /km is set)
;
;         NOBOUNDARY(optional): Override boundary limits.
;
;         STORM(optional): Specify storm-time version of T01 external 
;             magnetic field model use together with /T01.
;
;         add_tilt:  Increment the default dipole tilt used by the model with
;             a user provided tilt in degrees.  Result will be produced with TSY_DEFAULT_TILT+ADD_TILT
;             Value can be set to an N length array an M length array or a single element array. 
;             N is the number of time elements for the data.  M is the number of periods in the time interval.(determined by the period keyword)
;             If single element is provided the same correction will be applied to all periods.   
;             If an N length array is provided, the data will be re-sampled to an M length array. Consequently, if
;             the values change quickly, the period may need to be shortened. 
;         
;         get_tilt: Returns the dipole_tilt parameter used for each period. 
;             Returned value has a number of elements equal to the value returned by get_nperiod
;         
;         set_tilt: Alternative alternative dipole_tilt value rather than the geopack tilt.
;             This input can be an M length array, and N length array or a single elemnt.
;             Value can be set to an N length array an M length array or a single element array. 
;             N is the number of time elements for the data.  M is the number of periods in the time interval.(determined by the period keyword)
;             If an N length array is provided, the data will be re-sampled to an M length array. Consequently, if
;             the values change quickly, the period may need to be shortened. 
;             set_tilt will cause add_tilt to be ignored. 
;
;         exact_tilt_times (optional):  Set this keyword to avoid grouping similar times (default 10 minutes) and instead
;              recalculate the dipole tilt at each input time
;                   
;         get_nperiod: Returns the number of periods used for the time interval=  ceil((end_time-start_time)/period)
;
;         geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work.
;              
;Example: trace2iono,in_time,in_pos,out_foot
;
;Notes:
;  1. Relies on the IDL/Geopack Module provided by Haje Korth JHU/APL
;      and N.A. Tsyganenko NASA/GSFC, if the module is not installed
;      this function will fail.  
;  2. Has a loop with number of iterations =
;      (tarray[n_elements(t_array)]-tarray[0])/period
;      This means that as period becomes smaller the amount time of this
;      function should take will grow quickly.
;  3. If the trace_array variable is set
;      the period variable will be ignored.  The program will
;      recalculate for each value, this will cause the program to
;      run very slowly. 
;  4. All calculations are done internally in double precision
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2025-06-22 10:49:35 -0700 (Sun, 22 Jun 2025) $
; $LastChangedRevision: 33400 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/trace/trace2iono.pro $
;-

pro trace2iono, tarray, in_pos_array, out_foot_array, out_trace_array=out_trace_array, $
    in_coord=in_coord, out_coord=out_coord, internal_model=internal_model, external_model=external_model, $
    south=south, km=km, par=par, period=period, error=error, standard_mapping=standard_mapping, r0=r0, $
    rlim=rlim, add_tilt=add_tilt, get_tilt=get_tilt, set_tilt=set_tilt, get_nperiod=get_nperiod, $
    get_period_times=get_period_times, geopack_2008=geopack_2008, exact_tilt_times=exact_tilt_times, $
    ts07_param_dir=ts07_param_dir, ts07_param_file=ts07_param_file,skip_ts07_load=skip_ts07_load, skip_ta16_load=skip_ta16_load, _extra=_extra

    COMPILE_OPT idl2
    if ta16_supported() eq 1 then ta16supported=1 else ta16supported=0
    
    if undefined(geopack_2008) then geopack_2008=0
    if undefined(exact_tilt_times) then exact_tilt_times=0
    if undefined(skip_ts07_load) then skip_ts07_load=0
    if undefined(skip_ta16_load) then skip_ta16_load=0
    
    error = 0
    
    ;constant arrays used for input validation
    valid_coords = ['gei', 'gse', 'geo','gsm', 'sm']
    valid_internals = ['dip', 'igrf']
    valid_externals = ['none', 't89', 't96', 't01', 't04s','ts07', 'ta15b', 'ta15n', 'ta16']
    
    ;6371.2 = the value used in the GEOPACK FORTRAN code for Re
    km_in_re = 6371.2D
    
    if not keyword_set(rlim) then $
       if keyword_set(km) then $
          rlim = 60D*km_in_re $
       else $
          rlim = 60D

    ;test to make sure idl/geopack library is installed
    if igp_test(geopack_2008=geopack_2008) eq 0 then return
    
    if not keyword_set(tarray) then begin 
      message, /continue, 'tarray must be set'
      return
    endif
    
    if not keyword_set(in_pos_array) then begin
      message, /continue, 'in_pos_array must be set'
      return
    endif
    
    ;be sure to test this predicate
    if not arg_present(out_foot_array) then begin
      message, /continue, 'out_foot_array must be set'
      return
    endif
    
    if keyword_set(in_coord) then begin 
      in_coord2 = strlowcase(in_coord)
      if(strfilter(valid_coords, in_coord2) eq '') then begin
        message, /continue, 'in_coord not a valid coordinate name'
        return
      endif
    endif else in_coord2 = 'gsm'
    
    if keyword_set(out_coord) then begin 
      out_coord2 = strlowcase(out_coord)
      if(strfilter(valid_coords, out_coord2) eq '') then begin
        message, /continue, 'out_coord not a valid coordinate name'
        return
      endif
    endif else out_coord2 = 'gsm'
    
    if keyword_set(internal_model) then begin 
      internal_model2 = strlowcase(internal_model)
      if(strfilter(valid_internals, internal_model2) eq '') then begin
        message, /continue, 'internal_model not a valid internal model name'
        return
      endif
    endif else internal_model2 = 'igrf'
    
    if keyword_set(external_model) then begin 
      external_model2 = strlowcase(external_model)
      if(strfilter(valid_externals, external_model2) eq '') then begin
        message, /continue, 'external_model not a valid external model name'
        return
      endif
    endif else external_model2 = 'none'    
    
    if ta16supported eq 0 && external_model2 eq 'ta16' then begin
      message, /continue, 'external_model ta16 is only supported with geopack DLM version 10.9 or newer'
      return
    endif
    
    if (external_model2 eq 'ta16') && (skip_ta16_load eq 0) then ta16_setpath
    
    if keyword_set(south) then dir = 1.0D $
    else dir = -1.0D
    
    ;convert inputs into double precision to ensure consistency of calculations
    tarray2 = double(tarray)
    
    if n_elements(tarray2) gt 1 then begin ;only check for monotonicity if array has more than one element (lphilpott oct-2011)
      idx = where((tarray2[1:n_elements(tarray2)-1] - tarray2[0:n_elements(tarray2)-2]) lt 0,nonmonotone_times)
      
      if nonmonotone_times gt 0 then begin
        dprint,'Warning some times are non monotonic, this may cause unreliable results'
      endif
    endif
    
    in_pos_array2 = double(in_pos_array)
    
    if n_elements(r0) gt 0 then r02 = double(r0)
    
    if n_elements(rlim) gt 0 then rlim2 = double(rlim)
    
    if keyword_set(km) then begin
       in_pos_array2 = in_pos_array2/km_in_re
    
       if n_elements(r02) gt 0 then r02 = r02/km_in_re
    
       if n_elements(rlim2) gt 0 then rlim2 = rlim2/km_in_re
    endif else begin
       idx_temp = where(abs(in_pos_array2) gt km_in_re)
    
       if idx_temp[0] ne -1L then begin
          message,/continue,'!!!! WARNING !!!! the magnitude of your rgsm values suggests your data may be in km'
          message,/continue,'Default is Re, please set keyword "km" or see calling sequence by typing doc_library,"trace2iono".'
       endif
    endelse
    
    if internal_model2 eq 'igrf' then IGRF = 1 else IGRF = 0
    
    if external_model2 ne 'none' and (n_elements(par) eq 0) then begin
       message,/continue,'par must be set if external model is set'
       return
    endif
    
    if external_model2 eq 't89' then begin
      ;these switches used to tell the
      ;IDL/GEOPACK trace function which
      ;model to use
      vT89 = 1
      vT96 = 0
      vT01 = 0
      vTS04 = 0
      vTS07 = 0
      vTA15N = 0
      vTA15B = 0
      vTA16 = 0
       
      ;intialize and check par array
      if size(par,/n_dim) eq 0 then par_array = make_array(n_elements(tarray2),/DOUBLE,value=par)
    
      if size(par,/n_dim) eq 1 then begin
          if n_elements(par) ne n_elements(tarray2) then begin
              message,/continue,'par must have the same number of elements as tarray '
              return
          endif else par_array = double(par)
      endif
    
      if size(par,/n_dim) gt 1 then begin
          message,/continue,'par must have 0 or 1 dimensions when used with model t89'
          return
      endif
    
      ; Range check for Kp
      ; Valid IOPT values are in the range [1.0,7.0]
      ; kp2iopt will replace any out-of-range iopt values with 1.0 or 7.0 as appropriate,
      ; so we only warn here instead of throwing an error.
      
      par_idx_low = where(par_array lt 0.0)
    
      if par_idx_low[0] ne -1L then begin
          message, /continue, 'par (Kp) has value less than 0 (will be treated as 0)'
      endif
    
      par_idx_high = where(par_array gt 6.0)
    
      if par_idx_high[0] ne -1L then begin
          message, /continue, 'par (Kp) has value greater than 6 (will be treated as 6)'
      endif
      
      par_array=kp2iopt(par_array)   ; Convert Kp values to iopt values for T89 model
      
    endif else if external_model2 ne 'none' then begin
       ;these switches used to tell the
       ;IDL/GEOPACK trace function which
       ;model to use
       vT89 = 0
       if external_model2 eq 't96' then vT96 = 1 else vT96 = 0
       if external_model2 eq 't01' then vT01 = 1 else vT01 = 0
       if external_model2 eq 't04s' then vTS04 = 1 else vTS04 = 0
       if external_model2 eq 'ts07' then vTS07 = 1 else vTS07 = 0
       if external_model2 eq 'ta15n' then vTA15N=1 else vTA15N = 0
       if external_model2 eq 'ta15b' then vTA15B=1 else vTA15B = 0
       if external_model2 eq 'ta16' then vTA16=1 else vTA16 = 0
    
       ;check par array
       s = size(par,/dimensions)
    
       if n_elements(s) eq 1 && s[0] eq 10 then par_array = transpose(rebin(par,10,n_elements(tarray2))) else $
       if n_elements(s) eq 2 && s[0] eq 1 && s[1] eq 10 then par_array = rebin(par,n_elements(tarray2),10) else $
       if n_elements(s) ne 2 || s[1] ne 10 || s[0] ne n_elements(tarray2) then begin
          message,/continue,'par must be an N x 10 array or 10 element array if ' + external_model2 + ' is set'
          return
       endif else par_array = double(par)
    
    endif else begin
      vT89 = 0
      vT96 = 0
      vT01 = 0
      vTS04 = 0
      vTS07 = 0
      vTA15N = 0
      vTA15B = 0
      vTA16 = 0
    endelse
    
    ;check input array dimensions
    t_size = size(tarray2, /dimensions)
    r_size = size(in_pos_array2, /dimensions)
    
    if n_elements(t_size) ne 1 then begin
       message, /continue, 'tarray has incorrect dimensions'
       return
    endif
    
    if n_elements(r_size) ne 2 || r_size[1] ne 3 then begin
       message, /continue, 'in_pos_array has incorrect dimensions'
       return
    endif
    
    if t_size[0] ne r_size[0] then begin
       message, /continue, 'number of times in tarray does not match number of positions in in_pos_array'
       return
    endif
        
    ts = time_struct(tarray2)
    
    tstart = tarray2[0]
    
    ;all calculations will be done in GSM (or GSW, for Geopack 2008) internally
    if geopack_2008 then begin
        if in_coord2 eq 'gei' then begin
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gei2gse
        endif else if in_coord2 eq 'geo' then begin
           cotrans,in_pos_array2,in_pos_array2,tarray2,/geo2gei
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gei2gse
        endif else if in_coord2 eq 'sm' then begin 
           cotrans,in_pos_array2,in_pos_array2,tarray2,/sm2gse
        endif else if in_coord2 eq 'gsm' then begin
           cotrans,in_pos_array2,in_pos_array2,tarray2, /gsm2gse
        endif 
        ; GSE->GSW is inside the main loop because it is time dependent 
    endif else begin
        if in_coord2 eq 'gei' then begin
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gei2gse
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gse2gsm
        endif else if in_coord2 eq 'geo' then begin
           cotrans,in_pos_array2,in_pos_array2,tarray2,/geo2gei
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gei2gse
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gse2gsm
        endif else if in_coord2 eq 'gse' then $
           cotrans,in_pos_array2,in_pos_array2,tarray2,/gse2gsm $
        else if in_coord2 eq 'sm' then $
           cotrans,in_pos_array2,in_pos_array2,tarray2,/sm2gsm
    endelse
    
    
    ;intialize and check period
    if not keyword_set(period) then period2 = 60.0D  $
    else period2 = double(period)
    
    if period2 le 0. then begin
      message, /continue, 'period must be positive'
      return
    endif
    
    ;defaults to NaN so it will plot properly in tplot and to prevent
    ;insertion of spurious default dindgen values
    out_foot_array = make_array(r_size, /DOUBLE, VALUE = !VALUES.D_NAN)

    
    ;loop boundaries and storage if traces requested
    if arg_present(out_trace_array) then begin
       ;if traces are requested every point is processed individually
       ct = t_size[0] - 1L
       
       ;allocate space for traces, since traces may have different lengths
       ;pointers are allocated
       tr_ptr_arr = ptrarr(t_size[0])
    
       ;the maximum trace size will be stored so we'll know how large to
       ;make the array that is ultimately output
       max_trace_size = 0
    endif else begin ;loop boundaries if traces are not requested
       if ~exact_tilt_times then begin
        tend = tarray2[t_size[0] - 1L]
        ;number of iterations is interval length divided by period length
        ct = ceil((tend-tstart)/period2)
       endif else begin
        ct = t_size[0] - 1L
       endelse           
    endelse
    
    nperiod = ct+1
    
    if arg_present(get_nperiod) then begin
      get_nperiod = nperiod
    endif
    
    if arg_present(get_tilt) then begin
      get_tilt = dblarr(nperiod)
    endif
    
    if arg_present(get_period_times) then begin
      if arg_present(out_trace_array) or (exact_tilt_times) then begin
        ; If traces are requested, or if exact_tilt_times keyword specified, tilt times are identical to input times
        get_period_times = tarray
      endif else begin
        ; Otherwise, divide interval up into periods and calculate the tilt at the start of each period.
        get_period_times = tstart + dindgen(nperiod)*period2
      endelse
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
        return
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
        return
      endelse
    endif
    
    i = 0L
    
    if vTS07 eq 1 then begin
       if ~keyword_set(skip_ts07_load) then begin
        
          ; find start, end years and download parameter files
          time_start = strmid(time_string(tarray[0]), 0, 4)
          time_end = strmid(time_string(tarray[n_elements(tarray)-1]), 0, 4)

          if time_end gt time_start then begin
            tdiff = 0 + time_end - time_start
            years = [time_start]
            for i=1, tdiff do begin
              years = [years, time_start + i]
            endfor
          endif else ts07_years = [time_start]

          ts07_download, years=ts07_years

          ; Directory for model parameters.
          if not keyword_set(ts07_param_dir) then begin
            ts07_param_dir = !spedas.geopack_param_dir
          endif else if ~file_test(ts07_param_dir, /READ, /directory) then begin
            ts07_param_dir = !spedas.geopack_param_dir
          endif
          ; Directory that contains the coeficient files
          GEOPACK_TS07_SETPATH, ts07_param_dir[0]
          if keyword_set(ts07_param_file) then begin
            ; Coeficcient filename only, without the full path
            GEOPACK_TS07_LOADCOEF, file_basename(ts07_param_file[0])
          endif else begin
            dprint,'Error: ts07_param_file must be specified if using model ts07'
            return       
          endelse
       endif else begin
          dprint,'Skipping loading of TS07 parameters'
       endelse
    
    endif
  
    tilt = 0.0D   ; Ensure tilt is always defined  
    while i le ct do begin

       ; Default to last calculated tilt value, in case no points lie in this interval      
       if n_elements(get_tilt) gt 0 then begin
         get_tilt[i] = tilt
       endif
      
       ;call for each point individually if field line traces are requrested
       if arg_present(out_trace_array) then begin
    
          ;recalculate magnetic dipole
          if geopack_2008 then begin
            geopack_recalc_08, ts[i].year,ts[i].doy, ts[i].hour, ts[i].min, ts[i].sec, tilt = tilt
          endif else begin
            geopack_recalc, ts[i].year,ts[i].doy, ts[i].hour, ts[i].min, ts[i].sec, tilt = tilt
          endelse 
          
          ;calculate which par values should be used on this iteration
          if vT89 eq 1 then par_iter = par_array[i] $
          else if vT96 eq 1 || vT01 eq 1 || vTS04 eq 1 || vTS07 eq 1 || vTA15N eq 1 || vTA15B eq 1 || vTA16 eq 1 then par_iter = par_array[i,*] $
          else par_iter = ''
          
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
              
    ;      geopack_trace,in_pos_array2[i,0],in_pos_array2[i,1],in_pos_array2[i,2],dir,par_iter,out_foot_array[i,0],out_foot_array[i,1],out_foot_array[i,2],R0=R02,RLIM=RLIM2,fline = trgsm_out,tilt=tilt,IGRF=IGRF,T89=T89,T96=T96,T01=T01,TS04=TS04,/refine,/ionosphere,_extra=_extra
          
          if geopack_2008 then begin
              ; Use Geopack 2008

              ; cotrans transformed the coordinates to GSE, use Geopack to transform to GSW (required for geopack_2008)
              geopack_conv_coord_08, in_pos_array2[i, 0], in_pos_array2[i, 1], in_pos_array2[i, 2], x_out_gsw, y_out_gsw, z_out_gsw, /from_gse, /to_gsw              
              if keyword_set(standard_mapping) then begin
                  if ta16supported eq 1 then begin              
                      geopack_trace_08, x_out_gsw, y_out_gsw, z_out_gsw, dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16, _extra = _extra 
                  endif else begin
                      geopack_trace_08, x_out_gsw, y_out_gsw, z_out_gsw, dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, _extra = _extra
                  endelse
              endif else begin
                  if ta16supported eq 1 then begin
                      geopack_trace_08, x_out_gsw, y_out_gsw, z_out_gsw, dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16, /refine, /ionosphere, _extra = _extra
                  endif else begin
                      geopack_trace_08, x_out_gsw, y_out_gsw, z_out_gsw, dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, /refine, /ionosphere, _extra = _extra
                  endelse              
              endelse              

              ; GSW->GSE for the trace
              geopack_conv_coord_08, trgsm_out[*,0], trgsm_out[*,1], trgsm_out[*,2], x_trout_gse, y_trout_gse, z_trout_gse, /from_gsw, /to_gse
              trgsm_out = [[x_trout_gse], [y_trout_gse], [z_trout_gse]]
              
              ; GSW->GSE for the foot point
              geopack_conv_coord_08, out_foot_x, out_foot_y, out_foot_z, x_footout_gse, y_footout_gse, z_footout_gse, /from_gsw, /to_gse
              out_foot_x=x_footout_gse
              out_foot_y=y_footout_gse
              out_foot_z=z_footout_gse  
          endif else begin
              ; Use Geopack 2005
              if keyword_set(standard_mapping) then begin
                  if ta16supported eq 1 then begin
                      geopack_trace, in_pos_array2[i, 0], in_pos_array2[i, 1], in_pos_array2[i, 2], dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16, _extra = _extra 
                  endif else begin
                      geopack_trace, in_pos_array2[i, 0], in_pos_array2[i, 1], in_pos_array2[i, 2], dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, _extra = _extra 
                  endelse             
              endif else begin
                if ta16supported eq 1 then begin
                    geopack_trace, in_pos_array2[i, 0], in_pos_array2[i, 1], in_pos_array2[i, 2], dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16, /refine, /ionosphere, _extra = _extra
                endif else begin
                    geopack_trace, in_pos_array2[i, 0], in_pos_array2[i, 1], in_pos_array2[i, 2], dir, par_iter, out_foot_x, out_foot_y, out_foot_z, R0 = R02, RLIM = RLIM2, fline = trgsm_out, tilt = tilt, IGRF = IGRF, T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, /refine, /ionosphere, _extra = _extra
                endelse
                 
              endelse
          endelse
          
          out_foot_array[i, 0] = out_foot_x
          out_foot_array[i, 1] = out_foot_y
          out_foot_array[i, 2] = out_foot_z
          
          ;store pointer to field trace
          tr_ptr_arr[i] = ptr_new(trgsm_out)
    
          tr_size = size(trgsm_out,/dimensions)
    
          ;store the maximum trace size so it
          ;can be used to calculate output storage
          if tr_size[0] gt max_trace_size then max_trace_size = tr_size[0]
    
       endif else begin ;calculate over an interval if traces are not requested
          if ~exact_tilt_times then begin
            ;find indices of points in the interval for this iteration
            idx1 = where(tarray2 ge tstart + i*period2)
            idx2 = where(tarray2 le tstart + (i+1)*period2)
       
            idx = ssl_set_intersection(idx1, idx2)
          endif else begin
            idx = i
          endelse
          
          if idx[0] ne -1L then begin 
          
             id = idx[0]
    
             ;recalculate geomagnetic dipole
             if geopack_2008 then begin
                ; Geopack 2008
                geopack_recalc_08, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
             endif else begin
                ; Geopack 2005
                geopack_recalc, ts[id].year,ts[id].doy, ts[id].hour, ts[id].min, ts[id].sec, tilt = tilt
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
    
             rgsm_x = in_pos_array2[idx, 0]
             rgsm_y = in_pos_array2[idx, 1]
             rgsm_z = in_pos_array2[idx, 2]
    
             ;calculate which par values should be used on this iteration
             if vT89 eq 1 then par_iter = par_array[id] $
             else if vT96 eq 1 || vT01 eq 1 || vTS04 eq 1 || vTS07 eq 1 then par_iter = par_array[id,*] else par_iter = ''
             
             if geopack_2008 then begin
                 ; Geopack 2008
                 ; cotrans transformed the coordinates to GSE, use Geopack to transform to GSW (required for geopack_2008)
                 geopack_conv_coord_08, rgsm_x, rgsm_y, rgsm_z, x_out_gsw, y_out_gsw, z_out_gsw, /from_gse, /to_gsw
                 if keyword_set(standard_mapping) then begin
                    if ta16supported eq 1 then begin
                      geopack_trace_08,x_out_gsw,y_out_gsw,z_out_gsw,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16,_extra=_extra 
                    endif else begin
                      geopack_trace_08,x_out_gsw,y_out_gsw,z_out_gsw,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B,_extra=_extra                      
                    endelse
                 endif else begin
                    if ta16supported eq 1 then begin                 
                      geopack_trace_08,x_out_gsw,y_out_gsw,z_out_gsw,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16, /refine,/ionosphere,_extra=_extra
                    endif else begin
                      geopack_trace_08,x_out_gsw,y_out_gsw,z_out_gsw,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, /refine,/ionosphere,_extra=_extra
                    endelse                  
                 endelse
                 
                 ; GSW->GSE for the foot point
                 geopack_conv_coord_08, foot_x, foot_y, foot_z, x_foot_gse, y_foot_gse, z_foot_gse, /from_gsw, /to_gse
                 foot_x=x_foot_gse
                 foot_y=y_foot_gse
                 foot_z=z_foot_gse
             endif else begin
                 ; Geopack 2005
                 if keyword_set(standard_mapping) then begin
                    if ta16supported eq 1 then begin
                      geopack_trace,rgsm_x,rgsm_y,rgsm_z,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16,_extra=_extra 
                    endif else begin
                      geopack_trace,rgsm_x,rgsm_y,rgsm_z,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B,_extra=_extra                      
                    endelse
                 endif else begin
                    if ta16supported eq 1 then begin                 
                      geopack_trace,rgsm_x,rgsm_y,rgsm_z,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, TA16 = vTA16, /refine,/ionosphere,_extra=_extra
                    endif else begin
                      geopack_trace,rgsm_x,rgsm_y,rgsm_z,dir,par_iter,foot_x,foot_y,foot_z,R0=R02,RLIM=RLIM2,tilt=tilt,IGRF=IGRF,T89 = vT89, T96 = vT96, T01 = vT01, TS04 = vTS04, TS07 = vTS07, TA15N = vTA15N, TA15B = vTA15B, /refine,/ionosphere,_extra=_extra
                    endelse                  
                 endelse
             endelse
    
             ;output foot
             out_foot_array[idx, 0] = foot_x
             out_foot_array[idx, 1] = foot_y
             out_foot_array[idx, 2] = foot_z
          endif
       endelse
    
       i++
    endwhile
    
    ;copy pointer version of trace into output array
    if arg_present(out_trace_array) then begin
       out_trace_array = make_array([t_size[0],max_trace_size,3],/DOUBLE, VALUE = !VALUES.D_NAN)
    
       for i = 0L,t_size[0]-1L do begin 
    
          tr_temp = *tr_ptr_arr[i]
    
          ptr_free,tr_ptr_arr[i]
    
          s_temp = size(tr_temp,/dimensions)
          
          ;all points within each trace have the same time  
          t_temp = replicate(tarray2[i],s_temp[0])

          ;convert trace into the output coordinate system
          if geopack_2008 then begin
            ; if geopack 2008 is being used, need to convert from GSE to GSM
            cotrans, tr_temp, tr_temp, t_temp, /gse2gsm
          endif
          
          if out_coord2 eq 'gei' then begin
             cotrans,tr_temp,tr_temp,t_temp,/gsm2gse
             cotrans,tr_temp,tr_temp,t_temp,/gse2gei
          endif else if out_coord2 eq 'geo' then begin
             cotrans,tr_temp,tr_temp,t_temp,/gsm2gse
             cotrans,tr_temp,tr_temp,t_temp,/gse2gei
             cotrans,tr_temp,tr_temp,t_temp,/gei2geo
          endif else if out_coord2 eq 'gse' then $
             cotrans,tr_temp,tr_temp,t_temp,/gsm2gse $
          else if out_coord2 eq 'sm' then $
             cotrans,tr_temp,tr_temp,t_temp,/gsm2sm
    
          out_trace_array[i,0:(s_temp[0]-1L),*] = tr_temp
       endfor
    
       ;convert from re to km
       if keyword_set(km) then out_trace_array *= km_in_re
    endif
    
    ; if geopack 2008 is being used, need to convert back to GSM
    if geopack_2008 then begin
        ; convert from GSE to GSM
        cotrans, out_foot_array, out_foot_array, tarray2, /gse2gsm
    endif
    
    ;convert footprint into the output coordinate system
    if out_coord2 eq 'gei' then begin
       cotrans,out_foot_array,out_foot_array,tarray2,/gsm2gse
       cotrans,out_foot_array,out_foot_array,tarray2,/gse2gei
    endif else if out_coord2 eq 'geo' then begin
       cotrans,out_foot_array,out_foot_array,tarray2,/gsm2gse
       cotrans,out_foot_array,out_foot_array,tarray2,/gse2gei
       cotrans,out_foot_array,out_foot_array,tarray2,/gei2geo
    endif else if out_coord2 eq 'gse' then $
       cotrans,out_foot_array,out_foot_array,tarray2,/gsm2gse $
    else if out_coord2 eq 'sm' then $
       cotrans,out_foot_array,out_foot_array,tarray2,/gsm2sm
    
    ;convert from re to km
    if keyword_set(km) then out_foot_array *= km_in_re
    
    ;signal success
    error = 1

end
