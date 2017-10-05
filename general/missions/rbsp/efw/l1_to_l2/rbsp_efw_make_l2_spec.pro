;+
;rbsp_efw_spec_L2_crib
;
;Loads and plots RBSP (Van Allen probes) spectral data
;used for the L2 CDF files
;
; SPEC returns 7 channels, with nominal data selection:
;		SPEC0: E12AC
;		SPEC1: E56AC
;		SPEC2: SCMpar
;		SPEC3: SCMperp
;		SPEC4: SCMW
;		SPEC5: V1AC
;		SPEC6: V2AC
;
;			Select 7 of: E12dc,E34dc,E56dc
;						 E12ac,E34ac,E56ac
;						 Edcpar,Edcprp
;						 Eacpar,Eacprp
;						 V1ac,V2ac,V3ac,V4ac,V5ac,V6ac
;						 SCMU,SCMV,SCMW
;						 SCMpar,SCMprp,
;						 (V1dc+V2dc+V3dc+V4dc)/4,
;						 Edcprp2, Eacprp2, SCMprp2
;
;	notes:
;
;
;	Aaron Breneman, UMN, Feb 2013
;	email: awbrenem@gmail.com
;
; VERSION:
;	$LastChangedBy: aaronbreneman $
;	$LastChangedDate: 2016-08-03 13:19:08 -0700 (Wed, 03 Aug 2016) $
;	$LastChangedRevision: 21597 $
;	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_spec.pro $
;
;-



pro rbsp_efw_make_l2_spec,sc,date,folder=folder,testing=testing,boom_pair=bp

	skip_plot = 1   ;set to skip restoration of cdf file and test plotting at end of program
	if ~KEYWORD_SET(bp) then bp = '12'

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
	skeleton=rbspx+'/l2/spec/0000/'+ $
		rbspx+'_efw-l2_spec_00000000_v'+vstr+'.cdf'
	if ~keyword_set(testing) then source_file=file_retrieve(skeleton,_extra=!rbsp_efw)


        if keyword_set(testing) then begin
           skeleton = 'rbspa_efw-l2_spec_00000000_v01.cdf'
           source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/' + skeleton
        endif


;	source_file=file_retrieve(skeleton,_extra=!rbsp_efw)
	;source_file=file_retrieve(source_file,_extra=!rbsp_efw)

	; use skeleton from the staging dir until we go live in the main data tree
	;source_file='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton

	; make sure we have the skeleton CDF
	source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
	if ~found then begin
		dprint,'Could not find spec v'+vstr+' skeleton CDF, returning.'
		return
	endif
	; fix single element source file array
	source_file=source_file[0]

	; fix single element source file array
	source_file=source_file[0]


	timespan, date

;Load the spectrogram data
	rbsp_load_efw_spec,probe=sc,type='calibrated'


	;Determine number of bins
	tn = tnames('*spec0')
	get_data,tn[0],data=dd
	bins = strtrim(n_elements(dd.v),2)

	get_data,rbspx+'_efw_'+bins+'_spec0',data=spec0,dlimits=dlim0
	get_data,rbspx+'_efw_'+bins+'_spec1',data=spec1,dlimits=dlim1
	get_data,rbspx+'_efw_'+bins+'_spec2',data=spec2,dlimits=dlim2
	get_data,rbspx+'_efw_'+bins+'_spec3',data=spec3,dlimits=dlim3
	get_data,rbspx+'_efw_'+bins+'_spec4',data=spec4,dlimits=dlim4
	get_data,rbspx+'_efw_'+bins+'_spec5',data=spec5,dlimits=dlim5
	get_data,rbspx+'_efw_'+bins+'_spec6',data=spec6,dlimits=dlim6

	chn0 = strlowcase(dlim0.data_att.channel)
	chn1 = strlowcase(dlim1.data_att.channel)
	chn2 = strlowcase(dlim2.data_att.channel)
	chn3 = strlowcase(dlim3.data_att.channel)
	chn4 = strlowcase(dlim4.data_att.channel)
	chn5 = strlowcase(dlim5.data_att.channel)
	chn6 = strlowcase(dlim6.data_att.channel)

	ep0 = tplot_time_to_epoch(spec0.x,/epoch16)
	ep1 = tplot_time_to_epoch(spec1.x,/epoch16)
	ep2 = tplot_time_to_epoch(spec2.x,/epoch16)
	ep3 = tplot_time_to_epoch(spec3.x,/epoch16)
	ep4 = tplot_time_to_epoch(spec4.x,/epoch16)
	ep5 = tplot_time_to_epoch(spec5.x,/epoch16)
	ep6 = tplot_time_to_epoch(spec6.x,/epoch16)

	datatimes = spec0.x


	;Get the time structure for the flag values. These are not necessarily at the cadence
	;of physical data.
	epoch_flag_times,date,5,epoch_qual,timevals



;Get all the flag values
        flag_str = rbsp_efw_get_flag_values(sc,timevals,boom_pair=bp)


        flag_arr = flag_str.flag_arr
        bias_sweep_flag = flag_str.bias_sweep_flag
        ab_flag = flag_str.ab_flag
        charging_flag = flag_str.charging_flag
        ibias = flag_str.ibias


        get_data,'rbsp'+sc+'_density',data=dens






	;Rename the skeleton file
	filename = 'rbsp'+sc+'_efw-l2_spec_'+strjoin(strsplit(date,'-',/extract))+'_'+version+'.cdf'
	file_copy,source_file,folder+filename,/overwrite

	;Open the new skeleton file
	cdfid = cdf_open(folder+filename)
	cdf_control, cdfid, get_var_info=info, variable='epoch'



	cdf_varput,cdfid,'epoch',ep0
	cdf_varput,cdfid,'epoch_qual',epoch_qual
	cdf_varput,cdfid,'efw_qual',transpose(flag_arr)

	if is_struct(spec0) then cdf_varput,cdfid,'spec'+bins+'_'+chn0,transpose(spec0.y)
	if is_struct(spec1) then cdf_varput,cdfid,'spec'+bins+'_'+chn1,transpose(spec1.y)
	if is_struct(spec2) then cdf_varput,cdfid,'spec'+bins+'_'+chn2,transpose(spec2.y)
	if is_struct(spec3) then cdf_varput,cdfid,'spec'+bins+'_'+chn3,transpose(spec3.y)
	if is_struct(spec4) then cdf_varput,cdfid,'spec'+bins+'_'+chn4,transpose(spec4.y)
	if is_struct(spec5) then cdf_varput,cdfid,'spec'+bins+'_'+chn5,transpose(spec5.y)
	if is_struct(spec6) then cdf_varput,cdfid,'spec'+bins+'_'+chn6,transpose(spec6.y)



	cdf_close, cdfid

	dprint,'END TIME IS: ',systime()


	store_data,tnames(),/delete

;Load the newly filled CDF structure to see if it works
if ~skip_plot then begin
	cdf_leap_second_init
	cdf2tplot,files=folder + filename

	zlim,1,1d-3^2,1d-1^2,1
	ylim,[1,2,3,4,5,6,7],1,10000,1

	zlim,[1,2,3,4,5,6,7],1d-3^2,1d-1^2,1


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

	ylim,1,1,10000,1
	zlim,1,0.001,10,1

	tplot,[1,4,5]

endif


end
