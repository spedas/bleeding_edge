;+
;Procedure: THM_LOAD_ESA_PKT
;
;Purpose:  Loads THEMIS ESA data
;
;keywords:
;  probe = Probe name. The default is 'all', i.e., load all available probes.
;          This can be an array of strings, e.g., ['a', 'b'] or a
;          single string delimited by spaces, e.g., 'a b'
;  datatype = The type of data to be loaded: 
;		'peif','peir','peib','peef','peer','peeb'
;		if not set, default is all variables
;  TRANGE= (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded
;  use_eclipse_corrections = Flag to specify which spin model will be used:
;      0 - No corrections (default)
;      1 - Use partial corrections
;      2 - Use full eclipse corrections
;  /GET_SUPPORT_DATA: load support_data variables as well as data variables
;                      into tplot variables.
;  /DOWNLOADONLY: download file but don't read it.
;  /valid_names, if set, then this routine will return the valid probe, datatype
;          and/or level options in named variables supplied as
;          arguments to the corresponding keywords.
;  files   named varible for output of pathnames of local files.
;  /VERBOSE  set to output some useful info
; 	suffix		string		"suffix" is appended to the default tplot names 
;
;Example:
;   thg_load_esa,/get_suppport_data,probe=['a', 'b']
;
;CREATED BY:	J. McFadden	  07/03/22
;VERSION:	1
;LAST MODIFICATION:  08/05/14
;MOD HISTORY:
;			suffix keyword added  			08/05/14 jmcfadden
;			trange keyword made functional 		09/08/25 bkerr
;			trange keyword function corrected 	10/07/23 jmcfadden
;			clipping and no_clipping added		11/01/04 jmcfadden 
; 
;-
pro thm_load_esa_pkt,probe=probe, datatype=datatype, trange=trange, $
		verbose=verbose, downloadonly=downloadonly, $
		get_support_data=get_support_data, $
		use_eclipse_corrections=use_eclipse_corrections, $
		valid_names = valid_names, files=files,suffix=suffix, $
		no_time_clip = no_time_clip, $
		_extra=_extra

thm_init


vb = keyword_set(verbose) ? verbose : 0
vb = vb > !themis.verbose
if vb ge 5 then printdat,!themis,/pgmtrace

vprobes = ['a','b','c','d','e','f']
; vlevels = ['l0']
vdatatypes=['peif','peir','peib','peef','peer','peeb']

support_suffix = '_esa_part_tmp'

if keyword_set(valid_names) then begin
    probe = vprobes
    datatype = vdatatypes
    return
endif

if not keyword_set(probe) then probe=['a','b','c','d','e']
;probes = strfilter(vprobes, probe ,delimiter=' ',/string)
if not keyword_set(datatype) then datatype='*'
if ~keyword_set(suffix) then suffix=''
;datatypes = strfilter(vdatatypes, datatype ,delimiter=' ',/string)

probes = ssl_check_valid_name(probe,vprobes,/include_all,/ignore_case)
if(probes[0] eq '') then message,'incorrect probe input passed to thm_load_esa_pkt'
datatypes = ssl_check_valid_name(datatype,vdatatypes,/include_all,/ignore_case)
if(datatypes[0] eq '') then message,'incorrect datatype input passed to thm_load_esa_pkt'


ndt=n_elements(datatypes)
apid=strarr(ndt)
	for i=0l,ndt-1 do begin
		case datatypes[i] of
				'peif': apid[i]='454'
				'peir': apid[i]='455'
				'peib': apid[i]='456'
				'peef': apid[i]='457'
				'peer': apid[i]='458'
				'peeb': apid[i]='459'
		endcase
	endfor

for s=0,n_elements(probes)-1 do begin
	sc = probes[s]

	tt=timerange(trange)
	t1=time_double(strmid(time_string(tt[0]),0,10))
	t2=time_double(strmid(time_string(tt[1]-1.),0,10))
	ndays=1+long((t2-t1)/(24.*3600.))
        If(ndays Gt 2) Then Begin
            dprint,dlev=0, ' '
            dprint, dlev=0,'***WARNING: Time range may be too long for some ESA datatypes'
            dprint,dlev=0, ' '
        Endif
	relpathnames=strarr(ndays*ndt) 
	t0 = t1  ;copy time for later
	i=0l
	while t1 le t2 do begin
		ts=time_string(t1) 
		yr=strmid(ts,0,4) & mo=strmid(ts,5,2) & da=strmid(ts,8,2)
		dir='th'+sc+'/l0/'+yr+'/'+mo+'/'+da+'/' 
		relpathnames[i*ndt:(i+1)*ndt-1]=dir+'th'+sc+'_l0_'+apid+'_'+yr+mo+da+'.pkt'
		i=i+1
		t1=t1+24.*3600.
	endwhile

     	files = spd_download(remote_file=relpathnames, _extra=!themis)

	thm_load_esa_cal

  ;load support data for spinmodel  
  thm_load_state, probe=sc, trange=trange, downloadonly=downloadonly, $
                  /get_support_data, suffix = support_suffix

	if not keyword_set(downloadonly) then begin
  	for j=0,ndt-1 do begin
		case datatypes[j] of
				'peif': thm_load_peif,sc=sc,themishome=!themis.local_data_dir,suffix=suffix,trange=trange, use_eclipse_corrections=use_eclipse_corrections
				'peir': thm_load_peir,sc=sc,themishome=!themis.local_data_dir,suffix=suffix,trange=trange, use_eclipse_corrections=use_eclipse_corrections
				'peib': thm_load_peib,sc=sc,themishome=!themis.local_data_dir,suffix=suffix,trange=trange, use_eclipse_corrections=use_eclipse_corrections
				'peef': thm_load_peef,sc=sc,themishome=!themis.local_data_dir,suffix=suffix,trange=trange, use_eclipse_corrections=use_eclipse_corrections
				'peer': thm_load_peer,sc=sc,themishome=!themis.local_data_dir,suffix=suffix,trange=trange, use_eclipse_corrections=use_eclipse_corrections
				'peeb': thm_load_peeb,sc=sc,themishome=!themis.local_data_dir,suffix=suffix,trange=trange, use_eclipse_corrections=use_eclipse_corrections
		endcase

	; the following was a Vassilis request to clip tplot variables to trange (doesn't save memory)
	; get names of new tplot vars
		tplotnames=['th'+sc+'_'+datatypes[j]+'_en_counts'+suffix, $
				'th'+sc+'_'+datatypes[j]+'_mode'+suffix]
	; clip data to requested trange, if it exists 
	; (no_time_clip keyword had to be added because clipping f**ks up level 2 production)
		If(~keyword_set(no_time_clip)) Then Begin
			If (keyword_set(trange) && n_elements(trange) Eq 2) $
			Then tr = timerange(trange) Else tr = timerange()
			for i = 0, n_elements(tplotnames)-1 do begin
				if tnames(tplotnames[i]) eq '' then continue
				time_clip, tplotnames[i], min(tr), max(tr), /replace, error = tr_err
				if tr_err then del_data, tplotnames[i]
			endfor
		Endif


	endfor
	endif

endfor

;remove temporary state vars
store_data, '*' + support_suffix, /delete

end
