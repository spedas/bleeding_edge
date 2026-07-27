pro seg_csv_get_start_end,filename=filename,unix_starts=unix_starts, unix_ends=unix_ends

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

  brst_data=0
  if file_test(filename) eq 1 then begin
    brst_data = read_ascii(filename, template=brst_seg_temp, count=num_items)
  endif else begin
    dprint,dlevel=0,'seg_csv_get_start_end: File not found: ' + filename
    unix_starts=[]
    unix_ends=[]
    return
  endelse

  if ~is_struct(brst_data) then begin
    dprint,dlevel=0,"seg_csv_get_start_end: No burst segments found in "+filename
    unix_starts=[]
    unix_ends=[]
    return
  endif

  complete_idxs = where(brst_data.status eq 'COMPLETE+FINISHED', c_count)
  if c_count ne 0 then begin
    tai_start = brst_data.TAISTARTTIME[complete_idxs]
    tai_end = brst_data.TAIENDTIME[complete_idxs]
    unix_starts=mms_tai2unix(tai_start)
    unix_ends=mms_tai2unix(tai_end)
  endif else begin
    dprint,dlevel=0,"seg_csv_get_start_end: No matching intervals found in ",filename
    unix_starts=[]
    unix_ends=[]
  endelse
  return

end