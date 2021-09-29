;20191002 Ali
;plots MAVEN/SEP fov projection on a map of the surface of Mars

pro mvn_sep_fov_mars_mapper,xyziau,phi,theta

  phi=reform(!radeg*atan(xyziau[1,*],xyziau[0,*]))
  theta=reform(90.-!radeg*acos(xyziau[2,*]))
  wlt0=where(phi lt 0.,/null)
  if n_elements(wlt0) gt 0 then phi[wlt0]+=360.

end

pro mvn_sep_fov_mars_plot,sur,mvn_sep_fov,magnitude=magnitude,sun=sun,mvn=mvn,overplot=overplot,edge=edge

  pos=mvn_sep_fov.pos.mar
  rad=mvn_sep_fov.rad.mar
  pdm=mvn_sep_fov.pdm.mar
  qrot_iau=mvn_sep_fov.qrot_iau
  rmars=3390.

  dim0=size(sur,/dim)
  if dim0[0] eq 0 then sur=rebin([sur],3)
  if n_elements(dim0) eq 3 then dim=dim0[1]*dim0[2] else if n_elements(dim0) eq 2 then dim=dim0[1] else dim=1
  spoint=reform(sur,[3,dim])
  posmar=(replicate(1.,3)#rad)*pos
  xyzsep1=spoint-rebin(posmar,[3,dim]) ;xyz coordinates of surface seen by MAVEN in sep1 reference frame
  suredge=edge.sur-rebin(posmar,[3,n_elements(edge.sur)/3])
  suredge2=edge.sur2*rad*pdm-rebin(posmar,[3,n_elements(edge.sur)/3])
  sunedge=edge.sun
  xyziau=quaternion_rotation(xyzsep1/rmars,rebin(qrot_iau,[4,dim]),/last_ind)
  suriau=quaternion_rotation(suredge2/rmars,rebin(qrot_iau,[4,n_elements(suredge)/3]),/last_ind)
  teriau=quaternion_rotation(sunedge,rebin(qrot_iau,[4,n_elements(suredge)/3]),/last_ind)
  suniau=quaternion_rotation(mvn_sep_fov.pos.sun,qrot_iau,/last_ind)
  mvniau=quaternion_rotation(-pos,qrot_iau,/last_ind)

  mvn_sep_fov_mars_mapper,xyziau,phifov,thetafov
  mvn_sep_fov_mars_mapper,suriau,phisur,thetasur
  mvn_sep_fov_mars_mapper,teriau,phiter,thetater
  mvn_sep_fov_mars_mapper,suniau,phisun,thetasun
  mvn_sep_fov_mars_mapper,mvniau,phimvn,thetamvn

  p=getwindows('mvn_sep_fov_mars_plot')
  if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_fov_mars_plot')
  if ~keyword_set(overplot) then begin
    p.erase
    p=plot([0],/nodat,/aspect_ratio,xrange=[0,360],yrange=[-90,90],xtickinterval=30.,ytickinterval=15.,xminor=5.,yminor=2.,xtitle='East Longitude (degrees)',ytitle='Latitude (degrees)',/current)
  endif
  if keyword_set(sun) then p=plot([phisun,phisun],[thetasun,thetasun],/o,name='Sun',sym_color='orange',sym='o',/sym_filled,' ')
  if keyword_set(mvn) then p=plot([phimvn,phimvn],[thetamvn,thetamvn],/o,name='MVN',sym_color='b',sym='x',/sym_filled,' ')
  if n_elements(magnitude) ne 0 then begin
    range=[1.5,3.5]
    crscaled=bytscl(alog10(magnitude),min=range[0],max=range[1])
    crscaled=rebin([crscaled],dim)
    rgb=33
    p=colorbar(rgb=rgb,range=range,title='log10[SEP Count Rate (Hz)]',position=[0.4,.93,0.7,.97])
  endif
  wnan=where(finite(phifov),/null,nwnan)
  if nwnan gt 0 then p=scatterplot(phifov[wnan],thetafov[wnan],magnitude=crscaled[wnan],sym='.',/o,rgb=rgb)
  p=plot(phisur,thetasur,'.',/o)
  p=plot(phiter,thetater,'r.',/o)

end