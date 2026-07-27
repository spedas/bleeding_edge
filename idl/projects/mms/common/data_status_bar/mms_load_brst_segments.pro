;+
; PROCEDURE:
;         mms_load_brst_segments
;
; PURPOSE:
;         Loads the brst segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         trange:       time range of interest
;         suffix:       suffix to append to the tplot variable of the burst segments bar
;         start_times:  returns an array of unix times (double) containing the start for each burst interval
;         end_times:    returns an array of unix times (double) containing the end of each burst interval
;         no_download:   flag to load the file if it's stored locally, and not download it from the spedas.org server;
;                       this is useful if the remote file seems out of date; you can run mms_update_brst_intervals
;                       to manually update the file from the data at the SDC, and set this flag to load your local file
;         sdc:          flag to load the brst intervals directly from the SDC; set this flag to 0 to load the data from spedas.org (may be out of date)
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-07-22 17:28:56 -0700 (Wed, 22 Jul 2026) $
;$LastChangedRevision: 34663 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_brst_segments.pro $
;-

pro mms_load_brst_segments, trange=trange, suffix=suffix, start_times=start_times, end_times=end_times, no_download=no_download, sdc=sdc
  if undefined(suffix) then suffix = ''
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  if undefined(no_download) then no_download=0
  if undefined(suffix) then suffix=''
    
  mms_init
  padding = 2*86400
  
  tr_padded = [tr[0]-padding, tr[1]+padding]
  
  undefine, start_times
  undefine, end_times
  
  if no_download eq 0 then begin
    mms_update_brst_intervals, trange=tr_padded, start_times=start_times, end_times=end_times
  endif else begin
    monthly_intervals = spd_month_intervals(tr_padded[0], tr_padded[1])
    if n_elements(monthly_intervals) < 2 then begin
      dprint,dlevel=0,"mms_load_brst_intervals: Can't find monthly intervals for input trange: ",trange
      return
    endif
    ; Iterate through cached files and collect the burst intervals
    for i=0,n_elements(monthly_intervals)/2-1 do begin
      file_start = monthly_intervals[0,i]
      file_end=monthly_intervals[1,i]
      file_start_str = time_string(file_start,tformat="YYYY_MM_DD")
      file_end_str = time_string(file_end,tformat="YYYY_MM_DD")
      local_filename=spd_addslash(!mms.local_data_dir)+'burst_intervals/segments_'+file_start_str+'_'+file_end_str+".csv"
      seg_csv_get_start_end,filename=local_filename,unix_starts=this_start, unix_ends=this_end
      append_array,start_times,this_start
      append_array,end_times, this_end
    endfor
  endelse

  ; Instead of restoring a single combined file, iterate over local files and accumulate intervals in range  
  ;restore, brst_file
  
  if n_elements(start_times) ge 1 then begin
    unix_start = start_times
    unix_end = end_times
    
    sorted_idxs = bsort(unix_start)
    unix_start = unix_start[sorted_idxs]
    unix_end = unix_end[sorted_idxs]
    
    ; Time clip to remove any padding
    times_in_range = where(unix_start ge tr[0] and unix_start le tr[1], t_count)
  
    if t_count ne 0 then begin
      
      for idx = 0, n_elements(unix_start)-1 do begin
        if unix_end[idx] ge tr[0] and unix_start[idx] le tr[1] then begin
          append_array, bar_x, [unix_start[idx], unix_start[idx], unix_end[idx], unix_end[idx]]
          append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
        endif
      endfor
      if undefined(bar_x) then begin
        dprint, dlevel = 0, 'mms_load_brst_intervals: No burst segments within the requested time range'
        return
      endif
      store_data,'mms_bss_burst'+suffix,data={x:bar_x, y:bar_y}
      options,'mms_bss_burst'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
        ticklen=0,panel_size=0.09,colors=4, labels=['Burst'], charsize=2.
      start_times = unix_start
      end_times = unix_end
    endif else begin
      dprint, dlevel = 0, 'mms_load_brst_intervals: No burst segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
      start_times=[]
      end_times=[]
    endelse
  endif else begin
    dprint, dlevel = 0, 'mms_load_brst_intervals: No burst segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
    start_times=[]
    end_times=[]
  endelse
end