;;+
;PROCEDURE:   mvn_lpw_pkt_adr
;PURPOSE:
;  Takes the decumuted data (L0) from the ADR packet,
;  and turn it the data into tplot structures
;  NOTE mvn_lpw_pkt_atr needs to be read before mvn_lpw_pkt_adr
; ATR packet will only be provided as raw values expect for the
; sweep values that is derived into units of Volt
;
;USAGE:
;  mvn_lpw_pkt_adr,output,lpw_const,cdf_istp_lpw,tplot_var
;
;INPUTS:
;       output:         L0 data
;       lpw_const:      information of lpw calibration etc
;       cdf_istp_lpw:   information for CDF production
;
;KEYWORDS:
;       tplot_var   'all' or 'sci'  'sci' produces tplot variables that have physical units associated with them.
;                                   'all' produces all tplot variables.
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.
;
;CREATED BY:   Laila Andersson 17 august 2011
;FILE: mvn_lpw_pkt_adr.pro
;VERSION:   2.0  <------------------------------- update 'pkt_ver' variable
;LAST MODIFICATION:
;07/11/13 - Chris Fowler - added IF statement checking for data in output.p6, and keyword tplot_var.
;05/16/13
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels, since this is a read back of tables no dv or dy information exist
;04/15/14 L. Andersson included L1
;04/18/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;;140718 clean up for check out L. Andersson
;2014-10-03: CF: modified dlimit fields for ISTP compliance.
;2014-10-03:LA: change too the new bias/stub calibration from from seperate files
;
;-


pro mvn_lpw_pkt_adr, output,lpw_const,tplot_var=tplot_var,spice=spice

  IF output.p8 GT 0 THEN BEGIN  ;check we have data

    ;-------------------Check different inputs------------------------------------
    If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.
    IF output.p8 NE n_elements(output.adr_DYN_OFFSET1) then stop
    ;--------------------------------------------------------------------

    ;--------------------- Constants Used In This Routine ------------------------------------
    t_routine          =SYSTIME(0)
    t_epoch            =lpw_const.t_epoch
    today_date         =lpw_const.today_date
    cal_ver            =lpw_const.version_calib_routine
    pkt_ver            ='pkt_adr_ver  V2.0'
    cdf_istp           =lpw_const.cdf_istp_lpw
    filename_L0        =output.filename
    ;---------
    const_active_steps=lpw_const.nn_active_steps                             ; the last point is omitted, do not contain importnat information
    nn_steps=lpw_const.nn_swp_steps                                          ; nn_steps  number of input in the table note the wvalues is 128-1 because 1 point the instrument wait for everything to setle
    nn_steps2=lpw_const.nn_swp                                               ;true number of steps
    nn_pktnum=lpw_const.nn_modes
    const_V1_readback =lpw_const.V1_readback
    const_V2_readback =lpw_const.V2_readback
    mvn_lpw_cal_read_bias,bias_arr,bias_file
    mvn_lpw_cal_read_guard,guard_arr,guard_file   ;><<<<<<< not working yet!!!!!
    mvn_lpw_cal_read_stub,stub_arr,stub_file
    const_sign = lpw_const.sign
    const_lp_bias1_DAC=lpw_const.lp_bias1_DAC
    const_w_bias1_DAC=lpw_const.w_bias1_DAC
    const_lp_guard1_DAC=lpw_const.lp_guard1_DAC
    const_w_guard1_DAC=lpw_const.w_guard1_DAC
    const_lp_stub1_DAC=lpw_const.lp_stub1_DAC
    const_w_stub1_DAC=lpw_const.w_stub1_DAC
    const_lp_bias2_DAC=lpw_const.lp_bias2_DAC
    const_w_bias2_DAC=lpw_const.w_bias2_DAC
    const_lp_guard2_DAC=lpw_const.lp_guard2_DAC
    const_w_guard2_DAC=lpw_const.w_guard2_DAC
    const_lp_stub2_DAC=lpw_const.lp_stub2_DAC
    const_w_stub2_DAC=lpw_const.w_stub2_DAC
    const_bias1_readback=lpw_const.bias1_readback
    const_guard1_readback=lpw_const.guard1_readback
    const_stub1_readback=lpw_const.stub1_readback
    const_bias2_readback=lpw_const.bias2_readback
    const_guard2_readback=lpw_const.guard2_readback
    const_stub2_readback=lpw_const.stub2_readback

    ;--------------------------------------------------------------------
    nn_pktnum = output.p8                                 ; number of data packages
    ;---------------------------------------------

    ;-------------------- Get correct clock time ------------------------------
    time_sc               = double(output.SC_CLK1[output.adr_i]+output.SC_CLK2[output.adr_i]/2l^16)+t_epoch                  ;data points in s/c time
    IF keyword_set(spice) THEN BEGIN                                                                                                ;if this computer has SPICE installed:
      aa=floor(time_sc-t_epoch)
      bb=floor(((time_sc-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
      mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,time  ;correct times using SPICE
    ENDIF ELSE BEGIN
      clock_field_str  = ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00']
      time             = time_sc                                                                                            ;data points in s/c time
      clock_start_t    = [time_sc(0)-t_epoch,          time_sc(0)]                         ;corresponding start times to above string array, s/c time
      clock_end_t      = [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)] ;corresponding end times, s/c time
      spice_used       = 'SPICE not used'
      str_xtitle       = 'Time (s/c)'
      kernel_version    = 'N/A'
    ENDELSE
    ;--------------------------------------------------------------------



    ;----------  variable: LP_BIAS1 RAW + Converted    ---------------------------
    data =  create_struct(  $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
      'v',    fltarr(nn_pktnum,nn_steps) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    data.y = output.adr_lp_bias1
    for i=0,nn_pktnum-1 do data.v(i,*)=indgen(nn_steps)
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ADR lp bias1 raw', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     'RAW>raw' ,  $
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
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.v), $
      'SCALEMAX',                    max(data.v), $        ;..end of required for cdf production.
      't_epoch'         ,            t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,            'Information from PKT: ADR', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[bins]', $
      'cal_v_const1'    ,            'PKT: Bin no' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'zsubtitle'       ,            '[RAW]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'adr_lp_bias1'                 ,$
      'yrange' ,        [min(data.v),max(data.v)] ,$
      'ystyle'  ,       1.                       ,$
      'ztitle' ,        'Bias 1 (DN) '                ,$
      'zrange' ,        [min(data.y),max(data.y)],$
      'spec'            ,     1, $
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)])          ;for plotting lpw pkt lab data
    ;------------- store --------------------
    ;-------------   RAW    ----------
    ;IF tplot_var EQ 'all' THEN
    store_data,'mvn_lpw_adr_lp_bias1_raw',data=data,limit=limit,dlimit=dlimit
    ;------------------ Converted ---------------------------
    data.y                  = bias_arr(data.y,1)
    dlimit.cal_y_const1     = 'Used:  '+bias_file
    limit.zrange            = [min(data.y),max(data.y)]
    limit.ztitle            = 'Bias 1 [V]'
    dlimit.zsubtitle         = '[corr]
    store_data,'mvn_lpw_adr_lp_bias1_bin',data=data,limit=limit,dlimit=dlimit
    ;------------------ the voltage also on the y axis---------------------------
    for i=0,nn_pktnum-1 do data.v[i,*]=data.y[i,sort(data.y[i,*])]
    data.y                  = data.v
    limit.yrange            = [min(data.y),max(data.y)]
    limit.ytitle            = 'Bias 1 [V]'
    store_data,'mvn_lpw_adr_lp_bias1',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


    ;----------  variable: LP_BIAS2   RAW + Converted    ---------------------------
    data =  create_struct(      $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_steps) ,   $    ; same size as y
      'v',    fltarr(nn_pktnum,nn_steps) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    data.y = output.adr_lp_bias2
    for i=0,nn_pktnum-1 do data.v[i,*]=indgen(nn_steps)
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ADR lp bias2 raw', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     'RAW>raw' ,  $
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
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.v), $
      'SCALEMAX',                    max(data.v), $        ;..end of required for cdf production.
      't_epoch'         ,            t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,            'Information from PKT: ADR', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[bins]', $
      'cal_v_const1'    ,            'Used: Bin no' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      'zsubtitle'       ,            '[RAW]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Adr_lp_bias2'                 ,$
      'yrange' ,        [min(data.v),max(data.v)] ,$
      'ystyle'  ,       1.                       ,$
      'ztitle' ,        'Bias 2 (DN) '                ,$
      'zrange' ,        [min(data.y),max(data.y)],$
      'spec'            ,     1, $
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)])          ;for plotting lpw pkt lab data
    ;------------- store --------------------
    ;-------------   RAW    ----------
    ;IF tplot_var EQ 'all' THEN
    store_data,'mvn_lpw_adr_lp_bias2_raw',data=data,limit=limit,dlimit=dlimit
    ;------------------ Converted ---------------------------
    data.y                  = bias_arr(data.y,2)
    dlimit.cal_y_const1     = 'Used:  '+bias_file
    limit.zrange            = [min(data.y),max(data.y)]
    limit.ztitle            = 'Bias 2 [V]'
    dlimit.zsubtitle         = '[corr]
    store_data,'mvn_lpw_adr_lp_bias2_bin',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------
    ;------------------ the voltage also on the y axis---------------------------
    for i=0,nn_pktnum-1 do data.v[i,*]=data.y[i,sort(data.y[i,*])]
    data.y                  = data.v
    limit.yrange            = [min(data.y),max(data.y)]
    limit.ytitle            = 'Bias 2 [V]'
    ;limit.spec              = 1
    store_data,'mvn_lpw_adr_lp_bias2',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


    options,'mvn_lpw_adr_lp_bias*'  ,'x_no_interp',1
    options,'mvn_lpw_adr_lp_bias*'  ,'y_no_interp',1



    ;----------  variable: offset1   RAW + Converted    ---------------------------
    data =  create_struct(      $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    data.y = output.adr_dyn_offset1
    data.dy=  1    ; DN error is 1
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ADR dyn offset1 raw', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     'RAW>raw' ,  $
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
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.y), $
      'SCALEMAX',                    max(data.y), $        ;..end of required for cdf production.
      't_epoch'         ,            t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,           'Information from PKT: ADR', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[Raw]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'ADR_dyn_offset1'                 ,$
      'yrange' ,        [min(data.y),max(data.y)] ,$
      'ystyle'  ,       1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    ;-------------   RAW    ----------
    ;IF tplot_var EQ 'all' THEN
    store_data,'mvn_lpw_adr_dyn_offset1_raw',data=data,limit=limit,dlimit=dlimit
    ;---------------- Converted --------------------
    data.y                       = bias_arr(data.y,1)
    data.dy                       = (bias_arr((data.y-1)>0,1)-bias_arr((data.y+1)<4095,1))*0.5  ; the error is the size to the next value.
    dlimit.cal_y_const1          = 'Used:  '+ bias_file+ ' # '+'the error is derived as the dV too the nearby points'
    limit.ytitle                 = 'DAC offset '
    limit.yrange                 = [min(data.y),max(data.y)]
    dlimit.ysubtitle              = '[V]
    store_data,'mvn_lpw_adr_dyn_offset1',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------






    ;----------  variable: offset2    RAW + Converted   ---------------------------
    data =  create_struct(    $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum)  )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    data.y = output.adr_dyn_offset2
    data.dy= 1   ; DN error is 1
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ADR dyn offset2 raw', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     'RAW>raw' ,  $
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
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.y), $
      'SCALEMAX',                    max(data.y), $        ;..end of required for cdf production.
      't_epoch'         ,            t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,           'Information from PKT: ADR', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[Raw]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'ADR_dyn_offset2'                 ,$
      'yrange' ,        [min(data.y),max(data.y)] ,$
      'ystyle'  ,       1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    ;-------------   RAW    ----------
    ;    IF tplot_var EQ 'all' THEN
    store_data,'mvn_lpw_adr_dyn_offset2_raw',data=data,limit=limit,dlimit=dlimit
    ;---------------- Converted --------------------
    data.y                       = bias_arr(data.y,2)
    data.dy                       = (bias_arr((data.y-1)>0,1)-bias_arr((data.y+1)<4095,1))*0.5  ; the error is the size to the next value.
    dlimit.cal_y_const1          = 'Used:  '+ bias_file+ ' # '+'the error is derived as the dV too the nearby points'
    limit.ytitle                 = 'DAC offset'
    limit.yrange                 = [min(data.y),max(data.y)]
    dlimit.ysubtitle              = '[V]
    store_data,'mvn_lpw_adr_dyn_offset2',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------



    ;------------- variable:  surface_pot1  RAW + Converted  ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,6) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,6) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    data.y[*,0]=output.adr_w_bias1
    data.y[*,1]=output.adr_w_guard1
    data.y[*,2]=output.adr_w_stub1
    data.y[*,3]=output.adr_w_v1
    data.y[*,4]=output.adr_lp_guard1
    data.y[*,5]=output.adr_lp_stub1
    str1=['ADR_W_BIAS1','ADR_W_GUARD1','ADR_W_STUB1','ADR_W_V1' ,'ADR_LP_GUARD1','ADR_LP_STUB1']
    data.dy[*,0:5]=1. ;DN error is 1
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ADR surface pot1 raw', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     'RAW>raw' ,  $
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
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.y), $
      'SCALEMAX',                    max(data.y), $        ;..end of required for cdf production.
      't_epoch'         ,            t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,            'Information from PKT: ADR', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[Raw]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Different potentials 1' ,$
      'yrange' ,        [min(data.y),max(data.y)],$
      'ystyle'  ,       1.                       ,$
      'labels' ,        str1                      ,$
      'colors' ,        [1,2,3,4,5,6]            ,$
      'labflag' ,       1                        ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    ;-------------   RAW    ----------
    ;IF tplot_var EQ 'all' THEN
    store_data,'mvn_lpw_adr_surface_pot1_raw',data=data,limit=limit,dlimit=dlimit
    ;---------------- Converted --------------------
    limit.ytitle                 = 'Diff Readback Pot 1'
    dlimit.ysubtitle              = '[V]'
    dlimit.cal_y_const1='PKT level:' +stub_file+' # '+guard_file+' # '+bias_file+' # V1 readback '+strcompress(const_V1_readback,/remove_all) + ' # error not derived'
    data.y[*,0]      = bias_arr(data.y[*,0],1)
    data.y[*,1]      = guard_arr(data.y[*,1],1)
    data.y[*,2]      = stub_arr(data.y[*,2],1)
    data.y[*,3]      = data.y[*,3]*const_V1_readback        ;output.adr_w_v1*const_V1_readback
    data.y[*,4]      = guard_arr(data.y[*,4],1)
    data.y[*,5]      = stub_arr(data.y[*,5],1)
    data.dy[*,0]      = (bias_arr( (data.y[*,0]-1)>0,1)-bias_arr( (data.y[*,0]+1)<4095,1))*0.5
    data.dy[*,1]      = (guard_arr((data.y[*,0]-1)>0,1)-guard_arr((data.y[*,0]+1)<4095,1))*0.5
    data.dy[*,2]      = (stub_arr( (data.y[*,0]-1)>0,1)-stub_arr( (data.y[*,0]+1)<4095,1))*0.5
    data.dy[*,3]      = 1.*const_V1_readback
    data.dy[*,4]      = (guard_arr((data.y[*,0]-1)>0,1)-guard_arr((data.y[*,0]+1)<4095,1))*0.5
    data.dy[*,5]      = (stub_arr( (data.y[*,0]-1)>0,1)-stub_arr( (data.y[*,0]+1)<4095,1))*0.5
    limit.yrange     =[min(data.y),max(data.y)]
    store_data,'mvn_lpw_adr_surface_pot1',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


    ;------------- variable:  surface_pot2   RAW + Converted  ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,6) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,6) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time
    data.y[*,0]=output.adr_w_bias2
    data.y[*,1]=output.adr_w_guard2
    data.y[*,2]=output.adr_w_stub2
    data.y[*,3]=output.adr_w_v2
    data.y[*,4]=output.adr_lp_guard2
    data.y[*,5]=output.adr_lp_stub2
    str1=['ADR_W_BIAS2','ADR_W_GUARD2','ADR_W_STUB2','ADR_W_V2' ,'ADR_LP_GUARD2','ADR_LP_STUB2']
    data.dy[*,0:5]=1.
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'ADR surface pot2 raw', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     'RAW>raw' ,  $
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
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.y), $
      'SCALEMAX',                    max(data.y), $        ;..end of required for cdf production.
      't_epoch'         ,            t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_source'      ,            'Information from PKT: ADR', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[Raw]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'Different potentials 2' ,$
      'yrange' ,        [min(data.y),max(data.y)],$
      'ystyle'  ,       1.                       ,$
      'labels' ,        str1                      ,$
      'colors' ,        [1,2,3,4,5,6]            ,$
      'labflag' ,       1                        ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    ;-------------   RAW    ----------
    ;IF tplot_var EQ 'all' THEN
    store_data,'mvn_lpw_adr_surface_pot2_raw',data=data,limit=limit,dlimit=dlimit
    ;---------------- Converted --------------------
    limit.ytitle                  = 'Diff Readback Pot 2'
    dlimit.ysubtitle              = '[V]'
    dlimit.cal_y_const1='PKT level:' +stub_file+' # '+guard_file+' # '+bias_file+' # V2 readback '+strcompress(const_V2_readback,/remove_all) + ' # error not derived'
    data.y[*,0]       = bias_arr(data.y[*,0],2)
    data.y[*,1]       = guard_arr(data.y[*,1],2)
    data.y[*,2]       = stub_arr(data.y[*,2],2)
    data.y[*,3]       = data.y[*,3]*const_V2_readback        ;output.adr_w_v2*const_V2_readback
    data.y[*,4]       = guard_arr(data.y[*,4],2)
    data.y[*,5]       = stub_arr(data.y[*,5],2)
    data.dy[*,0]      = (bias_arr( (data.y[*,0]-1)>0,2)-bias_arr( (data.y[*,0]+1)<4095,2))*0.5
    data.dy[*,1]      = (guard_arr((data.y[*,0]-1)>0,2)-guard_arr((data.y[*,0]+1)<4095,2))*0.5
    data.dy[*,2]      = (stub_arr( (data.y[*,0]-1)>0,2)-stub_arr( (data.y[*,0]+1)<4095,2))*0.5
    data.dy[*,3]      = 1.*const_V2_readback
    data.dy[*,4]      = (guard_arr((data.y[*,0]-1)>0,2)-guard_arr((data.y[*,0]+1)<4095,2))*0.5
    data.dy[*,5]      = (stub_arr( (data.y[*,0]-1)>0,2)-stub_arr( (data.y[*,0]+1)<4095,2))*0.5
    limit.yrange     =[min(data.y),max(data.y)]
    store_data,'mvn_lpw_adr_surface_pot2',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  smp_avg ---------------------------
      data =  create_struct(  $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time
      data.y = 2^(output.smp_avg[output.adr_i]+1)       ;from table 7.6  2^(smp_avg+1)
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ADR sample average', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     cdf_istp[3] ,  $
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
        'SCALEMIN', min(0.), $
        'SCALEMAX', max(data.y)*1.2, $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: converted '  , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ADR', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'ADR_smp_avg'                 ,$
        'yrange' ,        [0,max(data.y)*1.2] ,$
        'ystyle'  ,       1.                       ,$
        'ylog'   ,        1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])             ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_adr_smp_avg',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF

    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  adr_mode ---------------------------
      data =  create_struct( $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time
      data.y = output.ORB_MD[output.adr_i]
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ADR mode', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     cdf_istp[3] ,  $
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
        'cal_y_const1'    ,     'Used: No' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: ADR', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'ADR_mode'                 ,$
        'yrange' ,        [-1,18] ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_adr_mode',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF



    ;*******************************************************************************************
    ;***************     Second half where ADR is compared with ATR    *************************
    ;*******************************************************************************************
    ;adr is always after atr, hence match to a atr before this time stamp

    ;    IF tplot_var EQ 'all' THEN BEGIN
    IF 'all' EQ 'all' THEN BEGIN
      ;-------------- Set up the fundamental so  Expected ATR can be derived (12 different values is created below)----------------
      ;------------------------------ This is will then be compared to ADR_raw*const ----------------------------------------------
      ;----------------------------------   The time is based on the ATR time stamp ----------------------------------------------
      ;---- To get the ADR time-stamp I expect the  ATR(data0) packet first for the matching ADR(data1) packet  ------------
      get_data,'mvn_lpw_atr_dac',data=data0,dlimit=dlimit0    ; this is what we based it on
      get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1,dlimit=dlimit1  ;data1.y(*,3)=output.adr_w_v1
      ;-------------
      data =  create_struct(  $
        'x',    dblarr(n_elements(data0.x)) ,  $     ; double 1-D arr
        'y',    fltarr(n_elements(data0.x)) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = data0.x
      ;data.y =   ; will be different for all 12 variables  ;this will change below
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'exp_ATR_bias1_LP', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'RAW>raw' ,  $
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
        'MONOTON',                     'INCREASE', $
        'SCALEMIN',                    min(data.y), $
        'SCALEMAX',                    max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,            t_epoch, $
        'Time_start'      ,            clock_start_t, $
        'Time_end'        ,            clock_end_t, $
        'Time_field'      ,            clock_field_str, $
        'SPICE_kernel_version',        kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,            filename_L0 , $
        'cal_vers'        ,            cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,            'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        'cal_source'      ,            'Information from PKT: ADR and ATR', $
        'xsubtitle'       ,            '[sec]', $
        'ysubtitle'       ,            '[DAC [V?]]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'expect_ATR_X'                 ,$
        'yrange' ,        [min(data.y),max(data.y)] ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      ;-------------
      ;---------------- Create 10 of the 12 variables ----------------------
      ;---------------- mvn_lpw_expect_ATR_bias1_wave --------------------
      ;mvn_lpw_atr_dac:  data0.y(*,0)=output.ATR_W_BIAS1(i)
      get_data,'mvn_lpw_atr_dac_raw',data=data0,dlimit=dlimit0    ; this is what we based it on
      get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1,dlimit=dlimit1  ;data1.y(*,3)=output.adr_w_v1
      sort_data1=fltarr(n_elements(data0.x))     ;DO I HAVE TO DO THIS ON ALL VARIABLES BELOW?
      for i=0,n_elements(data0.x)-1 do BEGIN
        qq=min(abs( (data0.x[i]-data1.x) +1e9*(data0.x[i]-data1.x LT 0)),nq)  ;find the right ADR(data1) match to the ATR(data0) time
        sort_data1[i]=nq
      endfor
      dlimit.cal_y_const1='PKT level:' + strcompress(const_w_bias1_DAC,/remove_all) +' # '+ $
        strcompress(const_V1_readback,/remove_all)
      data.y = (data0.y[*,0]-const_sign)*const_w_bias1_DAC +(data1.y[sort_data1,3]*const_V1_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          bias_file+' # V1 readback '+strcompress(const_V1_readback,/remove_all)
      ;data.y = bias_arr(data0.y[*,0],1) +(data1.y[sort_data1,3]*const_V1_readback)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_bias1_wave'
      store_data,'mvn_lpw_exp_ATR_bias1_wave',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_guard1_wave --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,1]=output.ATR_W_GUARD1[i]
      get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1,dlimit=dlimit1  ;data1.y[*,3]=output.adr_w_v1
      dlimit.cal_y_const1='PKT level:' + strcompress(const_w_guard1_DAC,/remove_all) +' # '+ $
        strcompress(const_V1_readback,/remove_all)
      data.y = (data0.y[*,1]-const_sign)*const_w_guard1_DAC +(data1.y[sort_data1,3]*const_V1_readback)
      ;             dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;                      guard_file+' # V1 readback '+strcompress(const_V1_readback,/remove_all)
      ;            data.y = guard_arr(data0.y[*,1],1) +(data1.y[sort_data1,3]*const_V1_readback)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_guard1_wave'
      store_data,'mvn_lpw_exp_ATR_guard1_wave',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_stub1_wave --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,2]=output.ATR_W_STUB1[i]
      get_data,'mvn_lpw_adr_surface_pot1_raw',data=data1,dlimit=dlimit1  ;data1.y[*,3]=output.adr_w_v1
      data.y = (data0.y[*,2]-const_sign)*const_w_stub1_DAC +(data1.y[sort_data1,3]*const_V1_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          stub_file+' # V1 readback '+strcompress(const_V1_readback,/remove_all)
      ;data.y = stub_arr(data0.y[*,2],1) +(data1.y[sort_data1,3]*const_V1_readback)
      limit.yrange=[-5,5] ;[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_stub1_wave'
      store_data,'mvn_lpw_exp_ATR_stub1_wave',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_bias2_wave --------------------
      ;mvn_lpw_atr_dac:  data0.y[*,6]=output.ATR_W_BIAS2[i]
      get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1,dlimit=dlimit1  ;data1.y[*,3]=output.adr_w_v2
      dlimit.cal_y_const1='PKT level:' + strcompress(const_w_bias2_DAC,/remove_all) +' # '+ $
        strcompress(const_V2_readback,/remove_all)
      data.y = (data0.y[*,6]-const_sign)*const_w_bias2_DAC +(data1.y[sort_data1,3]*const_V2_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          bias_file+' # V2 readback '+strcompress(const_V2_readback,/remove_all)
      ;data.y = bias_arr(data0.y[*,6],2) +(data1.y[sort_data1,3]*const_V2_readback)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_bias2_wave'
      store_data,'mvn_lpw_exp_ATR_bias2_wave',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_guard2_wave --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,7]=output.ATR_W_GUARD2[i]
      get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1,dlimit=dlimit1  ;data1.y[*,3]=output.adr_w_v2
      dlimit.cal_y_const1='PKT level:' + strcompress(const_w_guard2_DAC,/remove_all) +' # '+ $
        strcompress(const_V2_readback,/remove_all)
      data.y = (data0.y[*,7]-const_sign)*const_w_guard2_DAC +(data1.y[sort_data1,3]*const_V2_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          guard_file+' # V2 readback '+strcompress(const_V2_readback,/remove_all)
      ;data.y = guard_arr(data0.y[*,7],2) +(data1.y[sort_data1,3]*const_V2_readback)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_guard2_wave'
      store_data,'mvn_lpw_exp_ATR_guard2_wave',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_stub2_wave --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,8]=output.ATR_W_STUB2[i]
      get_data,'mvn_lpw_adr_surface_pot2_raw',data=data1,dlimit=dlimit1  ;data1.y[*,3]=output.adr_w_v2
      dlimit.cal_y_const1='PKT level:' + strcompress(const_w_stub2_DAC,/remove_all) +' # '+ $
        strcompress(const_V2_readback,/remove_all)
      data.y = (data0.y[*,8]-const_sign)*const_w_stub2_DAC +(data1.y[sort_data1,3]*const_V2_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          stub_file+' # V2 readback '+strcompress(const_V2_readback,/remove_all)
      ;data.y = stub_arr(data0.y[*,8],2) +(data1.y[sort_data1,3]*const_V2_readback)
      limit.yrange=[-5,5] ;[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_stub2_wave'
      store_data,'mvn_lpw_exp_ATR_stub2_wave',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_bias1_LP   moved down since this will be 128 of them --------------------
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_guard1_LP --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,4]=output.ATR_LP_GUARD1[i]
      get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1,dlimit=dlimit1           ;data1.y[*,127]=output.adr_lp_bias1[*,127]
      dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_guard1_DAC,/remove_all) +' # '+ $
        strcompress(const_bias1_readback,/remove_all)
      data.y = (data0.y[*,4]-const_sign)*const_lp_guard1_DAC +(data1.y[sort_data1,126]*const_bias1_readback)
      ;          dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;                    guard_file+' # V2 readback '+strcompress(const_V2_readback,/remove_all)
      ;     data.y = guard_arr(data0.y[*,4],2) +(data1.y[sort_data1,3]*const_V2_readback)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_guard1_LP'
      store_data,'mvn_lpw_exp_ATR_guard1_LP',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_stub1_LP --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,5]=output.ATR_LP_STUB1[i]
      get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1,dlimit=dlimit1           ;data1.y[*,127]=output.adr_lp_bias1[*,127]
      dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_stub1_DAC,/remove_all) +' # '+ $
        strcompress(const_bias1_readback,/remove_all)
      data.y = (data0.y[*,5]-const_sign)*const_lp_stub1_DAC +(data1.y[sort_data1,126]*const_bias1_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          stub_file+' # '+bias_file
      ;data.y = stub_arr(data0.y[*,5],1) +bias_arr(data1.y[sort_data1,126],1)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_stub1_LP'
      store_data,'mvn_lpw_exp_ATR_stub1_LP',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_bias2_LP   moved down since this will be 128 of them --------------------
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_guard12_LP --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,10]=output.ATR_LP_GUARD2[i]
      get_data,'mvn_lpw_adr_lp_bias2_raw',data=data1,dlimit=dlimit1           ;data1.y[*,127]=output.adr_lp_bias2[*,127]
      dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_guard2_DAC,/remove_all) +' # '+ $
        strcompress(const_bias2_readback,/remove_all)
      data.y = (data0.y[*,10]-const_sign)*const_lp_guard2_DAC +(data1.y[sort_data1,126]*const_bias2_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          guard_file+' # '+bias_file
      ;data.y = guard_arr(data0.y[*,10],2) +bias_arr(data1.y[sort_data1,126],2)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_guard2_LP'
      store_data,'mvn_lpw_exp_ATR_guard2_LP',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_stub2_LP --------------------
      ;mvn_lpw_atr_dac:  data0.y[i,11]=output.ATR_LP_STUB2[i]
      get_data,'mvn_lpw_adr_lp_bias2_raw',data=data1,dlimit=dlimit1           ;data1.y[*,127]=output.adr_lp_bias2[*,127]
      dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_stub2_DAC,/remove_all) +' # '+ $
        strcompress(const_bias2_readback,/remove_all)
      data.y = (data0.y[*,11]-const_sign)*const_lp_stub2_DAC +(data1.y[sort_data1,126]*const_bias2_readback)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+ dlimit1.cal_y_const1 +' # ' + $
      ;          stub_file+' # '+bias_file
      ;data.y = stub_arr(data0.y[*,11],2) +bias_arr(data1.y[sort_data1,126],2)
      limit.yrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_stub2_LP'
      store_data,'mvn_lpw_exp_ATR_stub2_LP',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- Create the last 2 of the 12 variables ----------------------
      ;;LP
      ;---------------- mvn_lpw_expect_ATR_bias1_LP     128 of them --------------------
      data =  create_struct(   $
        'x',    dblarr(n_elements(data0.x)) ,  $     ; double 1-D arr
        'y',    fltarr(n_elements(data0.x),nn_steps2) ,  $     ; most of the time float and 1-D or 2-D
        'v',    fltarr(n_elements(data0.x),nn_steps2)  )     ;1-D
      ;-------------- derive  time/variable ----------------
      ;mvn_lpw_atr_dac:  data0.y[*,3]=output.ATR_LP_BIAS1[i]
      get_data,'mvn_lpw_atr_swp_raw',data=data1,dlimit=dlimit1  ;data1.y[i,*]=(output.ATR_SWP[i,*] - const_sign) *const_DAC_volt   ;  not unique to boom 1 or boom 2
      data.x=data0.x  ;(sort_data0)
      print,'#################'
      sort_data1=fltarr(n_elements(data0.x))
      for i=0,n_elements(data0.x)-1 do BEGIN
        qq=min(abs( (data0.x[i]-data1.x) +1e9*(data0.x[i]-data1.x LT 0)),nq)  ;find the right ADR(data1) match to the ATR(data0) time
        sort_data1[i]=nq
        ; print,i,nq,data0.x[i]-data1.x[nq],' EE ',(data0.x[i]-data1.x)
      endfor
      for i=0,n_elements(data0.x)-1 do begin
        ;change to
        ;where Func(TBD) is first ATR packet that has the applicable orbital mode in the tertiary header
        data.y[i,*] =(data0.y[i,3]-const_sign)*const_lp_bias1_DAC+data1.y[sort_data1[i],*] + 0.  ;the '0' is because this is grounded
        ;data.y[i,*] =bias_arr(data0.y[i,3],1)+data1.y[sort_data1[i],*] + 0.  ;the '0' is because this is grounded
        data.v[i,*]=data1.v[sort_data1[i],*]
      endfor
      ;-------------------------------------------
      ;
      ; dlimit.cal_y_const1='PKT level:' + strcompress(const_lp_bias1_DAC,/remove_all)
      dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+dlimit1.cal_y_const1+' # ' + bias_file
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'expected_ATR_bias1_LP'                 ,$
        'yrange' ,        [min(data.v),max(data.v)] ,$
        'ystyle'  ,       1.                       ,$
        'ztitle' ,        'Points'                ,$
        'zrange' ,        [min(data.y),max(data.y)],$
        'spec'   ,        1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])             ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_exp_ATR_bias1_LP',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
      ;---------------- mvn_lpw_expect_ATR_bias2_LP     128 of them --------------------
      ;mvn_lpw_atr_dac:  data0.y[*,9]=output.ATR_LP_BIAS2[i]

      dlimit.cal_y_const1='Used:' + strcompress(const_lp_bias2_DAC,/remove_all)
      ;dlimit.cal_y_const1='Used: '+ dlimit0.cal_y_const1+' # '+dlimit1.cal_y_const1+' # ' + bias_file                                                               ;
      for i=0,n_elements(data0.x)-1 do begin
        data.y[i,*] =(data0.y[i,9]-const_sign)*const_lp_bias2_DAC+data1.y[sort_data1[i],*] + 0.  ;the '0' is because this is grounded
        ;data.y[i,*] =bias_arr(data0.y[i,9],2)+data1.y[sort_data1[i],*] + 0.  ;the '0' is because this is grounded
      endfor
      limit.zrange=[min(data.y),max(data.y)]
      limit.ytitle='expected_ATR_bias2_LP'
      store_data,'mvn_lpw_exp_ATR_bias2_LP',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    endif



    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  ADR L1-raw  ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $                                 ; double 1-D arr
        'y',    fltarr(nn_pktnum, 2*nn_steps+16))                        ; packet info
      ;-------------- derive  time/variable ----------------
      for i=0L,nn_pktnum-1 do begin
        data.x[i]                         = time_sc[i]                            ; sc time only
        data.y[i,nn_steps*0:1*nn_steps-1] = output.adr_lp_bias1[i,*]              ; nn_steps
        data.y[i,nn_steps*1:2*nn_steps-1] = output.adr_lp_bias2[i,*]              ; nn_steps
        data.y[i,2*nn_steps+00]           = output.adr_dyn_offset1[i]             ; 1
        data.y[i,2*nn_steps+01]           = output.adr_dyn_offset2[i]             ; 1
        data.y[i,2*nn_steps+02]           = output.adr_w_bias1[i]                 ; 1
        data.y[i,2*nn_steps+03]           = output.adr_w_bias2[i]                 ; 1
        data.y[i,2*nn_steps+04]           = output.adr_w_guard1[i]                ; 1
        data.y[i,2*nn_steps+05]           = output.adr_w_guard2[i]                ; 1
        data.y[i,2*nn_steps+06]           = output.adr_w_stub1[i]                 ; 1
        data.y[i,2*nn_steps+07]           = output.adr_w_stub2[i]                 ; 1
        data.y[i,2*nn_steps+08]           = output.adr_w_v1[i]                    ; 1
        data.y[i,2*nn_steps+09]           = output.adr_w_v2[i]                    ; 1
        data.y[i,2*nn_steps+10]           = output.adr_lp_guard1[i]               ; 1
        data.y[i,2*nn_steps+11]           = output.adr_lp_guard2[i]               ; 1
        data.y[i,2*nn_steps+12]           = output.adr_lp_stub1[i]                ; 1
        data.y[i,2*nn_steps+13]           = output.adr_lp_stub2[i]                ; 1
        data.y[i,2*nn_steps+14]           = 2^(output.smp_avg[output.adr_i[i]]+1) ;from table 7.6  2^(smp_avg+1)
        data.y[i,2*nn_steps+15]           = output.ORB_MD[output.adr_i[i]]
      endfor
      str1=['adr_lp_bias1'+strarr(nn_steps),'adr_lp_bias1'+strarr(nn_steps), $
        'adr_dyn_offset1',               'adr_dyn_offset2', $
        'adr_w_bias1',                   'adr_w_bias2', $
        'adr_w_guard1',                  'adr_w_guard2',  $
        'adr_w_stub1',                   'adr_w_stub2',  $
        'adr_w_v1',                      'adr_w_v2',   $
        'adr_lp_guard1',                 'adr_lp_guard2',  $
        'adr_lp_stub1',                  'adr_lp_stub2',  $
        'Number of averaged samples',    'Orbit mode']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'ADR raw, L0b', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'RAW>raw' ,  $
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
        'cal_source'      ,            'Information from PKT:  ADR-raw', $
        'cal_vers'        ,             cal_ver+' # '+pkt_ver ,$
        'xsubtitle'       ,            '[sec]', $
        'ysubtitle'       ,            '[Raw Packet Information]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'xtitle' ,        'SC Time'              ,$
        'ytitle' ,        'Misc'                 ,$
        'labels' ,        str1                    ,$
        'yrange' ,        [min(data.y),max(data.y)] )
      ;------------- store --------------------
      store_data,'mvn_lpw_adr_l0b',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


    ENDIF
  ENDIF ELSE print, "mvn_lpw_adr.pro skipped as no packets found."

end
;*******************************************************************




