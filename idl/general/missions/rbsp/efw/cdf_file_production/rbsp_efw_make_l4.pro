;+
; NAME:
;   rbsp_efw_make_l4
;
; PURPOSE:
;   Generate level-4 EFW CDF files
;
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l4, sc, date
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
;   Jan 2020: Created by Aaron W Breneman, U. Minnesota
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2020-09-11 13:31:42 -0700 (Fri, 11 Sep 2020) $
; $LastChangedRevision: 29135 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_make_l4.pro $
;
;-

;***********************************************
;Spinfits with E*B=0  - all boompairs
;The "best" spinfit duplicated and called something else.
;All density calculations

;***********************************************



pro rbsp_efw_make_l4,sc,date,$
  folder=folder,$
  version=version,$
  testing=testing,$
  density_min=dmin


  if ~keyword_set(dmin) then dmin = 10.


  if ~keyword_set(testing) then begin
     openw,lun,'output.txt',/get_lun
     printf,lun,'date = ',date
     printf,lun,'date type: ',typename(date)
     printf,lun,'probe = ',sc
     printf,lun,'probe type: ',typename(sc)
     printf,lun,'bp = ',bp

     close,lun
     free_lun,lun
  endif


  ;Make IDL behave nicely
  compile_opt idl2


  timespan,date


  ;Clean slate
  store_data,tnames(),/delete


;  ;Only download if you don't have the file locally
;  extra_spicelocation = create_struct('local_spice_only_if_exist_locally',1)


 ; ;Initial (and only) load of these
 ; rbsp_load_spice_kernels,_extra=extra_spicelocation
  rbsp_efw_init


  ;Define keyword inheritance to pass to subroutines. This will ensure that
  ;subsequent routines don't reload spice kernels or rbsp_efw_init
  extra = create_struct('no_spice_load',1,$
                        'no_rbsp_efw_init',1,$
                        'no_waveform_load',0,$
                        'no_emfisis_load',0)


  if n_elements(version) eq 0 then version = 1
  vstr = string(version, format='(I02)')

  rbx = 'rbsp' + strlowcase(sc[0]) + '_'


;------------ Set up paths. BEGIN. ----------------------------


  year = strmid(date, 0, 4)

;  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
;                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
;                                       'l2' + path_sep() + $
;                                       'spinfit' + path_sep() + $
;                                       year + path_sep()

;  ;make sure we have the trailing slash on folder
;  if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
;  if ~keyword_set(no_cdf) then file_mkdir, folder



	;Grab skeleton file
	if ~keyword_set(testing) then begin
		folder = '/Volumes/UserA/user_homes/rbsp_efw/Code/tdas_svn_daily/general/missions/rbsp/efw/cdf_file_production/'
		skeletonfile=file_search(folder + rbx+'efw-lX_00000000_vXX.cdf',count=found)
		if ~found then begin
	     dprint,'Could not find skeleton CDF, returning.'
	     return
	  endif
	endif else begin
		folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/cdf_file_production/'
		skeletonfile = folder +rbx+'efw-lX_00000000_vXX.cdf'
	endelse






;------------ Set up paths. END. ----------------------------




  ;Load both the spinfit data and also the E*B=0 version


  ;boom pairs
  bps = ['12','13','14','23','24','34']

  ;for each boompair
  for uu=0,n_elements(bps)-1 do begin
    rbsp_efw_edotb_to_zero_crib,date,sc,$
      /noplot,$
      suffix='edotb',$
      boom_pair=bps[uu],$
      _extra=extra



    if uu eq 0 then begin

      ;Get the official times to which all quantities are interpolated to
      ;For spinfit data use the spinfit times.
      get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',data=tmp
      times = tmp.x
      epoch = tplot_time_to_epoch(times,/epoch16)

      ;Following calls don't need to load EMFISIS data
      extra.no_emfisis_load = 1.
    endif

    ;At this point we've loaded the vsvy data for the '13' pair and don't
    ;need to reload it.
    if uu eq 1 then begin
      extra.no_waveform_load = 1.
      ;Interpolate Vsvy data to time base
      tinterpol_mxn,rbx+'efw_vsvy',times,/spline;,/overwrite
      get_data,rbx+'efw_vsvy_interp',data=vsvy
    endif


    ;data not always on exact same time base
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_spinfit',times,/overwrite,/spline
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',times,/overwrite,/spline
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',times,/overwrite,/spline
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',times,/overwrite,/spline


    ;Rename useful variables based on their boom pair
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',rbx+'efw_esvy_mgse_vxb_removed_spinfit_'+bps[uu]
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+bps[uu]
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb_'+bps[uu]
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_'+bps[uu]


    store_data,[rbx+'efw_esvy_mgse_vxb_removed_spinfit',$
                rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',$
                rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',$
                rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb'],/delete

  endfor


  tinterpol_mxn,rbx+'emfisis_l3_1sec_gse_Mag',times,/overwrite,/spline
  tinterpol_mxn,rbx+'mag_mgse',times,/overwrite,/spline
  get_data,rbx+'emfisis_l3_1sec_gse_Mag',data=mag_gse
  get_data,rbx+'mag_mgse',data=mag_mgse




  ;; full resolution (V1+V2)/2
  vsvy_vavg = [[(vsvy.y[*,0] + vsvy.y[*,1])/2.],$
               [(vsvy.y[*,0] + vsvy.y[*,2])/2.],$
               [(vsvy.y[*,0] + vsvy.y[*,3])/2.],$
               [(vsvy.y[*,1] + vsvy.y[*,2])/2.],$
               [(vsvy.y[*,1] + vsvy.y[*,3])/2.],$
               [(vsvy.y[*,2] + vsvy.y[*,3])/2.]]





;------------------------------------------------------------------
;Load ephemeris data and put on a once/min cadence
;------------------------------------------------------------------


	;Load SPICE data
	rbsp_load_spice_cdf_file,sc




	;interpolate ephemeris values to this once/min cadence
	tinterpol_mxn,rbx+'state_pos_gse',times,/overwrite,/spline
	tinterpol_mxn,rbx+'state_vel_gse',times,/overwrite,/spline
	tinterpol_mxn,rbx+'spinaxis_direction_gse',times,/overwrite,/spline
	tinterpol_mxn,rbx+'state_mlt',times,/overwrite,/spline
	tinterpol_mxn,rbx+'state_mlat',times,/overwrite,/spline
	tinterpol_mxn,rbx+'state_lshell',times,/overwrite,/spline

	get_data,rbx+'state_pos_gse',data=pos_gse
	get_data,rbx+'state_vel_gse',data=vel_gse
	get_data,rbx+'spinaxis_direction_gse',data=wgse
	get_data,rbx+'state_mlt',data=mlt
	get_data,rbx+'state_mlat',data=mlat
	get_data,rbx+'state_lshell',data=lshell








  ;--------------------------------------------------
  ;Get flag values (also gets density values from v12 and v34)
  ;--------------------------------------------------



  flag_str12 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='12',_extra=extra)
  flag_str13 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='13',_extra=extra)
  flag_str14 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='14',_extra=extra)
  flag_str23 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='23',_extra=extra)
  flag_str24 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='24',_extra=extra)
  flag_str34 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='34',_extra=extra)


  ;Create master flag array
  flag_arr = intarr(n_elements(times),20,n_elements(bps))
  flag_arr[*,*,0] = flag_str12.flag_arr
  flag_arr[*,*,1] = flag_str13.flag_arr
  flag_arr[*,*,2] = flag_str14.flag_arr
  flag_arr[*,*,3] = flag_str23.flag_arr
  flag_arr[*,*,4] = flag_str24.flag_arr
  flag_arr[*,*,5] = flag_str34.flag_arr

;   flag_arr = flag_str.flag_arr
;   bias_sweep_flag = flag_str.bias_sweep_flag
;   ab_flag = flag_str.ab_flag
;   charging_flag = flag_str.charging_flag




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

   for q=0,n_elements(b1t.startb1)-1 do begin $
     goodtimes = where((times ge b1t.startb1[q]) and (times le b1t.endb1[q])) & $
     if goodtimes[0] ne -1 then b1_flag[goodtimes] = b1t.samplerate[q]
   endfor
   for q=0,n_elements(b2t.startb2[*,0])-1 do begin $
     goodtimes = where((times ge b2t.startb2[q]) and (times le b2t.endb2[q])) & $
     if goodtimes[0] ne -1 then b2_flag[goodtimes] = 1
   endfor




  ;--------------------------------------------------
  ;Nan out various values when global flag is thrown
  ;--------------------------------------------------


  ;Set the density and density flag based on the antenna pair used.
  flag_arr[*,16,*] = 0
  density = fltarr(n_elements(times),n_elements(bps))
  for uu=0,n_elements(bps)-1 do begin
    tinterpol_mxn,rbx+'density'+bps[uu],times,/overwrite,/spline
    get_data,rbx+'density'+bps[uu],data=tmp
    density[*,uu] = tmp.y
    if uu eq 0 then goo = where(flag_str12.flag_arr[*,0] eq 1)
    if uu eq 1 then goo = where(flag_str13.flag_arr[*,0] eq 1)
    if uu eq 2 then goo = where(flag_str14.flag_arr[*,0] eq 1)
    if uu eq 3 then goo = where(flag_str23.flag_arr[*,0] eq 1)
    if uu eq 4 then goo = where(flag_str24.flag_arr[*,0] eq 1)
    if uu eq 5 then goo = where(flag_str34.flag_arr[*,0] eq 1)
    ;    if goo[0] ne -1 and is_struct(tmp) then density[goo,uu] = -1.e31
    if goo[0] ne -1 and is_struct(tmp) then flag_arr[goo,16,uu] = 1
  endfor



  ;--------------------------------------------------
  ;Set a 3D flag variable for the survey plots
  ;--------------------------------------------------

  ;Flags for each time and boom pair
  ;charging, autobias, eclipse, and extreme charging flags all in one variable for convenience
  flags = fltarr(n_elements(times),4,n_elements(bps))

  flags[*,*,0] = [[flag_str12.flag_arr[*,15]],[flag_str12.flag_arr[*,14]],[flag_str12.flag_arr[*,1]],[flag_str12.flag_arr[*,16]]]
  flags[*,*,1] = [[flag_str13.flag_arr[*,15]],[flag_str13.flag_arr[*,14]],[flag_str13.flag_arr[*,1]],[flag_str13.flag_arr[*,16]]]
  flags[*,*,2] = [[flag_str14.flag_arr[*,15]],[flag_str14.flag_arr[*,14]],[flag_str14.flag_arr[*,1]],[flag_str14.flag_arr[*,16]]]
  flags[*,*,3] = [[flag_str23.flag_arr[*,15]],[flag_str23.flag_arr[*,14]],[flag_str23.flag_arr[*,1]],[flag_str23.flag_arr[*,16]]]
  flags[*,*,4] = [[flag_str24.flag_arr[*,15]],[flag_str24.flag_arr[*,14]],[flag_str24.flag_arr[*,1]],[flag_str24.flag_arr[*,16]]]
  flags[*,*,5] = [[flag_str34.flag_arr[*,15]],[flag_str34.flag_arr[*,14]],[flag_str34.flag_arr[*,1]],[flag_str34.flag_arr[*,16]]]
;  flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]],[flag_arr[*,16]]]



;  for uu=0,n_elements(bps)-1 do begin $
;    goo = where(density[*,uu] eq -1.e31) & $
;    if goo[0] ne -1 then flag_arr[goo,16,uu] = 1
;  endfor


  ;the times for the mag spinfit can be slightly different than the times for the
  ;Esvy spinfit.
  tinterpol_mxn,rbx+'mag_mgse',times,newname=rbx+'mag_mgse',/spline
  get_data,rbx+'mag_mgse',data=mag_mgse


  ;Downsample the GSE position and velocity variables to cadence of spinfit data
;  varstmp = [rbx+'E_coro_mgse',rbx+'vscxb',rbx+'state_vel_coro_mgse',rbx+'state_pos_gse',$
;  rbx+'state_vel_gse',$
;  rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
;  rbx+'spinaxis_direction_gse','angles']
  varstmp = [rbx+'vcoroxb_mgse',rbx+'vscxb_mgse',rbx+'state_vel_coro_mgse',rbx+'state_pos_gse',$
  rbx+'state_vel_gse',$
  rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
  rbx+'spinaxis_direction_gse',rbx+'angles','B2Bx_ratio']


  ;Interpolate all data to common time base
  for qq=0,n_elements(varstmp)-1 do tinterpol_mxn,varstmp[qq],times,newname=varstmp[qq],/spline


  ;Grab all the data non specific to any boom pair
  get_data,rbx+'vscxb_mgse',data=vxb
  get_data,rbx+'vcoroxb_mgse',data=corotation_efield_mgse
  get_data,rbx+'state_pos_gse',data=pos_gse
  get_data,rbx+'state_vel_gse',data=vel_gse
  ;get_data,rbx+'E_coro_mgse',data=corotation_efield_mgse
  ;get_data,rbx+'state_vel_coro_mgse',data=vcoro_mgse
  get_data,rbx+'spinaxis_direction_gse',data=sa
  get_data,rbx+'angles',data=angles
  get_data,rbx+'state_mlt',data=mlt
  get_data,rbx+'state_mlat',data=mlat
  get_data,rbx+'state_lshell',data=lshell




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
  ;save all spinfit resolution Efield quantities
  ;--------------------------------------------------

;  eclipse_tmp = where(flag_arr[*,1] eq 1)
  eclipse_tmp = where(flag_str12.flag_arr[*,1] eq 1)

  efield_inertial_spinfit_mgse = fltarr(n_elements(times),3,n_elements(bps))
  efield_corotation_spinfit_mgse = fltarr(n_elements(times),3,n_elements(bps))
  efield_inertial_spinfit_edotb_mgse = fltarr(n_elements(times),3,n_elements(bps))
  efield_corotation_spinfit_edotb_mgse = fltarr(n_elements(times),3,n_elements(bps))



  ;Populate the Efield variables
  for uu=0,n_elements(bps)-1 do begin

    get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;          tmp.y[*,0] = -1.0E31  ;remove spin-axis component
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,1] = -1.0E31
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,2] = -1.0E31
       efield_inertial_spinfit_mgse[*,*,uu] = tmp.y
       tmp = 0.
    endif

    get_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;          tmp.y[*,0] = -1.0E31  ;remove spin-axis component
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,1] = -1.0E31
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,2] = -1.0E31
       efield_corotation_spinfit_mgse[*,*,uu] = tmp.y
       tmp = 0.
    endif

    get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;      if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,*] = -1.0E31
;      ;Remove spin-axis component if not reliable
;      if badyx[0] ne -1 then tmp.y[badyx,0] = -1.0E31
;      if badzx[0] ne -1 then tmp.y[badzx,0] = -1.0E31
      efield_inertial_spinfit_edotb_mgse[*,*,uu] = tmp.y
      tmp = 0.
    endif

    get_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,*] = -1.0E31
          ;Remove spin-axis component if not reliable
;          if badyx[0] ne -1 then tmp.y[badyx,0] = -1.0E31
;          if badzx[0] ne -1 then tmp.y[badzx,0] = -1.0E31
       efield_corotation_spinfit_edotb_mgse[*,*,uu] = tmp.y
       tmp = 0.
    endif

  endfor




  ;------------------------------------------------------
  ;Subtract off DCfield
  ;------------------------------------------------------

  model = 't89'
  rbsp_efw_DCfield_removal_crib,sc,/no_spice_load,/noplot,model=model


;  tinterpol_mxn,rbx+'mag_gse_for_subtract',times,/overwrite,/spline
;  tinterpol_mxn,rbx+'mag_gse_t89',times,/overwrite,/spline
;  tinterpol_mxn,rbx+'mag_gse_t89_dif',times,/overwrite,/spline
  tinterpol_mxn,rbx+'mag_mgse_for_subtract',times,/overwrite,/spline
  tinterpol_mxn,rbx+'mag_mgse_t89',times,/overwrite,/spline
  tinterpol_mxn,rbx+'mag_mgse_t89_dif',times,/overwrite,/spline
;  tinterpol_mxn,rbx+'mag_mgse_t89_dif',times,/overwrite,/spline

;  get_data,rbx+'mag_gse_for_subtract',data=mag_gse
;  get_data,rbx+'mag_gse_t89',data=mag_gse_t89
;  get_data,rbx+'mag_gse_t89_dif',data=mag_gse_dif
  get_data,rbx+'mag_mgse_for_subtract',data=mag_mgse
  get_data,rbx+'mag_mgse_t89',data=mag_mgse_t89
  get_data,rbx+'mag_mgse_t89_dif',data=mag_mgse_dif

  bfield_magnitude = sqrt(mag_mgse.y[*,0]^2 + mag_mgse.y[*,1]^2 + mag_mgse.y[*,2]^2)
  bfield_magnitude_minus_modelmagnitude = sqrt(mag_mgse_dif.y[*,0]^2 + mag_mgse_dif.y[*,1]^2 + mag_mgse_dif.y[*,2]^2)



;------------------------------------------------------
;Load all the HSK data, if required
;------------------------------------------------------


rbsp_load_efw_hsk,probe=sc,/get_support_data



pre = rbx+'efw_hsk_'
pre2 = 'idpu_analog_'

get_data,pre+pre2+'IMON_BEB',data=tmp
timeshsk = tmp.x
epoch_hsk = tplot_time_to_epoch(timeshsk,/epoch16)

;get_data,pre+pre2+'IMON_BEB',data=imon_beb
;get_data,pre+pre2+'IMON_IDPU',data=imon_idpu
;get_data,pre+pre2+'IMON_FVX',data=imon_fvx
;get_data,pre+pre2+'IMON_FVY',data=imon_fvy
;get_data,pre+pre2+'IMON_FVZ',data=imon_fvz
;get_data,pre+pre2+'P33IMON',data=imon_p33
;get_data,pre+pre2+'P15IMON',data=imon_p15
;get_data,pre+pre2+'TMON_LVPS',data=tmon_lvps
;get_data,pre+pre2+'TMON_AXB5',data=tmon_axb5
;get_data,pre+pre2+'TMON_AXB6',data=tmon_axb6
;get_data,pre+pre2+'TEMP_FPGA',data=tmon_fpga
;get_data,pre+pre2+'P33VD',data=vmon_p33vd_i
;get_data,pre+pre2+'P15VD',data=vmon_p15vd_i
;get_data,pre+pre2+'VMON_BEB_P10VA',data=vmon_p10va_b
;get_data,pre+pre2+'VMON_BEB_N10VA',data=vmon_n10va_b
;get_data,pre+pre2+'VMON_BEB_P5VA',data=vmon_p5va_b
;get_data,pre+pre2+'VMON_BEB_P5VD',data=vmon_p5vd_b
;get_data,pre+pre2+'VMON_IDPU_N10VA',data=vmon_n10va_i
;get_data,pre+pre2+'VMON_IDPU_N5VA',data=vmon_n5va
;get_data,pre+pre2+'VMON_IDPU_P10VA',data=vmon_p10va_i
;get_data,pre+pre2+'VMON_IDPU_P18VD',data=vmon_p18vd
;get_data,pre+pre2+'VMON_IDPU_P36VD',data=vmon_p36vd
;get_data,pre+pre2+'VMON_IDPU_P5VA',data=vmon_p5va_i
;get_data,pre+pre2+'VMON_IDPU_P5VD',data=vmon_p5vd_i

;tinterpol_mxn,pre+'idpu_eng_SC_EFW_SSR',timeshsk,/overwrite,/spline
;get_data,pre+'idpu_eng_SC_EFW_SSR',data=ssr_fillper

;pre2 = 'idpu_fast_'
;get_data,pre+pre2+'B1_EVALMAX',data=b1_evalmax
;get_data,pre+pre2+'B1_PLAYREQ',data=b1_playreq
;get_data,pre+pre2+'B1_RECBBI',data=b1_recbbi
;get_data,pre+pre2+'B1_RECECI',data=b1_receci
;get_data,pre+pre2+'B1_THRESH',data=b1_thresh
;get_data,pre+pre2+'B2_THRESH',data=b2_thresh
;get_data,pre+pre2+'B2RECSTATE',data=b2_recstate
;get_data,pre+pre2+'B2_EVALMAX',data=b2_evalmax


;get_data,pre+'idpu_eng_IO_ECCSING',data=eccsing
;get_data,pre+'idpu_eng_IO_ECCMULT',data=eccmult
;get_data,pre+'idpu_eng_RSTCTR',data=rstctr
;get_data,pre+pre2+'RSTFLAG',data=rstflag



;get_data,pre+'auto_bias',data=d
;get_data,pre+pre2+'bias_current',data=ibias



pre2 = 'beb_analog_'
tinterpol_mxn,pre+pre2+'IEFI_GUARD1',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_GUARD1',data=guard1
tinterpol_mxn,pre+pre2+'IEFI_GUARD2',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_GUARD2',data=guard2
tinterpol_mxn,pre+pre2+'IEFI_GUARD3',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_GUARD3',data=guard3
tinterpol_mxn,pre+pre2+'IEFI_GUARD4',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_GUARD4',data=guard4
tinterpol_mxn,pre+pre2+'IEFI_GUARD5',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_GUARD5',data=guard5
tinterpol_mxn,pre+pre2+'IEFI_GUARD6',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_GUARD6',data=guard6
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
tinterpol_mxn,pre+pre2+'IEFI_USHER1',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_USHER1',data=usher1
tinterpol_mxn,pre+pre2+'IEFI_USHER2',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_USHER2',data=usher2
tinterpol_mxn,pre+pre2+'IEFI_USHER3',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_USHER3',data=usher3
tinterpol_mxn,pre+pre2+'IEFI_USHER4',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_USHER4',data=usher4
tinterpol_mxn,pre+pre2+'IEFI_USHER5',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_USHER5',data=usher5
tinterpol_mxn,pre+pre2+'IEFI_USHER6',timeshsk,/overwrite,/spline
get_data,pre+pre2+'IEFI_USHER6',data=usher6

ibias = [[ibias1.y],[ibias2.y],[ibias3.y],[ibias4.y],[ibias5.y],[ibias6.y]]
usher = [[usher1.y],[usher2.y],[usher3.y],[usher4.y],[usher5.y],[usher6.y]]
guard = [[guard1.y],[guard2.y],[guard3.y],[guard4.y],[guard5.y],[guard6.y]]












  year = strmid(date,0,4) & mm = strmid(date,5,2) & dd = strmid(date,8,2)


  datafile = folder+rbx+'efw-l4_'+year+mm+dd+'_v'+vstr+'.cdf'

  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.
  cdfid = cdf_open(datafile)





  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_12','efield_in_inertial_frame_spinfit_mgse_12'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_13','efield_in_inertial_frame_spinfit_mgse_13'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_14','efield_in_inertial_frame_spinfit_mgse_14'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_23','efield_in_inertial_frame_spinfit_mgse_23'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_24','efield_in_inertial_frame_spinfit_mgse_24'
  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_34','efield_in_inertial_frame_spinfit_mgse_34'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_12','efield_in_inertial_frame_spinfit_edotb_mgse_12'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_13','efield_in_inertial_frame_spinfit_edotb_mgse_13'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_14','efield_in_inertial_frame_spinfit_edotb_mgse_14'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_23','efield_in_inertial_frame_spinfit_edotb_mgse_23'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_24','efield_in_inertial_frame_spinfit_edotb_mgse_24'
  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_34','efield_in_inertial_frame_spinfit_edotb_mgse_34'

  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_12','efield_in_corotation_frame_spinfit_mgse_12'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_13','efield_in_corotation_frame_spinfit_mgse_13'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_14','efield_in_corotation_frame_spinfit_mgse_14'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_23','efield_in_corotation_frame_spinfit_mgse_23'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_24','efield_in_corotation_frame_spinfit_mgse_24'
  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_34','efield_in_corotation_frame_spinfit_mgse_34'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_12','efield_in_corotation_frame_spinfit_edotb_mgse_12'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_13','efield_in_corotation_frame_spinfit_edotb_mgse_13'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_14','efield_in_corotation_frame_spinfit_edotb_mgse_14'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_23','efield_in_corotation_frame_spinfit_edotb_mgse_23'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_24','efield_in_corotation_frame_spinfit_edotb_mgse_24'
  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_34','efield_in_corotation_frame_spinfit_edotb_mgse_34'

  cdf_varrename,cdfid,'corotation_efield_mgse','VxB_efield_of_earth_mgse'
  cdf_varrename,cdfid,'VxB_mgse','VscxB_motional_efield_mgse'

  cdf_varrename,cdfid,'vsvy_vavg_combo_12','spacecraft_potential_12'
  cdf_varrename,cdfid,'vsvy_vavg_combo_13','spacecraft_potential_13'
  cdf_varrename,cdfid,'vsvy_vavg_combo_14','spacecraft_potential_14'
  cdf_varrename,cdfid,'vsvy_vavg_combo_23','spacecraft_potential_23'
  cdf_varrename,cdfid,'vsvy_vavg_combo_24','spacecraft_potential_24'
  cdf_varrename,cdfid,'vsvy_vavg_combo_34','spacecraft_potential_34'





  ;Final list of variables to NOT delete
  varsave_general = ['diagBratio',$
    'epoch',$
    'epoch_hsk',$
    'efield_in_inertial_frame_spinfit_mgse_12',$
    'efield_in_inertial_frame_spinfit_mgse_13',$
    'efield_in_inertial_frame_spinfit_mgse_14',$
    'efield_in_inertial_frame_spinfit_mgse_23',$
    'efield_in_inertial_frame_spinfit_mgse_24',$
    'efield_in_inertial_frame_spinfit_mgse_34',$
    'efield_in_corotation_frame_spinfit_mgse_12',$
    'efield_in_corotation_frame_spinfit_mgse_13',$
    'efield_in_corotation_frame_spinfit_mgse_14',$
    'efield_in_corotation_frame_spinfit_mgse_23',$
    'efield_in_corotation_frame_spinfit_mgse_24',$
    'efield_in_corotation_frame_spinfit_mgse_34',$
    'efield_in_inertial_frame_spinfit_edotb_mgse_12',$
    'efield_in_inertial_frame_spinfit_edotb_mgse_13',$
    'efield_in_inertial_frame_spinfit_edotb_mgse_14',$
    'efield_in_inertial_frame_spinfit_edotb_mgse_23',$
    'efield_in_inertial_frame_spinfit_edotb_mgse_24',$
    'efield_in_inertial_frame_spinfit_edotb_mgse_34',$
    'efield_in_corotation_frame_spinfit_edotb_mgse_12',$
    'efield_in_corotation_frame_spinfit_edotb_mgse_13',$
    'efield_in_corotation_frame_spinfit_edotb_mgse_14',$
    'efield_in_corotation_frame_spinfit_edotb_mgse_23',$
    'efield_in_corotation_frame_spinfit_edotb_mgse_24',$
    'efield_in_corotation_frame_spinfit_edotb_mgse_34',$
    'VxB_efield_of_earth_mgse',$
    'VscxB_motional_efield_mgse',$
    'spacecraft_potential_12',$
    'spacecraft_potential_13',$
    'spacecraft_potential_14',$
    'spacecraft_potential_23',$
    'spacecraft_potential_24',$
    'spacecraft_potential_34',$
    'density_12',$
    'density_13',$
    'density_14',$
    'density_23',$
    'density_24',$
    'density_34',$
    'velocity_gse','position_gse','angle_spinplane_Bo','mlt','mlat','lshell',$
    'spinaxis_gse',$
    'flags_all_12',$
    'flags_all_13',$
    'flags_all_14',$
    'flags_all_23',$
    'flags_all_24',$
    'flags_all_34',$
    'flags_charging_bias_eclipse_12',$
    'flags_charging_bias_eclipse_13',$
    'flags_charging_bias_eclipse_14',$
    'flags_charging_bias_eclipse_23',$
    'flags_charging_bias_eclipse_24',$
    'flags_charging_bias_eclipse_34',$
    'burst1_avail',$
    'burst2_avail',$
;    'IMON_IDPU_BEB',$
;    'IMON_IDPU_IDPU',$
;    'IMON_IDPU_FVX',$
;    'IMON_IDPU_FVY',$
;    'IMON_IDPU_FVZ',$
;    'IMON_IDPU_P33',$
;    'IMON_IDPU_P15',$
;    'TMON_IDPU_LVPS',$
;    'TMON_IDPU_AXB5',$
;    'TMON_IDPU_AXB6',$
;    'TMON_IDPU_FPGA',$
;    'VMON_BEB_P10VA',$
;    'VMON_IDPU_P33VD',$
;    'VMON_IDPU_P10VA',$
;    'VMON_IDPU_P15VD',$
;    'VMON_BEB_P5VA',$
;    'VMON_IDPU_P5VA',$
;    'VMON_BEB_P5VD',$
;    'VMON_IDPU_P5VD',$
;    'VMON_BEB_N10VA',$
;    'VMON_IDPU_N10VA',$
;    'VMON_IDPU_N5VA',$
;    'VMON_IDPU_P36VD',$
;    'VMON_IDPU_P18VD',$
;    'SSR_FILLPER',$
    ;'B1_EVALMAX',$
    ;'B1_PLAYREQ',$
    ;'B1_RECBBI',$
    ;'B1_RECECI',$
    ;'B1_THRESH',$
    ;'B2_THRESH',$
    ;'B2_RECSTATE',$
    ;'B2_EVALMAX',$
    ;'IO_ECCSING',$
    ;'IO_ECCMULT',$
    ;'RSTCTR',$
    ;'RSTFLAG',$
  ;  'bias_sweep',$
    'bias_current',$
    'usher_voltage',$
    'guard_voltage',$
    ;'bfield_gse',$
    'bfield_mgse',$
    'bfield_minus_model_mgse',$
    'bfield_model_mgse',$
    ;'bfield_minus_model_gse',$
    ;'bfield_model_gse',$
    ;'bfield_gse',$
    'bfield_magnitude_minus_modelmagnitude',$
    'bfield_magnitude']







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



;NEED TO CREATE THE BELOW FLAG VARIABLES FOR EACH BOOM PAIR

  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'flags_charging_bias_eclipse_12',transpose(flags[*,*,0])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_13',transpose(flags[*,*,1])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_14',transpose(flags[*,*,2])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_23',transpose(flags[*,*,3])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_24',transpose(flags[*,*,4])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_34',transpose(flags[*,*,5])
  cdf_varput,cdfid,'flags_all_12',transpose(flag_arr[*,*,0])
  cdf_varput,cdfid,'flags_all_13',transpose(flag_arr[*,*,1])
  cdf_varput,cdfid,'flags_all_14',transpose(flag_arr[*,*,2])
  cdf_varput,cdfid,'flags_all_23',transpose(flag_arr[*,*,3])
  cdf_varput,cdfid,'flags_all_24',transpose(flag_arr[*,*,4])
  cdf_varput,cdfid,'flags_all_34',transpose(flag_arr[*,*,5])
  cdf_varput,cdfid,'burst1_avail',b1_flag
  cdf_varput,cdfid,'burst2_avail',b2_flag



  ;Rename and save inertial fram electric fields
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse_12',transpose(efield_inertial_spinfit_mgse[*,*,0])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse_13',transpose(efield_inertial_spinfit_mgse[*,*,1])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse_14',transpose(efield_inertial_spinfit_mgse[*,*,2])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse_23',transpose(efield_inertial_spinfit_mgse[*,*,3])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse_24',transpose(efield_inertial_spinfit_mgse[*,*,4])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_mgse_34',transpose(efield_inertial_spinfit_mgse[*,*,5])

  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse_12',transpose(efield_inertial_spinfit_edotb_mgse[*,*,0])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse_13',transpose(efield_inertial_spinfit_edotb_mgse[*,*,1])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse_14',transpose(efield_inertial_spinfit_edotb_mgse[*,*,2])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse_23',transpose(efield_inertial_spinfit_edotb_mgse[*,*,3])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse_24',transpose(efield_inertial_spinfit_edotb_mgse[*,*,4])
  cdf_varput,cdfid,'efield_in_inertial_frame_spinfit_edotb_mgse_34',transpose(efield_inertial_spinfit_edotb_mgse[*,*,5])


  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse_12',transpose(efield_corotation_spinfit_mgse[*,*,0])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse_13',transpose(efield_corotation_spinfit_mgse[*,*,1])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse_14',transpose(efield_corotation_spinfit_mgse[*,*,2])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse_23',transpose(efield_corotation_spinfit_mgse[*,*,3])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse_24',transpose(efield_corotation_spinfit_mgse[*,*,4])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_mgse_34',transpose(efield_corotation_spinfit_mgse[*,*,5])

  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse_12',transpose(efield_corotation_spinfit_edotb_mgse[*,*,0])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse_13',transpose(efield_corotation_spinfit_edotb_mgse[*,*,1])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse_14',transpose(efield_corotation_spinfit_edotb_mgse[*,*,2])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse_23',transpose(efield_corotation_spinfit_edotb_mgse[*,*,3])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse_24',transpose(efield_corotation_spinfit_edotb_mgse[*,*,4])
  cdf_varput,cdfid,'efield_in_corotation_frame_spinfit_edotb_mgse_34',transpose(efield_corotation_spinfit_edotb_mgse[*,*,5])


  cdf_varput,cdfid,'density_12',transpose(density[*,0])
  cdf_varput,cdfid,'density_13',transpose(density[*,1])
  cdf_varput,cdfid,'density_14',transpose(density[*,2])
  cdf_varput,cdfid,'density_23',transpose(density[*,3])
  cdf_varput,cdfid,'density_24',transpose(density[*,4])
  cdf_varput,cdfid,'density_34',transpose(density[*,5])


  cdf_varput,cdfid,'VxB_efield_of_earth_mgse',transpose(corotation_efield_mgse.y)
  cdf_varput,cdfid,'VscxB_motional_efield_mgse',transpose(vxb.y)
  cdf_varput,cdfid,'mlt',transpose(mlt.y)
  cdf_varput,cdfid,'mlat',transpose(mlat.y)
  cdf_varput,cdfid,'lshell',transpose(lshell.y)
  cdf_varput,cdfid,'position_gse',transpose(pos_gse.y)
  cdf_varput,cdfid,'velocity_gse',transpose(vel_gse.y)
  cdf_varput,cdfid,'spinaxis_gse',transpose(wgse.y)
  cdf_varput,cdfid,'angle_spinplane_Bo',transpose(angles.y)
  if is_struct(edotb_b2bx_ratio) then cdf_varput,cdfid,'diagBratio',transpose(edotb_b2bx_ratio.y)


  cdf_varput,cdfid,'spacecraft_potential_12',vsvy_vavg[*,0]
  cdf_varput,cdfid,'spacecraft_potential_13',vsvy_vavg[*,1]
  cdf_varput,cdfid,'spacecraft_potential_14',vsvy_vavg[*,2]
  cdf_varput,cdfid,'spacecraft_potential_23',vsvy_vavg[*,3]
  cdf_varput,cdfid,'spacecraft_potential_24',vsvy_vavg[*,4]
  cdf_varput,cdfid,'spacecraft_potential_34',vsvy_vavg[*,5]


  ;Magnetic field stuff
  cdf_varput,cdfid,'bfield_mgse',transpose(mag_mgse.y)
  cdf_varput,cdfid,'bfield_minus_model_mgse',transpose(mag_mgse_dif.y)
  cdf_varput,cdfid,'bfield_model_mgse',transpose(mag_mgse_t89.y)
  cdf_varput,cdfid,'bfield_magnitude_minus_modelmagnitude',bfield_magnitude_minus_modelmagnitude
  cdf_varput,cdfid,'bfield_magnitude',bfield_magnitude


  ;HSK data

  cdf_varput,cdfid,'epoch_hsk',epoch_hsk
  cdf_varput,cdfid,'bias_current',transpose(ibias)
  cdf_varput,cdfid,'usher_voltage',transpose(usher)
  cdf_varput,cdfid,'guard_voltage',transpose(guard)
;  cdf_varput,cdfid,'IMON_IDPU_BEB',imon_beb.y
;  cdf_varput,cdfid,'IMON_IDPU_IDPU',imon_idpu.y
;    cdf_varput,cdfid,'IMON_IDPU_FVX',imon_fvx.y
;    cdf_varput,cdfid,'IMON_IDPU_FVY',imon_fvy.y
;    cdf_varput,cdfid,'IMON_IDPU_FVZ',imon_fvz.y
;    cdf_varput,cdfid,'IMON_IDPU_P33',imon_p33.y
;    cdf_varput,cdfid,'IMON_IDPU_P15',imon_p15.y
;    cdf_varput,cdfid,'TMON_IDPU_LVPS',tmon_lvps.y
;    cdf_varput,cdfid,'TMON_IDPU_AXB5',tmon_axb5.y
;    cdf_varput,cdfid,'TMON_IDPU_AXB6',tmon_axb6.y
;    cdf_varput,cdfid,'TMON_IDPU_FPGA',tmon_fpga.y
;    cdf_varput,cdfid,'VMON_BEB_P10VA',vmon_p10va_b.y
;    cdf_varput,cdfid,'VMON_IDPU_P33VD',vmon_p33vd_i.y
;    cdf_varput,cdfid,'VMON_IDPU_P10VA',vmon_p10va_i.y
;    cdf_varput,cdfid,'VMON_IDPU_P15VD',vmon_p15vd_i.y
;    cdf_varput,cdfid,'VMON_BEB_P5VA',vmon_p5va_b.y
;    cdf_varput,cdfid,'VMON_IDPU_P5VA',vmon_p5va_i.y
;    cdf_varput,cdfid,'VMON_BEB_P5VD',vmon_p5vd_b.y
;    cdf_varput,cdfid,'VMON_IDPU_P5VD',vmon_p5vd_i.y
;    cdf_varput,cdfid,'VMON_BEB_N10VA',vmon_n10va_b.y
;    cdf_varput,cdfid,'VMON_IDPU_N10VA',vmon_n10va_i.y
;    cdf_varput,cdfid,'VMON_IDPU_N5VA',vmon_n5va.y
;    cdf_varput,cdfid,'VMON_IDPU_P36VD',vmon_p36vd.y
;    cdf_varput,cdfid,'VMON_IDPU_P18VD',vmon_p18vd.y
;    cdf_varput,cdfid,'SSR_FILLPER',ssr_fillper.y
;    cdf_varput,cdfid,'B1_EVALMAX',b1_evalmax.y
;    cdf_varput,cdfid,'B1_PLAYREQ',b1_playreq.y
;    cdf_varput,cdfid,'B1_RECBBI',b1_recbbi.y
;    cdf_varput,cdfid,'B1_RECECI',b1_receci.y
;    cdf_varput,cdfid,'B1_THRESH',b1_thresh.y
;    cdf_varput,cdfid,'B2_THRESH',b2_thresh.y
;    cdf_varput,cdfid,'B2_RECSTATE',b2_recstate.y
;    cdf_varput,cdfid,'B2_EVALMAX',b2_evalmax.y
    ;cdf_varput,cdfid,'IO_ECCSING',eccsing.y
    ;cdf_varput,cdfid,'IO_ECCMULT',eccmult.y
    ;cdf_varput,cdfid,'RSTCTR',rstctr.y
    ;cdf_varput,cdfid,'RSTFLAG',rstflag.y
;    cdf_varput,cdfid,'auto_bias',





  cdf_close, cdfid

stop

end
