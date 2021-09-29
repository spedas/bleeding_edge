;+
;
; This crib sheet shows how to search for events in the MMS burst-mode events database 
; 
;
;     WARNING - EXPERIMENTAL; please report bugs to egrimes@igpp.ucla.edu
;
;     Initial call will take more time than subsequent calls, due to the need to download the event index
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2020-11-24 13:13:35 -0800 (Tue, 24 Nov 2020) $
; $LastChangedRevision: 29388 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_event_search_crib.pro $
;-

; search for all events that mention 'bz'
mms_event_search, 'bz'
stop

; the events can also be returned by the keywords: 
;    authors, descriptions, start_times, end_times; e.g.,
mms_event_search, 'bz', authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times

; print the first description found 
print, 'Description: ' + descriptions[0]
print, 'Author: ' + authors[0]
print, 'Start time: ' + time_string(start_times[0])
print, 'End time: ' + time_string(end_times[0])
stop

; you can turn off printing to the console with the /quiet keyword, e.g.,
mms_event_search, 'solar wind', /quiet, authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times

print, 'Description: ' + descriptions[0]
print, 'Author: ' + authors[0]
print, 'Start time: ' + time_string(start_times[0])
print, 'End time: ' + time_string(end_times[0])
stop

; note: when searching for bigrams, etc, the events returned include all with descriptions containing both terms, e.g., 
;       if you search for 'bz jet' - all events with a description containing both 'bz' and 'jet' are returned
mms_event_search, 'bz jet', /quiet, authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times

print, 'Description: ' + descriptions[0]
print, 'Author: ' + authors[0]
print, 'Start time: ' + time_string(start_times[0])
print, 'End time: ' + time_string(end_times[0])

stop

; download FGM data for the last 5 events that mention 'jet' and 'reversal'
mms_event_search, 'jet reversal', /quiet, authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times

descs = descriptions[-5:-1]
starts = start_times[-5:-1]
ends = end_times[-5:-1]

for event_idx=0, n_elements(descs)-1 do begin
  print, 'Downloading: ' + descs[event_idx] + '; from ' + time_string(starts[event_idx]) + ' to ' + time_string(ends[event_idx])
  mms_load_fgm, probe=4, data_rate='brst', trange=[starts[event_idx], ends[event_idx]], /time_clip
endfor

end