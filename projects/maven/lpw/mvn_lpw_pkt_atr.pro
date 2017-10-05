;;+
;PROCEDURE:   mvn_lpw_pkt_atr
;PURPOSE:
;  Takes the decumuted data (L0) from the ATR packet, Active Table Read back
;  and turn it the data into tplot structures
;  NOTE mvn_lpw_pkt_atr needs to be read before mvn_lpw_pkt_adr
; ATR packet will only be provided as raw values expect for the
; sweep values that is derived into units of Volt
;
;USAGE:
;  mvn_lpw_pkt_atr,output,lpw_const,cdf_istp_lpw,tplot_var
;
;INPUTS:
;       output:         L0 data
;       lpw_const:      information of lpw calibration etc
;       cdf_istp_lpw:   information for CDF production
;
;KEYWORDS:
;       tplot_var   'ALL' or 'sci'  'sci' produces tplot variables that have physical units associated with them.
;                                   'ALL' produces all tplot variables.
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.
;
;CREATED BY:   Laila Andersson 17 august 2011
;FILE: mvn_lpw_pkt_atr.pro
;VERSION:   2.0  <------------------------------- update 'pkt_ver' variable
;LAST MODIFICATION:
;07/11/13 - Chris Fowler - added IF statement checking for data in output.p6, and keyword tplot_var.
;05/16/13
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels, since this is a read back of tables no dv or dy information exist
; 04/15/14 L. Andersson included L1
;18/04/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;;140718 clean up for check out L. Andersson
;2014-10-03: CF: edited dlimit fields for ISTP compliance.
;2014-10-03:LA: change too the new bias/stub calibration from from seperate files
;-

pro mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var,spice=spice


  IF output.p6 GT 0 THEN BEGIN  ;check we have data

    ;-------------------Check different inputs------------------------------------
    If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.
    ;--------------------------------------------------------------------


    ;--------------------- Constants Used In This Routine  ------------------------------------
    t_routine        =SYSTIME(0)
    t_epoch          =lpw_const.t_epoch
    today_date       =lpw_const.today_date
    cal_ver          =lpw_const.version_calib_routine
    pkt_ver          = 'Pkt_atr_ver V2.0 '
    cdf_istp         =lpw_const.cdf_istp_lpw
    filename_L0      =output.filename
    ;---------
    nn_swp=lpw_const.nn_swp
    nn_dac=lpw_const.nn_dac
    ;--------------------------------------------------------------------
    mvn_lpw_cal_read_bias,bias_arr,bias_file
    mvn_lpw_cal_read_guard,guard_arr,guard_file   ;><<<<<<< not working yet!!!!!
    mvn_lpw_cal_read_stub,stub_arr,stub_file
    ;----------  variable: --------------------
    nn_pktnum=output.p6                               ; number of data packages
    ;-----------------------------------------

    ;------------- Checks ---------------------
    if output.p6 NE n_elements(output.atr_i) then stanna
    if n_elements(output.atr_i) EQ 0 then print,'(mvn_lpw_atr) No packages where found <---------------'
    ;-----------------------------------------

    ;-------------------- Get correct clock time ------------------------------
    time_sc = double(output.SC_CLK1[output.atr_i]+output.SC_CLK2[output.atr_i]/2l^16)+t_epoch  ;data points in s/c time
    IF keyword_set(spice)  THEN BEGIN                                                                                                ;if this computer has SPICE installed:
      aa = output.SC_CLK1[output.atr_i]
      bb = output.SC_CLK2[output.atr_i]
      mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,time  ;correct times using SPICE
    ENDIF ELSE BEGIN
      clock_field_str  =  ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00']
      time             = time_sc                                                                                            ;data points in s/c time
      clock_start_t    = [time_sc(0)-t_epoch,          time_sc(0)]                         ;corresponding start times to above string array, s/c time
      clock_end_t      = [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)] ;corresponding end times, s/c time
      spice_used       = 'SPICE not used'
      str_xtitle       = 'Time (s/c)'
      kernel_version    = 'N/A'
    ENDELSE
    ;--------------------------------------------------------------------



    ;------------- variable:  atr_swp_table ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_swp) ,  $     ; most of the time float and 1-D or 2-D
      'v',    fltarr(nn_pktnum,nn_swp)  )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    for i=0,nn_pktnum-1 do begin
      data.y[i,*]=bias_arr(output.ATR_SWP[i,*],1)
      data.v[i,*]=indgen(nn_swp)
    endfor
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ATR sweep', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     cdf_istp[3], $
      'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
      'Descriptor',                    cdf_istp[5], $
      'PI_name',                       cdf_istp[6], $
      'PI_affiliation',                cdf_istp[7], $
      'TEXT',                          cdf_istp[8], $
      'Mission_group',                 cdf_istp[9], $
      'Generated_by',                  cdf_istp[10],  $
      'Generation_date',                today_date+' # '+t_routine, $
      'Rules of use',                  cdf_istp[11], $
      'Acknowledgement',               cdf_istp[13],   $
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(data.v,/nan)+1, $
      'SCALEMAX', max(data.v,/nan)+1, $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t, $
      'Time_end'        ,     clock_end_t, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: ' +bias_file+ 'used boom 1 cal' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: ATR', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[bin number]', $
      'cal_v_const1'    ,     'Used: Step no',$; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      'zsubtitle'       ,     '[V]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'ATR_sweep'                 ,$
      'yrange' ,        [min(data.v,/nan),max(data.v,/nan)]+1 ,$
      'ystyle'  ,       1.                       ,$
      'ylog'   ,        0.                       ,$
      'ztitle' ,        'Bias swep [V]'                ,$
      'zrange' ,        [min(data.y,/nan),max(data.y,/nan)] +1,$
      'zlog'   ,        0.                       ,$
      'spec'   ,        1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
    ;------------- store --------------------
    store_data,'mvn_lpw_atr_swp',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  atr_swp_table_raw ---------------------------
      data =  create_struct(     $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,nn_swp) ,  $     ; most of the time float and 1-D or 2-D
        'v',    fltarr(nn_pktnum,nn_swp) )
      ;-------------- derive  time/variable ----------------
      data.x = time
      for i=0,nn_pktnum-1 do begin
        data.y[i,*]=output.ATR_SWP[i,*]   ;raw data
        data.v[i,*]=indgen(nn_swp)
      endfor
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ATR sweep RAW', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'RAW>Raw' ,  $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules of use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(data.v,/nan)+1, $
        'SCALEMAX', max(data.v,/nan)+1, $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: NaN' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;                   'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;  'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ATR', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[bin number]', $
        'cal_v_const1'    ,     'Used: Step no' ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        'zsubtitle'       ,     '[raw value]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'ATR_sweep'                 ,$
        'yrange' ,        [min(data.v,/nan),max(data.v,/nan)]+1  ,$
        'ystyle'  ,       1.                       ,$
        'ztitle' ,        'Bias swep [RAW]'               ,$
        'zrange' ,        [min(data.y,/nan),max(data.y,/nan)]+1,$
        'spec'            ,     1, $
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_atr_swp_raw',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  atr_dac_table ---------------------------
      data =  create_struct(     $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,nn_dac) ,  $     ; most of the time float and 1-D or 2-D
        'v',    fltarr(nn_pktnum,nn_dac) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time
      for i=0,nn_pktnum-1 do begin
        data.y[i,0]=output.ATR_W_BIAS1[i]
        data.y[i,1]=output.ATR_W_GUARD1[i]
        data.y[i,2]=output.ATR_W_STUB1[i]
        data.y[i,3]=output.ATR_LP_BIAS1[i]
        data.y[i,4]=output.ATR_LP_GUARD1[i]
        data.y[i,5]=output.ATR_LP_STUB1[i]
        data.y[i,6]=output.ATR_W_BIAS2[i]
        data.y[i,7]=output.ATR_W_GUARD2[i]
        data.y[i,8]=output.ATR_W_STUB2[i]
        data.y[i,9]=output.ATR_LP_BIAS2[i]
        data.y[i,10]=output.ATR_LP_GUARD2[i]
        data.y[i,11]=output.ATR_LP_STUB2[i]
        data.v[i,*]=indgen(nn_dac)
      endfor
      str1= ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
        'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ATR dac', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'RAW>raw', $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules of use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', 0., $
        'SCALEMAX', 12., $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: NAN' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ATR', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[RAW]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'ATR_DAC_table'          ,$
        'yrange' ,        [0,4096]                   ,$
        'ystyle'  ,       1.                       ,$
        'labels' ,        str1                     ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_atr_dac_raw',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  atr_dac_table ---------------------------
      data =  create_struct(     $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,nn_dac) ,  $     ; most of the time float and 1-D or 2-D
        'v',    fltarr(nn_pktnum,nn_dac) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time
      for i=0,nn_pktnum-1 do begin
        data.y[i,0]=bias_arr(output.ATR_W_BIAS1[i] < 4095,1)
        data.y[i,1]=guard_arr(output.ATR_W_GUARD1[i]< 4095,1)
        data.y[i,2]=stub_arr(output.ATR_W_STUB1[i]< 4095,1)
        data.y[i,3]=bias_arr(output.ATR_LP_BIAS1[i]< 4095,1)
        data.y[i,4]=guard_arr(output.ATR_LP_GUARD1[i]< 4095,1)
        data.y[i,5]=stub_arr(output.ATR_LP_STUB1[i]< 4095,1)
        data.y[i,6]=bias_arr(output.ATR_W_BIAS2[i]< 4095,2)
        data.y[i,7]=guard_arr(output.ATR_W_GUARD2[i]< 4095,2)
        data.y[i,8]=stub_arr(output.ATR_W_STUB2[i]< 4095,2)
        data.y[i,9]=bias_arr(output.ATR_LP_BIAS2[i]< 4095,2)
        data.y[i,10]=guard_arr(output.ATR_LP_GUARD2[i]< 4095,2)
        data.y[i,11]=stub_arr(output.ATR_LP_STUB2[i]< 4095,2)
        data.v[i,*]=indgen(nn_dac)
      endfor
      str1= ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
        'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ATR dac', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'RAW>raw', $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules of use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', 0., $
        'SCALEMAX', 12., $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used:' +bias_file+' # '+guard_file+' # '+stub_file ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ATR', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Not yet complete V]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'ATR_DAC_table'          ,$
        'yrange' ,        [min(data.y),max(data.y)]                   ,$
        'ystyle'  ,       1.                       ,$
        'labels' ,        str1                     ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_atr_dac',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------

    ENDIF

    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  rpt_rate ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum))    ; same size as y
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y=2^(output.smp_avg[output.atr_i]+1)       ; from table 7.1.1 2^(rpt_rate_dummy+1) * MCU
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ATR rpt rate', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     cdf_istp[3], $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules of use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', 0., $
        'SCALEMAX', max(data.y)*1.2, $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used : MCU=1' ,$  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ; 'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ATR', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'atr_rpt_rate * MCU'                 ,$
        'yrange' ,        [0,max(data.y)*1.2] ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_atr_rpt_rate',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF

    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  atr_mode ---------------------------
      data =  create_struct(  $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum)  )
      ;-------------- derive  time/variable ----------------
      data.x = time
      data.y = output.ORB_MD[output.atr_i]
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ATR mode', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     cdf_istp[3], $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules of use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', -1, $
        'SCALEMAX', 18, $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used :'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ; 'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ; 'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ATR', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                 ,$
        'ytitle' ,        'ATR_mode'               ,$
        'yrange' ,        [-1,18]                  ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_atr_mode',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  ATR L1-raw  ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $                           ; double 1-D arr
        'y',    fltarr(nn_pktnum, nn_swp+12+2))                   ;1-D
      ;-------------- derive  time/variable ----------------
      for i=0L,nn_pktnum-1 do begin
        data.x[i]                    = time_sc[i]                          ;sc time only
        data.y[i,0:nn_swp-1]         = output.ATR_SWP[i,*]   ;nn_swp
        data.y[i,nn_swp+00]       = output.ATR_W_BIAS1[i]
        data.y[i,nn_swp+01]       = output.ATR_W_GUARD1[i]
        data.y[i,nn_swp+02]       = output.ATR_W_STUB1[i]
        data.y[i,nn_swp+03]       = output.ATR_LP_BIAS1[i]
        data.y[i,nn_swp+04]       = output.ATR_LP_GUARD1[i]
        data.y[i,nn_swp+05]       = output.ATR_LP_STUB1[i]
        data.y[i,nn_swp+06]       = output.ATR_W_BIAS2[i]
        data.y[i,nn_swp+07]       = output.ATR_W_GUARD2[i]
        data.y[i,nn_swp+08]       = output.ATR_W_STUB2[i]
        data.y[i,nn_swp+09]       = output.ATR_LP_BIAS2[i]
        data.y[i,nn_swp+10]       = output.ATR_LP_GUARD2[i]
        data.y[i,nn_swp+11]       = output.ATR_LP_STUB2[i]
        data.y[i,nn_swp+12]       = 2^(output.smp_avg[output.atr_i[i]]+1)  ; from table 7.1.1 2^(rpt_rate_dummy+1) * MCU
        data.y[i,nn_swp+13]       = output.ORB_MD[output.atr_i[i]]
      endfor
      str1=['adr_lp_swp'+strarr(nn_swp), $
        'W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
        'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2', $
        'Number of averaged samples','Orbit mode']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW raw L0b ATR data', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'RAW>raw', $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules of use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
        'y_catdesc',                     'See labels for individual lines', $    ;
        'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
        'y_Var_notes',                   'See labels for individual lines', $
        'xFieldnam',                     'x: UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
        'yFieldnam',                     'y: see labels for individual lines', $
        'derivn',                        'Equation of derivation', $    ;####
        'sig_digits',                    '# sig digits', $ ;#####
        'SI_conversion',                 'Convert to SI units', $  ;####
        'MONOTON',                     'INCREASE', $
        'SCALEMIN',                    min(data.y), $
        'SCALEMAX',                    max(data.y), $
        't_epoch'         ,            t_epoch, $
        'Time_start'      ,            [time_sc(0)-t_epoch,          time_sc(0)] , $
        'Time_end'        ,            [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)], $
        'Time_field'      ,            ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
        'SPICE_kernel_version',        'NaN', $
        'SPICE_kernel_flag'      ,     'SPICE not used', $
        'L0_datafile'     ,            filename_L0 , $
        'cal_source'      ,            'Information from PKT: ATR-raw', $
        'cal_vers'        ,             cal_ver+' # '+pkt_ver ,$
        'xsubtitle'       ,            '[sec]', $
        'ysubtitle'       ,            '[Raw Packet Information]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'xtitle' ,                      'Time (s/c)'             ,$
        'ytitle' ,                      'Misc'                 ,$
        'labels' ,                      str1                    ,$
        'yrange' ,                      [min(data.y),max(data.y)] )
      ;------------- store --------------------
      store_data,'mvn_lpw_atr_l0b',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------

    ENDIF
  ENDIF ELSE print, "mvn_lpw_atr.pro skipped as no packets found."

end
;*******************************************************************






