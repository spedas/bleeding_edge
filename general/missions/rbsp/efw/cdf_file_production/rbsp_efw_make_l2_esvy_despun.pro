;+
; NAME:
;   rbsp_efw_make_l2_esvy_despun
;
; PURPOSE:
;   Generate level-2 EFW CDF files
;
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l2_esvy_despun, sc, date
;
; ARGUMENTS:
;   sc: IN, REQUIRED
;         'a' or 'b'
;   date: IN, REQUIRED
;         A date string in format like '2013-02-13'
;
; KEYWORDS:
;   folder: IN, OPTIONAL
;         Default is something like
;           !rbsp_efw.local_data_dir/rbspa/l2/spinfit/2012/
;
; 
;
; HISTORY:
;   2014-12-02: Created by Aaron W Breneman, U. Minnesota
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2020-07-08 08:38:26 -0700 (Wed, 08 Jul 2020) $
; $LastChangedRevision: 28864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_make_l2_esvy_despun.pro $
;
;-


;***NOTE: UPDATE THIS FOR PHASE F

pro rbsp_efw_make_l2_esvy_despun,sc,date,$
  folder=folder,$
  version = version,$
  save_flags = save_flags,$
  no_cdf = no_cdf,$
  testing=testing,$
  boom_pair=bp,$
  density_min=dmin,$
  bad_probe=bad_probe


  if ~keyword_set(dmin) then dmin = 10.


  if ~keyword_set(testing) then begin
     openw,lun,'output.txt',/get_lun
     printf,lun,'date = ',date
     printf,lun,'date type: ',typename(date)
     printf,lun,'probe = ',sc
     printf,lun,'probe type: ',typename(sc)
     printf,lun,'bp = ',bp
     printf,lun,'bp type: ',typename(bp)
     close,lun
     free_lun,lun
  endif

  compile_opt idl2


  timespan,date


  ;Clean slate
  store_data,tnames(),/delete




  ;Only download if you don't have the file locally
  extra_spicelocation = create_struct('local_spice_only_if_exist_locally',1)


  ;Initial (and only) load of these
  rbsp_load_spice_kernels,_extra=extra_spicelocation
  rbsp_efw_init


  ;Define keyword inheritance to pass to subroutines. This will ensure that
  ;subsequent routines don't reload spice kernels or rbsp_efw_init
  extra = create_struct('no_spice_load',1,$
                        'no_rbsp_efw_init',1,$
                        'sheng_cdf',1)



  if n_elements(version) eq 0 then version = 2
  vstr = string(version, format='(I02)')

  rbx = 'rbsp' + strlowcase(sc[0]) + '_'


;------------ Set up paths. BEGIN. ----------------------------

  if ~keyword_set(no_cdf) then begin

     year = strmid(date, 0, 4)

     if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                           'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                           'l2' + path_sep() + $
                                           'spinfit' + path_sep() + $
                                           year + path_sep()

                                ; make sure we have the trailing slash on folder
     if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
     if ~keyword_set(no_cdf) then file_mkdir, folder



                                ; Grab the skeleton file.
;     skeleton='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+rbspx+'_efw-l2_00000000_v02.cdf'
     skeleton='/Volumes/UserA/user_homes/kersten/Code/tdas_svn_daily/general/missions/rbsp/efw/l1_to_l2/'+rbx+'efw-l2_00000000_vXX.cdf'

     found = 1
                                ; make sure we have the skeleton CDF
     if ~keyword_set(testing) then skeletonFile=file_search(skeleton,count=found)
     if keyword_set(testing) then $
        skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbsp'+$
                       sc+'_efw-l2_00000000_vXX.cdf'


     if ~found then begin
        dprint,'Could not find skeleton CDF, returning.'
        return
     endif
                                ; fix single element source file array
     skeletonFile=skeletonFile[0]

  endif

  if keyword_set(testing) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'



;------------ Set up paths. END. ----------------------------



  ;despin the Efield data and put in MGSE
  ;Load the vxb subtracted data. If there isn't any vxb subtracted data
  ;then grab the regular Esvy MGSE data
  rbsp_efw_vxb_subtract_crib,sc,/noplot,bad_probe=bad_probe,_extra=extra

stop

  get_data,rbx+'efw_esvy_mgse_vxb_removed',data=esvy_vxb_mgse
  epoch_e = tplot_time_to_epoch(esvy_vxb_mgse.x,/epoch16)
  times_e = esvy_vxb_mgse.x

  get_data,rbx+'state_mlt',data=tmp
  times = tmp.x
  epoch = tplot_time_to_epoch(times,/epoch16)


  ;Load ECT's magnetic ephemeris
  rbsp_read_ect_mag_ephem,sc





  ;--------------------------------------------------
  ;Get flag values (also gets density values from v12 and v34)
  ;--------------------------------------------------


   flag_str = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair=bp,_extra=extra)

   flag_arr = flag_str.flag_arr
   bias_sweep_flag = flag_str.bias_sweep_flag
   ab_flag = flag_str.ab_flag
   charging_flag = flag_str.charging_flag





  ;--------------------------------------------------
  ;Nan out various values when global flag is thrown
  ;--------------------------------------------------

;******************
;NOTE: fill this out
;******************


  ;--------------------------------------------------
  ;Set a 3D flag variable for the survey plots
  ;--------------------------------------------------

     ;;charging, autobias, eclipse, and extreme charging flags all in one variable for convenience
     flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]],[flag_arr[*,16]]]




     ;Downsample the GSE position and velocity variables to cadence of spinfit data
     varstmp = [rbx+'state_vel_coro_mgse',rbx+'state_pos_gse',$
     rbx+'state_vel_gse',$
     rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
     rbx+'ME_orbitnumber',rbx+'spinaxis_direction_gse']

     for qq=0,n_elements(varstmp)-1 do tinterpol_mxn,varstmp[qq],times,newname=varstmp[qq],/spline




     ;get_data,'vxb',data=vxb
     get_data,rbx+'state_pos_gse',data=pos_gse
     get_data,rbx+'state_vel_gse',data=vel_gse
;     get_data,rbx+'E_coro_mgse',data=ecoro_mgse
     get_data,rbx+'state_vel_coro_mgse',data=vcoro_mgse
     get_data,rbx+'spinaxis_direction_gse',data=sa
     ;get_data,'angles',data=angles
     get_data,rbx+'state_mlt',data=mlt
     get_data,rbx+'state_mlat',data=mlat
     get_data,rbx+'state_lshell',data=lshell
     get_data,rbx+'ME_orbitnumber',data=orbit_num


     if is_struct(orbit_num) then orbit_num = orbit_num.y else orbit_num = replicate(-1.e31,n_elements(times))





  year = strmid(date,0,4) & mm = strmid(date,5,2) & dd = strmid(date,8,2)
  datafile = folder+rbx+'efw-l2_esvy_despun_'+year+mm+dd+'_v'+vstr+'.cdf'
  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.
  cdfid = cdf_open(datafile)




  ;Final list of variables to NOT delete
  varsave_general = ['epoch','epoch_e','vsvy_DFB_config','vsvy_BEB_config','flags_all',$
  'mlt','mlat','lshell','position_gse','velocity_gse','efield_mgse',$
  'flags_charging_bias_eclipse','orbit_num']



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



;--------------------------------------------------
;esvy despun files
;--------------------------------------------------


  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'epoch_e',epoch_e


  varsave_general = ['vsvy_DFB_config','vsvy_BEB_config','flags_all',$
  'efield_mgse']


  cdf_varput,cdfid,'mlt',transpose(mlt.y)
  cdf_varput,cdfid,'mlat',transpose(mlat.y)
  cdf_varput,cdfid,'lshell',transpose(lshell.y)
  cdf_varput,cdfid,'position_gse',transpose(pos_gse.y)
  cdf_varput,cdfid,'velocity_gse',transpose(vel_gse.y)
  ;full resolution
  esvy_vxb_mgsev2 = esvy_vxb_mgse.y
  esvy_vxb_mgsev2[*,0] = -1.e31
  cdf_varput,cdfid,'efield_mgse',transpose(esvy_vxb_mgsev2)
  cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
  cdf_varput,cdfid,'flags_all',transpose(flag_arr)
  cdf_varput,cdfid,'orbit_num',orbit_num







  cdf_close, cdfid


end
