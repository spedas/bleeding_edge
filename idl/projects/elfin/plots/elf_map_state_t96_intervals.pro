;+
;polar orbit
;JWu change south pole position in GEO plot
;
;
; NAME:
;    ELF_MAP_STATE_T96_INTERVALS
;
; PURPOSE:
;    map ELFIN spacecraft to their magnetic footprints
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    elf_map_state_t96_intervals,'2018-11-10/00:00:00'
;
; INPUTS:
;    tstart start time for the map
;
; KEYWORD PARAMETERS:
;    gifout   generate a gif image at output
;    south    use southern hemisphere (otherwise, north)
;    noview   do not open window for display
;    model    specify Tsyganenko model like 't89' or 't01', default is 't96'
;    dir_move directory name to move plots to
;    quick_trace  run ttrace2iono on smaller set of points for speed
;    tstep    use this to turn on tick marks and set the frequency in seconds
;    clean    obsolete (parameter should be removed)
;    no_trace set this flag if you already have the data in hand and calculated in
;             a previous run
;    one_hour_only: set this flag to only plot the first orbit
;    hires    set this flag to create a higher resolution plot
;    sm       set this keyword for footprint in SM coordinates, default is GEO
;    bfirst   set this keyword for probe b footprint on top (default is for a on top)
;             note that this keyword is only used if the coordinates are in SM
;    pred     set this flag to use predicted state data
;    insert_stop set this flag to stop after the first plot (used for debugging)
;
; OUTPUTS:
;    GIF images
;
; EXAMPLE:
;    elf_map_state_t96_intervals,'2018-11-10/00:00:00'   ; this will defer to defaults and plot only
;                                                        ; northern hemisphere, geographic grids in
;                                                        ; normal resolution
;
; MODIFICATION HISTORY:
;    Written by: C L Russell May 2020
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL:
;
;-
pro elf_map_state_t96_intervals, tstart, gifout=gifout, south=south, noview=noview,$
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
  if ~keyword_set(noview) then noview=1 else nonview=1
  if ~keyword_set(tstep) then tstep=1 else tstep=1
  if ~keyword_set(quick) then quick=1 else quick=1
  if ~keyword_set(gifout) then gifout=1 else gifout=1
  if ~keyword_set(quick) then quick=1
  if keyword_set(hires) then hires=1 else hires=0
  if keyword_set(sm) then ft_coord='sm' else ft_coord='geo'
  if keyword_set(pred) then pred=1 else pred=0

  elf_init
  aacgmidl
  loadct,39 ;color tables
  thm_init

  set_plot,'z'     ; z-buffer
  device,set_resolution=[750,500]
  tvlct,r,g,b,/get

  ; set symbols
  symbols=[4, 2]
  probes=['a','b']
  index=[254,253,252,249,248]  ;,252,253,254]  ;index=250 rgb=[255 0 0]

  ; set colors
  ;ELFIN A Blue
  r[index[1]]=0 & g[index[1]]=0  & b[index[1]]=255
  ;ELFIN B Orange
  r[index[0]]=255 & g[index[0]]=99 & b[index[0]]=71
  ;Grey (for RHS SM orbit plots)
  r[index[2]]=170 & g[index[2]]=170 & b[index[2]]=170  
  ; stations
; **** blue purple ok
; blue
;  r[index[3]]=135 & g[index[3]]=206 & b[index[3]]=235
; purple
;  r[index[4]]=238 & g[index[4]]=130 & b[index[4]]=238
; purple
r[index[4]]=238 & g[index[4]]=130 & b[index[4]]=238
; green
;r[index[4]]=0 & g[index[4]]=160 & b[index[4]]=0
r[index[3]]=90 & g[index[3]]=188 & b[index[3]]=102

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
    get_data,'el'+probes[sc]+'_pos_gsm',data=datgsm  ; position in SM

    ; Set up for quick_trace -> do only every 60th point (i.e. per minute)
    count=n_elements(datgsm.x)
    num=n_elements(datgsm.x)-1
    tsyg_param_count=count
    if keyword_set(quick_trace) then begin
      store_data, 'el'+probes[sc]+'_pos_gsm_mins', data={x: datgsm.x[0:*:60], y: datgsm.y[0:*:60,*]}
      tsyg_param_count=n_elements(datgsm.x[0:*:60]) ; prepare fewer replicated parameters below
    endif

    ; Setup info for Tsyganenko models
    case 1 of
      (tsyg_mod eq 't89'): tsyg_parameter=2.0d
      (tsyg_mod eq 't96'): tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
        [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
      (tsyg_mod eq 't01'): tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
        [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
        [replicate(g1,tsyg_param_count)],[replicate(g2,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
      ELSE: begin
        print,'Unknown Tsyganenko model'
        return
      endcase
    endcase

    ; for development convenience only (ttrace2iono takes a long time)
    if keyword_set(no_trace) then goto, skip_trace

    ; TRACE TO IONOSPHERE
    ; Use quick trace (high resolution not needed)
    if keyword_set(quick_trace) then begin
      if keyword_set(south) then begin
        ttrace2iono,'el'+probes[sc]+'_pos_gsm_mins',newname='el'+probes[sc]+'_ifoot_gsm_mins', $
          external_model=tsyg_mod,par=tsyg_parameter,R0= 1.0156 ,/km,/south
      endif else begin ;north
        ttrace2iono,'el'+probes[sc]+'_pos_gsm_mins',newname='el'+probes[sc]+'_ifoot_gsm_mins', $
          external_model=tsyg_mod,par=tsyg_parameter,R0= 1.0156,/km
      endelse
      ; interpolate the minute-by-minute data back to the full array
      get_data,'el'+probes[sc]+'_ifoot_gsm_mins',data=ifoot_mins
      store_data,'el'+probes[sc]+'_ifoot_gsm',data={x: dats.x, y: interp(ifoot_mins.y[*,*], ifoot_mins.x, dats.x)}
      ; clean up the temporary data
      del_data, '*_mins'
    endif else begin ; not quick trace
      if keyword_set(south) then begin
        ttrace2iono,'el'+probes[sc]+'_pos_gsm',newname='el'+probes[sc]+'_ifoot_gsm', $
          external_model=tsyg_mod,par=tsyg_parameter,R0= 1.0156 ,/km,/south
      endif else begin
        ttrace2iono,'el'+probes[sc]+'_pos_gsm',newname='el'+probes[sc]+'_ifoot_gsm', $
          external_model=tsyg_mod,par=tsyg_parameter,R0= 1.0156 ,/km
      endelse
    endelse

    skip_trace:

    ; CONVERT coordinate system to geo and sm
    cotrans, 'el'+probes[sc]+'_ifoot_gsm', 'el'+probes[sc]+'_ifoot_gse', /gsm2gse
    cotrans, 'el'+probes[sc]+'_ifoot_gsm', 'el'+probes[sc]+'_ifoot_sm', /gsm2sm
    cotrans, 'el'+probes[sc]+'_ifoot_gse', 'el'+probes[sc]+'_ifoot_gei', /gse2gei
    cotrans, 'el'+probes[sc]+'_ifoot_gei', 'el'+probes[sc]+'_ifoot_geo', /gei2geo

    tt89,'el'+probes[sc]+'_pos_gsm', kp=2,newname='el'+probes[sc]+'_bt89_gsm',/igrf_only
    tdotp,'el'+probes[sc]+'_bt89_gsm','el'+probes[sc]+'_pos_gsm',newname='el'+probes[sc]+'_Br_sign'

    print,'Done '+tsyg_mod+' ',probes[sc]

  endfor  ; END of SC Loop

  ;---------------------------
  ; COLLECT DATA FOR PLOTS
  ;--------------------------
  ; Get science collection times
  trange=[time_double(tstart), time_double(tend)]
  epda_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='epd') ;alternate pef_spinper/pef_nflux
  epdb_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='b', instrument='epd')
  epdia_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='epdi') ;alternate pef_spinper/pef_nflux
  epdib_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='b', instrument='epdi')
  fgma_sci_zones=get_elf_science_zone_start_end(trange=trange, probe='a', instrument='fgm') ;alternate pef_spinper/pef_nflux
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
  get_data, 'ela_spin_orbnorm_angle', data=norma
  get_data, 'ela_spin_sun_angle', data=suna
  get_data, 'ela_att_solution_date', data=solna
  get_data, 'ela_att_gei',data=attgeia
  if size(attgeia, /type) EQ 8 then cotrans, 'ela_att_gei', 'ela_att_gse', /gei2gse
  get_data, 'ela_att_gse',data=attgsea
  get_data, 'elb_spin_orbnorm_angle', data=normb ;1440*1
  get_data, 'elb_spin_sun_angle', data=sunb ;1440*1
  get_data, 'elb_att_solution_date', data=solnb ;1440*1
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
      if hires then device,set_resolution=[1200,900] else device,set_resolution=[800,600]
      charsize=1
    endif else begin
      set_plot,'win'
      ;set_plot,'x'
      window,xsize=800,ysize=600
      charsize=1
    endelse

    ; annotate constants
    xann=9.96
    if hires then yann=750 else yann=463

    ;;;; Jiang Liu edit here
    this_time=ela_state_pos_sm.x[min_st[k]:min_en[k]]
    midpt=n_elements(this_time)/2.
    tdate = this_time[midpt]

    ; Make SM GRIDS
    if keyword_set(sm) then begin
      ; get poles
      ;;;; Jiang Liu edit here: This is necessary because the noon location needes to be known
      ;sm_grid=elf_make_sm_grid(tdate=tdate, south = south)
      sm_grid=elf_make_sm_grid(tdate=tdate, south = south)
      ;;;; end of Jiang Liu edit
      lonlats=sm_grid.lat_circles
      nll=n_elements(lonlats[*,1])-1
      diffll=lonlats[1:nll,1]-lonlats[0:nll-1,1]
      llidx =where(diffll GT 5,ncnt)
      llidx=[0,llidx]
      llidx=[llidx,nll-8]
      latpole=sm_grid.pole[0]
      lonpole=sm_grid.pole[1]
    endif else begin
      if ~keyword_set(south) then latpole=90. else latpole=-90
      lonpole=-90.
    endelse

    ;;;;; spacecraft location
    for sc = 0,1 do begin
      if keyword_set(sm) then begin
        del_data, 'el'+probes[sc]+'_ifoot_geo_ftime'
        get_data, 'el'+probes[sc]+'_ifoot_sm', data = ifoot_sm
        ifoot_sm_faketime={x:replicate(tdate, n_elements(ifoot_sm.x)), y:ifoot_sm.y} ;tdate is middle time
        store_data, 'el'+probes[sc]+'_ifoot_sm_ftime', data = ifoot_sm_faketime
        cotrans, 'el'+probes[sc]+'_ifoot_sm_ftime', 'el'+probes[sc]+'_ifoot_gsm_ftime', /sm2gsm
        cotrans, 'el'+probes[sc]+'_ifoot_gsm_ftime', 'el'+probes[sc]+'_ifoot_gse_ftime', /gsm2gse
        cotrans, 'el'+probes[sc]+'_ifoot_gse_ftime', 'el'+probes[sc]+'_ifoot_gei_ftime', /gse2gei
        cotrans, 'el'+probes[sc]+'_ifoot_gei_ftime', 'el'+probes[sc]+'_ifoot_geo_ftime', /gei2geo
        get_data, 'el'+probes[sc]+'_ifoot_geo_ftime', data=ifoot_geo_faketime
        ifoot_geo_orig = {x:ifoot_sm.x, y:ifoot_geo_faketime.y}
        ifoot = ifoot_geo_orig
      endif else begin
        get_data, 'el'+probes[sc]+'_ifoot_geo', data = ifoot_geo
        ifoot = ifoot_geo
      endelse

      ;----------------------------
      ; CONVERT TRACE to LAT LON
      ;----------------------------
      get_data,'el'+probes[sc]+'_pos_geo',data=dpos_geo
      get_data,'el'+probes[sc]+'_Br_sign',data=Br_sign_tmp
      Case sc of
        ; ELFIN A
        0: begin
          lon = !radeg * atan2(ifoot.y[*,1],ifoot.y[*,0])
          lat = !radeg * atan(ifoot.y[*,2],sqrt(ifoot.y[*,0]^2+ifoot.y[*,1]^2))
          dposa=dpos_geo
          lona_all=lon
          lata_all=lat

          ; clean up data that's out of scope
          if keyword_set(south) then begin
            junk=where(Br_sign_tmp.y le 0., count)
          endif else begin
            junk=where(Br_sign_tmp.y gt 0., count)
          endelse
          if (count gt 0) then begin
            lat[junk]=!values.f_nan
            lon[junk]=!values.f_nan
          endif
        end

        ; ELFIN B
        1: begin
          lon2 = !radeg * atan2(ifoot.y[*,1],ifoot.y[*,0])
          lat2 = !radeg * atan(ifoot.y[*,2],sqrt(ifoot.y[*,0]^2+ifoot.y[*,1]^2))
          dposb=dpos_geo
          lonb_all=lon2
          latb_all=lat2
          ; clean up data that's out of scope
          if keyword_set(south) then begin
            junk=where(Br_sign_tmp.y le 0., count2)
          endif else begin
            junk=where(Br_sign_tmp.y gt 0., count2)
          endelse
          if (count2 gt 0) then begin
            lat2[junk]=!values.f_nan
            lon2[junk]=!values.f_nan
          endif
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
    if keyword_set(sm) then coord='Solar Magnetic' else coord='Geographic'
    if keyword_set(pred) then pred_str='Predicted ' else pred_str=''

    ;;;; Jiang Liu edit here
    if keyword_set(sm) then this_rot = 90-(-180.-sm_grid.noon[1])-lonpole $
    else this_rot=180.-mid_hr*15. ;geo turn LT=0 to the left side of the figure
    if keyword_set(south) then begin
      title=pred_str+'Southern '+coord+' Footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
      map_set,latpole,lonpole,-this_rot,/orthographic,/conti,title=title,position=[0.005,0.005,600./800.*0.96,0.96], charsize=.9
      map_grid,latdel=10.,londel=30.
    endif else begin
      title=pred_str+'Northern '+coord+' Footprints '+strmid(tstart,0,10)+plot_lbl[k]+' UTC'
      map_set,latpole,lonpole,this_rot,/orthographic, /conti, title=title, position=[0.005,0.005,600./800.*0.96,0.96], xmargin=[15,3], ymargin=[15,3], charsize=.9
      map_grid,latdel=10.,londel=30.
    endelse

    ;----------------------------------
    ; display latitude/longitude
    ;------------------------
    ; SM COORDINATES
    ;------------------------
    if keyword_set(sm) then begin
      lonlats=sm_grid.lat_circles
      nll=n_elements(lonlats[*,1])-1
      diffll=lonlats[1:nll,1]-lonlats[0:nll-1,1]
      llidx =where(diffll GT 5,ncnt) ;seperate into different circles
      llidx=[0,llidx]
      llidx=[llidx,nll]
      for lx=0,n_elements(llidx)-2 do $
        plots, lonlats[llidx[lx]+1:llidx[lx+1],0], lonlats[llidx[lx]+1:llidx[lx+1],1], psym=3, color=250 ;linestyle=1, color=250
      ; plot longitude lines
      lonlats=sm_grid.lon_lines
      nll=n_elements(lonlats[*,1])-1
      diffll=lonlats[1:nll,1]-lonlats[0:nll-1,1]
      llidx =where(abs(diffll) GT 40,ncnt)
      llidx=[0,llidx]
      llidx=[llidx,nll]
      for lx=0,n_elements(llidx)-2 do begin
        plots, lonlats[llidx[lx]+1:llidx[lx+1],0], lonlats[llidx[lx]+1:llidx[lx+1],1], psym=3, color=250  ;linestyle=1, color=250
      endfor
      ;;;; end of Jiang Liu edits
    endif else begin
      ;----------------------
      ;;; MAG Coords
      ;----------------------

      if keyword_set(south) then begin
        ;JWu edit start
        ;for i=0,nmlats-1 do oplot,v_lon[i,*],-v_lat[i,*],color=250,thick=contour_thick,linestyle=1
        for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1
        for i=0,nmlons-1 do begin
          idx=where(u_lon[i,*] NE 0)
          ;oplot,u_lon[i,idx],-u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
          oplot,u_lon[i,idx],u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
        endfor
        ;JWu edit end
      endif else begin ;north
        for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1 ;latitude rings
        for i=0,nmlons-1 do begin
          idx=where(u_lon[i,*] NE 0)   ;9 and 10 Lat=0 Lon=0 maybe b/c too close to equator
          if i EQ 0 then color=100 else color=250
          oplot,u_lon[i,idx],u_lat[i,idx],color=color,thick=contour_thick,linestyle=1
        endfor
      endelse
    endelse
    
    ;-------------------------------
    ; PLOT VLF and EISCAT Stations
    ;-------------------------------
    pts = (2*!pi/99.0)*findgen(100)
    earth=findgen(361)
    ex=[0]
    ey=[0]
    for i=0.,1.,0.025 do ex=[ex,i*cos(earth*!dtor)]
    for i=0.,1.,0.025 do ey=[ey,i*sin(earth*!dtor)]
    ; plot earth
;    oplot, ex[night_idx], ey[night_idx]
;    oplot, 1.0*cos(pts), 1.0*sin(pts)
;    oplot,[-100,100],[0,0],line=1
;    oplot,[0,0],[-100,100],line=1

    if size(eiscat_pos, /type) EQ 8 then begin
      ename=eiscat_pos.name
      elat=eiscat_pos.lat
      elon=eiscat_pos.lon
      symsz=[0.95, 0.75, 0.5, 0.25]
      for es=0,2 do begin
        for ss=0,n_elements(symsz)-1 do plots, elon[es], elat[es], color=248, psym=5, symsize=symsz[ss]  ;253
        plots, elon[es], elat[es], psym=5, symsize=1.0
 ;       plots, elon[es], elat[es], psym=5, symsize=1.35
      endfor
    endif
    if size(vlf_pos, /type) EQ 8 then begin
      vname=vlf_pos.name
      vlat=vlf_pos.glat
      vlon=vlf_pos.glon
      symsz=[0.65, 0.5, 0.25]
      for vs=0,6 do begin
        for ss=0,n_elements(symsz)-1 do plots, vlon[vs], vlat[vs], color=249, psym=6, symsize=symsz[ss]
        plots, vlon[vs], vlat[vs], psym=6, symsize=.7
      endfor
    endif

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
    alt_len=strlen(this_a_alt_str)
    this_a_alt_str=strmid(this_a_alt_str,0,alt_len-2)+'km'
    this_a_lat = lata[min_st[k]:min_en[k]]
    this_a_l = la[min_st[k]:min_en[k]]
    if size(attgeia, /type) EQ 8 then begin
      min_a_att_gei=min(abs(ela_state_pos_sm.x[midx]-attgeia.x),agei_idx)
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
    if ~undefined(epdia_sci_zones) && size(epdia_sci_zones, /type) EQ 8 then begin
      iidx=where(epdia_sci_zones.starts GE this_time[0] and epdia_sci_zones.starts LT this_time[nptsa-1], aizones)
      if aizones GT 0 then begin
        append_array, this_a_sz_st, epdia_sci_zones.starts[iidx]
        append_array, this_a_sz_en, epdia_sci_zones.ends[iidx]
        if epdia_sci_zones.ends[aizones-1] GT this_time[nptsa-1] then this_a_sz_en[aizones-1]=this_time[nptsa-1]
      endif
    endif
    if ~undefined(fgma_sci_zones) && size(fgma_sci_zones, /type) EQ 8 then begin
      fidx=where(fgma_sci_zones.starts GE this_time[0] and fgma_sci_zones.starts LT this_time[nptsa-1], afzones)
      if afzones GT 0 then begin
        append_array, this_a_sz_st, fgma_sci_zones.starts[fidx]
        append_array, this_a_sz_en, fgma_sci_zones.ends[fidx]
        if fgma_sci_zones.ends[afzones-1] GT this_time[nptsa-1] then this_a_sz_en[afzones-1]=this_time[nptsa-1]
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
    alt_len=strlen(this_b_alt_str)
    this_b_alt_str=strmid(this_b_alt_str,0,alt_len-2)+'km'
;    this_b_alt_str = strtrim(string(this_b_alt),1)
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

    ; Plot foot points
    if ~keyword_set(bfirst) then begin
      plots, this_lon2, this_lat2, psym=2, symsize=.05, color=254    ; thick=3
      plots, this_lon, this_lat, psym=2, symsize=.05, color=253   ; thick=3
    endif else begin
      plots, this_lon, this_lat, psym=2, symsize=.05, color=253   ; thick=3
      plots, this_lon2, this_lat2, psym=2, symsize=.05, color=254    ; thick=3
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
      spin_idxa=where(spina.x GE this_time[0] AND spina.x LT this_time[nptsa-1], ncnt)
      ;JWu
      ;spin_idxa=where(spina.x GE this_time2[0] AND spina.x LT this_time2[nptsa-1], ncnt)
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
        for sci=0, n_elements(this_b_sz_st)-1 do begin
          tidxb=where(this_time2 GE this_b_sz_st[sci] and this_time2 LT this_b_sz_en[sci], bcnt)
          if bcnt GT 5 then begin
            plots, this_lon2[tidxb], this_lat2[tidxb], psym=2, symsize=.25, color=254, thick=3
          endif
        endfor
      endif
      if ~undefined(this_a_sz_st) then begin
        for sci=0, n_elements(this_a_sz_st)-1 do begin
          tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
          if acnt GT 5 then begin
            plots, this_lon[tidxa], this_lat[tidxa], psym=2, symsize=.25, color=253, thick=3
          endif
        endfor
      endif
    endif else begin
      if ~undefined(this_a_sz_st) then begin
         for sci=0, n_elements(this_a_sz_st)-1 do begin
          tidxa=where(this_time GE this_a_sz_st[sci] and this_time LT this_a_sz_en[sci], acnt)
          if acnt GT 5 then begin
            plots, this_lon[tidxa], this_lat[tidxa], psym=2, symsize=.25, color=253, thick=3
          endif
        endfor
      endif
      if ~undefined(this_b_sz_st) then begin
        for sci=0, n_elements(this_b_sz_st)-1 do begin
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
      plots, this_lon2[count/2], this_lat2[count/2], psym=5, symsize=1.9, color=254 ;triangle
      ; elfina
      count=nptsa    ;n_elements(this_lon)
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.9, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.9, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.75, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.75, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.6, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.6, color=253
      plots, this_lon[count/2], this_lat[count/2], psym=5, symsize=1.9, color=253
    endif else begin
      ; elfina
      count=nptsa    ;n_elements(this_lon)
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.9, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.9, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.75, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.75, color=253
      plots, this_lon[0], this_lat[0], psym=4, symsize=1.6, color=253
      plots, this_lon[count-1], this_lat[count-1], psym=2, symsize=1.6, color=253
      plots, this_lon[count/2], this_lat[count/2], psym=5, symsize=1.9, color=253
      count=nptsb   ;n_elements(this_lon2)
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.9, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.9, color=254
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.75, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.75, color=254
      plots, this_lon2[0], this_lat2[0], psym=4, symsize=1.6, color=254
      plots, this_lon2[count-1], this_lat2[count-1], psym=2, symsize=1.6, color=254
      plots, this_lon2[count/2], this_lat2[count/2], psym=5, symsize=1.9, color=254
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
      plots, this_lon2[istepsb], this_lat2[istepsb], psym=1, symsize=1.35, color=254
      plots, this_lon[istepsa], this_lat[istepsa], psym=1, symsize=1.35, color=253
    endif else begin
      plots, this_lon[istepsa], this_lat[istepsa], psym=1, symsize=1.35, color=253
      plots, this_lon2[istepsb], this_lat2[istepsb], psym=1, symsize=1.35, color=254
    endelse

    ;--------------------------------
    ; AURORAL ZONES - Get and Plot
    ; -------------------------------
    ;kp_value=elf_load_kp(trange=this_time, /no_download)
    if undefined(kp_value) || kp_value EQ -1 then kp_value=2
    ovalget,kp_value,pwdboundlonlat,ewdboundlonlat   ;pwdboundlonlat in degree
    rp=make_array(n_elements(pwdboundlonlat[*,0]), /double)+100. ; array of 100
    outlon=make_array(n_elements(pwdboundlonlat[*,0]))
    outlat=make_array(n_elements(pwdboundlonlat[*,0]))
    ;;;; Note: Lon Lat are in SM
    ;JWu edit start
    if keyword_set(south) then begin
      pwdboundlonlat[*,1] = -pwdboundlonlat[*,1]
      ewdboundlonlat[*,1] = -ewdboundlonlat[*,1]
    endif

    ;if keyword_set(south) && keyword_set(sm) then begin
    ;  pwdboundlonlat[*,0] = pwdboundlonlat[*,0]+180
    ;  ewdboundlonlat[*,0] = ewdboundlonlat[*,0]+180
    ;endif
    ;JWu edit end
    sphere_to_cart, rp, pwdboundlonlat[*,1], pwdboundlonlat[*,0], vec=pwd_oval_sm
    sphere_to_cart, rp, ewdboundlonlat[*,1], ewdboundlonlat[*,0], vec=ewd_oval_sm

    t=make_array(n_elements(pwdboundlonlat[*,0]), /double)+tdate
    store_data, 'oval_sm', data={x:t, y:pwd_oval_sm}
    cotrans, 'oval_sm', 'oval_gsm', /sm2gsm
    cotrans, 'oval_gsm', 'oval_gse', /gsm2gse
    cotrans, 'oval_gse', 'oval_gei', /gse2gei
    cotrans, 'oval_gei', 'oval_geo', /gei2geo
    cotrans, 'oval_geo', 'oval_mag', /geo2mag
    get_data, 'oval_geo', data=d
    cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], rp, theta, phi
    pwdboundlonlat[*,0]=phi
    pwdboundlonlat[*,1]=theta

    t=make_array(n_elements(ewdboundlonlat[*,0]), /double)+tdate
    store_data, 'oval_sm', data={x:t, y:ewd_oval_sm}
    cotrans, 'oval_sm', 'oval_gsm', /sm2gsm
    cotrans, 'oval_gsm', 'oval_gse', /gsm2gse
    cotrans, 'oval_gse', 'oval_gei', /gse2gei
    cotrans, 'oval_gei', 'oval_geo', /gei2geo
    cotrans, 'oval_geo', 'oval_mag', /geo2mag
    get_data, 'oval_geo', data=d
    cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], rp, theta, phi
    ewdboundlonlat[*,0]=phi
    ewdboundlonlat[*,1]=theta

    ;JWu edit start
    ;    if keyword_set(south) then begin
    ;      if keyword_set(sm) then begin
    ;        plots,pwdboundlonlat[*,0]+180,pwdboundlonlat[*,1],color=155, thick=1.05
    ;        plots,ewdboundlonlat[*,0]+180,ewdboundlonlat[*,1],color=155, thick=1.05
    ;      endif else begin
    ;        plots,pwdboundlonlat[*,0],pwdboundlonlat[*,1],color=155, thick=1.05
    ;        plots,ewdboundlonlat[*,0],ewdboundlonlat[*,1],color=155, thick=1.05
    ;      endelse
    ;    endif else begin ;north
    ;      plots,pwdboundlonlat[*,0],pwdboundlonlat[*,1],color=155, thick=1.05
    ;      plots,ewdboundlonlat[*,0],ewdboundlonlat[*,1],color=155, thick=1.05
    ;    endelse
    ;JWu edit end
    plots,pwdboundlonlat[*,0],pwdboundlonlat[*,1],color=155, thick=1.05
    plots,ewdboundlonlat[*,0],ewdboundlonlat[*,1],color=155, thick=1.05

    ; get spin angle
    spin_att_ang_str='B/SP: (NA/ND/SD/SA)'
    ; ELFIN A
    ; IBO
    if size(attgeia, /type) EQ 8 then begin  ;a
      elf_calc_sci_zone_att,probe='a',trange=[this_time[0],this_time[n_elements(this_time)-1]], $
        lat=this_a_lat*!radeg, lshell=this_a_l, /ibo
      ela_ibo_spin_att_ang_str = 'IBO: ' + elf_make_spin_att_string(probe='a')
    endif else begin
      ela_ibo_spin_att_ang_str = 'IBO: not available'
    endelse
    ; OBO
    if size(attgeia, /type) EQ 8 then begin  ;a
      elf_calc_sci_zone_att,probe='a',trange=[this_time[0],this_time[n_elements(this_time)-1]], $
        lat=this_a_lat*!radeg, lshell=this_a_l
      ela_obo_spin_att_ang_str = 'OBO: ' + elf_make_spin_att_string(probe='a')
    endif else begin
      ela_obo_spin_att_ang_str = 'OBO: not available'
    endelse

    ; ELFIN B
    ; IBO
    if size(attgeib, /type) EQ 8 then begin    ;b
      elf_calc_sci_zone_att,probe='b',trange=[this_time2[0],this_time2[n_elements(this_time2)-1]], $
        lat=this_b_lat*!radeg, lshell=this_b_l, /ibo
      elb_ibo_spin_att_ang_str = 'IBO: ' + elf_make_spin_att_string(probe='b')
    endif else begin
      elb_ibo_spin_att_ang_str = 'IBO: not available'
    endelse
    ; OBO
    if size(attgeib, /type) EQ 8 then begin    ;b
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
    a_spin_str='Tspin='+a_spinper+'s['+a_rpm_str+'RPM]'
    a_torb_str='Torb='+a_period_str+'min'
    ; elfin b
    ; ******get spin period routines******
    b_rpm=elf_load_att(probe='b', tdate=ela_state_pos_sm.x[min_st[k]])
    b_sp=60./b_rpm
    b_spinper = strmid(strtrim(string(b_sp),1),0,4)
    b_rpm_str = strmid(strtrim(string(b_rpm),1),0,5)
    b_spin_str='Tspin='+b_spinper+'s['+b_rpm_str+'RPM]'
    b_torb_str='Torb='+b_period_str+'min'

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
    xann=9.6
    xyouts,xann,yann+12.5*8,'ELFIN (A)',/device,charsize=.75,color=253
;    xyouts,xann,yann+12.5*7,a_orb_spin_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*7,a_spin_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*6,a_torb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*5,spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*4,ela_obo_spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*3,ela_ibo_spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*2,a_att_gei_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*1,a_att_gse_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*0,'S w/Sun, deg: '+suna_str,/device,charsize=charsize
    xyouts,xann,yann-12.5*1,'S w/OrbNorm, deg: '+norma_str,/device,charsize=charsize
    xyouts,xann,yann-12.5*2,'Att.Sol@'+solna_str,/device,charsize=charsize
    xyouts,xann,yann-12.5*3,'Altitude: '+this_a_alt_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*6,ela_spin_att_ang_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*5,a_att_gei_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*4,a_att_gse_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*3,'S w/Sun, deg: '+suna_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*2,'S w/OrbNorm, deg: '+norma_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*1,'Att.Solution@'+solna_str,/device,charsize=charsize
    ;    xyouts,xann,yann+12.5*0,'Altitude, km: '+this_a_alt_str,/device,charsize=charsize

    yann=0.02
    xyouts,xann,yann+12.5*12,'ELFIN (B)',/device,charsize=.75,color=254
;    xyouts,xann,yann+12.5*10,b_orb_spin_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*11,b_spin_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*10,b_torb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*9,spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*8,elb_obo_spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*7,elb_ibo_spin_att_ang_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*6,b_att_gei_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*5,b_att_gse_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*4,'S w/Sun, deg: '+sunb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*3,'S w/OrbNorm, deg: '+normb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*2,'Att.Sol@: '+solnb_str,/device,charsize=charsize
    xyouts,xann,yann+12.5*1,'Altitude: '+this_b_alt_str,/device,charsize=charsize

    if keyword_set(sm) then latlon_text='SM Lat/Lon - Red dotted lines' $
    else latlon_text='Mag Lat/Lon - Red dotted lines'
    oval_text='Auroral Oval-Green, kp='+strtrim(kp_value,1)
    if keyword_set(sm) then oxadd=51.5 else oxadd=47
    if keyword_set(sm) then lxadd=26 else lxadd=21
    if hires then xann=670 else xann=410
    if hires then yann=750 else yann=463
    if hires then begin
      yann=750
      xann=670
      xyouts, xann-5,yann+12.5*8,'Earth/Oval View Center Time (triangle)',/device,color=255,charsize=charsize
      xyouts, xann+10,yann+12.5*7,'Thick - Science (FGM and/or EPD)',/device,color=255,charsize=charsize
      xyouts, xann+18,yann+12.5*6,'Geo Lat/Lon - Black dotted lines',/device,color=255,charsize=charsize
      xyouts, xann+25,yann+12.5*5, latlon_text,/device,color=251,charsize=charsize
      xyouts, xann+55,yann+12.5*4, oval_text,/device,color=155,charsize=charsize
      xyouts, xann+65,yann+12.5*3,'EISCAT-Purple Triangle',/device,color=248,charsize=charsize
      xyouts, xann+75,yann+12.5*2,'Tick Marks every 5min',/device,color=255,charsize=charsize
      xyouts, xann+85,yann+12.5*1,'Start Time-Diamond',/device,color=255,charsize=charsize
      xyouts, xann+95,yann+12.5*0,'End Time-Asterisk',/device,color=255,charsize=charsize
      xyouts, xann+100,yann-12.5,'VLF-Green Square',/device,color=249,charsize=charsize
    endif else begin
      yann=463
      xann=410
      xyouts, xann-5,yann+12.5*8,'Earth/Oval View Center Time (triangle)',/device,color=255,charsize=charsize
      xyouts, xann+10,yann+12.5*7,'Thick - Science (FGM and/or EPD)',/device,color=255,charsize=charsize
      xyouts, xann+15,yann+12.5*6,'Geo Lat/Lon - Black dotted lines',/device,color=255,charsize=charsize
      xyouts, xann+lxadd,yann+12.5*5, latlon_text,/device,color=251,charsize=charsize
      xyouts, xann+oxadd,yann+12.5*4, oval_text,/device,color=155,charsize=charsize
      xyouts, xann+65,yann+12.5*3,'EISCAT-Purple Triangle',/device,color=248,charsize=charsize
      xyouts, xann+66,yann+12.5*2,'Tick Marks every 5min',/device,color=255,charsize=charsize
      xyouts, xann+76,yann+12.5*1,'Start Time-Diamond',/device,color=255,charsize=charsize
      xyouts, xann+85,yann+12.5*0,'End Time-Asterisk',/device,color=255,charsize=charsize
      xyouts, xann+90,yann-12.5,'VLF-Green Square',/device,color=249,charsize=charsize
    endelse

    yann=0.02
    if hires then xann = 660 else xann=393
    case 1 of
      tsyg_mod eq 't89': xyouts,xann+20,yann+12.5*2,'Tsyganenko-1989',/device,charsize=charsize,color=255
      tsyg_mod eq 't96': xyouts,xann+20,yann+12.5*2,'Tsyganenko-1996',/device,charsize=charsize,color=255
      tsyg_mod eq 't01': xyouts,xann+20,yann+12.5*2,'Tsyganenko-2001',/device,charsize=charsize,color=255
    endcase

    ; North GEO Midnight and noon
    if ~keyword_set(sm) and ~keyword_set(south) then begin
      xyouts, .01, .489, '00:00', charsize=1.15, /normal
      xyouts, .663, .489, '12:00', charsize=1.15, /normal
    endif
    if keyword_set(sm) and ~keyword_set(south) then begin
      xyouts, .01, .489, '00:00', charsize=1.15, /normal
      xyouts, .663, .489, '12:00', charsize=1.15, /normal
    endif

    if ~keyword_set(sm) and keyword_set(south) then begin
      xyouts, .01, .489, '00:00', charsize=1.15, /normal
      xyouts, .663, .489, '12:00', charsize=1.15, /normal
    endif

    if keyword_set(sm) and keyword_set(south) then begin
      xyouts, .01, .463, '00:00', charsize=1.15, /normal
      xyouts, .663, .463, '12:00', charsize=1.15, /normal
    endif

    ;
    if keyword_set(south) then begin
      xyouts, .335, .935, '06:00', charsize=1.15, /normal
      xyouts, .335, .0185, '18:00', charsize=1.15, /normal
    endif else begin
      xyouts, .33, .935, '18:00', charsize=1.15, /normal
      xyouts, .335, .0185, '06:00', charsize=1.15, /normal
    endelse


    ; add time of creation
    xyouts,  xann+20, yann+12.5, 'Created: '+systime(),/device,color=255, charsize=charsize

    ;-----------------------
    ; START OF ORBIT PLOTS
    ;-----------------------
    ;--------
    ; SM X-Z
    ;--------
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*2./3.,0.985,0.96*3./3.],$
      title='SM orbit'
    ; plot the earth
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'
    ; plot short axes
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ; plot orbit behind of earth
    if ~keyword_set(bfirst) then begin
      idx = where(this_by gt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 1  ;, thick=.75
      endif
      idx = where(this_by le 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
      endif
      ; repeat for A
      idx = where(this_ay gt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=252, psym = 3  ;, thick=.75
      endif
      ; plot orbit in front of earth
      idx = where(this_ay le 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
      endif
    endif else begin
      ; start with A
      idx = where(this_ay gt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=252, psym = 3  ;, thick=.75
      endif
      ; plot orbit in front of earth
      idx = where(this_ay le 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
      endif
      ; repeat for B
      idx = where(this_by gt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 1  ;, thick=.75
      endif
      idx = where(this_by le 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
      endif
    endelse

    ;plot start/end points
    if ~keyword_set(bfirst) then begin
      plots, this_bx[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
      plots, this_ax[0]/6378.,this_az[0]/6378.,color=253,psym=symbols[0],symsize=0.8
      plots, this_bx[nptsb-1]/6378.,this_bz[nptsb-1]/6378.,color=254,psym=2,symsize=0.8
      plots, this_ax[nptsa-1]/6378.,this_az[nptsa-1]/6378.,color=253,psym=2,symsize=0.8
      plots, this_bx[(nptsb-1)/2]/6378.,this_bz[(nptsb-1)/2]/6378.,color=254,psym=5,symsize=0.8
      plots, this_ax[(nptsa-1)/2]/6378.,this_az[(nptsa-1)/2]/6378.,color=253,psym=5,symsize=0.8
    endif else begin
      plots, this_ax[0]/6378.,this_az[0]/6378.,color=253,psym=symbols[0],symsize=0.8
      plots, this_bx[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
      plots, this_ax[nptsa-1]/6378.,this_az[nptsa-1]/6378.,color=253,psym=2,symsize=0.8
      plots, this_bx[nptsb-1]/6378.,this_bz[nptsb-1]/6378.,color=254,psym=2,symsize=0.8
      plots, this_ax[(nptsa-1)/2]/6378.,this_az[(nptsa-1)/2]/6378.,color=253,psym=5,symsize=0.8
      plots, this_bx[(nptsb-1)/2]/6378.,this_bz[(nptsb-1)/2]/6378.,color=254,psym=5,symsize=0.8
    endelse

    ; plot lines to separate plots
    plots,[600./800.*0.96,1.],[0.005+0.96*3./3.,0.005+0.96*3./3.]-0.007,/normal
    plots,[600./800.*0.96,1.],[0.005+0.96*2./3.,0.005+0.96*2./3.]-0.005,/normal

    ;--------
    ; SM X-Y
    ;--------
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*1./3.,0.985,0.96*2./3.]
    ; plot the earth
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'
    xyouts,.05,-1.85,'-Y'
    xyouts,.05,1.7,'Y'
    ; plot short axes
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ; plot orbit behind of earth
    if ~keyword_set(bfirst) then begin
      idx = where(this_bz lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_by[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      idx = where(this_bz ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_by[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
      endif
      ; repeat for a
      idx = where(this_az lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_ay[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      ; plot orbit in front of earth
      idx = where(this_az ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_ay[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
      endif
    endif else begin
      ; start with a
      idx = where(this_az lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_ay[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      ; plot orbit in front of earth
      idx = where(this_az ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ax[istart[sidx]:iend[sidx]]/6378., this_ay[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
      endif
      ; repeat for b
      idx = where(this_bz lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_by[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      idx = where(this_bz ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_bx[istart[sidx]:iend[sidx]]/6378., this_by[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
      endif
    endelse

    ;plot start and end points
    if ~keyword_set(bfirst) then begin
      plots, this_bx[0]/6378., this_by[0]/6378.,color=254,psym=symbols[0],symsize=0.8
      plots, this_ax[0]/6378.,this_ay[0]/6378.,color=253,psym=symbols[0],symsize=0.8
      plots, this_bx[nptsb-1]/6378., this_by[nptsb-1]/6378.,color=254,psym=2,symsize=0.8
      plots, this_ax[nptsa-1]/6378.,this_ay[nptsa-1]/6378.,color=253,psym=2,symsize=0.8
      plots, this_bx[(nptsb-1)/2]/6378., this_by[(nptsb-1)/2]/6378.,color=254,psym=5,symsize=0.8
      plots, this_ax[(nptsa-1)/2]/6378.,this_ay[(nptsa-1)/2]/6378.,color=253,psym=5,symsize=0.8
    endif else begin
      plots, this_ax[0]/6378.,this_ay[0]/6378.,color=253,psym=symbols[0],symsize=0.8
      plots, this_bx[0]/6378., this_by[0]/6378.,color=254,psym=symbols[0],symsize=0.8
      plots, this_ax[nptsa-1]/6378.,this_ay[nptsa-1]/6378.,color=253,psym=2,symsize=0.8
      plots, this_bx[nptsb-1]/6378., this_by[nptsb-1]/6378.,color=254,psym=2,symsize=0.8
      plots, this_ax[(nptsa-1)/2]/6378.,this_ay[(nptsa-1)/2]/6378.,color=253,psym=5,symsize=0.8
    endelse

    ; plot lines to separate plots
    plots,[600./800.*0.96,1.],[0.005+0.96*1./3.,0.005+0.96*1./3.]-0.0025,/normal

    ;--------
    ; SM Y-Z
    ;--------
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*0./3.,0.985,0.96*1./3.]
    ; plot the earth
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-Y'
    xyouts,1.75,.05,'Y'
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'
    ; plot short axes
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ; plot orbit behind of earth
    ;    plots, this_by[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
    if ~keyword_set(bfirst) then begin
      idx = where(this_bx lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_by[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      idx = where(this_bx ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_by[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
      endif
      ; repeat for a
      idx = where(this_ax lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ay[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      ; plot orbit in front of earth
      idx = where(this_ax ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ay[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
      endif
    endif else begin
      ; start with a
      idx = where(this_ax lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ay[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      ; plot orbit in front of earth
      idx = where(this_ax ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_ay[istart[sidx]:iend[sidx]]/6378., this_az[istart[sidx]:iend[sidx]]/6378., color=253, thick=1.25
      endif
      ; repeat for b
      idx = where(this_bx lt 0, ncnt)
      if ncnt gt 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_by[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=252, linestyle = 2, thick=.75
      endif
      idx = where(this_bx ge 0, ncnt)
      if ncnt GT 0 then begin
        find_interval,idx,istart,iend
        for sidx = 0, n_elements(istart)-1 do oplot, this_by[istart[sidx]:iend[sidx]]/6378., this_bz[istart[sidx]:iend[sidx]]/6378., color=254, thick=1.25
      endif
    endelse

    ;plot start and end points
    if ~keyword_set(bfirst) then begin
      plots, this_by[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
      plots, this_ay[0]/6378.,this_az[0]/6378.,color=253,psym=symbols[0],symsize=0.8
      plots, this_by[nptsb-1]/6378.,this_bz[nptsb-1]/6378.,color=254,psym=2,symsize=0.8
      plots, this_ay[nptsa-1]/6378.,this_az[nptsa-1]/6378.,color=253,psym=2,symsize=0.8
      plots, this_by[(nptsb-1)/2]/6378.,this_bz[(nptsa-1)/2]/6378.,color=254,psym=5,symsize=0.8
      plots, this_ay[(nptsa-1)/2]/6378.,this_az[(nptsa-1)/2]/6378.,color=253,psym=5,symsize=0.8
    endif else begin
      plots, this_ay[0]/6378.,this_az[0]/6378.,color=253,psym=symbols[0],symsize=0.8
      plots, this_by[0]/6378.,this_bz[0]/6378.,color=254,psym=symbols[0],symsize=0.8
      plots, this_ay[nptsa-1]/6378.,this_az[nptsa-1]/6378.,color=253,psym=2,symsize=0.8
      plots, this_by[nptsb-1]/6378.,this_bz[nptsb-1]/6378.,color=254,psym=2,symsize=0.8
      plots, this_ay[(nptsa-1)/2]/6378.,this_az[(nptsa-1)/2]/6378.,color=253,psym=5,symsize=0.8
      plots, this_by[(nptsb-1)/2]/6378.,this_bz[(nptsa-1)/2]/6378.,color=254,psym=5,symsize=0.8
    endelse

    ; plot lines to separate plots
    plots,[600./800.*0.96,1.],[0.005+0.96*0./3.,0.005+0.96*0./3.],/normal

    ;--------------------------------
    ; CREATE GIF
    ;--------------------------------
    if keyword_set(gifout) then begin

      ; Create small plot
      image=tvrd()
      device,/close
      set_plot,'z'
      ;set_plot,'x'
      ;device,set_resolution=[1200,900]
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      if not keyword_set(noview) then window,3,xsize=800,ysize=600
      if not keyword_set(noview) then tv,image
      dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2)+'/'+strmid(date,8,2)+'/'
      file_mkdir, dir_products
      filedate=file_dailynames(trange=tr+[0, -1801.], /unique, times=times)

      if keyword_set(south) then plot_name = 'southtrack' else plot_name = 'northtrack'
      if keyword_set(sm) then begin
        coord_name='_sm_'
        if keyword_set(bfirst) then pname='elb' else pname='ela'
      endif else begin
        coord_name='_'
        pname='elf'
      endelse
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
