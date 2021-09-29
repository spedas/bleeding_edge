;+
; PROCEDURE:
;         elf_plot_attitude
;
; PURPOSE:
;         Create attitude plots (3 panels - att_gei vector, theta, phi) with timebars for maneuvers
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;
; EXAMPLES:
;         elf> elf_plot_attitude, trange=['2019-07-01', '2019-11-01']
;
; NOTES:
;
;-

pro elf_plot_attitude, trange=trange

 ;trange=['2020-01-01','2020-02-29']
  ; Initialize elfin system variables
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  ; verify time range parameter is properly set
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  ;daily_names = file_dailynames(trange=tr, /unique, times=times)
  ;dname=daily_names[0]
  ;dname2=daily_names[n_elements(daily_names)-1]
  daily_names = file_dailynames(trange=tr, /unique, times=times)
  daily_names2 = file_dailynames(trange=tr+86400., /unique, times=times)
  dname=daily_names[0]
  dname2=daily_names2[n_elements(daily_names2)-1]

  ; set up times and titles
  tdate=strmid(time_string(time_double(trange[0])),0,10)
  tdate1=strmid(time_string(time_double(trange[1])),0,10)  
  atitle='ELFIN A Attitude, '+tdate+' to ' + tdate1
  btitle='ELFIN B Attitude, '+tdate+' to ' + tdate1
  
  ; Get position and attitude data
  elf_load_state, probe='a', trange=trange
  elf_load_state, probe='b', trange=trange
  get_data, 'ela_pos_gei', data=ela_pos, dlimits=dlap
  get_data, 'elb_pos_gei', data=elb_pos, dlimits=dlbp 
  get_data, 'ela_vel_gei', data=ela_vel, dlimits=dlav
  get_data, 'elb_vel_gei', data=elb_vel, dlimits=dlbv
  get_data, 'ela_att_gei', data=ela_att, dlimits=dla
  get_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  dlb.labels=dla.labels
  store_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  options, 'ela_att_gei', title=atitle
  options, 'ela_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', title=btitle

  ; get MRM spin period
  start_time=time_double(trange[0])
  num_days=fix((time_double(trange[1])-time_double(trange[0]))/86400.)
  for nd=0,num_days-1 do begin
    this_time = time_double(trange[0]) + nd*86400.
    a_rpm=elf_load_att(probe='a', tdate=this_time)
    append_array, mrm_spina, a_rpm
    append_array, mrm_timea, this_time
  endfor
  dlm={ysubtitle:'[rpm]', labels:['spinper'], colors:[2]}
  store_data, 'ela_mrm_spin', data={x:mrm_timea, y:mrm_spina}, dlimits=dlm

  ; REPEAT for B
  for nd=0,num_days-1 do begin
    this_time = time_double(trange[0]) + nd*86400.
    b_rpm=elf_load_att(probe='b', tdate=this_time)
    append_array, mrm_spinb, b_rpm
    append_array, mrm_timeb, this_time
  endfor
  dlm={ysubtitle:'[rpm]', labels:['spinper'], colors:[2]}
  store_data, 'elb_mrm_spin', data={x:mrm_timeb, y:mrm_spinb}, dlimits=dlm
  
  ;get EPD spin period ('ela_pef_spinper')
  elf_load_epd, probe='a',trange=trange, datatype='pef'
  elf_load_epd, probe='b',trange=trange, datatype='pef'
  dlr={ysubtitle:'[rpm]', labels:['spinper'], colors:[2]}
  get_data, 'ela_pef_spinper', data=d
  d.y=60./d.y
  idx=where(d.y GT 18.5, ncnt)
  if ncnt GT 0 then d={x:d.x[idx], y:d.y[idx]}
  store_data, 'ela_pef_spinper', data=d, dlimits=dlr
  get_data, 'elb_pef_spinper', data=d
  d.y=60./d.y
  idx=where(d.y GT 18, ncnt)
  if ncnt GT 0 then d={x:d.x[idx], y:d.y[idx]}
  store_data, 'elb_pef_spinper', data=d, dlimits=dlr

   ; Get maneuver Times
   ; ELFIN A
   ;man_file = !elf.local_data_dir + 'ela/attplots/ela_attitude_maneuvers_times.txt'
   man_file = !elf.local_data_dir + 'attitude\ela_attitudes.csv'
   openr, lun, man_file, /GET_LUN
   line = ''
   ; Read first line - header info
   readf, lun, line
   ; Read one line at a time, saving the result into array
   while not EOF(lun) do begin 
     readf, lun, line
     append_array, atimes, line
   endwhile
   free_lun, lun

   ; ELFIN B
   ;man_file = !elf.local_data_dir + 'elb/attplots/elb_attitude_maneuvers_times.txt'
   man_file = !elf.local_data_dir + 'attitude\elb_attitudes.csv'
   openr, lun, man_file, /GET_LUN
   line = ''
   ; Read first line - header info
   readf, lun, line
   ; Read one line at a time, saving the result into array
   while not EOF(lun) do begin
     readf, lun, line
     append_array, btimes, line
   endwhile
   free_lun, lun 

  ; Calculate Theta Phi and create tplot var
  cart_to_sphere, ela_att.y[*,0], ela_att.y[*,1], ela_att.y[*,2], rda, tha, pha
  cart_to_sphere, elb_att.y[*,0], elb_att.y[*,1], elb_att.y[*,2], rdb, thb, phb 
  dlt={ysubtitle:'[deg]', labels:['theta'], colors:[2]}
  dlp={ysubtitle:'[deg]', labels:['phi'], colors:[2]}   
  store_data, 'ela_theta', data={x:ela_att.x, y:tha}, dlimits=dlt
  store_data, 'ela_phi', data={x:ela_att.x, y:pha}, dlimits=dlp
  options, 'ela_theta', yrange=[-95,95]
  options, 'ela_theta', ystyle=1
  options, 'ela_phi', yrange=[-185,185]
  options, 'ela_phi', ystyle=1
  store_data, 'elb_theta', data={x:elb_att.x, y:thb}, dlimits=dlt
  store_data, 'elb_phi', data={x:elb_att.x, y:phb}, dlimits=dlp
  options, 'elb_theta', yrange=[-95,95]
  options, 'elb_theta', ystyle=1
  options, 'elb_phi', yrange=[-185,185]
  options, 'elb_phi', ystyle=1
  options, 'ela_att_gei', yrange=[-1.05,1.05]
  options, 'ela_att_gei', ystyle=1
  options, 'elb_att_gei', yrange=[-1.05,1.05]
  options, 'elb_att_gei', ystyle=1
  
  ; set up plot parameters
  window, xsize=850, ysize=950
  thm_init
 
  ; Plot Probe A
  tplot, ['ela_att_gei', $
         'ela_theta',$
         'ela_phi', $
         'ela_mrm_spin', $
         'ela_pef_spinper']           
  timebar, atimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9 
  dir_products = !elf.local_data_dir + 'ela/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'ela_attitude_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file

  ; Plot probe B
  tplot, ['elb_att_gei', $
          'elb_theta', $
          'elb_phi', $
          'elb_mrm_spin', $
          'elb_pef_spinper']
  timebar, btimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'elb/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'elb_attitude_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file

  ; Plot keplerian elements
  ; set up plot parameters
  ; Convert position vector to keplerian elements
  ; Determine ascending equator crossing

  ; ELFIN A
  for i=0,num_days-1 do begin
      this_st=start_time+i*86400.
      this_en=this_st+86400.
      elf_load_state, probe='a', trange=[this_st, this_en], no_download=1
      get_data, 'ela_pos_gei', data=p
      get_data, 'ela_vel_gei', data=v
      idx = where(p.y[*,2] GE 0, ncnt)
      if ncnt GE 0 then begin
        find_interval, idx, sidx, eidx
        append_array, timea, p.x[sidx]
        append_array, xa, p.y[sidx, 0]
        append_array, ya, p.y[sidx, 1]
        append_array, za, p.y[sidx, 2]
        append_array, vxa, v.y[sidx, 0]
        append_array, vya, v.y[sidx, 1]
        append_array, vza, v.y[sidx, 2]
      endif
  endfor

  vec2elem, xa, ya, za, vxa, vya, vza, ela_ecc, ela_ra, ela_inc, ela_aper, ela_ma, ela_sma
  dl_ecc={labels:['ecc'], colors:[2], yrange:[-0.1,1], ystyle:1}
  dl_ra={ysubtitle:['[deg]'],labels:['ra'], colors:[2],yrange:[0,360]}
  dl_inc={ysubtitle:['[deg]'],labels:['inc'], colors:[2],yrange:[92,94]}
  dl_aper={ysubtitle:['[deg]'],labels:['aper'], colors:[2],yrange:[0,360]}
  dl_ma={ysubtitle:['[deg]'],labels:['ma'], colors:[2],yrange:[0,360]}
  dl_alt={ysubtitle:['[km]'],labels:['alt'], colors:[2],yrange:[400,500]}
  store_data, 'ela_ecc', data={x:timea,y:[ela_ecc]}, dlimits=dl_ecc
  store_data, 'ela_ra', data={x:timea,y:[ela_ra*!radeg]}, dlimits=dl_ra
  store_data, 'ela_inc', data={x:timea,y:[ela_inc*!radeg]}, dlimits=dl_inc
  daper=ela_aper[1:n_elements(ela_aper)-1] - ela_aper[0:n_elements(ela_aper)-2]
  idx=where(abs(daper*!radeg) LT 5, ncnt)
  if ncnt GT 0 then store_data, 'ela_aper', data={x:timea[idx],y:[ela_aper[idx]*!radeg]}, dlimits=dl_aper
  store_data, 'ela_ma', data={x:timea,y:[ela_ma*!radeg]}, dlimits=dl_ma
  alt=ela_sma-6374.
  dalt=alt[1:n_elements(alt)-1] - alt[0:n_elements(alt)-2]
  idx=where(abs(dalt) LT 2., ncnt)
  if ncnt GT 0 then store_data, 'ela_alt', data={x:timea[idx],y:alt[idx]}, dlimits=dl_alt
  options, 'ela_alt', title='ELFIN A Elements, '+tdate+' to ' + tdate1

  ; ELFIN B
  for i=0,num_days-1 do begin
    this_st=start_time+i*86400.
    this_en=this_st+86400.
    elf_load_state, probe='b', trange=[this_st, this_en], no_download=1
    get_data, 'elb_pos_gei', data=p
    get_data, 'elb_vel_gei', data=v
    idx = where(p.y[*,2] GE 0, ncnt)
    if ncnt GE 0 then begin
      find_interval, idx, sidx, eidx
      append_array, timeb, p.x[sidx]
      append_array, xb, p.y[sidx, 0]
      append_array, yb, p.y[sidx, 1]
      append_array, zb, p.y[sidx, 2]
      append_array, vxb, v.y[sidx, 0]
      append_array, vyb, v.y[sidx, 1]
      append_array, vzb, v.y[sidx, 2]
    endif
  endfor

  vec2elem, xb, yb, zb, vxb, vyb, vzb, elb_ecc, elb_ra, elb_inc, elb_aper, elb_ma, elb_sma
;  dl_ecc={labels:['ecc'], colors:[2], yrange:[-0.1,1], ystyle:1}
;  dl_ra={ysubtitle:['[deg]'],labels:['ra'], colors:[2],yrange:[0,360]}
;  dl_inc={ysubtitle:['[deg]'],labels:['inc'], colors:[2],yrange:[92,94]}
;  dl_aper={ysubtitle:['[deg]'],labels:['aper'], colors:[2],yrange:[0,360]}
;  dl_ma={ysubtitle:['[deg]'],labels:['ma'], colors:[2],yrange:[0,360]}
;  dl_alt={ysubtitle:['[km]'],labels:['alt'], colors:[2],yrange:[400,500]}
  store_data, 'elb_ecc', data={x:timeb,y:[elb_ecc]}, dlimits=dl_ecc
  store_data, 'elb_ra', data={x:timeb,y:[elb_ra*!radeg]}, dlimits=dl_ra
  store_data, 'elb_inc', data={x:timeb,y:[elb_inc*!radeg]}, dlimits=dl_inc
  daper=elb_aper[1:n_elements(elb_aper)-1] - elb_aper[0:n_elements(elb_aper)-2]
  idx=where(abs(daper*!radeg) LT 5, ncnt)
  if ncnt GT 0 then store_data, 'elb_aper', data={x:timeb[idx],y:[elb_aper[idx]*!radeg]}, dlimits=dl_aper
  store_data, 'elb_ma', data={x:timeb,y:[elb_ma*!radeg]}, dlimits=dl_ma
  alt=ela_sma-6374.
  dalt=alt[1:n_elements(alt)-1] - alt[0:n_elements(alt)-2]
  idx=where(abs(dalt) LT 2., ncnt)
  if ncnt GT 0 then store_data, 'elb_alt', data={x:timeb[idx],y:alt[idx]}, dlimits=dl_alt
  options, 'elb_alt', title='ELFIN B Elements, '+tdate+' to ' + tdate1

;  vec2elem, elb_pos.y[*,0], elb_pos.y[*,1], elb_pos.y[*,2], $
;    elb_vel.y[*,0], elb_vel.y[*,1], elb_vel.y[*,2], $
;    elb_ecc, elb_ra, elb_inc, elb_aper, elb_ma, elb_sma
;  store_data, 'elb_ecc', data={x:elb_pos.x,y:[elb_ecc]}, dlimits=dl_ecc
;  store_data, 'elb_ra', data={x:elb_pos.x,y:[elb_ra*!radeg]}, dlimits=dl_ra
;  store_data, 'elb_inc', data={x:elb_pos.x,y:[elb_inc*!radeg]}, dlimits=dl_inc
;  store_data, 'elb_aper', data={x:elb_pos.x,y:[elb_aper*!radeg]}, dlimits=dl_aper
;  store_data, 'elb_ma', data={x:elb_pos.x,y:[elb_ma*!radeg]}, dlimits=dl_ma
;  store_data, 'elb_alt', data={x:elb_pos.x,y:[elb_sma-6374.]}, dlimits=dl_alt
;  options, 'elb_alt', title='ELFIN B Elements, '+tdate+' to ' + tdate1

;  atitle='ELFIN A Elements, '+tdate+' to ' + tdate1
;  btitle='ELFIN B Elements, '+tdate+' to ' + tdate1

  ; Plot Probe A Elements
  window, xsize=850, ysize=950
  tplot, ['ela_alt', $
    'ela_inc', $
    'ela_ecc', $
    'ela_ra', $
    'ela_aper']
  timebar, atimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'ela/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'ela_elements_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file

  ; Plot Probe B Elements
  tplot, ['elb_alt', $
    'elb_inc', $
    'elb_ecc', $
    'elb_ra', $
    'elb_aper']
  timebar, btimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'elb/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'elb_elements_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file

end