;20171119 Ali
;making tplot variables

pro mvn_sep_elec_peri_tplot,time2,bw,energy,nsep,nfov,traj=traj,frame=frame

if keyword_set(traj) then begin
  nt=n_elements(where(finite(traj.dt)))
  traj2=traj[0:nt-1]
  time=dgen(nt,range=timerange())
  rmars=3390. ;km
  alt=sqrt(total(traj2.x^2,1))-rmars ;altitude (km)
  store_data,'mvn_sep_elec_r_'+frame+'_(km)',data={x:time,y:[[transpose(traj2.x)],[sqrt(total(traj2.x^2,1))]]},lim={colors:'bgr,',labels:['X','Y','Z','tot'],labflag:1,constant:0}
  store_data,'mvn_sep_elec_dr_'+frame+'_(km)',data={x:time,y:transpose(traj2.x-rebin(traj2[0].x,[3,nt]))},lim={colors:'bgr',labels:['X','Y','Z'],labflag:1,constant:0}
  store_data,'mvn_sep_elec_alt_(km)',data={x:time,y:alt},lim={}
  store_data,'mvn_sep_elec_v_'+frame+'_(km/s)',data={x:time,y:[[transpose(traj2.v)],[sqrt(total(traj2.v^2,1))]]},lim={colors:'bgrk',labels:['X','Y','Z','tot'],labflag:1,constant:0}
  store_data,'mvn_sep_elec_B_'+frame+'_(nT)',data={x:time,y:[[transpose(traj2.b)],[sqrt(total(traj2.b^2,1))]]},lim={colors:'bgrk',labels:['X','Y','Z','tot'],labflag:1,constant:0}
  store_data,'mvn_sep_elec_drB_(km)',data={x:time,y:[[traj2.drpara],[traj2.drperp]]},lim={colors:'br',labels:['para','perp'],labflag:1,constant:0}
  store_data,'mvn_sep_elec_dt_(s)',data={x:time,y:traj2.dt},lim={}
  store_data,'mvn_sep_elec_dtminsub',data={x:time,y:traj2.dtminsub},lim={yrange:[-1,3]}
  store_data,'mvn_sep_elec_optical_depth',data={x:time,y:traj2.od},lim={yrange:[1e-2,1e2],ylog:1}
  store_data,'mvn_sep_elec_iteration',data={x:time,y:findgen(nt)},lim={}
  tplot,'mvn_sep_elec_*'
endif else begin
lim={ylog:1,zlog:1,spec:1,ystyle:1,panel_size:.875,ytickunits:'scientific',ztickunits:'scientific'}
sepstr=['1A','1B','2A','2B']
od=bw.od
od[where(od lt 1e-2)]=1e-2 ;to preserve dynamic range
for isep=0,nsep-1 do begin ;loop over 4 seps
  store_data,'mvn_sep'+sepstr[isep]+'_alt_(km)',data={x:time2,y:mean(bw[*,*,isep,*].al,dim=4,/nan),v:energy},lim=lim,dlim={zrange:[100,1000]}
  store_data,'mvn_sep'+sepstr[isep]+'_iterations',data={x:time2,y:mean(bw[*,*,isep,*].it,dim=4,/nan),v:energy},lim=lim,dlim={zrange:[1,1e4]}
  store_data,'mvn_sep'+sepstr[isep]+'_exp_-optical_depth',data={x:time2,y:mean(exp(-od[*,*,isep,*]),dim=4,/nan),v:energy},lim=lim,dlim={zrange:[1e-3,1]}
  store_data,'mvn_sep'+sepstr[isep]+'_1/optical_depth',data={x:time2,y:1./exp(mean(alog(od[*,*,isep,*]),dim=4,/nan)),v:energy},lim=lim,dlim={zrange:[.005,100]}
  store_data,'mvn_sep'+sepstr[isep]+'_para_distance_(km)',data={x:time2,y:mean(bw[*,*,isep,*].rpara,dim=4,/nan),v:energy},lim=lim,dlim={zrange:[1,3e4]}
  store_data,'mvn_sep'+sepstr[isep]+'_perp_distance_(km)',data={x:time2,y:mean(bw[*,*,isep,*].rperp,dim=4,/nan),v:energy},lim=lim,dlim={zrange:[1,3e4]}
  store_data,'mvn_sep'+sepstr[isep]+'_final_speed_(km/s)',data={x:time2,y:mean(bw[*,*,isep,*].v1,dim=4,/nan),v:energy},lim=lim,dlim={zrange:[1e4,3e5]}
  for ifov=0,nfov-1 do begin
    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_alt_(km)',data={x:time2,y:bw[*,*,isep,ifov].al,v:energy},lim=lim,dlim={zrange:[100,1000]}
    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_iterations',data={x:time2,y:bw[*,*,isep,ifov].it,v:energy},lim=lim,dlim={zrange:[1,1e4]}
;    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_exp_-optical_depth',data={x:time2,y:exp(-od[*,*,isep,ifov]),v:energy},lim=lim,dlim={zrange:[1e-3,1]}
;    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_exp_-optical_depth',data={x:time2,y:exp(-od[*,*,isep,ifov]),v:energy},lim=lim,dlim={zrange:[1e-3,1]}
    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_1/optical_depth',data={x:time2,y:1./od[*,*,isep,ifov],v:energy},lim=lim,dlim={zrange:[.005,100]}
;    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_parallel_distance_(km)',data={x:time2,y:bw[*,*,isep,ifov].rp,v:energy},lim=lim,dlim={zrange:[1,1e4]}
;    store_data,'mvn_sep'+sepstr[isep]+'_fov'+strtrim(ifov,2)+'_final_speed_(km/s)',data={x:time2,y:bw[*,*,isep,ifov].v1,v:energy},lim=lim,dlim={zrange:[1e4,3e5]}
  endfor
endfor
tplot,'mvn_sep??_alt_(km) mvn_sep??_iterations mvn_sep??_1/optical_depth mvn_sep??_exp_-optical_depth mvn_sep??_para_distance_(km) mvn_sep??_perp_distance_(km) mvn_sep??_final_speed_(km/s)'
endelse

end