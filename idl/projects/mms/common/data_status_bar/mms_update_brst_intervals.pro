;+
;
;  This routine will create a save file, mms_brst_intervals.sav in
;  the directory:
;
;        !mms.local_data_dir + '/'
;
; containing a structure with the tags "start_times" and "end_times".
; These are the start/end times of the brst  intervals as
; specified in the mms_burst_data_segment.csv file
;
; This is meant to be run by an automated script that rebuilds the
; mms_brst_intervals.sav file and uploads it to spedas.org:
;
;     http://spedas.org/mms/mms_brst_intervals.sav
;
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-07-17 17:19:03 -0700 (Fri, 17 Jul 2026) $
; $LastChangedRevision: 34654 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_update_brst_intervals.pro $
;-

pro mms_update_brst_intervals, trange=trange, start_times=start_times, end_times=end_times

  mms_init

  padding=2*86400
  tr_dbl = time_double(trange)
  tr_padded = [tr_dbl[0] - padding, tr_dbl[1] + padding]
  
  ; Get a set of 1 calendar month time ranges covering the padded time range
  
  monthly_intervals = spd_month_intervals(tr_padded[0], tr_padded[1])
  
  if n_elements(monthly_intervals) lt 2 then begin
    dprint,dlevel=0,'Unable to compute monthly intervals for input trange: ', trange
    return
  endif

  n_months = n_elements(monthly_intervals)/2
  
  status = mms_login_lasp(username=username, password=password)

  brst_seg_temp = { VERSION: 1.0000000, $
    DATASTART: 1, $
    DELIMITER: 44b, $
    MISSINGVALUE: "", $
    COMMENTSYMBOL: "", $
    FIELDCOUNT: 13, $
    FIELDTYPES: [0, 3, 3, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0], $
    FIELDNAMES: [ "FIELD01", "TAISTARTTIME", $
    "TAIENDTIME", "FIELD04", "FIELD05", "FIELD06", $
    "FIELD07", "STATUS", "FIELD09", "FIELD10", $
    "FIELD11", "FIELD12", "FIELD13"], $
    FIELDLOCATIONS: [0, 4, 16, 28, 44, 50, 53, 56, 75, 78, 93, 114, 135], $
    FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  $
  }
  
  my_start_times=[]
  my_end_times=[]
  for i=0, n_months-1 do begin
    ; Get interval times and save to monthly files
    start_unix = monthly_intervals[0,i]
    end_unix = monthly_intervals[1,i]
    start_tai = mms_unix2tai(start_unix)
    end_tai = mms_unix2tai(end_unix)
    start_str = time_string(start_unix, tformat='YYYY_MM_DD')
    end_str = time_string(end_unix, tformat='YYYY_MM_DD')
    local_filename = 'segments_'+start_str+'_'+end_str+'.csv'
    print, '*** now grabbing updates for ' + start_str + ' - ' +  end_str
    local_filename=spd_addslash(!mms.local_data_dir)+'burst_segs/segments_'+start_str+'_'+end_str+".csv"
    remote_path = 'https://lasp.colorado.edu/mms/sdc/public/service/latis/'
    remote_file = 'mms_burst_data_segment.csv?TAIENDTIME%3E='+strtrim(string(start_tai),2)+'&TAISTARTTIME%3C'+strtrim(string(end_tai),2)

    brst_file = spd_download(remote_path=remote_path, remote_file=remote_file, $
      local_file=local_filename, /no_wildcards, $
      SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0, url_username=username, url_password=password)
    ; Read this file and accumulate merge its start/end times into the master list
    seg_csv_get_start_end,filename=local_filename, unix_starts=this_start, unix_ends=this_end
    append_array,my_start_times,this_start
    append_array,my_end_times,this_end
  endfor
  
  start_times=my_start_times
  end_times=my_end_times
  return
  

end