;+
; PROCEDURE:
;         flatten_spectra_multi
;
; PURPOSE:
;         Create quick plots of spectra at multiple times (i.e., energy vs. eflux, PA vs. eflux, etc)
;    
; INPUT:
;       num_spec: number of times to create spectra at
;       
; KEYWORDS:
;       [XY]LOG:   [XY] axis in log format
;       [XY]RANGE: 2 element vector that sets [XY] axis range
;       NOLEGEND:  Disable legend display
;       COLORS:    n element vector that sets the colors of the line in order that they are in tplot_vars.options.varnames
;                  n is number of tplot variables in tplot_vars.options.varnames
;             
;       PNG:         save png from the displayed windows (cannot be used with /POSTRSCRIPT keyword)
;       POSTRSCRIPT: create postscript files instead of displaying the plot
;       PREFIX:      filename prefix
;       FILENAME:    custorm filename, including folder. 
;                    By default the folder is your IDL working directory and the filename includes tplot names and selected time (or center time)      
;       
;       TIME_IN:     if the keyword is specified the time is determined from the variable, not from the cursor pick.
;       TRANGE:      Two-element time range over which data will be averaged. 
;       SAMPLES:     Number of nearest samples to time to average. Override trange.      
;       WINDOW:      Length in seconds over which data will be averaged. Override trange.
;       CENTER_TIME: Flag denoting that time should be midpoint for window instead of beginning.
;                    If TRANGE is specify, the the time center point is computed.
;       RANGETITLE:  If keyword is set, display range of the averagind time instead of the center time
;                    Does not affect deafult name of the png or postscript file 
;       TO_KEV:      Converts the x-axis to keV from eV (checks units in ysubtitle)
;       TO_FLUX: Converts the y-axis to units of flux, i.e., '1/(cm^2 s sr keV)', as with TO_KEV,
;                     this keyword uses the units string in the ztitle
;
; EXAMPLE:
;     To create line plots of FPI electron energy spectra for all MMS spacecraft:
;     
;       MMS> mms_load_fpi, datatype='des-moms', trange=['2015-12-15', '2015-12-16'], probes=[1, 2, 3, 4]
;       MMS> tplot, 'mms?_des_energyspectr_omni_fast'
;       MMS> flatten_spectra_multi, 3, /xlog, /ylog
;       
;       --> then click the tplot window at the 3 times you want to create the line plots at
;
; NOTES:
;     This is a fork of the code flatten_spectra
;     
;     currently only supports 1 panel per figure
;     
;     work in progress; suggestions, comments, complaints, etc: egrimes@igpp.ucla.edu
;     
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-09-13 17:00:06 -0700 (Fri, 13 Sep 2019) $
;$LastChangedRevision: 27758 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/flatten_spectra_multi.pro $
;-

pro mfs_warning, str
  compile_opt idl2, hidden
  ; print warning message 
  dprint, dlevel=0, '########################### WARNING #############################'  
  dprint, dlevel=0,  str
  dprint, dlevel=0, '#################################################################'
end

function mfs_get_unit_string, unit_array, disable_warning=disable_warning
  compile_opt idl2, hidden
  ; prepare string of units from the given array. If there is more that one unit in the array, print the warning 
  if ~undefined(unit_array) then begin
    if N_ELEMENTS(unit_array) gt 1 then begin
      if undefined(disable_warning) then mfs_warning, 'Units of the tplot variables are different!'
      return, STRJOIN(unit_array, ', ')             
    endif else RETURN, unit_array[0]
  endif else return, ''
end

pro mfs_get_unit_array, metadata, field, arr=arr
  compile_opt idl2, hidden
  ; extract unique units from metadata 
  str_element, metadata,field, SUCCESS=S, VALUE=V
  V = S ? V : '[]' ; Test if we sucsesfully return the value
  if undefined(arr) then begin
    append_array, arr, V      
  endif else begin
    if total(strcmp(arr, V)) lt 1 then append_array, arr, V       
  endelse
end



pro flatten_spectra_multi, num_spec, xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, nolegend=nolegend, colors=colors,$
   thick=thick, linestyle=linestyle, png=png, postscript=postscript, prefix=prefix, filename=filename, $   
   time=time_in, trange=trange_in, window_time=window_time, center_time=center_time, samples=samples, rangetitle=rangetitle, $
   charsize=charsize, replot=replot, to_kev=to_kev, legend_left=legend_left, bar=bar, to_flux=to_flux, yvalues=yvalues, xvalues=xvalues, $
   _extra=_extra
   
  @tplot_com.pro
  
  spd_graphics_config

  str_element, tplot_vars.options, 'varnames', varnames, success=s

  if ~s then begin
    dprint, dlevel=0, 'No tplot window found!'
    return
  endif
  
  if undefined(num_spec) then num_spec = 2

  ;
  ; Get the supporting information
  ;
  fname = '' ; filename for if we save png of postscript
  if UNDEFINED(prefix) THEN prefix = ''
  
  ;
  ; Time selection
  ;
  
  if keyword_set(replot) then begin
    get_data, 'flatten_spectra_time_multi', data=spec_time
    if ~is_struct(spec_time) then begin
      dprint, dlevel=0, 'Error, replot keyword specified, but no previous time found'
      return
    endif
    selected_times = spec_time.X
  endif
  
  window, 1
  
  yvalues = hash()
  xvalues = hash()
  
  ; position for the legend
  if keyword_set(legend_left) then leg_x = 0.04 else leg_x = 0.70
  leg_y = 0.04
  leg_dy = 0.04
  
  ; user defined plot options
  if ~KEYWORD_SET(colors) then begin
    colors = indgen(num_spec,start=0,increment=2)
  endif
  
  if ~undefined(thick) && n_elements(thick) ne num_spec && n_elements(thick) ne 1 then begin
    dprint, dlevel=0, 'Error, the number of elements in thick keyword should match the number of times'
    undefine, thick
  endif
  
  if ~undefined(linestyle) && n_elements(linestyle) ne num_spec && n_elements(linestyle) ne 1 then begin
    dprint, dlevel=0, 'Error, the number of elements in linestyle keyword should match the number of times'
    undefine, linestyle
  endif
  
  if n_elements(thick) eq 1 then thick = replicate(thick, num_spec)
  if n_elements(linestyle) eq 1 then linestyle = replicate(linestyle, num_spec)
  
  if keyword_set(time_in) then begin
    selected_times = time_double(time_in)
    colors = indgen(n_elements(selected_times),start=0,increment=2)
    store_data, 'flatten_spectra_time_multi', data={x: selected_times, y: 1}
  endif
  
  if undefined(selected_times) then begin
    for time_idx=0, num_spec-1 do begin
      ctime,t,npoints=1,prompt="Use cursor to select a time to plot the spectra", /silent 
          ;hours=hours,minutes=minutes,seconds=seconds,days=days  
      append_array, selected_times, t
      wait, 0.3
    endfor
    store_data, 'flatten_spectra_time_multi', data={x: selected_times, y: 1}
  endif 
  
  ;
  ; Plot or save to the file
  ;

  ; finalizing filename
  fname += time_string(selected_times[0], tformat='YYYYMMDD_hhmmss')
  fname = prefix + fname
  if ~UNDEFINED(filename) THEN fname = filename
  
  ; Device = postscript or window
  if KEYWORD_SET(postscript) then popen, fname, /landscape
  
  for time_idx=0, n_elements(selected_times)-1 do begin
    t = selected_times[time_idx]
    
    ; set the averaging time window
    if ~undefined(window_time) then begin
      if KEYWORD_SET(center_time) then begin
        trange = [t - window_time/2. , t + window_time/2.]
      endif else begin
        trange = [t , t + window_time]
      endelse    
    endif
    
    if undefined(charsize) then charsize = 2.0
      
    dprint, dlevel=1, 'time selected: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')

    vars_to_plot = tplot_vars.options.varnames
     
    
    ; loop to get supporting information
    for v_idx=0, n_elements(vars_to_plot)-1 do begin  
      get_data, vars_to_plot[v_idx], data=vardata, alimits=metadata
      m = spd_extract_tvar_metadata(vars_to_plot[v_idx])
  
      if ~is_struct(vardata) or ~is_struct(metadata) then begin
        dprint, dlevel=0, 'Could not plot: ' + vars_to_plot[v_idx]
        continue
      endif
  
      ; check that this variable is actually a spectra, to allow for line plots on the same figure
      str_element, metadata, 'spec', success=spec_exists
      if ~spec_exists || metadata.spec eq 0 then begin
        dprint, dlevel=1, 'Not including: ' + vars_to_plot[v_idx]
        continue
      endif
      
      ; determine units: get fields for metadata and add the the array if any 
      mfs_get_unit_array, metadata, 'ysubtitle', arr=xunits
      mfs_get_unit_array, metadata, 'ztitle', arr=yunits
      
      ; determine max and min  
      if N_ELEMENTS(xrange) ne 2 or N_ELEMENTS(yrange) ne 2 then begin 
        ;tmp = min(vardata.X - t, /ABSOLUTE, idx_to_plot) ; get the time index
        idx_to_plot = where(vardata.X eq find_nearest_neighbor(vardata.X, t), idx_count)
        if idx_count eq 0 then begin
          dprint, dlevel=0, 'Error, time not found: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff') + ' with variable ' + vars_to_plot[v_idx]
          continue
        endif
        
        if dimen2(vardata.v) eq 1 then data_x = vardata.v else data_x = vardata.v[idx_to_plot, *]
        data_y = vardata.Y[idx_to_plot, *]
        
        data_out = flatten_spectra_convert_units(vars_to_plot[v_idx], data_x, data_y, metadata, to_kev=to_kev, to_flux=to_flux)
        data_y = data_out['data_y']
        data_x = data_out['data_x']

        append_array,yr,reform(data_y)
        append_array,xr,reform(data_x)     
      endif       
      
      ; filename if we need to save file
      fname += vars_to_plot[v_idx] + '_'      
    endfor
    
    ; select [xy] range
    if N_ELEMENTS(xrange) ne 2 then xrange = KEYWORD_SET(xlog) ? [min(xr(where(xr>0))), max(xr(where(xr>0)))] : [min(xr), max(xr)]
    if N_ELEMENTS(yrange) ne 2 then yrange = KEYWORD_SET(ylog) ? [min(yr(where(yr>0))), max(yr(where(yr>0)))] : [min(yr), max(yr)]
    
    ; units string
    xunit_str = mfs_get_unit_string(xunits, disable_warning=to_kev)
    yunit_str = mfs_get_unit_string(yunits, disable_warning=to_flux)
     
    ; loop plot
    for v_idx=0, n_elements(vars_to_plot)-1 do begin
  
        get_data, vars_to_plot[v_idx], data=vardata, alimits=vardl
  
        if ~is_struct(vardata) or ~is_struct(vardl) then begin
          dprint, dlevel=0, 'Could not plot: ' + vars_to_plot[v_idx]
          continue
        endif
        
        varinfo = spd_extract_tvar_metadata(vars_to_plot[v_idx])
        
        ; check that this variable is actually a spectra, to allow for line plots on the same figure
        str_element, vardl, 'spec', success=spec_exists
        if ~spec_exists || vardl.spec eq 0 then begin
          dprint, dlevel=1, 'Not including: ' + vars_to_plot[v_idx]
          continue
        endif
        
        ; work with averaging      
        ;tmp = min(vardata.X - t, /ABSOLUTE, idx_to_plot) ; get the time index
        idx_to_plot = where(vardata.X eq find_nearest_neighbor(vardata.X, t), idx_count)
        if idx_count eq 0 then begin
          dprint, dlevel=0, 'Error, time not found: ' + time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff') + ' with variable ' + vars_to_plot[v_idx]
          continue
        endif
        
        ; Process samles keyword
        if ~undefined(samples) then begin
          if KEYWORD_SET(center_time) then begin
            pm_idx = ceil(samples/2.)
            t_idx  = [idx_to_plot - pm_idx, idx_to_plot+pm_idx]
          endif else begin
            t_idx  = [idx_to_plot , idx_to_plot+samples]
          endelse
          t_idx[0] = t_idx[0] lt 0 ? 0 : t_idx[0]
          t_idx[1] = t_idx[1] gt N_ELEMENTS(vardata.X)-1 ? N_ELEMENTS(vardata.X)-1 : t_idx[1] 
          trange  = [vardata.X[t_idx[0]] , vardata.X[t_idx[1]]]
        endif     
              
        if ~undefined(trange) then begin
          ; fix boundaries
          trange[0] = trange[0] lt vardata.X[0]  ? vardata.X[0] : trange[0]
          trange[1] = trange[1] gt vardata.X[-1] ? vardata.X[-1] : trange[1]
          ; find indexes that correspond to trange
          tmp = min(vardata.X - trange[0], /ABSOLUTE, t_idx_min)
          tmp = min(vardata.X - trange[1], /ABSOLUTE, t_idx_max)
          t_idx  = [t_idx_min , t_idx_max] 
        endif          
        
        ; t_idx is defined if we do averaging   
       if ~undefined(t_idx) then begin
          data_to_plot = mean(vardata.Y[t_idx[0]:t_idx[1], *],dimension=1) ; creates vector
          data_to_plot = reform(data_to_plot,[1,n_elements(data_to_plot)]) ; fix dimentions to [1,n]
        endif else begin        
          data_to_plot = vardata.Y[idx_to_plot, *]        
        endelse
          
        if dimen2(vardata.v) eq 1 then x_data = vardata.v else x_data = vardata.v[idx_to_plot, *]
        y_data = data_to_plot

        data_out = flatten_spectra_convert_units(vars_to_plot[v_idx], x_data, y_data, vardl, to_kev=to_kev, to_flux=to_flux)
        x_data = data_out['data_x']
        y_data = data_out['data_y']
        
        title_format = 'YYYY-MM-DD/hh:mm:ss.fff'
        title_str = (KEYWORD_SET(rangetitle) and ~undefined(trange)) ? $
          strjoin(time_string(trange, tformat=title_format),' - ') : $
          time_string(t, tformat='YYYY-MM-DD/hh:mm:ss.fff')
          
        if keyword_set(to_kev) then xunit_str = '[keV]'
        if keyword_set(to_flux) then yunit_str = '1/(cm!U2!N sr s keV)'
        
        if v_idx eq 0 and undefined(plot_created) then begin
          plot, x_data, y_data, $
            xlog=xlog, ylog=ylog, xrange=xrange, yrange=yrange, $
            xtitle=xunit_str, ytitle=yunit_str, $
            charsize=charsize, title=varinfo.catdesc, $
            thick=~undefined(thick) ? thick[time_idx] : 0, $
            linestyle=~undefined(linestyle) ? linestyle[time_idx] : 0, $
            color=colors[time_idx], _extra=_extra
            
            if ~keyword_set(nolegend) then begin
              if keyword_set(legend_left) then leg_x += !x.WINDOW[0]
              leg_y = !y.WINDOW[1] - leg_y
            endif            
        endif else begin
          oplot, x_data, y_data, thick=~undefined(thick) ? thick[time_idx] : 0, $
            linestyle=~undefined(linestyle) ? linestyle[time_idx] : 0,$
             color=colors[time_idx], _extra=_extra
        endelse
        
        ; to return the actual values via keywords
        yvalues[vars_to_plot[v_idx]] = reform(double(y_data))
        xvalues[vars_to_plot[v_idx]] = reform(double(x_data))
        
        ; needed for multiple times
        plot_created = 1b
        
        if ~keyword_set(nolegend) then begin
          leg_y -= leg_dy
          XYOUTS, leg_x, leg_y, title_str, /normal, color=colors[time_idx], charsize=1.5
        endif
    endfor
    if keyword_set(bar) then timebar, t
    wait, 0.3
  endfor
  

  ; save to file
  if KEYWORD_SET(png) and ~KEYWORD_SET(postscript) then makepng, fname
  if KEYWORD_SET(postscript) then pclose
end