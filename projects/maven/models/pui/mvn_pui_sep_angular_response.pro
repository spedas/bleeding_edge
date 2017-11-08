;20170222 Ali
;sdea: SEP detector effective area vs fov angle of incidence
;cosvsep1: desired sep cos angles (sep-x)
;cosvsep2: the other sep cos angles (sep-z)
;cosvswiy: perpendicular to both seps (sep-y or swia-y)
;use keyword /plot to plot the angular response

function mvn_pui_sep_angular_response,cosvsep1,cosvsep2,cosvswiy,plot_response=plot_response,trajplot=trajplot,tsteps=tsteps

@mvn_pui_commonblock.pro ;common mvn_pui_common

if ~keyword_set(pui0) then mvn_pui_aos

if keyword_set(plot_response) then begin
  phi=!dtor*findgen(360) ;azimuth angle
  theta=!dtor*findgen(30) ;polar angle
  x=sin(theta)#cos(phi)
  y=sin(theta)#sin(phi)
  z=cos(theta)#replicate(1.,360)
  sdea=mvn_pui_sep_angular_response(z,x,y)
  p=image(transpose(sdea),min=0,max=1.2,aspect_ratio=0,margin=.2,axis_style=2,rgb_table=33,xtitle='Azimuth Angle (Degrees)',ytitle='Polar Angle (Degrees)',title='SEP FOV Response')
  p=colorbar(orientation=1,title='Effective Area (cm2)')
  return,'plot created!'
endif

cosfovsep  =cos(!dtor*pui0.shcoa)
cosfovsepxy=cos(!dtor*pui0.scrsa) ;sep cross angle (half angular extent) in sep xy plane (s/c xz)
cosfovsepxz=cos(!dtor*pui0.srefa) ;sep ref   angle (half angular extent) in sep xz plane (s/c yz)

cosvsepxy=cosvsep1/sqrt(cosvsep1^2+cosvswiy^2) ;cosine of angle b/w projected -v on sep xy plane and sep fov
;cosvsepxy=sqrt(1.-cosvswiy^2) ;another way to calculate the above, but giving slightly different result at high xz (ref) angles
cosvsepxz=cosvsep1/sqrt(cosvsep1^2+cosvsep2^2) ;cosine of angle b/w projected -v on sep xz plane and sep fov
sdeaxy=(cosvsepxy-cosfovsepxy)/(1-cosfovsepxy) ;sep projected detector effective area on sep xy plane
sdeaxz=(cosvsepxz-cosfovsepxz)/(1-cosfovsepxz) ;sep projected detector effective area on sep xz plane
sdea=pui0.stdea*sdeaxy*sdeaxz ;sep detector effective area factor (cm2)

;very small sep detector area within cosfovsep (cm2)
sdea[where((cosvsepxy lt cosfovsepxy) or (cosvsepxz lt cosfovsepxz),/null)]=1e-2 ;similar to a closed attenuator
sdea[where(cosvsep1 lt cosfovsep,/null)]=0. ;zero everywhere else!

if keyword_set(trajplot) then begin
  phi=!dtor*findgen(360) ;azimuth angle
  x=pui0.shcoa*cos(phi)
  y=pui0.shcoa*sin(phi)
  
  edges=[[-pui0.srefa,-pui0.scrsa],[-pui0.srefa,pui0.scrsa],[pui0.srefa,pui0.scrsa],[pui0.srefa,-pui0.scrsa],[-pui0.srefa,-pui0.scrsa]]

  septhet=90.-!radeg*acos(cosvswiy) ;sep-xy angle (degrees): slightly different from how sdea is calculated from 1st cosvsepxy above
  sep1phi=!radeg*atan(cosvsep2,cosvsep1) ;sep-xz angle (degrees)
  sep2phi=sep1phi-90.
  ke=average(pui2[*,tsteps].ke,2,/nan)/1e3 ;pickup O+ energy (keV)
  kescaled=bytscl(ke,min=0.,max=100.)

  p=getwindows('septraj')
  if keyword_set(p) then p.setcurrent else p=window(name='septraj')
  p.erase
  ;SEP1F
  p=plot(edges,layout=[2,1,1],title='SEP1F FOV',xtitle='xz (ref) angle',ytitle='xy (cross) angle',xrange=[-pui0.shcoa,pui0.shcoa],yrange=[-pui0.shcoa,pui0.shcoa],/aspect_ratio,/current)
  p=colorbar(target=p,rgb=33,range=[0,100],title='Pickup O+ Energy (keV)',/orient)
  p=plot(x,y,/o)
  p=scatterplot(/o,sep1phi,septhet,rgb=33,magnitude=kescaled)
  ;SEP2F
  p=plot(edges,layout=[2,1,2],title='SEP2F FOV',xtitle='xz (ref) angle',ytitle='xy (cross) angle',xrange=[-pui0.shcoa,pui0.shcoa],yrange=[-pui0.shcoa,pui0.shcoa],/aspect_ratio,/current)
  p=plot(x,y,/o)
  p=scatterplot(/o,sep2phi,septhet,rgb=33,magnitude=kescaled)

;  stop
  return,0
endif

return,sdea

end