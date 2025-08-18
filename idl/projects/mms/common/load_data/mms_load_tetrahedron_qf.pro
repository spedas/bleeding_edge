;+
; PROCEDURE:
;         mms_load_tetrahedron_qf
;
; PURPOSE:
;         Loads the tetrahedron quality factor from the LASP SDC
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-07-20 16:20:12 -0700 (Thu, 20 Jul 2017) $
;$LastChangedRevision: 23686 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_tetrahedron_qf.pro $
;-

pro mms_load_tetrahedron_qf, trange = trange, suffix=suffix
    if undefined(suffix) then suffix = ''
    
    mms_init, local_data_dir = local_data_dir
    
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
    else tr = timerange()
 
    start_time = time_double(tr[0])-60*60*24.
    end_time = time_double(tr[1])

    ; check if end date is anything other than 00:00:00, if so
    ; add a day to the end time to ensure that all data is downloaded
    end_struct = time_struct(end_time)
    if (end_struct.hour GT 0) or (end_struct.min GT 0) then add_day = 60*60*24. else add_day = 0. 
    
    start_time_str = time_string(start_time, tformat='YYYY-MM-DD')
    end_time_str = time_string(end_time+add_day, tformat= 'YYYY-MM-DD')
 
    prod = 'defq'
    public = 1
    file_dir = !mms.local_data_dir + 'ancillary/tetrahedron_qf/'
    
    ; make sure the directory exists
    dir_search = file_search(file_dir, /test_directory)
    if dir_search eq '' then file_mkdir2, file_dir
    
    qf_template = { VERSION: 1.00000, $
      DATASTART: 11, $
      DELIMITER: 32b, $
      MISSINGVALUE: !values.D_NAN, $
      COMMENTSYMBOL: '', $
      FIELDCOUNT: 4, $
      FIELDTYPES: [7, 4, 4, 3], $
      FIELDNAMES: ['epoch', 'epoch_tai', 'qf', 'scale'], $
      FIELDLOCATIONS: [0, 25, 43, 52], $
      FIELDGROUPS: [0, 1, 2, 3]}
    
    ; grab the file list
    ancillary_file_info = mms_get_ancillary_file_info(sc_id='mms', product=prod, start_date=start_time_str, end_date=end_time_str, public=public)

    if is_string(ancillary_file_info) then begin
        ; get the filenames from the JSON
        remote_file_info = mms_parse_json(ancillary_file_info)
        
        filename = remote_file_info.filename
        num_filenames = n_elements(filename)
        
        ; grab the files
        for file_idx = 0, num_filenames-1 do begin
            dprint, dlevel = 0, 'Downloading ' + filename[file_idx]
            status = get_mms_ancillary_file(filename=filename[file_idx], local_dir=file_dir, public=public)
            
            if status eq 0 then append_array, files, file_dir + filename[file_idx]
        endfor
        
        if ~undefined(files) then begin
            for file_idx=0, n_elements(files)-1 do begin
                qf_data = read_ascii(files[file_idx], template=qf_template, count=num_items)
                append_array, time_data, time_double(qf_data.Epoch, tformat='YYYY-DOY/hh:mm:ss.fff')
                append_array, tetrahedron_qfs, qf_data.qf
            endfor
            idx=[uniq(time_data, sort(time_data))]
            time_values = time_data[idx]
            tqfs = tetrahedron_qfs[idx]
            
        endif
    endif else begin
        dprint, dlevel = 0, 'No tetrahedron quality factor found for this trange: ' + start_time_str + ' - ' + end_time_str
    endelse
    
    if ~undefined(time_data) && ~undefined(tetrahedron_qfs) then begin
        store_data, 'mms_tetrahedron_qf'+suffix, data={x: time_values, y: tqfs}
        ; clip down to the requested time range
        time_clip, 'mms_tetrahedron_qf'+suffix, tr[0], tr[1], /replace
    endif
    
end