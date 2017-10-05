;+
;Procedure: tt89
;
;Purpose:  tplot wrapper for the functional interface to the IDL Geopack
;          implementation of the Tsyganenko 89 and IGRF model.
;
;Input:
;          pos_gsm_tvar: the tplot variable storing the position in
;               gsm coordinates(can use standard globbing)
;
;Keywords: 
;          kp(optional): the requested value of the kp parameter(default: 2) 
;               can also be a tplot variable name if it is a tplot variable name 
;               the kp values stored in the variable will be interpolated to match 
;               the time grid of the position input values
;
;          period(optional): the amount of time between recalculations of
;               geodipole tilt in seconds(default: 600)  increase this
;               value to decrease run time
;             
;          get_nperiod(optional): Return the number of periods used in the time interval
;
;          newname(optional):the name of the output variable. 
;               (default: pos_gsm_tvar+'_bt89') This option is ignored if
;               globbing is used.
;
;          error(optional): named variable in which to return the
;               error state of this procedure call. 1 = success, 0 = failure
;        
;          igrf_only(optional): Set this keyword to turn off the t89 component of
;               the model and return only the igrf component
;        
;          get_tilt(optional):  Set this value to a tplot variable name in which the geodipole tilt for each period will be returned
;               One sample will be returned for each period with time at the center of the period.
;          
;          set_tilt(optional): Set this to a tplot variable name or an array of values containing the dipole tilt that should be used.
;               If a tplot input is used it will be interpolated to match the time inputs from the position
;               var. Non-tplot array values must match the number of times in the tplot input for pos_gsm_tvar
;               Notes:
;                    1) set_tilt will cause add_tilt to be ignored
;                    2) Due to this routine adding IGRF to the returned field, you cannot use set_tilt = 0 and give input 
;                         position values in SM coordinates; input position values are required to be in GSM coordinates due to the
;                         IGRF calculation
;
;          add_tilt(optional): Set this to a tplot variable name or an array of values containing the values to be added to the dipole tilt
;               that should be used for each period. If a tplot input is used it will be interpolated to match the time inputs from the position
;               var. Non-tplot array values must match the number of times in the tplot input for pos_gsm_tvar
;
;          geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work.
;              
; Output: Stores the result of the field model calculations in tplot variables
;          
; Notes: 
;        1. Converts from normal gsm to rgsm by dividing vectors by earth's
;            radius(6371.2 km) ie inputs should be in km
;            6371.2 = the value used in the GEOPACK FORTRAN code for Re
;        2. Input must be in GSM coordinates
;        3. Haje Korth's IDL/Geopack DLM must be installed for this
;        procedure to work
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-03-20 08:27:55 -0700 (Fri, 20 Mar 2015) $
; $LastChangedRevision: 17153 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/t89/tt89.pro $
;-

pro tt89, pos_gsm_tvar, kp=kp, period=period, get_nperiod=get_nperiod, newname=newname, $
    error=error, igrf_only=igrf_only, get_tilt=get_tilt, set_tilt=set_tilt,add_tilt=add_tilt,$
    geopack_2008=geopack_2008

  error = 0

  if ~is_string(pos_gsm_tvar) then begin
    message, /continue, 'pos_gsm_tvar must be set'
    return
  endif

  var_names = tnames(pos_gsm_tvar)

  if(var_names[0] eq '') then begin
    message, /continue, 'No valid tplot_variables match pos_gsm_tvar'
    return
  endif

  if n_elements(kp) gt 0 then begin
     ;if kp is a string, assume kp is stored in a tplot variable
      if size(kp,/type) eq 7 then begin
          if tnames(kp) eq '' then begin
              message,/continue,'kp is of type string but no tplot variable of that name exists'
              return
          endif
          
          ;for the sake of simplicity
          if n_elements(var_names) gt 1 then begin
              message,/continue,'cannot use globbing AND arrayed kp values'
              return
          endif
          
          ;make sure there are an appropriate number of kp values in the array
          tinterpol_mxn,kp,var_names[0],newname='kp_int_temp',error=e

          if e ne 0 then begin
              get_data,'kp_int_temp',data=d_kp
              kp_dat = d_kp.y
          endif else begin
              message,/continue,'error interpolating kp onto position data'
              return
          endelse
     
      endif else kp_dat = kp
  endif

  for i = 0, n_elements(var_names)-1L do begin

    var_name = var_names[i]

    get_data, var_name, data = d, dlimits = dl, limits = l

    ; check the variable's coordinate system
    if tsy_valid_coords(dl, geopack_2008 = geopack_2008) eq -1 then return
    
    if n_elements(add_tilt) gt 0 then begin
      add_tilt_dat = tsy_valid_param(add_tilt, var_name)
      if(size(add_tilt, /n_dim) eq 0 && add_tilt_dat[0] eq -1L) then return
    endif
 
    if n_elements(set_tilt) gt 0 then begin
      set_tilt_dat = tsy_valid_param(set_tilt, var_name)
      if(size(set_tilt, /n_dim) eq 0 && set_tilt_dat[0] eq -1L) then return
    endif
    
    ;do the calculation, division (by 6371.2) converts position into earth radii units
    ;various types for various tilt control options
    if n_elements(set_tilt) gt 0 then begin
      mag_array = t89(d.x, d.y/6371.2, kp=kp_dat, period=period, igrf_only=keyword_set(igrf_only), $
        get_nperiod=get_nperiod, get_period_times=period_times_dat, get_tilt=tilt_dat, set_tilt=set_tilt_dat, geopack_2008=geopack_2008)
    endif else if n_elements(add_tilt) gt 0 then begin
      mag_array = t89(d.x, d.y/6371.2, kp=kp_dat, period=period, igrf_only=keyword_set(igrf_only), $
        get_nperiod=get_nperiod, get_period_times=period_times_dat, get_tilt=tilt_dat, add_tilt=add_tilt_dat, geopack_2008=geopack_2008)
    endif else begin
      mag_array = t89(d.x, d.y/6371.2, kp=kp_dat, period=period, igrf_only=keyword_set(igrf_only), $
        get_nperiod=get_nperiod, get_period_times=period_times_dat, get_tilt=tilt_dat, geopack_2008=geopack_2008)
    endelse

    if size(mag_array, /n_dim) eq 0 && mag_array[0] eq -1L then begin
      message, /continue, 'Tsyganenko model query failed, returning'
      return
    endif

    if is_string(get_tilt) then begin
      store_data,get_tilt,data={x:period_times_dat,y:tilt_dat}
    endif

    ;sometimes v element is present, sometimes not 
    ;if it is around it is stored in output so information is not lost 
    str_element, d, 'v', success = s

    if s eq 1 then $
      d_out = {x:d.x, y:mag_array, v:d.v} $
    else $
      d_out = {x:d.x, y:mag_array}

    if keyword_set(newname) && n_elements(var_names) eq 1 then $
      store_data, newname, data = d_out, dlimits = dl, limits = l $
    else $
      store_data, var_names[i]+'_bt89', data = d_out, dlimits = dl, limits = l

  endfor

  ;signal success
  error = 1 

  return

end
