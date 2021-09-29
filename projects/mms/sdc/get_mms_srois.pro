;+
; Query a LaTiS web service to get the SROIs whose
; start_time falls within the given time range.
; SROIs include predicted (future) values, which are subject to change.
; 
; start_time and end_time arguments are optional. If specified, they
; must be UTC dates or datetimes in a format similar to the following:
;   2020-02-15/08:21:01.000
; The '/' can optionally be a space or 'T'.
; The time part can be omitted. Fractional seconds are optional.
; If neither argument is specified, SROIs for all times are returned.
; Comparison to start_time is inclusive (>=), to end_time is exclusive (<).
; 
; sc_id is optional. If omitted, results are returned for all spacecraft.
; Otherwise, it must be one of 'mms1', 'mms2', 'mms3', 'mms4', case-insensitive.
; 
; Normally returns an array of struct with the following fields derived
; from the mms_events_view LaTiS dataset.
; 
; start_time : string, UTC datetime string, e.g., '2020-02-15/08:21:01.000'
; end_time   : string, UTC datetime string
; sc_id      : string, 'mms1', etc. 
; orbit      : int, MMS orbit number at start_time_utc
; public     : bool, if set, executes the latis query as a public user
; 
; The array is always sorted by start_time ascending.
; 
; Can return an integer error code or -1 if no data are found.
; 
; Example:
; IDL> srois = get_mms_srois(start_time='2020-02-15/08:21:01.000', sc_id='mms1')
; IDL> help,srois
; SROIS           STRUCT    = -> SROI Array[60]
; IDL> help,srois[0]
; ** Structure SROI, 4 tags, length=56, data length=52:
; START_TIME      STRING    '2020-02-15/08:21:01.000'
; END_TIME        STRING    '2020-02-15/17:54:03.000'
; SC_ID           STRING    'mms1'
; ORBIT           LONG              1084
;-
function get_mms_srois, start_time=start_time, end_time=end_time, sc_id=sc_id, public=public

  ;LaTiS URL components
  dataset = 'mms_events_view'
  ;public unauthenticated path (works even if basic auth enabled on connection)
  path = "mms/sdc/public/service/latis/" + dataset + ".csv"
  
  ;Construct the LaTiS query
  query = 'start_time_utc,end_time_utc,sc_id,start_orbit&event_type=SROI'
  if n_elements(start_time) gt 0 then begin
    ;convert to standard ISO format as accepted by LaTiS
    query += '&start_time_utc>=' + strjoin(strsplit(start_time, '/', /extract), 'T')
  endif
  if n_elements(end_time) gt 0 then begin
    ;time filtering is always to the start_time_utc field of the data
    query += '&start_time_utc<' + strjoin(strsplit(end_time, '/', /extract), 'T')
  endif
  if n_elements(sc_id) gt 0 then begin
    query += '&sc_id=' + strlowcase(sc_id)
  endif
  
  ;Define the structure template for the SROI record.
  sroi_struct = { sroi,  $
    start_time  : "",  $
    end_time    : "",  $
    sc_id       : "", $
    orbit       : 0L  $
  }
  
  ;Execute the query. Get the results back in an array of structures,
  ;  or an error code, or -1 if no results were found.
  result = execute_latis_query(path, query, sroi_struct, public=public)
  
  if isa(result, /array) then begin
    ;Convert the datetime strings to convenient SPEDAS format
    for i=0, n_elements(result)-1 do begin
      result[i].start_time = strjoin(strsplit(result[i].start_time, 'T', /extract), '/')
      result[i].end_time = strjoin(strsplit(result[i].end_time, 'T', /extract), '/')
    endfor
  endif
  
  return, result
end
 