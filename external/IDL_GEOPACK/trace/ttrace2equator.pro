;+
;Procedure : ttrace2equator
;
;Purpose: tplot wrapper for field line footprint and tracing routines
;         This program will always use the refined foot point mappings 
;         (a modification made by Vassilis Angelopoulos to provide more accurate
;         mappings of foot points) as there is no Tsyganenko code to 
;         perform equatorial traces.Model parameters can be provided
;         in the par array or individually, using the
;         parameter's name.  If a model parameter is provided
;         by name, it will overwrite a part of any par value
;         provided.  If a named parameter is provided, but is
;         unneeded by the model, it will be ignored.
;
;Input:
;         in_pos_tvar: name of the tplot variable storing the
;             position information for tracing, input values should be in
;             'gse','gei','gsm',or 'sm'
;
;Keywords:
;         newname(optional): name of the tplot variable in which output
;             footprints should be stored(default: in_pos_tvar+'_foot')
;
;         trace_var_name(optional): name of the tplot variable in
;             which to store the traces of field lines leading to footprints. 
;             Because traces are of variable length, the returned array
;             will be of dimensions NxDx3
;             D is the maximum number of vectors in any of the traces.
;             Shorter traces will have NaNs filling the space at the end
;             of the array  
;
;         in_coord(optional): set this keyword to the coordinate
;             system of the input, defaults to 'gsm', must match tplot
;             meta data
;
;         out_coord(optional): set this keyword to a string indicating
;             the coordinate system output data should be in, defaults to 'gsm'
;             (can be 'geo','gei','gse','gsm',or 'sm' default: the same as
;              the input)
;
;         internal_model(optional): set this keyword to a string
;             indicating the internal model that should be used in tracing
;             (can be 'dip' or 'igrf' default:igrf)
;
;         external_model(optional): set this keyword to a string
;             indicating the external model that should be used in tracing
;             (can be 'none','t89','t96','t01', or 't04s' default: none)
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
;             element array. At the moment if an external model is set and
;             this is not set an error will be thrown. This value can also
;             be tplot variable name. If it is a tplot variable name it
;             will be interpolated to match the positions in pos_tvar
; 
;           
;         period(optional): the amount of time between recalculations of
;             geodipole tilt and input of new model parameters in
;             seconds (default: 60) increase this value to decrease
;             run time 
;             if field line traces are requested this parameter is
;             ignored and new model parameters are input on each
;             iteration
;
;         error(optional): named variable in which to return the error
;             state of the procedure.  1 for success, 0 for failure
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
;         kp (optional): Kp index value for T89 model should either be a
;              string naming a tplot variable or an array or a single
;              value. If a tplot input is used it will be interpolated to
;              match the time inputs from the position var. Non-tplot array values
;              must match the number of times in the tplot input for pos_gsm_tvar
;            
;         pdyn(optional): Solar wind pressure(nanoPascals) should either be a
;              string naming a tplot variable or an array or a single
;              value. If a tplot input is used it will be interpolated to
;              match the time inputs from the position var. Non-tplot array values
;              must match the number of times in the tplot input for pos_gsm_tvar
;
;         dsti(optional): DST index(nanoTeslas)  should either be a
;              string naming a tplot variable or an array or a single
;              value.  If a tplot input is used it will be interpolated to
;              match the time inputs from the position var. Non-tplot array values
;              must match the number of times in the tplot input for pos_gsm_tvar
;
;         yimf(optional): y component of the interplanetary magnetic field
;             should either be a string naming a tplot variable or an
;             array or a single value.  If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         zimf(optional): z component of the interplanetary magnetic field
;             should either be a string naming a tplot variable or an
;             array or a single value.  If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         g1(optional):  index describes solar wind conditions in the
;             previous hour, should either be a string naming a tplot variable or an
;             array or a single value.   If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         g2(optional): index describes solar wind conditions in the
;             previous hour should either be a string naming a tplot variable or an
;             array or a single value.   If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;        
;         w1(optional):  time integral from the beginning of a storm
;             can be an array or a tplot variable(see paper reference
;             below for definitions of w1-w6) or a single value. 
;             If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         w2(optional): time integral from the beginning of a storm
;             can be an array or a tplot variable or a single value
;             If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         w3(optional):  time integral from the beginning of a storm
;             can be an array or a tplot variable or a single value
;             If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         w4(optional): time integral from the beginning of a storm
;             can be an array or a tplot variable or a single value
;             If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         w5(optional):  time integral from the beginning of a storm
;             can be an array or a tplot variable or a single value
;             If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         w6(optional): time integral from the beginning of a storm
;             can be an array or a tplot variable or a single value
;             If a tplot input is used it will
;             be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the
;             tplot input for pos_gsm_tvar
;
;         get_tilt(optional):  Set this value to a tplot variable name in which the geodipole tilt for each period will be returned
;             One sample will be returned for each period with time at the center of the period.
;          
;         set_tilt(optional): Set this to a tplot variable name or an array of values containing the dipole tilt that should be used.
;             If a tplot input is used it will be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the tplot input for pos_gsm_tvar
;
;         add_tilt(optional): Set this to a tplot variable name or an array of values containing the values to be added to the dipole tilt
;             that should be used for each period. If a tplot input is used it will be interpolated to match the time inputs from the position
;             var. Non-tplot array values must match the number of times in the tplot input for pos_gsm_tvar
;
;         exact_tilt_times (optional):  Set this keyword to avoid grouping similar times (default 10 minutes) and instead
;              recalculate the dipole tilt at each input time
;
;         get_nperiod(optional): Return the number of periods used in the time interval
;     
;         geopack_2008 (optional): Set this keyword to use the latest version (2008) of the Geopack
;              library. Version 9.2 of the IDL Geopack DLM is required for this keyword to work.
;              
;         ts07_param_dir (optional): Specify location of TS07 parameter directory
;         
;         ts07_param_file (optional): Specify TS07 parameter file to load
;         
;         skip_ts07_load (optional):  Do not reset the TS07 parameter directory or reload the parameter file
;
;Example: ttrace2equator,'tha_state_pos',newname='tha_out_foot'
;
;See: crib_ttrace for more examples
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
; $LastChangedDate: 2022-07-15 01:33:34 -0700 (Fri, 15 Jul 2022) $
; $LastChangedRevision: 30935 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/trace/ttrace2equator.pro $
;-

pro ttrace2equator,in_pos_tvar,newname = newname, trace_var_name=trace_tvar, in_coord=in_coord, $
    out_coord=out_coord, internal_model=internal_model, external_model=external_model, south=south, $
    km=km, par=par, period=period, error=error, r0=r0, rlim=rlim, noboundary=noboundary, storm=storm,$
    kp=kp, pdyn=pdyn, dsti=dsti, yimf=yimf, zimf=zimf, g1=g1, g2=g2, w1=w1, w2=w2, w3=w3, w4=w4, w5=w5, w6=w6,$
    get_tilt=get_tilt, set_tilt=set_tilt, add_tilt=add_tilt, get_nperiod=get_nperiod, exact_tilt_times=exact_tilt_times, $
    ts07_param_dir=ts07_param_dir, ts07_param_file=ts07_param_file, $
    xind=xind, skip_ts07_load=skip_ts07_load, _extra=_extra

    error = 0
    
    ;constant arrays used for input validation
    valid_externals = ['none', 't89', 't96', 't01', 't04s','ts07', 'ta15b', 'ta15n', 'ta16']

    if keyword_set(external_model) then begin
      external_model2 = strlowcase(external_model)
      if(strfilter(valid_externals, external_model2) eq '') then begin
        message, /continue, 'external_model not a valid external model name'
        return
      endif
    endif else external_model2 = 'none'
   
    if not keyword_set(in_pos_tvar) or tnames(in_pos_tvar) eq '' then begin
       message,/continue,'in_pos_tvar must be set'
       return
    endif
    
    ;prevent inadvertent output mutation
    if n_elements(par) gt 0  then begin
      par_in = par
    endif
    
    get_data,in_pos_tvar,data=d,dlimits=dl
    
    if not keyword_set(newname) then newname = in_pos_tvar + '_foot'
    
    if not keyword_set(in_coord) then in_coord='gsm'
    
    if n_elements(par_in) gt 0 && size(par_in,/type) eq 7 then begin
       if tnames(par_in) eq '' then message,'par variable not valid tplot variable'
       tinterpol_mxn,par_in,in_pos_tvar,newname='par_out'
       get_data,'par_out',data=dat
       par_in = dat.y
    endif
  
    if n_elements(kp) gt 0 then begin
      if n_elements(par) gt 0 then begin
        message,/continue,'Both kp and par values supplied, using kp.'
      endif

      kp_dat=tsy_valid_param(kp,in_pos_tvar,/nearest_neighbor)
      if(size(kp_dat, /n_dim) eq 0 && kp_dat[0] eq -1L) then return

      par_in = kp_dat
    endif
  
    if n_elements(pdyn) gt 0 then begin
       pdyn_dat = tsy_valid_param(pdyn, in_pos_tvar)
       if(size(pdyn_dat, /n_dim) eq 0 && pdyn_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(pdyn_dat),10)
       endif
    
       par_in[*,0] = pdyn_dat
    endif
    
    if n_elements(dsti) gt 0 then begin
       dsti_dat = tsy_valid_param(dsti, in_pos_tvar)
       if(size(dsti_dat, /n_dim) eq 0 && dsti_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(dsti_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,1] = dsti_dat
    endif
 
    ;  YIMF goes to a different parmod element for TA15N and TA15B since Dst param not used for these models
   
    if n_elements(yimf) gt 0 then begin
       yimf_dat = tsy_valid_param(yimf, in_pos_tvar)
       if(size(yimf_dat, /n_dim) eq 0 && yimf_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(yimf_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
       
       if (external_model2 eq 'ta15n') || (external_model2 eq 'ta15b') then begin
          par_in[*,1] = yimf_dat
       endif else if external_model2 eq 'ta16' then begin
          par_in[*,3] = yimf_dat
       endif else begin
          par_in[*,2] = yimf_dat
       endelse
       
    endif

    ; ZIMF goes to a different parmod element for TA15N and TA15B since Dst param not used for these models

    
    if n_elements(zimf) gt 0 then begin
       zimf_dat = tsy_valid_param(zimf, in_pos_tvar)
       if(size(zimf_dat, /n_dim) eq 0 && zimf_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(zimf_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
       if (external_model2 eq 'ta15n') || (external_model2 eq 'ta15b') then begin
         par_in[*,2] = zimf_dat
       endif else begin
         par_in[*,3] = zimf_dat
       endelse
   
    endif 

    ;
    ;   XIND is the N-index for TA15N, or the B-index for TA15B
    ;
    if n_elements(xind) gt 0 then begin
      xind_dat = tsy_valid_param(xind, in_pos_tvar)
      if(size(xind_dat, /n_dim) eq 0 && xind_dat[0] eq -1L) then return

      if n_elements(par_in) eq 0 then begin
        par_in = dblarr(n_elements(xind_dat),10)
        message,/continue,'Possible error, not all parameters for model provided.'
      endif

      if external_model2 eq 'ta16' then begin
        par_in[*,3] = xind_dat
      endif else begin
        par_in[*,4] = xind_dat
      endelse
    endif
    
    if n_elements(g1) gt 0 then begin
       g1_dat = tsy_valid_param(g1, in_pos_tvar)
       if(size(g1_dat, /n_dim) eq 0 && g1_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(g1_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,4] = g1_dat
    endif
    
    if n_elements(g2) gt 0 then begin
       g2_dat = tsy_valid_param(g2, in_pos_tvar)
       if(size(g2_dat, /n_dim) eq 0 && g2_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(g2_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,5] = g2_dat
    endif
    
    if n_elements(w1) gt 0 then begin
       w1_dat = tsy_valid_param(w1, in_pos_tvar)
       if(size(w1_dat, /n_dim) eq 0 && w1_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(w1_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       if n_elements(g1) gt 0 then begin
          message,'g1 and w1 set'
       endif
    
       par_in[*,4] = w1_dat
    endif
    
    if n_elements(w2) gt 0 then begin
       w2_dat = tsy_valid_param(w2, in_pos_tvar)
       if(size(w2_dat, /n_dim) eq 0 && w2_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(w2_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       if n_elements(g2) gt 0 then begin
          message,'g2 and w2 set'
       endif
    
       par_in[*,5] = w2_dat
    endif
    
    if n_elements(w3) gt 0 then begin
       w3_dat = tsy_valid_param(w3, in_pos_tvar)
       if(size(w3_dat, /n_dim) eq 0 && w3_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(w3_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,6] = w3_dat
    endif
    
    if n_elements(w4) gt 0 then begin
       w4_dat = tsy_valid_param(w4, in_pos_tvar)
       if(size(w4_dat, /n_dim) eq 0 && w4_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(w4_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,7] = w4_dat
    endif
    
    if n_elements(w5) gt 0 then begin
       w5_dat = tsy_valid_param(w5, in_pos_tvar)
       if(size(w5_dat, /n_dim) eq 0 && w5_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(w5_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,8] = w5_dat
    endif
    
    if n_elements(w6) gt 0 then begin
       w6_dat = tsy_valid_param(w6, in_pos_tvar)
       if(size(w6_dat, /n_dim) eq 0 && w6_dat[0] eq -1L) then return
    
       if n_elements(par_in) eq 0 then begin
          par_in = dblarr(n_elements(w6_dat),10)
          message,/continue,'Possible error, not all parameters for model provided.'
       endif
    
       par_in[*,9] = w6_dat
    endif

    if n_elements(xind) gt 0 then begin
      xind_dat = tsy_valid_param(xind, in_pos_tvar)
      if(size(xind_dat, /n_dim) eq 0 && xind_dat[0] eq -1L) then return

      if n_elements(par_in) eq 0 then begin
        par_in = dblarr(n_elements(xind_dat),10)
        message,/continue,'Possible error, not all parameters for model provided.'
      endif

      par_in[*,3] = xind_dat
    endif


    
    if keyword_set(dl) then begin
        str_element,dl,'data_att',success=s
    
        if s eq 1 then begin
            str_element,dl.data_att,'coord_sys',success=s
    
            if s eq 1 then begin
                if(strlowcase(in_coord) ne strlowcase(dl.data_att.coord_sys)) then begin
                    message,/continue,'input coord_sys does not match tplot meta data'
                    return
                endif    
           endif
       endif   
    endif
    
    if not keyword_set(out_coord)  then out_coord = 'gsm'
    
    if n_elements(add_tilt) gt 0 then begin
      add_tilt_dat = tsy_valid_param(add_tilt, in_pos_tvar)
      if(size(add_tilt, /n_dim) eq 0 && add_tilt_dat[0] eq -1L) then return
    endif
     
    if n_elements(set_tilt) gt 0 then begin
      set_tilt_dat = tsy_valid_param(set_tilt, in_pos_tvar)
      if(size(set_tilt, /n_dim) eq 0 && set_tilt_dat[0] eq -1L) then return
    endif
    
    if n_elements(set_tilt) gt 0 then begin
      if keyword_set(trace_tvar) then  begin
        trace2equator,d.x,d.y,f,out_trace_array = tr,in_coord=in_coord,out_coord=out_coord,$
            internal_model=internal_model,external_model=external_model,south=south,km=km,$
            par=par_in,period=period,error=e,r0=r0,rlim=rlim,get_nperiod=get_nperiod,$
            get_tilt=tilt_dat,set_tilt=set_tilt_dat,get_period_times=period_times_dat,geopack_2008=geopack_2008,$
            exact_tilt_times=exact_tilt_times,ts07_param_dir=ts07_param_dir,ts07_param_file=ts07_param_file,skip_ts07_load=skip_ts07_load,_extra=_extra 
      endif else begin
        trace2equator,d.x,d.y,f,in_coord=in_coord,out_coord=out_coord,internal_model=internal_model,$
            external_model=external_model,south=south,km=km,par=par_in,period=period,error=e,r0=r0,$
            rlim=rlim,get_nperiod=get_nperiod,get_tilt=tilt_dat,set_tilt=set_tilt_dat,$
            get_period_times=period_times_dat,geopack_2008=geopack_2008,exact_tilt_times=exact_tilt_times,$
            ts07_param_dir=ts07_param_dir,ts07_param_file=ts07_param_file, skip_ts07_load=skip_ts07_load,_extra=_extra
      endelse
      
    endif else if n_elements(add_tilt) gt 0 then begin
      if keyword_set(trace_tvar) then begin
        trace2equator,d.x,d.y,f,out_trace_array = tr,in_coord=in_coord,out_coord=out_coord,$
            internal_model=internal_model,external_model=external_model,south=south,km=km,$
            par=par_in,period=period,error=e,r0=r0,rlim=rlim,get_nperiod=get_nperiod,$
            get_tilt=tilt_dat,add_tilt=add_tilt_dat,get_period_times=period_times_dat,geopack_2008=geopack_2008,$
            exact_tilt_times=exact_tilt_times,ts07_param_dir=ts07_param_dir,ts07_param_file=ts07_param_file,skip_ts07_load=skip_ts07_load,_extra=_extra 
      endif else begin
        trace2equator,d.x,d.y,f,in_coord=in_coord,out_coord=out_coord,internal_model=internal_model,$
            external_model=external_model,south=south,km=km,par=par_in,period=period,error=e,r0=r0,$
            rlim=rlim,get_nperiod=get_nperiod,get_tilt=tilt_dat,add_tilt=add_tilt_dat,$
            get_period_times=period_times_dat,geopack_2008=geopack_2008,exact_tilt_times=exact_tilt_times,$
            ts07_param_dir=ts07_param_dir,ts07_param_file=ts07_param_file,skip_ts07_load=skip_ts07_load,_extra=_extra
      endelse
    endif else begin
      if keyword_set(trace_tvar) then begin
        trace2equator,d.x,d.y,f,out_trace_array = tr,in_coord=in_coord,out_coord=out_coord,$
            internal_model=internal_model,external_model=external_model,south=south,km=km,$
            par=par_in,period=period,error=e,r0=r0,rlim=rlim,get_nperiod=get_nperiod,$
            get_tilt=tilt_dat,get_period_times=period_times_dat,geopack_2008=geopack_2008,$
            exact_tilt_times=exact_tilt_times,ts07_param_dir=ts07_param_dir,ts07_param_file=ts07_param_file,skip_ts07_load=skip_ts07_load,_extra=_extra 
      endif else begin
        trace2equator,d.x,d.y,f,in_coord=in_coord,out_coord=out_coord,internal_model=internal_model,$
            external_model=external_model,south=south,km=km,par=par_in,period=period,error=e,r0=r0,$
            rlim=rlim,get_nperiod=get_nperiod,get_tilt=tilt_dat,get_period_times=period_times_dat,$
            geopack_2008=geopack_2008,exact_tilt_times=exact_tilt_times, $
            ts07_param_dir=ts07_param_dir,ts07_param_file=ts07_param_file,skip_ts07_load=skip_ts07_load,_extra=_extra
      endelse
    endelse 
    
    if e eq 0 then message,'trace2equator failed, returning'
    
    str_element,d,'v',success=s
    
    if s eq 0 then out = {x:d.x,y:f}  else out = {x:d.x,y:f,v:d.v}
    
    if not keyword_set(dl) then begin
       data_att = {coord_sys:out_coord}
       dl = {data_att:data_att}
    endif
    
    str_element,dl,'data_att',success=s
    
    if s eq 0 then begin
       data_att = {coord_sys:out_coord}
       str_element,dl,'data_att',data_att,/add_replace
    endif
    
    str_element,dl.data_att,'coord_sys',success=s
    
    if s eq 0 then begin
       data_att = dl.data_att
       str_element,data_att,'coord_sys',out_coord,/add_replace
       str_element,dl,'data_att',data_att,/add_replace
    endif
    
    dl.data_att.coord_sys = out_coord
    
    store_data,newname,data=out,dlimits=dl
    
    if keyword_set(trace_tvar) then begin
       tr_out = {x:d.x,y:tr}
    
       ;dl element will already be set by previous store so no need to repeat checks
    
       store_data,trace_tvar,data=tr_out,dlimits=dl
    endif
    
    if is_string(get_tilt) then begin
      store_data,get_tilt,data={x:period_times_dat,y:tilt_dat}
    endif
    
    error = 1
end
