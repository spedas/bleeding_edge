;;+
;PROCEDURE:   mvn_lpw_pkt_euv
;PURPOSE:
;  Start to the process to get the data into physical units
;  Take L0 data and trun them into tplot varibles
;  for some variables is claibrated
;
;USAGE:
;  mvn_lpw_pkt_euv,output,lpw_const,cdf_istp_euv,tplot_var
;
;INPUTS:
;       output:         L0 data
;       lpw_const:      information of lpw calibration etc
;       cdf_istp_euv:   information for CDF production
;
;KEYWORDS:
;       tplot_var   'all' or 'sci'  'sci' produces tplot variables that have physical units associated with them.
;                                   'all' produces all tplot variables.
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.
;
;CREATED BY:   Laila Andersson 27 July 2011
;FILE: mvn_lpw_pkt_euv.pro
;VERSION:   2.0   <------------------------------- update 'pkt_ver' variable
;LAST MODIFICATION:
; last change: 02/27/14 CF: added in SPICE routines to get SPICE corrected times.
; 2013, July 11th, Chris Fowler - IF statement added to check for data; added keyword tplot_var
; 11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
; 04/15/14 L. Andersson included L1
;04/18/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. Andersson
;2014-10-03: CF: modified dlimit fields for ISTP compliance.
;-

pro mvn_lpw_pkt_euv, output,lpw_const,tplot_var=tplot_var, spice=spice


  IF output.p7 GT 0 THEN BEGIN  ;check we have data

    ;-------------------Check different inputs------------------------------------
    If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.
    ;-----------------------------------------

    ;--------------------- Constants ------------------------------------
    t_routine          = SYSTIME(0)
    t_epoch            = lpw_const.t_epoch
    today_date         = lpw_const.today_date
    pkt_ver            = 'Pkt_euv_ver  2.0'
    cal_ver            = lpw_const.version_calib_routine  ;<------------- presently only one file, no selection needed
    filename_L0        = output.filename
    ;---------
    nn_steps       = lpw_const.nn_euv               ;number steps in one package
    nn_diodes      = lpw_const.nn_euv_diodes       ;number of diodes
    dt             = lpw_const.dt_euv                     ; time step
    euv_diod_A     = lpw_const.euv_diod_A    ;convert diode from raw to units
    euv_diod_B     = lpw_const.euv_diod_B    ;convert diode from raw to units
    euv_diod_C     = lpw_const.euv_diod_C    ;convert diode from raw to units
    euv_diod_D     = lpw_const.euv_diod_D    ;convert diode from raw to units
    euv_temp       = lpw_const.euv_temp        ;convert temp  from raw to units
    calib_file_euv = lpw_const.calib_file_euv   ; time sencitive
    cdf_istp       = lpw_const.cdf_istp_euv
    ;--------------------------------------------------------------------
    nn_pktnum=output.p7                               ; number of data packages
    nn_size=nn_pktnum*nn_steps                        ; number of data points
    ;--------------------------------------------------------------------


    ;the way we do the clock (fix sc_dt and then spice) gives us a unsertainty of 1e-6/16 SEC in time TBR

    ;-------------------- Get correct clock time ------------------------------
    time_sc = double(output.SC_CLK1[output.euv_i]+output.SC_CLK2[output.euv_i]/2l^16)+t_epoch  ;packet time in s/c time
    dt=dt*2.^(output.smp_avg[output.euv_i]+6) / 2.^10                                          ; time step corrected for smp_avg
    time_dt = dblarr(nn_pktnum*nn_steps)                                                                                  ;will hold times for subcycles within each packet
    for i=0L,nn_pktnum-1 do time_dt[nn_steps*i:nn_steps*(i+1)-1]  =time_sc[i]+dt*indgen(nn_steps)

    IF keyword_set(spice)  THEN BEGIN                                                                                                ;if this computer has SPICE installed:
      aa=floor(time_sc-t_epoch)
      bb=floor(((time_sc-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
      mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,time  ;correct times using SPICE
      aa=floor(time_dt-t_epoch)
      bb=floor(((time_dt-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
      mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t_dt,clock_end_t_dt,spice,spice_used,str_xtitle,kernel_version,time_dt  ;correct times using SPICE
    ENDIF ELSE BEGIN
      clock_field_str  = ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00']
      time             = time_sc                                                                                            ;data points in s/c time
      clock_start_t    = [time_sc(0)-t_epoch,          time_sc(0)]                         ;corresponding start times to above string array, s/c time
      clock_end_t      = [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)]               ;corresponding end times, s/c time
      spice_used       = 'SPICE not used'
      str_xtitle       = 'Time (s/c)'
      kernel_version    = 'N/A'
      clock_start_t_dt = [time_dt(0)-t_epoch,          time_dt(0)]
      clock_end_t_dt   = [time_dt(nn_pktnum-1)-t_epoch,time_dt(nn_pktnum-1)]
    ENDELSE
    ;--------------------------------------------------------------------


    ;------------- variable:  EUV 4-diodes ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_size) ,  $     ; double 1-D arr
      'y',    fltarr(nn_size,nn_diodes) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_size,nn_diodes) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x=time_dt
    for i=0L,nn_pktnum-1 do begin
      data.y[nn_steps*i:nn_steps*(i+1)-1,0] =output.DIODE_A[i,*]*euv_diod_A  ;'DIODE A'
      data.y[nn_steps*i:nn_steps*(i+1)-1,1] =output.DIODE_B[i,*]*euv_diod_B  ;'DIODE B'
      data.y[nn_steps*i:nn_steps*(i+1)-1,2] =output.DIODE_C[i,*]*euv_diod_C  ;'DIODE C'
      data.y[nn_steps*i:nn_steps*(i+1)-1,3] =output.DIODE_D[i,*]*euv_diod_D  ;'DIODE D'
      data.dy[nn_steps*i:nn_steps*(i+1)-1,0]=output.DIODE_A[i,*]*euv_diod_A *0.1
      data.dy[nn_steps*i:nn_steps*(i+1)-1,1]=output.DIODE_B[i,*]*euv_diod_B *0.1
      data.dy[nn_steps*i:nn_steps*(i+1)-1,2]=output.DIODE_C[i,*]*euv_diod_C *0.1
      data.dy[nn_steps*i:nn_steps*(i+1)-1,3]=output.DIODE_D[i,*]*euv_diod_D *0.1
    endfor
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    ;These are the fields the CDF write consider
    dlimit=create_struct(   $
      'Product_name',                  'MAVEN LPW raw EUV', $
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
      'Rules_of_use',                  cdf_istp[11], $
      'Acknowledgement',               cdf_istp[13],   $
      'MONOTON',                     'INCREASE', $
      'SCALEMIN',                    min(data.y), $
      'SCALEMAX',                    max(data.y), $
      't_epoch',                     t_epoch, $
      'Time_start'      ,            clock_start_t, $
      'Time_end'        ,            clock_end_t, $
      'Time_field'      ,            clock_field_str, $
      'SPICE_kernel_version',        kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,            filename_L0 , $
      'cal_vers',                    cal_ver+' # '+pkt_ver ,$
      'cal_y_const1' ,               'Used: '+strcompress(euv_diod_A,/remove_all)+' # ' + $
      strcompress(euv_diod_B,/remove_all)+' # ' + $
      strcompress(euv_diod_C,/remove_all)+' # ' + $
      strcompress(euv_diod_D,/remove_all) , $
      'cal_y_const2',                'NA', $
      'cal_datafile',                calib_file_euv , $
      'cal_source',                  'Information from PKT: EUV', $
      'flag_info',                   'NA', $
      'flag_source',                 'NA', $
      'xsubtitle',                   '[sec]', $
      'ysubtitle',                   '[Raw * D]', $
      'cal_v_const1',                'NA', $
      'cal_v_const2',                'NA', $
      'zsubtitle',                   'NA')
    ;-------------  limit ----------------
    ;limit options for CDF production: CHAR_SIZE, XTITLE, YTITLE, YRANGE, YSTYLE, YLOG, ZTITLE, ZRANGE, ZLOG, SPEC, COLORS, LABELS, LABFLAG, NOERRORBARS
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle               ,$
      'ytitle' ,        'mvn_lpw_euv'                 ,$
      'yrange' ,        [min(data.y),max(data.y)] ,$
      'ystyle'  ,       1.                       ,$
      'labels' ,        ['diod!DA!N','diod!DB!N','diod!DC!N','diod!DD!N']  ,$
      'colors' ,        [0,2,4,6]                     ,$
      'labflag' ,       1                        ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars',    1)
    ;------------- store --------------------
    store_data,'mvn_lpw_euv',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------

    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable: EUV_temp RAW ---------------------------
      data =  create_struct(    $
        'x',    dblarr(nn_size) ,  $     ; double 1-D arr
        'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
        'dy',   fltarr(nn_size) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time_dt
      for i=0L,nn_pktnum-1 do begin
        data.y[nn_steps*i:nn_steps*(i+1)-1] = output.THERM[i,*]
        data.dy[nn_steps*i:nn_steps*(i+1)-1]= 0
      endfor
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW EUV raw temperature', $
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
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON',                       'INCREASE', $
        'SCALEMIN',                      min(data.y), $
        'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver , $
        'cal_y_const1'    ,     'Used: Raw' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        'cal_datafile'    ,     calib_file_euv , $
        'cal_source'      ,     'Information from PKT: EUV', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Raw]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'EUV temp'                 ,$
        'yrange' ,        [min(data.y),max(data.y)] ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
        'noerrorbars',    1)
      ;------------- store --------------------
      store_data,'mvn_lpw_euv_temp',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF



    ;------------- variable: EUV_temp C deg---------------------------
    ;If you take the 20 bit temperature data and divide it by 16 to get 16 bit numbers, the numbers should follow the following conversion:
    ;Temp_in_DN(16 bit) = 41.412 x Temp_in_deg_C - 8160.7
    ;    (measured *  euv_temp(0) +   euv_temp(1)) /euv_temp(2)  = Temp_in_deg_C
    data =  create_struct(  $
      'x',    dblarr(nn_size) ,  $     ; double 1-D arr
      'y',    fltarr(nn_size) ,  $     ; double 1-D arr
      'dy',    fltarr(nn_size) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time_dt
    for i=0L,nn_pktnum-1 do begin
      data.y[nn_steps*i:nn_steps*(i+1)-1] = (output.THERM[i,*] *  euv_temp[0] +   euv_temp[1]) /euv_temp[2]
      data.dy[nn_steps*i:nn_steps*(i+1)-1]= 0
    endfor
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'MAVEN LPW EUV temperature', $
      'Project',                       cdf_istp[12], $
      'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
      'Discipline',                    cdf_istp[1], $
      'Instrument_type',               cdf_istp[2], $
      'Data_type',                     cdf_istp[3],  $
      'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
      'Descriptor',                    cdf_istp[5], $
      'PI_name',                       cdf_istp[6], $
      'PI_affiliation',                cdf_istp[7], $
      'TEXT',                          cdf_istp[8], $
      'Mission_group',                 cdf_istp[9], $
      'Generated_by',                  cdf_istp[10],  $
      'Generation_date',                today_date+' # '+t_routine, $
      'Rules_of_use',                  cdf_istp[11], $
      'Acknowledgement',               cdf_istp[13],   $
      'MONOTON',                       'INCREASE', $
      'SCALEMIN',                       min(data.y), $
      'SCALEMAX',                       max(data.y), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t_dt, $
      'Time_end'        ,     clock_end_t_dt, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: ' + strcompress(euv_temp[0],/remove_all) +' # ' + $
      strcompress(euv_temp[1],/remove_all) +' # ' + $
      strcompress(euv_temp[2],/remove_all) , $
      ; 'cal_y_const2'    ,     'Used :'
      'cal_datafile'    ,     calib_file_euv, $
      'cal_source'      ,     'Information from PKT: EUV', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Deg C]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'EUV Temp'                 ,$
      'yrange' ,        [min(data.y),max(data.y)] ,$
      'ystyle'  ,       1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_euv_temp_C',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;---------variable: info of the start of each packet -----------------
      data =  create_struct(     $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x= time_sc
      data.y=1.0
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW EUV packet start', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'Support_data',  $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON',                        'INCREASE', $
        'SCALEMIN',                      'NA', $
        'SCALEMAX',                      'NA', $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_source'      ,     'Information from PKT: EUV', $  ; only information of when each packet starts
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'None'                 )              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_euv_packet_start',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------



      ;------------- variable:  smp_avg ---------------------------
      data =  create_struct(  $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum))     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y=2.^(output.smp_avg[output.euv_i]+6)       ; from ICD section 7.6
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW EUV smp average', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'Support_data',  $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON',                       'INCREASE', $
        'SCALEMIN',                      2^6, $
        'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: NaN ' , $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: EUV', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'EUV_smp_avg'                 ,$
        'yrange' ,        [2^6,max(data.y)],$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_euv_smp_avg',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  EUV L1-raw  ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,(nn_diodes+1)*nn_steps+1 ))     ;1-D
      ;-------------- derive  time/variable ----------------
      for i=0L,nn_pktnum-1 do begin
        data.x[i]   = time_sc[i]                  ; Each time step represent a new packet
        data.y[i,*] = [[output.DIODE_A[i,*]], $     ; all data from the same packet in a long array
          [output.DIODE_B[i,*]], $
          [output.DIODE_C[i,*]], $
          [output.DIODE_D[i,*]], $
          [output.THERM[i,*]], $
          [2.^(output.smp_avg[output.euv_i[i]]+6)]]
      endfor
      str1=['diod_a'+strarr(nn_steps),'diod_b'+strarr(nn_steps),'diod_c'+strarr(nn_steps),'diod_d'+strarr(nn_steps),'THERMAL'+strarr(nn_steps),'Number of averaged samples']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      ;These are the fields the CDF write consider
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW EUV raw L0b', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     cdf_istp[3],  $
        'Data_version',                  cdf_istp[4], $  ;Keep this text string, need to add v## when we make the CDF file (done later)
        'Descriptor',                    cdf_istp[5], $
        'PI_name',                       cdf_istp[6], $
        'PI_affiliation',                cdf_istp[7], $
        'TEXT',                          cdf_istp[8], $
        'Mission_group',                 cdf_istp[9], $
        'Generated_by',                  cdf_istp[10],  $
        'Generation_date',                today_date+' # '+t_routine, $
        'Rules_of_use',                  cdf_istp[11], $
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
        't_epoch',                     t_epoch, $
        'Time_start',                  [time_sc(0)-t_epoch,          time_sc(0)] , $
        'Time_end',                    [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)], $
        'Time_field',                  ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
        'SPICE_kernel_version',        'NaN', $
        'SPICE_kernel_flag',           'SPICE not used', $
        'L0_datafile',                 filename_L0 , $
        'cal_vers',                    cal_ver+' # '+pkt_ver ,$
        'cal_y_const1' ,               'NA', $
        'cal_y_const2',                'NA', $
        'cal_datafile',                'NA', $
        'cal_source',                  'Information from PKT: EUV-raw', $
        'flag_info',                   'NA', $
        'flag_source',                 'NA', $
        'xsubtitle',                   '[sec]', $
        'ysubtitle',                   '[Raw Packet Information]', $
        'cal_v_const1',                'NA', $
        'cal_v_const2',                'NA', $
        'zsubtitle',                   'NA')
      ;-------------  limit ----------------
      ;limit options for CDF production: CHAR_SIZE, XTITLE, YTITLE, YRANGE, YSTYLE, YLOG, ZTITLE, ZRANGE, ZLOG, SPEC, COLORS, LABELS, LABFLAG, NOERRORBARS
      limit=create_struct(   $
        'xtitle' ,                      'Time (s/c)'             ,$
        'ytitle' ,                      'Misc'                 ,$
        'labels' ,                      str1                    ,$
        'yrange' ,                      [min(data.y),max(data.y)] )
      ;------------- store --------------------
      store_data,'mvn_lpw_euv_l0b',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------

    ENDIF

  ENDIF ELSE  print, "mvn_lpw_euv.pro skipped as no packets found."

end
;*******************************************************************







