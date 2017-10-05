;+
;PROCEDURE:	thm_load_esa_cal
;PURPOSE:	
;	Loads ESA time varying relative efficiency into common tha_esa_cal for use by get_thm_esa_cal()
;INPUT:		
;
;KEYWORDS:
;	file:		string, strarr	the complete path and filename to the raw pkt files
;					if not set, uses timerange to select files
;	themishome:	string		path to data dir, where data dir contains the th* dir, where *=a,b,c,d,e
;
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  07/10/19
;MOD HISTORY:
;
;NOTES:	  
;	
;-

pro thm_load_esa_cal,file=file,themishome=themishome

	if not keyword_set(themishome) then themishome=!themis.local_data_dir

; set default
	common tha_esa_cal,esa_cal_time,esa_cal_gf
	esa_cal_time=time_double(['07-01-01','17-01-01'])
	rel_gf=fltarr(6,2,2) & rel_gf[*,*,*]=1.0
	esa_cal_gf=rel_gf


; get filenames if file keyword not set
	if not keyword_set(file) then begin
		dir='tha/l1/esa/0000/' 
		name='tha_l1_esa_cal.txt'
		file=themishome+dir+name
		relpathnames=dir+name
	    	files = spd_download(remote_file=relpathnames, _extra=!themis)
		dprint, dlevel=2, 'Download ESA Cal file: ',files
	endif

; check that file exists
	if not file_test(file) then begin
		dprint, file+' --- does not exist.'
		return 
	endif


; get the files
; esa_cal_gf(sc,ion,nfits)

	openr,fp,file,/get_lun
	fs = fstat(fp)
	dprint,dlevel=4,fs
	tstr='2007-03-01/00:00' & gf=fltarr(12) 
	if fs.size ne 0 then begin
		readf,fp,tstr
		readf,fp,gf
		nfits = 1
		time=time_double(tstr) & rel_gf=gf
		fs=fstat(fp)
;			dprint,dlevel=1,fs.cur_ptr,fs.size
		while fs.cur_ptr lt fs.size do begin
			readf,fp,tstr
			readf,fp,gf
			nfits = nfits+1
			time=[time,time_double(tstr)] & rel_gf=[rel_gf,gf] 
			fs=fstat(fp)
;			dprint,dlevel=1,fs.cur_ptr,fs.size
		endwhile
		free_lun,fp
		rel_gf=reform(rel_gf,6,2,nfits)
		common tha_esa_cal,esa_cal_time,esa_cal_gf & esa_cal_time=time & esa_cal_gf=rel_gf
	endif

end
