;+
;Function:	thm_load_spinmodel(sc=sc,themishome=themishome)
;PURPOSE:	
;	Returns template for spinmodel.txt files
;INPUT:		
;		
;KEYWORDS:
;
;		sc	string		spacecraft designation: 'a','b','c','d','e'
;	themishome:	string		path to data dir, where data dir contains the th* dir, where *=a,b,c,d,e
;	available	0,1		if data is available, "available" is set to 1
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  07/04/02
;MOD HISTORY:
;
;NOTES:	  
;	Used by thm_load_***.pro where ***=ief,ieb,ier,eef,eeb,eer.
;-

FUNCTION thm_load_spinmodel,sc=sc,themishome=themishome,available=available

; limit the valid spin period range
	sp_lim=[2.0,5.0]

; sc default
	available=0
	if not keyword_set(sc) then begin
		dprint, 'No spacecraft selected, No spinmodel data returned   th'+sc
		return,-1
	endif
	if sc ne 'a' and sc ne 'b' and sc ne 'c' and sc ne 'd' and sc ne 'e' then begin
		dprint, 'No spacecraft selected, No spinmodel data returned   th'+sc
		return,-1
	endif
	if not keyword_set(themishome) then themishome=!themis.local_data_dir

; download files

	tt=timerange()
	t1=time_double(strmid(time_string(tt(0)),0,10))
	t_1=t1
	t2=time_double(strmid(time_string(tt(1)-1.),0,10))
	ndays=1+fix((t2-t1)/(24.*3600.))
	spinpathnames=strarr(ndays)
	i=0
	while t1 le t2 do begin
		ts=time_string(t1) 
		yr=strmid(ts,0,4) & mo=strmid(ts,5,2) & da=strmid(ts,8,2)
		dir='th'+sc+'/l1/tmpfiles/th'+sc+'_'+yr+mo+da+'/' 
		spinpathnames[i]=dir+'spinmodel.txt'
		i=i+1
		t1=t1+24.*3600.
	endwhile

   	files = spd_download(remote_file=spinpathnames, _extra=!themis)

; extract spin data

	t1=t_1
	spinfile=strarr(ndays)
	i=0
	while t1 le t2 do begin
		ts=time_string(t1)
		yr=strmid(ts,0,4) & mo=strmid(ts,5,2) & da=strmid(ts,8,2)

		spinfile[i]=themishome+'th'+sc+'/l1/tmpfiles/th'+sc+'_'+yr+mo+da+'/spinmodel.txt'
		i=i+1
		t1=t1+24.*3600.
	endwhile

; check that files exist
	nfiles=n_elements(spinfile)
	if nfiles eq 1 then begin
		if not file_test(spinfile) then begin
			dprint, spinfile +' --- does not exist.'
			return,-1
		endif
	endif else begin 
		ind=-1
		for i=0,nfiles-1 do begin
			if file_test(spinfile[i]) then ind=[ind,i] else dprint, spinfile[i]+' --- does not exist.'
		endfor
		n_ind=n_elements(ind)
		if n_ind eq 1 then begin
			return,-1
		endif else begin
			ind=ind[1:n_ind-1]
			spinfile=spinfile[ind]
		endelse 
	endelse	

; initialized arrays

	spindata=-1
	nfits=0
	t1=0d & t2=0d & s1=0l & s2=0l & sp=0d & me=0d

; get the files

	if n_elements(spinfile) eq 1 then openr,fp,spinfile,/get_lun else openr,fp,spinfile[0],/get_lun
	fs = fstat(fp)
;	help,fs,/st
	if fs.size ne 0 then begin
		readf,fp,t1,t2,s1,s2,sp,me
		nfits = 1
		tt1=t1 & tt2=t2 & ss1=s1 & ss2=s2 & spn=sp & mer=me
		fs=fstat(fp)
;			dprint,dlevel=1,fs.cur_ptr,fs.size
		while fs.cur_ptr lt fs.size do begin
			readf,fp,t1,t2,s1,s2,sp,me
			nfits = nfits+1
			tt1=[tt1,t1] & tt2=[tt2,t2] & ss1=[ss1,s1] & ss2=[ss2,s2] & spn=[spn,sp] & mer=[mer,me]
			fs=fstat(fp)
;			dprint,dlevel=1,fs.cur_ptr,fs.size
		endwhile
		free_lun,fp
	endif

	if n_elements(spinfile) ne 1 then begin
		nfile=n_elements(spinfile)
		for i=1,nfile-1 do begin
			openr,fp,spinfile[i],/get_lun
			fs = fstat(fp)
			if fs.size ne 0 then begin
				readf,fp,t1,t2,s1,s2,sp,me
				if nfits eq 0 then begin
					nfits=1 & tt1=t1 & tt2=t2 & ss1=s1 & ss2=s2 & spn=sp & mer=me
				endif else begin
					nfits = nfits+1
					tt1=[tt1,t1] & tt2=[tt2,t2] & ss1=[ss1,s1] & ss2=[ss2,s2] & spn=[spn,sp] & mer=[mer,me]
				endelse
				fs=fstat(fp)
				while fs.cur_ptr lt fs.size do begin
					readf,fp,t1,t2,s1,s2,sp,me
					nfits = nfits+1
					tt1=[tt1,t1] & tt2=[tt2,t2] & ss1=[ss1,s1] & ss2=[ss2,s2] & spn=[spn,sp] & mer=[mer,me]
					fs=fstat(fp)
				endwhile
			endif
			free_lun,fp
		endfor
	endif


if nfits gt 1 then begin
	; remove bad spin data - these line aren't needed if Lewis fixes his code
		ind=where(spn gt sp_lim(0) and spn lt sp_lim(1),count)
		bad_ind=where(spn le sp_lim(0) or spn ge sp_lim(1))
		if count eq 0 then return,-1
		if count ne n_elements(spn) then begin
			t0=time_double('2001-1-1/0')
			dprint,dlevel=1,'Error: Spin periods outside range ',sp_lim(0),' to ',sp_lim(1),' thrown out!!!!'
			dprint,dlevel=1,time_string(tt1(bad_ind)+t0)
			dprint,dlevel=1,spn(bad_ind)
			tt1=tt1(ind) & tt2=tt2(ind)
			ss1=ss1(ind) & ss2=ss2(ind)
			spn=spn(ind) & mer=mer(ind)
		endif
	spindata={s_time:tt1,e_time:tt2,s_spin:ss1,e_spin:ss2,spin_period:spn,merit:mer}
	available=1
endif

return,spindata

end
