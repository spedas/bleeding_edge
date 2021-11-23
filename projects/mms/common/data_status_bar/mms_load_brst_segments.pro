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
;         nodownload:   flag to load the file if it's stored locally, and not download it from the spedas.org server;
;                       this is useful if the remote file seems out of date; you can run mms_update_brst_intervals
;                       to manually update the file from the data at the SDC, and set this flag to load your local file
;         sdc:          flag to load the brst intervals directly from the SDC; set this flag to 0 to load the data from spedas.org (may be out of date)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-11-22 12:26:03 -0800 (Mon, 22 Nov 2021) $
;$LastChangedRevision: 30433 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_brst_segments.pro $
;-

pro mms_load_brst_segments, trange=trange, suffix=suffix, start_times=start_times, end_times=end_times, nodownload=nodownload, sdc=sdc
  if undefined(suffix) then suffix = ''
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  
  mms_init
  
  undefine, start_times
  undefine, end_times
  
  ; SDC option is the default as of 27 Oct 2021
  if undefined(sdc) then sdc = 1
  
  if undefined(nodownload) and sdc eq 0 then begin
    brst_file = spd_download(remote_file='http://www.spedas.org/mms/mms_brst_intervals.sav', $
      local_file=!mms.local_data_dir+'mms_brst_intervals.sav', $
      SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

    ; try updating the burst intervals file if there are any errors while trying to load the file
    catch, error_status
    if (error_status ne 0) then begin
      catch, /cancel
      if strpos(!error_state.msg, 'RESTORE: Error opening file.') ne -1 then begin
          mms_update_brst_intervals
          brst_file = !mms.local_data_dir+'mms_brst_intervals.sav'
      endif
    endif
  endif else brst_file = !mms.local_data_dir+'mms_brst_intervals.sav'
  
  if undefined(nodownload) and sdc eq 1 then mms_update_brst_intervals
  
  restore, brst_file
  
  if is_struct(brst_intervals) then begin
    unix_start = brst_intervals.start_times
    unix_end = brst_intervals.end_times
    
    sorted_idxs = bsort(unix_start)
    unix_start = unix_start[sorted_idxs]
    unix_end = unix_end[sorted_idxs]
    
    times_in_range = where(unix_start ge tr[0]-300.0 and unix_start le tr[1]+300, t_count)

    if t_count ne 0 then begin
      unix_start = unix_start[times_in_range]
       ; +10 second offset added by egrimes, 10/26/2016; there appears to be an extra 10
       ; seconds of data, consistently, not included in the range here
      unix_end = unix_end[times_in_range]+10.0
      
      for idx = 0, n_elements(unix_start)-1 do begin
        if unix_end[idx] ge tr[0] and unix_start[idx] le tr[1] then begin
          append_array, bar_x, [unix_start[idx], unix_start[idx], unix_end[idx], unix_end[idx]]
          append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
        endif
      endfor
      if undefined(bar_x) then begin
        dprint, dlevel = 0, 'Error, no burst intervals within the requested time range'
        return
      endif
      store_data,'mms_bss_burst'+suffix,data={x:bar_x, y:bar_y}
      options,'mms_bss_burst'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
        ticklen=0,panel_size=0.09,colors=4, labels=['Burst'], charsize=2.
      start_times = unix_start
      end_times = unix_end
    endif else begin
      dprint, dlevel = 0, 'Error, no brst segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
    endelse
  endif else begin
    dprint, dlevel = 0, 'Error, couldn''t find the brst intervals save file'
  endelse
end