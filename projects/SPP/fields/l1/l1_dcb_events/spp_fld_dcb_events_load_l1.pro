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

  rts_types = prefix + ['RTSLMTERR','RTSENAERR','RTSBSYERR','RTSSTARTED']

  rts_codes = [0xC9,0xCA,0xCB,0xCC]

  foreach rts_type, rts_types, i do begin

    ind = where(d_code.y EQ rts_codes[i], count)

    if count GT 0 then begin

      rts = d_dat1.y[ind]

      store_data, rts_type, $
        dat = {x:d_code.x[ind], y:rts}

      ;options, name, 'ynozero', 1
      options, rts_type, 'colors', [6]
      options, rts_type, 'ytitle', 'DCB RTS'

      options, rts_type, 'ysubtitle', ''

      options, rts_type, 'psym', 4
      options, rts_type, 'symsize', 0.5
    endif

  endforeach

  ;  t0_ur8 = time_double('1982-01-01')
  ;
  ;  foreach b, burst_types do begin
  ;
  ;    pre = prefix + b
  ;
  ;    get_data, pre + '_TIME_MET', dat = t_met
  ;    get_data, pre + '_TIME_UR8', dat = t_ur8
  ;
  ;    if size(/type, t_ur8) EQ 8 and size(/type, t_met) EQ 8 then begin
  ;
  ;      finite_ind = where(finite(t_ur8.y), finite_count)
  ;
  ;      if finite_count GT 0 then begin
  ;
  ;        t_unix = t0_ur8 + t_ur8.y[finite_ind] * 24d * 60d * 60d
  ;
  ;        store_data, pre + '_TIME_COLLECT_TO_WRITE', $
  ;          dat = {x:t_unix, y:(t_ur8.x[finite_ind] - t_unix)/60d}
  ;
  ;        options, pre + '_TIME_COLLECT_TO_WRITE', 'ytitle', b + '!CCOLLECT!CTO WRITE'
  ;        options, pre + '_TIME_COLLECT_TO_WRITE', 'ysubtitle', '[Min]'
  ;        options, pre + '_TIME_COLLECT_TO_WRITE', 'psym', 4
  ;        options, pre + '_TIME_COLLECT_TO_WRITE', 'symsize', 0.5
  ;        options, pre + '_TIME_COLLECT_TO_WRITE', 'colors', 6
  ;        options, pre + '_TIME_COLLECT_TO_WRITE', 'ylog', 1
  ;
  ;      end
  ;
  ;    end
  ;
  ;  end

  ;  tu2=tu + u*24*60*60.


end