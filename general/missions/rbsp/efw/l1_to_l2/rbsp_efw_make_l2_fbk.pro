;+
;
;rbsp_efw_make_l2_fbk
;
;Creates the RBSP (Van Allen probes) L2 CDF file
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
;Written by:
;	Aaron Breneman, UNN, Feb 2013
;		email: awbrenem@gmail.com
;
; History:
;	2013-04-25 - mostly written
; 2020-Jan - huge efficiency update for Phase F
;
; VERSION:
;	$LastChangedBy: aaronbreneman $
;	$LastChangedDate: 2020-01-03 11:34:05 -0800 (Fri, 03 Jan 2020) $
;	$LastChangedRevision: 28158 $
;	$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_fbk.pro $
;
;-

pro rbsp_efw_make_l2_fbk,sc,date,$
  folder=folder,$
  testing=testing,$
  boom_pair=bp,$
  version=version



  ;Initialize variables
  rbsp_efw_init
  if ~KEYWORD_SET(bp) then bp = '12'

  sc=strlowcase(sc)
  if sc ne 'a' and sc ne 'b' then begin
     dprint,'Invalid spacecraft: '+sc+', returning.'
     return
  endif
  rbspx = 'rbsp'+sc


  if ~KEYWORD_SET(version) then version = 1
  vstr = string(version, format='(I02)')
  ;version = 'v'+vstr


  ;Load some data
  timespan,date



  dprint,'BEGIN TIME IS ',systime()



  if ~keyword_set(folder) then folder ='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'
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




  ;use skeleton from the staging dir until we go live in the main data tree
  ;source_file='/Volumes/DataA/user_volumes/kersten/data/rbsp/'+skeleton


  ;make sure we have the skeleton CDF
  source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
  if ~found then begin
     dprint,'Could not find fbk v01 skeleton CDF, returning.'
     return
  endif


  ;fix single element source file array
  source_file=source_file[0]


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




  ;Determine the type and source channels of the data
  if is_struct(dlim13_fb1) then type = 'fbk13' else type = 'fbk7'


  if type eq 'fbk13' then begin
    source_fb1 = dlim13_fb1.data_att.channel
    source_fb2 = dlim13_fb2.data_att.channel
  endif else begin
    source_fb1 = dlim7_fb1.data_att.channel
    source_fb2 = dlim7_fb2.data_att.channel
  endelse



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
  if is_struct(fbk13_pk_fb1) then epoch_fbk = tplot_time_to_epoch(fbk13_pk_fb1.x,/epoch16)
  if is_struct(fbk7_pk_fb1) then  epoch_fbk = tplot_time_to_epoch(fbk7_pk_fb1.x,/epoch16)



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



  ;Get list of all the variable names in the CDF file.
  inq = cdf_inquire(cdfid)
  CDFvarnames = ''
  for varNum = 0, inq.nzvars-1 do begin $
    stmp = cdf_varinq(cdfid,varnum,/zvariable) & $
    if stmp.recvar eq 'VARY' then CDFvarnames = [CDFvarnames,stmp.name]
  endfor
  CDFvarnames = CDFvarnames[1:n_elements(CDFvarnames)-1]



  ;------------------------------
  ;Populate the CDF variables
  ;------------------------------

  if type eq 'fbk7' then begin

    varname1 = 'fbk7_'+strlowcase(source_fb1)+'_'
    varname2 = 'fbk7_'+strlowcase(source_fb2)+'_'


    cdf_varput,cdfid,'epoch',epoch_fbk
    cdf_varput,cdfid,'epoch_qual',epoch_qual
    cdf_varput,cdfid,'efw_qual',transpose(flag_arr)

    if is_struct(fbk7_pk_fb1) then begin
      cdf_varput,cdfid,varname1+'pk',transpose(fbk7_pk_fb1.y)
      cdf_varput,cdfid,varname1+'av',transpose(fbk7_av_fb1.y)
    endif
    if is_struct(fbk7_pk_fb2) then begin
      cdf_varput,cdfid,varname2+'pk',transpose(fbk7_pk_fb2.y)
      cdf_varput,cdfid,varname2+'av',transpose(fbk7_av_fb2.y)
    endif

  endif



  if type eq 'fbk13' then begin

    varname1 = 'fbk13_'+strlowcase(source_fb1)+'_'
    varname2 = 'fbk13_'+strlowcase(source_fb2)+'_'


    cdf_varput,cdfid,'epoch',epoch_fbk
    cdf_varput,cdfid,'epoch_qual',epoch_qual
    cdf_varput,cdfid,'efw_qual',transpose(flag_arr)


    if is_struct(fbk13_pk_fb1) then begin
      cdf_varput,cdfid,varname1+'pk',transpose(fbk13_pk_fb1.y)
      cdf_varput,cdfid,varname1+'av',transpose(fbk13_av_fb1.y)
    endif
    if is_struct(fbk13_pk_fb2) then begin
      cdf_varput,cdfid,varname2+'pk',transpose(fbk13_pk_fb2.y)
      cdf_varput,cdfid,varname2+'av',transpose(fbk13_av_fb2.y)
    endif

  endif




  ;--------------------------------------------------
  ; Now delete unused CDF variables
  ;--------------------------------------------------

  for q=0,n_elements(CDFvarnames)-1 do begin
    cond1 = (CDFvarnames[q] eq varname1+'pk') or (CDFvarnames[q] eq varname1+'av')
    cond2 = (CDFvarnames[q] eq varname2+'pk') or (CDFvarnames[q] eq varname2+'av')
    cond3 = cond1 or cond2
    tmp = strmid(CDFvarnames[q],0,5)
    cond4 = tmp eq 'fbk13' or tmp eq 'fbk7_'
    if not cond3 and cond4 then cdf_vardelete,cdfid,CDFvarnames[q]
  endfor




  cdf_close, cdfid

  dprint,'END TIME IS: ',systime()

  store_data,tnames(),/delete


end
