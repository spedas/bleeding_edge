;+
; NAME:
;    ELF_MAP_STATE_SOUTH_T96_INTERVALS
;
; PURPOSE:
;    map ELFIN spacecraft to their magnetic footprints in the south
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    elf_map_state_south_t96_intervals,'2008-03-10/00:00:00'
;
; INPUTS:
;    tstart start time for the map
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    gifout   generate a gif image at output
;    noview   do not open window for display
;    move   move file to summary plot directory
;    insert_stop  insert a stop for debugging
;    model    specify Tsyganenko model like 't89' or 't01', default is 't96'
;    quick    plot only every 10 minutes to speed up
;
; OUTPUTS:
;    None
;
; OPTIONAL OUTPUTS:
;    GIF images
;
; COMMON BLOCKS:
;    None
;
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
;    elf_map_state_south_t96,'2007-03-10/00:00:00'
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey  some time 2007
;                Version 2.0 August, 25, 2011, fixed:
;     - T96
;                       - GSE plots after ARTEMIS
;     - corrected site locations for different years
;                       - single_time
;                       - some checks
;                       - added keyword quick, and many more small things
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL:
;
;-

pro elf_map_state_south_t96_intervals, tstart, gifout=gifout, noview=noview,$
  move=move, insert_stop=insert_stop, model=model, quick=quick, dir_move=dir_move, $
  no_trace=no_trace, tstep=tstep

  ; some checks
  if (time_double(tstart) lt time_double('2018-09-16')) then begin
    print,'Time before ELFIN launch'
    return
  endif

  ; some setup
  elf_init
  if keyword_set(dir_move) then begin
    dir_products=dir_move
  endif

  ; annotate
  xann=10
  yann=485

  ;  thm_init,/no_color_setup
  aacgmidl
  loadct,39
  thm_init
  set_plot,'z'
  device,set_resolution=[750,500]
  tvlct,r,g,b,/get

  ; colors and symbols, closest numbers for loadct,39
  symbols=[4, 2]  ;[5,2,1,4,6]
  probes=['a','b']
  index=[253,254]  ;,252,253,254]

  ; color=253 will be dark blue for ELFIN A
  ;P4 dark blue  [0,0,255],    57 IDL symbol 4
  r[index[0]]=30   & g[index[0]]=144   & b[index[0]]=255
  ; color=254 will be green for ELFIN B
  ;P5 purple     [0,255,0],   30 IDL symbol 6
  r[index[1]]=138 & g[index[1]]=43   & b[index[1]]=226
  tvlct,r,g,b

  ; time input
  timespan,tstart,1,/day
  tend=time_string(time_double(tstart)+86400.0d0)
  sphere=1
  lim=2
  earth=findgen(361)

  ; circle of the field of view of the all-sky imagers
  ; solve the spherical triangle to show the circle with z-radius
  ; formula from Taff, Celestial mechanics
  ;azi=findgen(361)
  ;a=6378.d    ; Earth radius in km
  ;z=120.d     ; altitude of emission in km
  ;zeta=80.d   ; zenith angle
  ;theta=(180.d0/!dpi)*asin(a/(a+z)*sin(zeta*!dpi/180.d0)) ; second angle of triangle
  ;alpha=zeta-theta        ; angle at Earth center

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

  ; now loop through spacecraft
  for sc=0,1 do begin

    ; load spacecraft data
    elf_load_state,probe=probes[sc]
    comm="get_data,'el"+probes[sc]+"_pos_gei',data=dat_d1"  ; position in GEI
    res=execute(comm)
    ; also get data for 30 minutes into next day
    tr=timerange()+86400.
    elf_load_state,probe=probes[sc], trange=tr, suffix='_d2'
    comm="get_data,'el"+probes[sc]+"_pos_gei_d2',data=dat_d2"  ; position in GEI
    res=execute(comm)
    ;new_data={x:datnd.x[0:1800],y:datnd.y[0:1800,*]}
    ;comm="store_data,'el"+probes[sc]+"_pos_gei_nextday',data=new_data" ; position in GEI
    ;res=execute(comm)
    new_t=array_concat(dat_d2.x[0:1800], dat_d1.x)
    new_x=array_concat(dat_d2.y[0:1800,0], dat_d1.y[*,0])
    new_y=array_concat(dat_d2.y[0:1800,1], dat_d1.y[*,1])
    new_z=array_concat(dat_d2.y[0:1800,2], dat_d1.y[*,2])
    dats={x:new_t, y:[[new_x], [new_y], [new_z]]}
    comm="store_data,'el"+probes[sc]+"_pos_gei',data=dats"  ; position in GEI
    res=execute(comm)

    ; prepare arrays for Tsyganenko
    comm="cotrans, 'el"+probes[sc]+"_pos_gei', 'el"+probes[sc]+"_pos_gse', /gei2gse"
    res=execute(comm)
    comm="cotrans, 'el"+probes[sc]+"_pos_gse', 'el"+probes[sc]+"_pos_gsm', /gse2gsm"
    res=execute(comm)
    comm="cotrans, 'el"+probes[sc]+"_pos_gsm', 'el"+probes[sc]+"_pos_sm', /gsm2sm"
    res=execute(comm)
    comm="get_data,'el"+probes[sc]+"_pos_sm',data=dats"  ; position in SM
    res=execute(comm)

    count=n_elements(dats.x)
    num=n_elements(dats.x)-1

    ; prepare parameter for input into Tsyganenko models
    case 1 of
      (tsyg_mod eq 't89'): tsyg_parameter=2.0d
      (tsyg_mod eq 't96'): tsyg_parameter=[[replicate(dynp,count)],[replicate(dst,count)],$
        [replicate(bswy,count)],[replicate(bswz,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)]]
      (tsyg_mod eq 't01'): tsyg_parameter=[[replicate(dynp,count)],[replicate(dst,count)],$
        [replicate(bswy,count)],[replicate(bswz,count)],$
        [replicate(g1,count)],[replicate(g2,count)],[replicate(0.,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)]]
      ELSE: begin
        print,'Unknown Tsyganenko model'
        return
      endcase
    endcase

  if keyword_set(no_trace) then goto, skip_trace

  ; mapping with Tsyganenko-96, new way
  comm="ttrace2iono,'el"+probes[sc]+"_pos_gsm',newname='el"+probes[sc]+$
    "_ifoot_geo',external_model=tsyg_mod,par=tsyg_parameter,/km,in_coord='gsm',out_coord='geo', /south"
  res=execute(comm)
 
skip_trace:
 
    comm="get_data,'el"+probes[sc]+"_ifoot_geo',data=d"
    res=execute(comm)
    print,'Done '+tsyg_mod+' ',probes[sc]

    Case sc of 
      0: begin
        lon = !radeg * atan(d.y[*,1],d.y[*,0])
        lat = !radeg * atan(d.y[*,2],sqrt(d.y[*,0]^2+d.y[*,1]^2))
        time_dummy=time_string(dats.x)
        ; clean up data that's out of scope
        junk=where(lat gt 0.,count2)
        if (count2 gt 0) then begin
          lat[junk]=!values.f_nan
          lon[junk]=!values.f_nan
        endif
      end 
      1: begin
        lon2 = !radeg * atan(d.y[*,1],d.y[*,0])
        lat2 = !radeg * atan(d.y[*,2],sqrt(d.y[*,0]^2+d.y[*,1]^2))
        time_dummy2=time_string(dats.x)
        junk=where(lat2 gt 0.,count2)
        if (count2 gt 0) then begin
          lat2[junk]=!values.f_nan
          lon2[junk]=!values.f_nan
        endif
      end
    Endcase
     
    ; time markers
    if sc eq 0 then begin
      posa_00={time:time_dummy[0]         ,ft_geo:[lon[0],lat[0]]}
      posa_06={time:time_dummy[count/4l]  ,ft_geo:[lon[count/4l],lat[count/4l]]}
      posa_12={time:time_dummy[count/2l]  ,ft_geo:[lon[count/2l],lat[count/2l]]}
      posa_18={time:time_dummy[count*3l/4],ft_geo:[lon[count*3l/4],lat[count*3l/4]]}
;      pos_24={time:time_dummy[count-1]   ,ft_geo:[lon[count-1],lat[count-1]]}
    endif
    if (sc eq 1) then begin
      posb_00={time:time_dummy[0]         ,ft_geo:[lon2[0],lat2[0]]}
      posb_06={time:time_dummy[count/4l]  ,ft_geo:[lon2[count/4l],lat2[count/4l]]}
      posb_12={time:time_dummy[count/2l]  ,ft_geo:[lon2[count/2l],lat2[count/2l]]}
      posb_18={time:time_dummy[count*3l/4],ft_geo:[lon2[count*3l/4],lat2[count*3l/4]]}
;      posb_24={time:time_dummy[count-1]   ,ft_geo:[lon3[count-1],lat3[count-1]]}
    endif

  endfor  ; sc loop

  ; get positions for orbit plots
  get_data,'ela_pos_sm',data=ela_state_pos_sm
  get_data,'elb_pos_sm',data=elb_state_pos_sm

  ; display latitude/longitude
  ;-------------------------------------------------------------------------------
  ;mlat contours
  ;the call of cnv_aacgm here converts from geomagnetic to geographic
  latstep=-10
  latstart=0
  latend=-90
  lonstep=30
  lonstart=0
  lonend=360
  nmlats=round((latend-latstart)/float(latstep)+1)
  mlats=latstart+findgen(nmlats)*latstep
  n2=150
  v_lat=fltarr(nmlats,n2)
  v_lon=fltarr(nmlats,n2)
  height=100.
  for i=0,nmlats-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r1,error,/geo
      v_lat[i,j]=u
      v_lon[i,j]=v
    endfor
  endfor

  ;mlon contours
  ;get geomagnetic lat/lons
  nmlons=12 ;mlons shown at intervals of 15 degrees or one hour of MLT
  mlon_step=round(360/float(nmlons))
  n2=20
  u_lat=fltarr(nmlons,n2)
  u_lon=fltarr(nmlons,n2)
  cnv_aacgm, 56.35, 265.34, height, outlat,outlon,r1,error   ;Gillam
  mlats=latstart+findgen(n2)/float(n2-1)*(latend-latstart)
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r1,error
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor
  ;
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r1,error,/geo
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor

  ; setup for orbits
  ; 1 24 hour plot, 4 6 hr plots, 12 2 hr plots
  hr_st = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)]
  hr_en = hr_st + 1.5
  ; Stings for labels, filenames
  hr_ststr = string(hr_st, format='(i2.2)')
  plot_lbl=strarr(25)
  for m=0,23 do plot_lbl[m] = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'  ;+'-'+hr_enstr
  file_lbl = '_'+hr_ststr   ;+hr_enstr
  min_st = hr_st*3600.    ;*60.  ;*3600.   ;*res
  min_en = min_st + 90.*60
  idx=where(min_en GT n_elements(ela_state_pos_sm.x), ncnt)
  if ncnt GT 0 then min_en[idx]=n_elements(ela_state_pos_sm.x)-1
  nplots = n_elements(min_st)

  ; for gif-output
  date=strmid(tstart,0,10)
  timespan, tstart
  tr=timerange()

;------------------------------------
; Start Plots
;------------------------------------
for k=0,nplots-2 do begin

   !p.multi=0
   if keyword_set(gifout) then begin
      set_plot,'z'
      device,set_resolution=[800,600]
      charsize=1
   endif else begin
      set_plot,'win'
      window,xsize=800,ysize=600
      charsize=1.5
   endelse

  ; set up map
  title='Southern footprints '+strmid(tstart,0,10)+plot_lbl[k]
  map_set,-90.,-90.,/orthographic,/conti,limit=[0.,-180.,-90.,180.],$
    title=title,position=[0.005,0.005,600./800.*0.96,0.96]
  map_grid,latdel=-10.,londel=30.

  for i=0,nmlats-1 do oplot,v_lon[i,*],v_lat[i,*],color=250,thick=contour_thick,linestyle=1
  for i=0,nmlons-1 do begin
    idx=where(u_lon[i,*] NE 0)
    oplot,u_lon[i,idx],u_lat[i,idx],color=250,thick=contour_thick,linestyle=1
  endfor

  this_time=ela_state_pos_sm.x[min_st[k]:min_en[k]]
  this_lon=lon[min_st[k]:min_en[k]]
  this_lat=lat[min_st[k]:min_en[k]]
  this_time2=elb_state_pos_sm.x[min_st[k]:min_en[k]]
  this_lon2=lon2[min_st[k]:min_en[k]]
  this_lat2=lat2[min_st[k]:min_en[k]]

  npts=n_elements(this_lat)
  diff=this_lat[1:npts-1] - this_lat[0:npts-2]
  idx = where(abs(diff) GT 1.5, ncnt)
  idxs=idx[0]
  idxe=idx[ncnt-1]
  if ncnt GT 2 then begin
    plots, this_lon[0:idxs], this_lat[0:idxs], psym=2, symsize=.08, color=253   ; thick=3
    plots, this_lon[idxe+1:npts-1], this_lat[idxe+1:npts-1], psym=2, symsize=.08, color=253   ; thick=3
    plots, this_lon[0], this_lat[0], psym=symbols[0], symsize=1.5, color=253   ; thick=3
  endif

  npts=n_elements(this_lat2)
  diff=this_lat2[1:npts-1] - this_lat2[0:npts-2]
  idx = where(abs(diff) GT 1.5, ncnt)
  idxs=idx[0]
  idxe=idx[ncnt-1]
  if ncnt GT 2 then begin
    plots, this_lon2[0:idxs], this_lat2[0:idxs], psym=2, symsize=.08, color=254    ; thick=3
    plots, this_lon2[idxe+1:npts-1], this_lat2[idxe+1:npts-1], psym=2, symsize=.08, color=254    ; thick=3
    plots, this_lon2[0], this_lat2[0], psym=2, symsize=1.5, color=254    ; thick=3
  endif

  if keyword_set(tstep) then begin
    tstep=300.
    ; add tick marks for A
    res=this_time[1] - this_time[0]
    istep=tstep/res
    last = n_elements(this_time)
    steps=lindgen(last/istep+1)*istep
    tmp=max(steps,nmax)
    if tmp gt (last-1) then steps=steps[0:nmax-1]
    tsteps0=this_time[steps[0]]
    dummy=min(abs(this_time-tsteps0),istep0)
    isteps=steps+istep0
    plots, this_lon[isteps], this_lat[isteps], psym=1, symsize=1.5, color=253
    ; add tick marks for B
    res=this_time2[1] - this_time2[0]
    istep=tstep/res
    last = n_elements(this_time2)
    steps=lindgen(last/istep+1)*istep
    tmp=max(steps,nmax)
    if tmp gt (last-1) then steps=steps[0:nmax-1]
    tsteps0=this_time2[steps[0]]
    dummy=min(abs(this_time2-tsteps0),istep0)
    isteps=steps+istep0
    plots, this_lon2[isteps], this_lat2[isteps], psym=1, symsize=1.5, color=254
  endif

  ovalget,6,pwdboundlonlat,ewdboundlonlat ; get oval data, north first, then mirror lat to south
  plots,pwdboundlonlat[*,0],-pwdboundlonlat[*,1],color=155, thick=1.05
  plots,ewdboundlonlat[*,0],-ewdboundlonlat[*,1],color=155, thick=1.05

  xyouts,xann,yann+18*4,'ELFIN (A)',/device,charsize=charsize,color=253
  xyouts,xann,yann+18*3,'ELFIN (B)',/device,charsize=charsize,color=254
  case 1 of
    tsyg_mod eq 't89': xyouts,.6,.02,'Tsyganenko-1989',/normal, charsize=.75,color=255
    tsyg_mod eq 't96': xyouts,.6,.02,'Tsyganenko-1996',/normal, charsize=.75,color=255
    tsyg_mod eq 't01': xyouts,.6,.02,'Tsyganenko-2001',/normal, charsize=.75,color=255
  endcase
  msg = 'Geo Lat/Lon - Black dotted lines'
  xyouts, .01, .06, msg, /normal, color=255, charsize=.75
  msg = 'Mag Lat/Lon - Red dotted lines'
  xyouts, .01, .04, msg, /normal, color=252, charsize=.75
  msg = 'Auroral Oval - Green lines'
  xyouts, .01, .02, msg, /normal, color=155, charsize=.75

  ; mark times for A
  year=fix(strmid(tstart,0,4))
  month=fix(strmid(tstart,5,2))
  if (hr_st[k] EQ 0) && (posa_00.ft_geo[1] ge 45.) then xyouts,posa_00.ft_geo[0],posa_00.ft_geo[1],$
    strmid(posa_00.time,11,5),color=253,/data,charsize=charsize+0.5
  if (hr_st[k] LE 6 AND hr_en[k] GE 6) && (posa_06.ft_geo[1] ge 45.) then xyouts,posa_06.ft_geo[0],posa_06.ft_geo[1],$
    strmid(posa_06.time,11,5),color=253,/data,charsize=charsize+0.5
  if (hr_st[k] LE 12 AND hr_en[k] GE 12) && (posa_12.ft_geo[1] ge 45.) then xyouts,posa_12.ft_geo[0],posa_12.ft_geo[1],$
    strmid(posa_12.time,11,5),color=253,/data,charsize=charsize+0.5
  if (hr_st[k] LE 18 AND hr_en[k] GE 18) &&(posa_18.ft_geo[1] ge 45.) then xyouts,posa_18.ft_geo[0],posa_18.ft_geo[1],$
    strmid(posa_18.time,11,5),color=253,/data,charsize=charsize+0.5

  ; mark times for B
  year=fix(strmid(tstart,0,4))
  month=fix(strmid(tstart,5,2))
  if (hr_st[k] EQ 0) && (posb_00.ft_geo[1] ge 45.) then xyouts,posb_00.ft_geo[0],posb_00.ft_geo[1],$
    strmid(posb_00.time,11,5),color=254,/data,charsize=charsize+0.5
  if (hr_st[k] LE 6 AND hr_en[k] GE 6) && (posb_06.ft_geo[1] ge 45.) then xyouts,posb_06.ft_geo[0],posb_06.ft_geo[1],$
    strmid(posb_06.time,11,5),color=254,/data,charsize=charsize+0.5
  if (hr_st[k] LE 12 AND hr_en[k] GE 12) && (posb_12.ft_geo[1] ge 45.) then xyouts,posb_12.ft_geo[0],posb_12.ft_geo[1],$
    strmid(posb_12.time,11,5),color=254,/data,charsize=charsize+0.5
  if (hr_st[k] LE 18 AND hr_en[k] GE 18) &&(posb_18.ft_geo[1] ge 45.) then xyouts,posb_18.ft_geo[0],posb_18.ft_geo[1],$
    strmid(posb_18.time,11,5),color=254,/data,charsize=charsize+0.5

    xcenter=median([median(ela_state_pos_sm.y[*,0]),median(elb_state_pos_sm.y[*,0])])/6378.
    ycenter=median([median(ela_state_pos_sm.y[*,1]),median(elb_state_pos_sm.y[*,1])])/6378.
    zcenter=median([median(ela_state_pos_sm.y[*,2]),median(elb_state_pos_sm.y[*,2])])/6378.

    ; SM X-Z
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
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]

    ;plot orbit
    plots, ela_state_pos_sm.y[0,0]/6378., ela_state_pos_sm.y[0,2]/6378.,  $
      color=253,psym=symbols[0],symsize=0.8
    plots, elb_state_pos_sm.y[0,0]/6378., elb_state_pos_sm.y[0,2]/6378.,  $
      color=254,psym=symbols[1],symsize=0.8
    oplot,ela_state_pos_sm.y[min_st[k]:min_en[k],0]/6378., $
       ela_state_pos_sm.y[min_st[k]:min_en[k],2]/6378.,color=253,psym=3
    oplot,elb_state_pos_sm.y[min_st[k]:min_en[k],0]/6378., $
       elb_state_pos_sm.y[min_st[k]:min_en[k],2]/6378.,color=254,psym=3

    ; plot lines to separate plots 
    plots,[600./800.*0.96,1.],[0.005+0.96*3./3.,0.005+0.96*3./3.]-0.007,/normal
    plots,[600./800.*0.96,1.],[0.005+0.96*2./3.,0.005+0.96*2./3.]-0.005,/normal

    ; GSE X-Y
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*1./3.,0.985,0.96*2./3.]
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'
    xyouts,.05,-1.85,'-Y'
    xyouts,.05,1.7,'Y'
    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]
    plots, ela_state_pos_sm.y[0,0]/6378., ela_state_pos_sm.y[0,1]/6378.,  $
      color=253,psym=symbols[0],symsize=0.8
    plots, elb_state_pos_sm.y[0,0]/6378., elb_state_pos_sm.y[0,1]/6378.,  $
      color=254,psym=symbols[1],symsize=0.8
    oplot,ela_state_pos_sm.y[min_st[k]:min_en[k],0]/6378., $
      ela_state_pos_sm.y[min_st[k]:min_en[k],1]/6378.,color=253,psym=3
    oplot,elb_state_pos_sm.y[min_st[k]:min_en[k],0]/6378., $
      elb_state_pos_sm.y[min_st[k]:min_en[k],1]/6378.,color=254,psym=3
    plots,[600./800.*0.96,1.],[0.005+0.96*1./3.,0.005+0.96*1./3.]-0.0025,/normal

    ; GSE Y-Z
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*0./3.,0.985,0.96*1./3.]
    oplot,cos(earth*!dtor),sin(earth*!dtor)
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-Y'
    xyouts,1.75,.05,'Y'
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'

    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]
    for sc=1,2 do res=execute("oplot,el"+probes[sc-1]+"_state_pos_sm.y[min_st[k]:min_en[k],1]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_sm.y[min_st[k]:min_en[k],2]/6378.,color=252+sc,psym=3")
    for sc=1,2 do res=execute("plots,el"+probes[sc-1]+"_state_pos_sm.y[0,1]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_sm.y[0,2]/6378.,color=252+sc,psym=symbols[sc-1],symsize=0.5")
    plots,[600./800.*0.96,1.],[0.005+0.96*0./3.,0.005+0.96*0./3.],/normal

    ; gif-output
    date=strmid(tstart,0,10)
    if keyword_set(gifout) then begin
      image=tvrd()
      device,/close
;      if !d.name EQ 'WIN' then set_plot,'win' else set_plot,'x'
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      if not keyword_set(noview) then window,3,xsize=800,ysize=600
      if not keyword_set(noview) then tv,image
      dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2) 
      file_mkdir, dir_products 
      filedate=file_dailynames(trange=tr, /unique, times=times)
      if keyword_set(move) then gif_name=dir_products+'/'+'elf_l2_southtrack_'+filedate+file_lbl[k] else $
        gif_name='elf_l2_southtrack_'+filedate+file_lbl[k]
      write_gif,gif_name+'.gif',image,r,g,b
      print,'Output in ',gif_name+'.gif'
    endif

    if keyword_set(insert_stop) then stop

  endfor ; end of plotting loop
 
end
