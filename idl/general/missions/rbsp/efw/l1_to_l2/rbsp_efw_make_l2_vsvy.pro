;+
; NAME:
;   rbsp_efw_make_l2_vsvy
;
; PURPOSE: Create L2 (level-2) CDF files from the Van Allen Probe EFW 
;			Vsvy data product. 
;
;
; CALLING SEQUENCE:
;
; ARGUMENTS:	sc -> Which probe? 'a' or 'b'
;				date -> ex, '2013-10-13'
;
; KEYWORDS:
;
;
; EXAMPLES:	rbsp_efw_make_l2_vsvy,'a','2012-10-13'
;
; NOTES: This program stuffs the following quantities into the skeleton CDF file.
;		V1-V6 -> single-ended potential quantities
;		(Vx+Vy)/2 -> opposing boom averages
;
;
;	The flag array to be inserted into CDF has the following 20 fields:
;		global_flag
;		eclipse
;		maneuver
;		efw_sweep
;		efw_deploy
;		v1_saturation
;		v2_saturation
;		v3_saturation
;		v4_saturation
;		v5_saturation
;		v6_saturation
;		Espb_magnitude
;		Eparallel_magnitude
;		magnetic_wake
;		undefined	
;		undefined	
;		undefined	
;		undefined	
;		undefined	
;		undefined	
;
;	This program only sets the values of the V1-V6_saturation. The other values
;	are set to N/A or to unknown
;
;
; HISTORY:
;   March 2013: Created by Aaron Breneman, University of Minnesota
;
;
; VERSION:
;	$LastChangedBy: kersten $
;	$LastChangedDate: 2013-09-18 13:41:10 -0700 (Wed, 18 Sep 2013) $
;	$LastChangedRevision: 13062 $
; 	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_vsvy.pro $
;-

pro rbsp_efw_make_l2_vsvy,sc,date,folder=folder,version=version

	
	rbsp_efw_init
	
	skip_plot = 1   ;set to skip restoration of cdf file and test plotting at end of program


	dprint,'BEGIN TIME IS ',systime()

	if n_elements(version) eq 0 then version = 1
	vstr = string(version, format='(I02)')
	version = 'v'+vstr

	sc=strlowcase(sc)
	if sc ne 'a' and sc ne 'b' then begin
		dprint,'Invalid spacecraft: '+sc+', returning.'
		return
	endif
	rbspx = 'rbsp'+sc

	if ~keyword_set(folder) then folder ='~/Desktop/code/Aaron/RBSP/l2_processing_cribs/'
	; make sure we have the trailing slash on folder
	if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
	file_mkdir,folder
	
	; Grab the skeleton file.
	skeleton=rbspx+'/l2/vsvy-hires/0000/'+ $
		rbspx+'_efw-l2_vsvy-hires_00000000_v'+vstr+'.cdf'
	source_file=file_retrieve(skeleton,_extra=!rbsp_efw)

	; use skeleton from the staging dir until we go live in the main data tree
	;source_file='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton
	
	; make sure we have the skeleton CDF
	source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
	if ~found then begin
		dprint,'Could not find vsvy-hires v'+vstr+' skeleton CDF, returning.'
		return
	endif
	; fix single element source file array
	source_file=source_file[0]
	
	;Load some data
	timespan,date

	;Load the survey data
	rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean
	get_data,rbspx+'_efw_vsvy',data=vsvy 
	if ~is_struct(vsvy) then begin
  		dprint,rbspx+'_efw_vsvy unavailable, returning.'
  		return
	endif


	;Not ready to release the V5, V6 values.
	vsvy.y[*,4] = -1.0e31
	vsvy.y[*,5] = -1.0e31


	;Get the time structure for the flag values. These are not necessarily at the cadence
	;of physical data.
	epoch_flag_times,date,5,epoch_qual,timevals



	;Load HSK data
	rbsp_load_efw_hsk,probe=sc,/get_support_data

	get_data,rbspx+'_efw_vsvy_ccsds_data_BEB_config',data=beb
	if ~is_struct(beb) then begin
  		dprint,rbspx+'_efw_vsvy_ccsds_data_BEB_config unavailable, returning.'
  		return
	endif

	get_data,rbspx+'_efw_vsvy_ccsds_data_DFB_config',data=dfb
	if ~is_struct(dfb) then begin
  		dprint,rbspx+'_efw_vsvy_ccsds_data_DFB_config unavailable, returning.'
  		return
	endif
	



;*****TEMPORARY CODE***********
;APPLY THE ECLIPSE FLAG WITHIN THIS ROUTINE. LATER, THIS WILL BE DONE BY THE MASTER ROUTINE
	;load eclipse times
	; for Keith's stack
	rbsp_load_eclipse_predict,sc,date,$
		local_data_dir='~/data/rbsp/',$
		remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'

	get_data,rbspx + '_umbra',data=eu
	get_data,rbspx + '_penumbra',data=ep


	eclipset = replicate(0B,n_elements(vsvy.x))

;*****************************


	;Get flag values
	na_val = -2    ;not applicable value
	fill_val = -1  ;value in flag array that indicates "dunno"
	good_val = 0   ;value for good data
	bad_val = 1    ;value for bad data
	maxvolts = 195. ;Max antenna voltage above which the saturation flag is thrown

	offset = 5   ;position in flag_arr of "v1_saturation" 

	tmp = replicate(0,n_elements(vsvy.x),6)

	;All the flag values for the entire EFW data set
	flag_arr = replicate(fill_val,n_elements(timevals),20)


	for i=0,5 do begin

		;flag bad values
		vbad = where(abs(vsvy.y[*,i]) ge maxvolts)
		if vbad[0] ne -1 then tmp[vbad,i] = bad_val


;****TEMPORARY CODE******
;Set the actual bad vsvy values to NaN
if vbad[0] ne -1 then vsvy.y[vbad,i] = -1.0e31
;************************



		;set good values
		vgood = where(abs(vsvy.y[*,i]) lt maxvolts)
		if vgood[0] ne -1 then tmp[vgood,i] = good_val

		;Interpolate the bad data values onto the pre-defined flag value times
		flag_arr[*,i+offset] = ceil(interpol(tmp[*,i],vsvy.x,timevals))






;*****TEMPORARY CODE*****
;set the eclipse flag in this program

flag_arr[*,1] = 0.    ;default to no eclipse

;Umbra
if is_struct(eu) then begin
	for bb=0,n_elements(eu.x)-1 do begin
		goo = where((vsvy.x ge eu.x[bb]) and (vsvy.x le (eu.x[bb]+eu.y[bb])))
		if goo[0] ne -1 then eclipset[goo] = 1
	endfor
endif
;Penumbra
if is_struct(ep) then begin
	for bb=0,n_elements(ep.x)-1 do begin
		goo = where((vsvy.x ge ep.x[bb]) and (vsvy.x le (ep.x[bb]+ep.y[bb])))
		if goo[0] ne -1 then eclipset[goo] = 1
	endfor
endif

flag_arr[*,1] = ceil(interpol(eclipset,vsvy.x,timevals))

;***********************

		

	endfor


		flag_arr[*,0] = 0	;global_flag

		;Set the unknown values. These quantities do have a direct relevance
		;to the Vsvy L2 data product

		flag_arr[*,2] = fill_val	;maneuver
		flag_arr[*,3] = fill_val	;efw_sweep
		flag_arr[*,4] = fill_val	;efw_deploy


		;Set the N/A values. These are not directly relevant to the quality
		;of the Vsvy product
		flag_arr[*,11] = na_val	;Espb_magnitude
		flag_arr[*,12] = na_val	;Eparallel_magnitude
		flag_arr[*,13] = na_val	;magnetic_wake
		flag_arr[*,14:19] = na_val  ;undefined values




	;Create average values of opposing antennas
	v1v2 = 0.5*(vsvy.y[*,0] + vsvy.y[*,1])
	v3v4 = 0.5*(vsvy.y[*,2] + vsvy.y[*,3])
	v5v6 = 0.5*(vsvy.y[*,4] + vsvy.y[*,5])


	;not ready to release V5 or V6 values
	v5v6[*] = -1.0e31
	


;*****TEMPORARY********
;Set bad vavg values to ISTP compliant value of -1.0E31
goo = where((finite(vsvy.y[*,0]) eq 0) or (finite(vsvy.y[*,1]) eq 0))
if goo[0] ne -1 then v1v2[goo] = -1.0e31
goo = where((finite(vsvy.y[*,2]) eq 0) or (finite(vsvy.y[*,3]) eq 0))
if goo[0] ne -1 then v3v4[goo] = -1.0e31
;**********************


	
	vsvy_vavg = [[v1v2],[v3v4],[v5v6]]



	;Make the time string
	times = vsvy.x
	times_hsk = beb.x

	epoch = tplot_time_to_epoch(times,/epoch16)
	epoch_hsk = tplot_time_to_epoch(times_hsk,/epoch16)




;****TEMPORARY CODE******
;Throw the global flag if any of the single-ended measurement flags are thrown.

	goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
	if goo[0] ne -1 then flag_arr[goo,0] = 1

;Also set global flag if eclipse flag is thrown
	goo = where(flag_arr[*,1] eq 1)
	if goo[0] ne -1 then flag_arr[goo,0] = 1
;************************


 
	;Stuff values into the cdf skeleton structure

	filename = 'rbsp'+sc+'_efw-l2_vsvy-hires_'+strjoin(strsplit(date,'-',/extract))+'_'+version+'.cdf'
	file_copy,source_file,folder+filename,/overwrite ; overwrite old files

	cdfid = cdf_open(folder+filename)
	cdf_control, cdfid, get_var_info=info, variable='epoch'


	cdf_varput,cdfid,'epoch',epoch
	cdf_varput,cdfid,'epoch_hsk',epoch_hsk
	cdf_varput,cdfid,'epoch_qual',epoch_qual
	cdf_varput,cdfid,'vsvy',transpose(vsvy.y)
	cdf_varput,cdfid,'vsvy_vavg',transpose(vsvy_vavg)
	cdf_varput,cdfid,'vsvy_DFB_config',dfb.y
	cdf_varput,cdfid,'vsvy_BEB_config',beb.y
	cdf_varput,cdfid,'efw_qual',transpose(flag_arr)


	cdf_close, cdfid

	dprint,'END TIME IS: ',systime()

	store_data,tnames(),/delete



	;Load the newly filled CDF structure to see if it works
	if ~skip_plot then begin
		cdf_leap_second_init
		cdf2tplot,files=folder + filename

		ylim,'vsvy',-20,20
		ylim,'vsvy_vavg',-20,20
		ylim,'vsvy_DFB_config',-2,2
		ylim,'vsvy_BEB_config',-2,2

		names = ['global_flag',$
			'eclipse',$
			'maneuver',$
			'efw_sweep',$
			'efw_deploy',$
			'v1_saturation',$
			'v2_saturation',$
			'v3_saturation',$
			'v4_saturation',$
			'v5_saturation',$
			'v6_saturation',$
			'Espb_magnitude',$
			'Eparallel_magnitude',$
			'magnetic_wake',$
			'undefined',$
			'undefined',$
			'undefined',$
			'undefined',$
			'undefined',$
			'undefined']

		split_vec,'efw_qual',suffix='_'+names

		ylim,'efw_qual_v*_saturation',-2,2
		ylim,1,-250,250
		tplot,['vsvy','vsvy_vavg','vsvy_DFB_config','vsvy_BEB_config','efw_qual']

	endif


end
