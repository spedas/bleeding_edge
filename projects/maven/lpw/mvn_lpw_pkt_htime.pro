;;+
;PROCEDURE:   mvn_lpw_pkt_htime
;PURPOSE:
;  Takes the decumuted data (L0) from the HTIME packet
;  and turn it the data into tplot structures
;  This packet contains the information of when HSBM packets are created
;  The capture time and when they where sent to the archive
;  Noraml operation: HTIME paket is transimtted in the survey pipeline while HSBM is via archive
;
;  This ia not archivable or important for data analysis to the dlimit information has not been filled in and spice is not used
;
;USAGE:
;  mvn_lpw_pkt_pas,output,lpw_const,cdf_istp_lpw,tplot_var
;
;INPUTS:
;       output:         L0 data
;       lpw_const:      information of lpw calibration etc
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'     => 'sci' produces tplot variables with physical units associated with them and is the default
;                                      => 'all' produces all tplot variables
;
;
;CREATED BY:   Laila Andersson 13 august 2012
;FILE: mvn_lpw_pkt_pas.pro
;VERSION:   2.0
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   05/16/13
;                     2013, July 11th, Chris Fowler - added IF statement to check for data
;                     2013, July 12th, Chris Fowler - add keyword tplot_var
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels, no dy or dv is needed in this routine
;;140718 clean up for check out L. Andersson
;-

pro mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var

  If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.

  IF output.p23 GT 0 THEN BEGIN  ;check for data

    ;--------------------- Constants ------------------------------------
    t_routine=SYSTIME(0)
    t_epoch=lpw_const.t_epoch
    today_date=lpw_const.today_date
    cal_ver=lpw_const.version_calib_routine
    pkt_ver          = 'Pkt_hsk_ver 2.0 '
    cdf_istp=lpw_const.cdf_istp_lpw
    filename_L0=output.filename
    nn_pktnum=n_elements(output.HTIME_i)
    ;--------------------------------------------------------------------

    ;--------------------------------------------------------------------
    ; time stamp of the packet it self
    time=double(output.SC_CLK1[output.HTIME_i]) + output.SC_CLK2[output.HTIME_i]/2l^16+t_epoch  ;number of packets

    length=(((long(output.length[output.HTIME_i])-1)/2)-7)/2+1
    lenght_cum0=total(length,/CUMULATIVE)
    time_long=dblarr(n_elements(output.htime_type))  ;make time so it matches htime_type

    for i=0,nn_pktnum-1 do $
      if length[i] GT 0 then $
      time_long[lenght_cum0[i]-length[i]:lenght_cum0[i]-1]=time[i]
    type_3=['lf','mf','hf','unused']  ; 00, 01, 10, 11 see ICD section 9.11
    ; since this ia not archivable or important for data analysis the time is not corrected using spice
    clock_start_t    = [time(0)-t_epoch,          time(0)]                         ;corresponding start times to above string array, s/c time
    clock_end_t      = [time(nn_pktnum-1)-t_epoch,time(nn_pktnum-1)] ;corresponding end times, s/c time
    spice_used       = 'SPICE not used'
    str_xtitle       = 'Time (s/c)'
    kernel_version    = 'N/A'
    ;--------------------------------------------------------------------

    IF tplot_var EQ 'ALL' THEN BEGIN
      ;--------------------------------------------------------------------
      for iu=0,2  do begin ; loop over the HSBM types lf mf hf
        type=type_3[iu]
        qq=where(output.htime_type EQ iu,nq)

        ;-------------  compare time with time as function of time  capture time and trensfere time---------------------------
        data =  create_struct(   $
          'x',    dblarr(nq) ,  $     ; double 1-D arr
          'y',    fltarr(nq) )    ;1-D
        ;-------------- derive  time/variable ----------------
        data.x=double(time_long[qq] + output.cap_time[qq])
        data.y=output.htime_type[qq]+0.8     ; for the plotting routine the yvalue in cap and xfer needs to be different
        ;-------------------------------------------
        ;--------------- dlimit   ------------------
        dlimit=create_struct(   $
          'Product_name',                  'htime xfer', $
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
          'SCALEMIN', 0, $
          'SCALEMAX', 3, $        ;..end of required for cdf production.
          'Time_clock'      ,     'Clock', $
          't_epoch'         ,     t_epoch, $
          'L0_datafile'     ,     filename_L0 , $
          'cal_vers'        ,     cal_ver ,$
          'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
          ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
          ; 'cal_datafile'    ,     'No calibration file used' , $
          'cal_source'      ,     'Information from PKT: HTIME', $
          'xsubtitle'       ,     '[sec]')
        ;-------------  limit ----------------
        limit=create_struct(   $
          'char_size' ,     1.2                      ,$
          'xtitle' ,        'Time (not sorted)'      ,$
          'ytitle' ,        'Capture time '+type     ,$
          'yrange' ,        [0,3] ,$
          'ystyle'  ,       1.                       ,$
          'ylog'   ,        1.                       ,$
          'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
          'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
          'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
        ;------------- store --------------------
        store_data,'mvn_lpw_htime_cap_'+type,data=data,limit=limit,dlimit=dlimit
        ;--------------------------------------------------
        data.x=double(time_long[qq] + output.xfer_time[qq])
        data.y=output.htime_type[qq] +0.1     ; for the plotting routine the yvalue in cap and xfer needs to be different
        limit.ytitle='Xfer '+type
        store_data,'mvn_lpw_htime_xfer_'+type,data=data,limit=limit,dlimit=dlimit
        ;--------------------------------------------------

      endfor  ;end loop over the HSBM types lf mf hf
    ENDIF



    IF 'yes' EQ 'no' and tplot_var EQ 'ALL' THEN BEGIN ; this is not archived since this is not imporatant information
      ;------------- variable:  HTIME report rate ---------------------------

      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum))     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time
      data.y = 2^output.smp_avg[output.HTIME_i]        ; smp_avg is used for htime to get the HTIME_rate, Equation see table 7.8 ICD
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'htime rate', $
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
        'SCALEMIN', -1, $
        'SCALEMAX', max(data.y)*1.2, $        ;..end of required for cdf production.
        'Time_clock'      ,     'Clock', $
        't_epoch'         ,     t_epoch, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver ,$
        'cal_y_const1'    ,     'PKT level:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HTIME', $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        'Time'                   ,$
        'ytitle' ,        'HTIME rate (sec)'       ,$
        'yrange' ,        [-1,max(data.y)*1.2]     ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_htime_rate',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      help,time_long

      print,'##'
      print,time_long
      print,'##'
      print,lenght_cum0
      print,'##'
      print,output.htime_type


      ;------------- variable:  htime L1-raw nn_size=??? ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $                       ; double 1-D arr
        'y',    fltarr(nn_pktnum,max(length)*3+1))                ;1-D
      ;-------------- derive  time/variable ----------------
      for i=0L,nn_pktnum-1 do begin

        help,output.cap_time,output.xfer_time,output.htime_type
        help,output.cap_time[i,*],output.xfer_time[i,*],output.htime_type[i,*]

        help,data.y[i,max(length)*0:max(length)*0+length(i)-1]
        help,time_long,lenght_cum0
        print,'### ', i ,length(i),lengh_cum0(i)

        stanna
        data.x[i]                       = time_sc[i]                              ;sc time only
        data.y[i,max(length)*0:max(length)*0+length(i)-1] = output.cap_time[i,*]
        data.y[i,max(length)*1:max(length)*1+length(i)-1] = output.xfer_time[i,*]
        data.y[i,max(length)*2:max(length)*2+length(i)-1] = output.htime_type[i,*]
        data.y[i,max(length)*3]             = 2^output.smp_avg[output.HTIME_i[i]]   ; smp_avg is used for htime to get the HTIME_rate, Equation see table 7.8 ICD
      endfor
      str1=['Capture Time'+strarr(max(length)),'Transfter Time'+strarr(max(length)), $
        'Burst Time'+strarr(max(length)),'Number of averaged samples']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'MAVEN LPW RAW htime, L0b', $
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
        'Time_start'      ,            time_string(data.x[0]), $
        'Time_end'        ,            time_string(data.x[nn_pktnum-1]), $
        'Time_field'      ,            'SC packet time given, t_epoch is the 0-time of sc clock', $
        'SPICE_kernel_version',        'NaN', $
        'SPICE_kernel_flag'      ,     'SPICE not used', $
        'L0_datafile'     ,            filename_L0 , $
        'cal_source'      ,            'Information from PKT: htime-raw', $
        'xsubtitle'       ,            '[sec]', $
        'ysubtitle'       ,            '[Raw Packet Information]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'xtitle' ,                      'Time (s/c)'             ,$
        'ytitle' ,                      'Misc'                 ,$
        'labels' ,                      str1                    ,$
        'yrange' ,                      [min(data.y),max(data.y)] )
      ;------------- store --------------------
      store_data,'mvn_lpw_htime_l0b',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------

    ENDIF
  ENDIF

  IF output.p23 LE 0 THEN print, "mvn_lpw_htime.pro skipped as no packets found."

end
;*******************************************************************
;


