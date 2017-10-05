;+
;PROCEDURE:	thm_make_esa_mag
;PURPOSE:	
;	Make a tplot structure out of ESA magnetometer data
;INPUT:		
;
;KEYWORDS:
;	probe:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;	sc:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;	themishome:	string		path to data dir, where data dir contains the th* dir, where *=a,b,c,d,e
;
;CREATED BY:	J. McFadden	08/12/07
;VERSION:	1
;LAST MODIFICATION:  08/12/07
;MOD HISTORY:
;			
;
;NOTES:	  
;	
;-

pro thm_make_esa_mag,sc=sc,probe=probe,themishome=themishome

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
; store magnetometer data

for i=0,nsc-1 do begin

	if probes(i) eq 'a' then begin
		common tha_455,tha_455_ind,tha_455_dat 
		if n_elements(tha_455_dat) ne 0 then store_data,'tha_peir_fgm',data={x:tha_455_dat.time,y:tha_455_dat.magf}
		common tha_458,tha_458_ind,tha_458_dat 
		if n_elements(tha_458_dat) ne 0 then store_data,'tha_peer_fgm',data={x:tha_458_dat.time,y:tha_458_dat.magf}
	endif else if probes(i) eq 'b' then begin
		common thb_455,thb_455_ind,thb_455_dat 
		if n_elements(thb_455_dat) ne 0 then store_data,'thb_peir_fgm',data={x:thb_455_dat.time,y:thb_455_dat.magf}
		common thb_458,thb_458_ind,thb_458_dat 
		if n_elements(thb_458_dat) ne 0 then store_data,'thb_peer_fgm',data={x:thb_458_dat.time,y:thb_458_dat.magf}
	endif else if probes(i) eq 'c' then begin
		common thc_455,thc_455_ind,thc_455_dat 
		if n_elements(thc_455_dat) ne 0 then store_data,'thc_peir_fgm',data={x:thc_455_dat.time,y:thc_455_dat.magf}
		common thc_458,thc_458_ind,thc_458_dat 
		if n_elements(thc_458_dat) ne 0 then store_data,'thc_peer_fgm',data={x:thc_458_dat.time,y:thc_458_dat.magf}
	endif else if probes(i) eq 'd' then begin
		common thd_455,thd_455_ind,thd_455_dat 
		if n_elements(thd_455_dat) ne 0 then store_data,'thd_peir_fgm',data={x:thd_455_dat.time,y:thd_455_dat.magf}
		common thd_458,thd_458_ind,thd_458_dat 
		if n_elements(thd_458_dat) ne 0 then store_data,'thd_peer_fgm',data={x:thd_458_dat.time,y:thd_458_dat.magf}
	endif else if probes(i) eq 'e' then begin
		common the_455,the_455_ind,the_455_dat 
		if n_elements(the_455_dat) ne 0 then store_data,'the_peir_fgm',data={x:the_455_dat.time,y:the_455_dat.magf}
		common the_458,the_458_ind,the_458_dat 
		if n_elements(the_458_dat) ne 0 then store_data,'the_peer_fgm',data={x:the_458_dat.time,y:the_458_dat.magf}
	endif

endfor
end
