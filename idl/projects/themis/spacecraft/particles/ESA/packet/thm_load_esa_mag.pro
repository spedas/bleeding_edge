;+
;PROCEDURE:	thm_load_esa_mag
;PURPOSE:	
;	Add magnetometer data to the ESA structures
;INPUT:		
;
;KEYWORDS:
;	probe:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;	sc:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;	themishome:	string		path to data dir, where data dir contains the th* dir, where *=a,b,c,d,e
;	datatype	string or 0/1	if not set, uses fgs
;					if set to 1, uses fgl
;					if string, uses string data type
;					fgl and fge data averaged by "time_average" with resolution=2s before interpolation 
;					all mag data are interpolated to center of esa data collection
;
;CREATED BY:	J. McFadden	07/05/27
;VERSION:	1
;LAST MODIFICATION:  08/04/16
;MOD HISTORY:
;				08/04/16	added probe keyword
;				09/04/29	changed from time_average to smooth_in_time
;
;NOTES:	  
;	
;-

pro thm_load_esa_mag,sc=sc,probe=probe,themishome=themishome,datatype=datatype

; sc default
	if keyword_set(probe) then sc=probe
	if not keyword_set(sc) then begin
		dprint, 'S/C number not set, default = all probes'
		sc=['a','b','c','d','e','f']
	endif

	if not keyword_set(themishome) then themishome=!themis.local_data_dir

nsc = n_elements(sc)
probes=strarr(1)
if nsc eq 1 then probes(0)=sc
if nsc ne 1 then probes=sc

;***********************************************************************************
; get magnetometer data

for i=0,nsc-1 do begin

	if not keyword_set(datatype) then begin
		thm_load_fit,level=1,probe=probes(i),datatype='fgs'
		get_data,'th'+probes(i)+'_fgs',data=tmp
	endif else if string(datatype) eq 'fgs' then begin
		thm_load_fit,level=1,probe=probes(i),datatype='fgs'
		get_data,'th'+probes(i)+'_fgs',data=tmp
	endif else if string(datatype) eq 'fge' then begin
		thm_load_fgm,level=1,probe=probes(i)
		get_data,'th'+probes(i)+'_fge',data=tmp1
;		fge=time_average(tmp1.x,tmp1.y,resolution=2.,newtime=newtime)
		fge=smooth_in_time(tmp1.y,tmp1.x,2.)
;		store_data,'th'+probes(i)+'_fge_2s',data={x:newtime,y:fge}
		store_data,'th'+probes(i)+'_fge_2s',data={x:tmp1.x,y:fge}
		get_data,'th'+probes(i)+'_fge_2s',data=tmp	
	endif else begin
		thm_load_fgm,level=1,probe=probes(i)
		get_data,'th'+probes(i)+'_fgl',data=tmp1
;		fgl=time_average(tmp1.x,tmp1.y,resolution=2.,newtime=newtime)
		fgl=smooth_in_time(tmp1.y,tmp1.x,2.)
;		store_data,'th'+probes(i)+'_fgl_2s',data={x:newtime,y:fgl}
		store_data,'th'+probes(i)+'_fgl_2s',data={x:tmp1.x,y:fgl}
		get_data,'th'+probes(i)+'_fgl_2s',data=tmp
	endelse

	if probes(i) eq 'a' then begin
		common tha_454,tha_454_ind,tha_454_dat 
		if n_elements(tha_454_dat) ne 0 then begin
		  if tha_454_ind ne -1 then begin
			time=(tha_454_dat.time+tha_454_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			tha_454_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common tha_455,tha_455_ind,tha_455_dat 
		if n_elements(tha_455_dat) ne 0 then begin
		  if tha_455_ind ne -1 then begin
			time=(tha_455_dat.time+tha_455_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			tha_455_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common tha_456,tha_456_ind,tha_456_dat 
		if n_elements(tha_456_dat) ne 0 then begin
		  if tha_456_ind ne -1 then begin
			time=(tha_456_dat.time+tha_456_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			tha_456_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common tha_457,tha_457_ind,tha_457_dat 
		if n_elements(tha_457_dat) ne 0 then begin
		  if tha_457_ind ne -1 then begin
			time=(tha_457_dat.time+tha_457_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			tha_457_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common tha_458,tha_458_ind,tha_458_dat 
		if n_elements(tha_458_dat) ne 0 then begin
		  if tha_458_ind ne -1 then begin
			time=(tha_458_dat.time+tha_458_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			tha_458_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common tha_459,tha_459_ind,tha_459_dat 
		if n_elements(tha_459_dat) ne 0 then begin
		  if tha_459_ind ne -1 then begin
			time=(tha_459_dat.time+tha_459_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			tha_459_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
	endif else if probes(i) eq 'b' then begin
		common thb_454,thb_454_ind,thb_454_dat 
		if n_elements(thb_454_dat) ne 0 then begin
		  if thb_454_ind ne -1 then begin
			time=(thb_454_dat.time+thb_454_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thb_454_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thb_455,thb_455_ind,thb_455_dat 
		if n_elements(thb_455_dat) ne 0 then begin
		  if thb_455_ind ne -1 then begin
			time=(thb_455_dat.time+thb_455_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thb_455_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thb_456,thb_456_ind,thb_456_dat 
		if n_elements(thb_456_dat) ne 0 then begin
		  if thb_456_ind ne -1 then begin
			time=(thb_456_dat.time+thb_456_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thb_456_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thb_457,thb_457_ind,thb_457_dat 
		if n_elements(thb_457_dat) ne 0 then begin
		  if thb_457_ind ne -1 then begin
			time=(thb_457_dat.time+thb_457_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thb_457_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thb_458,thb_458_ind,thb_458_dat 
		if n_elements(thb_458_dat) ne 0 then begin
		  if thb_458_ind ne -1 then begin
			time=(thb_458_dat.time+thb_458_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thb_458_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thb_459,thb_459_ind,thb_459_dat 
		if n_elements(thb_459_dat) ne 0 then begin
		  if thb_459_ind ne -1 then begin
			time=(thb_459_dat.time+thb_459_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thb_459_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
	endif else if probes(i) eq 'c' then begin
		common thc_454,thc_454_ind,thc_454_dat 
		if n_elements(thc_454_dat) ne 0 then begin
		  if thc_454_ind ne -1 then begin
			time=(thc_454_dat.time+thc_454_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thc_454_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thc_455,thc_455_ind,thc_455_dat 
		if n_elements(thc_455_dat) ne 0 then begin
		  if thc_455_ind ne -1 then begin
			time=(thc_455_dat.time+thc_455_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thc_455_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thc_456,thc_456_ind,thc_456_dat 
		if n_elements(thc_456_dat) ne 0 then begin
		  if thc_456_ind ne -1 then begin
			time=(thc_456_dat.time+thc_456_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thc_456_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thc_457,thc_457_ind,thc_457_dat 
		if n_elements(thc_457_dat) ne 0 then begin
		  if thc_457_ind ne -1 then begin
			time=(thc_457_dat.time+thc_457_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thc_457_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thc_458,thc_458_ind,thc_458_dat 
		if n_elements(thc_458_dat) ne 0 then begin
		  if thc_458_ind ne -1 then begin
			time=(thc_458_dat.time+thc_458_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thc_458_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thc_459,thc_459_ind,thc_459_dat 
		if n_elements(thc_459_dat) ne 0 then begin
		  if thc_459_ind ne -1 then begin
			time=(thc_459_dat.time+thc_459_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thc_459_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
	endif else if probes(i) eq 'd' then begin
		common thd_454,thd_454_ind,thd_454_dat 
		if n_elements(thd_454_dat) ne 0 then begin
		  if thd_454_ind ne -1 then begin
			time=(thd_454_dat.time+thd_454_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thd_454_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thd_455,thd_455_ind,thd_455_dat 
		if n_elements(thd_455_dat) ne 0 then begin
		  if thd_455_ind ne -1 then begin
			time=(thd_455_dat.time+thd_455_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thd_455_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thd_456,thd_456_ind,thd_456_dat 
		if n_elements(thd_456_dat) ne 0 then begin
		  if thd_456_ind ne -1 then begin
			time=(thd_456_dat.time+thd_456_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thd_456_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thd_457,thd_457_ind,thd_457_dat 
		if n_elements(thd_457_dat) ne 0 then begin
		  if thd_457_ind ne -1 then begin
			time=(thd_457_dat.time+thd_457_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thd_457_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thd_458,thd_458_ind,thd_458_dat 
		if n_elements(thd_458_dat) ne 0 then begin
		  if thd_458_ind ne -1 then begin
			time=(thd_458_dat.time+thd_458_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thd_458_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common thd_459,thd_459_ind,thd_459_dat 
		if n_elements(thd_459_dat) ne 0 then begin
		  if thd_459_ind ne -1 then begin
			time=(thd_459_dat.time+thd_459_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			thd_459_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
	endif else if probes(i) eq 'e' then begin
		common the_454,the_454_ind,the_454_dat 
		if n_elements(the_454_dat) ne 0 then begin
		  if the_454_ind ne -1 then begin
			time=(the_454_dat.time+the_454_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			the_454_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common the_455,the_455_ind,the_455_dat 
		if n_elements(the_455_dat) ne 0 then begin
		  if the_455_ind ne -1 then begin
			time=(the_455_dat.time+the_455_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			the_455_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common the_456,the_456_ind,the_456_dat 
		if n_elements(the_456_dat) ne 0 then begin
		  if the_456_ind ne -1 then begin
			time=(the_456_dat.time+the_456_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			the_456_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common the_457,the_457_ind,the_457_dat 
		if n_elements(the_457_dat) ne 0 then begin
		  if the_457_ind ne -1 then begin
			time=(the_457_dat.time+the_457_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			the_457_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common the_458,the_458_ind,the_458_dat 
		if n_elements(the_458_dat) ne 0 then begin
		  if the_458_ind ne -1 then begin
			time=(the_458_dat.time+the_458_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			the_458_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
		common the_459,the_459_ind,the_459_dat 
		if n_elements(the_459_dat) ne 0 then begin
		  if the_459_ind ne -1 then begin
			time=(the_459_dat.time+the_459_dat.end_time)/2.
			magf0 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,0),tmp.x,time)
			magf1 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,1),tmp.x,time)
			magf2 = interp(/no_extrapolate,interp_threshold=5.1,tmp.y(*,2),tmp.x,time)
			the_459_dat.magf=[[magf0],[magf1],[magf2]]
		  endif
		endif
	endif

endfor
end
