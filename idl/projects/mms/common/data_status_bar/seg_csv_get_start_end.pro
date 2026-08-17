pro seg_csv_get_start_end,filename=filename,unix_starts=unix_starts, unix_ends=unix_ends

  ; This old template was wrong -- for some reason it was trying to use both comma delimiters and fixed field locations.
  ; When the segment IDs started to use more digits, the tamplate didn't match the input and the TAI start/end times
  ; weren't being read correctly.  
  ;
  ;
  ;brst_seg_temp = { VERSION: 1.0000000, $
  ;  DATASTART: 1, $
  ;  DELIMITER: 44b, $
  ;  MISSINGVALUE: "", $
  ;  COMMENTSYMBOL: "", $
  ;  FIELDCOUNT: 13, $
  ;  FIELDTYPES: [0, 3, 3, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0], $
  ;  FIELDNAMES: [ "FIELD01", "TAISTARTTIME", $
  ;  "TAIENDTIME", "FIELD04", "FIELD05", "FIELD06", $
  ;  "FIELD07", "STATUS", "FIELD09", "FIELD10", $
  ;  "FIELD11", "FIELD12", "FIELD13"] $,
  ;  FIELDLOCATIONS: [0, 4, 16, 28, 44, 50, 53, 56, 75, 78, 93, 114, 135], $
  ;  FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  $
  ;}

  ; This corrected template seems to work for both early in the mission and for more recent time intervals.
  ; JWL 2026-08-14 
  
  brst_seg_temp = { $
    VERSION:        1.0, $
    DATASTART:      1L, $
    DELIMITER:      44B, $       ; ASCII comma
    MISSINGVALUE:   '', $
    COMMENTSYMBOL:  '', $
    FIELDCOUNT:     8L, $
    FIELDTYPES:     [7L, 7L, 7L, 0L, 0L, 0L, 0L, 7L], $
    FIELDNAMES:     ['DATASEGMENTID', 'TAISTARTTIME', 'TAIENDTIME', $
    'FIELD04', 'FIELD05', 'FIELD06', 'FIELD07', 'STATUS'], $
    FIELDLOCATIONS: LONARR(8), $
    FIELDGROUPS:    LINDGEN(8) $
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
    tai_start = LONG64(brst_data.TAISTARTTIME[complete_idxs])
    tai_end = LONG64(brst_data.TAIENDTIME[complete_idxs])
    unix_starts=mms_tai2unix(tai_start)
    unix_ends=mms_tai2unix(tai_end)
  endif else begin
    dprint,dlevel=0,"seg_csv_get_start_end: No matching intervals found in ",filename
    unix_starts=[]
    unix_ends=[]
  endelse
  return

end