pro spp_fld_dcb_events_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_events_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  dcb_event_names = tnames(prefix + '*')

  if dcb_event_names[0] NE '' then begin

    for i = 0, n_elements(dcb_event_names)-1 do begin

      name = dcb_event_names[i]

      options, name, 'ynozero', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', 'DCB Evnt!C' + name.Remove(0, prefix.Strlen()-1)

      options, name, 'ysubtitle', ''

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endfor

  endif

  get_data, 'spp_fld_dcb_events_CCSDS_MET_Seconds', data = d_met
  get_data, 'spp_fld_dcb_events_EVNTCODE', dat = d_code
  get_data, 'spp_fld_dcb_events_EVNTDATA0', dat = d_dat0
  get_data, 'spp_fld_dcb_events_EVNTDATA1', dat = d_dat1
  get_data, 'spp_fld_dcb_events_EVNTDATA2', dat = d_dat2

  if size(/type, d_met) NE 8 then return


  burst_types = prefix + ['DFB_BURST','TDS_QUALITY', 'TDS_HONESTY']
  burst_codes = [0x3A, 0x2B, 0x2A]
  burst_colors = [2,4,6]

  options, 'spp_fld_dcb_events_EVNTCODE', 'yrange', [0, 256]
  options, 'spp_fld_dcb_events_EVNTCODE', 'ystyle', 1

  options, 'spp_fld_dcb_events_EVNTCODE', 'yticks', 4

  options, 'spp_fld_dcb_events_EVNTCODE', 'yticklen', 1

  options, 'spp_fld_dcb_events_EVNTCODE', 'ygridstyle', 1

  foreach b, burst_types, i do begin

    ind = where(d_code.y EQ burst_codes[i], count)

    if count GT 0 then begin

      burst_write_met = d_met.y[ind]

      burst_collect_met = (d_met.y[ind] / 256ll^3) * 256ll^3 + $
        d_dat0.y[ind] * 256ll^2 + $
        d_dat1.y[ind] * 256ll + $
        d_dat2.y[ind]

      store_data, b + '_TIME_COLLECT_TO_WRITE', $
        dat = {x:d_code.x[ind], y:(burst_write_met - burst_collect_met)>1}

      options, b + '_TIME_COLLECT_TO_WRITE', 'ytitle', $
        repstr(strmid(b,strlen(prefix)),'_','!C') + '!CCOLLECT!CTO WRITE'
      options, b + '_TIME_COLLECT_TO_WRITE', 'ysubtitle', '[Seconds]'
      options, b + '_TIME_COLLECT_TO_WRITE', 'psym', 1
      options, b + '_TIME_COLLECT_TO_WRITE', 'symsize', 0.65
      options, b + '_TIME_COLLECT_TO_WRITE', 'colors', burst_colors[i]
      options, b + '_TIME_COLLECT_TO_WRITE', 'ylog', 1
      options, b + '_TIME_COLLECT_TO_WRITE', 'panel_size', 2

      ;
      ; We want the TMlib time here because we want to compare collection
      ; times (MET) with command times, which are in MET (i.e. not corrected
      ; to UTC).
      ;

      tmlib_collect_t = time_double('2010-01-01') + burst_collect_met + $
        lonarr(n_elements(burst_collect_met)) / 65536d

      store_data, b + '_COLLECT_TIME', $
        dat = {x:tmlib_collect_t, $
        y:dblarr(n_elements(burst_collect_met)) + 0.5d}

      options, b + '_COLLECT_TIME', 'ytitle', $
        repstr(strmid(b,strlen(prefix)),'_','!C') + '!CCOLLECT'
      options, b + '_COLLECT_TIME', 'psym', 1
      options, b + '_COLLECT_TIME', 'symsize', 0.65
      options, b + '_COLLECT_TIME', 'colors', burst_colors[i]
      options, b + '_COLLECT_TIME', 'yrange', [0,1]
      options, b + '_COLLECT_TIME', 'yticks', 1
      options, b + '_COLLECT_TIME', 'yminor', 1
      options, b + '_COLLECT_TIME', 'ytickname', [' ', ' ']

    endif

  endforeach

  ;
  ; The dcb_events catalog contains an entry for each time an RTS is called.
  ;
  ; RTS name/value identify the type of each individual RTS, with text 'name'
  ;   and numerical 'value':
  ;
  ; RTS name: short name identifying the particular RTS, used as a suffix
  ;   for the TPLOT item. Empty string matches all RTS, and is used to
  ;   create a TPLOT item corresponding to all RTS.
  ; RTS value: number (1-32) corresponding to the RTS. -1 matches all RTS, and
  ;   is used to create a TPLOT item corresponding to all RTS.
  ;
  ; RTS type/code describe the status of each RTS, with text 'type' and
  ;   numerical 'code'.
  ;
  ; RTS stat: Status of the RTS, which can indicate:
  ;   'limit' error (called RTS is out of bounds of valid RTS range)
  ;   'enable' error (called RTS is disabled)
  ;   'busy' error (called RTS is already running)
  ;   'started' (RTS successfully started at the given time with no error).
  ; RTS code: Hexadecimal code from the DCB Events data,
  ;   corresponding to the above statuses.
  ;

  rts_names = ['', '_BIAS_SWEEP','_MAG_CAL','_SCM_CAL']
  rts_values = [-1,21,15,17]

  rts_stats = prefix + ['RTSLMTERR','RTSENAERR','RTSBSYERR','RTSSTARTED']
  rts_codes = [0xC9,0xCA,0xCB,0xCC]

  foreach rts_name, rts_names, i do begin

    rts_value = rts_values[i]

    foreach rts_stat, rts_stats, j do begin

      rts_code = rts_codes[j]

      if rts_value EQ -1 then begin

        ind = where(d_code.y EQ rts_code, count)

      endif else begin

        ind = where(d_code.y EQ rts_code and d_dat1.y EQ rts_value, count)

      endelse

      print, count, rts_stat + rts_name

      if count GT 0 then begin

        rts = d_dat1.y[ind]

        store_data, rts_stat + rts_name, $
          dat = {x:d_code.x[ind], y:rts}

        if rts_stat.EndsWith('STARTED') then begin
          options, rts_stat + rts_name, 'colors', [2]
          options, rts_stat + rts_name, 'symsize', 0.5
          options, rts_stat + rts_name, 'psym', 1
        endif else begin
          options, rts_stat + rts_name, 'colors', [6]
          options, rts_stat + rts_name, 'symsize', 0.75
          options, rts_stat + rts_name, 'psym', 2
        endelse
        options, rts_stat + rts_name, 'ytitle', 'DCB RTS' + $
          rts_name.Replace('_','!C')
        options, rts_stat + rts_name, 'ysubtitle', ''

        if min(rts) EQ max(rts) then begin
          options, rts_stat + rts_name, 'yrange', rts + [-1,1]
          options, rts_stat + rts_name, 'ystyle', 1
          options, rts_stat + rts_name, 'symsize', 1.0
          options, rts_stat + rts_name, 'yminor', 1
          options, rts_stat + rts_name, 'yticks', 2
        endif

      endif

    endforeach

    store_data, prefix + 'RTS' + rts_name, $
      data = rts_stats + rts_name
    options, prefix + 'RTS' + rts_name, 'ytitle', 'DCB RTS' + $
      rts_name.Replace('_','!C')
    options, prefix + 'RTS' + rts_name, 'ystyle', 1

    if rts_name NE '' then begin
      options, prefix + 'RTS' + rts_name, 'yrange', rts_value + [-1,1]
      options, prefix + 'RTS' + rts_name, 'yminor', 1
      options, prefix + 'RTS' + rts_name, 'yticks', 2
    endif else begin
      options, prefix + 'RTS' + rts_name, 'yrange', [0,32]
    endelse

  endforeach

end