;+
; PROCEDURE:
;         mms_find_burst_intervals_crib
;
; PURPOSE:
;         This crib sheet shows how to find the start/stop times of
;         MMS burst intervals from the burst segments bar
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-08-18 09:28:15 -0700 (Thu, 18 Aug 2016) $
;$LastChangedRevision: 21669 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_find_burst_intervals_crib.pro $
;-

trange = ['2015-10-16/13:00', '2015-10-16/14:00']

; Load the burst segments bar for October 16, 2015
mms_load_brst_segments, trange=trange, start_times = start_bursts, end_times = end_bursts

; loop over the intervals, printing the start and stop
for interval_idx=0, n_elements(start_bursts)-1 do begin
  print, 'burst interval start: ' + time_string(start_bursts[interval_idx]) + ' - stop: ' + time_string(end_bursts[interval_idx])
endfor

end