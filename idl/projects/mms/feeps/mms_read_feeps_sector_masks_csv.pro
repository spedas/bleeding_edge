;+
;
; FUNCTION:
;         mms_read_feeps_sector_masks_csv
;
; PURPOSE:
;         Returns the FEEPS sectors to mask due to sunlight contamination
;
; OUTPUT:
;         Hash table containing the sectors to mask for each spacecraft and sensor ID
;
; EXAMPLE:
;     ; to get the masks for MMS1, top sensor = 1:
;     IDL> masks = mms_read_feeps_sector_masks_csv()
;
;     ; note the concatenation: mms+probe#+imask+[t or b]+sensorID
;     IDL> mms1_top_sensor1 = masks['mms1imaskt1']
;     IDL> mms1_top_sensor1
;         2       3       4       5       6      20      21
;
;
; NOTES:
;     Will only work in IDL 8.0+, due to the hash table data structure
;
;     Updated to use CSV files, 8/1/2016
;     
;     Updated to use the CSV file closest to the requested trange (uses trange[0]), 8/15/2017
;     
;     
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-02-28 16:59:47 -0800 (Fri, 28 Feb 2025) $
; $LastChangedRevision: 33160 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_read_feeps_sector_masks_csv.pro $
;-

function mms_read_feeps_sector_masks_csv, trange=trange
    masks = hash()

    ; assuming the CSV files containing the sector mask data are
    ; in the same directory as this file
    feeps_info = routine_info('mms_read_feeps_sector_masks_csv', /source, /function)
    path = file_dirname(feeps_info.path) + PATH_SEP()

    dates = [1447200000.0000000, $ ; 11/11/2015
             1468022400.0000000, $ ; 7/9/2016
             1477612800.0000000, $ ; 10/28/2016
             1496188800.0000000, $ ; 5/31/2017
             1506988800.0000000, $ ; 10/3/2017
             1538697600.0000000, $ ; 10/5/2018
             1642032000.0000000, $ ; 1/13/2022
             1651795200.0000000, $ ; 5/6/2022
             1660521600.0000000, $ ; 8/15/2022            
             1706832000.0000000, $ ; 2/02/2024
             1721779200.0000000, $ ; 07/24/2024           
             1739664000.0000000]   ; 02/16/2025    
                      
    nearest_date = find_nearest_neighbor(dates, time_double(trange[0]), /allow_outside)
    dprint, dlevel = 2, 'Removing sun contamination using the file: MMS#_FEEPS_ContaminatedSectors_'+time_string(nearest_date, tformat='YYYYMMDD')+'.csv
    
    for mms_sc = 1, 4 do begin
      csv_file = path+'sun/MMS'+strcompress(string(mms_sc), /rem)+'_FEEPS_ContaminatedSectors_'+time_string(nearest_date, tformat='YYYYMMDD')+'.csv'
  
      test = read_csv(csv_file)
      
      for i = 0, 11 do begin
          mask_vals = []
          for val_idx = 0, n_elements(test.(i))-1 do if test.(i)[val_idx] eq 1 then append_array, mask_vals, val_idx
          masks['mms'+strcompress(string(mms_sc), /rem)+'imaskt'+strcompress(string(i+1), /rem)] = mask_vals
      endfor
      
      for i = 0, 11 do begin
        mask_vals = []
        for val_idx = 0, n_elements(test.(i+12))-1 do if test.(i+12)[val_idx] eq 1 then append_array, mask_vals, val_idx
        masks['mms'+strcompress(string(mms_sc), /rem)+'imaskb'+strcompress(string(i+1), /rem)] = mask_vals
      endfor
    endfor
    
    return, masks
end