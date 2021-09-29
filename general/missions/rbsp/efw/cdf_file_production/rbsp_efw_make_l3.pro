;+
; NAME:
;   rbsp_efw_make_l3
;
; PURPOSE:
;   Generate level-3 EFW "spinfit" CDF files
;
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l3, sc, date
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
;   boom_pair -> specify for the spinfit routine. E.g. '12', '34', '24', etc.
;                Defaults to '12'
;
;
;
; HISTORY:
;   2014-12-02: Created by Aaron W Breneman, U. Minnesota
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2020-09-11 13:31:38 -0700 (Fri, 11 Sep 2020) $
; $LastChangedRevision: 29134 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_make_l3.pro $
;
;-


;*******************************
;NOTE: INCLUDE ;    'VxB_mgse','vel_coro_mgse'???
;---Combine mlt_lshell_mlat like in L3 files?
;*******************************

pro rbsp_efw_make_l3,sc,date,$
  folder=folder,$
  version = version,$
  testing=testing,$
  boom_pair=bp,$
  density_min=dmin



  if ~keyword_set(dmin) then dmin = 10.
  if ~keyword_set(bp) then bp = '12'


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


  ;Make IDL more friendly
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
                        'no_rbsp_efw_init',1)



  if n_elements(version) eq 0 then version = 2
  vstr = string(version, format='(I02)')

  rbx = 'rbsp' + strlowcase(sc[0]) + '_'


;------------ Set up paths. BEGIN. ----------------------------


  year = strmid(date, 0, 4)

;  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
;                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
;                                       'l3' + path_sep() + $
;                                       year + path_sep()

 ; ;make sure we have the trailing slash on folder
 ; if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
 ; if ~keyword_set(no_cdf) then file_mkdir, folder



  ;Grab the skeleton file.
  skfile = rbx+'efw-lX_00000000_vXX.cdf'


  if ~keyword_set(testing) then begin
    path = '/Volumes/UserA/user_homes/kersten/Code/tdas_svn_daily/general/missions/rbsp/efw/cdf_file_production/'
    skeleton = path + skfile
  endif else begin
    path = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/cdf_file_production/'
    skeleton = path + skfile
  endelse


  ;make sure we have the skeleton CDF
  found = 1
  skeletonFile=file_search(skeleton,count=found)
  if ~found then begin
    dprint,'Could not find skeleton CDF, returning.'
    return
  endif
  skeletonFile = skeletonFile[0]



;------------ Set up paths. END. ----------------------------




  ;Load both the spinfit data and also the E*B=0 version
  rbsp_efw_edotb_to_zero_crib,date,sc,$
    /noplot,$
    suffix='edotb',$
    boom_pair=bp,$
    /noremove,$
    _extra=extra




  ;Get the official times to which all quantities are interpolated to
  ;For spinfit data use the spinfit times.

  get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=tmp
  times = tmp.x
  epoch = tplot_time_to_epoch(times,/epoch16)





  ;If we're using boom pairs 12 or 34 then we haven't already loaded antenna potentials because
  ;I got Esvy from Sheng's CDF files. Load them here if necessary.

  if bp eq '12' or bp eq '34' then rbsp_load_efw_waveform, probe=sc, datatype = ['vsvy'], coord = 'uvw',/noclean




  tinterpol_mxn,rbx+'efw_vsvy',times,/overwrite,/spline
  get_data,rbx+'efw_vsvy',data=vsvy



  if bp eq '12' then vsvy_vavg = (vsvy.y[*,0] + vsvy.y[*,1])/2.
  if bp eq '13' then vsvy_vavg = (vsvy.y[*,0] + vsvy.y[*,2])/2.
  if bp eq '14' then vsvy_vavg = (vsvy.y[*,0] + vsvy.y[*,3])/2.
  if bp eq '23' then vsvy_vavg = (vsvy.y[*,1] + vsvy.y[*,2])/2.
  if bp eq '24' then vsvy_vavg = (vsvy.y[*,1] + vsvy.y[*,3])/2.
  if bp eq '34' then vsvy_vavg = (vsvy.y[*,2] + vsvy.y[*,3])/2.







;------------------------------------------------------
;Load all the HSK data, if required
;------------------------------------------------------


rbsp_load_efw_hsk,probe=sc,/get_support_data



pre = rbx+'efw_hsk_'
pre2 = 'idpu_analog_'

get_data,pre+pre2+'IMON_BEB',data=tmp
timeshsk = tmp.x
epoch_hsk = tplot_time_to_epoch(timeshsk,/epoch16)

pre2 = 'beb_analog_'
tinterpol_mxn,pre+pre2+'IEFI_IBIAS1',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_IBIAS1',data=ibias1
tinterpol_mxn,pre+pre2+'IEFI_IBIAS2',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_IBIAS2',data=ibias2
tinterpol_mxn,pre+pre2+'IEFI_IBIAS3',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_IBIAS3',data=ibias3
tinterpol_mxn,pre+pre2+'IEFI_IBIAS4',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_IBIAS4',data=ibias4
tinterpol_mxn,pre+pre2+'IEFI_IBIAS5',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_IBIAS5',data=ibias5
tinterpol_mxn,pre+pre2+'IEFI_IBIAS6',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_IBIAS6',data=ibias6

ibias = [[ibias1.y],[ibias2.y],[ibias3.y],[ibias4.y],[ibias5.y],[ibias6.y]]











;*****************************
;*****************************
;*****************************
;*****************************
;Put EMFISIS values on final time cadence

  tinterpol_mxn,rbx+'emfisis_l3_1sec_gse_Mag',times,/overwrite,/spline
  tinterpol_mxn,rbx+'mag_mgse',times,/overwrite,/spline
  get_data,rbx+'emfisis_l3_1sec_gse_Mag',data=mag_gse
  get_data,rbx+'mag_mgse',data=mag_mgse





  ;--------------------------------------------------
  ;Get flag values (also gets density values from v12 and v34)
  ;--------------------------------------------------


   flag_str = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair=bp,_extra=extra)

   flag_arr = flag_str.flag_arr
   bias_sweep_flag = flag_str.bias_sweep_flag
   ab_flag = flag_str.ab_flag
   charging_flag = flag_str.charging_flag


;-------------------------------------------------------
   ;Get diagnostics related to the E*B=0 calculation
;-------------------------------------------------------

   ;By/Bx and Bz/Bx
   get_data,'B2Bx_ratio',data=edotb_b2bx_ratio
   if is_struct(edotb_b2bx_ratio) then begin
     badyx = where(edotb_b2bx_ratio.y[*,0] gt 3.732)
     badzx = where(edotb_b2bx_ratio.y[*,1] gt 3.732)
   endif



   ;--------------------------------------------------
   ;Get burst times
   ;This is a bit complicated for spinperiod data b/c the short
   ;B2 snippets can be less than the spinperiod.
   ;So, I'm padding the B2 times by +/- a half spinperiod so that they don't
   ;disappear upon interpolation to the spinperiod data.
   ;--------------------------------------------------


   b1_flag = intarr(n_elements(times))
   b2_flag = b1_flag

   ;get B1 times and rates from this routine
   b1t = rbsp_get_burst_times_rates_list(sc)

   ;get B2 times from this routine
   b2t = rbsp_get_burst2_times_list(sc)
   ;Pad B2 by +/- half spinperiod
   b2t.startb2 -= 6.
   b2t.endb2   += 6.

   for q=0,n_elements(b1t.startb1)-1 do begin
     goodtimes = where((times ge b1t.startb1[q]) and (times le b1t.endb1[q]))
     if goodtimes[0] ne -1 then b1_flag[goodtimes] = b1t.samplerate[q]
   endfor
   for q=0,n_elements(b2t.startb2[*,0])-1 do begin $
     goodtimes = where((times ge b2t.startb2[q]) and (times le b2t.endb2[q])) & $
     if goodtimes[0] ne -1 then b2_flag[goodtimes] = 1
   endfor



  ;--------------------------------------------------
  ;save all spinfit resolution Efield quantities
  ;--------------------------------------------------

  eclipse_tmp = where(flag_arr[*,1] eq 1)

  get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=tmp
  if is_struct(tmp) then begin
        tmp.y[*,0] = -1.0E31  ;remove spin-axis component
        if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,1] = -1.0E31
        if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,2] = -1.0E31
     efield_inertial_spinfit_mgse = tmp.y
     tmp = 0.
  endif

  get_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',data=tmp
  if is_struct(tmp) then begin
        tmp.y[*,0] = -1.0E31  ;remove spin-axis component
        if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,1] = -1.0E31
        if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,2] = -1.0E31
     efield_corotation_spinfit_mgse = tmp.y
     tmp = 0.
  endif

  get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',data=tmp
  if is_struct(tmp) then begin
    if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,*] = -1.0E31
    ;Remove spin-axis component if not reliable
    if badyx[0] ne -1 then tmp.y[badyx,0] = -1.0E31
    if badzx[0] ne -1 then tmp.y[badzx,0] = -1.0E31
    efield_inertial_spinfit_edotb_mgse = tmp.y
    tmp = 0.
  endif

  get_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',data=tmp
  if is_struct(tmp) then begin
        if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,*] = -1.0E31
        ;Remove spin-axis component if not reliable
        if badyx[0] ne -1 then tmp.y[badyx,0] = -1.0E31
        if badzx[0] ne -1 then tmp.y[badzx,0] = -1.0E31
     efield_corotation_spinfit_edotb_mgse = tmp.y
     tmp = 0.
  endif


  ;--------------------------------------------------
  ;Nan out various values when global flag is thrown
  ;--------------------------------------------------

  ;density
  tinterpol_mxn,rbx+'density'+bp,times,/overwrite,/spline
  get_data,rbx+'density'+bp,data=tmp
  density = tmp.y
  goo = where(flag_arr[*,0] eq 1)
  if goo[0] ne -1 and is_struct(tmp) then density[goo] = -1.e31


  ;--------------------------------------------------
  ;Set a 3D flag variable for the survey plots
  ;--------------------------------------------------

  ;;charging, autobias, eclipse, and extreme charging flags all in one variable for convenience
  flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]],[flag_arr[*,16]]]



  ;;Set the density flag based on the antenna pair
  ;;used. We don't want to do this if type =
  ;;'spinfit_both_boompairs' because I include density values
  ;;obtained from both V12 and V34 in these CDF files
  flag_arr[*,16] = 0
   goo = where(density eq -1.e31)
   if goo[0] ne -1 then flag_arr[goo,16] = 1



  ;the times for the mag spinfit can be slightly different than the times for the
  ;Esvy spinfit.
  tinterpol_mxn,rbx+'mag_mgse',times,newname=rbx+'mag_mgse',/spline
  get_data,rbx+'mag_mgse',data=mag_mgse


  ;Downsample the GSE position and velocity variables to cadence of spinfit data
  varstmp = [rbx+'vcoroxb_mgse',rbx+'vscxb_mgse',rbx+'state_vel_coro_mgse',rbx+'state_pos_gse',$
  rbx+'state_vel_gse',$
  rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
  rbx+'spinaxis_direction_gse','angles']


  ;Interpolate all data to common time base
  for qq=0,n_elements(varstmp)-1 do tinterpol_mxn,varstmp[qq],times,newname=varstmp[qq],/spline

  ;Grab all the data
  get_data,rbx+'vscxb_mgse',data=vxb
  get_data,rbx+'state_pos_gse',data=pos_gse
  get_data,rbx+'state_vel_gse',data=vel_gse
  get_data,rbx+'vcoroxb_mgse',data=corotation_efield_mgse
  get_data,rbx+'spinaxis_direction_gse',data=sa
  get_data,rbx+'angles',data=angles
  get_data,rbx+'state_mlt',data=mlt
  get_data,rbx+'state_mlat',data=mlat
  get_data,rbx+'state_lshell',data=lshell


;*************TEMPORARY FOR WYGANT
get_data,rbx+'efield_sc_frame_wygant',data=efield_sc_frame_mgse
efield_sc_frame_mgse.y[*,0] = !values.f_nan
;**********************************


  year = strmid(date,0,4) & mm = strmid(date,5,2) & dd = strmid(date,8,2)


  datafile = path+rbx+'efw-l3_'+year+mm+dd+'_v'+vstr+'.cdf'
;  datafile = path+rbx+'efw-l3_'+year+mm+dd+'_v'+vstr+'.cdf'

  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.


  cdfid = cdf_open(datafile)





  ;Rename the appropriate variables to more generic names. The rest will get deleted.
;  cdf_varrename,cdfid,'efield_spinfit_mgse_'+bp,'efield_spinfit_mgse'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_'+bp,'efield_in_inertial_frame_spinfit_mgse'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_'+bp,'efield_in_corotation_frame_spinfit_mgse'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_'+bp,'efield_in_inertial_frame_spinfit_edotb_mgse'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_'+bp,'efield_in_corotation_frame_spinfit_edotb_mgse'
  cdf_varrename,cdfid,'density_'+bp,'density'
  cdf_varrename,cdfid,'corotation_efield_mgse','VxB_efield_of_earth_mgse'
  cdf_varrename,cdfid,'VxB_mgse','VscxB_motional_efield_mgse'
  cdf_varrename,cdfid,'vsvy_vavg_combo_'+bp,'spacecraft_potential'


;**********TEMPORARY FOR WYGANT
cdf_varrename,cdfid,'efield_spinfit_mgse_23','efield_moving_with_sc_mgse_Wygant'

;****************************
;****************************
;****************************
;****************************
;****************************



  ;Final list of variables to NOT delete
  varsave_general = ['diagBratio',$
    'epoch',$
    'epoch_hsk',$
    'efield_in_inertial_frame_spinfit_mgse',$
    'efield_in_corotation_frame_spinfit_mgse',$
    'efield_in_inertial_frame_spinfit_edotb_mgse',$
    'efield_in_corotation_frame_spinfit_edotb_mgse',$
    'VxB_efield_of_earth_mgse',$
    'VscxB_motional_efield_mgse',$
    'spacecraft_potential',$
    'density',$
    'velocity_gse','position_gse','angle_spinplane_Bo','mlt','mlat','lshell',$
    'spinaxis_gse',$
    'flags_all','flags_charging_bias_eclipse','global_flag',$
    'burst1_avail',$
    'burst2_avail',$
    'bfield_gse','bfield_mgse',$
    'bias_current',$
    'efield_moving_with_sc_mgse_Wygant']


;**********MAY WANT TO ADD THESE VARAIBLES******************
;     cdf_varput,cdfid,'mlt_lshell_mlat',transpose(mlt_lshell_mlat)
;     cdf_varput,cdfid,'diagEx1',diagEx1
;     cdf_varput,cdfid,'diagEx2',diagEx2
;     cdf_varput,cdfid,'diagBratio',transpose(b2bx_ratio.y)
;**********MAY WANT TO ADD THESE VARAIBLES******************
;**********MAY WANT TO ADD THESE VARAIBLES******************
;**********MAY WANT TO ADD THESE VARAIBLES******************













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
  ;Populate the remaining variables
  ;--------------------------------------------------


  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
  cdf_varput,cdfid,'flags_all',transpose(flag_arr)
  cdf_varput,cdfid,'global_flag',reform(flag_arr[*,0])
  cdf_varput,cdfid,'burst1_avail',b1_flag
  cdf_varput,cdfid,'burst2_avail',b2_flag

  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse',transpose(efield_inertial_spinfit_mgse)
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse',transpose(efield_corotation_spinfit_mgse)
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse',transpose(efield_inertial_spinfit_edotb_mgse)
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse',transpose(efield_corotation_spinfit_edotb_mgse)

  cdf_varput,cdfid,'density',transpose(density)

  cdf_varput,cdfid,'VxB_efield_of_earth_mgse',transpose(corotation_efield_mgse.y)
  cdf_varput,cdfid,'VscxB_motional_efield_mgse',transpose(vxb.y)

  cdf_varput,cdfid,'mlt',transpose(mlt.y)
  cdf_varput,cdfid,'mlat',transpose(mlat.y)
  cdf_varput,cdfid,'lshell',transpose(lshell.y)
  cdf_varput,cdfid,'position_gse',transpose(pos_gse.y)
  cdf_varput,cdfid,'velocity_gse',transpose(vel_gse.y)
  cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
  cdf_varput,cdfid,'angle_spinplane_Bo',transpose(angles.y)
  if is_struct(edotb_b2bx_ratio) then cdf_varput,cdfid,'diagBratio',transpose(edotb_b2bx_ratio.y)


  cdf_varput,cdfid,'bfield_mgse',transpose(mag_mgse.y)
  cdf_varput,cdfid,'bfield_gse',transpose(mag_gse.y)

  cdf_varput,cdfid,'spacecraft_potential',vsvy_vavg

;**************TEMPORARY
cdf_varput,cdfid,'efield_moving_with_sc_mgse_Wygant',transpose(efield_sc_frame_mgse.y)
  ;**************TEMPORARY


  cdf_varput,cdfid,'epoch_hsk',epoch_hsk
  cdf_varput,cdfid,'bias_current',transpose(ibias)


  cdf_close, cdfid


end
