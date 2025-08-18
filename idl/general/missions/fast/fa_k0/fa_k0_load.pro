;+
;PURPOSE: Download FAST CDF files off themis.ssl.berkeley.edu or sprg.ssl.berkeley.edu.
;         Load FAST data into TPLOT variables.
;USAGE: fa_k0_load,TYPES,ORBITRANGE/TRANGE=[SOMETHING,SOMETHING]
;        If TYPES is not specified, ['ees','ies'] is used as default TYPES.
;		 If keywords ORBITRANGE, TRANGE, STIMES, and SORBITS
;                are not set, fa_k0_load calls timerange().
;        NOTE THAT only 'ees', 'ies', 'orb', 'tms', 'acf' data are
;        available from ssl.berkeley.edu, for FAST K0 data available
;        from NASA SPDF, use ISTP_FA_K0_LOAD.pro. Note also that the
;        ssl.berkeley.edu versions of K0 data are more recent than
;        those at SPDF.
;EXAMPLES: fa_k0_load,'ees',orbit=51314
;          fa_k0_load,'ies',orbit=51314
;          fa_k0_load,'orb',orbit=51314
;          fa_k0_load,'tms',orbit=51314
;          fa_k0_load,'acf',orbit=01314 ;acf files do not exist past 03709
;KEYWORDS: FILENAMES - String array of filenames of CDF files on local hard drive.
;          VERSION - Specify a version number for all CDF files, i.e. version='04'.
;          TRANGE - Specify time range in which FAST data will be loaded, i.e. trange=['1998-1-1/21:00','1998-1-2/4:00']
;          ORBITRANGE - Specify orbit range in which FAST data will be loaded, i.e. orbitrange=[31314,31316]
;          STIMES - Specify array of individual times to be loaded. CDF files for times in between will not be loaded.
;          SORBITS - Specify array of individual orbits to be loaded. CDF files for orbits in between will not be loaded.
;          VAR - String array of CDF variables to be loaded.
;          DVAR - String array of dependent variables to be loaded.
;          NO_OPTS - Do not set any TPLOT options or load any DVAR variables. Use CDF2TPLOT to load data.
;					 NO_OPTS does not add datagaps between orbits.
;          IGNORE_EXISTENCE - By default, no data is loaded if a file is missing.
;                             Set IGNORE_EXISTENCE to load data even if giles are missing. 
;          DOWNLOADONLY - Download CDF files but do not load into TPLOT variables.
;                         Specifying FILENAMES and using DOWNLOADONLY causes routine to do nothing.
;          NODATA - Return 0 if data from existing files was successfully loaded into TPLOT variables.
;                   Return 1 if data was not loaded (or only partially loaded) into TPLOT variables.
;BUG: Crashes on orbitrange=[5000,5001] and orbitrange=[5001,5002].
;UPDATE HISTORY: fa_k0_load obsoletes load_fa_ees.pro, load_fa_ies.pro, and fa_k0_orb_load.pro.
;				 Written by Davin Larson.
;                Heavily modified by Dillon Wong.
;                v7 May 26, 2010.
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro fa_k0_load,types, $
               datatype=datatype, $
               filenames=filenames, $
               version=version, $
               trange=trange, $
               orbitrange=orbitrange, $
               stimes=stimes, $
               sorbits=sorbits, $
               var=var, $
               dvar=dvar, $
               no_opts=no_opts, $
               ignore_existence=ignore_existence, $
               downloadonly=downloadonly, $
               nodata=nodata

fa_init
nodata=1
file_input=0
if keyword_set(var) then var_input=1 else var_input=0
if keyword_set(var) AND (n_elements(types) GT 1) then $
   print,'Warning: Multiple Types Specified'

case 1 of

	keyword_set(filenames): begin
		file_input=1
		if NOT keyword_set(types) then begin
			print,'Error: No Type Specified'
			print,'Aborting...'
			return
		endif
		if n_elements(types) NE 1 then begin
			print,'Error: Multiple Types Specified'
			print,'Enter a Type or Press Enter to Quit'
			types=''
			read,types
			if types EQ '' then begin
				print,'Quitting...'
				return
			endif
		endif
	end

	keyword_set(orbitrange): begin
		if n_elements(orbitrange) EQ 1 then begin
			orbits=strcompress(string(orbitrange[0],format='(i05)'),/remove_all)
		endif else begin
			if n_elements(orbitrange) NE 2 then begin
				print,'Error: Incorrect ORBITRANGE format'
				return
			endif
			if orbitrange[0] GT orbitrange[1] then begin
				print,'Switching orbitrange entries...'
				tmp_sto=orbitrange[0]
				orbitrange[0]=orbitrange[1]
				orbitrange[1]=tmp_sto
			endif
			orbitrange=interp(orbitrange,orbitrange[1]-orbitrange[0]+1)
			orbits=strcompress(string(orbitrange,format='(i05)'),/remove_all)
		endelse
	end

	keyword_set(trange): begin
		if n_elements(trange) EQ 1 then begin
			orbits=strcompress(string(fa_time_to_orbit(trange[0]),format='(i05)'),/remove_all)
		endif else begin
			if n_elements(trange) NE 2 then begin
				print,'Error: Incorrect TRANGE format'
				return
			endif
			orbitrange=lonarr(2)
			orbitrange[0]=fa_time_to_orbit(trange[0])
			orbitrange[1]=fa_time_to_orbit(trange[1])
			if orbitrange[0] GT orbitrange[1] then begin
				print,'Switching trange entries...'
				tmp_sto=orbitrange[0]
				orbitrange[0]=orbitrange[1]
				orbitrange[1]=tmp_sto
			endif
			orbitrange=interp(orbitrange,orbitrange[1]-orbitrange[0]+1)
			orbits=strcompress(string(orbitrange,format='(i05)'),/remove_all)
		endelse
	end
  
	keyword_set(sorbits): begin
		orbits=strcompress(string(sorbits,format='(i05)'),/remove_all)
	end
  
	keyword_set(stimes): begin
		ntimes=n_elements(stimes)
		orbits=strarr(ntimes)
		for i=0,ntimes-1 do $
		 orbits[i]=strcompress(string(fa_time_to_orbit(stimes[i]),format='(i05)'),/remove_all)
	end
  
	else: begin
		trange=timerange()
		start_orbit=long(fa_time_to_orbit(trange[0]))
		end_orbit=long(fa_time_to_orbit(trange[1]))
		orbits=indgen(end_orbit-start_orbit+1)+start_orbit
		orbits=strcompress(string(orbits,format='(i05)'),/remove_all)
	end
  
endcase

if NOT keyword_set(filenames) then orbit_dir=strmid(orbits,0,2)+'000'

if keyword_set(datatype) then types=datatype
if NOT keyword_set(types) then types=['ees','ies','orb']

for k=0,n_elements(types)-1 do begin
	
	type=strlowcase(types[k])
	
	if file_input EQ 0 then begin
		if keyword_set(version) then begin
			vxx='v'+string(version, format='(i2.2)')
		endif else begin
			vxx='v'+fa_config('version','K0_'+type,valid=vx_flag)
			if vx_flag EQ 0 then begin
				print,'Error: Type Not Known'
				print,'Using v01 as Version...'
				vxx='v01'
			endif
		endelse
		
		relpathnames = $
		 'k0/'+type+'/'+orbit_dir+'/fa_k0_'+type+'_'+orbits+'_'+vxx+'.cdf'
		
		filenames = file_retrieve(relpathnames,_extra=!fast)
   
	endif

	if keyword_set(downloadonly) then continue

	for j=0,n_elements(filenames)-1 do begin
		if keyword_set(ignore_existence) then begin
			if file_test(filenames[j]) EQ 0 then begin
				print,'Warning: '+filenames[j]+' does not exist!'
				filenames[j]=''
			endif
		endif else begin
			if file_test(filenames[j]) EQ 0 then begin
				print,'Error: One or More Files Do Not Exist'
				return
			endif
		endelse
	endfor
	if keyword_set(ignore_existence) then filenames=filenames[where(filenames NE '')]
   
	if keyword_set(no_opts) then begin
		cdf2tplot,file=filenames,/all,verbose=verbose,varformat='*'
		nodata=0
		return
	endif
	
	;Set var and dvar.
	;if var_input EQ 1 then begin
		;nvar=n_elements(var)
		;if NOT keyword_set(dvar) then dvar=strarr(nvar)
		;if nvar NE n_elements(dvar) then begin
			;print,'Error: Dimensions of nvar and dvar must agree.'
			;return
		;endif
	;endif else begin
		;var=['el_0','el_90','el_180','el_low','el_high','JEe','Je']
		;dvar=['el_en','el_en','el_en','el_low_pa','el_high_pa','','']
		;nvar=n_elements(var)
	;endelse
	
	case type of

		'ees': begin
		
			if var_input EQ 1 then begin
				nvar=n_elements(var)
				if NOT keyword_set(dvar) then dvar=strarr(nvar)
				if nvar NE n_elements(dvar) then begin
					print,'Error: Dimensions of nvar and dvar must agree.'
					return
				endif
			endif else begin
				var=['el_0','el_90','el_180','el_low','el_high','JEe','Je']
				dvar=['el_en','el_en','el_en','el_low_pa','el_high_pa','','']
				nvar=n_elements(var)
			endelse

			nfiles=n_elements(filenames)

			for d=0,nfiles-1 do begin
				print,'Loading file: ',filenames[d],'...'
				varstruct=cdf_load_vars(filenames[d],varformat='*',varnames=varnames)
				if (where(varnames EQ 'TIME'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'TIME',data=tmp
				endif else if (where(varnames EQ 'unix_time'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'unix_time',data=tmp
				endif else begin
					print,'Error: cdf structure element for time is missing!'
					return
				endelse
				if d EQ 0 then begin
					time=tmp
				endif else begin
					ntime=n_elements(time)
					gaptime1=2.*time[ntime-1]-time[ntime-2]
					gaptime2=2.*tmp[0]-tmp[1]
					time=[time,gaptime1,gaptime2,tmp]
				endelse
			endfor

			for n=0,nvar-1 do begin

				for d=0,nfiles-1 do begin
					cdf_load_ptr,filenames[d],var[n],data=tmp
					if dvar[n] NE '' then cdf_load_ptr,filenames[d],dvar[n],data=tmpv
					if d EQ 0 then begin
						tmp_tot=tmp
						if dvar[n] NE '' then tmpv_tot=tmpv
					endif else begin
						gapdata=tmp_tot[0:1,*]
						gapdata[*,*]=!values.f_nan
						tmp_tot=[tmp_tot,gapdata,tmp]
						if dvar[n] NE '' then tmpv_tot=[tmpv_tot,gapdata,tmpv]
					endelse
				endfor

				if dvar[n] NE '' then begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot,v:tmpv_tot}
					options,var[n],'spec',1	
					options,var[n],'panel_size',2
					zlim,var[n],1e6,1e9,1
					options,var[n],'ztitle','eV/cm!U2!N-s-sr-eV'
					if var[n] EQ 'el_low' OR var[n] EQ 'el_high' then begin
						ylim,var[n],-100,280,0
						if var[n] EQ 'el_low' then begin
							options,var[n],'ytitle','e- .1-1 keV!C!C Pitch Angle'
						endif else begin
							options,var[n],'ytitle','e- >1 keV!C!C Pitch Angle'
						endelse
					endif else begin
						ylim,var[n],3,40000,1
						if var[n] EQ 'el_0' then begin
							options,var[n],'ytitle','e- 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
						endif else begin
							if var[n] EQ 'el_90' then begin
								options,var[n],'ytitle','e- 60!Uo!N-120!Uo!N!C!CEnergy (eV)'
							endif else begin
								options,var[n],'ytitle','e- 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
							endelse
						endelse
					endelse
					options,var[n],'x_no_interp',1
					options,var[n],'y_no_interp',1
				endif else begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot}
				endelse

			endfor

			;Label 'JEe' and 'Je' plots
			if (where(var EQ 'JEe'))[0] NE -1 then begin
				ylim,'JEe',.001,100,1
				options,'JEe','tplot_routine','pmplot'
				options,'JEe','labflag',3
				options,'JEe','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
				options,'JEe','labpos',[30.,4.]
				options,'JEe','ytitle','e- >25eV!C!Cergs/cm!U2!N-s'
			endif
			if (where(var EQ 'Je'))[0] NE -1 then begin
				ylim,'Je',1.e6,1.e10,1
				options,'Je','tplot_routine','pmplot'
				options,'Je','labflag',3
				options,'Je','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
				options,'Je','labpos',[3.e9,6.e8]
				options,'Je','ytitle','e- >25eV!C!C1/cm!U2!N-s'
			endif
			
			;Zero the time range
			tplot_options,trange=[0,0]
			
		end
	  
		'ies': begin
			
			if var_input EQ 1 then begin
				nvar=n_elements(var)
				if NOT keyword_set(dvar) then dvar=strarr(nvar)
				if nvar NE n_elements(dvar) then begin
					print,'Error: Dimensions of nvar and dvar must agree.'
					return
				endif
			endif else begin
				var=['ion_0','ion_90','ion_180','ion_low','ion_high','JEi','Ji']
				dvar=['ion_en','ion_en','ion_en','ion_low_pa','ion_high_pa','','']
				nvar=n_elements(var)
			endelse
			
			nfiles=n_elements(filenames)
			
			for d=0,nfiles-1 do begin
				print,'Loading file: ',filenames[d],'...'
				varstruct=cdf_load_vars(filenames[d],varformat='*',varnames=varnames)
				if (where(varnames EQ 'TIME'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'TIME',data=tmp
				endif else if (where(varnames EQ 'unix_time'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'unix_time',data=tmp
				endif else begin
					print,'Error: cdf structure element for time is missing!'
					return
				endelse
				if d EQ 0 then begin
					time=tmp
				endif else begin
					ntime=n_elements(time)
					gaptime1=2.*time[ntime-1]-time[ntime-2]
					gaptime2=2.*tmp[0]-tmp[1]
					time=[time,gaptime1,gaptime2,tmp]
				endelse
			endfor
				
			for n=0,nvar-1 do begin

				for d=0,nfiles-1 do begin
					cdf_load_ptr,filenames[d],var[n],data=tmp
					if dvar[n] NE '' then cdf_load_ptr,filenames[d],dvar[n],data=tmpv
					if d EQ 0 then begin
						tmp_tot=tmp
						if dvar[n] NE '' then tmpv_tot=tmpv
					endif else begin
						gapdata=tmp_tot[0:1,*]
						gapdata[*,*]=!values.f_nan
						tmp_tot=[tmp_tot,gapdata,tmp]
						if dvar[n] NE '' then tmpv_tot=[tmpv_tot,gapdata,tmpv]
					endelse
				endfor

				if dvar[n] NE '' then begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot,v:tmpv_tot}
					options,var[n],'spec',1	
					options,var[n],'panel_size',2
					zlim,var[n],1e4,1e8,1
					options,var[n],'ztitle','eV/cm!U2!N-s-sr-eV'
					if var[n] EQ 'ion_low' OR var[n] EQ 'ion_high' then begin
						ylim,var[n],-100,280,0
						if var[n] EQ 'ion_low' then begin
							options,var[n],'ytitle','ions .05-1 keV!C!C Pitch Angle'
						endif else begin
							options,var[n],'ytitle','ions >1 keV!C!C Pitch Angle'
						endelse
					endif else begin
						ylim,var[n],3,40000,1
						if var[n] EQ 'ion_0' then begin
							options,var[n],'ytitle','ions 0!Uo!N-30!Uo!N!C!CEnergy (eV)'
						endif else begin
							if var[n] EQ 'ion_90' then begin
								options,var[n],'ytitle','ions 40!Uo!N-140!Uo!N!C!CEnergy (eV)'
							endif else begin
								options,var[n],'ytitle','ions 150!Uo!N-180!Uo!N!C!CEnergy (eV)'
							endelse
						endelse
					endelse
					options,var[n],'x_no_interp',1
					options,var[n],'y_no_interp',1
				endif else begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot}
				endelse

			endfor

			;Label 'JEi' and 'Ji'
			if (where(var EQ 'JEi'))[0] NE -1 then begin
				ylim,'JEi',1.e-5,1,1
				options,'JEi','tplot_routine','pmplot'
				options,'JEi','labflag',3
				options,'JEi','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
				options,'JEi','labpos',[.30,.04]
				options,'JEi','ytitle','i+ >20eV!C!Cergs/cm!U2!N-s'
			endif
			if (where(var EQ 'Ji'))[0] Ne -1 then begin
				ylim,'Ji',1.e5,1.e9,1
				options,'Ji','tplot_routine','pmplot'
				options,'Ji','labflag',3
				options,'Ji','labels',['Downgoing','Upgoing!C!C  Mapped!C  to 100km!C  Altitude']
				options,'Ji','labpos',[3.e8,6.e7]
				options,'Ji','ytitle','i+ >20eV!C!C1/cm!U2!N-s'
			endif
			
			;Zero the time range
			tplot_options,trange=[0,0]

		end
	  
		'orb': begin
	  
			if var_input EQ 1 then begin
				nvar=n_elements(var)
				if NOT keyword_set(dvar) then dvar=strarr(nvar)
				if nvar NE n_elements(dvar) then begin
					print,'Error: Dimensions of nvar and dvar must agree.'
					return
				endif
			endif else begin
				var=['orbit','fa_spin_ra','fa_spin_dec','r','v','alt','flat','flng','mlt','ilat']
				dvar=['','','','','','','','','','']
				;;dvar=['','','','cartesian','cartesian','','','','','']
				nvar=n_elements(var)
			endelse
			
			nfiles = dimen1(filenames)
			
			for d=0,nfiles-1 do begin
				print,'Loading file: ',filenames[d],'...'
				varstruct=cdf_load_vars(filenames[d],varformat='*',varnames=varnames)
				if (where(varnames EQ 'TIME'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'TIME',data=tmp
				endif else if (where(varnames EQ 'unix_time'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'unix_time',data=tmp
				endif else begin
					print,'Error: cdf structure element for time is missing!'
					return
				endelse
				if d EQ 0 then begin
					time=tmp
				endif else begin
					ntime=n_elements(time)
					gaptime1=2.*time[ntime-1]-time[ntime-2]
					gaptime2=2.*tmp[0]-tmp[1]
					time=[time,gaptime1,gaptime2,tmp]
				endelse
			endfor
			
			for n=0,nvar-1 do begin
			
				for d=0,nfiles-1 do begin
					cdf_load_ptr,filenames[d],var[n],data=tmp
					if dvar[n] NE '' then cdf_load_ptr,filenames[d],dvar[n],data=tmpv
					if d EQ 0 then begin
						tmp_tot=tmp
						if dvar[n] NE '' then tmpv_tot=tmpv
					endif else begin
						gapdata=tmp_tot[0:1,*]
						gapdata[*,*]=!values.f_nan
						tmp_tot=[tmp_tot,gapdata,tmp]
						if dvar[n] NE '' then tmpv_tot=[tmpv_tot,gapdata,tmpv]
					endelse
				endfor

				if dvar[n] NE '' then begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot,v:tmpv_tot}
				endif else begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot}
					case var[n] of
						
						'fa_spin_ra': begin
							ylim,'fa_spin_ra',0,360,0
							options,'fa_spin_ra','ytitle','Spin RA'
							;options,'fa_spin_ra','tplot_routine','pmplot'
						end
						
						'fa_spin_dec': begin
							ylim,'fa_spin_dec',-90,90,0
							options,'fa_spin_dec','ytitle','Spin Dec'
							;options,'fa_spin_dec','tplot_routine','pmplot'
						end
						
						'alt': begin
							ylim,'alt',0,5000,0
							options,'alt','ytitle','ALT'
							;options,'alt','tplot_routine','pmplot'
						end
						
						'orbit': begin
							ylim,'alt',0,100000,0
							options,'alt','ytitle','SC Orbit'
							;options,'alt','tplot_routine','pmplot'
						end
						
						'flat': begin
							ylim,'flat',-90,90,0
							options,'flat','ytitle','FLAT'
							;options,'flat','tplot_routine','pmplot'
						end
						
						'flng': begin
							ylim,'flng',-180,180,0
							options,'flng','ytitle','FLNG'
							;options,'flng','tplot_routine','pmplot'
						end
						
						'mlt': begin
							ylim,'mlt',0,24,0
							options,'mlt','ytitle','MLT'
							;options,'mlt','tplot_routine','pmplot'
						end
						
						'ilat': begin
							ylim,'ilat',-90,90,0
							options,'ilat','ytitle','ILAT'
							;options,'ilat','tplot_routine','pmplot'
						end
						
						else: begin
						end
						
					endcase
				endelse
			
			endfor

			;Zero the time range
			tplot_options,trange=[0,0]
			
		end
	  
		'tms': begin
		
			nfiles=n_elements(filenames)
		
			if var_input EQ 0 then begin
				first=1
				for i=0,nfiles-1 do begin
					
					test_id=cdf_open(filenames[i])
					result=cdf_inquire(test_id)
					if first then begin
						nzvars=result.nzvars
						first=0
					endif else if nzvars NE result.nzvars then begin
						print,'load_fa_k0_tms.pro: The number of CDF variables must be the same for ' 
						print,'     all files given in the filenames keyword'
						print,'     First file contained: ', nzvars, ' variables'
						print,'     File: '+ filenames[i] + ' contains: ', $
						result.nzvars , ' variables'
					return
					endif

					if result.nzvars GE 14 then begin	;includes He+
						have_he_plus=1
						var=['H+','He+','O+','H+_low','H+_high','He+_low','He+_high', $
							'O+_low','O+_high']
						dvar=['H+_en','He+_en','O+_en','H+_low_pa','H+_high_pa','He+_low_pa','He+_high_pa', $
							'O+_low_pa','O+_high_pa']
					endif else begin       				;old file--H+ and O+ only
						have_he_plus=0
						var=['H+','O+','H+_low','H+_high','O+_low','O+_high']
						dvar=['H+_en','O+_en','H+_low_pa','H+_high_pa','O+_low_pa','O+_high_pa']
					endelse
					cdf_close, test_id
					
				endfor

			endif
			nvar=n_elements(var)
			if NOT keyword_set(dvar) then dvar=strarr(nvar)
			if nvar NE n_elements(dvar) then begin
				print,'Error: Dimensions of nvar and dvar must agree.'
				return
			endif

						for d=0,nfiles-1 do begin
				print,'Loading file: ',filenames[d],'...'
				varstruct=cdf_load_vars(filenames[d],varformat='*',varnames=varnames)
				if (where(varnames EQ 'TIME'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'TIME',data=tmp
				endif else if (where(varnames EQ 'unix_time'))[0] NE -1 then begin
					cdf_load_ptr,filenames[d],'unix_time',data=tmp
				endif else begin
					print,'Error: cdf structure element for time is missing!'
					return
				endelse
				if d EQ 0 then begin
					time=tmp
				endif else begin
					ntime=n_elements(time)
					gaptime1=2.*time[ntime-1]-time[ntime-2]
					gaptime2=2.*tmp[0]-tmp[1]
					time=[time,gaptime1,gaptime2,tmp]
				endelse
			endfor
			
			for n=0,nvar-1 do begin

				for d=0,nfiles-1 do begin
					cdf_load_ptr,filenames[d],var[n],data=tmp
					if dvar[n] NE '' then cdf_load_ptr,filenames[d],dvar[n],data=tmpv
					if d EQ 0 then begin
						tmp_tot=tmp
						if dvar[n] NE '' then tmpv_tot=tmpv
					endif else begin
						gapdata=tmp_tot[0:1,*]
						gapdata[*,*]=!values.f_nan
						tmp_tot=[tmp_tot,gapdata,tmp]
						if dvar[n] NE '' then tmpv_tot=[tmpv_tot,gapdata,tmpv]
					endelse
				endfor

				if dvar[n] NE '' then begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot,v:tmpv_tot}
				endif else begin
					store_data,var[n],data={ytitle:var[n],x:time,y:tmp_tot}
				endelse

			endfor

			;Hydrogen, Helium, and Oxygen differential energy flux - energy spectrograms
			options,'H+','spec',1
			zlim,'H+',1e2,1e7,1
			ylim,'H+',1,10000,1
			options,'H+','ytitle','H+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
			options,'H+','ztitle','eV/cm!U2!N-s-sr-eV'
			options,'H+','x_no_interp',1
			options,'H+','y_no_interp',1
			options,'H+','panel_size',2
			if  have_he_plus  then begin
				options,'He+','spec',1
				zlim,'He+',1e2,1e7,1
				ylim,'He+',1,10000,1
				options,'He+','ytitle','He+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
				options,'He+','ztitle','eV/cm!U2!N-s-sr-eV'
				options,'He+','x_no_interp',1
				options,'He+','y_no_interp',1
				options,'He+','panel_size',2
			endif
			options,'O+','spec',1
			zlim,'O+',1e2,1e7,1
			ylim,'O+',1,10000,1
			options,'O+','ytitle','O+ 0!Uo!N-360!Uo!N!C!C Energy (eV)'
			options,'O+','ztitle','eV/cm!U2!N-s-sr-eV'
			options,'O+','x_no_interp',1
			options,'O+','y_no_interp',1
			options,'O+','panel_size',2

			;Hydrogen differential energy flux - angle spectrograms
			options,'H+_low','spec',1
			zlim,'H+_low',1e2,1e7,1
			ylim,'H+_low',-100,280,0
			options,'H+_low','ytitle','H+ .01-1keV !C!CPitch Angle'
			options,'H+_low','ztitle','eV/cm!U2!N-s-sr-eV'
			options,'H+_low','x_no_interp',1
			options,'H+_low','y_no_interp',1
			options,'H+_low','panel_size',2
			options,'H+_high','spec',1
			zlim,'H+_high',1e2,1e7,1
			ylim,'H+_high',-100,280,0
			options,'H+_high','ytitle','H+ >1keV !C!CPitch Angle'
			options,'H+_high','ztitle','eV/cm!U2!N-s-sr-eV'
			options,'H+_high','x_no_interp',1
			options,'H+_high','y_no_interp',1
			options,'H+_high','panel_size',2

			;Helium differential energy flux - angle spectrograms
			if  have_he_plus  then begin
				options,'He+_low','spec',1
				zlim,'He+_low',1e2,1e7,1
				ylim,'He+_low',-100,280,0
				options,'He+_low','ytitle','He+ .01-1keV !C!CPitch Angle'
				options,'He+_low','ztitle','eV/cm!U2!N-s-sr-eV'
				options,'He+_low','x_no_interp',1
				options,'He+_low','y_no_interp',1
				options,'He+_low','panel_size',2
				options,'He+_high','spec',1
				zlim,'He+_high',1e2,1e7,1
				ylim,'He+_high',-100,280,0
				options,'He+_high','ytitle','He+ >1keV !C!CPitch Angle'
				options,'He+_high','ztitle','eV/cm!U2!N-s-sr-eV'
				options,'He+_high','x_no_interp',1
				options,'He+_high','y_no_interp',1
				options,'He+_high','panel_size',2
			endif

			;Oxygen differential energy flux - angle spectrograms
			options,'O+_low','spec',1
			zlim,'O+_low',1e2,1e7,1
			ylim,'O+_low',-100,280,0
			options,'O+_low','ytitle','O+ .01-1keV !C!CPitch Angle'
			options,'O+_low','ztitle','eV/cm!U2!N-s-sr-eV'
			options,'O+_low','x_no_interp',1
			options,'O+_low','y_no_interp',1
			options,'O+_low','panel_size',2
			options,'O+_high','spec',1
			zlim,'O+_high',1e2,1e7,1
			ylim,'O+_high',-100,280,0
			options,'O+_high','ytitle','O+ >1keV !C!CPitch Angle'
			options,'O+_high','ztitle','eV/cm!U2!N-s-sr-eV'
			options,'O+_high','x_no_interp',1
			options,'O+_high','y_no_interp',1
			options,'O+_high','panel_size',2
			;options,'hm','spec',1
			;zlim,'hm',1e-2,1e5,1
			;ylim,'hm',0,75,0
			;ylim,'hm',.5,65.,1
			;options,'hm','ztitle', 'counts/sec'
			;options,'hm','ytitle', 'mass (mass unit)'
			;options,'hm','x_no_interp',1
			;options,'hm','y_no_interp',1

			;Zero the time range
			tplot_options,trange=[0,0]
			
		end
	  
		else: begin
		
			;cdf2tplot does not include gapdata.
			cdf2tplot,file=filenames,/all,verbose=verbose,varformat='*'
			
		end
	  
   endcase

endfor

nodata=0
return
end
