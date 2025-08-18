;+
;
;  This routine will create a save file, mms_fast_intervals.sav in 
;  the directory: 
;  
;        !mms.local_data_dir + '/abs/'
;        
; containing a structure with the tags "start_times" and "end_times".
; These are the start/end times of the fast survey intervals as 
; specified in the automated burst system (ABS) files
; 
; This is meant to be run by an automated script that rebuilds the 
; mms_fast_intervals.sav file and uploads it to spedas.org:
; 
;     http://spedas.org/mms/mms_fast_intervals.sav
;
; Note: in order to run this script, you need a sav file in
;       your working directory called 'mms_login_info_for_updating_abs.sav'
;       containing your login information. 
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-05-30 12:46:17 -0700 (Fri, 30 May 2025) $
; $LastChangedRevision: 33353 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_update_fast_intervals.pro $
;-

pro mms_update_fast_intervals
    mms_init
    
    start_date = '2015-01-01'
    end_date = time_string(systime(/seconds), tformat='YYYY-MM-DD')
    
    ; login first
    status = mms_login_lasp(login_info = 'mms_auth_info.sav')
    
    filenames = mms_get_abs_file_names(start_date=start_date, end_date=end_date)

    file_mkdir2, spd_addslash(!mms.local_data_dir) + 'abs/'
    for file_idx = 0, n_elements(filenames)-1 do begin
        this_file = (strsplit(filenames[file_idx], '/', /extract))[-1]
        status = get_mms_abs_selections(filename = this_file, local_dir = spd_addslash(!mms.local_data_dir) + 'abs/')
        append_array, sav_files, this_file
    endfor
    
    for sav_file_idx = 0, n_elements(sav_files)-1 do begin
        restore, spd_addslash(!mms.local_data_dir) + 'abs/' + sav_files[sav_file_idx]
        if is_struct(fomstr) then begin
          if tag_exist(fomstr, 'timestamps') then begin
            append_array, start_times, mms_tai2unix(fomstr.timestamps[0])
            append_array, end_times, mms_tai2unix(fomstr.timestamps[n_elements(fomstr.timestamps)-1])
          endif
        endif
    endfor
    
    fast_intervals = {start_times: start_times, end_times: end_times}
    save, fast_intervals, filename=spd_addslash(!mms.local_data_dir) + 'abs/' + 'mms_fast_intervals.sav'
    dprint, dlevel = 0, 'Fast survey intervals updated! Last interval in the file: ' + time_string(start_times[0]) + ' to ' + time_string(end_times[0])
end