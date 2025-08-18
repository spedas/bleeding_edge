;+
;
; PROCEDURE:
;     mms_event_search
;     
; PURPOSE:
;     Search the MMS events database for terms in the event description
;     
; INPUT:
;     term: term to search for in the events database (description)
;
; KEYWORDS:
;     trange: two element array specifying time range; default is to return all events
;     descriptions: returns the list of descriptions for found events
;     authors: returns the list of authors for found events
;     start_times: returns the list of start times for found events
;     end_times: returns the list of end times for found events
;     quiet: disable printing event authors and descriptions to the console
;     
; NOTES:
;     WARNING - EXPERIMENTAL; please report bugs to egrimes@igpp.ucla.edu
;     
;     Initial call will take more time than subsequent calls, due to the need to download the event index
;     
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-05-02 10:36:22 -0700 (Thu, 02 May 2019) $
; $LastChangedRevision: 27171 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/events/mms_event_search.pro $
;-

pro mms_events, quiet=quiet
  common MMSEVENTS, mms_events_search_table, mms_event_table
  
  if ~keyword_set(quiet) then dprint, dlevel=2, 'Building events table; this could take a few minutes...'
  
  mms_init
  
  remote_path = 'https://lasp.colorado.edu/mms/sdc/public/service/latis/'
  remote_file = 'mms_burst_data_segment.csv'

  brst_seg_temp = {VERSION: 1.0000000,$
    DATASTART: 1,$
    DELIMITER: 44b,$
    MISSINGVALUE: 'NaN',$
    COMMENTSYMBOL: "",$
    FIELDCOUNT: 25,$
    FIELDTYPES: [3, 3, 3, 7, 4, 3, 3, 7, 3, 7, 7, 7, 3, 3, 3, 3, $
    3, 3, 3, 3, 3, 3, 3, 3, 7],$
        FIELDNAMES: [ "FIELD01", "FIELD02", "FIELD03", "FIELD04", "FIELD05",$
    "FIELD06", "FIELD07", "FIELD08", "FIELD09", "FIELD10", "FIELD11", "FIELD12",$
    "FIELD13", "FIELD14", "FIELD15", "FIELD16", "FIELD17", "FIELD18", "FIELD19",$
    "FIELD20", "FIELD21", "FIELD22", "FIELD23", "FIELD24", "FIELD25"],$
        FIELDLOCATIONS: [0, 4, 16, 28, 44, 50, 53, 56, 75, 78, 93, 114,$ 
    135, 138, 141, 144, 147, 150, 153, 156, 159, 162, 165, 168, 171] ,$
        FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,$ 
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24]$
  }

  brst_file = spd_download(remote_path=remote_path, remote_file=remote_file, $
    local_file=!mms.local_data_dir+'mms_burst_data_segment.csv', /no_wildcards, $
    SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0, url_username=username, url_password=password, /disable_cdfcheck)

  brst_data = read_ascii(brst_file, template=brst_seg_temp, count=num_items)
  
  descriptions = brst_data.field25
  authors = brst_data.field10
  start_tai = brst_data.field02
  end_tai = brst_data.field03
  
  mms_events_search_table = hash()
  mms_event_table = hash()
  event_count = 0l

  if ~keyword_set(quiet) then dprint, dlevel=2, 'Building event index...'
  
  for event_idx=0l, n_elements(descriptions)-1 do begin
    tokens = strsplit(strlowcase(descriptions[event_idx]), ' ', /extract)
    
    for token_idx=0l, n_elements(tokens)-1 do begin
      if mms_events_search_table.haskey(tokens[token_idx]) then begin
        mms_events_search_table[tokens[token_idx]] = [mms_events_search_table[tokens[token_idx]], event_count]
      endif else begin
        mms_events_search_table[tokens[token_idx]] = [event_count]
      endelse
    endfor
    mms_event_table[event_count] = create_struct('author', authors[event_idx], 'description', descriptions[event_idx], 'start_time', start_tai[event_idx], 'end_time', end_tai[event_idx])
    event_count += 1l
  endfor

  if ~keyword_set(quiet) then dprint, dlevel=2, 'Done building event index...'

end

pro mms_event_search, term, trange=trange, authors=authors, descriptions=descriptions, start_times=start_times, end_times=end_times, quiet=quiet
  common MMSEVENTS, mms_events_search_table, mms_event_table
  if undefined(mms_events_search_table) then mms_events, quiet=quiet
  
  authors = []
  descriptions = []
  start_times = []
  end_times = []
  
  if keyword_set(trange) then trange = time_double(trange)
  
  if undefined(term) then begin
    dprint, dlevel=0, 'Please specify term to search for; e.g., mms_event_search, "current sheet"'
    return
  endif
  
  tokens = strsplit(strlowcase(term), ' ', /extract)

  for token_idx=0, n_elements(tokens)-1 do begin
    if ~mms_events_search_table.haskey(tokens[token_idx]) then begin
      dprint, dlevel=0, 'Term not found: ' + tokens[token_idx]
      return
    endif
    desc = mms_events_search_table[tokens[token_idx]]
    if token_idx eq 0 then begin
      events = desc
    endif else begin
      events = ssl_set_intersection(events, desc)
    endelse
  endfor
  
  if events[0] eq -1 then begin
    dprint, dlevel=0, 'No events found matching: ' + term
    return
  endif

  for event_idx=0, n_elements(events)-1 do begin
    start_time = mms_tai2unix(mms_event_table[events[event_idx]].start_time)
    end_time = mms_tai2unix(mms_event_table[events[event_idx]].end_time)
    if keyword_set(trange) && ~(start_time ge trange[0] and start_time le trange[1]) && ~(end_time le trange[1] and end_time ge trange[0]) then continue
    
    if ~keyword_set(quiet) then print, mms_event_table[events[event_idx]].author + ': ' + mms_event_table[events[event_idx]].description + ' [' + time_string(start_time) + ' to ' + time_string(end_time) + ']'
    
    append_array, authors, mms_event_table[events[event_idx]].author
    append_array, descriptions, mms_event_table[events[event_idx]].description
    append_array, start_times, start_time
    append_array, end_times, end_time
  endfor
end