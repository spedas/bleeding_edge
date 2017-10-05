;+
;PROCEDURE:
;         mms_tplot_quicklook
;
; PURPOSE:
;         Wrapper around tplot specifically for MMS quicklook figures; this
;         routine will include all panels in the QL figure even when there is no 
;         data (panels without data are labeled 'NO DATA')
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-19 08:34:58 -0700 (Fri, 19 Aug 2016) $
; $LastChangedRevision: 21677 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/quicklook/mms_tplot_quicklook.pro $
;-

pro mms_tplot_quicklook, tplotnames, degap=degap, window=win_idx, $
  xsize=xsize, ysize=ysize, burst_bar=burst_bar, fast_bar=fast_bar, $
  trange=trange, title=title, _extra=ex
  
@tplot_com.pro ; tplot common block

    if keyword_set(trange) then begin
      start_time = time_string(trange[0])
      end_time = time_string(trange[1])
    endif else if is_struct(tplot_vars.options) then begin
      ; grab the trange from the common block if it isn't specified as a keyword
      start_time = time_string(tplot_vars.options.trange[0])
      end_time = time_string(tplot_vars.options.trange[1])
    endif
    
    ; grab previous data names if tplotnames isn't specified
    if undefined(tplotnames) then begin
      tpv_opt_tags = tag_names( tplot_vars.options)
      idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
      if icnt gt 0 then begin
        tplotnames = tplot_vars.options.datanames
        tplotnames = tnames(tplotnames, nd, /all, index=ind)
      endif else begin
        return
      endelse
    endif; else tplotnames = tnames(tplotnames, nd, /all, index=ind)

    if ~keyword_set(xsize) then xsize=710
    if ~keyword_set(ysize) then ysize=1150

    if keyword_set(fast_bar) && tnames(fast_bar) ne '' then begin
      append_array, tplotnames_with_data, fast_bar
      append_array, data_or_no_data, 1
    endif
    if keyword_set(burst_bar) && tnames(burst_bar) ne '' then begin
      append_array, tplotnames_with_data, burst_bar
      append_array, data_or_no_data, 1
    endif

    ; check that the tvars exist and have data over the trange
    for tvar_idx = 0, n_elements(tplotnames)-1 do begin
      get_data, tplotnames[tvar_idx], data=d
      if tdexists(tplotnames[tvar_idx], start_time, end_time) ne 0 or (is_array(d) && is_string(d)) then begin
        
        ; force the data to be monotonic
       ; tplot_force_monotonic, tplotnames[tvar_idx], /forward, /keep_repeats 
        
        if is_array(d) && is_string(d) then begin
          ; pseudo variable
          valid_p_var = 0
          
          for pseudo_var_idx = 0, n_elements(d)-1 do begin
            if tdexists(d[pseudo_var_idx], start_time, end_time) ne 0 then valid_p_var += 1
          endfor
          
          ; check if there was a valid variable inside the pseudo variable
          if valid_p_var gt 0 then begin
            append_array, tplotnames_with_data, tplotnames[tvar_idx]
            append_array, data_or_no_data, 1
          endif else begin
            ; dummy var, only name is correct (for y-axis title)
            store_data, tplotnames[tvar_idx]+'_nodata', data={x: [time_double(start_time), time_double(end_time)], y: [0, 0]}
            append_array, tplotnames_with_data, tplotnames[tvar_idx]+'_nodata'
            append_array, data_or_no_data, 0
          endelse
            
        endif else begin
          append_array, tplotnames_with_data, tplotnames[tvar_idx]
          append_array, data_or_no_data, 1
        endelse
      endif else begin
        ; dummy var, only name is correct (for y-axis title)
        store_data, tplotnames[tvar_idx]+'_nodata', data={x: [time_double(start_time), time_double(end_time)], y: [0, 0]}
        append_array, tplotnames_with_data, tplotnames[tvar_idx]+'_nodata'
        append_array, data_or_no_data, 0
      endelse
    endfor
    
    ; degap the data
    if keyword_set(degap) then tdegap, tplotnames_with_data, /overwrite
    
    ; plot them
    if keyword_set(win_idx) then window, win_idx, xsize=xsize, ysize=ysize else window, xsize=xsize, ysize=ysize


    ; fixes weird bug with title on OS X, when calling this
    ; routine repeatedly
    wait, .01
    
    tplot, tplotnames_with_data, get_plot_pos=positions, window=win_idx, trange=trange, title=title, _extra=ex

    ; add NO DATA labels to plots on the figure without any data
    where_no_data = where(data_or_no_data eq 0, nodatacount)
    if nodatacount ne 0 then begin
      no_data_msg = 'NO DATA'
      no_data_panel_pos = positions[*, where_no_data]
      for no_data_panel=0, nodatacount-1 do begin
        xyouts, charsize=1, /normal, 0.47, (no_data_panel_pos[*,no_data_panel])[1]+((no_data_panel_pos[*,no_data_panel])[3]-(no_data_panel_pos[*,no_data_panel])[1])/2.0, no_data_msg
      endfor
    endif
end