;+mercator plot with only conjugate hemisphere tracing
;

pro elf_map_state_t96_intervals_mercator_conjugate, tstart, gifout=gifout, south=south, noview=noview,$
  model=model, dir_move=dir_move, insert_stop=insert_stop, hires=hires, $
  no_trace=no_trace, tstep=tstep, clean=clean, quick_trace=quick_trace, pred=pred, $
  sm=sm, bfirst=bfirst, one_hour_only=one_hour_only

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

  set_plot,'z'     ; z-buffer
  device,set_resolution=[800,630]
  tvlct,r,g,b,/get

  ; set symbols
  symbols=[4, 2]
  probes=['a','b']
  index=[254,253,252]  

  ; set colors
  ;ELFIN A Blue
  r[index[1]]=0 & g[index[1]]=0  & b[index[1]]=255 ;blue
  ;ELFIN B Orange
  r[index[0]]=255 & g[index[0]]=99 & b[index[0]]=71
  ;Grey (for RHS SM orbit plots)
  r[index[2]]=170 & g[index[2]]=170 & b[index[2]]=170
  tvlct,r,g,b

  ; time input
  timespan,tstart,1,/day ;set tplot time range
  tr=timerange()
  tr[1]=tr[1]+60.*30 ; add 30 minutes into next day
  tend=time_string(time_double(tstart)+86400.0d0)
  lim=2
  earth=findgen(361)
  launch_date = time_double('2018-09-16')

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
  for sc=0,1 do begin

    ; reset timespan (attitude solution could be days old)
    timespan,tstart,88200.,/sec
    tr=timerange()

    ; GET POSITION VELOCITY
    if ~keyword_set(pred) then elf_load_state,probe=probes[sc] else elf_load_state,probe=probes[sc], /pred  ;, no_download=no_download
    get_data,'el'+probes[sc]+'_pos_gei',data=dats, dlimits=dl, limits=l  ; position in GEI
    elf_convert_state_gei2sm, probe=probes[sc]
    get_data,'el'+probes[sc]+'_pos_geo',data=dpos_geo
    get_data,'el'+probes[sc]+'_pos_sm',data=dpos_sm
    ;high latitude tracing should be avoid
    ;use latitude limit to determine the area of tracing 
    ;I use SM latitude <70 degree here
    pos_lon = !radeg * atan2(dpos_sm.y[*,1],dpos_sm.y[*,0])
    pos_lat = !radeg * atan(dpos_sm.y[*,2],sqrt(dpos_sm.y[*,0]^2+dpos_sm.y[*,1]^2))
    pos_lat_min = pos_lat[0:*:60]

    ;----------------------------------
    ; using Br to seperate into two hemisphere tracing
    ;----------------------------------
    tt89,'el'+probes[sc]+'_pos_gsm', kp=2,newname='el'+probes[sc]+'_bt89_gsm',/igrf_only
    tdotp,'el'+probes[sc]+'_bt89_gsm','el'+probes[sc]+'_pos_gsm',newname='el'+probes[sc]+'_Br_sign'

    ;no quick trace setup
    get_data,'el'+probes[sc]+'_Br_sign',data=Br_sign_tmp
    ;do not trace above 70 degree SM latitude
    north_index=where((Br_sign_tmp.y gt 0.) and (abs(pos_lat) lt 70.), north_index_count) ;locate in south but should trace to north
    south_index=where((Br_sign_tmp.y lt 0.) and (abs(pos_lat) lt 70.), south_index_count) ;locate in north but should trace to south
    get_data, 'el'+probes[sc]+'_pos_gsm', data=pos_gsm
    store_data, 'el'+probes[sc]+'_pos_gsm_north', data={x:pos_gsm.x[north_index], y: pos_gsm.y[north_index,*]}
    store_data, 'el'+probes[sc]+'_pos_gsm_south', data={x:pos_gsm.x[south_index], y: pos_gsm.y[south_index,*]}

    ;quick trace
    if keyword_set(quick_trace) then begin
      store_data, 'el'+probes[sc]+'_Br_sign_mins', data={x: Br_sign_tmp.x[0:*:60], y: Br_sign_tmp.y[0:*:60,*]}
      get_data,'el'+probes[sc]+'_Br_sign_mins',data=Br_sign_tmp_mins
      north_index_mins=where((Br_sign_tmp_mins.y gt 0.) and (abs(pos_lat_min) lt 70.), north_index_mins_count) ;locate in south but should trace to north
      south_index_mins=where((Br_sign_tmp_mins.y lt 0.) and (abs(pos_lat_min) lt 70.), south_index_mins_count) ;locate in north but should trace to south
      store_data, 'el'+probes[sc]+'_pos_gsm_mins', data={x: pos_gsm.x[0:*:60], y: pos_gsm.y[0:*:60,*]}
      get_data, 'el'+probes[sc]+'_pos_gsm_mins', data=pos_gsm_mins
      store_data, 'el'+probes[sc]+'_pos_gsm_north_mins', data={x:pos_gsm_mins.x[north_index_mins], y: pos_gsm_mins.y[north_index_mins,*]}
      store_data, 'el'+probes[sc]+'_pos_gsm_south_mins', data={x:pos_gsm_mins.x[south_index_mins], y: pos_gsm_mins.y[south_index_mins,*]}
    endif


    ;----------------------------------
    ; trace steup
    ;----------------------------------
    ; Set up for quick_trace -> do only every 60th point (i.e. per minute)
    count=n_elements(pos_gsm.x)
    if keyword_set(quick_trace) then begin
      tsyg_param_count_north=north_index_mins_count
      tsyg_param_count_south=south_index_mins_count
    endif else begin
      tsyg_param_count_north=north_index_count
      tsyg_param_count_south=south_index_count
    endelse
    case 1 of  ; north
      (tsyg_mod eq 't89'): tsyg_parameter_north=2.0d
      (tsyg_mod eq 't96'): tsyg_parameter_north=[[replicate(dynp,tsyg_param_count_north)], $
        [replicate(dst,tsyg_param_count_north)],[replicate(bswy,tsyg_param_count_north)],[replicate(bswz,tsyg_param_count_north)],$
        [replicate(0.,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)],$
        [replicate(0.,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)]]
      (tsyg_mod eq 't01'): tsyg_parameter_north=[[replicate(dynp,tsyg_param_count_north)],$
        [replicate(dst,tsyg_param_count_north)],[replicate(bswy,tsyg_param_count_north)],[replicate(bswz,tsyg_param_count_north)],$
        [replicate(g1,tsyg_param_count_north)],[replicate(g2,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)],$
        [replicate(0.,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)],[replicate(0.,tsyg_param_count_north)]]
      else: begin
        print,'Unknown Tsyganenko model'
        return
      end
    endcase
    case 1 of ; south
      (tsyg_mod eq 't89'): tsyg_parameter_south=2.0d
      (tsyg_mod eq 't96'): tsyg_parameter_south=[[replicate(dynp,tsyg_param_count_south)], $
        [replicate(dst,tsyg_param_count_south)],[replicate(bswy,tsyg_param_count_south)],[replicate(bswz,tsyg_param_count_south)],$
        [replicate(0.,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)],$
        [replicate(0.,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)]]
      (tsyg_mod eq 't01'): tsyg_parameter_south=[[replicate(dynp,tsyg_param_count_south)],$
        [replicate(dst,tsyg_param_count_south)],[replicate(bswy,tsyg_param_count_south)],[replicate(bswz,tsyg_param_count_south)],$
        [replicate(g1,tsyg_param_count_south)],[replicate(g2,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)],$
        [replicate(0.,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)],[replicate(0.,tsyg_param_count_south)]]
      else: begin
        print,'Unknown Tsyganenko model'
        return
      end
    endcase


    ; for development convenience only (ttrace2iono takes a long time)
    if keyword_set(no_trace) then goto, skip_trace

    ;----------------------------------
    ; trace to ionosphere
    ;----------------------------------
    ; Use quick trace (high resolution not needed)
    if keyword_set(quick_trace) then begin
      ;  south trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_south_mins',newname='el'+probes[sc]+'_ifoot_gsm_south_mins', $
        external_model=tsyg_mod,par=tsyg_parameter_south,R0= 1.0156 ,/km,/south
      ;  north trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_north_mins',newname='el'+probes[sc]+'_ifoot_gsm_north_mins', $
        external_model=tsyg_mod,par=tsyg_parameter_north,R0= 1.0156,/km
      ; combine north and south data
      get_data,'el'+probes[sc]+'_ifoot_gsm_south_mins',data=ifoot_mins_south
      get_data,'el'+probes[sc]+'_ifoot_gsm_north_mins',data=ifoot_mins_north
      ifoot_mins=make_array(n_elements(pos_gsm_mins.x),3, value= !values.f_nan)
      ifoot_mins[south_index_mins,*]=ifoot_mins_south.y[*,*]
      ifoot_mins[north_index_mins,*]=ifoot_mins_north.y[*,*]
      ;some high latitude points have been tracing to magnetopshere
      ;exclude footprints not in ionosphere
      ex_points=where(sqrt(ifoot_mins[*,0]^2+ifoot_mins[*,1]^2+ifoot_mins[*,2]^2) gt 7000)
      ifoot_mins[ex_points,*]=!values.f_nan
      ; interpolate the minute-by-minute data back to the full array
      store_data,'el'+probes[sc]+'_ifoot_gsm',data={x: dats.x, y: interp(ifoot_mins[*,*], pos_gsm_mins.x, dats.x)}

      ; clean up the temporary data
      del_data, '*_mins'
    endif else begin ; not quick trace
      ;  south trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_south',newname='el'+probes[sc]+'_ifoot_gsm_south', $
        external_model=tsyg_mod,par=tsyg_parameter_south,R0= 1.0156 ,/km,/south
      ;  north trace
      ttrace2iono,'el'+probes[sc]+'_pos_gsm_north',newname='el'+probes[sc]+'_ifoot_gsm_north', $
        external_model=tsyg_mod,par=tsyg_parameter_north,R0= 1.0156 ,/km
      ; combine north and south data
      get_data,'el'+probes[sc]+'_ifoot_gsm_south',data=ifoot_south
      get_data,'el'+probes[sc]+'_ifoot_gsm_north',data=ifoot_north
      ifoot=make_array(n_elements(pos_gsm.x),3, value= !values.f_nan)
      ifoot[south_index,*]=ifoot_south.y[*,*]
      ifoot[north_index,*]=ifoot_north.y[*,*]
      ;exclude points that havn't trace to ionosphere
      ex_points=where(sqrt(ifoot[*,0]^2+ifoot[*,1]^2+ifoot[*,2]^2) gt 7000)
      ifoot[ex_points,*]=!values.f_nan
      store_data,'el'+probes[sc]+'_ifoot_gsm',data={x: dats.x, y: ifoot[*,*]}
    endelse

    skip_trace:

    ; CONVERT coordinate system to geo and sm
    cotrans, 'el'+probes[sc]+'_ifoot_gsm', 'el'+probes[sc]+'_ifoot_gse', /gsm2gse
    cotrans, 'el'+probes[sc]+'_ifoot_gsm', 'el'+probes[sc]+'_ifoot_sm', /gsm2sm
    cotrans, 'el'+probes[sc]+'_ifoot_gse', 'el'+probes[sc]+'_ifoot_gei', /gse2gei
    cotrans, 'el'+probes[sc]+'_ifoot_gei', 'el'+probes[sc]+'_ifoot_geo', /gei2geo

    print,'Done '+tsyg_mod+' ',probes[sc]

  endfor  ; END of SC Loop

  ;---------------------------
  ; COLLECT DATA FOR PLOTS
  ;--------------------------
  ; Get science collection times
  trange=[time_double(tstart), time_double(tend)]
  epda_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='epd')
  epdb_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='b', instrument='epd') 

  ; Get position and attitude
  get_data,'ela_pos_sm',data=ela_state_pos_sm
  get_data,'elb_pos_sm',data=elb_state_pos_sm
  get_data,'ela_pos_gsm',data=ela_state_pos_gsm
  get_data,'elb_pos_gsm',data=elb_state_pos_gsm

  ; Get MLT
  elf_mlt_l_lat,'ela_pos_sm',MLT0=MLTA,L0=LA,LAT0=latA ;;subroutine to calculate mlt,l,mlat under dipole configuration
  elf_mlt_l_lat,'elb_pos_sm',MLT0=MLTB,L0=LB,LAT0=latB ;;subroutine to calculate mlt,l,mlat under dipole configuration

  ; Create attitude info for plot text
  get_data, 'ela_spin_orbnorm_angle', data=norma
  get_data, 'ela_spin_sun_angle', data=suna
  get_data, 'ela_att_solution_date', data=solna
  get_data, 'ela_att_gei',data=attgeia
  if size(attgeia, /type) EQ 8 then cotrans, 'ela_att_gei', 'ela_att_gse', /gei2gse
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
  res=where(ela_state_pos_sm.y[*,1] GE 0, ncnt) ;sm x component
  find_interval, res, sres, eres
  at_ag=(ela_state_pos_sm.x[eres]-ela_state_pos_sm.x[sres])/60.*2  ;x is time
  at_s=ela_state_pos_sm.x[sres]
  an_ag = n_elements([at_ag])
  if an_ag GT 1 then med_ag=median([at_ag]) else med_ag=at_ag
  badidx = where(at_ag LT 80.,ncnt)
  if ncnt GT 0 then at_ag[badidx]=med_ag  ;replace the first one with median
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
  checka=n_elements(ela_state_pos_sm.x)
  checkb=n_elements(elb_state_pos_sm.x)
  for m=0,23 do begin
    this_s = tr[0] + m*3600.
    this_e = this_s + 90.*60.
    if checkb LT checka then begin
      idx = where(elb_state_pos_sm.x GE this_s AND elb_state_pos_sm.x LT this_e, ncnt)
    endif else begin
      idx = where(ela_state_pos_sm.x GE this_s AND ela_state_pos_sm.x LT this_e, ncnt)
    endelse
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

  ;----------------------------------
  ; Start Plots
  ;----------------------------------
  for k=0,nplots-1 do begin

    !p.multi=0
    if keyword_set(gifout) then begin
      set_plot,'z'
      if hires then device,set_resolution=[1200,900] else device,set_resolution=[800,630]
      charsize=1
    endif else begin
      set_plot,'win'   
      window,xsize=800,ysize=630
      charsize=1
    endelse

    ; annotate constants
    ;xann=100
    if hires then yann=780 else yann=500

    ;;;; Jiang Liu edit here
    this_time=ela_state_pos_sm.x[min_st[k]:min_en[k]]
    midpt=n_elements(this_time)/2.
    tdate = this_time[midpt]

    ;;;;; spacecraft location
    for sc = 0,1 do begin

      get_data, 'el'+probes[sc]+'_ifoot_geo', data = ifoot_geo
      ifoot = ifoot_geo

      ;----------------------------
      ; CONVERT TRACE to LAT LON
      ;----------------------------
      get_data,'el'+probes[sc]+'_pos_geo',data=dpos_geo
      Case sc of
        ; ELFIN A
        0: begin
          lon = !radeg * atan2(ifoot.y[*,1],ifoot.y[*,0])
          lat = !radeg * atan(ifoot.y[*,2],sqrt(ifoot.y[*,0]^2+ifoot.y[*,1]^2))
          dposa=dpos_geo
          lona_all=lon
          lata_all=lat
        end

        ; ELFIN B
        1: begin
          lon2 = !radeg * atan2(ifoot.y[*,1],ifoot.y[*,0])
          lat2 = !radeg * atan(ifoot.y[*,2],sqrt(ifoot.y[*,0]^2+ifoot.y[*,1]^2))
          dposb=dpos_geo
          lonb_all=lon2
          latb_all=lat2
        end
      Endcase
    endfor
    ;;;;; end of Jiang Liu edit


    ; find midpt MLT for this orbit track
    midx=min_st[k] + (min_en[k] - min_st[k])/2.
    mid_time_struc=time_struct(ela_state_pos_sm.x[midx])
    mid_hr=mid_time_struc.hour + mid_time_struc.min/60.
    mid_hr=midhrs[k]  ;mid UT

    ; -------------------------------------
    ; MAP PLOT
    ; -------------------------------------
    ; set up map
    coord='Conjugate Geographic'
    if keyword_set(pred) then pred_str='Predicted ' else pred_str=''
    title=pred_str+coord+' Footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
    map_set,0,0,0, /mercator, /conti, position=[0.02,0.01,0.98,0.98], charsize=.7, /isotropic
    xyouts, (!X.Window[1] - !X.Window[0]) / 2. + !X.Window[0], 0.975, title, $
      /Normal, Alignment=0.5, Charsize=1.25
    map_grid,latdel=10.,londel=30., label=1, charsize=0.7
    map_continents, color=252
    ;----------------------
    ;;; MAG Coords
    ;----------------------
    for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1 ;latitude rings
    ; plot geomagnetic equator
    ; (nmlats-1)/2 is equator index
    equ_lon=(v_lon[(nmlats-1)/2-1,*]+v_lon[(nmlats-1)/2+1,*])/2
    equ_lat=(v_lat[(nmlats-1)/2-1,*]+v_lat[(nmlats-1)/2+1,*])/2
    oplot,equ_lon,equ_lat,color=248,thick=contour_thick,linestyle=1
    for i=0,nmlons-1 do begin
      idx=where(u_lon[i,*] NE 0)
      oplot,u_lon[i,idx],u_lat[i,idx],color=248,thick=contour_thick,linestyle=1
    endfor

    ; Set up data for ELFIN A for this time span
    this_time=ela_state_pos_sm.x[min_st[k]:min_en[k]]
    nptsa=n_elements(this_time)
    this_lon=lon[min_st[k]:min_en[k]]
    this_lat=lat[min_st[k]:min_en[k]]
    this_ax=ela_state_pos_sm.y[min_st[k]:min_en[k],0]
    this_ay=ela_state_pos_sm.y[min_st[k]:min_en[k],1]
    this_az=ela_state_pos_sm.y[min_st[k]:min_en[k],2]
    this_dposa=dposa.y[min_st[k]:min_en[k],2]
    this_a_alt = mean(sqrt(this_ax^2 + this_ay^2 + this_az^2))-6371.
    this_a_alt_str = strtrim(string(this_a_alt),1)
    if size(attgeia, /type) EQ 8 then begin
      min_a_att_gei=min(abs(ela_state_pos_sm.x[midx]-attgeia.x),agei_idx) ;agei_idex min subscript
      min_a_att_gse=min(abs(ela_state_pos_sm.x[midx]-attgsea.x),agse_idx)
      this_a_att_gei = attgeia.y[agei_idx,*]
      this_a_att_gse = attgsea.y[agse_idx,*]
    endif
    undefine, this_a_sz_st
    undefine, this_a_sz_en
    if ~undefined(epda_sci_zones) && size(epda_sci_zones, /type) EQ 8 then begin
      idx=where(epda_sci_zones.starts GE this_time[0] and epda_sci_zones.starts LT this_time[nptsa-1], azones)
      if azones GT 0 then begin
        this_a_sz_st=epda_sci_zones.starts[idx]
        this_a_sz_en=epda_sci_zones.ends[idx]
        if epda_sci_zones.ends[azones-1] GT this_time[nptsa-1] then this_a_sz_en[azones-1]=this_time[nptsa-1]
      endif
    endif

    ; repeat for ELFIN B
    this_time2=elb_state_pos_sm.x[min_st[k]:min_en[k]]
    nptsb=n_elements(this_time2)
    this_lon2=lon2[min_st[k]:min_en[k]]
    this_lat2=lat2[min_st[k]:min_en[k]]
    this_bx=elb_state_pos_sm.y[min_st[k]:min_en[k],0]
    this_by=elb_state_pos_sm.y[min_st[k]:min_en[k],1]
    this_bz=elb_state_pos_sm.y[min_st[k]:min_en[k],2]
    this_dposb=dposb.y[min_st[k]:min_en[k],2]
    this_b_alt = mean(sqrt(this_bx^2 + this_by^2 + this_bz^2))-6371.
    this_b_alt_str = strtrim(string(this_b_alt),1)
    if size(attgeib, /type) EQ 8 then begin
      min_b_att_gei=min(abs(elb_state_pos_sm.x[midx]-attgeib.x),bgei_idx)
      min_b_att_gse=min(abs(elb_state_pos_sm.x[midx]-attgseb.x),bgse_idx)
      this_b_att_gei = attgeib.y[bgei_idx,*]
      this_b_att_gse = attgseb.y[bgse_idx,*]
    endif
    ;;;; Jiang Liu edit: to reduce errors for the ease of debugging
    undefine, this_b_sz_st
    undefine, this_b_sz_en
    ;    if ~undefined(epdb_sci_zones) && epdb_sci_zones.starts[0] NE -1 then begin
    ;       idx=where(epdb_sci_zones.starts GE this_time2[0] and epdb_sci_zones.starts LT this_time2[nptsb-1], bzones)
    ;       if bzones GT 0 then begin
    ;         this_b_sz_st=epdb_sci_zones.starts[idx]
    ;         this_b_sz_en=epdb_sci_zones.ends[idx]
    ;         if epdb_sci_zones.ends[bzones-1] GT this_time2[nptsb-1] then this_b_sz_en[bzones-1]=this_time2[nptsb-1]
    ;       endif
    ;    endif
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
      oplot, this_lon2[0:*:5], this_lat2[0:*:5], color=254, linestyle=2
      oplot, this_lon[0:*:5], this_lat[0:*:5], color=253, linestyle=2
    endif else begin
      oplot, this_lon[0:*:5], this_lat[0:*:5], color=253, linestyle=2
      oplot, this_lon2[0:*:5], this_lat2[0:*:5], color=254, linestyle=2
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

    ; Repeat for A
    spin_stra=''
    get_data, 'ela_pef_spinper', data=spina ; spin period  
    if size(spina, /type) EQ 8 then begin
      spin_idxa=where(spina.x GE this_time2[0] AND spina.x LT this_time2[nptsa-1], ncnt)
      if ncnt GT 5 then begin
        med_spina=median(spina.y[spin_idxa])
        spin_vara=stddev(spina.y[spin_idxa])*100.
        spin_stra='Median Spin Period, s: '+strmid(strtrim(string(med_spina), 1),0,4) + $
          ', % of Median: '+strmid(strtrim(string(spin_vara), 1),0,4)
      endif
    endif

    ; ------------------------------
    ; PLOT science collection
    ;-------------------------------
    if ~keyword_set(bfirst) then begin
      if ~undefined(this_b_sz_st) then begin
        for sci=0, n_elements(bzones)-1 do begin
          tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
          if bcnt GT 5 then begin
            plots, this_lon2[tidxb], this_lat2[tidxb], psym=2, symsize=.25, color=254, thick=3
          endif
        endfor
      endif
      if ~undefined(this_a_sz_st) then begin
        for sci=0, azones-1 do begin
          tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
          if acnt GT 5 then begin
            plots, this_lon[tidxa], this_lat[tidxa], psym=2, symsize=.25, color=253, thick=3
          endif
        endfor
      endif
    endif else begin
      if ~undefined(this_a_sz_st) then begin
        for sci=0, azones-1 do begin
          tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
          if acnt GT 5 then begin
            plots, this_lon[tidxa], this_lat[tidxa], psym=2, symsize=.25, color=253, thick=3
          endif
        endfor
      endif
      if ~undefined(this_b_sz_st) then begin
        for sci=0, n_elements(bzones)-1 do begin
          tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
          if bcnt GT 5 then begin
            plots, this_lon2[tidxb], this_lat2[tidxb], psym=2, symsize=.25, color=254, thick=3
          endif
        endfor
      endif
    endelse

    ;-----------------------------------------
    ; Plot dataset start/stop position markers
    ; ----------------------------------------
    ; elfinb
    if ~keyword_set(bfirst) then begin
      count=nptsb   ;n_elements(this_lon2)
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.9, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.9, color=254 ;*
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.75, color=254 ;diamond
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.75, color=254
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.6, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.6, color=254
      ;plots, this_lon2[count/2], this_lat2[count/2], psym=5, symsize=1.9, color=254 ;triangle
      ; elfina
      count=nptsa    ;n_elements(this_lon)
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.9, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.9, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.75, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.75, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.6, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.6, color=253
      ;plots, this_lon[count/2], this_lat[count/2], psym=5, symsize=1.9, color=253
    endif else begin
      ; elfina
      count=nptsa    ;n_elements(this_lon)
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.9, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.9, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.75, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.75, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.6, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.6, color=253
      ;plots, this_lon[count/2], this_lat[count/2], psym=5, symsize=1.9, color=253
      count=nptsb   ;n_elements(this_lon2)
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.9, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.9, color=254
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.75, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.75, color=254
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.6, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.6, color=254
      ;plots, this_lon2[count/2], this_lat2[count/2], psym=5, symsize=1.9, color=254
    endelse

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
      plots, this_lon2[istepsb], this_lat2[istepsb], psym=1, symsize=1.35, color=254, clip=[-180, -78, 180, 78], NOCLIP=0
      plots, this_lon[istepsa], this_lat[istepsa], psym=1, symsize=1.35, color=253, clip=[-180, -78, 180, 78], NOCLIP=0
    endif else begin
      plots, this_lon[istepsa], this_lat[istepsa], psym=1, symsize=1.35, color=253, clip=[-180, -78, 180, 78], NOCLIP=0
      plots, this_lon2[istepsb], this_lat2[istepsb], psym=1, symsize=1.35, color=254, clip=[-180, -78, 180, 78], NOCLIP=0
    endelse

    ;add elfa number label
    for i=1,n_elements(istepsa)-1 do begin
      if abs(this_lat[istepsa[i]]) lt 78 then begin
        tick_label=strtrim(string(fix(istepsa(i)/60)),2)
        xyouts,this_lon[istepsa[i]]+1,this_lat[istepsa[i]]+0.5,tick_label,alignment=0.0,charsize=.75,color=253
      endif
    endfor

    ;add elfb number label
    for i=1,n_elements(istepsb)-1 do begin
      if abs(this_lat2[istepsb[i]]) lt 78 then begin
        tick_label=strtrim(string(fix(istepsb(i)/60)),2)
        xyouts,this_lon2[istepsb[i]]-1,this_lat2[istepsb[i]]+0.5,tick_label,alignment=1.0,charsize=.75,color=254
      endif
    endfor

    ; get spin angle
    if size(attgeia, /type) EQ 8 then begin  ;a
      elf_calc_sci_zone_att,probe='a',trange=[this_time[0],this_time[n_elements(this_time)-1]], $
        lat=lata[min_st[k]:min_en[k]]*!radeg
      ela_spin_att_ang_str = elf_make_spin_att_string(probe='a')
    endif else begin
      ela_spin_att_ang_str = 'B/SP: not available'
    endelse
    if size(attgeib, /type) EQ 8 then begin    ;b
      elf_calc_sci_zone_att,probe='b',trange=[this_time2[0],this_time2[n_elements(this_time2)-1]], $
        lat=latb[min_st[k]:min_en[k]]*!radeg
      elb_spin_att_ang_str = elf_make_spin_att_string(probe='b')
    endif else begin
      elb_spin_att_ang_str = 'B/SP: not available'
    endelse

    ;-----------------------------------------
    ; Create Text for Annotations
    ;-----------------------------------------
    ; find total orbit time for this plot
    idx = where(at_s GE this_time[0], ncnt)
    if ncnt EQ 0 then idx=0
    a_period_str = strmid(strtrim(string(at_ag[idx[0]]), 1),0,5)
    idx = where(bt_s GE this_time2[0], ncnt)
    if ncnt EQ 0 then idx=0
    b_period_str = strmid(strtrim(string(bt_ag[idx[0]]), 1),0,5) ;strtrim delete blank strmid extract from 0-5

    ; get spin period and add to total orbit time
    ; elfin a
    a_rpm=elf_load_att(probe='a', tdate=ela_state_pos_sm.x[min_st[k]])
    a_sp=60./a_rpm
    a_spinper = strmid(strtrim(string(a_sp),1),0,4)
    a_rpm_str = strmid(strtrim(string(a_rpm),1),0,5)
    a_orb_spin_str='Torb='+a_period_str+'min; Tspin='+a_spinper+'s ['+a_rpm_str+'RPM]'
    ; elfin b
    ; ******get spin period routines******
    b_rpm=elf_load_att(probe='b', tdate=ela_state_pos_sm.x[min_st[k]])
    b_sp=60./b_rpm
    b_spinper = strmid(strtrim(string(b_sp),1),0,4)
    b_rpm_str = strmid(strtrim(string(b_rpm),1),0,5)
    b_orb_spin_str='Torb='+b_period_str+'min; Tspin='+b_spinper+'s ['+b_rpm_str+'RPM]'

    ; create attitude strings
    ; elfin a
    if size(norma,/type) EQ 8 then begin
      idx=where(norma.x GE this_time[0] and norma.x LT this_time[n_elements(this_time)-1], ncnt)
      if size(norma, /type) EQ 8 && ncnt GT 2 then $
        norma_str=strmid(strtrim(string(median(norma.y[idx])),1),0,5) $
      else norma_str = 'No att data'
      idx=where(suna.x GE this_time[0] and suna.x LT this_time[n_elements(this_time)-1], ncnt)
      if size(suna, /type) EQ 8 && ncnt GT 2 then $
        suna_str=strmid(strtrim(string(median(suna.y[idx])),1),0,5) $
      else suna_str = 'No att data'
      idx=where(solna.x GE this_time[0] and solna.x LT this_time[n_elements(this_time)-1], ncnt)
      if size(solna, /type) EQ 8 && ncnt GT 2 && solna.y[0] GT launch_date then begin
        solna_string=time_string(solna.y[0])
        solna_str=strmid(solna_string,0,4)+'-'+strmid(solna_string,5,2)+'-'+strmid(solna_string,8,2)+'/'+strmid(solna_string,11,2)
      endif else begin
        solna_str = 'No att data'
      endelse
    endif else begin
      norma_str = 'No att data'
      suna_str = 'No att data'
      solna_str = 'No att data'
    endelse
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
    if ~undefined(this_a_att_gei) then begin
      if this_a_att_gei[0] GE 0. then offset=5 else offset=6
      a_att_gei_x_str = strmid(strtrim(string(this_a_att_gei[0]),1),0,offset)
      if this_a_att_gei[1] GE 0. then offset=5 else offset=6
      a_att_gei_y_str = strmid(strtrim(string(this_a_att_gei[1]),1),0,offset)
      if this_a_att_gei[2] GE 0. then offset=5 else offset=6
      a_att_gei_z_str = strmid(strtrim(string(this_a_att_gei[2]),1),0,offset)
      a_att_gei_str = 'S: ['+a_att_gei_x_str+','+a_att_gei_y_str+','+a_att_gei_z_str+'] GEI'
    endif else begin
      a_att_gei_str = 'S: not available'
    endelse
    if ~undefined(this_a_att_gse) then begin
      if this_a_att_gse[0] GE 0. then offset=5 else offset=6
      a_att_gse_x_str = strmid(strtrim(string(this_a_att_gse[0]),1),0,offset)
      if this_a_att_gse[1] GE 0. then offset=5 else offset=6
      a_att_gse_y_str = strmid(strtrim(string(this_a_att_gse[1]),1),0,offset)
      if this_a_att_gse[2] GE 0. then offset=5 else offset=6
      a_att_gse_z_str = strmid(strtrim(string(this_a_att_gse[2]),1),0,offset)
      a_att_gse_str = 'S: ['+a_att_gse_x_str+','+a_att_gse_y_str+','+a_att_gse_z_str+'] GSE'
    endif else begin
      a_att_gse_str = 'S: not available'
    endelse
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
      b_att_gse_str = 'S: ['+b_att_gse_x_str+','+b_att_gse_y_str+','+a_att_gse_z_str+'] GSE'
    endif else begin
      b_att_gse_str = 'S: not available'
    endelse

    if hires then charsize=.75 else charsize=.65
    ; annotate
    xann=17
    xyouts,xann,yann+12.5*8,'ELFIN (A)',/device,charsize=.75,color=253
    xyouts,xann,yann+12.5*7,a_orb_spin_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*6,ela_spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*5,a_att_gei_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*4,a_att_gse_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*3,'S w/Sun, deg: '+suna_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*2,'S w/OrbNorm, deg: '+norma_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*1,'Att.Solution@'+solna_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*0,'Altitude, km: '+this_a_alt_str,/device,charsize=charsize

    yann=6
    xyouts,xann,yann+12.5*9,'ELFIN (B)',/device,charsize=.75,color=254
    xyouts,xann,yann+12.5*8,b_orb_spin_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*7,elb_spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*6,b_att_gei_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*5,b_att_gse_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*4,'S w/Sun, deg: '+sunb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*3,'S w/OrbNorm, deg: '+normb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*2,'Att.Solution@: '+solnb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*1,'Altitude, km: '+this_b_alt_str,/device,charsize=charsize

    latlon_text='Mag Lat/Lon - Red dotted lines'
    oxadd=47 & lxadd=21
    if hires then begin
      yann=750
      xann=780
      xyouts, xann-5,yann+12.5*8,'Earth/Oval View Center Time (triangle)',/device,color=255,charsize=charsize
      xyouts, xann+10,yann+12.5*7,'Thick - Science (FGM and/or EPD)',/device,color=255,charsize=charsize
      xyouts, xann+18,yann+12.5*6,'Geo Lat/Lon - Black dotted lines',/device,color=255,charsize=charsize
      xyouts, xann+25,yann+12.5*5, latlon_text,/device,color=251,charsize=charsize
      ;xyouts, xann+75,yann+12.5*4,'Tick Marks every 5min from '+hr_ststr[k]+':00',/device,color=255,charsize=charsize
      xyouts, xann-10,yann+12.5*4,'Tick Marks every 5min from '+hr_ststr[k]+':00 UTC',/device,color=255,charsize=charsize
      xyouts, xann+85,yann+12.5*2,'Start Time-Diamond',/device,color=255,charsize=charsize
      xyouts, xann+95,yann+12.5*1,'End Time-Asterisk',/device,color=255,charsize=charsize
    endif else begin
      yann=500
      xann=615
      xyouts, xann-5,yann+12.5*8,'Earth/Oval View Center Time (triangle)',/device,color=255,charsize=charsize
      xyouts, xann+10,yann+12.5*7,'Thick - Science (FGM and/or EPD)',/device,color=255,charsize=charsize
      xyouts, xann+15,yann+12.5*6,'Geo Lat/Lon - Black dotted lines',/device,color=255,charsize=charsize
      xyouts, xann+lxadd,yann+12.5*5, latlon_text,/device,color=251,charsize=charsize
      ;xyouts, xann+66,yann+12.5*4,'Tick Marks every 5min from '+hr_ststr[k]+':00',/device,color=255,charsize=charsize
      xyouts, xann-10,yann+12.5*4,'Tick Marks every 5min from '+hr_ststr[k]+':00 UTC',/device,color=255,charsize=charsize
      xyouts, xann+76,yann+12.5*3,'Start Time-Diamond',/device,color=255,charsize=charsize
      xyouts, xann+85,yann+12.5*2,'End Time-Asterisk',/device,color=255,charsize=charsize
    endelse
    yann=6
    if hires then xann = 660 else xann=600
    case 1 of
      tsyg_mod eq 't89': xyouts,xann+20,yann+12.5*2,'Tsyganenko-1989',/device,charsize=charsize,color=255
      tsyg_mod eq 't96': xyouts,xann+20,yann+12.5*2,'Tsyganenko-1996',/device,charsize=charsize,color=255
      tsyg_mod eq 't01': xyouts,xann+20,yann+12.5*2,'Tsyganenko-2001',/device,charsize=charsize,color=255
    endcase


    ; add time of creation
    xyouts,  xann+20, yann+12.5, 'Created: '+systime(),/device,color=255, charsize=charsize

    ;--------------------------------
    ; CREATE GIF
    ;--------------------------------
    if keyword_set(gifout) then begin

      ; Create small plot
      image=tvrd()
      device,/close
      set_plot,'z'
      ;device,set_resolution=[1200,900]
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      if not keyword_set(noview) then window,3,xsize=800,ysize=630
      if not keyword_set(noview) then tv,image
      dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2)+'/'+strmid(date,8,2)+'/'
      file_mkdir, dir_products
      filedate=file_dailynames(trange=tr+[0, -1801.], /unique, times=times)

      plot_name = 'mercator_conj'
      coord_name='_'
      pname='elf'
      gif_name=dir_products+'/'+pname+'_l2_'+plot_name+coord_name+filedate+file_lbl[k]

      if hires then gif_name=gif_name+'_hires'
      write_gif,gif_name+'.gif',image,r,g,b
      print,'Output in ',gif_name+'.gif'

    endif

    if keyword_set(insert_stop) then stop
    if keyword_set(one_hour_only) then break

  endfor ; end of plotting loop

  pro_end_time=SYSTIME(/SECONDS)
  print, SYSTIME(), ' -- Finished creating overview plots'
  print, 'Duration (s): ', pro_end_time - pro_start_time

end
