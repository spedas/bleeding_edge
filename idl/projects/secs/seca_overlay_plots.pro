;+
; NAME:
;  seca_overlay_plots
;
; PURPOSE:
;  This routine will create a plot of SECA and THEMIS ASI data which is overlaid onto a map of
;  the northern hemisphere. See the SECS ASI mosaic overlay plot crib sheet for an explanation of the
;  data and how to use this routine. You can find the crib sheet in spedas/projects/secs/examples/
;
; KEYWORDS:
;  trange:        time range of interest
;  createpng:     set this flag to create a PNG file of the plot
;  showgeo:       set this flag to display geographic latitude and longitude lines
;  showmag:       set this flag to display magnetic latitude and longitude lines
;  dynscale:      set this flag to use dynamic scaling
;
; OUTPUT:
;  none
;
; CALLING SEQUENCE:
;  seca_overlay_plots, trange=['2017-02-28/00:01:00','2017-02-28/00:02:00'],
;      /showgeo, /showmag, /makepng, /dynscale
;  See example crib sheets for additional examples
;
; NOTE: If no time range is specified the routine will use whatever was set previously by timespan or
;   timerange.
;   If no time has not been set the user will be queried for the time.
;   Data files for each data set are available per minute 
;
; VERSION:
;   $LastChangedBy: jwl $
;   $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;   $LastChangedRevision: 33563 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/seca_overlay_plots.pro $
;-
pro seca_overlay_plots, $ 
    trange=trange, $ ; time range
    createpng=createpng, $ ; generate png from the figure
    showgeo=showgeo, $ ; show geographic grid
    showmag=showmag, $ ; show geomagnetic grid
    dynscale=dynscale ; use dynamic scaling

  ; initialize variables
  defsysv,'!secs',exists=exists
  if not(exists) then secs_init
  defsysv,'!themis',exists=exists
  if not(exists) then thm_init
  thm_config
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  tr[1]=tr[0]
  inten=6001;
  
  ; ------------
  ; Get Data
  ; ------------
  ; extract the EICS data from the tplot vars
  ; sort the data into parameters and rotate they for plotxyvec
  secs_load_data, trange=tr,  datatype=['seca'], /get_stations
  get_data, 'secs_seca_latlong', data=latlon
  if ~is_struct(latlon) then begin
      dprint, 'There is no SECS data for date: '+time_string(tr[0])
      return
  endif
  lon=latlon.y[*,1]
  lat=latlon.y[*,0]
  get_data, 'secs_seca_amp', data=amp

  if ~is_struct(amp) then begin
    dprint, 'There is no SECS data for date: '+time_string(tr[0])
    return
  endif
  get_data, 'secs_stations', data=stations
  if ~is_struct(stations) then begin
    dprint, 'There is no Station data for date: '+time_string(tr[0])
  endif

  ; -----------------
  ; Make the mosaic
  ; -----------------
  thm_asi_create_mosaic,time_string(tr[0]),/verbose,$            ; removed /thumb
      central_lon=264.0,central_lat=61.,scale=4.5e7,$         ; set lat to 64.5;set area scale=3.5or2.8e7 or scale=5.5e7,
      no_grid='no_grid', /no_midnight, $     
      show  =['atha','fsmi','fykn','gako','gbay','gill','inuv','kapu','kian','kuuj','mcgr','nrsq','pgeo','pina','tpas','rank','snkq','talo','tpas','whit'] ,$
      minval=[0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 01],$
      maxval=[inten, 12000, inten, inten, inten, inten, inten, 8000, inten, inten, inten, inten, inten, 8000, inten, 5000,  8000,  inten,  8000, inten  ];
 
  ; Plot the geographic and magnetic grid lines
  loadct2,34  
  aacgmidl
  thm_init
  geographic_lons=[0,30,60,90,120,150,180,210,240,270,300,330,360]
  geographic_lats=[0,20,30,40,50,60,70,80]

  ; overplot the EICs onto the mosaic map
  ;nidx=where(amp.y LT 0, ncnt)
  ;pidx=where(amp.y GE 0, pcnt)
  ;if ncnt GT 0 then oplot, lon[nidx], lat[nidx], psym=6, color=50
  ;if pcnt GT 0 then oplot, lon[pidx], lat[pidx], psym=1, color=250
  ; To specity the size of the marker we need to plot each point individually
  
  scale = 1
  leg_sz = 20000.
  
  ; This settings are for dynamic scaling
  scale_factor=max(abs(amp.y))
  if keyword_set(dynscale) then begin
    max_factor = [50000., 40000., 30000., 20000., 10000.] ; GT limits
    idx = where(scale_factor gt 3*max_factor)
    leg_sz = max_factor(idx[0])
  endif  
  
  datan = size(amp.y,/N_ELEMENTS)
  if datan gt 0 then begin 
    for idx=0,datan-1 do begin
      ; todo: find out how the size of the markers is determined in the original figure
      sz = scale*amp.y[idx]/leg_sz
      if sz ge 0 then begin
        clr = 250
        psm = 1
      endif else begin
        clr = 50
        psm = 6
      endelse
      oplot, [lon[idx]], [lat[idx]], psym=psm, color=clr, SYMSIZE=abs(sz)
    endfor
  endif


  ; ----------------
  ; PLOT Latitudes
  ; ----------------
  nmlats=round((max(geographic_lats)-min(geographic_lats))/float(10)+1)
  mlats=min(geographic_lats)+findgen(nmlats)*10
  n2=150
  v_lat=fltarr(nmlats,n2)
  v_lon=fltarr(nmlats,n2)
  height=100.
  ; construct geographic lats
  if keyword_set(showgeo) then begin
    for i=0,nmlats-1 do begin
      for j=0,n2-1 do begin
        v_lat[i,j]=mlats[i]
        v_lon[i,j]=j/float(n2-1)*360
      endfor
      oplot,v_lon[i,*],v_lat[i,*],color=0,thick=contour_thick,linestyle=1
    endfor
  endif
  ; construct magnetic lats
  if keyword_set(showmag) then begin
    for i=0,nmlats-1 do begin
      for j=0,n2-1 do begin
        cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r,error,/geo
        v_lat[i,j]=u
        v_lon[i,j]=v
      endfor
      oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1
    endfor
  endif

  ; ----------------
  ; PLOT Longitudes
  ; ----------------
  ;construct and plot geographic lons
  nmlons=n_elements(geographic_lons)
  n2=20
  u_lat=fltarr(nmlons,n2)
  u_lon=fltarr(nmlons,n2)
  mlats=min(geographic_lats)+findgen(n2)/float(n2-1)*(max(geographic_lats)-min(geographic_lats))
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      u_lat[i,j]=mlats[j]
      u_lon[i,j]=geographic_lons[i]
    endfor
    if keyword_set(showgeo) then oplot,u_lon[i,*],u_lat[i,*],color=0,thick=contour_thick,linestyle=1
  endfor
  ; construct and plot magnetic lons (need /geo keyword for plot)
  if keyword_set(showmag) then begin
    for i=0,nmlons-1 do begin
      for j=0,n2-1 do begin
        cnv_aacgm,mlats[j],geographic_lons[i],height,u,v,r,error,/geo
        u_lat[i,j]=u
        u_lon[i,j]=v
      endfor
      idx = where(u_lon[i,*] NE 0)
      oplot,u_lon[i,idx],u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
    endfor
  endif

  ; ----------------
  ; PLOT Midnight
  ; ----------------
  if keyword_set(showgeo) then begin
    ts=time_struct(tr[0])
    midnight=(-15.*(ts.sod/3600.))+360.
    if midnight LT 0 then midnight=midnight+180
    midnight=midnight mod 360.
    mlons=fltarr(n2)+midnight
    oplot,mlons,mlats,color=0, thick=1.5
  endif

  ; --------------------
  ; PLOT GMAG Stations
  ; --------------------
  if is_struct(stations) then begin
    oplot, stations.v[*,1], stations.v[*,0], psym=2, color=150
  endif

  ; --------------------
  ; Display annotations
  ;---------------------
  
  ; legend position for 4 entries
  ; in /normal coordinates
  legx = FLTARR(4) + 0.82
  legy = FINDGEN(4, INCREMENT=0.05) + 0.01
  legidx = 0
  
  ; Text on the left side
  ; The location is consstent with thm_asi_create_mosaic
  xyouts, 0.005,0.102, 'SECS - EICS', /NORMAL, color=0, charsize=1.5
  
    ; First legend record
  xyouts, legx(legidx)+0.02, legy(legidx), /NORMAL, string(leg_sz,FORMAT='("+/- ",I5," A")'),charsize=1.125, charthick=1.25,color=0
  ; Note, this solution of the markers location is not ideal, because it may look different in various os
  xyz_arr  = convert_coord(legx(legidx)+0.025, legy(legidx)+0.025, /NORMAL, /TO_DATA) ; where the point in /data coords
  oplot, [xyz_arr[0]], [xyz_arr[1]], psym=1, color=250, SYMSIZE=scale  
  xyz_arr  = convert_coord(legx(legidx)+0.055, legy(legidx)+0.025, /NORMAL, /TO_DATA) ; where the point in /data coords 
  oplot, [xyz_arr[0]], [xyz_arr[1]], psym=6, color=50, SYMSIZE=scale
  
  ; Draw other legenr entries
  legidx += 1
  if keyword_set(showmag) then begin
    xyouts, legx(legidx), legy(legidx), /NORMAL, 'Mag Red dot line', color=250, charthick=1.2, charsize=1.125
    legidx += 1
  endif
  if keyword_set(showgeo) then begin
    xyouts, legx(legidx), legy(legidx), /NORMAL, 'Geo Black dot line', color=0, charthick=1.25, charsize=1.125
    legidx += 1
  endif
  if is_struct(stations) then begin
    xyouts, legx(legidx), legy(legidx), /NORMAL, 'GMAG green star', color=150, charthick=1.2, charsize=1.125
    legidx += 1 ; this is done so we can move the blocks around
  endif
  
  ; ------------------
  ; Create PNG file
  ; ------------------
  if keyword_set(createpng) then begin
    ; construct png file name
    tstruc = time_struct(tr[0])
    yr = strmid(time_string(tr[0]),0,4)
    mo = strmid(time_string(tr[0]),5,2)
    da = strmid(time_string(tr[0]),8,2)
    hr = strmid(time_string(tr[0]),11,2)
    mi = strmid(time_string(tr[0]),14,2)
    sc = strmid(time_string(tr[0]),17,2)
    plotdir = !secs.local_data_dir + 'Mosaic/' + yr + '/' + mo + '/' + da + '/' 
    plotfile = 'ThemisMosaicSECA' + yr + mo + da + '_' + hr + mi + sc
    makepng, plotdir+plotfile, /mkdir
    print, 'PNG file created: ' + plotdir + plotfile 
  endif
  
return
end
