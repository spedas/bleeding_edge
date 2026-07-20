;+
; PROCEDURE:
;         mms_load_fast_segments
;
; PURPOSE:
;         Loads the fast segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         trange:       time range of interest
;         suffix:       suffix to append to the fast segments bar tplot variable
;         start_times:  returns an array of unix times (double) containing the start for each fast interval
;         end_times:    returns an array of unix times (double) containing the end of each fast interval
;         nodownload:   flag to load the file if it's stored locally, and not download it from the spedas.org server;
;                       this is useful if the remote file seems out of date; you can run mms_update_brst_intervals
;                       to manually update the file from the data at the SDC, and set this flag to load your local file
;         sdc:          flag to load the fast survey intervals directly from the SDC; set this flag to 0 to load the data 
;                       from spedas.org (may be out of date)
; 
; NOTES:
;         WARNING: this routine no longer loads the correct fast segments for later in the mission; 
;                  for loading fast segment bars correctly throughout the entire mission, please
;                  use the wrapper: spd_mms_load_bss, which switches between this routine (for dates 
;                  before 6Nov15) and the new SRoI code (mms_load_sroi_segments) for dates on and after 6Nov15 
; 
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-07-17 17:19:03 -0700 (Fri, 17 Jul 2026) $
;$LastChangedRevision: 34654 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_fast_segments.pro $
;-

pro mms_load_fast_segments, trange=trange, suffix=suffix, start_times=start_times, end_times=end_times, nodownload=nodownload
  if undefined(suffix) then suffix = ''
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  
  mms_init
  
  padding = 14*86400
  
  tr_padded = [tr[0]-padding, tr[1]+padding]


  if undefined(nodownload) then begin
    ; Get fast survey intervals from the SDC
    mms_update_fast_intervals, trange=tr_padded, unix_start=unix_start, unix_end=unix_end
    ; Check for empty arrays
    if n_elements(unix_start) eq 0 then begin
      dprint, dlevel = 0, 'Error, no fast segments returned from SDC in this time interval: ' + time_string(tr_padded[0]) + ' to ' + time_string(tr_padded[1])     
    endif
  endif else begin
    ; Read fast survey intervals from cached abs files
    ; Instead of restoring a combined file, iterate through the abs directory and accumulate unix_start and unix_end arrays.
    dir_path = spd_addslash(!mms.local_data_dir) + 'abs/'
    file_list = file_search(dir_path + 'abs_selections_*.sav')
    if n_elements(file_list) eq 0 then begin
      dprint,dlevel=0,'mms_load_fast_segments: No local files found"
      return
    endif
    for i=0, n_elements(file_list)-1 do begin
      print,'Loading local file ', file_list[i]
      bn = file_basename(file_list[i])
      yyyy=strmid(bn,15,4)
      mon=strmid(bn,20,2)
      day=strmid(bn,23,2)
      hr=strmid(bn,26,2)
      mm=strmid(bn,29,2)
      sec=strmid(bn,32,2)
      file_timestamp=yyyy+'-'+mon+'-'+day+'/'+hr+':'+mm+':'+sec
      file_timestamp_dbl=time_double(file_timestamp)
      abs_get_start_end,filename=file_list[i], unix_start=this_start, unix_end=this_end
      
      append_array, unix_start, this_start
      append_array, unix_end, this_end
      
      ; Can we stop reading files yet?  The choice of timestamps in the file names are a little weird. The individual files can contain
      ; start times before the filename time, or after the filename time (by several days!)   So far, 1 week of padding seems to be
      ; enough to guarantee that there won't be more segments found in later files.  For safety, we'll double that, and quit once
      ; the file timestamps are two weeks past the end of the requested time range.

      if file_timestamp_dbl gt tr_padded[1] then begin
        dprint,dlevel=0,"Current file timestamp: "+ file_timestamp+" , end of unpadded time range: "+time_string(tr[1])+" , stopping search."
        break
      endif

    endfor
    
    if n_elements(unix_start) eq 0 then begin
      dprint,dlevel=0,'mms_load_fast_segments: No time intervals found in local files'
    endif
  endelse
  
  ; Sort start and end time arrays (maybe not needed now?)
  ; The search time range was padded by 2 days on either side; now we'll time clip to the exact interval requested
  times_in_range = where(unix_end ge tr[0] and unix_start le tr[1], t_count)

  if t_count ne 0 then begin
    unix_start_clipped = unix_start[times_in_range]
    unix_end_clipped = unix_end[times_in_range]
    
    for idx = 0, n_elements(unix_start_clipped)-1 do begin
        append_array, bar_x, [unix_start_clipped[idx], unix_start_clipped[idx], unix_end_clipped[idx], unix_end_clipped[idx]]
        append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
    endfor
    
    if undefined(bar_x) then return
    
    store_data,'mms_bss_fast'+suffix,data={x:bar_x, y:bar_y}
    options,'mms_bss_fast'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
      ticklen=0,panel_size=0.09,colors=4, labels=['Fast'], charsize=2.
    start_times = unix_start
    end_times = unix_end
  endif else begin
    dprint, dlevel = 0, 'No fast segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
  endelse
end