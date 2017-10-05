;;+
;PROCEDURE:   mvn_lpw_pkt_hsk
;PURPOSE:
;  THis is theinformation from the LPW HSK packet that is converted into tplot variables
;  both raw and calibrated information is created
;  HSK have for instance temperature and the volta
;
;USAGE:
;  mvn_lpw_pkt_hsk,output,lpw_const,cdf_istp_lpw,tplot_var
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
;FILE: mvn_lpw_pkt_atr.pro
;VERSION:   2.0   <------------------------------- update 'pkt_ver' variable
;LAST MODIFICATION:
;07/11/13 - Chris Fowler - added IF statement checking for data in output.p6, and keyword tplot_var.
;05/16/13
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels, since this is a read back of tables no dv or dy information exist
; 04/15/14 L. Andersson included L1
;04/18/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. Andersson
;2014-10-03: CF: edited dlimit fields for ISTP compliance.
;-

pro mvn_lpw_pkt_hsk, output,lpw_const,tplot_var=tplot_var,spice=spice

  IF output.p9 GT 0 THEN BEGIN  ;check we have data

    ;-------------------Check different inputs------------------------------------
    If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.
    ;--------------------------------------------------------------------

    ;--------------------- Constants ------------------------------------
    t_routine        = SYSTIME(0)
    t_epoch          = lpw_const.t_epoch
    today_date       = lpw_const.today_date
    cal_ver          = lpw_const.version_calib_routine
    pkt_ver          = 'Pkt_hsk_ver V2.0 '
    cdf_istp         = lpw_const.cdf_istp_lpw
    filename_L0      = output.filename
    const_hsk_temp   = lpw_const.hsk_temp
    const_hsk_voltage= lpw_const.hsk_voltage
    ;------------------------------------------------------------
    nn_pktnum              = output.p9                              ; number of data packages
    ;--------------------------------------------------------------------

    ;------------- Checks ---------------------
    if output.p9 NE n_elements(output.hsk_i) then stanna
    if n_elements(output.hsk_i) EQ 0 then print,'(mvn_lpw_hsk) No packages where found <---------------'
    ;-----------------------------------------

    ;-------------------- Get correct clock time ------------------------------
    time_sc = double(output.SC_CLK1[output.hsk_i]+output.SC_CLK2[output.hsk_i]/2l^16)+t_epoch  ;data points in s/c time
    IF keyword_set(spice)  THEN BEGIN                                                                                                ;if this computer has SPICE installed:
      aa = output.SC_CLK1[output.hsk_i]
      bb = output.SC_CLK2[output.hsk_i]
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


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  hsk ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,17)  )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      for i=0,nn_pktnum-1 do begin            ; the corrected numbers in seperate variables
        data.y[i,0] = output.Preamp_Temp1[i]   ; * const_hsk_temp(0,0) + const_hsk_temp(1,0)     ;
        data.y[i,1] = output.Preamp_Temp2[i]   ; * const_hsk_temp(0,1) + const_hsk_temp(1,1)  ;
        data.y[i,2]=output.Beb_Temp[i]         ; * const_hsk_temp(0,2) + const_hsk_temp(1,2) ;
        data.y[i,3]=output.plus12va[i]         ; * const_hsk_voltage(0)  ;0.0004581
        data.y[i,4]=output.minus12va[i]        ; * const_hsk_voltage(1)  ;0.0004699
        data.y[i,5]=output.plus5va[i]          ; * const_hsk_voltage(2)  ; 0.0001913
        data.y[i,6]=output.minus5va[i]         ; * const_hsk_voltage(3)  ; 0.0001923
        data.y[i,7]=output.plus90va[i]         ; * const_hsk_voltage(4)  ; 0.0077058
        data.y[i,8]=output.minus90va[i]        ; * const_hsk_voltage(5)  ; 0.0077058
        data.y[i,9]=output.CMD_ACCEPT[i]
        data.y[i,10]=output.CMD_REJECT[i]
        data.y[i,11]=output.MEM_SEU_COUNTER[i]
        data.y[i,12]=output.INT_STAT[i]
        data.y[i,13]=output.CHKSUM[i]
        data.y[i,14]=output.EXT_STAT[i]
        data.y[i,15]=output.DPLY1_CNT[i]
        data.y[i,16]=output.DPLY2_CNT[i]
      endfor
      str1=['Preamp_Temp1','Preamp_Temp2','Beb_Temp','plus12va','minus12va','plus5va','minus5va','plus90va','minus90va','CMD_ACCEPT','CMD_REJECT', $
        'MEM_SEU_COUNTER','INT_STAT','CHKSUM','EXT_STAT','DPLY1_CNT','DPLY2_CNT']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK data', $
        'Project',                       cdf_istp[12], $
        'Source_name',                   cdf_istp[0], $     ;Required for cdf production...
        'Discipline',                    cdf_istp[1], $
        'Instrument_type',               cdf_istp[2], $
        'Data_type',                     'Support_data' ,  $
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
        'MONOTON', 'INCREASE', $
        'SCALEMIN', 'NA', $
        'SCALEMAX', 'NA', $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: Raw DN'  ,$
        ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ; 'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSK', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSK'                 ,$
        'labels' ,        str1                    ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])
      ;------------- store --------------------
      store_data,'mvn_lpw_hsk',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  hsk_temp ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,3) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y[*,0] = output.Preamp_Temp1[*]    * const_hsk_temp(0,0) + const_hsk_temp(1,0)     ;
      data.y[*,1] = output.Preamp_Temp2[*]    * const_hsk_temp(0,1) + const_hsk_temp(1,1)  ;
      data.y[*,2] = output.Beb_Temp[*]        * const_hsk_temp(0,2) + const_hsk_temp(1,2) ;

      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK temp', $
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
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(data.y), $
        'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: preamp1 ' + strcompress(const_hsk_temp(0,0),/remove_all) +' + '+ strcompress(const_hsk_temp(1,0),/remove_all) + $ ;
        ' preamp2 ' + strcompress(const_hsk_temp(0,1),/remove_all) +' + '+ strcompress(const_hsk_temp(1,2),/remove_all) + $ ;
        ' BEB ' + strcompress(const_hsk_temp(0,2),/remove_all) +' + '+ strcompress(const_hsk_temp(1,2),/remove_all) , $; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSK', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[C]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSK Temp'                 ,$
        'yrange' ,        [-80,80] ,$ ;  [min(data.y),max(data.y)] ,$
        'ystyle'  ,       1.                       ,$
        'labels' ,        str1[0:2]                ,$
        'colors' ,        [2,4,6]                  ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsk_temp',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------



      ;------------- variable:  hsk_12v ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,2)  )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y[*,0]=abs(output.plus12va[*]          * const_hsk_voltage(0))
      data.y[*,1]=abs(output.minus12va[*]         * const_hsk_voltage(1))
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK 12v', $
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
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(data.y), $
        'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: plus12v ' + strcompress(const_hsk_voltage(0),/remove_all) +' +  minus12v '+ strcompress(const_hsk_voltage(1),/remove_all)  , $;
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSK', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Volt]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSK - abs(12V)'         ,$
        'yrange' ,        [12.,12.5] ,$
        'ystyle'  ,       1.                       ,$
        'labels' ,        str1[3:4]                 ,$
        'colors' ,        [4,6]                      ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsk_12v',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  hsk_5v ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,2)  )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y[*,0]=abs(output.plus5va[*]           * const_hsk_voltage(2))
      data.y[*,1]=abs(output.minus5va[*]          * const_hsk_voltage(3))
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK 5v', $
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
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(data.y), $
        'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: plus5v ' + strcompress(const_hsk_voltage(2),/remove_all) +' + minus5v '+ strcompress(const_hsk_voltage(3),/remove_all)  , $;
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSK', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Volt]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSK - abs(5V)'         ,$
        'yrange' ,        [5.1,5.2] ,$
        'ystyle'  ,       1.                       ,$
        'labels' ,        str1[5:6]                 ,$
        'colors' ,        [4,6]                      ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsk_5v',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  hsk_90v ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum,2)  )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y[*,0]=abs(output.plus90va[*]          * const_hsk_voltage(4))
      data.y[*,1]=abs(output.minus90va[*]         * const_hsk_voltage(5))
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK 90v', $
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
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(data.y), $
        'SCALEMAX', max(data.y), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver,$
        'cal_y_const1'    ,     'Used: plus90v ' + strcompress(const_hsk_voltage(4),/remove_all) +' +  minus90v '+ strcompress(const_hsk_voltage(5),/remove_all)  , $;
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSK', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Volt]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSK - abs(90V)'         ,$
        'yrange' ,        [90,120] ,$
        'ystyle'  ,       1.                       ,$
        'labels' ,        str1[7:8]                 ,$
        'colors' ,        [4,6]                      ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsk_90v',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  smp_avg ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum))     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x=time
      data.y=2^(output.smp_avg[output.hsk_i]+1)       ; from ICD section 7.6
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK sample average', $
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
        'Rules_of_use',                  cdf_istp[11], $
        'Acknowledgement',               cdf_istp[13],   $
        'MONOTON', 'INCREASE', $
        'SCALEMIN', 'NA', $
        'SCALEMAX', 'NA', $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: NaN'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSK', $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[No]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSK smp_avg'                 ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsk_smp_avg',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  HSK L1-raw  ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $           ; double 1-D arr
        'y',    fltarr(nn_pktnum, 18))           ;1-D
      ;-------------- derive  time/variable ----------------
      for i=0L,nn_pktnum-1 do begin
        data.x[i]    = time_sc[i]                                    ;sc time only
        data.y[i,0]  = output.Preamp_Temp1[i]
        data.y[i,1]  = output.Preamp_Temp2[i]
        data.y[i,2]  = output.Beb_Temp[i]
        data.y[i,3]  = output.plus12va[i]
        data.y[i,4]  = output.minus12va[i]
        data.y[i,5]  = output.plus5va[i]
        data.y[i,6]  = output.minus5va[i]
        data.y[i,7]  = output.plus90va[i]
        data.y[i,8]  = output.minus90va[i]
        data.y[i,9]  = output.CMD_ACCEPT[i]
        data.y[i,10] = output.CMD_REJECT[i]
        data.y[i,11] = output.MEM_SEU_COUNTER[i]
        data.y[i,12] = output.INT_STAT[i]
        data.y[i,13] = output.CHKSUM[i]
        data.y[i,14] = output.EXT_STAT[i]
        data.y[i,15] = output.DPLY1_CNT[i]
        data.y[i,16] = output.DPLY2_CNT[i]
        data.y[i,17] = 2^(output.smp_avg[output.hsk_i[i]]+1)       ; from ICD section 7.6
      endfor
      str1=['Preamp_Temp1','Preamp_Temp2','Beb_Temp', $
        'plus12va','minus12va','plus5va','minus5va','plus90va','minus90va', $
        'CMD_ACCEPT','CMD_REJECT','MEM_SEU_COUNTER','INT_STAT','CHKSUM','EXT_STAT','DPLY1_CNT','DPLY2_CNT', $
        'Number of averaged samples']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW HSK temp', $
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
        't_epoch'         ,            t_epoch, $
        'Time_start'      ,            [time_sc(0)-t_epoch,          time_sc(0)] , $
        'Time_end'        ,            [time_sc(nn_pktnum-1)-t_epoch,time_sc(nn_pktnum-1)], $
        'Time_field'      ,            ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
        'SPICE_kernel_version',        'NaN', $
        'SPICE_kernel_flag'      ,     'SPICE not used', $
        'L0_datafile'     ,            filename_L0 , $
        'cal_source'      ,            'Information from PKT: HSK-raw', $
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
      store_data,'mvn_lpw_hsk_l0b',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


    ENDIF
  ENDIF ELSE print, "mvn_lpw_hsk.pro skipped as no data packet found."

end
;*******************************************************************







