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

  monthly_intervals = spd_month_intervals(start_time, end_time)
  
  ;LaTiS URL components
  dataset = 'mms_events_view'
  ;public unauthenticated path (works even if basic auth enabled on connection)
  path = "mms/sdc/public/service/latis/" + dataset + ".csv"
  
  month_count = n_elements(monthly_intervals)/2-1
  for i=0,month_count do begin
    month_start=monthly_intervals[0,i]
    month_end=monthly_intervals[1,i]
    month_start_str=time_string(month_start,tformat='YYYY_MM_DDThh:mm:ss')
    month_end_str=time_string(month_end,tformat='YYYY_MM_DDThh:mm:ss')
    ; colons in timestamps need to be url encoded
    month_start_url=time_string(month_start,tformat='YYYY-MM-DDThh%3Amm%3Ass')
    month_end_url=time_string(month_end,tformat='YYYY-MM-DDThh%3Amm%3Ass')

    month_filename=time_string(month_start,tformat='/srois/monthly_YYYY_MM.csv')

    ;Construct the LaTiS query
    query = '?start_time_utc,end_time_utc,sc_id,start_orbit&event_type=SROI'
    if n_elements(start_time) gt 0 then begin
      ;convert to standard ISO format as accepted by LaTiS
      query += '&start_time_utc%3E=' + month_start_url
    endif
    if n_elements(end_time) gt 0 then begin
      ;time filtering is always to the start_time_utc field of the data
      query += '&start_time_utc%3C' + month_end_url
    endif
    if n_elements(sc_id) gt 0 then begin
      query += '&sc_id=' + strlowcase(sc_id)
    endif

    print, '*** now grabbing SROI updates for ' + month_start_str + ' - ' +  month_end_str
    local_filename=spd_addslash(!mms.local_data_dir)+sc_id+month_filename
    remote_path = 'https://lasp.colorado.edu/mms/sdc/public/service/latis/'
    remote_file = dataset+".csv"+query

    brst_file = spd_download(remote_path=remote_path, remote_file=remote_file, $
      local_file=local_filename, /no_wildcards, $
      SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0)
    
  endfor
  
  
  return, 1
end
 