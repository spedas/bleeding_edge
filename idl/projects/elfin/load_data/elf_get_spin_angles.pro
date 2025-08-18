;+
; PROCEDURE:
;         elf_get_spin_angles
;
; PURPOSE:
;         This routine will download elfin attitude and state data along with sun position.
;         The routine will interpolate the attitude data to match the state and sun position
;         cadence.
;         The spin_sun_ang and the spin_norm_ang are returned 
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       'a' or 'b'
;         att:          attitude data in gei coordinates (if no attitude tplot variable
;                       is present the routine will download the data)
;         start_time:   start time of interest with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         stop_time:    stop time of interest with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;
;-
pro elf_get_spin_angles, probes=probes, att=att, start_time=start_time, stop_time=stop_time

  ; initialize parameters if needed
  if undefined(probes) then probes='a'
   timespan, start_time
   tr=timerange()
   if undefined(stop_time) then stop_time=time_string(time_double(start_time)+86400.)

  for i = 0, n_elements(probes)-1 do begin
 
    ; check that attitude data exists, if not download it   
    if undefined(att) then begin
      sc='el'+probes[i]
      if ~spd_data_exists(sc+'_att_gei',start_time,stop_time) then elf_get_att, start_time=start_time, probe=probe  
      get_data, sc+'_att_gei', data=att
      if size(att, /type) ne 8 then begin
        print, 'No attitude data available.'
        return
      endif
    endif

    ; check that position and velocity data exists, if not download it
    if ~spd_data_exists(sc+'_pos_gei',start_time,stop_time) then elf_load_state, probe=probes[i], trange=tr
    get_data, sc+'_pos_gei', data=pos
    if size(pos, /type) ne 8 then begin
      print, 'No position data available.'
      return
    endif
    get_data, sc+'_vel_gei', data=vel1
    if size(vel1, /type) ne 8 then begin
      print, 'No velocity data available.'
      return
    endif
    
    ; interpolate attitude to position/velocity times and calculate
    ; the spin_norm_ang
    posx=interp(pos.y[*,0], pos.x, att.x)
    posy=interp(pos.y[*,1], pos.x, att.x)
    posz=interp(pos.y[*,2], pos.x, att.x)
    velx=interp(vel1.y[*,0], vel1.x, att.x)
    vely=interp(vel1.y[*,1], vel1.x, att.x)
    velz=interp(vel1.y[*,2], vel1.x, att.x)
    pos1=[[posx],[posy],[posz]]
    vel1=[[velx],[vely],[velz]]
    orb_norm=crossp2(reform(pos1), reform(vel1))
    spin_norm_ang=get_vec_ang(reform(att.y),(orb_norm))
    store_data, sc+'_spin_norm_ang', data={x:att.x, y:spin_norm_ang}

    ; get the sun position and calculate the spin sun ang
    thm_load_slp, datatype='sun_pos', trange=tr
    get_data, 'slp_sun_pos', data=sun1
    if size(sun1, /type) ne 8 then begin
      print, 'No sun position data available.'
      return
    endif
    sunx=interp(sun1.y[*,0], sun1.x, att.x)
    suny=interp(sun1.y[*,1], sun1.x, att.x)
    sunz=interp(sun1.y[*,2], sun1.x, att.x)
    sun1=[[sunx],[suny],[sunz]]  
    spin_sun_ang=get_vec_ang(reform(att.y),reform(sun1))
    store_data, sc+'_spin_sun_ang', data={x:att.x, y:spin_sun_ang}
  
  endfor
    
end

  
  
  
  
     