;20180330 Ali
;plots celestial objects w.r.t. 4 sep fov's
;includes useful info such as mars shine, fraction of each fov covered by mars, etc.

pro mvn_sep_fov_mapper,pdf,sepphi,septheta

  septheta=90.-!radeg*acos(-pdf[1,*]) ;sep-xy angle (degrees)
  sep1fphi=!radeg*atan(pdf[2,*],pdf[0,*]) ;sep1f-xz angle (degrees) [-180,180]
  sepphi=sep1fphi-45. ;to align phi=0 with s/c +Z axis
  wlt180=where(sepphi lt -180.,/null)
  if n_elements(wlt180) gt 0 then sepphi[wlt180]+=360.

end

;tms: time minimum subscript, normally supplied by mvn_sep_fov_snap
;edge: surface edge of mars, occultation altitude edge, Sun-ward hemisphere edge
;fraction: fraction of fov covered by mars, atmo and mars shine, etc.
;pos: position of points to be plotted with colors given by cr
;cr: colors corresponding to pos
;sym: symbol used to plot pos
;overplot: if set, does not erase the previous mvn_sep_fov plot
;atmo: plots atmosphere shine

pro mvn_sep_fov_plot,tms,edge=edge,fraction=fraction,pos=pos,cr=cr,sym=sym,overplot=overplot,atmo=atmo,save=save

  @mvn_sep_fov_common.pro
  @mvn_pui_commonblock.pro ;common mvn_pui_common

  shcoa=30.
  srefa=15.5 ;ref angle
  scrsa=21.0 ;cross angle
  sref0=20.5 ;Sun keep-out
  scrs0=25.0 ;
  phi=!dtor*findgen(360) ;azimuth angle
  x=shcoa*cos(phi)
  y=shcoa*sin(phi)
  edges=[[-srefa,-scrsa],[-srefa,scrsa],[srefa,scrsa],[srefa,-scrsa],[-srefa,-scrsa]]
  edge0=[[-sref0,-scrs0],[-sref0,scrs0],[sref0,scrs0],[sref0,-scrs0],[-sref0,-scrs0]]
  title=['1F','2F','1R','2R']

  name='mvn_sep_fov_plot'
  p=getwindows(name)
  if keyword_set(p) then p.setcurrent else p=window(name=name)
  if ~keyword_set(overplot) then begin
    p.erase
    p.refresh,/disable
    p=plot([0],/nodat,/aspect_ratio,xrange=[180,-180],yrange=[-90,90],xtickinterval=45.,ytickinterval=45.,xminor=8.,yminor=8.,xtitle='SEP XZ (ref) angle',ytitle='SEP XY (cross) angle',/current)
    if n_elements(tms) eq 0 then begin
      for pn=-1,2 do begin  ;SEP 2R,1F,2F,1R
        p=plot(edges+rebin([90.*pn-45.,0.],[2,5]),/o)
        p=text((3.-pn)/5.,.76,'SEP'+title[pn])
      endfor
    endif
  endif

  if keyword_set(pos) then begin
    mvn_sep_fov_mapper,pos,sepphi,septheta
    if keyword_set(cr) then p=scatterplot(/o,sepphi,septheta,magnitude=cr,rgb=33,sym='.',name=' ') else p=plot([sepphi,sepphi],[septheta,septheta],/o,name=sym.name,sym_color=sym.color,sym=sym.symbol,' ')
  endif

  if n_elements(tms) gt 0 then begin
    pos =mvn_sep_fov[tms].pos
    time=mvn_sep_fov[tms].time
    tal= mvn_sep_fov[tms].tal
    rad= mvn_sep_fov[tms].rad
    att= mvn_sep_fov[tms].att
  endif else return

  cossza=alog10(fraction.cossza)
  atmosh=alog10(fraction.atmosh)
  cosszamin=-2
  cosszamax=0
  tanalt=fraction.tanalt
  tanaltmin=0
  tanaltmax=200
  tanaltrgb=(colortable(62,/reverse))[0:250,*]
  cosszargb=[(colortable(64,/reverse))[0:254,*],transpose([255,200,0])]
  p=image(tanalt,fraction.phid,fraction.thed-90.,rgb=tanaltrgb,/o,min=tanaltmin,max=tanaltmax,transparency=10) ;Tangent Altitude
  p=image(cossza,fraction.phid,fraction.thed-90.,rgb=cosszargb,/o,min=cosszamin,max=cosszamax,transparency=10) ;Mars Surface
  if keyword_set(atmo) then p=image(atmosh,fraction.phid,fraction.thed-90.,rgb=cosszargb,/o,min=cosszamin,max=cosszamax,transparency=10) ;Atmo Shine
  p=colorbar(rgb=tanaltrgb,range=[tanaltmin,tanaltmax],title='Tangent Altitude (km)',position=[0.7,.16,.97,.18],transparency=10)
  p=colorbar(rgb=cosszargb,range=[cosszamin,cosszamax],title='Log10[cos(SZA)]',position=[0.7,.06,.97,.08],transparency=10)

  tags=strlowcase(tag_names(pos))
  tags=[tags,strtrim(fix(mvn_sep_fov0.occalt[1]),2)+' km','Marsward','Sunward','Mars Surface']
  colors=['orange','deep_sky_blue','r','g','m','c','b','k','b','r']
  syms=['o','o','o','o','o','*','*','x','.','.','.','.']
  npos=n_tags(pos)
  for ipos=-2,npos-1 do begin
    if ipos eq -4 then pdf=edge.occedge ;Mars occultation altitude
    if ipos eq -3 then pdf=edge.maredge ;Mars-ward hemisphere
    if ipos eq -2 then pdf=edge.sunedge ;Sun-ward hemisphere
    if ipos eq -1 then pdf=edge.suredge ;Mars edge
    if ipos ge 0  then pdf=pos.(ipos) ;planets and x-ray sources
    mvn_sep_fov_mapper,pdf,sepphi,septheta
    p=plot([sepphi,sepphi],[septheta,septheta],/o,name=tags[ipos],sym_color=colors[ipos],sym=syms[ipos],/sym_filled,' ')
    ;the positions in the plot are repeated twice for the legend symbols to show up!
  endfor
  p=legend(/orient,position=[1,1],sample_width=0)

  for pn=-1,2 do begin  ;SEP 2R,1F,2F,1R
    if att[pn and 1] eq 1. then p=plot(edges   +rebin([90.*pn-45.,0.],[2,5]),/o)
    if att[pn and 1] eq 2. then p=plot(edges/2.+rebin([90.*pn-45.,0.],[2,5]),/o)
    p=plot(edge0+rebin([90.*pn-45.,0.],[2,5]),/o,'--')
    p=text((3.-pn)/5.,.92,strtrim(fraction.mars_surfa[pn],2))
    p=text((3.-pn)/5.,.89,strtrim(fraction.atmo_shine[pn],2))
    p=text((3.-pn)/5.,.86,strtrim(fraction.mars_shine[pn],2))
    p=text((3.-pn)/5.,.83,strtrim(fraction.ashine_fov[pn],2))
    p=text((3.-pn)/5.,.80,strtrim(fraction.mshine_fov[pn],2))
    p=text((3.-pn)/5.,.76,'SEP'+title[pn])
  endfor
  p=plot(45.*[-3.,-1.,0.,1.,3.],[0.,0.,0.,0.,0.],'+',/o) ;centers of fov
  p=text(0.01,.92,'Mars Surface')
  p=text(0.01,.89,'Atmo Shine')
  p=text(0.01,.86,'Mars Shine')
  p=text(0.01,.83,'Atmo Shine*FOV')
  p=text(0.01,.80,'Mars Shine*FOV')
  p=text(0.01,.13,'mvn alt (km)')
  p=text(0.01,.10,'Sco X-1 tanalt (km)')
  p=text(0.01,.05,'Distance to Phobos='+strtrim(fix(rad.pho),2)+' km, mvn speed='+strtrim(rad.ram,2)+' km/s')
  for pn=0,2 do begin  ;tangent altitude
    p=text((3.1-pn)/5.5,.16,(['sphere','ellipsoid','areoid'])[pn])
    p=text((3.1-pn)/5.5,.13,strtrim(tal[pn].mar,2))
    p=text((3.1-pn)/5.5,.10,strtrim(tal[pn].sx1,2))
  endfor
  p=text(0.01,0.01,'SEP1_TIME='+time_string(time)+', SEP1_ATT='+strtrim(fix(att[0]),2)+', SEP2_ATT='+strtrim(fix(att[1]),2))
  p.refresh
  if keyword_set(save) then begin
    if strtrim(save,2) eq '1' then save2='/' else save2=save+'/'
    dir='Desktop/sep/fov/'+name+time_string(time,tformat='_YYYYMMDD')+save2
    file_mkdir2,dir
    p.save,resolution=96,dir+name+'_'+time_string(time,format=2)+'.png'
  endif

  ;if keyword_set(pui) then mvn_sep_fov_pui_plot ;to plot mag and pickup ion velocity distributions

end