;Do not use /LATESTVERSION. It works fine, but I would rather
;/disks/data/fast/calibration/fastconfig be updated with the latest version
;number instead.

;input trange=[starttime,endtime] and this routine will download and load
;all daily files between starttime and endtime, including starttime but not
;including endtime

pro istp_fa_k0_load,types,trange=trange, $
orbitrange=orbitrange,latestversion=latestversion,$
downloadonly=downloadonly,no_download=no_download,no_update=no_uptate

istp_init
source = !istp
if(keyword_set(no_download)) then source.no_download=1
if(keyword_set(no_update)) then source.no_update=1

;local_dir = root_data_dir() + 'fast/' ; '/data/fast/
;remote_dir = 'http://cdaweb.gsfc.nasa.gov/data/fast/'

if not keyword_set(types) then types = ['ees','ies']

if keyword_set(orbitrange) AND NOT keyword_set(trange) then begin
orbitsarray=fa_orbit_to_time(orbitrange)
maxtime=max(orbitsarray[2,*])
mintime=min(orbitsarray[1,*])
trange=[mintime,maxtime]
endif

for i=0,n_elements(types)-1 do begin

    if NOT keyword_set(latestversion) then begin
    type = types[i]
    relpath = type+'/'
    prefix = 'fa_k0_'+type+'_'
    ending = '_v'+fa_config('version','K0_istp')+'.cdf'
    relpathnames = file_dailynames(relpath,prefix,ending,/YEARDIR,trange=trange)

    remote_path = source.remote_data_dir+'fast/esa/k0/'
    local_path = source.local_data_dir+'fast/'
    filenames = spd_download(remote_file=relpathnames, remote_path=remote_path, $
                             local_path = local_path, no_download = source.no_download, $
                             no_update = source.no_update, $
                             file_mode = '666'o, dir_mode = '777'o)
;    filenames = file_retrieve(relpathnames,_extra=source)
    endif else begin
      type = types[i]
      relpath = 'fast/'+type+'/'
      prefix = 'fa_k0_'+type+'_'
      relpathnames = file_dailynames(relpath,prefix,/YEARDIR,trange=trange)
      nfiles=n_elements(relpathnames)
      filenames=strarr(nfiles)
      maxversion=2
      minversion=1
      for j=0,nfiles-1 do begin
        for k=maxversion,minversion,-1 do begin
          
          ;valid=1
          if k GE 10 then ending='_v'+strcompress(k,/remove_all)+'.cdf'
          if k LT 10 then ending='_v0'+strcompress(k,/remove_all)+'.cdf'
          ;filesteal,'http://cdaweb.gsfc.nasa.gov/istp_public/data/'+ $
          ;  relpathnames[j]+ending,valid=valid,/nodownload
          ;if valid EQ 0 then continue
          ;if valid EQ 1 then begin
          ;  filenames[j]=file_retrieve(relpathnames[j]+ending,_extra=source)
          ;  break
          ;endif
          
          remote_path = source.remote_data_dir+'fast/esa/k0/'
          local_path = local_data_dir+'fast/'
          filenames[j] = spd_download(remote_file=relpathnames[j], remote_path=remote_path, $
                                      local_path = local_path, no_download = source.no_download, $
                                      no_update = source.no_update, $
                                      file_mode = '666'o, dir_mode = '777'o)
;          filenames[j]=file_retrieve(relpathnames[j]+ending,_extra=source)
          if file_test(filenames[j]) then break
          
        endfor
      endfor
    endelse
     
stop
     if keyword_set(downloadonly) then continue
     ;cdf2tplot,file=files,all=all,verbose=verbose ,prefix = 'istp_fa_'    
     ; load data into tplot variables
     ;call_procedure,'load_fa_k0_'+type,filenames=filenames
     
if  type EQ 'ees' then begin
   
var=['el_0','el_90','el_180','el_low','el_high','JEe','Je']
dvar=['el_en','el_en','el_en','el_low_pa','el_high_pa','','']
	
nvar=dimen1(var)

nfiles = dimen1(filenames)
	for d=0,nfiles-1 do begin
		print,'Loading file: ',filenames(d),'...'
		cdf_load_ptr,filenames(d),'TIME',data=tmp,valid=cdf_valid
		if cdf_valid EQ 0 then $
		   cdf_load_ptr,filenames(d),'unix_time',data=tmp,valid=cdf_valid
		if cdf_valid EQ 0 then begin
			print,'ERROR: cdf structure element for time is missing!'
			nodata=1
			return
		endif
		if d eq 0 then begin
			time=tmp 
		endif else begin
			ntime=dimen1(time)
			gaptime1=2.*time(ntime-1) - time(ntime-2)
			gaptime2=2*tmp(0) - tmp(1)
			time=[time,gaptime1,gaptime2,tmp]
		endelse
	endfor

for n=0,nvar-1 do begin

	for d=0,nfiles-1 do begin
		cdf_load_ptr,filenames(d),var(n),data=tmp
		if dvar(n) ne '' then cdf_load_ptr,filenames(d),dvar(n),data=tmpv
		if d eq 0 then begin
			tmp_tot  = tmp
			if dvar(n) ne '' then tmpv_tot = tmpv
		endif else begin
			gapdata=tmp_tot(0:1,*)
			gapdata(*,*)=!values.f_nan
			tmp_tot  = [tmp_tot,gapdata,tmp]
			if dvar(n) ne '' then tmpv_tot = [tmpv_tot,gapdata,tmpv]
		endelse
	endfor

	if dvar(n) ne '' then begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot,v:tmpv_tot}
		options,var(n),'spec',1	
		options,var(n),'panel_size',2
		zlim,var(n),1e6,1e9,1
		options,var(n),'ztitle','eV/cm!U2!N-s-sr-eV'
		if var(n) eq 'el_low' or var(n) eq 'el_high' then begin
			ylim,var(n),-100,280,0
			if var(n) eq 'el_low' then begin
				options,var(n),'ytitle','e- .1-1 keV!C!C Pitch Angle'
			endif else begin
				options,var(n),'ytitle','e- >1 keV!C!C Pitch Angle'
			endelse
		endif else begin
			ylim,var(n),3,40000,1
			if var(n) eq 'el_0' then begin
				options,var(n),'ytitle','e- 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
			endif else begin
			if var(n) eq 'el_90' then begin
				options,var(n),'ytitle','e- 60!Uo!N-120!Uo!N!C!CEnergy (eV)'
			endif else begin
				options,var(n),'ytitle','e- 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
			endelse
			endelse
		endelse
		options,var(n),'x_no_interp',1
		options,var(n),'y_no_interp',1
	endif else begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
		if var(n) eq 'JEe' then begin
			ylim,'JEe',.001,100,1
			options,'JEe','ytitle','e-!C!Cergs/cm!U2!N-s'
			options,'JEe','tplot_routine','pmplot'
		endif else begin
			ylim,'Je',1.e6,1.e10,1
			options,'Je','ytitle','e-!C!C1/cm!U2!N-s'
			options,'Je','tplot_routine','pmplot'
		endelse
	endelse

endfor

; Label 'JEe' and 'Je' plots and check version number
	ver=0
		options,'Je','labflag',1
		options,'JEe','labflag',1
		options,'Je','labels',['','']
		options,'JEe','labels',['','']
	for d=0,nfiles-1 do begin
		lastver=ver
		pos=strpos(filenames(d),'.cdf')
		ver=fix(strmid(filenames(d),pos-2,2))
		if ver ne lastver and lastver ne 0 then begin
			print,'Error: Incompatible versions of cdf files being appended!!!'
			options,'Je','labels',['','Incompatible!C  Versions!C  Appended']
			options,'JEe','labels',['','Incompatible!C  Versions!C  Appended']
			ver=-1
		endif
	endfor
	if ver ge 2 then begin
		options,'Je','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'Je','labflag',3
		options,'Je','labpos',[3.e9,6.e8]
		options,'JEe','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'JEe','labflag',3
		options,'JEe','labpos',[30.,4.]
	endif
	if ver ge 3 then begin
			options,'JEe','ytitle','e- >25eV!C!Cergs/cm!U2!N-s'
			options,'Je','ytitle','e- >25eV!C!C1/cm!U2!N-s'
	endif
    
    ; Get the orbit data
         
		 get_data,'el_0',data=tmp
		 starttime=tmp.x[0]
		 endtime=tmp.x[n_elements(tmp.x)-1]
		 if starttime GT 1.2410834e+009 then starttime=1.2410834e+009
		 if endtime GT 1.2410834e+009 then endtime=1.2410834e+009
		 startorbit=fa_time_to_orbit(starttime)
		 endorbit=fa_time_to_orbit(endtime)
		 fa_k0_load, 'orb',orbitrange=[startorbit,endorbit]
        
; Get modebar data if it exists

;	mbar4particles,orbit=orbit

; Zero the time range

	tplot_options,trange=[0,0]

endif

   if type EQ 'ies' then begin

var=['ion_0','ion_90','ion_180','ion_low','ion_high','JEi','Ji']
dvar=['ion_en','ion_en','ion_en','ion_low_pa','ion_high_pa','','']

nvar=dimen1(var)

nfiles = dimen1(filenames)
	for d=0,nfiles-1 do begin
		print,'Loading file: ',filenames(d),'...'
		cdf_load_ptr,filenames(d),'TIME',data=tmp,valid=cdf_valid
		if cdf_valid EQ 0 then $
		   cdf_load_ptr,filenames(d),'unix_time',data=tmp,valid=valid
		if cdf_valid EQ 0 then begin
			print,'ERROR: cdf structure element for time is missing!'
			return
		endif
		if d eq 0 then begin
			time=tmp 
		endif else begin
			ntime=dimen1(time)
			gaptime1=2.*time(ntime-1) - time(ntime-2)
			gaptime2=2*tmp(0) - tmp(1)
			time=[time,gaptime1,gaptime2,tmp]
		endelse
	endfor

for n=0,nvar-1 do begin

	for d=0,nfiles-1 do begin
		cdf_load_ptr,filenames(d),var(n),data=tmp
		if dvar(n) ne '' then cdf_load_ptr,filenames(d),dvar(n),data=tmpv
		if d eq 0 then begin
			tmp_tot  = tmp
			if dvar(n) ne '' then tmpv_tot = tmpv
		endif else begin
			gapdata=tmp_tot(0:1,*)
			gapdata(*,*)=!values.f_nan
			tmp_tot  = [tmp_tot,gapdata,tmp]
			if dvar(n) ne '' then tmpv_tot = [tmpv_tot,gapdata,tmpv]
		endelse
	endfor

	if dvar(n) ne '' then begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot,v:tmpv_tot}
		options,var(n),'spec',1	
		options,var(n),'panel_size',2
		zlim,var(n),1e4,1e8,1
		options,var(n),'ztitle','eV/cm!U2!N-s-sr-eV'
		if var(n) eq 'ion_low' or var(n) eq 'ion_high' then begin
			ylim,var(n),-100,280,0
			if var(n) eq 'ion_low' then begin
				options,var(n),'ytitle','ions .05-1 keV!C!C Pitch Angle'
			endif else begin
				options,var(n),'ytitle','ions >1 keV!C!C Pitch Angle'
			endelse
		endif else begin
			ylim,var(n),3,40000,1
			if var(n) eq 'ion_0' then begin
				options,var(n),'ytitle','ions 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
			endif else begin
			if var(n) eq 'ion_90' then begin
				options,var(n),'ytitle','ions 40!Uo!N-140!Uo!N!C!CEnergy (eV)'
			endif else begin
				options,var(n),'ytitle','ions 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
			endelse
			endelse
		endelse
		options,var(n),'x_no_interp',1
		options,var(n),'y_no_interp',1
	endif else begin
		store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
		if var(n) eq 'JEi' then begin
			ylim,'JEi',1.e-5,1,1
			options,'JEi','ytitle','ions!C!Cergs/cm!U2!N-s'
			options,'JEi','tplot_routine','pmplot'
		endif else begin
			ylim,'Ji',1.e5,1.e9,1
			options,'Ji','ytitle','ions!C!C1/cm!U2!N-s'
			options,'Ji','tplot_routine','pmplot'
		endelse
	endelse

endfor

; Label 'JEi' and 'Ji' plots and check version number
	ver=0
		options,'Ji','labflag',1
		options,'JEi','labflag',1
		options,'Ji','labels',['','']
		options,'JEi','labels',['','']
	for d=0,nfiles-1 do begin
		lastver=ver
		pos=strpos(filenames(d),'.cdf')
		ver=fix(strmid(filenames(d),pos-2,2))
		if ver ne lastver and lastver ne 0 then begin
			print,'Error: Incompatible versions of cdf files being appended!!!'
			options,'Ji','labels',['','Incompatible!C  Versions!C  Appended']
			options,'JEi','labels',['','Incompatible!C  Versions!C  Appended']
			ver=-1
		endif
	endfor
	if ver ge 2 then begin
		options,'Ji','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'Ji','labflag',3
		options,'Ji','labpos',[3.e8,6.e7]
		options,'JEi','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
		options,'JEi','labflag',3
		options,'JEi','labpos',[.30,.04]
	endif
	if ver ge 3 then begin
			options,'JEi','ytitle','i+ >20eV!C!Cergs/cm!U2!N-s'
			options,'Ji','ytitle','i+ >20eV!C!C1/cm!U2!N-s'
	endif
    
    ; Get the orbit data
         
		 get_data,'ion_0',data=tmp
		 starttime=tmp.x[0]
		 endtime=tmp.x[n_elements(tmp.x)-1]
		 if starttime GT 1.2410834e+009 then starttime=1.2410834e+009
		 if endtime GT 1.2410834e+009 then endtime=1.2410834e+009
		 startorbit=fa_time_to_orbit(starttime)
		 endorbit=fa_time_to_orbit(endtime)
		 fa_k0_orb_load,orbit=[startorbit,endorbit]

; Zero the time range

	tplot_options,trange=[0,0]

endif
     
endfor

end
