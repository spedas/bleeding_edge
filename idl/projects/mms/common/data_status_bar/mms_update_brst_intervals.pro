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
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-03-09 13:47:54 -0800 (Thu, 09 Mar 2023) $
; $LastChangedRevision: 31614 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_update_brst_intervals.pro $
;-

pro mms_update_brst_intervals

  mms_init

  ; grab ~6 months of burst intervals at a time
  start_interval = '2015-03-01'
  end_interval = time_double(start_interval) + 6.*30*24*60*60
  
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
  
  while time_double(start_interval) le time_double(systime(/seconds)) do begin
    start_str = time_string(start_interval, tformat='DD-MTH-YYYY')
    end_str = time_string(end_interval, tformat='DD-MTH-YYYY')
    print, '*** now grabbing updates for ' + start_str + ' - ' +  end_str
    ;remote_path = 'https://lasp.colorado.edu/mms/sdc/sitl/latis/dap/'
    remote_path = 'https://lasp.colorado.edu/mms/sdc/public/service/latis/'
    remote_file = 'mms_burst_data_segment.csv?FINISHTIME>='+start_str+'&FINISHTIME<'+end_str
    
    brst_file = spd_download(remote_path=remote_path, remote_file=remote_file, $
      local_file=!mms.local_data_dir+'mms_burst_data_segment.csv', /no_wildcards, $
      SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0, url_username=username, url_password=password)

    brst_data = read_ascii(brst_file, template=brst_seg_temp, count=num_items)
  
    if ~is_struct(brst_data) then break
    
    complete_idxs = where(brst_data.status eq 'COMPLETE+FINISHED', c_count)
    if c_count ne 0 then begin
      tai_start = brst_data.TAISTARTTIME[complete_idxs]
      tai_end = brst_data.TAIENDTIME[complete_idxs]
  
      append_array, unix_start, mms_tai2unix(tai_start)
      append_array, unix_end, mms_tai2unix(tai_end)
    endif

    print, '*** done grabbing updates for ' + start_str + ' - ' +  end_str
    start_interval = end_interval
    end_interval = time_double(start_interval) + 6.*30*24*60*60
  endwhile

  brst_intervals = {start_times: unix_start, end_times: unix_end}
  save, brst_intervals, filename=!mms.local_data_dir + '/mms_brst_intervals.sav'
  dprint, dlevel = 0, 'Brst intervals updated! Last interval in the file: ' + time_string(unix_start[n_elements(unix_start)-1]) + ' to ' + time_string(unix_end[n_elements(unix_end)-1])

end