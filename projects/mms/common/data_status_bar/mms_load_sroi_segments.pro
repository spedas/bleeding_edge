;+
; PROCEDURE:
;         mms_load_sroi_segments
;
; PURPOSE:
;         Loads the SRoI segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         trange:       time range of interest
;         probe:        spacecraft probe # to load the SRoIs for (default: 1)
;         suffix:       suffix to append to the SRoI segments bar tplot variable
;         start_times:  returns an array of unix times (double) containing the start for each SRoI interval
;         end_times:    returns an array of unix times (double) containing the end of each SRoI interval
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-06-19 11:30:13 -0700 (Fri, 19 Jun 2020) $
;$LastChangedRevision: 28790 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_sroi_segments.pro $
;-

pro mms_load_sroi_segments, trange=trange, probe=probe, suffix=suffix, start_times=start_times, end_times=end_times

  if undefined(suffix) then suffix = ''
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  mms_init
  
  results = get_mms_srois(start_time=time_string(tr[0]-2*86400.0, tformat='YYYY-MM-DD'), end_time=time_string(tr[1]+2*86400.0, tformat='YYYY-MM-DD'), sc_id='mms'+probe, /public)

  if ~is_struct(results) then begin
    dprint, dlevel=0, 'Error, no Science Regions of Interest found'
    return
  endif
  
  for result_idx=0, n_elements(results)-1 do begin
    if time_double(results[result_idx].end_time) ge tr[0] and time_double(results[result_idx].start_time) le tr[1] then begin
      append_array, bar_x, [time_double(results[result_idx].start_time), time_double(results[result_idx].start_time), time_double(results[result_idx].end_time), time_double(results[result_idx].end_time)]
      append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
      ; for returning the actual values
      append_array, start_times, time_double(results[result_idx].start_time)
      append_array, end_times, time_double(results[result_idx].end_time)
    endif
  endfor
  
  if undefined(bar_x) then return

  store_data,'mms'+probe+'_bss_sroi'+suffix,data={x:bar_x, y:bar_y}
  options,'mms'+probe+'_bss_sroi'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=0.09,colors=4, labels=['SRoI'], charsize=2.

end