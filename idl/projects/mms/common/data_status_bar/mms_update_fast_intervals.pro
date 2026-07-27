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
; $LastChangedDate: 2026-07-22 17:28:56 -0700 (Wed, 22 Jul 2026) $
; $LastChangedRevision: 34663 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_update_fast_intervals.pro $
;-

pro mms_update_fast_intervals, trange=trange, unix_start=my_unix_start, unix_end=my_unix_end
    mms_init
    
    start_date = time_string(trange[0],tformat="YYYY-MM-DD")
    end_date = time_string(trange[1], tformat='YYYY-MM-DD')
    
    ; login first
    status = mms_login_lasp(login_info = 'mms_auth_info.sav')
    
    filenames = mms_get_abs_file_names(start_date=start_date, end_date=end_date)
    ; The SDC query returns them in reverse chronological order, so sort before loading
    idx=bsort(filenames)
    filenames=filenames[idx]

    file_mkdir2, spd_addslash(!mms.local_data_dir) + 'abs/'
    for file_idx = 0, n_elements(filenames)-1 do begin
        this_file = (strsplit(filenames[file_idx], '/', /extract))[-1]
        print,'Downloading ',this_file
        status = get_mms_abs_selections(filename = this_file, local_dir = spd_addslash(!mms.local_data_dir) + 'abs/')
        append_array, sav_files, this_file
    endfor
    
    last_start = -1
    first = 1
    for sav_file_idx = 0, n_elements(sav_files)-1 do begin
        abs_get_start_end,filename=spd_addslash(!mms.local_data_dir)+'abs/' + sav_files[sav_file_idx], unix_starts=unix_starts, unix_ends=unix_ends
        if (first eq 0) and (unix_starts le last_start) then begin
          dprint,dlevel=0, "Skipping duplicate or out-of-order segment start time "+time_string(unix_starts)
        endif else begin
          append_array, start_times, unix_starts
          append_array, end_times, unix_ends
          last_start = unix_starts
          first=0
        endelse
        ; Can we stop searching?
        if unix_starts gt trange[1] then begin
          dprint,dlevel=0, "Current segment time "+time_string(unix_starts)+" beyond end of requested time range "+time_string(tr[1])+", quitting search."
        endif
    endfor
    
    fast_intervals = {start_times: start_times, end_times: end_times}
    my_unix_start=start_times
    my_unix_end=end_times
    last_seg = n_elements(start_times)-1
    if last_seg gt 0 then begin
      dprint, dlevel = 0, 'Fast survey intervals updated! Last interval: ' + time_string(start_times[last_seg]) + ' to ' + time_string(end_times[last_seg])
    endif else begin
      dprint, dlevel = 0, "No fast survey intervals found in specified time range."
    endelse
end