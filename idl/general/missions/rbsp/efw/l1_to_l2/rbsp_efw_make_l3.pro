;+
; NAME: rbsp_efw_make_l3
; SYNTAX:
; PURPOSE: Create the EFW L3 CDF file
; INPUT:
; OUTPUT:
; KEYWORDS: type -> hidden - version for creating hidden file with EMFISIS data
;                -> survey - version for long-duration survey plots
;                -> if not set defaults to standard L3 version
;           script -> set if running from script. The date is read in
;           differently if so
;           version -> 1, 2, 3, etc...Defaults to 1
;           boom_pair -> defaults to '12' for spinfit data. Can change
;           to '34'
;
; HISTORY: Created by Aaron W Breneman, May 2014
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2016-09-02 06:56:49 -0700 (Fri, 02 Sep 2016) $
;   $LastChangedRevision: 21782 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l3.pro $
;-


pro rbsp_efw_make_l3,sc,date,folder=folder,version=version,$
                     type=type,testing=testing,script=script,$
                     boom_pair=bp,density_min=density_min

  print,date

  ;KEEP!!!!!! Necessary when running scripts
  if keyword_set(script) then date = time_string(double(date),prec=-3)

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


  rbsp_efw_init
  if ~keyword_set(type) then type = 'L3'
  if ~keyword_set(bp) then bp = '12'


  skip_plot = 1                 ;set to skip restoration of cdf file and test plotting at end of program


  starttime=systime(1)
  dprint,'BEGIN TIME IS ',systime()

  if ~keyword_set(version) then version = 2
  vstr = string(version, format='(I02)')


;__________________________________________________
;Get skeleton file
;__________________________________________________

;Skeleton file
  vskeleton = '02'
  skeleton='rbsp'+sc+'_efw-l3_00000000_v'+vskeleton+'.cdf'


  sc=strlowcase(sc)
  if sc ne 'a' and sc ne 'b' then begin
     dprint,'Invalid spacecraft: '+sc+', returning.'
     return
  endif
;  rbspx = 'rbsp'+sc


  if ~keyword_set(folder) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'
                                ; make sure we have the trailing slash on folder
  if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
  file_mkdir,folder



                                ; Use local skeleton
  if keyword_set(testing) then begin
     source_file='~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/' + skeleton
  endif else source_file='/Volumes/UserA/user_homes/kersten/Code/tdas_svn_daily/general/missions/rbsp/efw/l1_to_l2/'+skeleton



                                ; make sure we have the skeleton CDF
  source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
  if ~found then begin
     dprint,'Could not find l3 v'+vskeleton+' skeleton CDF, returning.'
     return
  endif
                                ; fix single element source file array
  source_file=source_file[0]

;__________________________________________________

  store_data,tnames(),/delete

  timespan,date

  rbsp_load_spice_kernels

  ;Load ECT's magnetic ephemeris
  rbsp_read_ect_mag_ephem,sc

  ;Load both the spinfit data and also the E*B=0 version
  rbsp_efw_edotb_to_zero_crib,date,sc,/no_spice_load,/noplot,suffix='edotb',$
                              boom_pair=bp,/noremove



;Get By/Bx and Bz/Bx from E*B=0 calculation
get_data,'B2Bx_ratio',data=b2bx_ratio
badyx = where(b2bx_ratio.y[*,0] gt 3.732)
badzx = where(b2bx_ratio.y[*,1] gt 3.732)

;Get spinaxis component
get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',data=diagEx
diagEx = diagEx.y[*,0]

;Have two versions. First has all E*B=0 data, second has E*B=0 bad data removed
diagEx1 = diagEx
diagEx2 = diagEx
if badyx[0] ne -1 then diagEx2[badyx,0] = !values.f_nan
if badzx[0] ne -1 then diagEx2[badzx,0] = !values.f_nan


;Get the official times to which all quantities are interpolated to
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmp
  times = tmp.x
  epoch = tplot_time_to_epoch(times,/epoch16)


;Get all the flag values
  flag_str = rbsp_efw_get_flag_values(sc,times,boom_pair=bp,density_min=density_min)

  flag_arr = flag_str.flag_arr
  bias_sweep_flag = flag_str.bias_sweep_flag
  ab_flag = flag_str.ab_flag
  charging_flag = flag_str.charging_flag
  charging_flag_extreme = flag_str.charging_flag_extreme
  ibias = flag_str.ibias

  if bp eq '12' then copy_data,'rbsp'+sc+'_density12','rbsp'+sc+'_density'
  if bp eq '34' then copy_data,'rbsp'+sc+'_density34','rbsp'+sc+'_density'

  get_data,'rbsp'+sc+'_density',data=dens


;--------------------------------------------------
;save all spinfit resolution Efield quantities
;--------------------------------------------------

                                ;Spinfit with corotation field
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb = tmp.y
                                ;Spinfit with corotation field and E*B=0
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit_edotb',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb_edotb = tmp.y
                                ;Spinfit without corotation field
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb_coro = tmp.y
                                ;Spinfit without corotation field and E*B=0
  get_data,'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',data=tmp
  if type eq 'L3' then tmp.y[*,0] = -1.0E31
  spinfit_vxb_coro_edotb = tmp.y


;--------------------------------------
;SUBTRACT OFF MODEL FIELD
;--------------------------------------

  model = 't89'
  rbsp_efw_dcfield_removal_crib,sc,/no_spice_load,/noplot,model=model



;--------------------------------------------------
;Nan out various values when global flag is thrown
;--------------------------------------------------

  ;;density
  goo = where(flag_arr[*,0] eq 1)
  if goo[0] ne -1 then dens.y[goo] = -1.e31


;--------------------------------------------------
;Set a 3D flag variable for the survey plots
;--------------------------------------------------

  ;charging, extreme charging, autobias and eclipse flags all in one variable for convenience
  flags = [[flag_arr[*,15]],[flag_arr[*,16]],[flag_arr[*,14]],[flag_arr[*,1]]]


;the times for the mag spinfit can be slightly different than the times for the
;Esvy spinfit.
  tinterpol_mxn,'rbsp'+sc+'_mag_mgse',times,newname='rbsp'+sc+'_mag_mgse'
  get_data,'rbsp'+sc+'_mag_mgse',data=mag_mgse


;Downsample the GSE position and velocity variables to cadence of spinfit data
  tinterpol_mxn,'rbsp'+sc+'_E_coro_mgse',times,newname='rbsp'+sc+'_E_coro_mgse'
  tinterpol_mxn,'rbsp'+sc+'_vscxb',times,newname='vxb'
  tinterpol_mxn,'rbsp'+sc+'_state_vel_coro_mgse',times,newname='rbsp'+sc+'_state_vel_coro_mgse'
  tinterpol_mxn,'rbsp'+sc+'_state_pos_gse',times,newname='rbsp'+sc+'_state_pos_gse'
  tinterpol_mxn,'rbsp'+sc+'_state_vel_gse',times,newname='rbsp'+sc+'_state_vel_gse'
  get_data,'vxb',data=vxb
  get_data,'rbsp'+sc+'_state_pos_gse',data=pos_gse
  get_data,'rbsp'+sc+'_state_vel_gse',data=vel_gse
  get_data,'rbsp'+sc+'_E_coro_mgse',data=ecoro_mgse
  get_data,'rbsp'+sc+'_state_vel_coro_mgse',data=vcoro_mgse

  tinterpol_mxn,'rbsp'+sc+'_mag_mgse_'+model,times,newname='rbsp'+sc+'_mag_mgse_'+model
  tinterpol_mxn,'rbsp'+sc+'_mag_mgse_t89_dif',times,newname='rbsp'+sc+'_mag_mgse_t89_dif'
  get_data,'rbsp'+sc+'_mag_mgse_'+model,data=mag_model
  get_data,'rbsp'+sc+'_mag_mgse_t89_dif',data=mag_diff

  mag_model_magnitude = sqrt(mag_model.y[*,0]^2 + mag_model.y[*,1]^2 + mag_model.y[*,2]^2)
  mag_data_magnitude = sqrt(mag_mgse.y[*,0]^2 + mag_mgse.y[*,1]^2 + mag_mgse.y[*,2]^2)
  mag_diff_magnitude = mag_data_magnitude - mag_model_magnitude

  tinterpol_mxn,'rbsp'+sc+'_state_mlt',times,newname='rbsp'+sc+'_state_mlt'
  tinterpol_mxn,'rbsp'+sc+'_state_mlat',times,newname='rbsp'+sc+'_state_mlat'
  tinterpol_mxn,'rbsp'+sc+'_state_lshell',times,newname='rbsp'+sc+'_state_lshell'
;  tinterpol_mxn,'rbsp'+sc+'_ME_lstar',times,newname='rbsp'+sc+'_ME_lstar'
  tinterpol_mxn,'rbsp'+sc+'_ME_orbitnumber',times,newname='rbsp'+sc+'_ME_orbitnumber'

  get_data,'rbsp'+sc+'_state_mlt',data=mlt
  get_data,'rbsp'+sc+'_state_mlat',data=mlat
  get_data,'rbsp'+sc+'_state_lshell',data=lshell
  get_data,'rbsp'+sc+'_ME_orbitnumber',data=orbit_num
  if is_struct(orbit_num) then orbit_num = orbit_num.y else orbit_num = replicate(-1.e31,n_elements(times))
  ;get_data,'rbsp'+sc+'_ME_lstar',data=lstar
  lstar = replicate(-1.e31,n_elements(times))



  tinterpol_mxn,'rbsp'+sc+'_spinaxis_direction_gse',times,newname='rbsp'+sc+'_spinaxis_direction_gse'
  get_data,'rbsp'+sc+'_spinaxis_direction_gse',data=sa

  get_data,'angles',data=angles


  get_data,'rbsp'+sc +'_efw_vsvy_V1',data=v1
  get_data,'rbsp'+sc +'_efw_vsvy_V2',data=v2
  get_data,'rbsp'+sc +'_efw_vsvy_V3',data=v3
  get_data,'rbsp'+sc +'_efw_vsvy_V4',data=v4
  get_data,'rbsp'+sc +'_efw_vsvy_V5',data=v5
  get_data,'rbsp'+sc +'_efw_vsvy_V6',data=v6


  if bp eq '12' then vavg = (v1.y + v2.y)/2.
  if bp eq '34' then vavg = (v3.y + v4.y)/2.
  if bp eq '56' then vavg = (v5.y + v6.y)/2.

;--------------------------------------------------
  ;These are variables for the L3 survey plots
  mlt_lshell_mlat = [[mlt.y],[lshell.y],[mlat.y]]
  location = [[mlt.y],[lshell.y],[mlat.y],$
              [pos_gse.y[*,0]],[pos_gse.y[*,1]],[pos_gse.y[*,2]],$
              [vel_gse.y[*,0]],[vel_gse.y[*,1]],[vel_gse.y[*,2]],$
              [sa.y[*,0]],[sa.y[*,1]],[sa.y[*,2]],[orbit_num],[lstar]]
  bfield_data = [[mag_mgse.y[*,0]],[mag_mgse.y[*,0]],[mag_mgse.y[*,0]],$
                 [mag_model.y[*,0]],[mag_model.y[*,0]],[mag_model.y[*,0]],$
                 [mag_diff.y[*,0]],[mag_diff.y[*,0]],[mag_diff.y[*,0]],$
                 [mag_data_magnitude],[mag_diff_magnitude]]
  density_potential = [[dens.y],[vavg],[v1.y],[v2.y],[v3.y],[v4.y],[v5.y],[v6.y]]

;--------------------------------------------------

  if type eq 'L3' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'.cdf'
  if type eq 'hidden' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'_hidden.cdf'
  if type eq 'survey' then filename = 'rbsp'+sc+'_efw-l3_'+strjoin(strsplit(date,'-',/extract))+'_v'+vstr+'_survey.cdf'



  file_copy,source_file,folder+filename,/overwrite

  cdfid = cdf_open(folder+filename)

  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'flags_all',transpose(flag_arr)
  cdf_varput,cdfid,'flags_charging_bias_eclipse',transpose(flags)



;;--------------------------------------------------
;;Remove values during eclipse times
;;--------------------------------------------------

  goo = where(flags[*,2] eq 1)

  if goo[0] ne -1 then begin
     spinfit_vxb[goo,*] = !values.f_nan
     spinfit_vxb_coro[goo,*] = !values.f_nan
     dens.y[goo] = !values.f_nan
     vavg[goo] = !values.f_nan
  endif


;--------------------------------------------------
;Populate CDF file for L3 version
;--------------------------------------------------

  ;;Rename certain variables based on selected boom pair
  if bp eq '12' then begin
     cdf_varrename,cdfid,'density_v12','density'
     cdf_varrename,cdfid,'efield_inertial_frame_mgse_e12','efield_inertial_frame_mgse'
     cdf_varrename,cdfid,'efield_corotation_frame_mgse_e12','efield_corotation_frame_mgse'
     cdf_varrename,cdfid,'Vavg_v12','Vavg'
     cdf_varrename,cdfid,'density_potential_v12','density_potential'
     cdf_varrename,cdfid,'efield_inertial_frame_mgse_edotb_zero_e12','efield_inertial_frame_mgse_edotb_zero'
     cdf_varrename,cdfid,'efield_corotation_frame_mgse_edotb_zero_e12','efield_corotation_frame_mgse_edotb_zero'

     cdf_vardelete,cdfid,'density_v34'
     cdf_vardelete,cdfid,'efield_inertial_frame_mgse_e34'
     cdf_vardelete,cdfid,'efield_corotation_frame_mgse_e34'
     cdf_vardelete,cdfid,'Vavg_v34'
     cdf_vardelete,cdfid,'density_potential_v34'
     cdf_vardelete,cdfid,'efield_inertial_frame_mgse_edotb_zero_e34'
     cdf_vardelete,cdfid,'efield_corotation_frame_mgse_edotb_zero_e34'
  endif else begin

     cdf_varrename,cdfid,'density_v34','density'
     cdf_varrename,cdfid,'efield_inertial_frame_mgse_e34','efield_inertial_frame_mgse'
     cdf_varrename,cdfid,'efield_corotation_frame_mgse_e34','efield_corotation_frame_mgse'
     cdf_varrename,cdfid,'Vavg_v34','Vavg'
     cdf_varrename,cdfid,'density_potential_v34','density_potential'
     cdf_varrename,cdfid,'efield_inertial_frame_mgse_edotb_zero_e34','efield_inertial_frame_mgse_edotb_zero'
     cdf_varrename,cdfid,'efield_corotation_frame_mgse_edotb_zero_e34','efield_corotation_frame_mgse_edotb_zero'

     cdf_vardelete,cdfid,'density_v12'
     cdf_vardelete,cdfid,'efield_inertial_frame_mgse_e12'
     cdf_vardelete,cdfid,'efield_corotation_frame_mgse_e12'
     cdf_vardelete,cdfid,'Vavg_v12'
     cdf_vardelete,cdfid,'density_potential_v12'
     cdf_vardelete,cdfid,'efield_inertial_frame_mgse_edotb_zero_e12'
     cdf_vardelete,cdfid,'efield_corotation_frame_mgse_edotb_zero_e12'
  endelse




  if type eq 'L3' then begin

     cdf_varput,cdfid,'efield_inertial_frame_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse',transpose(spinfit_vxb_coro)
     cdf_varput,cdfid,'VcoroxB_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'VscxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'density',dens.y
     cdf_varput,cdfid,'Vavg',vavg
     cdf_varput,cdfid,'mlt_lshell_mlat',transpose(mlt_lshell_mlat)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'diagEx1',diagEx1
     cdf_varput,cdfid,'diagEx2',diagEx2
     cdf_varput,cdfid,'diagBratio',transpose(b2bx_ratio.y)


     cdf_vardelete,cdfid,'efield_inertial_frame_mgse_edotb_zero'
     cdf_vardelete,cdfid,'efield_corotation_frame_mgse_edotb_zero'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'Bfield'
     cdf_vardelete,cdfid,'density_potential'
     cdf_vardelete,cdfid,'ephemeris'
     cdf_vardelete,cdfid,'orbit_num'
     cdf_vardelete,cdfid,'Lstar'
     cdf_vardelete,cdfid,'angle_Ey_Ez_Bo'
     cdf_vardelete,cdfid,'bias_current'

  endif



;--------------------------------------------------
;Populate CDF file for survey version
;--------------------------------------------------


  if type eq 'survey' then begin

     cdf_varput,cdfid,'efield_inertial_frame_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse',transpose(spinfit_vxb_coro)
     cdf_varput,cdfid,'efield_inertial_frame_mgse_edotb_zero',transpose(spinfit_vxb_edotb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse_edotb_zero',transpose(spinfit_vxb_coro_edotb)
     cdf_varput,cdfid,'VcoroxB_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'VscxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'Bfield',transpose(bfield_data)
     cdf_varput,cdfid,'density_potential',transpose(density_potential)
     cdf_varput,cdfid,'ephemeris',transpose(location)
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)

     cdf_vardelete,cdfid,'orbit_num'
     cdf_vardelete,cdfid,'Lstar'
     cdf_vardelete,cdfid,'density'
     cdf_vardelete,cdfid,'Vavg'
     cdf_vardelete,cdfid,'pos_gse'
     cdf_vardelete,cdfid,'vel_gse'
     cdf_vardelete,cdfid,'spinaxis_gse'
     cdf_vardelete,cdfid,'mlt_lshell_mlat'
     cdf_vardelete,cdfid,'bfield_mgse'
     cdf_vardelete,cdfid,'bfield_model_mgse'
     cdf_vardelete,cdfid,'bfield_minus_model_mgse'
     cdf_vardelete,cdfid,'bfield_magnitude_minus_modelmagnitude'
     cdf_vardelete,cdfid,'bfield_magnitude'

  endif


;--------------------------------------------------
;Populate CDF file for hidden version
;--------------------------------------------------

  if type eq 'hidden' then begin

     cdf_varput,cdfid,'efield_inertial_frame_mgse',transpose(spinfit_vxb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse',transpose(spinfit_vxb_coro)
     cdf_varput,cdfid,'efield_inertial_frame_mgse_edotb_zero',transpose(spinfit_vxb_edotb)
     cdf_varput,cdfid,'efield_corotation_frame_mgse_edotb_zero',transpose(spinfit_vxb_coro_edotb)
     cdf_varput,cdfid,'VcoroxB_mgse',transpose(ecoro_mgse.y)
     cdf_varput,cdfid,'VscxB_mgse',transpose(vxb.y)
     cdf_varput,cdfid,'bfield_magnitude',mag_data_magnitude
     cdf_varput,cdfid,'bfield_mgse',transpose(mag_mgse.y)
     cdf_varput,cdfid,'bfield_model_mgse',transpose(mag_model.y)
     cdf_varput,cdfid,'bfield_minus_model_mgse',transpose(mag_diff.y)
     cdf_varput,cdfid,'bfield_magnitude_minus_modelmagnitude',mag_diff_magnitude
     cdf_varput,cdfid,'density',dens.y
     cdf_varput,cdfid,'Vavg',vavg
     cdf_varput,cdfid,'mlt_lshell_mlat',transpose(mlt_lshell_mlat)
     cdf_varput,cdfid,'pos_gse',transpose(pos_gse.y)
     cdf_varput,cdfid,'vel_gse',transpose(vel_gse.y)
     cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
     cdf_varput,cdfid,'orbit_num',orbit_num
     cdf_varput,cdfid,'Lstar',lstar
     cdf_varput,cdfid,'angle_Ey_Ez_Bo',transpose(angles.y)
     cdf_varput,cdfid,'bias_current',transpose(ibias)


     cdf_vardelete,cdfid,'Bfield'
     cdf_vardelete,cdfid,'ephemeris'
     cdf_vardelete,cdfid,'density_potential'


  endif



  cdf_close, cdfid
  store_data,tnames(),/delete


end
