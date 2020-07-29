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
; 
; NOTES:
;         WARNING: this routine no longer loads the correct fast segments for later in the mission; 
;                  for loading fast segment bars correctly throughout the entire mission, please
;                  use the wrapper: spd_mms_load_bss, which switches between this routine (for dates 
;                  before 6Nov15) and the new SRoI code (mms_load_sroi_segments) for dates on and after 6Nov15 
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-07-28 14:48:00 -0700 (Tue, 28 Jul 2020) $
;$LastChangedRevision: 28949 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_fast_segments.pro $
;-

pro mms_load_fast_segments, trange=trange, suffix=suffix, start_times=start_times, end_times=end_times
  if undefined(suffix) then suffix = ''
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  
  mms_init

  fast_file = spd_download(remote_file='http://www.spedas.org/mms/mms_fast_intervals.sav', $
    local_file=!mms.local_data_dir+'mms_fast_intervals.sav', $
    SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

  restore, fast_file
  
  if is_struct(fast_intervals) then begin
    unix_start = reverse(fast_intervals.start_times)
    unix_end = reverse(fast_intervals.end_times)
    
    times_in_range = where(unix_start ge tr[0]-2*86400.0 and unix_start le tr[1]+2*86400.0, t_count)

    if t_count ne 0 then begin
      unix_start = unix_start[times_in_range]
      unix_end = unix_end[times_in_range]
      
      for idx = 0, n_elements(unix_start)-1 do begin
        if unix_end[idx] ge tr[0] and unix_start[idx] le tr[1] then begin
          append_array, bar_x, [unix_start[idx], unix_start[idx], unix_end[idx], unix_end[idx]]
          append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
        endif
      endfor
      
      if undefined(bar_x) then return
      
      store_data,'mms_bss_fast'+suffix,data={x:bar_x, y:bar_y}
      options,'mms_bss_fast'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
        ticklen=0,panel_size=0.09,colors=4, labels=['Fast'], charsize=2.
      start_times = unix_start
      end_times = unix_end
    endif else begin
      dprint, dlevel = 0, 'Error, no fast segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
    endelse
  endif else begin
    dprint, dlevel = 0, 'Error, couldn''t find the fast intervals save file'
  endelse
end