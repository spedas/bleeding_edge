;+
;
;rbsp_efw_make_l2_fbk
;
;Loads and plots RBSP (Van Allen probes) filterbank data
;used to create the L2 CDF file
;
;note: Source selects for the Filter Bank:
;		0=E12DC
;		1=E34DC
;		2=E56DC
;		3=E12AC
;		4=E34AC
;		5=E56AC
;		6=SCMU
;		7=SCMV
;		8=SCMW
;		9=(V1DC+V2DC+V3DC+V4DC)/4
;		(default is 0)
;
;
;KEY: fbk7 bin width (Hz):
;	0.8-1.5, 3-6, 12-25, 50-100, 200-400, 800-1.6k, 3.2-6.5k
;
;KEY: fbk13 bin width (Hz):
;	0.8-1.5, 1.5-3, 3-6, 6-12, 12-25, 25-50, 50-100, 100-200,
;	200-400, 400-800, 800-1.6k, 1.6k-3.2k, 3.2-6.5k
;
;
;
;
;Written by:
;	Aaron Breneman, UNN, Feb 2013
;		email: awbrenem@gmail.com
;
; History:
;	2013-04-25 - mostly written
;
;
; VERSION:
;	$LastChangedBy: aaronbreneman $
;	$LastChangedDate: 2016-08-12 11:21:58 -0700 (Fri, 12 Aug 2016) $
;	$LastChangedRevision: 21640 $
;	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_fbk.pro $
;
;-

pro rbsp_efw_make_l2_fbk,sc,date,folder=folder,testing=testing,boom_pair=bp,$
    version=version

  rbsp_efw_init
  skip_plot = 1                 ;set to skip restoration of cdf file and test plotting at end of program

  if ~KEYWORD_SET(bp) then bp = '12'

  dprint,'BEGIN TIME IS ',systime()

  if ~KEYWORD_SET(version) then version = 1
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

  ; Grab the skeleton file (always use V01 skeleton. V02 files have all the unnecesary fields removed in final CDF)
  skeleton=rbspx+'/l2/fbk/0000/'+ $
           rbspx+'_efw-l2_fbk_00000000_v01.cdf'
  source_file=file_retrieve(skeleton,_extra=!rbsp_efw)


  if keyword_set(testing) then begin
     skeleton = 'rbspa_efw-l2_fbk_00000000_v01.cdf'
     source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/' + skeleton
  endif




                                ; use skeleton from the staging dir until we go live in the main data tree
                                ;source_file='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton

                                ; make sure we have the skeleton CDF
  source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
  if ~found then begin
     dprint,'Could not find fbk v01 skeleton CDF, returning.'
     return
  endif
                                ; fix single element source file array
  source_file=source_file[0]

                                ;Load some data
  timespan,date

                                ;Load the filterbank data
  rbsp_load_efw_fbk,probe=sc,type='calibrated'
  get_data,rbspx+'_efw_fbk_13_fb1_pk',data=fbk13_pk_fb1,dlimits=dlim13_fb1
  get_data,rbspx+'_efw_fbk_13_fb2_pk',data=fbk13_pk_fb2,dlimits=dlim13_fb2
  get_data,rbspx+'_efw_fbk_7_fb1_pk',data=fbk7_pk_fb1,dlimits=dlim7_fb1
  get_data,rbspx+'_efw_fbk_7_fb2_pk',data=fbk7_pk_fb2,dlimits=dlim7_fb2

  get_data,rbspx+'_efw_fbk_13_fb1_av',data=fbk13_av_fb1
  get_data,rbspx+'_efw_fbk_13_fb2_av',data=fbk13_av_fb2
  get_data,rbspx+'_efw_fbk_7_fb1_av',data=fbk7_av_fb1
  get_data,rbspx+'_efw_fbk_7_fb2_av',data=fbk7_av_fb2





                                ;Determine the source of the data

  if is_struct(dlim13_fb1) then source13_fb1 = dlim13_fb1.data_att.channel else source13_fb1 = ''
  if is_struct(dlim13_fb2) then source13_fb2 = dlim13_fb2.data_att.channel else source13_fb2 = ''
  if is_struct(dlim7_fb1) then source7_fb1 = dlim7_fb1.data_att.channel else source7_fb1 = ''
  if is_struct(dlim7_fb2) then source7_fb2 = dlim7_fb2.data_att.channel else source7_fb2 = ''




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






                                ;Make the time string

  if is_struct(fbk13_pk_fb1) then times13 = fbk13_pk_fb1.x
  if is_struct(fbk7_pk_fb1) then times7 = fbk7_pk_fb1.x


  if is_struct(fbk13_pk_fb1) then epoch_fbk13 = tplot_time_to_epoch(times13,/epoch16)
  if is_struct(fbk7_pk_fb1) then epoch_fbk7 = tplot_time_to_epoch(times7,/epoch16)


  if is_struct(fbk13_pk_fb1) then datatimes = fbk13_pk_fb1.x
  if is_struct(fbk7_pk_fb1)  then datatimes = fbk7_pk_fb1.x



                                ;Rename the skeleton file
  filename = 'rbsp'+sc+'_efw-l2_fbk_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'.cdf'
  file_copy,source_file,folder+filename,/overwrite



                                ;Eliminate structures with zero data in them. This prevents the overwriting (below) of
                                ;good data with bad data

  if is_struct(fbk7_pk_fb1) then if total(fbk7_pk_fb1.y,/nan) eq 0. then fbk7_pk_fb1 = 0.
  if is_struct(fbk7_av_fb1) then if total(fbk7_av_fb1.y,/nan) eq 0. then fbk7_av_fb1 = 0.
  if is_struct(fbk7_pk_fb2) then if total(fbk7_pk_fb2.y,/nan) eq 0. then fbk7_pk_fb2 = 0.
  if is_struct(fbk7_av_fb2) then if total(fbk7_av_fb2.y,/nan) eq 0. then fbk7_av_fb2 = 0.

  if is_struct(fbk13_pk_fb1) then if total(fbk13_pk_fb1.y,/nan) eq 0. then fbk13_pk_fb1 = 0.
  if is_struct(fbk13_av_fb1) then if total(fbk13_av_fb1.y,/nan) eq 0. then fbk13_av_fb1 = 0.
  if is_struct(fbk13_pk_fb2) then if total(fbk13_pk_fb2.y,/nan) eq 0. then fbk13_pk_fb2 = 0.
  if is_struct(fbk13_av_fb2) then if total(fbk13_av_fb2.y,/nan) eq 0. then fbk13_av_fb2 = 0.



  cdfid = cdf_open(folder+filename)
  cdf_control, cdfid, get_var_info=info, variable='epoch'

  if is_struct(fbk7_pk_fb1) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk7
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source7_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_pk',transpose(fbk7_pk_fb1.y)
     if source7_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_pk',transpose(fbk7_pk_fb1.y)

  endif


  if is_struct(fbk7_av_fb1) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk7
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source7_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_av',transpose(fbk7_av_fb1.y)
     if source7_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_av',transpose(fbk7_av_fb1.y)

  endif


  if is_struct(fbk7_pk_fb2) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk7
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source7_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_pk',transpose(fbk7_pk_fb2.y)
     if source7_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_pk',transpose(fbk7_pk_fb2.y)

  endif


  if is_struct(fbk7_av_fb2) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk7
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source7_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk7_e12dc_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk7_e12ac_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk7_e34dc_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk7_e34ac_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk7_e56dc_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk7_e56ac_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk7_scmu_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk7_scmv_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk7_scmw_av',transpose(fbk7_av_fb2.y)
     if source7_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk7_v1v1v3v4_avg_ac_av',transpose(fbk7_av_fb2.y)

  endif


  if is_struct(fbk13_pk_fb1) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk13
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source13_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_pk',transpose(fbk13_pk_fb1.y)
     if source13_fb1 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_pk',transpose(fbk13_pk_fb1.y)

  endif


  if is_struct(fbk13_av_fb1) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk13
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source13_fb1 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_av',transpose(fbk13_av_fb1.y)
     if source13_fb1 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_av',transpose(fbk13_av_fb1.y)

  endif




  if is_struct(fbk13_pk_fb2) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk13
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source13_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_pk',transpose(fbk13_pk_fb2.y)
     if source13_fb2 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_pk',transpose(fbk13_pk_fb2.y)

  endif


  if is_struct(fbk13_av_fb2) then begin

     cdf_varput,cdfid,'epoch',epoch_fbk13
     cdf_varput,cdfid,'epoch_qual',epoch_qual
     cdf_varput,cdfid,'efw_qual',transpose(flag_arr)
     if source13_fb2 eq 'E12DC' then cdf_varput,cdfid,'fbk13_e12dc_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'E12AC' then cdf_varput,cdfid,'fbk13_e12ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'E34DC' then cdf_varput,cdfid,'fbk13_e34dc_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'E34AC' then cdf_varput,cdfid,'fbk13_e34ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'E56DC' then cdf_varput,cdfid,'fbk13_e56dc_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'E56AC' then cdf_varput,cdfid,'fbk13_e56ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'EparDC' then cdf_varput,cdfid,'fbk13_epardc_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'Eperp1DC' then cdf_varput,cdfid,'fbk13_eperp1dc_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'EparAC' then cdf_varput,cdfid,'fbk13_eparac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'Eperp1AC' then cdf_varput,cdfid,'fbk13_eperp1ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V1AC' then cdf_varput,cdfid,'fbk13_v1ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V2AC' then cdf_varput,cdfid,'fbk13_v2ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V3AC' then cdf_varput,cdfid,'fbk13_v3ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V4AC' then cdf_varput,cdfid,'fbk13_v4ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V5AC' then cdf_varput,cdfid,'fbk13_v5ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V6AC' then cdf_varput,cdfid,'fbk13_v6ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'SCMU' then cdf_varput,cdfid,'fbk13_scmu_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'SCMV' then cdf_varput,cdfid,'fbk13_scmv_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'SCMW' then cdf_varput,cdfid,'fbk13_scmw_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'SCMpar' then cdf_varput,cdfid,'fbk13_scmpar_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'SCMperp1' then cdf_varput,cdfid,'fbk13_scmperp1_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'V1V2V3V4_AVG_AC' then cdf_varput,cdfid,'fbk13_v1v1v3v4_avg_ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'Eperp2DC' then cdf_varput,cdfid,'fbk13_eperp2dc_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'Eperp2AC' then cdf_varput,cdfid,'fbk13_eperp2ac_av',transpose(fbk13_av_fb2.y)
     if source13_fb2 eq 'SCMperp2' then cdf_varput,cdfid,'fbk13_scmperp2_av',transpose(fbk13_av_fb2.y)

  endif



;;--------------------------------------------------
;; Now delete unused fields
;;--------------------------------------------------


  ;;delete all FBK7 variables if we're using FBK13
  if source7_fb1 eq '' and source7_fb2 eq '' then begin
     cdf_vardelete,cdfid,'fbk7_e12dc_pk'
     cdf_vardelete,cdfid,'fbk7_e12ac_pk'
     cdf_vardelete,cdfid,'fbk7_e34dc_pk'
     cdf_vardelete,cdfid,'fbk7_e34ac_pk'
     cdf_vardelete,cdfid,'fbk7_e56dc_pk'
     cdf_vardelete,cdfid,'fbk7_e56ac_pk'
     cdf_vardelete,cdfid,'fbk7_scmu_pk'
     cdf_vardelete,cdfid,'fbk7_scmv_pk'
     cdf_vardelete,cdfid,'fbk7_scmw_pk'
     cdf_vardelete,cdfid,'fbk7_v1v2v3v4_avg_pk'
     cdf_vardelete,cdfid,'fbk7_e12dc_av'
     cdf_vardelete,cdfid,'fbk7_e12ac_av'
     cdf_vardelete,cdfid,'fbk7_e34dc_av'
     cdf_vardelete,cdfid,'fbk7_e34ac_av'
     cdf_vardelete,cdfid,'fbk7_e56dc_av'
     cdf_vardelete,cdfid,'fbk7_e56ac_av'
     cdf_vardelete,cdfid,'fbk7_scmu_av'
     cdf_vardelete,cdfid,'fbk7_scmv_av'
     cdf_vardelete,cdfid,'fbk7_scmw_av'
     cdf_vardelete,cdfid,'fbk7_v1v2v3v4_avg_av'
  endif else begin
     ;;delete all FBK13 variables if we're using FBK7
     cdf_vardelete,cdfid,'fbk13_e12dc_pk'
     cdf_vardelete,cdfid,'fbk13_e12ac_pk'
     cdf_vardelete,cdfid,'fbk13_e34dc_pk'
     cdf_vardelete,cdfid,'fbk13_e34ac_pk'
     cdf_vardelete,cdfid,'fbk13_e56dc_pk'
     cdf_vardelete,cdfid,'fbk13_e56ac_pk'
     cdf_vardelete,cdfid,'fbk13_scmu_pk'
     cdf_vardelete,cdfid,'fbk13_scmv_pk'
     cdf_vardelete,cdfid,'fbk13_scmw_pk'
     cdf_vardelete,cdfid,'fbk13_v1v2v3v4_avg_pk'
     cdf_vardelete,cdfid,'fbk13_e12dc_av'
     cdf_vardelete,cdfid,'fbk13_e12ac_av'
     cdf_vardelete,cdfid,'fbk13_e34dc_av'
     cdf_vardelete,cdfid,'fbk13_e34ac_av'
     cdf_vardelete,cdfid,'fbk13_e56dc_av'
     cdf_vardelete,cdfid,'fbk13_e56ac_av'
     cdf_vardelete,cdfid,'fbk13_scmu_av'
     cdf_vardelete,cdfid,'fbk13_scmv_av'
     cdf_vardelete,cdfid,'fbk13_scmw_av'
     cdf_vardelete,cdfid,'fbk13_v1v2v3v4_avg_av'
  endelse




  ;; Now delete unused FBK13 variables

  sources = ['E12DC','E12AC','E34DC','E34AC','E56DC','E56AC',$
                      'SCMU','SCMV','SCMW','V1V2V3V4_AVG_AC']


  if source7_fb1 eq '' and source7_fb2 eq '' then begin

     fbk13_vars = ['fbk13_e12dc','fbk13_e12ac','fbk13_e34dc','fbk13_e34ac',$
                   'fbk13_e56dc','fbk13_e56ac','fbk13_scmu',$
                   'fbk13_scmv','fbk13_scmw','fbk13_v1v2v3v4_avg']

     goo = where(sources eq source13_fb1)
     if goo[0] ne -1 then sources[goo[0]] = ''
     goo = where(sources eq source13_fb2)
     if goo[0] ne -1 then sources[goo[0]] = ''

     for jj=0,n_elements(sources)-1 do if sources[jj] ne '' then cdf_vardelete,cdfid,fbk13_vars[jj]+'_av'
     for jj=0,n_elements(sources)-1 do if sources[jj] ne '' then cdf_vardelete,cdfid,fbk13_vars[jj]+'_pk'

  endif else begin

     fbk7_vars = ['fbk7_e12dc','fbk7_e12ac','fbk7_e34dc','fbk7_e34ac',$
                   'fbk7_e56dc','fbk7_e56ac','fbk7_scmu',$
                   'fbk7_scmv','fbk7_scmw','fbk7_v1v2v3v4_avg']


     goo = where(sources eq source7_fb1)
     if goo[0] ne -1 then sources[goo[0]] = ''
     goo = where(sources eq source7_fb2)
     if goo[0] ne -1 then sources[goo[0]] = ''

     for jj=0,n_elements(sources)-1 do if sources[jj] ne '' then cdf_vardelete,cdfid,fbk7_vars[jj] + '_pk'
     for jj=0,n_elements(sources)-1 do if sources[jj] ne '' then cdf_vardelete,cdfid,fbk7_vars[jj] + '_av'

  endelse




  cdf_close, cdfid

  dprint,'END TIME IS: ',systime()

  store_data,tnames(),/delete



                                ;Load the newly filled CDF structure to see if it works
  if ~skip_plot then begin
     cdf_leap_second_init
     cdf2tplot,files=folder + filename


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
              'autobias',$
              'charging',$
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
