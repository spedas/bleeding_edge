; obsolete routine
pro elf_plot_attitude_deriv, tdate=tdate, dur=dur, probe=probe

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  tdate='2019-08-01'
  if undefined(dur) then dur=120
  probe='a'  
  
  if undefined(tdate) then begin
    dprint, 'You must enter a date (e.g. 2020-02-24/03:45:00)'
    return
  endif else begin
    tdate1=strmid(time_string(time_double(tdate)+dur*86400.),0,10)
    title='ELFIN '+strupcase(probe)+' Attitude, '+tdate+' to ' + tdate1
    ;    tdate=time_double(tdate)
    timespan, tdate, dur
  endelse
  if ~undefined(probe) then probe='a'
  probe='b'
 
  elf_load_state, probe=probe, trange=trange
  deriv_data, 'el'+probe+'_att_gei', newname='el'+probe+'_att_deriv'
  get_data, 'el'+probe+'_att_deriv', data=att_deriv  

  att_deriv_mag=(sqrt(att_deriv.y[*,0]^2+att_deriv.y[*,1]^2+att_deriv.y[*,2]^2))*1.0e7
  att_mag_dev=stddev(att_deriv_mag)
  store_data, 'el'+probe+'_att_deriv_mag', data={x:att_deriv.x, y:att_deriv_mag}
 
  idx = where(abs(att_deriv_mag) GT 30.)
;  idx = where(att_deriv_mag LT 3.)
  find_interval, idx, sidx, eidx

  ; set up plot parameters
  thm_init
  window, xsize=850, ysize=950

  tplot, ['el'+probe+'_att_gei', $
    'el'+probe+'_att_deriv', $
    'el'+probe+'_att_deriv_mag']

  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
;midx=make_array(n_elements(sidx), /double)
;for i=0,n_elements(sidx)-1 do midx[i]=att_deriv.x[sidx[i]]+(att_deriv.x[eidx[i]]-att_deriv.x[sidx[i]])/2.
;  print, time_string(midx)
for i=0,n_elements(sidx)-1 do print, time_string([att_deriv.x[sidx[i]],att_deriv.x[eidx[i]]])
;for i=0,n_elements(sidx)-1 do print, time_string([att_deriv.x[sidx[i]],att_deriv.x[eidx[i]]])
stop
;  dir_products = !elf.local_data_dir + 'attplots/
;  file_mkdir, dir_products

;  gif_file = dir_products+'el'+probe+'_attitude_plot_'+tdate+'_'+tdate1
;  dprint, 'Making gif file '+gif_file+'.gif'
;  makegif, gif_file

end