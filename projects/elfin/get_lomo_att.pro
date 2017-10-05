pro get_lomo_att, tr=tr

  ;timespan, '2016-07-01'
  ;tr=timerange()

  ;----------------
  ; GET LOMO Data
  ; ---------------
  ; extract data items from strings
  ;elf_init
  restore, file='template_lomo.sav'

  hrs = ['00','01','02','03','04','05','06','07','08','09','10', $
    '11','12','13','14','15','16','17','18','19','20', $
    '21','22','23']

  ts = time_string(tr[0])
  yr = strmid(ts,0,4)
  mo = strmid(ts,5,2)
  day = strmid(ts,8,2)
  date1 = yr+mo+day

  for i=3,23 do begin
    local_file = !elf.local_data_dir + 'bi/' + date1 + '/orient_coord-' + strmid(date1,2) + '-' + hrs[i] + '.dat'
    if file_test(local_file) EQ 0 then continue
    data = -1
    data = READ_ASCII(local_file, TEMPLATE=temp_att)
    if ~is_struct(data) && data EQ -1 then begin
      print, '***** SKIPPING: '+local_file
      stop
      continue
    endif

    date = data.field1.replace(' ','/')
    lomo_times = time_double(date.substring(1,19)) ;+ 3*3600.
    xyz = make_array(n_elements(lomo_times), 3, /double)
    xyz[*,0] = double(data.field3.replace('"', ''))/1000.
    xyz[*,1] = double(data.field4.replace('"', ''))/1000.
    xyz[*,2] = double(data.field5.replace('"', ''))/1000.
    vxyz = make_array(n_elements(lomo_times), 3, /double)
    vxyz[*,0] = double(data.field6.replace('"', ''))/1000.
    vxyz[*,1] = double(data.field7.replace('"', ''))/1000.
    vxyz[*,2] = double(data.field8.replace('"', ''))/1000.

    ; translate att data to ???? data from GEO to GSM coordinates
    ;store_data, 'lomo_pos_geo', data={x:lomo_times, y:xyz}
    ;get_data, 'lomo_pos_geo', data=dgeo
    ;cotrans, 'lomo_pos_geo', 'lomo_pos_gei', /geo2gei
    ;get_data, 'lomo_pos_gei', data=dgei
    ;cotrans, 'lomo_pos_gei', 'lomo_pos_gse', /gei2gse
    ;get_data, 'lomo_pos_gse', data=dgse
    ;cotrans, 'lomo_pos_gse', 'lomo_pos_gsm', /gse2gsm
    ;get_data, 'lomo_pos_gsm', data=dgsm
    ;get_data, 'lomo_pos_gsm', data=d

    append_array, lomo_time, lomo_times
    append_array, lomo_roll, d.y[*,0]
    append_array, lomo_pitch, d.y[*,1]
    append_array, lomo_yaw, d.y[*,2]

    ; translate velocity data from GEO to GSM coordinates
    ;store_data, 'lomo_vel_geo', data={x:lomo_times, y:vxyz}
    ;get_data, 'lomo_vel_geo', data=vgeo
    ;cotrans, 'lomo_vel_geo', 'lomo_vel_gei', /geo2gei
    ;get_data, 'lomo_vel_gei', data=vgei
    ;cotrans, 'lomo_vel_gei', 'lomo_vel_gse', /gei2gse
    ;get_data, 'lomo_vel_gse', data=vgse
    ;cotrans, 'lomo_vel_gse', 'lomo_vel_gsm', /gse2gsm
    ;get_data, 'lomo_vel_gsm', data=vgsm
    ;get_data, 'lomo_vel_gsm', data=v

    ;append_array, lomo_vxgsm, v.y[*,0]
    ;append_array, lomo_vygsm, v.y[*,1]
    ;append_array, lomo_vzgsm, v.y[*,2]

  endfor

  ts = time_string(tr[0]+86400.)
  yr = strmid(ts,0,4)
  mo = strmid(ts,5,2)
  day = strmid(ts,8,2)
  date0 = yr+mo+day

  for i=0,2 do begin
    ;if date0 EQ '20160831' then continue

    local_file = !elf.local_data_dir + 'bi/' + date0 + '/orient_coord-' + strmid(date0,2) + '-' + hrs[i] + '.dat'
    if file_test(local_file) EQ 0 then continue
    data = -1
    data = READ_ASCII(local_file, TEMPLATE=temp_att)
    if ~is_struct(data) && data EQ -1 then begin
      print, '***** SKIPPING: '+local_file
      stop
      continue
    endif
    date = data.field1.replace(' ','/')
    lomo_times = time_double(date.substring(1,19)) ;+ 3*3600.
    xyz = make_array(n_elements(lomo_times), 3, /double)
    xyz[*,0] = double(data.field3.replace('"', ''))/1000.
    xyz[*,1] = double(data.field4.replace('"', ''))/1000.
    xyz[*,2] = double(data.field5.replace('"', ''))/1000.
    vxyz = make_array(n_elements(lomo_times), 3, /double)
    vxyz[*,0] = double(data.field6.replace('"', ''))/1000.
    vxyz[*,1] = double(data.field7.replace('"', ''))/1000.
    vxyz[*,2] = double(data.field8.replace('"', ''))/1000.

    ; translate data from GEO to GSM coordinates
    ;store_data, 'lomo_pos_geo', data={x:lomo_times, y:xyz}
    ;get_data, 'lomo_pos_geo', data=dgeo
    ;cotrans, 'lomo_pos_geo', 'lomo_pos_gei', /geo2gei
    ;get_data, 'lomo_pos_gei', data=dgei
    ;cotrans, 'lomo_pos_gei', 'lomo_pos_gse', /gei2gse
    ;get_data, 'lomo_pos_gse', data=dgse
    ;cotrans, 'lomo_pos_gse', 'lomo_pos_gsm', /gse2gsm
    ;get_data, 'lomo_pos_gsm', data=dgsm
    ;get_data, 'lomo_pos_gsm', data=d

    append_array, lomo_time, d.x
    append_array, lomo_roll, d.y[*,0]
    append_array, lomo_pitch, d.y[*,1]
    append_array, lomo_yaw, d.y[*,2]

    ; translate velocity data from GEO to GSM coordinates
    ;store_data, 'lomo_vel_geo', data={x:lomo_times, y:vxyz}
    ;get_data, 'lomo_vel_geo', data=vgeo
    ;cotrans, 'lomo_vel_geo', 'lomo_vel_gei', /geo2gei
    ;get_data, 'lomo_vel_gei', data=vgei
    ;cotrans, 'lomo_vel_gei', 'lomo_vel_gse', /gei2gse
    ;get_data, 'lomo_vel_gse', data=vgse
    ;cotrans, 'lomo_vel_gse', 'lomo_vel_gsm', /gse2gsm
    ;get_data, 'lomo_vel_gsm', data=vgsm
    ;get_data, 'lomo_vel_gsm', data=v

    ;append_array, lomo_vxgsm, v.y[*,0]
    ;append_array, lomo_vygsm, v.y[*,1]
    ;append_array, lomo_vzgsm, v.y[*,2]

  endfor

  lomo_att = make_array(n_elements(lomo_time), 3, /double)
  lomo_att[*,0] = lomo_xgsm
  lomo_att[*,1] = lomo_ygsm
  lomo_att[*,2] = lomo_zgsm
  store_data, 'lomo_att', data={x:lomo_time, y:lomo_att}

  ;lomo_vel_gsm = make_array(n_elements(lomo_time), 3, /double)
  ;lomo_vel_gsm[*,0] = lomo_vxgsm
  ;lomo_vel_gsm[*,1] = lomo_vygsm
  ;lomo_vel_gsm[*,2] = lomo_vzgsm
  ;store_data, 'lomo_vel_gsm', data={x:lomo_time, y:lomo_vel_gsm}

end
