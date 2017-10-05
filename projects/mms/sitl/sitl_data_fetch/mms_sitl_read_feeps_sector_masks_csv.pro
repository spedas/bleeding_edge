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
;     Updated to use CSV files, 8/1/2016; files must be in the same
;     directory as this routine.
;
; $LastChangedBy: rickwilder $
; $LastChangedDate: 2017-08-09 13:51:06 -0700 (Wed, 09 Aug 2017) $
; $LastChangedRevision: 23769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_read_feeps_sector_masks_csv.pro $
;-

function mms_sitl_read_feeps_sector_masks_csv 
    masks = hash()

    ; assuming the CSV files containing the sector mask data are
    ; in the same directory as this file
    feeps_info = routine_info('mms_sitl_read_feeps_sector_masks_csv', /source, /function)
    path = file_dirname(feeps_info.path) + PATH_SEP()

    for mms_sc = 1, 4 do begin
      csv_file = path+'MMS'+strcompress(string(mms_sc), /rem)+'_SITL_FEEPS_ContaminatedSectors_20160709.csv'
  
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