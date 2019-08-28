;20170222 Ali
;plots the angular response in polar coordinates. Also, with given angular inputs, calculates the fov response (sdea)
;sdea: SEP detector effective area vs fov angle of incidence
;cosvsep1: sep1 cos angle (sep1 x)
;cosvsep2: sep2 cos angle (sep1 z)
;cosvswiy: perpendicular to both seps (sep1 -y or swia +y)
;plot_colors: colors corresponding to pickup ion energies to plot in sep coordinates. set this keyword to plot the fov response instead.

function mvn_pui_sep_angular_response,cosvsep1,cosvsep2,cosvswiy,plot_colors=colors

  @mvn_pui_commonblock.pro ;common mvn_pui_common

  if ~keyword_set(pui0) then mvn_pui_aos

  if ~keyword_set(cosvsep1) then begin
    ntp=[91,360] ;number of [theta,phi] or [polar,azimuth] points
    td=30.*findgen(ntp[0])/ntp[0] ;degrees
    pd=findgen(ntp[1])
    tr=!dtor*td
    pr=!dtor*pd
    x=sin(tr)#cos(pr)
    y=sin(tr)#sin(pr)
    z=cos(tr)#replicate(1.,ntp[1])
    sdea=mvn_pui_sep_angular_response(z,x,y,plot_colors=colors)
    p=getwindows('mvn_sep_fov_response')
    if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_fov_response')
    p.erase
    p=image(transpose(sdea),pd,td,min=0,max=1.2,aspect_ratio=0,margin=.2,axis_style=2,rgb_table=33,xtitle='Azimuth Angle (Degrees)',ytitle='Polar Angle (Degrees)',title='SEP FOV Response',/current)
    p=colorbar(orientation=1,title='Detector Effective Area (cm2)')
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

  if keyword_set(colors) then begin
    phi=!dtor*findgen(360) ;azimuth angle
    x=pui0.shcoa*cos(phi)
    y=pui0.shcoa*sin(phi)

    edges=[[-pui0.srefa,-pui0.scrsa],[-pui0.srefa,pui0.scrsa],[pui0.srefa,pui0.scrsa],[pui0.srefa,-pui0.scrsa],[-pui0.srefa,-pui0.scrsa]]

    septhet=90.-!radeg*acos(cosvswiy) ;sep-xy angle (degrees): slightly different from how sdea is calculated from 1st cosvsepxy above
    sep1phi=!radeg*atan(cosvsep2,cosvsep1) ;sep-xz angle (degrees)
    sep2phi=sep1phi-90.
    if size(sdea,/n_dimen) eq 1 then begin
      range=[0,100]
      colorbartitle='Pickup O+ Energy (keV)'
    endif else begin
      colorbartitle='Log10 Detector Effective Area (cm2)'
      sym='.'
      range=[-3,1]
      sep1phi=reform(sep1phi,n_elements(sep1phi))
      sep2phi=reform(sep2phi,n_elements(sep2phi))
      septhet=reform(septhet,n_elements(septhet))
      colors=reform(alog10(sdea),n_elements(sdea))
    endelse
    kescaled=bytscl(colors,min=range[0],max=range[1])

    p=getwindows('mvn_sep_angular_response')
    if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_angular_response')
    p.erase
    xtitle='xz (ref) angle'
    ytitle='xy (cross) angle'
    xrange=[-pui0.shcoa,pui0.shcoa]
    ;SEP1F
    p=plot(edges,layout=[2,1,1],title='SEP1F FOV',xtitle=xtitle,ytitle=ytitle,xrange=xrange,yrange=xrange,/aspect_ratio,/current)
    p=scatterplot(/o,sep1phi,septhet,rgb=33,sym=sym,magnitude=kescaled)
    p=plot(x,y,/o)
    p=colorbar(target=p,rgb=33,range=range,title=colorbartitle,/orient)
    ;SEP2F
    p=plot(edges,layout=[2,1,2],title='SEP2F FOV',xtitle=xtitle,ytitle=ytitle,xrange=xrange,yrange=xrange,/aspect_ratio,/current)
    p=scatterplot(/o,sep2phi,septhet,rgb=33,magnitude=kescaled)
    p=plot(x,y,/o)
  endif

  return,sdea

end