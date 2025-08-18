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

  rts_names = ['', '_SCM_CAL', '_MAG_CAL', '_V5_SWEEP', $
    '_SET_RBIAS2', '_SET_RBIAS1', '_BIAS_SWEEP', $
    '_RFS_LO', '_STUB_TOGGLE', '_RFS_CAL']
  rts_values = [-1, 15, 17, 18, $
    19, 20, 21, $
    28, 29, 30]

  ;
  ; Prior to Encounter 3, BIAS_SWEEP was RTS = 20
  ; Prior to Encounter 4, SET_RBIAS1 was not defined
  ; Prior to Encounter 11, RFS and STUB_TOGGLE not defined
  ;

  enc03_met = 303673800
  pre_enc03 = where(d_met.y LT enc03_met, pre_enc03_count)
  enc04_met = 316820280
  pre_enc04 = where(d_met.y LT enc04_met, pre_enc04_count)
  enc11_met = 379159774
  pre_enc11 = where(d_met.y LT enc11_met, pre_enc11_count)

  ;
  ; Error conditions (LMTERR, ENAERR, BSYERR) correspond to different values
  ; of the code variable.
  ;
  ; Error conditions occur infrequently, compared
  ; to nominal start of the RTS (STARTED).
  ;
  ; On orbit, LMTERR has never occurred (as of 2022 March).
  ;
  ; ENAERR has occurred one time, in the file 0274861895_2_DF on 2018-09-17
  ;
  ; BSYERR has occurred a handful of times, typically appearing immediately
  ; after a turn on.
  ;



  rts_stats = prefix + ['RTSLMTERR','RTSENAERR','RTSBSYERR','RTSSTARTED']
  rts_codes = [0xC9,0xCA,0xCB,0xCC]

  foreach rts_name, rts_names, i do begin

    rts_value = rts_values[i]

    foreach rts_stat, rts_stats, j do begin

      rts_code = rts_codes[j]

      if rts_code EQ 0xCC then rts_dat = d_dat0.y else rts_dat = d_dat1.y

      if rts_value EQ -1 then begin

        ind = where(d_code.y EQ rts_code, count)

      endif else begin

        code_dat = d_code.y

        if rts_name EQ '_BIAS_SWEEP' and pre_enc03_count GT 0 then begin

          ind_pre = where(code_dat EQ rts_code and rts_dat EQ 20 and d_met.y LT enc03_met, pre_count)
          ind = where(code_dat EQ rts_code and rts_dat EQ rts_value and d_met.y GE enc03_met, count)

          if pre_count NE 0 then begin
            if count EQ 0 then begin
              ind = ind_pre
              count = pre_count
            endif else begin
              ind = [ind_pre, ind]
              count = pre_count + count
            endelse
          endif

        endif else if rts_name EQ '_SET_RBIAS1' and pre_enc04_count GT 0 then begin

          ind = where(code_dat EQ rts_code and rts_dat EQ rts_value and d_met.y GE enc04_met, count)

        endif else if rts_name EQ '_RFS_LO' or rts_name EQ '_STUB_TOGGLE' or rts_name EQ '_RFS_CAL' then begin

          ind = where(code_dat EQ rts_code and rts_dat EQ rts_value and d_met.y GE enc11_met, count)
     
        endif else begin

          ind = where(code_dat EQ rts_code and rts_dat EQ rts_value, count)

        endelse

      endelse

      print, count, rts_stat + rts_name

      if count GT 0 then begin

        rts = rts_dat[ind]

        store_data, rts_stat + rts_name, $
          dat = {x:d_code.x[ind], y:rts}

        store_data, rts_stat + rts_name + '_MET', $
          dat = {x:d_code.x[ind], y:d_met.y[ind]}
        options, rts_stat + rts_name + '_MET', 'ynozero', 1

        if rts_stat.EndsWith('STARTED') then begin
          options, rts_stat + rts_name, 'colors', [2]
          options, rts_stat + rts_name, 'symsize', 1.0
          options, rts_stat + rts_name, 'psym', 1
        endif else begin
          options, rts_stat + rts_name, 'colors', [6]
          options, rts_stat + rts_name, 'symsize', 2.5
          options, rts_stat + rts_name, 'psym', 2
          options, rts_stat + rts_name, 'thick', 3
        endelse
        options, rts_stat + rts_name, 'ytitle', 'DCB RTS' + $
          rts_name.Replace('_','!C')
        options, rts_stat + rts_name, 'ysubtitle', ''

        if min(rts) EQ max(rts) or min(rts) + 1 EQ max(rts) then begin
          options, rts_stat + rts_name, 'yrange', [min(rts)-1, max(rts) + 1]
          options, rts_stat + rts_name, 'ystyle', 1
          options, rts_stat + rts_name, 'symsize', 1.0
          options, rts_stat + rts_name, 'yminor', 1
          options, rts_stat + rts_name, 'yticks', [max(rts) - min(rts)] + 2
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