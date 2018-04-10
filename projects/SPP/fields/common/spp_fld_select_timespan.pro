function spp_fld_select_timespan_preset, preset_times

  preset_keys = preset_times.Keys()

  preset_str = ''

  foreach preset_time, preset_times, preset_key do begin

    if strlen(preset_str) GT 0 then sep = '|' else sep = ''

    preset_str += sep + string(preset_key,format = '(A30)') + ': ' + strjoin(time_string(preset_time),'-')

  endforeach

  preset_desc = [ $
    '0, DROPLIST,' + preset_str + ', LABEL_TOP = Select a preset time from the drop down list below:, TAG=preset_ind, QUIT']

  preset_select = cw_form(preset_desc,/column)

  return, preset_times[preset_keys[preset_select.preset_ind]]

end

function spp_fld_select_timespan, input_timespan = input_timespan, $
  update = update, preset_times = preset_times

  @tplot_com.pro
  str_element,tplot_vars,'options.trange_full',trange_full

  if n_elements(trange_full) eq 2 then ts = trange_full

  if n_elements(ts) LT 2 or max(ts) EQ 0. then begin

    ts = [systime(/sec)-60., systime(/sec)]

  endif

  if n_elements(update) GT 0 then begin

    ts = [ts[0], systime(/sec)]

  endif else if n_elements(input_timespan) EQ 2 then begin

    ts = time_double(input_timespan)

    select_timespan_desc = [ $
      '0, LABEL, Time range will be set to:, CENTER', $
      '0, LABEL, UTC Time (YYYY-MM-DD/hh:mm:ss)', $
      '0, LABEL, ' + time_string(ts[0]), $
      '0, LABEL, ' + time_string(ts[1]), $
      '2, BUTTON, Load intialized UTC time range, QUIT, TAG=UTC_OK']

    timespan_str = cw_form(select_timespan_desc, /column)

  endif else begin

    select_timespan_desc = [ $
      '0, LABEL, Select time range, CENTER', $
      '0, BUTTON, Past 10 minutes, QUIT, TAG=past10m', $
      '0, BUTTON, Past 30 minutes, QUIT, TAG=past30m', $
      '0, BUTTON, Past 1 hour, QUIT, TAG=past01h', $
      '0, BUTTON, Past 2 hours, QUIT, TAG=past02h', $
      '0, BUTTON, Past 4 hours, QUIT, TAG=past04h', $
      '0, BUTTON, Past 8 hours, QUIT, TAG=past08h', $
      '0, BUTTON, Past 12 hours, QUIT, TAG=past12h', $
      '0, BUTTON, Past 24 hours, QUIT, TAG=past24h', $
      '0, BUTTON, Past 48 hours, QUIT, TAG=past48h', $
      '0, BUTTON, Preset Time, QUIT, TAG=preset', $
      '0, LABEL, UTC Time (YYYY-MM-DD/hh:mm:ss)', $
      '0, TEXT, ' + time_string(ts[0]) + ', LABEL_LEFT=Start, WIDTH=19,TAG=start', $
      '0, TEXT, ' + time_string(ts[1]) + ', LABEL_LEFT=Stop_, WIDTH=19,TAG=stop', $
      '0, BUTTON, Use manual UTC time range, QUIT, TAG=UTC_OK', $
      '2, BUTTON, Cancel, QUIT, TAG=CANCEL']

    timespan_str = cw_form(select_timespan_desc, /column)

    if timespan_str.past10m then begin
      ts = systime(/sec) + [-60.d*10., 0.d]
    endif else if timespan_str.past30m then begin
      ts = systime(/sec) + [-60.d*30., 0.d]
    endif else if timespan_str.past30m then begin
      ts = systime(/sec) + [-60.d*30., 0.d]
    endif else if timespan_str.past01h then begin
      ts = systime(/sec) + [-60.d*60., 0.d]
    endif else if timespan_str.past02h then begin
      ts = systime(/sec) + [-60.d*60.*2., 0.d]
    endif else if timespan_str.past04h then begin
      ts = systime(/sec) + [-60.d*60.*4., 0.d]
    endif else if timespan_str.past08h then begin
      ts = systime(/sec) + [-60.d*60.*8., 0.d]
    endif else if timespan_str.past12h then begin
      ts = systime(/sec) + [-60.d*60.*12., 0.d]
    endif else if timespan_str.past24h then begin
      ts = systime(/sec) + [-60.d*60.*24., 0.d]
    endif else if timespan_str.past48h then begin
      ts = systime(/sec) + [-60.d*60.*48., 0.d]
    endif else if timespan_str.preset then begin
      if keyword_set(preset_times) then begin
        ts = spp_fld_select_timespan_preset(preset_times)
      endif else begin
        print, 'No preset times loaded, timespan unchanged'
      endelse
    endif else if timespan_str.utc_ok then begin
      ts = time_double([timespan_str.start, timespan_str.stop])
    endif else begin
      ts = ts
    endelse

  endelse

  ;print, time_string(ts)

  timespan, ts

  return, ts

end