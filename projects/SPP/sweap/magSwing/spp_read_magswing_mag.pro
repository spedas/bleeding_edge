; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-05-10 11:58:29 -0700 (Thu, 10 May 2018) $
; $LastChangedRevision: 25195 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/magSwing/spp_read_magswing_mag.pro $
; For now this is a crib sheet.

pro spp_read_magswing_mag, rotat = rotat, swing = swing, raster = raster, all = all

  if keyword_set(all) then begin
    rotat = 1
    swing = 1
    raster = 1
  endif else begin
    if keyword_set(rotat) then rotat = 1 else rotat = 0
    if keyword_set(swing) then swing = 1 else swing = 0
    if keyword_set(raster) then raster = 1 else raster = 0
  endelse
  

  if rotat then begin
    ;Read Goddard Mags first
    ;First AB
    path = 'spp/data/sci/sweap/prelaunch/magswing/magdata/Goddard/Rotation_Test_Files/*AB.txt'
    file = spp_file_retrieve(path)
    data_tagsAB = {time:0d, rel_time:0d, mag_a:[0.,0.,0.], mag_b:[0.,0.,0.], grad_ab:[0.,0.,0.]}
    mag_AB_data = read_asc(file, format = data_tagsAB)
    ;Second CD
    path = 'spp/data/sci/sweap/prelaunch/magswing/magdata/Goddard/Rotation_Test_Files/*CD.txt'
    file = spp_file_retrieve(path)
    data_tagsCD = {time:0d, rel_time:0d, mag_c:[0.,0.,0.], mag_d:[0.,0.,0.], grad_cd:[0.,0.,0.]}
    mag_CD_data = read_asc(file, format = data_tagsCD)
    
    ; adjust for difference in years - keeping UTC timestamp
    print, 'Changing Timestamp Format to UTC'
    i = long(0)
    foreach element, mag_AB_data.time do begin
      mag_AB_data[i].time = mag_AB_data[i].time - 2082844800.
      i ++
    endforeach
    i = long(0)
    foreach element, mag_CD_data.time do begin
      mag_CD_data[i].time = mag_CD_data[i].time - 2082844800.
      i ++
    endforeach
    ;save the goddard mag data in tplot format
    store_data, 'rot_AB_', data = mag_AB_data, tagnames = '*'
    store_data, 'rot_CD_', data = mag_CD_data, tagnames = '*'
    
    ;Then read APL mags
    ;pathAPL = '/Users/phyllisw/Desktop/magdata/APL_MAG_Swing_data/RT_20cm_H?/Grad4-????????-??????_filtered.csv'
    pathAPL = 'spp/data/sci/sweap/prelaunch/magswing/magdata/APL%20MAG%20Swing%20data/RT_20cm_H?/Grad4-????????-??????_filtered.csv'
    fileAPL = spp_file_retrieve(pathAPL)
    data_tagsAPL = {sample:0l, mag_1:[0.,0.,0.], mag_2:[0.,0.,0.], mag_3:[0.,0.,0.], mag_4:[0.,0.,0.], range:0.}
    i = long(0)
    offset = replicate(90, n_elements(fileAPL)) ; replace this later with a proper array
    secsIn4hours = 14400.
    mag_APL_data = []
    ;This segment needs to be in an explicit loop because the individual headers must be parsed for time variable
    for i = 0, (n_elements(fileAPL) - 1) do begin
      print, 'Reading File ', fileAPL[i]
      mag_APL_data_holder = read_asc(fileAPL[i], format = data_tagsAPL, nheader = 6, headers = headerval)
      timeSecs = time_double(headerval[0]+headerval[1], tformat = ("MTH-DD-YYYYhh:mm:ss"))
      str_element, /add, mag_APL_data_holder, 'time', mag_APL_data_holder.sample * 0.01 + timeSecs + secsIn4hours - offset[i]
      mag_APL_data = [mag_APL_data, mag_APL_data_holder]
    endfor
    store_data, 'rot_APL_', data = mag_APL_data, tagnames = '*'
    
    ;Now average all magnetic field data & subtract to remove Earth's field from data
    meanField = []
    for i = 0, 3 do begin
      meanField_holder = tsample('rot_APL_MAG_'+strtrim(string(i+1),1),/av, [mag_APL_data[-1].time, mag_APL_data[0].time])
      meanField = [[meanField], [meanField_holder]]
    endfor
    mag1_clean = mag_APL_data.mag_1 - meanField[*,0] # replicate(1,n_elements(mag_APL_data))
    mag2_clean = mag_APL_data.mag_2 - meanField[*,1] # replicate(1,n_elements(mag_APL_data))
    mag3_clean = mag_APL_data.mag_3 - meanField[*,2] # replicate(1,n_elements(mag_APL_data))
    mag4_clean = mag_APL_data.mag_4 - meanField[*,3] # replicate(1,n_elements(mag_APL_data))
    mag_APL_cleaned = {time:mag_APL_data.time, mag_1_clean:mag1_clean, mag_2_clean:mag2_clean, mag_3_clean:mag3_clean, mag_4_clean:mag4_clean}
    store_data, 'rot_APL_', data = mag_APL_cleaned, tagnames = '*'
  endif
  

  if swing then begin
    ;Read Goddard Mags first
    path = 'spp/data/sci/sweap/prelaunch/magswing/magdata/Goddard/Swing_Test_File_Group_?/*AB.txt'
    file = spp_file_retrieve(path)
    data_tagsAB = {time:0d, rel_time:0d, mag_a:[0.,0.,0.], mag_b:[0.,0.,0.], grad_ab:[0.,0.,0.]}
    mag_AB_data = []
    mag_AB_data = read_asc(file, format = data_tagsAB)
    ;Second CD
    path = 'spp/data/sci/sweap/prelaunch/magswing/magdata/Goddard/Swing_Test_File_Group_?/*CD.txt'
    file = spp_file_retrieve(path)
    data_tagsCD = {time:0d, rel_time:0d, mag_c:[0.,0.,0.], mag_d:[0.,0.,0.], grad_cd:[0.,0.,0.]}
    mag_CD_data = []
    mag_CD_data = read_asc(file, format = data_tagsCD)
    ; adjust for difference in years - keeping UTC timestamp
    print, 'Changing Timestamp Format to UTC'
    i = long(0)
    foreach element, mag_AB_data.time do begin
      mag_AB_data[i].time = mag_AB_data[i].time - 2082844800.
      i ++
    endforeach
    i = long(0)
    foreach element, mag_CD_data.time do begin
      mag_CD_data[i].time = mag_CD_data[i].time - 2082844800.
      i ++
    endforeach
    ;save the goddard mag data in tplot format
    store_data, 'swing_AB_', data = mag_AB_data, tagnames = '*'
    store_data, 'swing_CD_', data = mag_CD_data, tagnames = '*'
    
    ;------------------
    ;Then read APL mags
    pathAPL = 'spp/data/sci/sweap/prelaunch/magswing/magdata/APL%20MAG%20Swing%20data/TT_*m_H*/Grad4-????????-??????_filtered.csv'
    fileAPL = spp_file_retrieve(pathAPL)
    print, 'fileAPL ', fileAPL
    print, 'n_elements(fileAPL) ', n_elements(fileAPL)
    data_tagsAPL = {sample:0l, mag_1:[0.,0.,0.], mag_2:[0.,0.,0.], mag_3:[0.,0.,0.], mag_4:[0.,0.,0.], range:0.}
    ;put the following 3 lines in a loop
    i = 0
    offset = replicate(88.5, n_elements(fileAPL)) ; replace this later with a proper array
    secsIn4hours = 14400.
    mag_APL_data = []
    ;This segment needs to be in an explicit loop because the individual headers must be parsed for time variable
    for i = 0, (n_elements(fileAPL) - 1) do begin
      ;print, 'Reading File ', fileAPL[i]
      mag_APL_data_holder = read_asc(fileAPL[i], format = data_tagsAPL, nheader = 7, headers = headerval)
      timeSecs = time_double(headerval[0]+headerval[1], tformat = ("MTH-DD-YYYYhh:mm:ss"))
      str_element, /add, mag_APL_data_holder, 'time', mag_APL_data_holder.sample * 0.01 + timeSecs + secsIn4hours - offset[i]
      mag_APL_data = [mag_APL_data, mag_APL_data_holder]
    endfor
    store_data, 'swing_APL_', data = mag_APL_data, tagnames = '*'

    ;Now average all magnetic field data & subtract to remove Earth's field from data
    ;First mag position:
    meanField = []
    meanData = []
;    for i = 0, 3 do begin
;      meanField_holder = tsample('swing_APL_MAG_'+strtrim(string(i+1),1),/av, [mag_APL_data[0].time, mag_APL_data[-1].time])
;      meanField = [[meanField], [meanField_holder]]
;    endfor
    for i = 0, 3 do begin
      meanField_holder = tsample('swing_APL_MAG_'+strtrim(string(i+1),1),/av, [mag_APL_data[0].time, mag_APL_data[108999].time])
      meanField = [[meanField], [meanField_holder]]
    endfor
    for i = 0, 3 do begin
      meanField_holder = tsample('swing_APL_MAG_'+strtrim(string(i+1),1),/av, [mag_APL_data[109000].time, mag_APL_data[-1].time])
      meanField = [[meanField], [meanField_holder]]
    endfor
    printdat, meanField
;    mag1_clean = mag_APL_data.mag_1 - meanField[*,0] # replicate(1,n_elements(mag_APL_data))
;    mag2_clean = mag_APL_data.mag_2 - meanField[*,1] # replicate(1,n_elements(mag_APL_data))
;    mag3_clean = mag_APL_data.mag_3 - meanField[*,2] # replicate(1,n_elements(mag_APL_data))
;    mag4_clean = mag_APL_data.mag_4 - meanField[*,3] # replicate(1,n_elements(mag_APL_data))
    mag1_clean = mag_APL_data[0:108999].mag_1 - meanField[*,0] # replicate(1,n_elements(mag_APL_data[0:108999]))
    mag2_clean = mag_APL_data[0:108999].mag_2 - meanField[*,1] # replicate(1,n_elements(mag_APL_data[0:108999]))
    mag3_clean = mag_APL_data[0:108999].mag_3 - meanField[*,2] # replicate(1,n_elements(mag_APL_data[0:108999]))
    mag4_clean = mag_APL_data[0:108999].mag_4 - meanField[*,3] # replicate(1,n_elements(mag_APL_data[0:108999]))
    mag1_clean = [[mag1_clean], [(mag_APL_data[109000:-1].mag_1 - meanField[*,4] # replicate(1,n_elements(mag_APL_data[109000:-1])))]]
    mag2_clean = [[mag2_clean], [(mag_APL_data[109000:-1].mag_2 - meanField[*,5] # replicate(1,n_elements(mag_APL_data[109000:-1])))]]
    mag3_clean = [[mag3_clean], [(mag_APL_data[109000:-1].mag_3 - meanField[*,6] # replicate(1,n_elements(mag_APL_data[109000:-1])))]]
    mag4_clean = [[mag4_clean], [(mag_APL_data[109000:-1].mag_4 - meanField[*,7] # replicate(1,n_elements(mag_APL_data[109000:-1])))]]
;    mag1_scalar = sqrt(transpose(mag1_clean)#mag1_clean)
;    mag2_scalar = sqrt(transpose(mag2_clean)#mag2_clean)
;    mag3_scalar = sqrt(transpose(mag3_clean)#mag3_clean)
;    mag4_scalar = sqrt(transpose(mag4_clean)#mag4_clean)
    mag_APL_cleaned = {time:mag_APL_data.time, mag_1_clean:mag1_clean, mag_2_clean:mag2_clean, mag_3_clean:mag3_clean, mag_4_clean:mag4_clean};,$
;       mag_1_scalar: mag1_scalar, mag_2_scalar: mag2_scalar, mag_3_scalar: mag3_scalar, mag_4_scalar: mag4_scalar}
    store_data, 'swing_APL_', data = mag_APL_cleaned, tagnames = '*'
  endif
end
