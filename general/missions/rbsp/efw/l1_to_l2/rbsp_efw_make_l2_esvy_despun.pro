;+
; NAME: rbsp_efw_make_l2_esvy_despun
; SYNTAX: 
; PURPOSE: Crib sheet for creating the 32 S/s despun MGSE Efield with vxB subtraction
;			This is stored in a cdf file
;
; INPUT: 
; OUTPUT: 
; KEYWORDS: 
; HISTORY: Created Aaron Breneman Aug 2013
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-06-24 15:22:43 -0700 (Tue, 24 Jun 2014) $
;   $LastChangedRevision: 15425 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_esvy_despun.pro $
;-


pro rbsp_efw_make_l2_esvy_despun,sc,date,folder=folder,no_spice_load=no_spice_load,qa=qa,testing=testing


	rbsp_efw_init

	skip_plot = 1   ;set to skip restoration of cdf file and test plotting at end of program

	starttime=systime(1)
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

	if ~keyword_set(folder) then folder ='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'
	; make sure we have the trailing slash on folder
	if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
	file_mkdir,folder

	; Grab the skeleton file.
	skeleton=rbspx+'/l2/esvy_despun/0000/'+ $
		rbspx+'_efw-l2_esvy_despun_00000000_v'+vstr+'.cdf'

	source_file=file_retrieve(skeleton,_extra=!rbsp_efw)

	; Use local skeleton
	;source_file='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+skeleton



	if keyword_set(testing) then begin
		skeleton = 'rbsp'+sc+'_efw-l2_esvy_despun_00000000_v01.cdf'
		source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/' + skeleton
	endif


	; make sure we have the skeleton CDF
	source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
	if ~found then begin
		dprint,'Could not find l2_esvy_despun v'+vstr+' skeleton CDF, returning.'
		return
	endif
	; fix single element source file array
	source_file=source_file[0]



;Start with a clean slate
	store_data,tnames(),/delete



;Get the time structure for the flag values
	spinperiod = 11.8
	epoch_flag_times,date,spinperiod,epochvals,timevals


	
	timespan,date


;Load spice data
	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels



;Load the vxb subtracted data. If there isn't any vxb subtracted data
;then grab the regular Esvy MGSE data
	if ~keyword_set(qa) then rbsp_efw_vxb_subtract_crib,sc,/no_spice_load,/noplot
	if keyword_set(qa)  then rbsp_efw_vxb_subtract_crib,sc,/no_spice_load,/noplot,/qa


	get_data,rbspx+'_efw_esvy_mgse_vxb_removed',data=esvy_mgse
	if ~is_struct(esvy_mgse) then get_data,rbspx+'_efw_esvy_mgse',data=esvy_mgse
	
	
	
;Zero out the E56 data.
	esvy_mgse.y[*,0] = -1.e31
	
	

	epoch_esvy = tplot_time_to_epoch(esvy_mgse.x,/epoch16)



;Load Vsvy data - used to identify saturated data
	rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean
	rbsp_downsample,rbspx+'_efw_vsvy',1/spinperiod,/nochange	
	get_data,rbspx+'_efw_vsvy',data=vsvy
	split_vec, 'rbsp?_efw_vsvy', suffix='_V'+['1','2','3','4','5','6']


	get_data,rbspx +'_efw_vsvy_V1',data=d1
	get_data,rbspx +'_efw_vsvy_V2',data=d2
	get_data,rbspx +'_efw_vsvy_V3',data=d3
	get_data,rbspx +'_efw_vsvy_V4',data=d4
	get_data,rbspx +'_efw_vsvy_V5',data=d5
	get_data,rbspx +'_efw_vsvy_V6',data=d6



		

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
	maxvolts = 195. ;Max antenna voltage above which the saturation flag is thrown
	offset = 5   ;position in flag_arr of "v1_saturation" 

	tmp = replicate(0,n_elements(vsvy.x),6)

	;All the flag values for the entire EFW data set
	flag_arr = replicate(fill_val,n_elements(timevals),20)


;Throw the single-ended flag when the single-ended measurements are saturated
	for i=0,5 do begin

		;Change bad values to "1"
		vbad = where(abs(vsvy.y[*,i]) ge maxvolts)
		if vbad[0] ne -1 then tmp[vbad,i] = 1

		;Change good values to "0"
		vgood = where(abs(vsvy.y[*,i]) lt maxvolts)
		if vgood[0] ne -1 then tmp[vgood,i] = 0


		;Interpolate the bad data values onto the pre-defined flag value times
		flag_arr[*,i+offset] = ceil(interpol(tmp[*,i],vsvy.x,timevals))


		;****TEMPORARY CODE******
		;Set the actual bad vsvy values to NaN
		if vbad[0] ne -1 then vsvy.y[vbad,i] = -1.e31
		;************************

	endfor


	;****TEMPORARY CODE******
	;Throw the global flag if any of the single-ended flags are thrown.
		flag_arr[*,0] = 0
		flag_arr[*,1] = 0
		goo = where((flag_arr[*,5] eq 1) or (flag_arr[*,6] eq 1) or (flag_arr[*,7] eq 1) or (flag_arr[*,8] eq 1))
		if goo[0] ne -1 then flag_arr[goo,0] = 1
	;************************



	;set V5 and V6 flags to bad
	flag_arr[*,9] = 1
	flag_arr[*,10] = 1



	;*****TEMPORARY CODE*****
	;set the eclipse flag in this program

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


;	;Also set global flag if eclipse flag is thrown
	goo = where(flag_arr[*,1] eq 1)
	if goo[0] ne -1 then flag_arr[goo,0] = 1


;***********************

	flag_arr[*,2] = fill_val	;maneuver
	flag_arr[*,3] = fill_val	;efw_sweep
	flag_arr[*,4] = fill_val	;efw_deploy


	;Set the N/A values. These are not directly relevant to the quality
	;of the Vsvy product
	flag_arr[*,11] = na_val	;Espb_magnitude
	flag_arr[*,12] = na_val	;Eparallel_magnitude
	flag_arr[*,13] = na_val	;magnetic_wake
	flag_arr[*,14:19] = na_val  ;undefined values




	;now that global flag has been set, interpolate these values up to the
	;high time cadence of the esvy product so I can flag the bad esvy values
	esvy_flag = ceil(interpol(flag_arr[*,0],timevals,esvy_mgse.x))

	goo = where(esvy_flag eq 1)
	if goo[0] ne -1 then begin
		esvy_mgse.y[goo,0] = -1.e31
		esvy_mgse.y[goo,1] = -1.e31
		esvy_mgse.y[goo,2] = -1.e31
	endif


;Grab the state data
	get_data,rbspx+'_state_mlt',data=mlt
	get_data,rbspx+'_state_mlat',data=mlat
	get_data,rbspx+'_state_lshell',data=lshell
	get_data,rbspx+'_state_pos_gse',data=pos_gse
	get_data,rbspx+'_state_vel_gse',data=vel_gse

;Interpolate the flag value times to the data times
	epochstate = interpol(epochvals,timevals,mlt.x)
	


; FILL THE CDF
	
	;Rename the skeleton file 
	filename = 'rbsp'+sc+'_efw-l2_esvy_despun_'+strjoin(strsplit(date,'-',/extract))+'_'+version+'.cdf'
	
	file_copy,source_file,folder+filename,/overwrite

	cdfid = cdf_open(folder+filename)
	cdf_control, cdfid, get_var_info=info, variable='epoch_esvy'

	cdf_varput,cdfid,'epoch',epochstate
	cdf_varput,cdfid,'mlt',mlt.y
	cdf_varput,cdfid,'mlat',mlat.y
	cdf_varput,cdfid,'lshell',lshell.y
	cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
	cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)

	cdf_varput,cdfid,'epoch_esvy',epoch_esvy
	cdf_varput,cdfid,'efield_mgse',transpose(esvy_mgse.y)

	cdf_varput,cdfid,'epoch_qual',epochvals
	cdf_varput,cdfid,'efw_qual',transpose(flag_arr)

;	cdf_varput,cdfid,'vsvy_vavg',transpose(vsvy_vavg)
;	cdf_varput,cdfid,'density',density

	cdf_close, cdfid




	store_data,tnames(),/delete



	;Load the newly filled CDF structure to see if it works
	if ~skip_plot then begin

		cdf_leap_second_init
		cdf2tplot,files=folder + filename

		ylim,'efw_qual',-2,2


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
			'undefined	',$
			'undefined	',$
			'undefined	',$
			'undefined	',$
			'undefined',$
			'undefined']

		split_vec,'efw_qual',suffix='_'+names

	
	endif

	dprint,'END TIME IS ',systime()
	dprint,'TOTAL RUNTIME (s) IS ',systime(1)-starttime
	
end
