;+
; NAME:
;   rbsp_efw_make_l2_spinfit
;
; PURPOSE:
;   Generate level-2 EFW "spinfit" CDF files
;
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l2_spinfit, sc, date
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
; $LastChangedDate: 2020-07-08 08:38:26 -0700 (Wed, 08 Jul 2020) $
; $LastChangedRevision: 28864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_make_l2_spinfit.pro $
;
;-


;*******************************
;NOTE: INCLUDE ;    'VxB_mgse','vel_coro_mgse'???
;---Combine mlt_lshell_mlat like in L3 files?
;---HSK DATA LOADING FROM rbsp_efw_get_flag_values.PRO. Is this necessary?
;*******************************

pro rbsp_efw_make_l2_spinfit,sc,date,$
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


;*********WHAT IS THIS????
  compile_opt idl2
  ;*********WHAT IS THIS????


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

  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                       'l2' + path_sep() + $
                                       'spinfit' + path_sep() + $
                                       year + path_sep()

  ;make sure we have the trailing slash on folder
  if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
  if ~keyword_set(no_cdf) then file_mkdir, folder



  ;Grab the skeleton file.
  ;     skeleton='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+rbspx+'_efw-l2_00000000_v02.cdf'
  skeleton='/Volumes/UserA/user_homes/kersten/Code/tdas_svn_daily/general/missions/rbsp/efw/l1_to_l2/'+rbx+'efw-lX_00000000_vXX.cdf'


  ;make sure we have the skeleton CDF
  found = 1
  if ~keyword_set(testing) then skeletonFile=file_search(skeleton,count=found)
  if keyword_set(testing) then $
    skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbsp'+$
                   sc+'_efw-lX_00000000_vXX.cdf'



  if ~found then begin
    dprint,'Could not find skeleton CDF, returning.'
    return
  endif
                            ; fix single element source file array
  skeletonFile=skeletonFile[0]

  if keyword_set(testing) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'



;------------ Set up paths. END. ----------------------------


  ;Load ECT's magnetic ephemeris
  rbsp_read_ect_mag_ephem,sc



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






  tinterpol_mxn,rbx+'efw_vsvy',times,/overwrite,/spline
  get_data,rbx+'efw_vsvy',data=vsvy

  ;; full resolution (V1+V2)/2
  vsvy_vavg = [[(vsvy.y[*,0] - vsvy.y[*,1])/2.],$
          [(vsvy.y[*,2] - vsvy.y[*,3])/2.],$
          [(vsvy.y[*,4] - vsvy.y[*,5])/2.]]



  ;--------------------------------------------------
  ;Get flag values (also gets density values from v12 and v34)
  ;--------------------------------------------------


   flag_str = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair=bp,_extra=extra)

   flag_arr = flag_str.flag_arr
   bias_sweep_flag = flag_str.bias_sweep_flag
   ab_flag = flag_str.ab_flag
   charging_flag = flag_str.charging_flag
;   ibias = flag_str.ibias


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
  varstmp = [rbx+'E_coro_mgse',rbx+'vscxb',rbx+'state_vel_coro_mgse',rbx+'state_pos_gse',$
  rbx+'state_vel_gse',$
  rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
  rbx+'ME_orbitnumber',rbx+'spinaxis_direction_gse','angles']


  ;Interpolate all data to common time base
  for qq=0,n_elements(varstmp)-1 do tinterpol_mxn,varstmp[qq],times,newname=varstmp[qq],/spline

  ;Grab all the data
  get_data,rbx+'vxb',data=vxb
  get_data,rbx+'state_pos_gse',data=pos_gse
  get_data,rbx+'state_vel_gse',data=vel_gse
  get_data,rbx+'E_coro_mgse',data=corotation_efield_mgse
  ;get_data,rbx+'state_vel_coro_mgse',data=vcoro_mgse
  get_data,rbx+'spinaxis_direction_gse',data=sa
  get_data,rbx+'angles',data=angles
  get_data,rbx+'state_mlt',data=mlt
  get_data,rbx+'state_mlat',data=mlat
  get_data,rbx+'state_lshell',data=lshell
  get_data,rbx+'ME_orbitnumber',data=orbit_num

  if is_struct(orbit_num) then orbit_num = orbit_num.y else orbit_num = replicate(-1.e31,n_elements(times))
  if is_struct(lstar) then lstar = lstar.y[*,0]


  year = strmid(date,0,4) & mm = strmid(date,5,2) & dd = strmid(date,8,2)


  datafile = folder+rbx+'efw-l2_e-spinfit-mgse_'+year+mm+dd+'_v'+vstr+'.cdf'

  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.
  cdfid = cdf_open(datafile)



  ;Final list of variables to NOT delete
  varsave_general = ['diagBratio',$
    'epoch',$
    'efield_inertial_spinfit_mgse',$
    'efield_corotation_spinfit_mgse',$
    'efield_inertial_spinfit_edotb_mgse',$
    'efield_corotation_spinfit_edotb_mgse',$
    'corotation_efield_mgse',$
    'vsvy_vavg_combo',$
;    'VxB_mgse','velocity_corotation_mgse',$
    'density',$
    'orbit_num','velocity_gse','position_gse','angle_spinplane_Bo','mlt','mlat','lshell',$
    'spinaxis_gse',$
    'flags_all','flags_charging_bias_eclipse',$
    'bias_current',$
    'burst1_avail',$
    'burst2_avail']




  ;Rename the appropriate variables to more generic names. The rest will get deleted.
;  cdf_varrename,cdfid,'efield_spinfit_mgse_'+bp,'efield_spinfit_mgse'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_'+bp,'efield_inertial_spinfit_mgse'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_'+bp,'efield_corotation_spinfit_mgse'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_'+bp,'efield_inertial_spinfit_edotb_mgse'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_'+bp,'efield_corotation_spinfit_edotb_mgse'
  cdf_varrename,cdfid,'density_'+bp,'density'


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
    if not tstt then print,'Deleting var:  ', CDFvarnames[qq]
    if not tstt then cdf_vardelete,cdfid,CDFvarnames[qq]
  endfor




  ;--------------------------------------------------
  ;Populate the remaining variables
  ;--------------------------------------------------

;NOTE: VARIABLES TO ADD
;  'vel_coro_mgse',$

  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)
  cdf_varput,cdfid,'flags_all',transpose(flag_arr)
  cdf_varput,cdfid,'burst1_avail',b1_flag
  cdf_varput,cdfid,'burst2_avail',b2_flag


  cdf_varput,cdfid,'efield_inertial_spinfit_mgse',transpose(efield_inertial_spinfit_mgse)
  cdf_varput,cdfid,'efield_corotation_spinfit_mgse',transpose(efield_corotation_spinfit_mgse)
  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse',transpose(efield_inertial_spinfit_edotb_mgse)
  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse',transpose(efield_corotation_spinfit_edotb_mgse)

  cdf_varput,cdfid,'density',transpose(density)

  cdf_varput,cdfid,'corotation_efield_mgse',transpose(corotation_efield_mgse.y)


;  cdf_varput,cdfid,'VxB_mgse',transpose(vxb.y)
  cdf_varput,cdfid,'mlt',transpose(mlt.y)
  cdf_varput,cdfid,'mlat',transpose(mlat.y)
  cdf_varput,cdfid,'lshell',transpose(lshell.y)
  cdf_varput,cdfid,'position_gse',transpose(pos_gse.y)
  cdf_varput,cdfid,'velocity_gse',transpose(vel_gse.y)
  cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
  cdf_varput,cdfid,'orbit_num',orbit_num
  cdf_varput,cdfid,'angle_spinplane_Bo',transpose(angles.y)
  ;if ibias[0] ne 0 then cdf_varput,cdfid,'bias_current',transpose(ibias)
  if is_struct(edotb_b2bx_ratio) then cdf_varput,cdfid,'diagBratio',transpose(edotb_b2bx_ratio.y)



  cdf_close, cdfid

  stop

end
