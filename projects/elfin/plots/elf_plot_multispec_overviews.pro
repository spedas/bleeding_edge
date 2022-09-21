  ;+
  ;Procedure: elf_plot_multispec_overviews
  ;
  ;PURPOSE:
  ;  Routine just wraps epde_plot_wigrf_multispec_overviews. Mainly used for processing.
  ;
  ;INPUT
  ;  Date: date for plot creation, if not set, assumes current date and duration counts backwards(ie last N days from today)
  ; 
  ;KEYWORDS
  ;  Dur: If set, number of days to process, default is 1
  ;  probe: 'a' or 'b'
  ;  no_download: If set no files will be downloaded
  ;  sci_zone: If set this flag will create overplots by science zone rather than by hour
  ;  quick_run: set this flag to reduce the resolution of the data for a quicker run
  ;  one_zone_only: set this flag to plot only the first zone (this is for debug purposes)
  ;-
pro elf_plot_multispec_overviews, date, dur=dur, probe=probe, no_download=no_download, $
    sci_zone=sci_zone,quick_run=quick_run, one_zone_only=one_zone_only

  compile_opt idl2

  ; initialize variables and parameters if needed
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  if ~keyword_set(dur) then begin
    dur = 1
  endif
  if undefined(probe) then probe='a'
  if n_params() eq 0 then begin
    ts = time_struct(systime(/seconds)-dur*60.*60.*24)
    ;form time truncated datetime string
    date = num_to_str_pad(ts.year,4) + '-' + num_to_str_pad(ts.month,2) + '-' + num_to_str_pad(ts.date,2)
  endif
  if undefined(quick_run) then quick_run=1 else quick_run=quick_run

  dprint,"Processing start time " + time_string(systime(/seconds)) + ' UT'
  dprint,"Generating ELFIN EPDE overview plots for " + date + " with duration " + strtrim(dur,2) + " days."

  start_time = time_double(date) 
  end_time = start_time + 86400.
  epde_plot_overviews, trange=[start_time, end_time], probe=probe, $
    no_download=no_download, sci_zone=sci_zone, quick_run=quick_run,/one_zone_only

  ; create plots for each day
  for j = 0,dur-1 do begin
    start_time = time_double(date) + j*60.*60.*24.
    end_time = start_time + 86400.
    epde_plot_overviews, trange=[start_time, end_time], probe=probe, $
      no_download=no_download, sci_zone=sci_zone, quick_run=quick_run
    ; remove temporary science zone tplot vars
    del_data, 'el'+probe+'_*sz*'
  endfor 
  
  start_time = time_double(date)
  end_time = start_time + 86400.
  epdi_plot_overviews, trange=[start_time, end_time], probe=probe, $
    no_download=no_download, sci_zone=sci_zone, quick_run=quick_run,/one_zone_only

  ; create plots for each day
  for j = 0,dur-1 do begin
    start_time = time_double(date) + j*60.*60.*24.
    end_time = start_time + 86400.
    epdi_plot_overviews, trange=[start_time, end_time], probe=probe, $
      no_download=no_download, quick_run=quick_run
    del_data, 'el'+probe+'_*sz*'
  endfor

end