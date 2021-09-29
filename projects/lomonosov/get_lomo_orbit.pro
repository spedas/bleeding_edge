pro get_lomo_orbit, tr=tr

;----------------
; GET LOMO Data
; ---------------

; read ascci template for lomo elfin nav-coord data files
restore, file='template_lomo.sav'

hrs = ['00','01','02','03','04','05','06','07','08','09','10', $
  '11','12','13','14','15','16','17','18','19','20', $
  '21','22','23']

  ts = time_string(tr[0])
  yr = strmid(ts,0,4)
  mo = strmid(ts,5,2)
  day = strmid(ts,8,2)
  date1 = yr+mo+day
 
  ; for one day loop and read each one hour file
  ; NOTE: moscow times is UTC + 3 hours 
  for i=3,23 do begin
    ; retrieve lomo data files from the local ftp site 
    local_file = !elf.local_data_dir + 'bi/' + date1 + '/nav_coord-' + strmid(date1,2) + '-' + hrs[i] + '.dat'
    if file_test(local_file) EQ 0 then continue
    data = -1
    data = READ_ASCII(local_file, TEMPLATE=temp_pos)
    if ~is_struct(data) && data EQ -1 then begin
      print, '***** SKIPPING: '+local_file
      stop
      continue
    endif

    ; extract data fields from each line
    date = data.field1.replace(' ','/')
    ; time
    lomo_times = time_double(date.substring(1,19)) ;+ 3*3600.
    ; postion data
    xyz = make_array(n_elements(lomo_times), 3, /double)
    xyz[*,0] = double(data.field4.replace('"', ''))/1000.
    xyz[*,1] = double(data.field5.replace('"', ''))/1000.
    xyz[*,2] = double(data.field6.replace('"', ''))/1000.
    ; velocity data
    vxyz = make_array(n_elements(lomo_times), 3, /double)
    vxyz[*,0] = double(data.field7.replace('"', ''))/1000.
    vxyz[*,1] = double(data.field8.replace('"', ''))/1000.
    vxyz[*,2] = double(data.field9.replace('"', ''))/1000.

 
    ; translate position data from GEO to GSM coordinates
    ; note - store data as tplot variables so can make easy use of coordinate transformation routines
    store_data, 'lomo_pos_geo', data={x:lomo_times, y:xyz}
    get_data, 'lomo_pos_geo', data=dgeo
    cotrans, 'lomo_pos_geo', 'lomo_pos_gei', /geo2gei
    get_data, 'lomo_pos_gei', data=dgei
    cotrans, 'lomo_pos_gei', 'lomo_pos_gse', /gei2gse
    get_data, 'lomo_pos_gse', data=dgse
    cotrans, 'lomo_pos_gse', 'lomo_pos_gsm', /gse2gsm
    get_data, 'lomo_pos_gsm', data=dgsm

    ; append each 1 hour file to create a days worth of data
    append_array, lomo_time, lomo_times
    append_array, lomo_xgsm, dgsm.y[*,0]
    append_array, lomo_ygsm, dgsm.y[*,1]
    append_array, lomo_zgsm, dgsm.y[*,2]
    append_array, lomo_xgeo, dgeo.y[*,0]
    append_array, lomo_ygeo, dgeo.y[*,1]
    append_array, lomo_zgeo, dgeo.y[*,2]
    append_array, lomo_xgei, dgei.y[*,0]
    append_array, lomo_ygei, dgei.y[*,1]
    append_array, lomo_zgei, dgei.y[*,2]
    append_array, lomo_xgse, dgse.y[*,0]
    append_array, lomo_ygse, dgse.y[*,1]
    append_array, lomo_zgse, dgse.y[*,2]

;    !p.multi=[0,3,8,0,0]
;    window, xsize=750, ysize=1050
;    plot, dgeo.y[*,0], dgeo.y[*,1], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgeo.y[*,0], dgeo.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgeo.y[*,1], dgeo.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]   
;    plot, lomo_xgeo, lomo_ygeo, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgeo, lomo_zgeo, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_ygeo, lomo_zgeo, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
 
;    plot, dgei.y[*,0], dgei.y[*,1], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgei.y[*,0], dgei.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgei.y[*,1], dgei.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgei, lomo_ygei, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgei, lomo_zgei, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_ygei, lomo_zgei, /iso, yrange=[-10000,10000], xrange=[-10000,10000]

;    plot, dgse.y[*,0], dgse.y[*,1], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgse.y[*,0], dgse.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgse.y[*,1], dgse.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgse, lomo_ygse, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgse, lomo_zgse, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_ygse, lomo_zgse, /iso, yrange=[-10000,10000], xrange=[-10000,10000]

;    plot, dgsm.y[*,0], dgsm.y[*,1], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgsm.y[*,0], dgsm.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, dgsm.y[*,1], dgsm.y[*,2], /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgsm, lomo_ygsm, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_xgsm, lomo_zgsm, /iso, yrange=[-10000,10000], xrange=[-10000,10000]
;    plot, lomo_ygsm, lomo_zgsm, /iso, yrange=[-10000,10000], xrange=[-10000,10000]


    ; repeat above for velocity
    ; translate velocity data from GEO to GSM coordinates
    store_data, 'lomo_vel_geo', data={x:lomo_times, y:vxyz}
    get_data, 'lomo_vel_geo', data=vgeo
    cotrans, 'lomo_vel_geo', 'lomo_vel_gei', /geo2gei
    get_data, 'lomo_vel_gei', data=vgei
    cotrans, 'lomo_vel_gei', 'lomo_vel_gse', /gei2gse
    get_data, 'lomo_vel_gse', data=vgse
    cotrans, 'lomo_vel_gse', 'lomo_vel_gsm', /gse2gsm
    get_data, 'lomo_vel_gsm', data=vgsm

    append_array, lomo_vxgsm, vgsm.y[*,0]
    append_array, lomo_vygsm, vgsm.y[*,1]
    append_array, lomo_vzgsm, vgsm.y[*,2]
    append_array, lomo_vxgeo, vgeo.y[*,0]
    append_array, lomo_vygeo, vgeo.y[*,1]
    append_array, lomo_vzgeo, vgeo.y[*,2]

  endfor

  ts = time_string(tr[0]+86400.)
  yr = strmid(ts,0,4)
  mo = strmid(ts,5,2)
  day = strmid(ts,8,2)
  date0 = yr+mo+day

  ; now get the last three hours of this day (UTC) from the next days files in moscow time (UTC+3 hours)
  ; basically repeat loop above
  for i=0,2 do begin
    
    local_file = !elf.local_data_dir + 'bi/' + date0 + '/nav_coord-' + strmid(date0,2) + '-' + hrs[i] + '.dat'
    if file_test(local_file) EQ 0 then continue    
    data = -1
    data = READ_ASCII(local_file, TEMPLATE=temp)
    if ~is_struct(data) && data EQ -1 then begin
      print, '***** SKIPPING: '+local_file
      stop
      continue
    endif
    date = data.field1.replace(' ','/')
    lomo_times = time_double(date.substring(1,19)) ;+ 3*3600.
    xyz = make_array(n_elements(lomo_times), 3, /double)
    xyz[*,0] = double(data.field4.replace('"', ''))/1000.
    xyz[*,1] = double(data.field5.replace('"', ''))/1000.
    xyz[*,2] = double(data.field6.replace('"', ''))/1000.
    vxyz = make_array(n_elements(lomo_times), 3, /double)
    vxyz[*,0] = double(data.field7.replace('"', ''))/1000.
    vxyz[*,1] = double(data.field8.replace('"', ''))/1000.
    vxyz[*,2] = double(data.field9.replace('"', ''))/1000.
    
    ; translate data from GEO to GSM coordinates
    store_data, 'lomo_pos_geo', data={x:lomo_times, y:xyz}
    get_data, 'lomo_pos_geo', data=dgeo
    cotrans, 'lomo_pos_geo', 'lomo_pos_gei', /geo2gei
    get_data, 'lomo_pos_gei', data=dgei
    cotrans, 'lomo_pos_gei', 'lomo_pos_gse', /gei2gse
    get_data, 'lomo_pos_gse', data=dgse
    cotrans, 'lomo_pos_gse', 'lomo_pos_gsm', /gse2gsm
    get_data, 'lomo_pos_gsm', data=dgsm
       
    append_array, lomo_time, dgsm.x
    append_array, lomo_xgsm, dgsm.y[*,0]
    append_array, lomo_ygsm, dgsm.y[*,1]
    append_array, lomo_zgsm, dgsm.y[*,2]    
    append_array, lomo_xgeo, dgeo.y[*,0]
    append_array, lomo_ygeo, dgeo.y[*,1]
    append_array, lomo_zgeo, dgeo.y[*,2]

    ; translate velocity data from GEO to GSM coordinates
    store_data, 'lomo_vel_geo', data={x:lomo_times, y:vxyz}
    get_data, 'lomo_vel_geo', data=vgeo
    cotrans, 'lomo_vel_geo', 'lomo_vel_gei', /geo2gei
    get_data, 'lomo_vel_gei', data=vgei
    cotrans, 'lomo_vel_gei', 'lomo_vel_gse', /gei2gse
    get_data, 'lomo_vel_gse', data=vgse
    cotrans, 'lomo_vel_gse', 'lomo_vel_gsm', /gse2gsm
    get_data, 'lomo_vel_gsm', data=vgsm

    append_array, lomo_vxgsm, vgsm.y[*,0]
    append_array, lomo_vygsm, vgsm.y[*,1]
    append_array, lomo_vzgsm, vgsm.y[*,2]
    append_array, lomo_vxgeo, vgeo.y[*,0]
    append_array, lomo_vygeo, vgeo.y[*,1]
    append_array, lomo_vzgeo, vgeo.y[*,2]

  endfor

  ; save as tplot variables so can use in other routines
  lomo_pos_gsm = make_array(n_elements(lomo_time), 3, /double)
  lomo_pos_gsm[*,0] = lomo_xgsm
  lomo_pos_gsm[*,1] = lomo_ygsm
  lomo_pos_gsm[*,2] = lomo_zgsm
  store_data, 'lomo_pos_gsm', data={x:lomo_time, y:lomo_pos_gsm}

  lomo_vel_gsm = make_array(n_elements(lomo_time), 3, /double)
  lomo_vel_gsm[*,0] = lomo_vxgsm
  lomo_vel_gsm[*,1] = lomo_vygsm
  lomo_vel_gsm[*,2] = lomo_vzgsm
  store_data, 'lomo_vel_gsm', data={x:lomo_time, y:lomo_vel_gsm}

  lomo_pos_geo = make_array(n_elements(lomo_time), 3, /double)
  lomo_pos_geo[*,0] = lomo_xgeo
  lomo_pos_geo[*,1] = lomo_ygeo
  lomo_pos_geo[*,2] = lomo_zgeo
  store_data, 'lomo_pos_geo', data={x:lomo_time, y:lomo_pos_geo}

  lomo_vel_geo = make_array(n_elements(lomo_time), 3, /double)
  lomo_vel_geo[*,0] = lomo_vxgeo
  lomo_vel_geo[*,1] = lomo_vygeo
  lomo_vel_geo[*,2] = lomo_vzgeo
  store_data, 'lomo_vel_geo', data={x:lomo_time, y:lomo_vel_geo}

end
      