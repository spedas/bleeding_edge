; pro plot_fa_orbit
;
; Batch routines to plot Fast Orbit Parameters
;
pro plot_fa_orbit,def=def

; Get the first orbit of fast
	print,'Start of orbit 1 = 1996-08-21/11:07:22'
; Or get the current orbit
	t = systime(1)+7.*3600.
	print,'Current GMT      = ',time_to_str(t)
	tmin=t-4000
	tmax=t+4000.
	if keyword_set(def) then orbit_file='/disks/fast/almanac/orbit/definitive' else orbit_file='/disks/fast/almanac/orbit/predicted'
	get_fa_orbit,tmin,tmax,/all,orbit_file=orbit_file
	get_data,'ORBIT',data=tmp
	orbit_num=strcompress(string(tmp.y(0)),/remove_all)
	print,'Orbit number = ',orbit_num
;	Change fa_pos from km to Re 
		get_data,'fa_pos',data=tmp
		tmp.y=tmp.y/6370
		store_data,'fa_pos_re',data=tmp
;	Need to transform to GSE coordinates
		coord_trans,'fa_pos_re','fa_pos_gse','GEIGSE'
	ylim,lim,-2,2,0
	xlim,lim,-2,2,0
	zlim,lim,-2,2,0

; Plot time series of orbit parameters
	window,5,xpos=280,ypos=650,xsize=400,ysize=400
	;
	tstart=tmin
;	tstart=str_to_time('96-8-23/20:00')
	timespan,tstart,8000.,/sec
	tplot,['ILAT','MLT','LAT','ALT'],var_label=['MLT','ALT','ILAT']
; add s/c position
	get_data,'LAT',dat=lat
	ini = systime(1)+7.*3600.
	dt = min(abs(lat.x-ini),sub_ini)
	y = [lat.y(sub_ini)]
;	tplot_panel,4,deltatime=delta
	x = [lat.x(sub_ini)]
	timebar,x
;	oplot,x-delta,y,psym=4,color=120
	
; Plot x-z plot of orbit in GSE
	window,1,xpos=0,ypos=650,xsize=250,ysize=250
	;
	plot_orbit2,'fa_pos_gse',limits=lim,/xzplot
	oplot,[-2,0],[1,1],color=70
	oplot,[-2,0],[-1,-1],color=70
; add s/c position
	get_data,'fa_pos_gse',dat=pos
	ini = systime(1)+7.*3600.
	dt = min(abs(pos.x-ini),sub_ini)
	x = [pos.y(sub_ini,0)]
	y = [pos.y(sub_ini,2)]
	oplot,x,y,psym=4,color=120
; add spin axis
	t0=str_to_time('96-12-21/0:00')
	ang=(t-t0)*2*3.1416/(365.25*24.*3600.)
	tilt=22.*3.1416/180.
	xspin=[-2*sin(tilt)*cos(ang),2*sin(tilt)*cos(ang)]
	yspin=[2*cos(tilt),-2*cos(tilt)]
	oplot,xspin,yspin,color=150
	xyouts,xspin(0),yspin(0),'N',align=.5,color=150

; Plot y-z plot of orbit in GSE
	window,2,xpos=0,ypos=370,xsize=250,ysize=250
	;
	plot_orbit2,'fa_pos_gse',limits=lim,/yzplot
; add s/c position
	get_data,'fa_pos_gse',dat=pos
	ini = systime(1)+7.*3600.
	dt = min(abs(pos.x-ini),sub_ini)
	x = [pos.y(sub_ini,1)]
	y = [pos.y(sub_ini,2)]
	oplot,x,y,psym=4,color=120
; add spin axis
	t0=str_to_time('96-12-21/0:00')
	ang=(t-t0)*2*3.1416/(365.25*24.*3600.)
	tilt=22.*3.1416/180.
	xspin=[2*sin(tilt)*sin(ang),-2*sin(tilt)*sin(ang)]
	yspin=[2*cos(tilt),-2*cos(tilt)]
	oplot,xspin,yspin,color=150
	xyouts,xspin(0),yspin(0),'N',align=.5,color=150

; Plot x-y plot of orbit in GSE
	window,3,xpos=0,ypos=90,xsize=250,ysize=250
	;
	plot_orbit2,'fa_pos_gse',limits=lim
	oplot,[-2,0],[1,1],color=70
	oplot,[-2,0],[-1,-1],color=70
; add s/c position
	get_data,'fa_pos_gse',dat=pos
	ini = systime(1)+7.*3600.
	dt = min(abs(pos.x-ini),sub_ini)
	x = [pos.y(sub_ini,0)]
	y = [pos.y(sub_ini,1)]
	oplot,x,y,psym=4,color=120
; add spin axis
	t0=str_to_time('96-12-21/0:00')
	ang=(t-t0)*2*3.1416/(365.25*24.*3600.)
	tilt=22.*3.1416/180.
	yspin=[sin(tilt)*sin(ang),-sin(tilt)*sin(ang)]
	xspin=[-sin(tilt)*cos(ang),sin(tilt)*cos(ang)]
	oplot,xspin,yspin,color=150
	xyouts,xspin(0),yspin(0),'N',align=.5,color=150

; Plot ground track on map of earth
	window,4,xpos=280,ypos=0,xsize=400,ysize=300
	;
;	map_set,mol,30,-150
	map_set,cyl
	map_continents
	get_data,'LAT',data=lat
	th=lat.y
	get_data,'LNG',data=lng
	ph=lng.y
	oplot,ph,th
; add s/c position
	ini = systime(1)+7.*3600.
	dt = min(abs(lat.x-ini),sub_ini)
	th = [lat.y(sub_ini)]
	ph = [lng.y(sub_ini)]
	oplot,ph,th,psym=4,color=120

return
end
; End demo
