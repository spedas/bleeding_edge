;+
; NAME:
;   rbsp_efw_make_l2_vsvy_hires
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
; EXAMPLES:	rbsp_efw_make_l2_vsvy_hires,'a','2012-10-13'
;
; NOTES: This program stuffs the following quantities into the skeleton CDF file.
;		V1-V6 -> single-ended potential quantities
;		(Vx+Vy)/2 -> opposing boom averages
;
;
; HISTORY:
;   March 2020: Created by Aaron Breneman, University of Minnesota
;
;
; VERSION:
;	$LastChangedBy: aaronbreneman $
;	$LastChangedDate: 2020-07-08 08:38:26 -0700 (Wed, 08 Jul 2020) $
;	$LastChangedRevision: 28864 $
; 	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_make_l2_vsvy_hires.pro $
;-


;****NOTE: UPDATE THIS FOR PHASE F


pro rbsp_efw_make_l2_vsvy_hires,sc,date,$
	folder=folder,$
	version=version,$
	testing=testing


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
	rbx = 'rbsp' + strlowcase(sc[0]) + '_'



		year = strmid(date, 0, 4)

	if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
																				'rbsp' + strlowcase(sc[0]) + path_sep() + $
																				'l2' + path_sep() + $
																				'spinfit' + path_sep() + $
																				year + path_sep()

	; make sure we have the trailing slash on folder
	if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
	if ~keyword_set(no_cdf) then file_mkdir, folder


	;Grab skeleton file
	skeleton='/Volumes/UserA/user_homes/rbsp_efw/Code/tdas_svn_daily/general/missions/rbsp/efw/l1_to_l2/'+rbx+'efw-l2_00000000_vXX.cdf'
	if ~keyword_set(testing) then begin
		skeletonfile=file_search(skeleton,count=found)
		if ~found then begin
	     dprint,'Could not find skeleton CDF, returning.'
	     return
	  endif
	endif

	if keyword_set(testing) then $
		 skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbsp'+$
										sc+'_efw-l2_00000000_vXX.cdf'



	skeletonFile=skeletonFile[0]

	if keyword_set(testing) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'



	;Load some data
	timespan,date

	;Load the survey data
	rbsp_load_efw_waveform,probe=sc,type='calibrated',datatype='vsvy',/noclean
	get_data,rbx+'efw_vsvy',data=vsvy
	if ~is_struct(vsvy) then begin
  		dprint,rbx+'efw_vsvy unavailable, returning.'
  		return
	endif



	times_v = vsvy.x

;	;Not ready to release the V5, V6 values.
;	vsvy.y[*,4] = -1.0e31
;	vsvy.y[*,5] = -1.0e31


;Define keyword inheritance to pass to subroutines. This will ensure that
;subsequent routines don't reload spice kernels or rbsp_efw_init
;extra = create_struct('no_rbsp_efw_init',1)

;****
;	rbsp_efw_position_velocity_crib,probe=sc,/noplot;,_extra=extra
;****

;Load ECT's magnetic ephemeris
rbsp_read_ect_mag_ephem,sc





	cdf2tplot,'~/Desktop/rbspa_spice_products_2014_0101_v01.cdf'
;	1 rbspa_eu_wake_flag
;	2 rbspa_eu_fixed
;	3 rbspa_ev_wake_flag
;	4 rbspa_ev_fixed
;	5 pos_gsm
;	6 mlt
;	7 mlat
;	8 dis
;	9 lshell
; 10 q_uvw2gsm

	copy_data,rbx+'ME_pos_gse',rbx+'state_pos_gse'
	copy_data,rbx+'ME_mlat_eccdipole',rbx+'state_mlat'
	copy_data,rbx+'ME_mlt_eccdipole',rbx+'state_mlt'
	copy_data,rbx+'ME_lshell',rbx+'state_lshell'


;	rbspa_ME_lshell
;	copy_data,'lshell',rbx+'state_lshell'
;	copy_data,'q_uvw2gsm',rbx+'state_q_uvw2gsm'


;rbsp_cotrans,rbx+'state_pos_gsm','tst_gse',/gsm2gse




	get_data,rbx+'state_mlt',data=tmp
  times = tmp.x
  epoch = tplot_time_to_epoch(times,/epoch16)








	;Downsample the GSE position and velocity variables to cadence of spinfit data
	varstmp = [rbx+'state_pos_gse',$
						rbx+'state_vel_gse',$
						rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
						rbx+'ME_orbitnumber',rbx+'spinaxis_direction_gse']

	for qq=0,n_elements(varstmp)-1 do tinterpol_mxn,varstmp[qq],times,newname=varstmp[qq],/spline




	;get_data,'vxb',data=vxb
	get_data,rbx+'state_pos_gse',data=pos_gse
	get_data,rbx+'state_vel_gse',data=vel_gse
	get_data,rbx+'spinaxis_direction_gse',data=sa
	;get_data,'angles',data=angles
	get_data,rbx+'state_mlt',data=mlt
	get_data,rbx+'state_mlat',data=mlat
	get_data,rbx+'state_lshell',data=lshell
	;get_data,rbx+'ME_lshell',data=lshell
	get_data,rbx+'ME_orbitnumber',data=orbit_num



;dif_data,'rbspa_ME_pos_gse','rbspa_state_pos_gse',newname='posdiffgse'
;tplot,['posdiffgse','rbspa_ME_pos_gse','rbspa_state_pos_gse']


;dif_data,'rbspa_ME_pos_gsm','rbspa_state_pos_gsm',newname='posdiffgsm'
;tplot,['posdiffgsm','rbspa_ME_pos_gsm','rbspa_state_pos_gsm']

stop


	if is_struct(orbit_num) then orbit_num = orbit_num.y else orbit_num = replicate(-1.e31,n_elements(times))







  ;--------------------------------------------------
  ;Get flag values (also gets density values from v12 and v34)
  ;--------------------------------------------------

stop

   flag_str = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair=bp,_extra=extra)

   flag_arr = flag_str.flag_arr
   bias_sweep_flag = flag_str.bias_sweep_flag
   ab_flag = flag_str.ab_flag
   charging_flag = flag_str.charging_flag
;   ibias = flag_str.ibias





	;Create average values of opposing antennas
	v1v2 = 0.5*(vsvy.y[*,0] + vsvy.y[*,1])
	v3v4 = 0.5*(vsvy.y[*,2] + vsvy.y[*,3])
	v5v6 = 0.5*(vsvy.y[*,4] + vsvy.y[*,5])


;	;not ready to release V5 or V6 values
;	v5v6[*] = -1.0e31


;;*****TEMPORARY********
;;Set bad vavg values to ISTP compliant value of -1.0E31
;goo = where((finite(vsvy.y[*,0]) eq 0) or (finite(vsvy.y[*,1]) eq 0))
;if goo[0] ne -1 then v1v2[goo] = -1.0e31
;goo = where((finite(vsvy.y[*,2]) eq 0) or (finite(vsvy.y[*,3]) eq 0))
;if goo[0] ne -1 then v3v4[goo] = -1.0e31
;;**********************



	vsvy_vavg = [[v1v2],[v3v4],[v5v6]]

	epoch_v = tplot_time_to_epoch(times_v,/epoch16)

;;;charging, autobias, eclipse, and extreme charging flags all in one variable for convenience
;flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]],[flag_arr[*,16]]]



	;Stuff values into the cdf skeleton structure

	year = strmid(date,0,4) & mm = strmid(date,5,2) & dd = strmid(date,8,2)
  datafile = folder+rbx+'efw-l2_vsvy-hires_'+year+mm+dd+'_v'+vstr+'.cdf'
  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.
  cdfid = cdf_open(datafile)





	;Final list of variables to NOT delete
	varsave_general = ['epoch','epoch_v','vsvy','vsvy_vavg','flags_all',$
	'mlt','mlat','lshell','position_gse','velocity_gse','orbit_num']
;	'flags_charging_bias_eclipse']


	;Now that we have renamed some of the variables to our liking,
	;get list of all the variable names in the CDF file.
	inq = cdf_inquire(cdfid)
	CDFvarnames = ''
	for varNum = 0, inq.nzvars-1 do begin $
		stmp = cdf_varinq(cdfid,varnum,/zvariable) & $
		if stmp.recvar eq 'VARY' then CDFvarnames = [CDFvarnames,stmp.name]
	endfor
	CDFvarnames = CDFvarnames[1:n_elements(CDFvarnames)-1]


	;Delete all variables we don't want to save.
	for qq=0,n_elements(CDFvarnames)-1 do begin $
		tstt = array_contains(varsave_general,CDFvarnames[qq]) & $
		if not tstt then print,'Deleting var:  ', CDFvarnames[qq] & $
		if not tstt then cdf_vardelete,cdfid,CDFvarnames[qq]
	endfor



	cdf_varput,cdfid,'epoch',epoch
	cdf_varput,cdfid,'epoch_v',epoch_v
	cdf_varput,cdfid,'vsvy',transpose(vsvy.y)
	cdf_varput,cdfid,'vsvy_vavg',transpose(vsvy_vavg)

	;*****THIS CDF VAR IS ON "EPOCH" CADENCE. BUT, FLAG_ARR IS ON "EPOCH_V" CADENCE
	cdf_varput,cdfid,'flags_all',transpose(flag_arr)

	cdf_varput,cdfid,'mlt',transpose(mlt.y)
  cdf_varput,cdfid,'mlat',transpose(mlat.y)
  cdf_varput,cdfid,'lshell',transpose(lshell.y)
  cdf_varput,cdfid,'position_gse',transpose(pos_gse.y)
  cdf_varput,cdfid,'velocity_gse',transpose(vel_gse.y)
  cdf_varput,cdfid,'orbit_num',orbit_num




	cdf_close, cdfid

	dprint,'END TIME IS: ',systime()

	store_data,tnames(),/delete

end
