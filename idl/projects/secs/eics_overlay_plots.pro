;+
; NAME:
;  eics_overlay_plots
;
; PURPOSE:
;  This routine will create a plot of EICS and THEMIS ASI data which is overlaid onto a map of 
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
;  eics_overlay_plots, trange=['2017-02-28/00:01:00','2017-02-28/00:02:00'],
;      /showgeo, /showmag, /makepng, /dynscale
;  See example crib sheets for additional examples 
;                                
; NOTE: If no time range is specified the routine will use whatever was set previously by timespan or
;   timerange.
;   If no time has not been set the user will be queried for the time.  
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;$LastChangedRevision: 33563 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/eics_overlay_plots.pro $
;-

; VERSION:
;   $LastChangedBy: jwl $
;   $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
;   $LastChangedRevision: 33563 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/eics_overlay_plots.pro $
;-
function eics_coordtinate_convert, st, device=device, data=data
  if keyword_set(device) then begin
    to_device = 1
    from_device = 0    
    to_data = 0
    from_data = 1    
  endif
  if keyword_set(data) then begin
    to_device = 0
    from_device = 1    
    to_data = 1
    from_data = 0
  endif
  
  if size(st,/type) eq 8 then begin
    xyz = convert_coord(st.x, st.y, DATA=from_data, TO_DATA=to_data, DEVICE=from_device, TO_DEVICE=to_device, /DOUBLE) ; vector start position on normal grid
    tmp = {x:reform(xyz[0,*]), y:reform(xyz[1,*])}
  endif else begin
    if size(st,/N_ELEMENTS) gt 2 then begin
      xyz = convert_coord(st[*,0], st[*,1], DATA=from_data, TO_DATA=to_data, DEVICE=from_device, TO_DEVICE=to_device, /DOUBLE) ; vector start position on normal grid
      tmp = TRANSPOSE(xyz[0:1,*],[1,0])
    endif else begin
      xyz = convert_coord(st[0], st[1], DATA=from_data, TO_DATA=to_data, DEVICE=from_device, TO_DEVICE=to_device, /DOUBLE) ; vector start position on normal grid
      tmp = rotate(xyz[0:1],1)
    endelse  
  endelse
  
  return, tmp
end 

pro eics_coordtinate_processing, lonlat=ge_s, mag=ge_d, scale=scale_factor, leg_vector=leg_vector, new_mag=ge_vd 
  ; conversion  
  ge_e = ge_s + ge_d / scale_factor
  ge_m = sqrt(total(ge_d^2,2))
  ge_m = [[ge_m], [ge_m]]
  xy_s = eics_coordtinate_convert(ge_s, /DEVICE)
  xy_e = eics_coordtinate_convert(ge_e, /DEVICE)
  xy_d = xy_e - xy_s
  xy_m = sqrt(total(xy_d^2,2))
  xy_m = [[xy_m],[xy_m]]
  xy_i = xy_d / xy_m
  xy_v = xy_i * ge_m * 0.02 * !d.X_VSIZE / leg_vector
  xy_ve = xy_v + xy_s
  ge_ve = eics_coordtinate_convert(xy_ve, /DATA)
  ge_vd = ge_ve-ge_s
end

pro eics_overlay_plots, $
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
  inten=6001;
  
  ; ------------
  ; Get Data
  ; ------------
  ; extract the EICS data from the tplot vars
  ; sort the data into parameters and rotate them for plotxyvec
  secs_load_data, trange=tr,  datatype=['eics'], /get_stations
  get_data, 'secs_eics_latlong', data=latlon
  if ~is_struct(latlon) then begin
      dprint, 'There is no EICS data for date: '+time_string(tr[0])
      return
  endif  
  get_data, 'secs_eics_jxy', data=jxy
  if ~is_struct(jxy) then begin
    dprint, 'There is no EICS data for date: '+time_string(tr[0])
    return
  endif
  get_data, 'secs_stations', data=stations
  if ~is_struct(stations) then begin
    dprint, 'There is no Station data for date: '+time_string(tr[0])
  endif
  
  eics_pos = [[latlon.y[*,1]+360.], [latlon.y[*,0]]]
  eics_mag = [[jxy.y[*,1]], [jxy.y[*,0]]]
  
  ; grid conversion testing set
  ;ge_s1 = [[-154.44911],[63.563763]]
  ;ge_s2 = [[-65.179733],[42.226425]]
  ;ge_s3 = [[-96.],[51.]]   
  ;eics_pos = [ge_s1, ge_s1, ge_s1, ge_s1,ge_s2, ge_s2, ge_s2, ge_s2,ge_s3,ge_s3,ge_s3,ge_s3]
  ;eics_mag = [[800.,0.,-800.,0.,800.,0.,-800.,0.,800.,0.,-800.,0.], [0.,800.,0.,-800.,0.,800.,0.,-800.,0.,800.,0.,-800.]]


  ; -----------------
  ; Make the mosaic
  ; -----------------
    thm_asi_create_mosaic,time_string(tr[0]),/verbose,$            ; removed /thumb
    ;thm_asi_create_mosaic,'0000-00-00',/force_map,/verbose,$            ; removed /thumb
      central_lon=264.0,central_lat=61.,scale=4.5e7,$         ; set lat to 64.5;set area scale=3.5or2.8e7 or scale=5.5e7,
      no_grid='no_grid', /no_midnight,  $
      show  =['atha','fsmi','fykn','gako','gbay','gill','inuv','kapu','kian','kuuj','mcgr','nrsq','pgeo','pina','tpas','rank','snkq','talo','tpas','whit'] ,$            
      minval=[0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 0l, 0l, 01, 01, 01, 01],$
      maxval=[inten, 12000, inten, inten, inten, inten, inten, 8000, inten, inten, inten, inten, inten, 8000, inten, 5000,  8000,  inten,  8000, inten  ];
 
  ; Construct and plot the geographic and magnetic grid lines
  loadct2,34  
  aacgmidl
  thm_init
  geographic_lons=[0,30,60,90,120,150,180,210,240,270,300,330,360]
  geographic_lats=[0,20,30,40,50,60,70,80]

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

  ; set up plotting parameters for use by plotxyvec
  yrange = [30,80]
  xrange = [220,330]
  rows = 1
  cols = 1
  revrows = 0
  revcols = 0
  current = 0
  pos = !p.position
  plotvec = ptr_new(csvector('start'))

  ; create or update the system variable !tplotxy
  defsysv,'!tplotxy',exists=exists
  if not keyword_set(exists) then begin
    tpxy = { rows:rows,$
        revrows:revrows,$
        cols:cols,$
        revcols:revcols,$
        current:current,$
        pos:pos,$ 
        xrange:xrange,$
        yrange:yrange,$
        panels:ptr_new(), $
        plotvec:plotvec }
    defsysv, '!tplotxy', tpxy
  endif else begin
    !tplotxy.rows=rows
    !tplotxy.revrows=revrows
    !tplotxy.cols=cols
    !tplotxy.revcols=revcols
    !tplotxy.current=current
    !tplotxy.pos=pos
    !tplotxy.xrange=xrange
    !tplotxy.yrange=yrange
    !tplotxy.plotvec=plotvec
  endelse
  
  ; ------------------
  ; Plot EICS data
  ; ------------------
  eics_tmag = sqrt(total(eics_mag^2,2))
  scale_factor=max(eics_tmag)
  
  
  ; -----------------
  ; Scaling
  ; -----------------
  leg_vector = 200. ; legend default vector
  if keyword_set(dynscale) then begin ; dynamic scaling
    max_factor = [1600., 800., 400., 200., 40., 4., 0.] ; GT limits
    idx = where(scale_factor gt max_factor)
    max_factor[-1]= 1.  ; the last element
    leg_vector = max_factor(idx[0]) / 4
  endif
     
   eics_coordtinate_processing, lonlat=eics_pos, mag=eics_mag, scale=scale_factor, new_mag=eics_nmag, leg_vector=leg_vector

   ;plotxyvec,eics_pos,eics_mag,/overplot,color='r', thick=1.475,hsize=0.5,arrowscale=0.02 ; unconverted
   plotxyvec,eics_pos,eics_nmag,/overplot,color='y', thick=1.475,hsize=0.5,uarrowside='none'
   oplot,eics_pos[*,0],eics_pos[*,1],color=5,psym=2,symsize=0.25,thick=3   
  
  ; --------------------
  ; Display annotations
  ;---------------------
  
  ; legend position for 4 entries
  ; in /normal coordinates  
  legx = FLTARR(4) + 0.8  
  legy = FINDGEN(4, INCREMENT=0.05) + 0.01  
  legidx = 0

  ; Text on the left side
  ; The location is consstent with thm_asi_create_mosaic  
  xyouts, 0.005,0.102, 'SECS - EICS', /NORMAL, color=0, charsize=1.5
  
  ; First legend record, 
  xyouts, legx(legidx), legy(legidx), /NORMAL, string(leg_vector, FORMAT='(%"%d ma/V")'),charsize=1.125, charthick=1.25,color=5
  ; and the arrow
  ; move the point to the left
  pos_norm = {x:legx(legidx)-0.01,y:legy(legidx)}
  ; Convert to the view 
  xyz = convert_coord(pos_norm.x, pos_norm.y, /NORMAL, /TO_DATA, /DOUBLE)  
  pos = rotate(xyz[0:1],1)
  xyz = convert_coord(pos_norm.x, pos_norm.y, /NORMAL, /TO_DEVICE, /DOUBLE)
  pos_dev = rotate(xyz[0:1],1)  
  xy_v = [0., 1.] * 0.02 * !d.X_VSIZE
  xy_ve = xy_v + pos_dev
  nmag = eics_coordtinate_convert(xy_ve, /DATA)-pos
  plotxyvec,pos,nmag,/overplot,color='y', thick=1.475,hsize=0.5,uarrowside='none'
  oplot,pos[*,0],pos[*,1],color=5,psym=2,symsize=0.25,thick=3
  
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
    plotfile = 'ThemisMosaicEICS' + yr + mo + da + '_' + hr + mi + sc
    makepng, plotdir+plotfile, /mkdir
    print, 'PNG file created: ' + plotdir + plotfile 
  endif
  
return
end
