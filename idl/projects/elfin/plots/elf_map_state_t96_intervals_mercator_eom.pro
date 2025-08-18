;mecator plot with only half hemisphere tracing
;normal footprint
;

pro elf_map_state_t96_intervals_mercator_eom, tstart, gifout=gifout, noview=noview,$
  model=model, dir_move=dir_move, insert_stop=insert_stop, hires=hires, $
  no_trace=no_trace, tstep=tstep, clean=clean, quick_trace=quick_trace, pred=pred, bfirst=bfirst, one_hour_only=one_hour_only


  ; ACN
  pro_start_time=SYSTIME(/SECONDS)
  print, SYSTIME(), ' -- Creating overview plots'  ; show the time when the plot is being created

  if (time_double(tstart) lt time_double('2018-09-16')) then begin
    print,'Please enter time after ELFIN launch 2018-09-16.'
    return
  endif

  ; some setup
  if keyword_set(dir_move) then begin
    dir_products=dir_move
  endif
  if ~keyword_set(quick) then quick=1
  if keyword_set(hires) then hires=1 else hires=0
  ft_coord='geo'
  if keyword_set(pred) then pred=1 else pred=0

  elf_init
  aacgmidl
  loadct,39 ;color tables
  thm_init

  xwidth=950
  ywidth=1500
  decharsize=1  ;default char size for low resolution
  delinewidth=1.5  ;default line width for low resolution
  desymsize=1.9 ;default symbol size for low resolution
  decharthick=1 ;default char thick for low resolution

  hrs=1.5 ;high resolution scale
  if hires then begin
    xwidth=950*hrs
    ywidth=1500*hrs
    decharsize=1*hrs  ;default char size for high resolution
    delinewidth=1.5*hrs  ;default line width for high resolution
    desymsize=1.9*hrs ;default symbol size for high resolution
    decharthick=1*hrs
  endif

  set_plot,'z'     ; z-buffer
  device,set_resolution=[xwidth,ywidth]
  tvlct,r,g,b,/get

  ; set symbols
  symbols=[4, 2]
  probes=['a','b']
  index=[254,253,252,251,249,248]

  ; set colors
  r[0]=255 & g[0]=255 & b[0]=255
  r[255]=0 & g[255]=0 & b[255]=0
  ;ELFIN A Blue
  r[index[1]]=0 & g[index[1]]=0  & b[index[1]]=255
  ;ELFIN B Orange
  r[index[0]]=255 & g[index[0]]=99 & b[index[0]]=71
  ;Grey (for RHS SM orbit plots)
  r[index[2]]=170 & g[index[2]]=170 & b[index[2]]=170
  ;yellow
  r[index[3]]=250 & g[index[3]]=177 & b[index[3]]=17
  ; stations
  ; purple
  r[index[5]]=238 & g[index[5]]=130 & b[index[5]]=238
  ; green
  r[index[4]]=90 & g[index[4]]=188 & b[index[4]]=102
  tvlct,r,g,b

  ; time input
  timespan,tstart,1,/day ;set tplot time range
  tr=timerange()
  tr[1]=tr[1]+60.*30 ; add 30 minutes into next day
  tend=time_string(time_double(tstart)+86400.0d0)
  lim=2
  earth=findgen(361)
  launch_date = time_double('2018-09-16')
  filetime=tr[0]

  ; average solar wind conditions
  dst=-10.
  dynp=2.
  bswx=2.
  bswy=-2.
  bswz=-1.
  swv=400.  ; default
  bp = sqrt(bswy^2 + bswz^2)/40.
  hb = (bp^2)/(1.+bp)
  bs = abs(bswz<0)
  th = atan(bswy,bswz)
  g1 = swv*hb*sin(th/2.)^3
  g2 = 0.005 * swv*bs
  if keyword_set(model) then tsyg_mod=model else tsyg_mod='t96'

  ;-------------------
  ; SPACECRAFT LOOP
  ;-------------------
  for sc=1,1 do begin

    ; reset timespan (attitude solution could be days old)
    timespan,tstart,88200.,/sec
    tr=timerange()

    ; GET POSITION VELOCITY
    if ~keyword_set(pred) then elf_load_state,probe=probes[sc] else elf_load_state,probe=probes[sc], /pred  ;, no_download=no_download
    get_data,'el'+probes[sc]+'_pos_gei',data=dats, dlimits=dl, limits=l  ; position in GEI
    elf_convert_state_gei2sm, probe=probes[sc]
    get_data,'el'+probes[sc]+'_pos_sm',data=dpos_sm  ; position in SM
    ;high latitude in conjugate tracing should be avoid; use SM latitude <70 degree here
    pos_lon = !radeg * atan2(dpos_sm.y[*,1],dpos_sm.y[*,0])
    pos_lat = !radeg * atan(dpos_sm.y[*,2],sqrt(dpos_sm.y[*,0]^2+dpos_sm.y[*,1]^2))
    pos_lat_mins = pos_lat[0:*:60]

    ;----------------------------------
    ; trace steup
    ;----------------------------------
    ;seperate into two hemisphere for tracing
    tt89,'el'+probes[sc]+'_pos_gsm', kp=2,newname='el'+probes[sc]+'_bt89_gsm',/igrf_only
    tdotp,'el'+probes[sc]+'_bt89_gsm','el'+probes[sc]+'_pos_gsm',newname='el'+probes[sc]+'_Br_sign'

    ;no quick trace setup
    get_data,'el'+probes[sc]+'_Br_sign',data=Br_sign_tmp
    get_data, 'el'+probes[sc]+'_pos_gsm', data=pos_gsm
    ; down map tracing
    north_index_down=where(Br_sign_tmp.y lt 0., north_index_count_down)
    south_index_down=where(Br_sign_tmp.y gt 0., south_index_count_down)
    store_data, 'el'+probes[sc]+'_pos_gsm_north_down', data={x:pos_gsm.x[north_index_down], y: pos_gsm.y[north_index_down,*]}
    store_data, 'el'+probes[sc]+'_pos_gsm_south_down', data={x:pos_gsm.x[south_index_down], y: pos_gsm.y[south_index_down,*]}

    ;conjugate map tracing
    ;do not trace above 70 degree SM latitude
    north_index_conj=where((Br_sign_tmp.y gt 0.) and (abs(pos_lat) lt 70.), north_index_count_conj) ;locate in south but should trace to north
    south_index_conj=where((Br_sign_tmp.y lt 0.) and (abs(pos_lat) lt 70.), south_index_count_conj) ;locate in north but should trace to south
    store_data, 'el'+probes[sc]+'_pos_gsm_north_conj', data={x:pos_gsm.x[north_index_conj], y: pos_gsm.y[north_index_conj,*]}
    store_data, 'el'+probes[sc]+'_pos_gsm_south_conj', data={x:pos_gsm.x[south_index_conj], y: pos_gsm.y[south_index_conj,*]}


    ;quick trace
    if keyword_set(quick_trace) then begin
      store_data, 'el'+probes[sc]+'_Br_sign_mins', data={x: Br_sign_tmp.x[0:*:60], y: Br_sign_tmp.y[0:*:60,*]}
      get_data,'el'+probes[sc]+'_Br_sign_mins',data=Br_sign_tmp_mins
      store_data, 'el'+probes[sc]+'_pos_gsm_mins', data={x: pos_gsm.x[0:*:60], y: pos_gsm.y[0:*:60,*]}
      get_data, 'el'+probes[sc]+'_pos_gsm_mins', data=pos_gsm_mins
      ; down map tracing
      north_index_mins_down=where(Br_sign_tmp_mins.y lt 0., north_index_mins_count_down)
      south_index_mins_down=where(Br_sign_tmp_mins.y gt 0.,south_index_mins_count_down)
      store_data, 'el'+probes[sc]+'_pos_gsm_mins_north_down', data={x:pos_gsm_mins.x[north_index_mins_down], y: pos_gsm_mins.y[north_index_mins_down,*]}
      store_data, 'el'+probes[sc]+'_pos_gsm_mins_south_down', data={x:pos_gsm_mins.x[south_index_mins_down], y: pos_gsm_mins.y[south_index_mins_down,*]}

      ;conjugate map tracing
      north_index_mins_conj=where((Br_sign_tmp_mins.y gt 0.) and (abs(pos_lat_mins) lt 70.), north_index_mins_count_conj) ;locate in south but should trace to north
      south_index_mins_conj=where((Br_sign_tmp_mins.y lt 0.) and (abs(pos_lat_mins) lt 70.), south_index_mins_count_conj) ;locate in north but should trace to south
      store_data, 'el'+probes[sc]+'_pos_gsm_north_mins_conj', data={x:pos_gsm_mins.x[north_index_mins_conj], y: pos_gsm_mins.y[north_index_mins_conj,*]}
      store_data, 'el'+probes[sc]+'_pos_gsm_south_mins_conj', data={x:pos_gsm_mins.x[south_index_mins_conj], y: pos_gsm_mins.y[south_index_mins_conj,*]}
    endif

    ; Setup info for Tsyganenko models
    count=n_elements(dpos_sm.x)
    num=n_elements(dpos_sm.x)-1
    if keyword_set(quick_trace) then begin
      tsyg_param_count_north_down=north_index_mins_count_down
      tsyg_param_count_south_down=south_index_mins_count_down
      tsyg_param_count_north_conj=north_index_mins_count_conj
      tsyg_param_count_south_conj=south_index_mins_count_conj
    endif else begin
      tsyg_param_count_north_down=north_index_count_down
      tsyg_param_count_south_down=south_index_count_down
      tsyg_param_count_north_conj=north_index_count_conj
      tsyg_param_count_south_conj=south_index_count_conj
    endelse
    case 1 of  ; north
      (tsyg_mod eq 't89'): begin
        tsyg_parameter_north_down=2.0d
        tsyg_parameter_south_down=2.0d
        tsyg_parameter_north_conj=2.0d
        tsyg_parameter_south_conj=2.0d
      end
      (tsyg_mod eq 't96'): begin
        tsyg_parameter_north_down=[[replicate(dynp,tsyg_param_count_north_down)], $
          [replicate(dst,tsyg_param_count_north_down)],[replicate(bswy,tsyg_param_count_north_down)],[replicate(bswz,tsyg_param_count_north_down)],$
          [replicate(0.,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)],$
          [replicate(0.,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)]]
        tsyg_parameter_south_down=[[replicate(dynp,tsyg_param_count_south_down)], $
          [replicate(dst,tsyg_param_count_south_down)],[replicate(bswy,tsyg_param_count_south_down)],[replicate(bswz,tsyg_param_count_south_down)],$
          [replicate(0.,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)],$
          [replicate(0.,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)]]
        tsyg_parameter_north_conj=[[replicate(dynp,tsyg_param_count_north_conj)], $
          [replicate(dst,tsyg_param_count_north_conj)],[replicate(bswy,tsyg_param_count_north_conj)],[replicate(bswz,tsyg_param_count_north_conj)],$
          [replicate(0.,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)],$
          [replicate(0.,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)]]
        tsyg_parameter_south_conj=[[replicate(dynp,tsyg_param_count_south_conj)], $
          [replicate(dst,tsyg_param_count_south_conj)],[replicate(bswy,tsyg_param_count_south_conj)],[replicate(bswz,tsyg_param_count_south_conj)],$
          [replicate(0.,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)],$
          [replicate(0.,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)]]
      end
      (tsyg_mod eq 't01'): begin
        tsyg_parameter_north_down=[[replicate(dynp,tsyg_param_count_north_down)],$
          [replicate(dst,tsyg_param_count_north_down)],[replicate(bswy,tsyg_param_count_north_down)],[replicate(bswz,tsyg_param_count_north_down)],$
          [replicate(g1,tsyg_param_count_north_down)],[replicate(g2,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)],$
          [replicate(0.,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)],[replicate(0.,tsyg_param_count_north_down)]]
        tsyg_parameter_south_down=[[replicate(dynp,tsyg_param_count_south_down)],$
          [replicate(dst,tsyg_param_count_south_down)],[replicate(bswy,tsyg_param_count_south_down)],[replicate(bswz,tsyg_param_count_south_down)],$
          [replicate(g1,tsyg_param_count_south_down)],[replicate(g2,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)],$
          [replicate(0.,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)],[replicate(0.,tsyg_param_count_south_down)]]
        tsyg_parameter_north_conj=[[replicate(dynp,tsyg_param_count_north_conj)],$
          [replicate(dst,tsyg_param_count_north_conj)],[replicate(bswy,tsyg_param_count_north_conj)],[replicate(bswz,tsyg_param_count_north_conj)],$
          [replicate(g1,tsyg_param_count_north_conj)],[replicate(g2,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)],$
          [replicate(0.,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)],[replicate(0.,tsyg_param_count_north_conj)]]
        tsyg_parameter_south_down=[[replicate(dynp,tsyg_param_count_south_conj)],$
          [replicate(dst,tsyg_param_count_south_conj)],[replicate(bswy,tsyg_param_count_south_conj)],[replicate(bswz,tsyg_param_count_south_conj)],$
          [replicate(g1,tsyg_param_count_south_conj)],[replicate(g2,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)],$
          [replicate(0.,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)],[replicate(0.,tsyg_param_count_south_conj)]]
      end
      else: begin
        print,'Unknown Tsyganenko model'
        return
      end
    endcase

    ; for development convenience only (ttrace2iono takes a long time)
    if keyword_set(no_trace) then goto, skip_trace

    ;----------------------------------
    ;    trace to ionosphere
    ;----------------------------------
    if keyword_set(quick_trace) then begin
      ;--------------------------
      ;     quick trace
      ;--------------------------
      ;--------------------------
      ;     down map
      ;--------------------------
      ;  south trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_mins_south_down',newname='el'+probes[sc]+'_ifoot_gsm_mins_south_down', $
        external_model=tsyg_mod,par=tsyg_parameter_south_down,R0= 1.0156 ,/km,/south
      ;  north trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_mins_north_down',newname='el'+probes[sc]+'_ifoot_gsm_mins_north_down', $
        external_model=tsyg_mod,par=tsyg_parameter_north_down,R0= 1.0156,/km
      ; combine north and south data
      get_data,'el'+probes[sc]+'_ifoot_gsm_mins_south_down',data=ifoot_mins_south_down
      get_data,'el'+probes[sc]+'_ifoot_gsm_mins_north_down',data=ifoot_mins_north_down
      ifoot_mins_down=make_array(n_elements(pos_gsm_mins.x),3, value= 0.0)
      ifoot_mins_down[south_index_mins_down,*]=ifoot_mins_south_down.y[*,*]
      ifoot_mins_down[north_index_mins_down,*]=ifoot_mins_north_down.y[*,*]
      ; interpolate the minute-by-minute data back to the full array
      store_data,'el'+probes[sc]+'_ifoot_gsm_down',data={x: dats.x, y: interp(ifoot_mins_down[*,*], pos_gsm_mins.x, dats.x)}
      ;--------------------------
      ;     conjugate map
      ;--------------------------
      ;  south trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_south_mins_conj',newname='el'+probes[sc]+'_ifoot_gsm_south_mins_conj', $
        external_model=tsyg_mod,par=tsyg_parameter_south_conj,R0= 1.0156 ,/km,/south
      ;  north trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_north_mins_conj',newname='el'+probes[sc]+'_ifoot_gsm_north_mins_conj', $
        external_model=tsyg_mod,par=tsyg_parameter_north_conj,R0= 1.0156,/km
      ; combine north and south data
      get_data,'el'+probes[sc]+'_ifoot_gsm_south_mins_conj',data=ifoot_mins_south_conj
      get_data,'el'+probes[sc]+'_ifoot_gsm_north_mins_conj',data=ifoot_mins_north_conj
      ifoot_mins_conj=make_array(n_elements(pos_gsm_mins.x),3, value= !values.f_nan)
      ifoot_mins_conj[south_index_mins_conj,*]=ifoot_mins_south_conj.y[*,*]
      ifoot_mins_conj[north_index_mins_conj,*]=ifoot_mins_north_conj.y[*,*]
      ;some high latitude points have been tracing to magnetopshere
      ;exclude footprints not in ionosphere
      ex_points=where(sqrt(ifoot_mins_conj[*,0]^2+ifoot_mins_conj[*,1]^2+ifoot_mins_conj[*,2]^2) gt 7000)
      ifoot_mins_conj[ex_points,*]=!values.f_nan
      ; interpolate the minute-by-minute data back to the full array
      store_data,'el'+probes[sc]+'_ifoot_gsm_conj',data={x: dats.x, y: interp(ifoot_mins_conj[*,*], pos_gsm_mins.x, dats.x)}

      ; clean up the temporary data
      del_data, '*_mins'
    endif else begin
      ;--------------------------
      ;     no quick trace
      ;--------------------------
      ;--------------------------
      ;     down map
      ;--------------------------
      ;  south trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_south_down',newname='el'+probes[sc]+'_ifoot_gsm_south_down', $
        external_model=tsyg_mod,par=tsyg_parameter_south_down,R0= 1.0156 ,/km,/south
      ;  north trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_north_down',newname='el'+probes[sc]+'_ifoot_gsm_north_down', $
        external_model=tsyg_mod,par=tsyg_parameter_north_down,R0= 1.0156 ,/km
      ; combine north and south data
      get_data,'el'+probes[sc]+'_ifoot_gsm_south_down',data=ifoot_south_down
      get_data,'el'+probes[sc]+'_ifoot_gsm_north_down',data=ifoot_north_down
      ifoot_down=make_array(n_elements(pos_gsm.x),3, value= 0.0)
      ifoot_down[south_index_down,*]=ifoot_south_down.y[*,*]
      ifoot_down[north_index_down,*]=ifoot_north_down.y[*,*]
      store_data,'el'+probes[sc]+'_ifoot_gsm_down',data={x: dats.x, y: ifoot_down[*,*]}
      ;--------------------------
      ;     conjugate map
      ;--------------------------
      ;  south trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_south_conj',newname='el'+probes[sc]+'_ifoot_gsm_south_conj', $
        external_model=tsyg_mod,par=tsyg_parameter_south_conj,R0= 1.0156 ,/km,/south
      ;  north trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_north_conj',newname='el'+probes[sc]+'_ifoot_gsm_north_conj', $
        external_model=tsyg_mod,par=tsyg_parameter_north_conj,R0= 1.0156 ,/km
      ; combine north and south data
      get_data,'el'+probes[sc]+'_ifoot_gsm_south_conj',data=ifoot_south_conj
      get_data,'el'+probes[sc]+'_ifoot_gsm_north_conj',data=ifoot_north_conj
      ifoot_conj=make_array(n_elements(pos_gsm.x),3, value= !values.f_nan)
      ifoot_conj[south_index_conj,*]=ifoot_south_conj.y[*,*]
      ifoot_conj[north_index_conj,*]=ifoot_north_conj.y[*,*]
      ;exclude points that havn't trace to ionosphere
      ex_points=where(sqrt(ifoot_conj[*,0]^2+ifoot_conj[*,1]^2+ifoot_conj[*,2]^2) gt 7000)
      ifoot_conj[ex_points,*]=!values.f_nan
      store_data,'el'+probes[sc]+'_ifoot_gsm_conj',data={x: dats.x, y: ifoot_conj[*,*]}

    endelse

    skip_trace:

    ; CONVERT coordinate system to geo and sm
    cotrans, 'el'+probes[sc]+'_ifoot_gsm_down', 'el'+probes[sc]+'_ifoot_gse_down', /gsm2gse
    cotrans, 'el'+probes[sc]+'_ifoot_gsm_down', 'el'+probes[sc]+'_ifoot_sm_down', /gsm2sm
    cotrans, 'el'+probes[sc]+'_ifoot_gse_down', 'el'+probes[sc]+'_ifoot_gei_down', /gse2gei
    cotrans, 'el'+probes[sc]+'_ifoot_gei_down', 'el'+probes[sc]+'_ifoot_geo_down', /gei2geo

    cotrans, 'el'+probes[sc]+'_ifoot_gsm_conj', 'el'+probes[sc]+'_ifoot_gse_conj', /gsm2gse
    cotrans, 'el'+probes[sc]+'_ifoot_gsm_conj', 'el'+probes[sc]+'_ifoot_sm_conj', /gsm2sm
    cotrans, 'el'+probes[sc]+'_ifoot_gse_conj', 'el'+probes[sc]+'_ifoot_gei_conj', /gse2gei
    cotrans, 'el'+probes[sc]+'_ifoot_gei_conj', 'el'+probes[sc]+'_ifoot_geo_conj', /gei2geo

    print,'Done '+tsyg_mod+' ',probes[sc]

  endfor  ; END of SC Loop


  ;---------------------------
  ; COLLECT DATA FOR PLOTS
  ;--------------------------
  ; Get science collection times
  trange=[time_double(tstart), time_double(tend)]
  ;  epda_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='epd') ;alternate pef_spinper/pef_nflux
  epdb_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='b', instrument='epd')
;  epdia_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='epdi') ;alternate pef_spinper/pef_nflux
  epdib_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='b', instrument='epdi')
;  fgma_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='fgm') ;alternate pef_spinper/pef_nflux
  fgmb_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='b', instrument='fgm')

  ; get vlf and eiscat station positions
  eiscat_pos=elf_get_eiscat_positions()
  vlf_pos=elf_get_vlf_positions()

  ; Get position and attitude
  get_data,'ela_pos_sm',data=ela_state_pos_sm
  get_data,'elb_pos_sm',data=elb_state_pos_sm
  get_data,'ela_pos_gsm',data=ela_state_pos_gsm
  get_data,'elb_pos_gsm',data=elb_state_pos_gsm

  ; Get MLT
  elf_mlt_l_lat,'ela_pos_sm',MLT0=MLTA,L0=LA,LAT0=latA ;;subroutine to calculate mlt,l,mlat under dipole configuration
  elf_mlt_l_lat,'elb_pos_sm',MLT0=MLTB,L0=LB,LAT0=latB ;;subroutine to calculate mlt,l,mlat under dipole configuration

  ; Create attitude info for plot text
;  get_data, 'ela_spin_orbnorm_angle', data=norma
;  get_data, 'ela_spin_sun_angle', data=suna
;  get_data, 'ela_att_solution_date', data=solna
;  get_data, 'ela_att_gei',data=attgeia
;  if size(attgeia, /type) EQ 8 then cotrans, 'ela_att_gei', 'ela_att_gse', /gei2gse
  get_data, 'ela_att_gse',data=attgsea
  get_data, 'elb_spin_orbnorm_angle', data=normb
  get_data, 'elb_spin_sun_angle', data=sunb
  get_data, 'elb_att_solution_date', data=solnb
  get_data, 'elb_att_gei',data=attgeib
  if size(attgeib, /type) EQ 8 then cotrans, 'elb_att_gei', 'elb_att_gse', /gei2gse
  get_data, 'elb_att_gse',data=attgseb

  ;reset time (attitude data might be several days old)
  timespan,tstart,88200.,/sec
  tr=timerange()

  ; determine orbital period
  ; Elfin A
;  res=where(ela_state_pos_sm.y[*,1] GE 0, ncnt) ;sm x component
;  find_interval, res, sres, eres
;  at_ag=(ela_state_pos_sm.x[eres]-ela_state_pos_sm.x[sres])/60.*2  ;x is time
;  at_s=ela_state_pos_sm.x[sres]
;  an_ag = n_elements([at_ag])
;  if an_ag GT 1 then med_ag=median([at_ag]) else med_ag=at_ag
;  badidx = where(at_ag LT 80.,ncnt)
;  if ncnt GT 0 then at_ag[badidx]=med_ag  ;replace the first one with median
  ; Elfin B
  res=where(elb_state_pos_sm.y[*,1] GE 0, ncnt)
  find_interval, res, sres, eres
  bt_ag=(elb_state_pos_sm.x[eres]-elb_state_pos_sm.x[sres])/60.*2
  bt_s=elb_state_pos_sm.x[sres]
  bn_ag = n_elements([bt_ag])
  if bn_ag GT 1 then med_ag=median([bt_ag]) else med_ag=bt_ag
  badidx = where(bt_ag LT 80.,ncnt)
  if ncnt GT 0 then bt_ag[badidx]=med_ag

  ; setup for orbits
  ; 24 plots starting each hour for 90 minutes
  hr_arr = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)] ;0-24
  hr_ststr = string(hr_arr, format='(i2.2)') ;0-24 text
  ; Strings for labels, filenames
  ; Use smaller array if ela and elb are not the same
;  checka=n_elements(ela_state_pos_sm.x)
  checkb=n_elements(elb_state_pos_sm.x)
  for m=0,23 do begin
    this_s = tr[0] + m*3600.
    this_e = this_s + 90.*60.
;    if checkb LT checka then begin
      idx = where(elb_state_pos_sm.x GE this_s AND elb_state_pos_sm.x LT this_e, ncnt)
;    endif else begin
;      idx = where(ela_state_pos_sm.x GE this_s AND ela_state_pos_sm.x LT this_e, ncnt)
;    endelse
    if ncnt GT 10 then begin
      append_array, min_st, idx[0]
      append_array, min_en, idx[n_elements(idx)-1]
      this_lbl = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'
      append_array, plot_lbl, this_lbl
      this_file = '_'+hr_ststr[m]
      append_array, file_lbl, this_file
    endif
  endfor
  nplots = n_elements(min_st)
  midhrs=findgen(24)+.75

  ;---------------------------------
  ; CREATE LAT/LON grids and poles
  ;---------------------------------
  ; Make GEOGRAPHIC GRIDS

  geo_grids=elf_make_geo_grid()
  u_lon=geo_grids.u_lon
  u_lat=geo_grids.u_lat
  v_lon=geo_grids.v_lon
  v_lat=geo_grids.v_lat
  nmlats=geo_grids.nmlats
  nmlons=geo_grids.nmlons

  ; for gif-output
  date=strmid(tstart,0,10)
  timespan, tstart
  tr=timerange()

  ;sun symbol
  theta = findgen(25) * (!pi*2/24.)
  for i=0,24 do begin
    if (i mod 3) eq 0 then begin
      append_array, sun_x, [cos(theta[i]),2*cos(theta[i])]
      append_array, sun_y, [sin(theta[i]),2*sin(theta[i])]
    endif
    append_array, sun_x, cos(theta[i])
    append_array, sun_y, sin(theta[i])
  endfor

  ;----------------------------------
  ; Start Plots
  ;----------------------------------
  for k=0,nplots-1 do begin
    for kk=0,1 do begin  ; two sets of figure 0/180 GLON center
      !p.multi=[0,1,2,0,0]
      if keyword_set(gifout) then begin
        set_plot,'z'
        device,set_resolution=[xwidth,ywidth]
      endif else begin
        set_plot,'x'
        ;set_plot,'win'
        window,xsize=xwidth,ysize=ywidth
      endelse

      this_time=elb_state_pos_sm.x[min_st[k]:min_en[k]]
      midpt=n_elements(this_time)/2.
      tdate = this_time[midpt]

      ;;;;; spacecraft location
      for sc = 1,1 do begin
        get_data, 'el'+probes[sc]+'_ifoot_geo_down', data = ifoot_down
        get_data, 'el'+probes[sc]+'_ifoot_geo_conj', data = ifoot_conj
        ifoot=ifoot_down
        ;----------------------------
        ; CONVERT TRACE to LAT LON
        ;----------------------------
        get_data,'el'+probes[sc]+'_pos_geo',data=dpos_geo
 ;       Case sc of
 ;         ; ELFIN A
 ;         0: begin
 ;           lon_a_down = !radeg * atan2(ifoot_down.y[*,1],ifoot_down.y[*,0])
 ;           lat_a_down = !radeg * atan(ifoot_down.y[*,2],sqrt(ifoot_down.y[*,0]^2+ifoot_down.y[*,1]^2))
 ;           lon_a_conj = !radeg * atan2(ifoot_conj.y[*,1],ifoot_conj.y[*,0])
 ;           lat_a_conj = !radeg * atan(ifoot_conj.y[*,2],sqrt(ifoot_conj.y[*,0]^2+ifoot_conj.y[*,1]^2))
 ;           dposa=dpos_geo
 ;         end
          ; ELFIN B
 ;         1: begin
            lon_b_down = !radeg * atan2(ifoot_down.y[*,1],ifoot_down.y[*,0])
            lat_b_down = !radeg * atan(ifoot_down.y[*,2],sqrt(ifoot_down.y[*,0]^2+ifoot_down.y[*,1]^2))
            lon_b_conj = !radeg * atan2(ifoot_conj.y[*,1],ifoot_conj.y[*,0])
            lat_b_conj = !radeg * atan(ifoot_conj.y[*,2],sqrt(ifoot_conj.y[*,0]^2+ifoot_conj.y[*,1]^2))
            dposb=dpos_geo
 ;         end
 ;       Endcase
      endfor

      ; find midpt MLT for this orbit track
      midx=min_st[k] + (min_en[k] - min_st[k])/2.
      mid_time_struc=time_struct(ela_state_pos_sm.x[midx])
      mid_hr=mid_time_struc.hour + mid_time_struc.min/60.
      mid_hr=midhrs[k]  ;mid UT

      ;----------------------------------
      ;    day/night boundary
      ;----------------------------------
      earthRadius=6370. ;km
      Taltitude=[0., 100., 400.] ;terminator altitude in km
      terminator_geo_r = FltArr(361,3)
      terminator_geo_lat = FltArr(361,3)
      terminator_geo_lon = FltArr(361,3)
      terminator_gse_lon = FltArr(361,3)
      terminator_gse_lat = FltArr(361,3)
      terminator_gse_x=FltArr(361,3)
      terminator_gse_y=FltArr(361,3)
      terminator_gse_z=FltArr(361,3)
      for j=0,2 do begin
        alpha=asin(earthRadius / (earthRadius+Taltitude[j]))/!DTOR
        r_terminus = earthRadius+Taltitude
        for i=0,360 do begin
          azimuth=i*1.
          ;cart_to_sphere,-1,0,0,r,theta,phi
          results = LL_Arc_Distance([180, 0], alpha*!DTOR, azimuth, /degrees)
          terminator_gse_lon[i,j] = results[0] ;GSE
          terminator_gse_lat[i,j] = results[1]
        endfor
        sphere_to_cart, replicate(earthRadius,361), terminator_gse_lat[*,j], terminator_gse_lon[*,j], Tx, Ty, Tz
        terminator_gse_x[*,j] = Tx
        terminator_gse_y[*,j] = Ty
        terminator_gse_z[*,j] = Tz
        times=make_array(361,/double)+tdate
        store_data, 'terminator_gse', data={x:times, y:[[terminator_gse_x[*,j]], [terminator_gse_y[*,j]], [terminator_gse_z[*,j]]]}
        cotrans, 'terminator_gse', 'terminator_gei', /gse2gei
        cotrans, 'terminator_gei', 'terminator_geo', /gei2geo
        get_data, 'terminator_geo', data=terminator_geo
        cart_to_sphere,terminator_geo.y[*,0],terminator_geo.y[*,1],terminator_geo.y[*,2],Tr,Tlat,Tlon
        terminator_geo_r[*,j]=Tr
        terminator_geo_lat[*,j]=Tlat
        terminator_geo_lon[*,j]=Tlon
      endfor
      ; sub solar location
      times=make_array(2,/double)+tdate
      store_data, 'terminator_sun_gse', data={x:times, y:[[1], [0], [0]]}
      cotrans, 'terminator_sun_gse', 'terminator_sun_gei', /gse2gei
      cotrans, 'terminator_sun_gei', 'terminator_sun_geo', /gei2geo
      get_data, 'terminator_sun_geo', data=terminator_sun_geo
      cart_to_sphere,terminator_sun_geo.y[*,0],terminator_sun_geo.y[*,1],terminator_sun_geo.y[*,2],terminator_sun_geo_r,terminator_sun_geo_lat,terminator_sun_geo_lon

      ; -------------------------------------
      ; MAP PLOT
      ; -------------------------------------
      ; set up map
      coord='Down'
      if keyword_set(pred) then pred_str='Predicted ' else pred_str=''
      title=pred_str+coord+' Footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
      latnames=['-70','-60','-50','-40','-30','-20','-10','10','20','30','40','50','60','70'] ; exclude 0 so it doesn't overlap with 0 longitude
      lats=[indgen(7,increment=10,start=-70),indgen(7,increment=10,start=10)]
      lonnames0=['-180','-150','-120','-90','-60','-30','0','30','60','90','120','150','180']
      lons0=indgen(13,increment=30,start=-180)
      lons0[0]=lons0[0]+1  ; -180 degree is not shown so i use -179
      lonnames180=['0','30','60','90','120','150','180','210','240','270','300','330','360']
      lons180=indgen(13,increment=30,start=0)
      lons180[12]=lons180[12]-1  ; 360 degree is not shown so i use 359
      if kk eq 0 then begin
        map_set,0,0,0, /mercator, /conti, charsize=decharsize, position=[0.01,0.51,0.99,0.98], limit=[-80, -180, 80, 180]
        map_grid,lats=lats, latnames=latnames,label=1, lons=lons0,lonnames=lonnames0, charsize=decharsize, glinethick=delinewidth*1.2,charthick=decharthick
      endif else begin
        map_set,0,180,0, /mercator, /conti, charsize=decharsize, position=[0.01,0.51,0.99,0.98], limit=[-80, 0, 80, 360]
        map_grid,lats=lats, latnames=latnames,label=1,lons=lons180,lonnames=lonnames180, charsize=decharsize, glinethick=delinewidth*1.2,charthick=decharthick
      endelse
      xyouts, (!x.window[1] - !x.window[0]) / 2. + !x.window[0], 0.985, title, $
        /normal, alignment=0.5, charsize=decharsize*1.5, charthick=decharthick*1.5
      map_continents, color=252, mlinethick=delinewidth*0.5
      ;
      ;
      ;
      oplot,terminator_geo_lon[*,0],terminator_geo_lat[*,0],color=255,thick=delinewidth*1.5,linestyle=0 ;Talt=0
      oplot,terminator_geo_lon[*,1],terminator_geo_lat[*,1],color=255,thick=delinewidth*0.5,linestyle=0 ;Talt=100
      oplot,terminator_geo_lon[*,2],terminator_geo_lat[*,2],color=255,thick=delinewidth*1,linestyle=2 ;Talt=400

      usersym, sun_x, sun_y
      plots,terminator_sun_geo_lon[0],terminator_sun_geo_lat[0],psym=8, symsize=desymsize, color=255 ;sub solar point
      usersym, cos(theta), sin(theta), /fill
      plots,terminator_sun_geo_lon[0],terminator_sun_geo_lat[0],psym=8, symsize=desymsize, color=251 ;sub solar point

      ;----------------------
      ;;; MAG Coords
      ;----------------------
      for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=delinewidth*1.2,linestyle=1 ;latitude rings
      ; plot geomagnetic equator
      ; (nmlats-1)/2 is equator index
      ;equ_lon=(v_lon[(nmlats-1)/2-1,*]+v_lon[(nmlats-1)/2+1,*])/2
      ;equ_lat=(v_lat[(nmlats-1)/2-1,*]+v_lat[(nmlats-1)/2+1,*])/2
      ;oplot,equ_lon,equ_lat,color=248,thick=3,linestyle=1
      for i=0,nmlons-1 do begin
        idx=where(u_lon[i,*] NE 0)
        oplot,u_lon[i,idx],u_lat[i,idx],color=248,thick=delinewidth*1.2,linestyle=1
      endfor

      ;-------------------------------
      ; PLOT VLF and EISCAT Stations
      ;-------------------------------
      if size(eiscat_pos, /type) EQ 8 then begin
        ename=eiscat_pos.name
        elat=eiscat_pos.lat
        elon=eiscat_pos.lon
        symsz=[1.2, 1.0, 0.75, 0.5, 0.25]
        for es=0,2 do begin
          for ss=0,n_elements(symsz)-1 do plots, elon[es], elat[es], color=248, psym=5, symsize=symsz[ss]  ;253
          plots, elon[es], elat[es], psym=5, symsize=1.25
          ;          plots, elon[es], elat[es], psym=5, symsize=1.85
        endfor
      endif
      if size(vlf_pos, /type) EQ 8 then begin
        vname=vlf_pos.name
        vlat=vlf_pos.glat
        vlon=vlf_pos.glon
        symsz=[1.0, 0.75, 0.5, 0.25]
        for vs=0,6 do begin
          for ss=0,n_elements(symsz)-1 do plots, vlon[vs], vlat[vs], color=249, psym=6, symsize=symsz[ss]
          plots, vlon[vs], vlat[vs], psym=6, symsize=1.05
          ;         plots, vlon[vs], vlat[vs], psym=6, symsize=1.65
        endfor
      endif

      ; Set up data for ELFIN A for this time span
;      this_time=ela_state_pos_sm.x[min_st[k]:min_en[k]]
;      nptsa=n_elements(this_time)
 ;     this_a_lon_down=lon_a_down[min_st[k]:min_en[k]]
;      this_a_lat_down=lat_a_down[min_st[k]:min_en[k]]
;      this_a_lon_conj=lon_a_conj[min_st[k]:min_en[k]]
;      this_a_lat_conj=lat_a_conj[min_st[k]:min_en[k]]
;      this_ax=ela_state_pos_sm.y[min_st[k]:min_en[k],0]
;      this_ay=ela_state_pos_sm.y[min_st[k]:min_en[k],1]
;      this_az=ela_state_pos_sm.y[min_st[k]:min_en[k],2]
;      this_dposa=dposa.y[min_st[k]:min_en[k],2]
;      this_a_alt = mean(sqrt(this_ax^2 + this_ay^2 + this_az^2))-6371.
;      this_a_alt_str = strtrim(string(this_a_alt),1)
 ;     alt_len=strlen(this_a_alt_str)
 ;     this_a_alt_str=strmid(this_a_alt_str,0,alt_len-2)+'km'
      ;      this_a_alt_str = strtrim(string(this_a_alt),1)
;      this_a_lat = lata[min_st[k]:min_en[k]]
;      this_a_l = la[min_st[k]:min_en[k]]
 ;     if size(attgeia, /type) EQ 8 then begin
 ;       min_a_att_gei=min(abs(ela_state_pos_sm.x[midx]-attgeia.x),agei_idx) ;agei_idex min subscript
 ;       min_a_att_gse=min(abs(ela_state_pos_sm.x[midx]-attgsea.x),agse_idx)
 ;       this_a_att_gei = attgeia.y[agei_idx,*]
 ;       this_a_att_gse = attgsea.y[agse_idx,*]
 ;     endif
 ;     undefine, this_a_sz_st
 ;     undefine, this_a_sz_en
 ;     if ~undefined(epda_sci_zones) && size(epda_sci_zones, /type) EQ 8 then begin
 ;       idx=where(epda_sci_zones.starts GE this_time[0] and epda_sci_zones.starts LT this_time[nptsa-1], azones)
 ;       if azones GT 0 then begin
 ;         this_a_sz_st=epda_sci_zones.starts[idx]
 ;         this_a_sz_en=epda_sci_zones.ends[idx]
 ;         if epda_sci_zones.ends[azones-1] GT this_time[nptsa-1] then this_a_sz_en[azones-1]=this_time[nptsa-1]
 ;       endif
 ;     endif

      ; repeat for ELFIN B
      this_time2=elb_state_pos_sm.x[min_st[k]:min_en[k]]
      nptsb=n_elements(this_time2)
      this_time=this_time2
      nptsa=nptsb
      this_b_lon_down=lon_b_down[min_st[k]:min_en[k]]
      this_b_lat_down=lat_b_down[min_st[k]:min_en[k]]
      this_b_lon_conj=lon_b_conj[min_st[k]:min_en[k]]
      this_b_lat_conj=lat_b_conj[min_st[k]:min_en[k]]
      this_bx=elb_state_pos_sm.y[min_st[k]:min_en[k],0]
      this_by=elb_state_pos_sm.y[min_st[k]:min_en[k],1]
      this_bz=elb_state_pos_sm.y[min_st[k]:min_en[k],2]
      this_dposb=dposb.y[min_st[k]:min_en[k],2]
      this_b_alt = mean(sqrt(this_bx^2 + this_by^2 + this_bz^2))-6371.
      this_b_alt_str = strtrim(string(this_b_alt),1)
      alt_len=strlen(this_b_alt_str)
      this_b_alt_str=strmid(this_b_alt_str,0,alt_len-2)+'km'
      ;this_b_alt_str = strtrim(string(this_b_alt),1)
      this_b_lat = latb[min_st[k]:min_en[k]]
      this_b_l = lb[min_st[k]:min_en[k]]
      if size(attgeib, /type) EQ 8 then begin
        min_b_att_gei=min(abs(elb_state_pos_sm.x[midx]-attgeib.x),bgei_idx)
        min_b_att_gse=min(abs(elb_state_pos_sm.x[midx]-attgseb.x),bgse_idx)
        this_b_att_gei = attgeib.y[bgei_idx,*]
        this_b_att_gse = attgseb.y[bgse_idx,*]
      endif
      ;;;; Jiang Liu edit: to reduce errors for the ease of debugging
      undefine, this_b_sz_st
      undefine, this_b_sz_en
      if ~undefined(epdb_sci_zones) && size(epdb_sci_zones, /type) EQ 8 then begin
        idx=where(epdb_sci_zones.starts GE this_time2[0] and epdb_sci_zones.starts LT this_time2[nptsb-1], bzones)
        if bzones GT 0 then begin
          this_b_sz_st=epdb_sci_zones.starts[idx]
          this_b_sz_en=epdb_sci_zones.ends[idx]
          if epdb_sci_zones.ends[bzones-1] GT this_time2[nptsb-1] then this_b_sz_en[bzones-1]=this_time2[nptsb-1]
        endif
      endif

      ; Plot foot points
      if ~keyword_set(bfirst) then begin
        oplot, this_b_lon_down, this_b_lat_down, color=254, thick=delinewidth*1.5
;        oplot, this_a_lon_down, this_a_lat_down, color=253, thick=delinewidth*1.5
      endif else begin
;        oplot, this_a_lon_down, this_a_lat_down, color=253, thick=delinewidth*1.5
        oplot, this_b_lon_down, this_b_lat_down, color=254, thick=delinewidth*1.5
      endelse

      ;-----------------------------------------------------
      ; SCIENCE COLLECTIONS - check if there were any science
      ; collections this time frame
      ;-----------------------------------------------------
      ; Check B
      spin_strb=''
      get_data, 'elb_pef_spinper', data=spinb
      if size(spinb,/type) EQ 8 then begin
        spin_idxb=where(spinb.x GE this_time2[0] AND spinb.x LT this_time2[nptsb-1], ncnt)
        if ncnt GT 5 then begin
          med_spinb=median(spinb.y[spin_idxb])
          spin_varb=stddev(spinb.y[spin_idxb])*100.
          spin_strb='Median Spin Period, s: '+strmid(strtrim(string(med_spinb), 1),0,4) + $
            ', % of Median: '+strmid(strtrim(string(spin_varb), 1),0,4)
        endif
      endif
      if ~undefined(epdb_sci_zones) && size(epdb_sci_zones, /type) EQ 8 then begin
        idx=where(epdb_sci_zones.starts GE this_time2[0] and epdb_sci_zones.starts LT this_time2[nptsb-1], bzones)
        if bzones GT 0 then begin
          this_b_sz_st=epdb_sci_zones.starts[idx]
          this_b_sz_en=epdb_sci_zones.ends[idx]
          if epdb_sci_zones.ends[bzones-1] GT this_time2[nptsb-1] then this_b_sz_en[bzones-1]=this_time2[nptsb-1]
        endif
      endif
      if ~undefined(epdib_sci_zones) && size(epdib_sci_zones, /type) EQ 8 then begin
        iidx=where(epdib_sci_zones.starts GE this_time2[0] and epdib_sci_zones.starts LT this_time2[nptsb-1], bizones)
        if bizones GT 0 then begin
          append_array, this_b_sz_st, epdib_sci_zones.starts[iidx]
          append_array, this_b_sz_en, epdib_sci_zones.ends[iidx]
          if epdib_sci_zones.ends[bizones-1] GT this_time2[nptsb-1] then this_b_sz_en[bizones-1]=this_time2[nptsb-1]
        endif
      endif
      if ~undefined(fgmb_sci_zones) && size(fgmb_sci_zones, /type) EQ 8 then begin
        fidx=where(fgmb_sci_zones.starts GE this_time2[0] and fgmb_sci_zones.starts LT this_time2[nptsb-1], bfzones)
        if bfzones GT 0 then begin
          append_array, this_b_sz_st, fgmb_sci_zones.starts[fidx]
          append_array, this_b_sz_en, fgmb_sci_zones.ends[fidx]
          if fgmb_sci_zones.ends[bfzones-1] GT this_time2[nptsb-1] then this_b_sz_en[bfzones-1]=this_time2[nptsb-1]
        endif
      endif

      ; Repeat for A
;      spin_stra=''
;      get_data, 'ela_pef_spinper', data=spina ; spin period
;      if size(spina, /type) EQ 8 then begin
;        spin_idxa=where(spina.x GE this_time2[0] AND spina.x LT this_time2[nptsa-1], ncnt)
;        if ncnt GT 5 then begin
;          med_spina=median(spina.y[spin_idxa])
;          spin_vara=stddev(spina.y[spin_idxa])*100.
;          spin_stra='Median Spin Period, s: '+strmid(strtrim(string(med_spina), 1),0,4) + $
;            ', % of Median: '+strmid(strtrim(string(spin_vara), 1),0,4)
;        endif
;      endif
;      if ~undefined(epda_sci_zones) && size(epda_sci_zones, /type) EQ 8 then begin
;        idx=where(epda_sci_zones.starts GE this_time[0] and epda_sci_zones.starts LT this_time[nptsa-1], azones)
;        if azones GT 0 then begin
;          this_a_sz_st=epda_sci_zones.starts[idx]
;          this_a_sz_en=epda_sci_zones.ends[idx]
;          if epda_sci_zones.ends[azones-1] GT this_time[nptsa-1] then this_a_sz_en[azones-1]=this_time[nptsa-1]
;        endif
;      endif
;      if ~undefined(epdia_sci_zones) && size(epdia_sci_zones, /type) EQ 8 then begin
;        iidx=where(epdia_sci_zones.starts GE this_time[0] and epdia_sci_zones.starts LT this_time[nptsa-1], aizones)
;        if aizones GT 0 then begin
;          append_array, this_a_sz_st, epdia_sci_zones.starts[iidx]
;          append_array, this_a_sz_en, epdia_sci_zones.ends[iidx]
;          if epdia_sci_zones.ends[aizones-1] GT this_time[nptsa-1] then this_a_sz_en[aizones-1]=this_time[nptsa-1]
;        endif
;      endif
;      if ~undefined(fgma_sci_zones) && size(fgma_sci_zones, /type) EQ 8 then begin
;        fidx=where(fgma_sci_zones.starts GE this_time[0] and fgma_sci_zones.starts LT this_time[nptsa-1], afzones)
;        if afzones GT 0 then begin
;          append_array, this_a_sz_st, fgma_sci_zones.starts[fidx]
;          append_array, this_a_sz_en, fgma_sci_zones.ends[fidx]
;          if fgma_sci_zones.ends[afzones-1] GT this_time[nptsa-1] then this_a_sz_en[afzones-1]=this_time[nptsa-1]
;        endif
;      endif

      ; ------------------------------
      ; PLOT science collection
      ;-------------------------------
      if ~keyword_set(bfirst) then begin
        if ~undefined(this_b_sz_st) then begin
          for sci=0, n_elements(this_b_sz_st)-1 do begin
            tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
            if bcnt GT 5 then begin
              ;plots, this_b_lon_down[tidxb], this_b_lat_down[tidxb], psym=2, symsize=.25, color=254, thick=3
              oplot, this_b_lon_down[tidxb], this_b_lat_down[tidxb], color=254, thick=delinewidth*4
            endif
          endfor
        endif
     endif
;        if ~undefined(this_a_sz_st) then begin
;          for sci=0, n_elements(this_a_sz_st)-1 do begin
;            tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
;            if acnt GT 5 then begin
              ;plots, this_a_lon_down[tidxa], this_a_lat_down[tidxa], psym=2, symsize=.25, color=253, thick=3
;              oplot, this_a_lon_down[tidxa], this_a_lat_down[tidxa], color=253, thick=delinewidth*4
;            endif
;          endfor
 ;       endif
;      endif else begin
;        if ~undefined(this_a_sz_st) then begin
;          for sci=0, n_elements(this_a_sz_st)-1 do begin
;            tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
;            if acnt GT 5 then begin
;              ;plots, this_a_lon_down[tidxa], this_a_lat_down[tidxa], psym=2, symsize=.25, color=253, thick=3
;              oplot, this_a_lon_down[tidxa], this_a_lat_down[tidxa], color=253, thick=delinewidth*4
;            endif
;          endfor
;        endif
        if ~undefined(this_b_sz_st) then begin
          for sci=0, n_elements(this_b_sz_st)-1 do begin
            tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
            if bcnt GT 5 then begin
              ;plots, this_b_lon_down[tidxb], this_b_lat_down[tidxb], psym=2, symsize=.25, color=254, thick=3
              oplot, this_b_lon_down[tidxb], this_b_lat_down[tidxb], color=254, thick=delinewidth*4
            endif
          endfor
        endif
;      endelse

      ;-----------------------------------------
      ; Plot dataset start/stop position markers
      ; ----------------------------------------
      ; elfinb
      if ~keyword_set(bfirst) then begin
        count=nptsb   ;n_elements(this_b_lon_down)
        if (this_b_lat_down[0] lt 80) and (this_b_lat_down[0] gt -80) then begin
          plots, this_b_lon_down[0], this_b_lat_down[0], psym=4, symsize=desymsize, color=254 ;diamond
          plots, this_b_lon_down[0], this_b_lat_down[0], psym=4, symsize=desymsize*0.92, color=254 ;diamond
          plots, this_b_lon_down[0], this_b_lat_down[0], psym=4, symsize=desymsize*0.85, color=254
        endif
        if (this_b_lat_down[count-1] lt 80) and (this_b_lat_down[count-1] gt -80) then begin
          plots, this_b_lon_down[count-1], this_b_lat_down[count-1], psym=2, symsize=desymsize, color=254 ;*
          plots, this_b_lon_down[count-1], this_b_lat_down[count-1], psym=2, symsize=desymsize*0.92, color=254
          plots, this_b_lon_down[count-1], this_b_lat_down[count-1], psym=2, symsize=desymsize*0.85, color=254
        endif
        if (this_b_lat_down[count/2] lt 80) and (this_b_lat_down[count/2] gt -80) then begin
          plots, this_b_lon_down[count/2], this_b_lat_down[count/2], psym=5, symsize=desymsize, color=254 ;triangle
          plots, this_b_lon_down[count/2], this_b_lat_down[count/2], psym=5, symsize=desymsize*0.92, color=254 ;triangle
          plots, this_b_lon_down[count/2], this_b_lat_down[count/2], psym=5, symsize=desymsize*0.85, color=254 ;triangle
        endif
        ; elfina
;        count=nptsa    ;n_elements(this_a_lon_down)
;        if (this_a_lat_down[0] lt 80) and (this_a_lat_down[0] gt -80) then begin
;          plots, this_a_lon_down[0], this_a_lat_down[0], psym=4, symsize=desymsize, color=253
;          plots, this_a_lon_down[0], this_a_lat_down[0], psym=4, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_down[0], this_a_lat_down[0], psym=4, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_down[count-1] lt 80) and (this_a_lat_down[count-1] gt -80) then begin
;          plots, this_a_lon_down[count-1], this_a_lat_down[count-1], psym=2, symsize=desymsize, color=253
;          plots, this_a_lon_down[count-1], this_a_lat_down[count-1], psym=2, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_down[count-1], this_a_lat_down[count-1], psym=2, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_down[count/2] lt 80) and (this_a_lat_down[count/2] gt -80) then begin
;          plots, this_a_lon_down[count/2], this_a_lat_down[count/2], psym=5, symsize=desymsize, color=253
;          plots, this_a_lon_down[count/2], this_a_lat_down[count/2], psym=5, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_down[count/2], this_a_lat_down[count/2], psym=5, symsize=desymsize*0.85, color=253
;        endif
      endif
        ; elfina
;        count=nptsa    ;n_elements(this_a_lon_down)
;        if (this_a_lat_down[0] lt 80) and (this_a_lat_down[0] gt -80) then begin
;          plots, this_a_lon_down[0], this_a_lat_down[0], psym=4, symsize=desymsize, color=253
;          plots, this_a_lon_down[0], this_a_lat_down[0], psym=4, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_down[0], this_a_lat_down[0], psym=4, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_down[count-1] lt 80) and (this_a_lat_down[count-1] gt -80) then begin
;          plots, this_a_lon_down[count-1], this_a_lat_down[count-1], psym=2, symsize=desymsize, color=253
;          plots, this_a_lon_down[count-1], this_a_lat_down[count-1], psym=2, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_down[count-1], this_a_lat_down[count-1], psym=2, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_down[count/2] lt 80) and (this_a_lat_down[count/2] gt -80) then begin
;          plots, this_a_lon_down[count/2], this_a_lat_down[count/2], psym=5, symsize=desymsize, color=253
;          plots, this_a_lon_down[count/2], this_a_lat_down[count/2], psym=5, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_down[count/2], this_a_lat_down[count/2], psym=5, symsize=desymsize*0.85, color=253
;        endif
;        count=nptsb   ;n_elements(this_b_lon_down)
;        if (this_b_lat_down[0] lt 80) and (this_b_lat_down[0] gt -80) then begin
;          plots, this_b_lon_down[0], this_b_lat_down[0], psym=4, symsize=desymsize, color=254 ;diamond
;          plots, this_b_lon_down[0], this_b_lat_down[0], psym=4, symsize=desymsize*0.92, color=254 ;diamond
;          plots, this_b_lon_down[0], this_b_lat_down[0], psym=4, symsize=desymsize*0.85, color=254
;        endif
;        if (this_b_lat_down[count-1] lt 80) and (this_b_lat_down[count-1] gt -80) then begin
;          plots, this_b_lon_down[count-1], this_b_lat_down[count-1], psym=2, symsize=desymsize, color=254 ;*
;          plots, this_b_lon_down[count-1], this_b_lat_down[count-1], psym=2, symsize=desymsize*0.92, color=254
;          plots, this_b_lon_down[count-1], this_b_lat_down[count-1], psym=2, symsize=desymsize*0.85, color=254
;        endif
;        if (this_b_lat_down[count/2] lt 80) and (this_b_lat_down[count/2] gt -80) then begin
;          plots, this_b_lon_down[count/2], this_b_lat_down[count/2], psym=5, symsize=desymsize, color=254 ;triangle
;          plots, this_b_lon_down[count/2], this_b_lat_down[count/2], psym=5, symsize=desymsize*0.92, color=254 ;triangle
;          plots, this_b_lon_down[count/2], this_b_lat_down[count/2], psym=5, symsize=desymsize*0.85, color=254 ;triangle
;        endif
;      endelse

      ;---------------------
      ; ADD Tick Marks
      ;---------------------
      if keyword_set(tstep) then begin
        tstep=300.
        ; add tick marks for B
        res=this_time2[1] - this_time2[0]
        istep=tstep/res
        last = n_elements(this_time2)
        steps=lindgen(last/istep+1)*istep
        tmp=max(steps,nmax)
        if tmp gt (last-1) then steps=steps[0:nmax-1]
        tsteps0=this_time2[steps[0]]
        dummy=min(abs(this_time2-tsteps0),istep0)
        istepsb=steps+istep0
        ; add tick marks for A
        res=this_time[1] - this_time[0] ;=1
        istep=tstep/res; tick mark step
        last = n_elements(this_time) ;end of trajectory
        steps=lindgen(last/istep+1)*istep
        tmp=max(steps,nmax)
        if tmp gt (last-1) then steps=steps[0:nmax-1]
        tsteps0=this_time[steps[0]]
        dummy=min(abs(this_time-tsteps0),istep0)
        istepsa=steps+istep0
      endif

      if ~keyword_set(bfirst) then begin
        plots, this_b_lon_down[istepsb], this_b_lat_down[istepsb], psym=1, symsize=desymsize*1, color=254, clip=[-180, -78, 180, 78], NOCLIP=0 ;plus sign
;        plots, this_a_lon_down[istepsa], this_a_lat_down[istepsa], psym=1, symsize=desymsize*1, color=253, clip=[-180, -78, 180, 78], NOCLIP=0
      endif ;else begin
;        plots, this_a_lon_down[istepsa], this_a_lat_down[istepsa], psym=1, symsize=desymsize*1, color=253, clip=[-180, -78, 180, 78], NOCLIP=0
;        plots, this_b_lon_down[istepsb], this_b_lat_down[istepsb], psym=1, symsize=desymsize*1, color=254, clip=[-180, -78, 180, 78], NOCLIP=0
;      endelse

;      index_equ_a=where(abs(this_a_lat_down) lt 0.5) ;when cross equator
      index_equ_b=where(abs(this_b_lat_down) lt 0.5)
     ; if this_a_lon_down[index_equ_a[0]] lt this_b_lon_down[index_equ_b[0]] then begin ;a is on the left of b
;        if this_a_lon_down[index_equ_a[0]] lt this_b_lon_down[index_equ_b[0]] then begin ;a is on the left of b
        ;add elfa number label
;        for i=1,n_elements(istepsa)-1 do begin
;          if abs(this_a_lat_down[istepsa[i]]) lt 78 then begin
;            tick_label=strtrim(string(fix(istepsa(i)/60)),2)
;            xyouts,this_a_lon_down[istepsa[i]]-10,this_a_lat_down[istepsa[i]],tick_label,alignment=0.0,charsize=decharsize*1.2,color=253, charthick=decharthick*2
;          endif
;        endfor

        ;add elfb number label
        for i=1,n_elements(istepsb)-1 do begin
          if abs(this_b_lat_down[istepsb[i]]) lt 78 then begin
            tick_label=strtrim(string(fix(istepsb(i)/60)),2)
            xyouts,this_b_lon_down[istepsb[i]]+10,this_b_lat_down[istepsb[i]],tick_label,alignment=1.0,charsize=decharsize*1.2,color=254, charthick=decharthick*2
          endif
        endfor
;      endif else begin
        ;add elfa number label
;        for i=1,n_elements(istepsa)-1 do begin
;          if abs(this_a_lat_down[istepsa[i]]) lt 78 then begin
;            tick_label=strtrim(string(fix(istepsa(i)/60)),2)
;            xyouts,this_a_lon_down[istepsa[i]]+2,this_a_lat_down[istepsa[i]],tick_label,alignment=0.0,charsize=decharsize*1.2,color=253, charthick=decharthick*2
;          endif
;        endfor

        ;add elfb number label
        for i=1,n_elements(istepsb)-1 do begin
          if abs(this_b_lat_down[istepsb[i]]) lt 78 then begin
            tick_label=strtrim(string(fix(istepsb(i)/60)),2)
            xyouts,this_b_lon_down[istepsb[i]]-2,this_b_lat_down[istepsb[i]],tick_label,alignment=1.0,charsize=decharsize*1.2,color=254, charthick=decharthick*2
          endif
        endfor
;      endelse

      ; get spin angle
      spin_att_ang_str='B/SP: (NA/ND/SD/SA)'
      ; ELFIN A
      ; IBO
 ;     if size(attgeia, /type) EQ 8 then begin  ;a
 ;       elf_calc_sci_zone_att,probe='a',trange=[this_time[0],this_time[n_elements(this_time)-1]], $
 ;         lat=this_a_lat*!radeg, lshell=this_a_l, /ibo
 ;       ela_ibo_spin_att_ang_str = 'IBO: ' + elf_make_spin_att_string(probe='a')
 ;     endif else begin
 ;       ela_ibo_spin_att_ang_str = 'IBO: not available'
 ;     endelse
      ; OBO
 ;     if size(attgeia, /type) EQ 8 then begin  ;a
 ;       elf_calc_sci_zone_att,probe='a',trange=[this_time[0],this_time[n_elements(this_time)-1]], $
 ;         lat=this_a_lat*!radeg, lshell=this_a_l
 ;       ela_obo_spin_att_ang_str = 'OBO: ' + elf_make_spin_att_string(probe='a')
 ;     endif else begin
 ;       ela_obo_spin_att_ang_str = 'OBO: not available'
 ;     endelse

      ; ELFIN B
      ; IBO
      if size(attgeib, /type) EQ 8 then begin  ;b
        elf_calc_sci_zone_att,probe='b',trange=[this_time2[0],this_time2[n_elements(this_time2)-1]], $
          lat=this_b_lat*!radeg, lshell=this_b_l, /ibo
        elb_ibo_spin_att_ang_str = 'IBO: ' + elf_make_spin_att_string(probe='b')
      endif else begin
        elb_ibo_spin_att_ang_str = 'IBO: not available'
      endelse
      ; OBO
      if size(attgeib, /type) EQ 8 then begin  ;b
        elf_calc_sci_zone_att,probe='b',trange=[this_time2[0],this_time2[n_elements(this_time2)-1]], $
          lat=this_b_lat*!radeg, lshell=this_b_l
        elb_obo_spin_att_ang_str = 'OBO: ' + elf_make_spin_att_string(probe='b')
      endif else begin
        elb_obo_spin_att_ang_str = 'OBO: not available'
      endelse

      ;-----------------------------------------
      ; Create Text for Annotations
      ;-----------------------------------------
      ; find total orbit time for this plot
;      idx = where(at_s GE this_time[0], ncnt)
;      if ncnt EQ 0 then idx=0
;      a_period_str = strmid(strtrim(string(at_ag[idx[0]]), 1),0,5)
      idx = where(bt_s GE this_time2[0], ncnt)
      if ncnt EQ 0 then idx=0
      b_period_str = strmid(strtrim(string(bt_ag[idx[0]]), 1),0,5) ;strtrim delete blank strmid extract from 0-5

      ; get spin period and add to total orbit time
      ; elfin a
;      a_rpm=elf_load_att(probe='a', tdate=ela_state_pos_sm.x[min_st[k]])
;      a_sp=60./a_rpm
;      a_spinper = strmid(strtrim(string(a_sp),1),0,4)
;      a_rpm_str = strmid(strtrim(string(a_rpm),1),0,5)
;      a_spin_str='Tspin='+a_spinper+'s['+a_rpm_str+'RPM]'
;      a_torb_str='Torb='+a_period_str+'min'
      ;     a_orb_spin_str='Torb='+a_period_str+'min; Tspin='+a_spinper+'s ['+a_rpm_str+'RPM]'
      ; elfin b
      ; ******get spin period routines******
      b_rpm=elf_load_att(probe='b', tdate=ela_state_pos_sm.x[min_st[k]])
      b_sp=60./b_rpm
      b_spinper = strmid(strtrim(string(b_sp),1),0,4)
      b_rpm_str = strmid(strtrim(string(b_rpm),1),0,5)
      b_spin_str='Tspin='+b_spinper+'s['+b_rpm_str+'RPM]'
      b_torb_str='Torb='+b_period_str+'min'
      ;      b_orb_spin_str='Torb='+b_period_str+'min; Tspin='+b_spinper+'s ['+b_rpm_str+'RPM]'

      ; create attitude strings
      ; elfin a
;      if size(norma,/type) EQ 8 then begin
;        idx=where(norma.x GE this_time[0] and norma.x LT this_time[n_elements(this_time)-1], ncnt)
;        if size(norma, /type) EQ 8 && ncnt GT 2 then $
;          norma_str=strmid(strtrim(string(median(norma.y[idx])),1),0,5) $
;        else norma_str = 'No att data'
;        idx=where(suna.x GE this_time[0] and suna.x LT this_time[n_elements(this_time)-1], ncnt)
;        if size(suna, /type) EQ 8 && ncnt GT 2 then $
;          suna_str=strmid(strtrim(string(median(suna.y[idx])),1),0,5) $
;        else suna_str = 'No att data'
;        idx=where(solna.x GE this_time[0] and solna.x LT this_time[n_elements(this_time)-1], ncnt)
;        if size(solna, /type) EQ 8 && ncnt GT 2 && solna.y[0] GT launch_date then begin
;          solna_string=time_string(solna.y[0])
;          solna_str=strmid(solna_string,0,4)+'-'+strmid(solna_string,5,2)+'-'+strmid(solna_string,8,2)+'/'+strmid(solna_string,11,2)
;        endif else begin
;          solna_str = 'No att data'
;        endelse
;      endif else begin
;        norma_str = 'No att data'
;        suna_str = 'No att data'
;        solna_str = 'No att data'
;      endelse
      ; repeat for B
      if size(normb,/type) EQ 8 then begin
        idx=where(normb.x GE this_time2[0] and normb.x LT this_time2[n_elements(this_time2)-1], ncnt)
        if size(normb, /type) EQ 8 && ncnt GT 2 then $
          normb_str=strmid(strtrim(string(median(normb.y[idx])),1),0,5) $
        else normb_str = 'No att data'
        idx=where(sunb.x GE this_time2[0] and sunb.x LT this_time2[n_elements(this_time2)-1], ncnt)
        if size(sunb, /type) EQ 8 && ncnt GT 2 then $
          sunb_str=strmid(strtrim(string(median(sunb.y[idx])),1),0,5) $
        else sunb_str = 'No att data'
        idx=where(solnb.x GE this_time2[0] and solnb.x LT this_time2[n_elements(this_time2)-1], ncnt)
        if size(solnb, /type) EQ 8 && ncnt GT 2 && solnb.y[0] GT launch_date then begin
          solnb_string=time_string(solnb.y[0])
          solnb_str=strmid(solnb_string,0,4)+'-'+strmid(solnb_string,5,2)+'-'+strmid(solnb_string,8,2)+'/'+strmid(solnb_string,11,2)
        endif else begin
          solnb_str = 'No att data'
        endelse
      endif else begin
        normb_str = 'No att data'
        sunb_str = 'No att data'
        solnb_str = 'No att data'
      endelse

      ; Create attitude vector strings
      ; ELFIN A
;      if ~undefined(this_a_att_gei) then begin
;        if this_a_att_gei[0] GE 0. then offset=5 else offset=6
;        a_att_gei_x_str = strmid(strtrim(string(this_a_att_gei[0]),1),0,offset)
;        if this_a_att_gei[1] GE 0. then offset=5 else offset=6
;        a_att_gei_y_str = strmid(strtrim(string(this_a_att_gei[1]),1),0,offset)
;        if this_a_att_gei[2] GE 0. then offset=5 else offset=6
;        a_att_gei_z_str = strmid(strtrim(string(this_a_att_gei[2]),1),0,offset)
;        a_att_gei_str = 'S: ['+a_att_gei_x_str+','+a_att_gei_y_str+','+a_att_gei_z_str+'] GEI'
 ;     endif else begin
 ;       a_att_gei_str = 'S: not available'
 ;     endelse
 ;     if ~undefined(this_a_att_gse) then begin
 ;       if this_a_att_gse[0] GE 0. then offset=5 else offset=6
 ;       a_att_gse_x_str = strmid(strtrim(string(this_a_att_gse[0]),1),0,offset)
 ;       if this_a_att_gse[1] GE 0. then offset=5 else offset=6
 ;       a_att_gse_y_str = strmid(strtrim(string(this_a_att_gse[1]),1),0,offset)
 ;       if this_a_att_gse[2] GE 0. then offset=5 else offset=6
 ;       a_att_gse_z_str = strmid(strtrim(string(this_a_att_gse[2]),1),0,offset)
 ;       a_att_gse_str = 'S: ['+a_att_gse_x_str+','+a_att_gse_y_str+','+a_att_gse_z_str+'] GSE'
 ;     endif else begin
 ;       a_att_gse_str = 'S: not available'
 ;     endelse
      ; repeat for ELFIN B
      if ~undefined(this_b_att_gei) then begin
        if this_b_att_gei[0] GE 0. then offset=5 else offset=6
        b_att_gei_x_str = strmid(strtrim(string(this_b_att_gei[0]),1),0,offset)
        if this_b_att_gei[1] GE 0. then offset=5 else offset=6
        b_att_gei_y_str = strmid(strtrim(string(this_b_att_gei[1]),1),0,offset)
        if this_b_att_gei[2] GE 0. then offset=5 else offset=6
        b_att_gei_z_str = strmid(strtrim(string(this_b_att_gei[2]),1),0,offset)
        b_att_gei_str = 'S: ['+b_att_gei_x_str+','+b_att_gei_y_str+','+b_att_gei_z_str+'] GEI'
      endif else begin
        b_att_gei_str = 'S: not available'
      endelse
      if ~undefined(this_b_att_gse) then begin
        if this_b_att_gse[0] GE 0. then offset=5 else offset=6
        b_att_gse_x_str = strmid(strtrim(string(this_b_att_gse[0]),1),0,offset)
        if this_b_att_gse[1] GE 0. then offset=5 else offset=6
        b_att_gse_y_str = strmid(strtrim(string(this_b_att_gse[1]),1),0,offset)
        if this_b_att_gse[2] GE 0. then offset=5 else offset=6
        b_att_gse_z_str = strmid(strtrim(string(this_b_att_gse[2]),1),0,offset)
        b_att_gse_str = 'S: ['+b_att_gse_x_str+','+b_att_gse_y_str+','+b_att_gse_z_str+'] GSE'
      endif else begin
        b_att_gse_str = 'S: not available'
      endelse

      ; annotate constants
      yann1=1-0.03
      yann2=0.015
      yann3=0.4775
      yann4=0.514
      xann=0.015
      dyann=0.013
;      xyouts,xann,yann1-dyann*0,'ELFIN (A)',/normal,charsize=decharsize,color=253,charthick=decharthick*2
;      ;      xyouts,xann,yann1-dyann*1,a_orb_spin_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*1,a_spin_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*2,a_torb_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*3,spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*4,ela_obo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*5,ela_ibo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*6,a_att_gei_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*7,a_att_gse_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*8,'S w/Sun, deg: '+suna_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*9,'S w/OrbNorm, deg: '+norma_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*10,'Att.Sol@'+solna_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann1-dyann*11,'Altitude, km: '+this_a_alt_str,/normal,charsize=decharsize,charthick=decharthick

;      xyouts,xann,yann3-dyann*0,'ELFIN (A)',/normal,charsize=decharsize,color=253,charthick=decharthick*2
;      ;      xyouts,xann,yann1-dyann*1,a_orb_spin_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*1,a_spin_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*2,a_torb_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*3,spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*4,ela_obo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*5,ela_ibo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*6,a_att_gei_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*7,a_att_gse_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*8,'S w/Sun, deg: '+suna_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*9,'S w/OrbNorm, deg: '+norma_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*10,'Att.Sol@'+solna_str,/normal,charsize=decharsize,charthick=decharthick
;      xyouts,xann,yann3-dyann*11,'Altitude, km: '+this_a_alt_str,/normal,charsize=decharsize,charthick=decharthick

      xyouts,xann,yann2+dyann*11,'ELFIN (B)',/normal,charsize=decharsize,color=254,charthick=decharthick*2
      ;      xyouts,xann,yann2+dyann*9,b_orb_spin_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*10,b_spin_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*9,b_torb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*8,spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*7,elb_obo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*6,elb_ibo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*5,b_att_gei_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*4,b_att_gse_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*3,'S w/Sun, deg: '+sunb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*2,'S w/OrbNorm, deg: '+normb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*1,'Att.Sol@: '+solnb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann2+dyann*0,'Altitude: '+this_b_alt_str,/normal,charsize=decharsize,charthick=decharthick

      xyouts,xann,yann4+dyann*11,'ELFIN (B)',/normal,charsize=decharsize,color=254,charthick=decharthick*2
      ;      xyouts,xann,yann2+dyann*9,b_orb_spin_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*10,b_spin_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*9,b_torb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*8,spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*7,elb_obo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*6,elb_ibo_spin_att_ang_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*5,b_att_gei_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*4,b_att_gse_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*3,'S w/Sun, deg: '+sunb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*2,'S w/OrbNorm, deg: '+normb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*1,'Att.Sol@: '+solnb_str,/normal,charsize=decharsize,charthick=decharthick
      xyouts,xann,yann4+dyann*0,'Altitude: '+this_b_alt_str,/normal,charsize=decharsize,charthick=decharthick

      ;--------------------------------
      ;
      ;
      ;       CONJUGATE FOOTPRINT
      ;
      ;
      ;--------------------------------
      coord='Conjugate'
      if keyword_set(pred) then pred_str='Predicted ' else pred_str=''
      title=pred_str+coord+' Footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
      if kk eq 0 then begin
        map_set,0,0,0, /mercator, /conti, charsize=decharsize, /advance, position=[0.01,0.01,0.99,0.49], limit=[-80, -180, 80, 180]
        map_grid,lats=lats,latnames=latnames,label=1,lons=lons0,lonnames=lonnames0, charsize=decharsize, glinethick=delinewidth*1.2,charthick=decharthick
      endif else begin
        map_set,0,180,0, /mercator, /conti, charsize=decharsize, /advance, position=[0.01,0.01,0.99,0.49], limit=[-80, 0, 80, 360]
        map_grid,lats=lats,latnames=latnames,label=1,lons=lons180,lonnames=lonnames180, charsize=decharsize, glinethick=delinewidth*1.2,charthick=decharthick
      endelse

      xyouts, (!x.window[1] - !x.window[0]) / 2. + !x.window[0], 0.495, title, $
        /normal, alignment=0.5, charsize=decharsize*1.5,charthick=decharthick*1.5
      map_continents, color=252, mlinethick=delinewidth*0.5

      oplot,terminator_geo_lon[*,0],terminator_geo_lat[*,0],color=255,thick=delinewidth*1.5,linestyle=0 ;Talt=0
      oplot,terminator_geo_lon[*,1],terminator_geo_lat[*,1],color=255,thick=delinewidth*0.5,linestyle=0 ;Talt=100
      oplot,terminator_geo_lon[*,2],terminator_geo_lat[*,2],color=255,thick=delinewidth*1,linestyle=2 ;Talt=400
      usersym, sun_x, sun_y
      plots,terminator_sun_geo_lon[0],terminator_sun_geo_lat[0],psym=8, symsize=desymsize, color=255 ;sub solar point
      usersym, cos(theta), sin(theta), /fill
      plots,terminator_sun_geo_lon[0],terminator_sun_geo_lat[0],psym=8, symsize=desymsize, color=251 ;sub solar point

      ; MAG Coords
      for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=delinewidth*1.2,linestyle=1 ;latitude rings
      ; plot geomagnetic equator
      ; (nmlats-1)/2 is equator index
      ;equ_lon=(v_lon[(nmlats-1)/2-1,*]+v_lon[(nmlats-1)/2+1,*])/2
      ;equ_lat=(v_lat[(nmlats-1)/2-1,*]+v_lat[(nmlats-1)/2+1,*])/2
      ;oplot,equ_lon,equ_lat,color=248,thick=3,linestyle=1
      for i=0,nmlons-1 do begin
        idx=where(u_lon[i,*] NE 0)
        oplot,u_lon[i,idx],u_lat[i,idx],color=248,thick=delinewidth*1.2,linestyle=1
      endfor

      ;-------------------------------
      ; PLOT VLF and EISCAT Stations
      ;-------------------------------
      if size(eiscat_pos, /type) EQ 8 then begin
        ename=eiscat_pos.name
        elat=eiscat_pos.lat
        elon=eiscat_pos.lon
        symsz=[1.2, 1.0, 0.75, 0.5, 0.25]
        for es=0,2 do begin
          for ss=0,n_elements(symsz)-1 do plots, elon[es], elat[es], color=248, psym=5, symsize=symsz[ss]  ;253
          plots, elon[es], elat[es], psym=5, symsize=1.25
          ;          plots, elon[es], elat[es], psym=5, symsize=1.85
        endfor
      endif
      if size(vlf_pos, /type) EQ 8 then begin
        vname=vlf_pos.name
        vlat=vlf_pos.glat
        vlon=vlf_pos.glon
        symsz=[1.0, 0.75, 0.5, 0.25]
        for vs=0,6 do begin
          for ss=0,n_elements(symsz)-1 do plots, vlon[vs], vlat[vs], color=249, psym=6, symsize=symsz[ss]
          plots, vlon[vs], vlat[vs], psym=6, symsize=1.05
          ;          plots, vlon[vs], vlat[vs], psym=6, symsize=1.65
        endfor
      endif

      ; Plot foot points
      if ~keyword_set(bfirst) then begin
        oplot, this_b_lon_conj[0:*:5], this_b_lat_conj[0:*:5], color=254, linestyle=2, thick=delinewidth*1.5
;        oplot, this_a_lon_conj[0:*:5], this_a_lat_conj[0:*:5], color=253, linestyle=2, thick=delinewidth*1.5
      endif else begin
        oplot, this_a_lon_conj[0:*:5], this_a_lat_conj[0:*:5], color=253, linestyle=2, thick=delinewidth*1.5
;        oplot, this_b_lon_conj[0:*:5], this_b_lat_conj[0:*:5], color=254, linestyle=2, thick=delinewidth*1.5
      endelse


      ; ------------------------------
      ; PLOT science collection
      ;-------------------------------
      if ~keyword_set(bfirst) then begin
        if ~undefined(this_b_sz_st) then begin
          for sci=0, n_elements(bzones)-1 do begin
            tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
            if bcnt GT 5 then begin
              ;plots, this_b_lon_conj[tidxb], this_b_lat_conj[tidxb], psym=2, symsize=.25, color=254, thick=3
              oplot, this_b_lon_conj[tidxb], this_b_lat_conj[tidxb], color=254, thick=delinewidth*4
            endif
          endfor
        endif
 ;       if ~undefined(this_a_sz_st) then begin
 ;         for sci=0, azones-1 do begin
 ;           tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
 ;           if acnt GT 5 then begin
 ;             ;plots, this_a_lon_conj[tidxa], this_a_lat_conj[tidxa], psym=2, symsize=.25, color=253, thick=3
 ;             oplot, this_a_lon_conj[tidxa], this_a_lat_conj[tidxa], color=253, thick=delinewidth*4
 ;           endif
 ;         endfor
 ;       endif
      endif else begin
 ;       if ~undefined(this_a_sz_st) then begin
 ;         for sci=0, azones-1 do begin
 ;           tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
 ;           if acnt GT 5 then begin
 ;             oplot, this_a_lon_conj[tidxa], this_a_lat_conj[tidxa], color=253, thick=delinewidth*4
 ;           endif
 ;         endfor
 ;       endif
        if ~undefined(this_b_sz_st) then begin
          for sci=0, n_elements(bzones)-1 do begin
            tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
            if bcnt GT 5 then begin
              oplot, this_b_lon_conj[tidxb], this_b_lat_conj[tidxb], color=254, thick=delinewidth*4
            endif
          endfor
        endif
      endelse

      ;-----------------------------------------
      ; Plot dataset start/stop position markers
      ; ----------------------------------------
      ; elfinb
      if ~keyword_set(bfirst) then begin
        count=nptsb   ;n_elements(this_b_lon_down)
        if (this_b_lat_conj[0] lt 80) and (this_b_lat_conj[0] gt -80) then begin
          plots, this_b_lon_conj[0], this_b_lat_conj[0], psym=4, symsize=desymsize, color=254
          plots, this_b_lon_conj[0], this_b_lat_conj[0], psym=4, symsize=desymsize*0.92, color=254 ;diamond
          plots, this_b_lon_conj[0], this_b_lat_conj[0], psym=4, symsize=desymsize*0.85, color=254
        endif
        if (this_b_lat_conj[count-1] lt 80) and (this_b_lat_conj[count-1] gt -80) then begin
          plots, this_b_lon_conj[count-1], this_b_lat_conj[count-1], psym=2, symsize=desymsize, color=254 ;*
          plots, this_b_lon_conj[count-1], this_b_lat_conj[count-1], psym=2, symsize=desymsize*0.92, color=254
          plots, this_b_lon_conj[count-1], this_b_lat_conj[count-1], psym=2, symsize=desymsize*0.85, color=254
        endif
        if (this_b_lat_conj[count/2] lt 80) and (this_b_lat_conj[count/2] gt -80) then begin
          plots, this_b_lon_conj[count/2], this_b_lat_conj[count/2], psym=5, symsize=desymsize, color=254 ;triangle
          plots, this_b_lon_conj[count/2], this_b_lat_conj[count/2], psym=5, symsize=desymsize*0.92, color=254 ;triangle
          plots, this_b_lon_conj[count/2], this_b_lat_conj[count/2], psym=5, symsize=desymsize*0.85, color=254 ;triangle
        endif
        ; elfina
;        count=nptsa    ;n_elements(this_a_lon_conj)
;        if (this_a_lat_conj[0] lt 80) and (this_a_lat_conj[0] gt -80) then begin
;          plots, this_a_lon_conj[0], this_a_lat_conj[0], psym=4, symsize=desymsize, color=253
;          plots, this_a_lon_conj[0], this_a_lat_conj[0], psym=4, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_conj[0], this_a_lat_conj[0], psym=4, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_conj[count-1] lt 80) and (this_a_lat_conj[count-1] gt -80) then begin
;          plots, this_a_lon_conj[count-1], this_a_lat_conj[count-1], psym=2, symsize=desymsize, color=253
;          plots, this_a_lon_conj[count-1], this_a_lat_conj[count-1], psym=2, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_conj[count-1], this_a_lat_conj[count-1], psym=2, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_conj[count/2] lt 80) and (this_a_lat_conj[count/2] gt -80) then begin
;          plots, this_a_lon_conj[count/2], this_a_lat_conj[count/2], psym=5, symsize=desymsize, color=253
;          plots, this_a_lon_conj[count/2], this_a_lat_conj[count/2], psym=5, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_conj[count/2], this_a_lat_conj[count/2], psym=5, symsize=desymsize*0.85, color=253
;        endif
      endif else begin
        ; elfina
;        count=nptsa    ;n_elements(this_a_lon_conj)
;        if (this_a_lat_conj[0] lt 80) and (this_a_lat_conj[0] gt -80) then begin
;          plots, this_a_lon_conj[0], this_a_lat_conj[0], psym=4, symsize=desymsize, color=253
;          plots, this_a_lon_conj[0], this_a_lat_conj[0], psym=4, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_conj[0], this_a_lat_conj[0], psym=4, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_conj[count-1] lt 80) and (this_a_lat_conj[count-1] gt -80) then begin
;          plots, this_a_lon_conj[count-1], this_a_lat_conj[count-1], psym=2, symsize=desymsize, color=253
;          plots, this_a_lon_conj[count-1], this_a_lat_conj[count-1], psym=2, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_conj[count-1], this_a_lat_conj[count-1], psym=2, symsize=desymsize*0.85, color=253
;        endif
;        if (this_a_lat_conj[count/2] lt 80) and (this_a_lat_conj[count/2] gt -80) then begin
;          plots, this_a_lon_conj[count/2], this_a_lat_conj[count/2], psym=5, symsize=desymsize, color=253
;          plots, this_a_lon_conj[count/2], this_a_lat_conj[count/2], psym=5, symsize=desymsize*0.92, color=253
;          plots, this_a_lon_conj[count/2], this_a_lat_conj[count/2], psym=5, symsize=desymsize*0.85, color=253
;        endif
        count=nptsb   ;n_elements(this_b_lon_conj)
        if (this_b_lat_conj[0] lt 80) and (this_b_lat_conj[0] gt -80) then begin
          plots, this_b_lon_conj[0], this_b_lat_conj[0], psym=4, symsize=desymsize, color=254
          plots, this_b_lon_conj[0], this_b_lat_conj[0], psym=4, symsize=desymsize*0.92, color=254 ;diamond
          plots, this_b_lon_conj[0], this_b_lat_conj[0], psym=4, symsize=desymsize*0.85, color=254
        endif
        if (this_b_lat_conj[count-1] lt 80) and (this_b_lat_conj[count-1] gt -80) then begin
          plots, this_b_lon_conj[count-1], this_b_lat_conj[count-1], psym=2, symsize=desymsize, color=254 ;*
          plots, this_b_lon_conj[count-1], this_b_lat_conj[count-1], psym=2, symsize=desymsize*0.92, color=254
          plots, this_b_lon_conj[count-1], this_b_lat_conj[count-1], psym=2, symsize=desymsize*0.85, color=254
        endif
        if (this_b_lat_conj[count/2] lt 80) and (this_b_lat_conj[count/2] gt -80) then begin
          plots, this_b_lon_conj[count/2], this_b_lat_conj[count/2], psym=5, symsize=desymsize, color=254 ;triangle
          plots, this_b_lon_conj[count/2], this_b_lat_conj[count/2], psym=5, symsize=desymsize*0.92, color=254 ;triangle
          plots, this_b_lon_conj[count/2], this_b_lat_conj[count/2], psym=5, symsize=desymsize*0.85, color=254 ;triangle
        endif
      endelse

      ;---------------------
      ; ADD Tick Marks
      ;---------------------
      if ~keyword_set(bfirst) then begin
        plots, this_b_lon_conj[istepsb], this_b_lat_conj[istepsb], psym=1, symsize=desymsize*1, color=254, clip=[-180, -78, 180, 78], NOCLIP=0 ;plus sign
 ;       plots, this_a_lon_conj[istepsa], this_a_lat_conj[istepsa], psym=1, symsize=desymsize*1, color=253, clip=[-180, -78, 180, 78], NOCLIP=0
      endif else begin
 ;       plots, this_a_lon_conj[istepsa], this_a_lat_conj[istepsa], psym=1, symsize=desymsize*1, color=253, clip=[-180, -78, 180, 78], NOCLIP=0
        plots, this_b_lon_conj[istepsb], this_b_lat_conj[istepsb], psym=1, symsize=desymsize*1, color=254, clip=[-180, -78, 180, 78], NOCLIP=0
      endelse

  ;    index_equ_a=where(abs(this_a_lat_conj) lt 0.5) ;when cross equator
      index_equ_b=where(abs(this_b_lat_conj) lt 0.5)
  ;    if this_a_lon_conj[index_equ_a[0]] lt this_b_lon_conj[index_equ_b[0]] then begin ;a is on the left of b
  ;      ;add elfa number label
  ;      for i=1,n_elements(istepsa)-1 do begin
  ;        if abs(this_a_lat_conj[istepsa[i]]) lt 78 then begin
  ;          tick_label=strtrim(string(fix(istepsa(i)/60)),2)
  ;          xyouts,this_a_lon_conj[istepsa[i]]-10,this_a_lat_conj[istepsa[i]]-4,tick_label,alignment=0.0,charsize=decharsize*1.2,color=253, charthick=decharthick*2
  ;        endif
  ;      endfor

        ;add elfb number label
        for i=1,n_elements(istepsb)-1 do begin
          if abs(this_b_lat_conj[istepsb[i]]) lt 78 then begin
            tick_label=strtrim(string(fix(istepsb(i)/60)),2)
            xyouts,this_b_lon_conj[istepsb[i]]+10,this_b_lat_conj[istepsb[i]]+1,tick_label,alignment=1.0,charsize=decharsize*1.2,color=254, charthick=decharthick*2
          endif
        endfor
 ;     endif else begin
        ;add elfa number label
;        for i=1,n_elements(istepsa)-1 do begin
;          if abs(this_a_lat_conj[istepsa[i]]) lt 78 then begin
;            tick_label=strtrim(string(fix(istepsa(i)/60)),2)
;            xyouts,this_a_lon_conj[istepsa[i]]+2,this_a_lat_conj[istepsa[i]]+1,tick_label,alignment=0.0,charsize=decharsize*1.2,color=253, charthick=decharthick*2
;          endif
;        endfor

        ;add elfb number label
        for i=1,n_elements(istepsb)-1 do begin
          if abs(this_b_lat_conj[istepsb[i]]) lt 78 then begin
            tick_label=strtrim(string(fix(istepsb(i)/60)),2)
            xyouts,this_b_lon_conj[istepsb[i]]-2,this_b_lat_conj[istepsb[i]]+1,tick_label,alignment=1.0,charsize=decharsize*1.2,color=254, charthick=decharthick*2
          endif
        endfor
;      endelse

      latlon_text='Mag Lat/Lon - Red dotted lines'
      yann1=1-0.03
      xann=1-0.015
      dyann=0.013
      yann2=0.015
      xyouts, xann,yann1-dyann*0,'Mercator View Center Time (triangle)',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*1,'Thick - Science (FGM and/or EPD)',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*2,'Geo Lat/Lon - Black dotted lines',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*3, latlon_text,/normal,color=250,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*4,'Tick Marks every 5min from '+hr_ststr[k]+':00 UTC',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*5,'Start Time-Diamond',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*6,'End Time-Asterisk',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*7,'Terminator: ground-thick solid',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*8,'EISCAT-Purple Triangle',/normal,color=248,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*9,'VLF-Green Square',/normal,color=249,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*10,'100 km-thin solid',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann1-dyann*11,'400 km-dashed',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts,  xann, yann2+dyann*0, 'Created: '+systime(),/normal,color=255, charsize=decharsize, alignment=1,charthick=decharthick       ; add time of creation
      case 1 of
        tsyg_mod eq 't89': xyouts,xann,yann2+dyann*1,'Tsyganenko-1989',/normal,charsize=decharsize,color=255, alignment=1,charthick=decharthick
        tsyg_mod eq 't96': xyouts,xann,yann2+dyann*1,'Tsyganenko-1996',/normal,charsize=decharsize,color=255, alignment=1,charthick=decharthick
        tsyg_mod eq 't01': xyouts,xann,yann2+dyann*1,'Tsyganenko-2001',/normal,charsize=decharsize,color=255, alignment=1,charthick=decharthick
      endcase

      xyouts, xann,yann3-dyann*0,'Mercator View Center Time (triangle)',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*1,'Thick - Science (FGM and/or EPD)',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*2,'Geo Lat/Lon - Black dotted lines',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*3, latlon_text,/normal,color=250,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*4,'Tick Marks every 5min from '+hr_ststr[k]+':00 UTC',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*5,'Start Time-Diamond',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*6,'End Time-Asterisk',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*7,'Terminator: ground-thick solid',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*8,'EISCAT-Purple Triangle',/normal,color=248,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*9,'VLF-Green Square',/normal,color=249,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*10,'100 km-thin solid',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts, xann,yann3-dyann*11,'400 km-dashed',/normal,color=255,charsize=decharsize, alignment=1,charthick=decharthick
      xyouts,  xann, yann4+dyann*0, 'Created: '+systime(),/normal,color=255, charsize=decharsize, alignment=1,charthick=decharthick       ; add time of creation
      case 1 of
        tsyg_mod eq 't89': xyouts,xann,yann4+dyann*1,'Tsyganenko-1989',/normal,charsize=decharsize,color=255, alignment=1,charthick=decharthick
        tsyg_mod eq 't96': xyouts,xann,yann4+dyann*1,'Tsyganenko-1996',/normal,charsize=decharsize,color=255, alignment=1,charthick=decharthick
        tsyg_mod eq 't01': xyouts,xann,yann4+dyann*1,'Tsyganenko-2001',/normal,charsize=decharsize,color=255, alignment=1,charthick=decharthick
      endcase


      ;--------------------------------
      ; CREATE GIF
      ;--------------------------------
      if keyword_set(gifout) then begin
        ; Create small plot
        image=tvrd()
        device,/close
        ;set_plot,'x'
        set_plot,'z'
        ;image[where(image eq 255)]=1
        ;image[where(image eq 0)]=255
        if not keyword_set(noview) then begin
          window,3,xsize=xwidth,ysize=ywidth
        endif
        if not keyword_set(noview) then tv,image

        dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2)+'/'+strmid(date,8,2)+'/'
        file_mkdir, dir_products
        ;filedate=file_dailynames(trange=tr+[0, -1801.], /unique, times=times)

        filedate=file_dailynames(trange=filetime[0], /unique, times=times)

        plot_name = 'mercator'
        if kk eq 0 then pcenter = '_0glon' else pcenter = '_180glon'

        coord_name='_'
        pname='elf'
        gif_name=dir_products+'/'+pname+'_l2_'+plot_name+coord_name+filedate+file_lbl[k]+pcenter

        if hires then gif_name=gif_name+'_hires' else gif_name=gif_name
        write_gif,gif_name+'.gif',image,r,g,b
        print,'Output in ',gif_name+'.gif'
        if keyword_set(insert_stop) then stop

      endif
    endfor
    if keyword_set(insert_stop) then stop
    if keyword_set(one_hour_only) then break

  endfor ; end of plotting loop

  pro_end_time=SYSTIME(/SECONDS)
  print, SYSTIME(), ' -- Finished creating overview plots'
  print, 'Duration (s): ', pro_end_time - pro_start_time

end
