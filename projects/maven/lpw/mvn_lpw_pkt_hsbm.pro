;;+
;PROCEDURE:   mvn_lpw_pkt_hsbm
;PURPOSE:
;  Takes the decumuted data (L0) from the HSBM and HTIME packets
;  and turn it the data into L1 and L2 tplot structures
;  E12_HF gain boost is manually set
;
;USAGE:
;  mvn_lpw_pkt_hsbm,output,lpw_const,cdf_istp_lpw,type,tplot_var
;
;INPUTS:
;       output:         L0 data
;       lpw_const:      information of lpw calibration etc
;       type:           LF, MF or HF data
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'    => 'sci' produces tplot variables with physical units associated with them and is the default
;                                     => 'all' produces all tplot variables
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.
;
;CREATED BY:   Laila Andersson 17 august 2011
;FILE: mvn_lpw_pkt_hsbm.pro
;VERSION:   2.0
;LAST MODIFICATION:   2013, July 11th, Chris Fowler - added IF statement to check for data.
;                     2013, July 12th, Chris Fowler - added keyword tplot_var
;
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...;
;04/15/14 L. Andersson included L1
;04/18/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. andersson
;-

pro mvn_lpw_pkt_hsbm, output,lpw_const,type,tplot_var=tplot_var,spice=spice

  IF (output.p20 GT 0 AND type EQ 'lf') OR $  ;check for data, for keyword 'lf'
    (output.p21 GT 0 AND type EQ 'mf') OR $  ;check for data, for keyword 'mf'
    (output.p22 GT 0 AND type EQ 'hf') $     ;check for data, for keyword 'hf'
    THEN BEGIN

    If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.


    ;--------------------- Constants ------------------------------------
    t_routine            = SYSTIME(0)
    cdf_istp             = lpw_const.cdf_istp_lpw
    t_epoch              = lpw_const.t_epoch
    today_date           = lpw_const.today_date
    cal_ver              = lpw_const.version_calib_routine
    pkt_ver              = 'pkt_hsbm_ver 2.0'
    cdf_istp             = lpw_const.cdf_istp_lpw
    filename_L0          = output.filename
    ;----------------------------------------------------------------
    inst_phys            = lpw_const.inst_phys
    sensor_distance      = lpw_const.sensor_distance
    boom_shorting_factor = lpw_const.boom_shortening
    nn_fft_size          = lpw_const.nn_fft_size
    ;--------------------------------------------------------------------
    IF type EQ 'lf' and output.p20 GT 0 then begin
      nn_pktnum=long(output.p20)          ; number of data packages
      data_hsbm=output.hsbm_lf
      nn_index=output.hsbm_lf_i
      dt=  lpw_const.dt_hsbm_lf
      nn_size=lpw_const.nn_hsbm_lf
      f_bin=lpw_const.f_bin_lf
      nn_bin=lpw_const.nn_bin_lf
      const_E12=lpw_const.E12_lf
      center_freq=lpw_const.center_freq_lf
      e12_corr=lpw_const.e12_lf_corr
    endif
    IF type EQ 'mf' and output.p21 GT 0 then begin
      nn_pktnum=long(output.p21)          ; number of data packages
      data_hsbm=output.hsbm_mf
      nn_index=output.hsbm_mf_i
      dt= lpw_const.dt_hsbm_mf
      nn_size=lpw_const.nn_hsbm_mf
      f_bin=lpw_const.f_bin_mf
      nn_bin=lpw_const.nn_bin_mf
      const_E12=lpw_const.E12_mf
      center_freq=lpw_const.center_freq_mf
      e12_corr=lpw_const.e12_mf_corr
    endif
    IF type EQ 'hf' and output.p22 GT 0 then begin
      ;the way we do the clock (fix sc_dt and then spice) gives us a unsertainty of 0.4% in frequency TBR
      nn_pktnum=long(output.p22)          ; number of data packages
      data_hsbm=output.hsbm_hf
      nn_index=output.hsbm_hf_i
      dt=  lpw_const.dt_hsbm_hf
      nn_size=lpw_const.nn_hsbm_hf
      f_bin=lpw_const.f_bin_hf
      nn_bin=lpw_const.nn_bin_hf
      const_E12=lpw_const.E12_hf
      e12_corr=lpw_const.e12_hf_corr

      print,'### HF HSBM  E12_HF gain boost ####',output.E12_HF_GB[nn_index]

      ;WARING the above means we do not expect this to change for flight we need to change this
      center_freq=lpw_const.center_freq_hf
    endif
    ;--------------------------------------------------------------------



    ;-------------------- Get correct clock time ------------------------------
    time_sc=double(output.SC_CLK1[nn_index]) + output.SC_CLK2[nn_index]/2l^16+t_epoch     ;initial packet time

    ; ## per Jan 4 2012 From D. Meyer ##
    ;   Just a reminder… Since the HSBM timestamp indicates the end of the buffer,
    ; the following timestamp correction should be applied to the whole 48 bit timestamp
    ; before converting to human readable format.
    ;HSBM_HF: PKT_TS – 0x0000_0000_0040    (-1 msec)
    ;HSBM_MF: PKT_TS – 0x0000_0000_1000    (-62.5 msec)
    ;HSBM_LF: PKT_TS – 0x0000_0001_0000      (-1 second)
    if type EQ 'hf' THEN time_sc=time_sc-0.001                                                ;time here is corrected for start of the data array
    if type EQ 'mf' THEN time_sc=time_sc-0.0625
    if type EQ 'lf' THEN time_sc=time_sc-1.0
    time            = time_sc
    time_dt         = dblarr(nn_pktnum*nn_size)                                            ;the time of each individual point

    for i=0L,nn_pktnum-1 do time_dt[nn_size*i:nn_size*(i+1)-1]  =time[i] + dindgen(nn_size)*dt
    ;it used to be this, have I messed up                    = time[i] -(nn_size-1-dindgen(nn_size))*dt
    IF keyword_set(spice)  THEN BEGIN                                                                                                ;if this computer has SPICE installed:
      aa=floor(time-t_epoch)
      bb=floor(((time-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:

      help, time
      print,time[0]

      if min(time) LT 0  then stanna  ; this means a incorrect identified packet

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
      clock_start_t_dt = [time_dt(0)-t_epoch,          time_dt(0)]                                           ; no change for EUV start
      clock_end_t_dt   = [time_dt(nn_pktnum-1)-t_epoch,time_dt(nn_pktnum-1)]
    ENDELSE
    ;--------------------------------------------------------------------


    ;-------------  E as function of time E12_HSBM ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum*nn_size) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum*nn_size) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum*nn_size) )     ;1-D
    ;-------------- derive  time/variable ----------------
    time_sort=sort(time)
    FOR i=0,nn_pktnum-1 do BEGIN
      data.x[1L*nn_size*i:1L*nn_size*(i+1)-1]  = time[time_sort[i]]+dindgen(nn_size)*dt    ;<----- need to do this here!!!
      ;data.y[1L*nn_size*i:1L*nn_size*(i+1)-1]  = data_hsbm(*,time_sort[i])*const_E12
      data.y[1L*nn_size*i:1L*nn_size*(i+1)-1]  =(( data_hsbm(*,time_sort[i])*const_E12 )-e12_corr(0))/e12_corr(1)
      data.dy[1L*nn_size*i:1l*nn_size*(i+1)-1] = ((                    1   *const_E12 )            )/e12_corr(1)   ;  20 DN  uncertanty
    ENDFOR
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'HSBM: '+type, $
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
      'Time_start'      ,     clock_start_t_dt, $
      'Time_end'        ,     clock_end_t_dt, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: '+strcompress(const_E12,/remove_all)+' # '+strcompress(e12_corr(0),/remove_all)+' # '+strcompress(e12_corr(1)  ,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: HSBM'+type, $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Volt]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     lpw_const.tplot_char_size ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'HSBM_'+type              ,$
      'yrange' ,        [min(data.y),max(data.y)] ,$
      'ystyle'  ,       1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------
    ;-------------- derive  time/variable ----------------
    time_sort=sort(time)
    xx=lindgen(nn_size)

    ; now remove any slope, if two burst are next to each other work with multiple bursts....
    dt=data.x[1]-data.x[0]   ; time step
    aa=data.x[1:*]-data.x[0:*]
    tmpa=where(aa GT dt*1.5,nqa)          ;this is the last point in each time sequence
    tmpa=[0,tmpa,n_elements(data.x)-1]   ; add first point

    if type NE 'lf' then $
      FOR i=0,nqa do BEGIN
      xx=lindgen(tmpa[i+1]-tmpa[i]+1) ; make a index array of the time serie
      tmp                       =  data.y[tmpa[i]:tmpa[i+1]]
      tmp2                      = LADFIT(xx,tmp)  ;,nan )
      tmp3                      = (tmp -(tmp2[1]*xx+tmp2[0]) )
      data.y[tmpa[i]:tmpa[i+1]] =  tmp3
      if type EQ 'hf' then   data.y[1L*nn_size*(i+1)-1]  =  !values.f_nan     ; blank out the last point
    endfor
    xx=lindgen(nn_size)
    if type EQ 'lf' then  $
      FOR i=0,nn_pktnum-1 do begin
      tmp = (( data_hsbm(*,time_sort[i])*const_E12 )-e12_corr(0))/e12_corr(1)
      tmp2= LADFIT(xx[32:nn_size-1],tmp[32:nn_size-1])  ;,nan )
      tmp3 = (tmp -(tmp2[1]*xx+tmp2[0]) )
      data.y[1L*nn_size*i:1L*nn_size*(i+1)-1]  =  tmp3
      data.y[1L*nn_size*i:1L*nn_size*(i)+95]  =  !values.f_nan     ; blank out the 6 first E12-DC points == 96 e12 lf points
    ENDFOR
    data.dy = 0.15*abs(data.y)>  data.dy


    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm2_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------



    ;-------------  E matrix each burst versus time ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_size) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,nn_size) ,  $
      'v',    fltarr(nn_pktnum,nn_size))     ;frequency - no significant error in this value
    ;-------------- derive  time/variable ----------------
    time_sort=sort(time)
    FOR i=0,nn_pktnum-1 do BEGIN
      data.x[i]=time[time_sort[i]]
      ; data.y[i,*]=data_hsbm[*,time_sort[i]]*const_E12
      data.y[i,*]=((data_hsbm[*,time_sort[i]]*const_E12) -e12_corr(0))/e12_corr(1)
      data.v[i,*]=dindgen(nn_size)*dt
      data.dy[i,*]=SQRT(ABS(data_hsbm[*,time_sort[i]]))*const_E12
    ENDFOR
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'HSBM matrix, '+type, $
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
      'SCALEMIN', min(data.v), $
      'SCALEMAX', max(data.v), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t_dt, $
      'Time_end'        ,     clock_end_t_dt, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used:'+strcompress(const_E12 ,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: HSBM'+type, $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Volt]', $
      'cal_v_const1'    ,     'PKT level: ' +strcompress(dt,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      'zsubtitle'       ,     '[Time]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     lpw_const.tplot_char_size ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'HSBM_'+type             ,$
      'yrange' ,        [min(data.v),max(data.v)] ,$
      'ystyle'  ,       1.                       ,$
      'ztitle' ,        'E-field E12'            ,$
      'zrange' ,        [min(data.y,/nan),max(data.y,/nan)],$
      'zlog'   ,        1.                       ,$
      'spec'   ,        1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $             ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_matrix_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;-------------  which order the packets arrive in  ---------------------------
      datatype=create_struct('type', '{ raw}')
      data=create_struct(   $
        'x'     ,  dblarr(nn_pktnum)  ,$
        'y'     ,  fltarr(nn_pktnum,3))  ;one for the order the other for the peak ampitude
      ;-------------- derive the time ----------------
      time_sort=sort(time)
      FOR i=0,nn_pktnum-1 do BEGIN
        data.x[i]=time[time_sort[i]]
        data.y[i,0]=time_sort[i]                              ;how to sort the data
        data.y[i,1]=i                                         ;which order the data was sent
        data.y[i,2]=max(abs(data_hsbm[*,time_sort[i]]*const_E12))  ;max amplitude within a package
      ENDFOR
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'HSBM order, '+type, $
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
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used:'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;   'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;  'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSBM'+type, $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[Volt]', $
        ;   'cal_v_const1'    ,     'PKT level::' ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;   'cal_v_const2'    ,     'Used :'  ,$ ; Fixed convert information from measured binary values to physical units, variables from space testing
        'zsubtitle'       ,     '[A]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     lpw_const.tplot_char_size ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'mvn_lpw_hsbm_'+type                ,$
        'yrange' ,        [min(data.y),max(data.y)] ,$
        'ystyle'  ,       1.                       ,$
        'ylog'   ,        1.                       ,$
        ;'ztitle' ,        'Z-title'                ,$
        ;'zrange' ,        [min(data.y),max(data.y)],$
        ;'zlog'   ,        1.                       ,$
        ;'spec'   ,        1.                       ,$
        'labels' ,        ['order sent','clock order','max peak']                    ,$
        'labflag' ,       1                        ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsbm_order_'+type,data=data,limit=limit,dlimit=dlimit
      ;--------------------------------------------------
    ENDIF

    ;-------------  HSBM FFT FULL---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_size/2+1) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,nn_size/2+1) ,  $     ; same size as y
      'v',    fltarr(nn_pktnum,nn_size/2+1) ,  $     ; same size as y
      'dv',   fltarr(nn_pktnum,nn_size/2+1) )        ;same size as y
    ;-------------- derive  time/variable ----------------
    time_sort=sort(time)
    FOR i=0,nn_pktnum-1 do BEGIN
      data.x[i]=time[time_sort[i]]
      comp1=data_hsbm[*,time_sort[i]]
      uu=0
      nn_zero=0
      comp1=comp1[nn_zero:nn_size-1]
      length=nn_size-nn_zero
      ; Find the power spectrum with and without the Hanning filter.
      han = HANNING(length, /DOUBLE)
      powerHan = ABS(FFT(han*comp1))^2
      freq = FINDGEN(length)/(length*dt)
      data.y[i,0:length/2]=powerHan[0:length/2]  ; note I magnify this value so it comes closer to the other spectras and one should do it the other way
      data.v[i,0:length/2]= freq[0:length/2]
      data.dy[i,0:length/2]=SQRT(ABS(data.y[i,0:length/2]))
      data.dv[i,0:length/2]=SQRT(ABS(data.v[i,0:length/2]))
    ENDFOR
    data.v[*,0]= 0.3*data.v[*,1]  ; so that it is not 0 Hz
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'HSBM spec full, '+type, $
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
      'MONOTON', 'INCREASE', $
      'SCALEMIN', 0.8*min(data.v(*,0)), $
      'SCALEMAX', 1.1*max(data.v(*,nn_size/2)), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t_dt, $
      'Time_end'        ,     clock_end_t_dt, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: HSBM'+type, $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[alog10(Hz)]', $
      'cal_v_const1'    ,     'PKT level: ' ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      'zsubtitle'       ,     '[RAW]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     lpw_const.tplot_char_size ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'hsbm_full_burst_'+type,$
      'yrange' ,        [0.8*min(data.v[*,0]),1.1*max(data.v[*,nn_size/2])],$
      'ystyle'  ,       1.                       ,$
      'ylog'   ,        1.                       ,$
      'ztitle' ,        'Wave power'             ,$
      'zrange' ,        [1.*lpw_const.power_scale_hf,1.e7],$
      'zlog'   ,        1.                       ,$
      'spec'   ,        1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_spec_full_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------


    ;-------------  HSBM FFT ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_fft_size/2+1) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,nn_fft_size/2+1) ,  $    ; same size as y
      'v',    fltarr(nn_pktnum,nn_fft_size/2+1) ,  $     ; same size as y
      'dv',   fltarr(nn_pktnum,nn_fft_size/2+1) )       ; same size as y
    ;-------------- derive  time/variable ----------------
    time_sort=sort(time)
    FOR i=0,nn_pktnum-1 do BEGIN
      data.x[i]=time[time_sort[i]]
      comp1=data_hsbm[0:nn_fft_size-1,time_sort[i]] ;*const_E12
      han = HANNING(nn_fft_size, /DOUBLE)
      powerHan = ABS(FFT(han*comp1))^2
      freq = FINDGEN(nn_fft_size)/(nn_fft_size*dt)
      data.y[i,*]=powerHan[0:nn_fft_size/2]   ; note I magnify this value so it comes closer to the other spectras and one should do it the other way
      data.v[i,*]= freq[0:nn_fft_size/2]
      data.dy[i,*]=SQRT(ABS(data.y[i,*]))
      data.dv[i,*]=SQRT(ABS(data.v[i,*]))
    ENDFOR
    data.v[*,0]=0.3*data.v[*,1]   ; to not have 0 hertz as the lowest freq
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'HSBM spec, '+type, $
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
      'MONOTON', 'INCREASE', $
      'SCALEMIN', 0.9*min(center_freq), $
      'SCALEMAX', 1.1*max(center_freq,/nan), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t_dt, $
      'Time_end'        ,     clock_end_t_dt, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      ; 'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: HSBM'+type, $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Hz]', $
      'cal_v_const1'    ,     'Used: ' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      'zsubtitle'       ,     '[RAW]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     lpw_const.tplot_char_size ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'hsbm_full_burst_'+type ,$
      'yrange' ,        [0.9*min(center_freq),1.1*max(center_freq,/nan)],$
      'ystyle'  ,       1.                       ,$
      'ylog'   ,        1.                       ,$
      'ztitle' ,        'Frequency'              ,$
      'zrange' ,        [1.*lpw_const.power_scale_hf,1.e7],$
      'zlog'   ,        1.                       ,$
      'spec'   ,        1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_spec_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------


    ;-------------  HSBM FFT bin as spectras ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,nn_bin) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,nn_bin) ,  $    ; same size as y
      'v',    fltarr(nn_pktnum,nn_bin) ,  $     ; same size as y
      'dv',   fltarr(nn_pktnum,nn_bin) )     ;1-D
    ;-------------- derive  time/variable ----------------
    get_data,'mvn_lpw_hsbm_spec_'+type,data=data2,limit=limit,dlimit=dlimit
    data.x=data2.x
    ii1=0   ;first bin is the 0 hz
    ii2=0
    for i=0,nn_bin-1 do begin
      ii2=ii1+f_bin[i]-1
      if ii1 EQ ii2 then data.y[*,i]=data2.y[*,ii1]  ELSE data.y[*,i]= total(data2.y[*,ii1:ii2],2)/f_bin[i]
      data.v[*,i]= data2.v[*,ii1+0.4*f_bin[i]]
      ii1=ii2+1
      data.dy[*,i]=data2.y[*,i]*.2
      data.dv[*,i]=data2.v[*,i]*.2
    endfor
    ;-------------------------------------------
    ;------------- What needs to be updated???? --------------------
    limit.ztitle='Freq (bin)'
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_spec_bin_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------


    ;-------------  HSBM FFT power---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum,2) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum,2)  )
    ;-------------- derive  time/variable ----------------
    get_data,'mvn_lpw_hsbm_spec_bin_'+type,data=data2
    data.x=data2.x
    print,'2222'
    data.y[*,0]=alog10( total(data2.y,2))
    for i=0,nn_pktnum-1 do begin
      data.y[i,1]=alog10(total(   data2.y[i,2:n_elements(data2.y[0,*])-1]   ))
    endfor
    data.dy[*,0:1]=data.y[*,0:1]*0.2
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'HSBM spec total, '+type, $
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
      'MONOTON', 'INCREASE', $
      'SCALEMIN', min(data.y,/nan), $
      'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t_dt, $
      'Time_end'        ,     clock_end_t_dt, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      ; 'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: HSBM'+type, $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[log10 raw]')
    ;-------------  limit ----------------
    qq=where(data.y GT 0,nq) ; only sum over points > 0 to get the lower yrange correct
    limit=create_struct(   $
      'char_size' ,     lpw_const.tplot_char_size ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'mvn_lpw_hsbm_tot_power_'+type,$
      'yrange' ,         [min(data.y[qq,0],/nan),max(data.y,/nan)] ,$
      'ystyle'  ,       1.                       ,$
      'labels' ,        [' ',' ']                    ,$
      'colors' ,        [4,6]                    ,$
      'labflag' ,       1                        ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_spec_total_'+type,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  hsbm_mode --------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum)  )     ;1-D
      ;-------------- derive  time/variable ----------------
      time_sort=sort(time)
      data.x = time[time_sort]
      data.y = output.orb_md[nn_index[time_sort]]
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'HSBM '+type+' mode', $
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
        'SCALEMAX', 18, $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSBM'+type, $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     lpw_const.tplot_char_size ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSBM_'+type+'_mode'     ,$
        'yrange' ,        [-1,18]                  ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_hsbm_'+type+'_mode',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------
    ENDIF


    IF nn_fft_size NE nn_size  THEN BEGIN   ;this is for MF which has longer burst
      nn_expand=nn_size/nn_fft_size
      ; I spread the time stamps out as much as possible, the time stamps is hterefore not accurate on the last three fft spectras
      ; print,' ###### ','mvn_lpw_hsbm_spec_long_'+type, ' is for the size ',nn_expand,nn_size,nn_fft_size,' warning with the time for this one'

      ;-------------  HSBM FFT LONG ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum*nn_expand) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) ,  $     ; most of the time float and 1-D or 2-D
        'dy',   fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) ,  $    ; same size as y
        'v',    fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) ,  $     ; same size as y
        'dv',   fltarr(nn_pktnum*nn_expand,nn_fft_size/2+1) )     ;1-D
      ;-------------- derive  time/variable ----------------
      time_sort=sort(time)
      FOR i=0,nn_pktnum-1 do BEGIN
        for ii=0,nn_expand-1 do begin
          if n_elements(time) GT 1  THEN $
            if i LT nn_pktnum-1 then ddt=time[time_sort[i+1]]-time[time_sort[i]] ELSE $
            ddt=time[time_sort[i]]-time[time_sort[i-1]] ELSE ddt=0.01; maximimize to spred them out
          data.x[i*nn_expand+ii]=time[time_sort[i]]+ii*ddt*0.25 ;;nn_fft_size*dt*ii    ;here I work to increase the time
          comp1=data_hsbm[ii*nn_fft_size:(ii+1)*nn_fft_size-1,time_sort[i]] ;*const_E12
          han = HANNING(nn_fft_size, /DOUBLE)
          powerHan = ABS(FFT(han*comp1))^2
          freq = FINDGEN(nn_fft_size)/(nn_fft_size*dt)
          data.y[i*nn_expand+ii,*]=powerHan[0:nn_fft_size/2]   ; note I magnify this value so it comes closer to the other spectras and one should do it the other way
          data.v[i*nn_expand+ii,*]= freq[0:nn_fft_size/2]
          data.dy[i*nn_expand+ii,*]=data.y[i*nn_expand+ii,*]*0.2
          data.dv[i*nn_expand+ii,*]=data.v[i*nn_expand+ii,*]*0.2
        endfor ;ii
      ENDFOR ;i
      data.v[*,0]=0.3*data.v[*,1]   ; to not have 0 hertz as the lowest freq
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'HSBM spec long '+type, $
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
        'MONOTON', 'INCREASE', $
        'SCALEMIN', 0.9*min(center_freq), $
        'SCALEMAX', 1.1*max(center_freq,/nan), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ; 'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSBM'+type, $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[alog10(Hz)]', $
        'cal_v_const1'    ,     'Used: ', $  ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;   'cal_v_const2'    ,     'Used :'  , $ ; Fixed convert information from measured binary values to physical units, variables from space testing
        'zsubtitle'       ,     '[raw]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     lpw_const.tplot_char_size ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'HSBM_spec_'+type,$
        'yrange' ,        [0.9*min(center_freq),1.1*max(center_freq,/nan)],$
        'ystyle'  ,       1.                       ,$
        'ylog'   ,        1.                       ,$
        'ztitle' ,        'Frequency'                ,$
        'zrange' ,        [1.*lpw_const.power_scale_hf,1.e7],$
        'zlog'   ,        1.                       ,$
        'spec'   ,        1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
        'noerrorbars', 1)
      ;------------- store --------------------
      store_data,'mvn_lpw_hsbm_spec_long_'+type,data=data,limit=limit,dlimit=dlimit
      ;--------------------------------------------------

      ;-------------  HSBM FFT LONG BIN---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum*nn_expand) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum*nn_expand,nn_bin) ,  $     ; most of the time float and 1-D or 2-D
        'dy',   fltarr(nn_pktnum*nn_expand,nn_bin) ,  $    ; same size as y
        'v',    fltarr(nn_pktnum*nn_expand,nn_bin) ,  $     ; same size as y
        'dv',   fltarr(nn_pktnum*nn_expand,nn_bin) )
      ;-------------- derive  time/variable ----------------
      get_data,'mvn_lpw_hsbm_spec_long_'+type,data=data2,limit=limit,dlimit=dlimit
      data.x=data2.x
      ii1=0   ;first bin is the 0 hz
      ii2=0
      for i=0,nn_bin-1 do begin
        ii2=ii1+f_bin[i]-1
        if ii1 EQ ii2 then data.y[*,i]=data2.y[*,ii1]  ELSE data.y[*,i]= total(data2.y[*,ii1:ii2],2)/f_bin[i]
        data.v[*,i]= data2.v[*,ii1+0.4*f_bin[i]]
        ii1=ii2+1
      endfor
      data.dy=data.dy*0.2
      data.dv=0
      ;-------------------------------------------
      ;------------- What needs to be updated???? --------------------
      limit.ztitle='Freq (bin)'
      ;------------- store --------------------
      store_data,'mvn_lpw_hsbm_spec_long_bin_'+type,data=data,limit=limit,dlimit=dlimit
      ;--------------------------------------------------


      ;-------------  HSBM FFT power2---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum*nn_expand) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum*nn_expand) ,  $     ; most of the time float and 1-D or 2-D
        'dy',   fltarr(nn_pktnum*nn_expand) )
      ;-------------- derive  time/variable ----------------
      get_data,'mvn_lpw_hsbm_spec_long_bin_'+type,data=data2
      data.x=data2.x
      data.y=alog10(total(data2.y,2))
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'HSBM spec total2 '+type, $
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
        'MONOTON', 'INCREASE', $
        'SCALEMIN', min(data.y(qq),/nan), $
        'SCALEMAX', max(data.y,/nan), $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t_dt, $
        'Time_end'        ,     clock_end_t_dt, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: HSBM'+type, $
        'xsubtitle'       ,     '[sec]', $
        'ysubtitle'       ,     '[log10 raw]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     lpw_const.tplot_char_size ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'mvn_lpw_hsbm_tot_power2_'+type,$
        'yrange' ,        [min(data.y[qq],/nan),max(data.y,/nan)],$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
        'noerrorbars', 1)
      ;------------- store --------------------
      store_data,'mvn_lpw_hsbm_spec_total2_'+type,data=data,limit=limit,dlimit=dlimit
      ;--------------------------------------------------
    ENDIF   ;IF nn_fft_size NE nn_size  THEN BEGIN   ;this is for MF which has longer burst




    ;----------- in case gst is active - not for flight data----------------------
    if n_elements(output.SC_CLK1) EQ n_elements(output.SC_CLK1_gst) THEN BEGIN

      nn_index2=where(output.APID2 EQ output.APID[nn_index[0]],nq)

      time1=double(output.SC_CLK1[nn_index]) + double(output.SC_CLK2[nn_index])/2l^16+t_epoch
      time2=double(output.SC_CLK1_gst[nn_index2]) + double(output.SC_CLK2_gst[nn_index2])/2l^16+t_epoch
      time3=double(output.SC_CLK3_gst[nn_index2]) + double(output.SC_CLK4_gst[nn_index2])/2l^16+t_epoch

      if type EQ 'hf' THEN time1=time1-0.001
      if type EQ 'mf' THEN time1=time1-0.0625
      if type EQ 'lf' THEN time1=time1-1.0
      ;Correction is not needed for the gsm/gst time (i.e time2 and time3)
      ;from Corinnes read_htime
      htime_length = output.length[output.htime_i]
      htime_clk = output.SC_CLK1[output.htime_i]
      ii = 0
      for i = 0,n_elements(htime_length)-1 do begin ;loop over three
        for iii = 0,(((htime_length[i]-1)/2)-7)/2 do begin   ; the length derived in r_header such that -1 should not be used
          if ii eq 0 then abs_cap_time  = double(output.cap_time[ii]  + htime_clk[i]) else abs_cap_time  = [abs_cap_time,  double(output.cap_time[ii] + htime_clk[i]) ]
          if ii EQ 0 then abs_xfer_time = double(output.xfer_time[ii] + htime_clk[i]) else abs_xfer_time = [abs_xfer_time, double(output.xfer_time[ii] + htime_clk[i])]
          ii = ii+1
        endfor
      endfor
      column1 = string(output.htime_type)
      column2 = string(output.cap_time)
      column3 = string(output.xfer_time)
      column4 = string(abs_cap_time,format = '(Z08)')
      column5 = string(abs_xfer_time,format = '(Z08)')
      print,'############################ start type ',type,' #####################################'
      print,"       TYPE      REL_CAP_TIME      REL_XFER_TIME     index      ABS_CAP_TIME     ABS_XFER_TIME      index     packet_CAP_TIME   gse_XFER_TIME"
      iii=0
      for i=0, n_elements(output.htime_type)-1 do $
        if  (output.APID[nn_index[0]] EQ 95) and (output.htime_type[i] EQ 0) then begin
        print,column1[i]+string(9B)+column2[i]+string(9B)+column3[i]+string(9B)+string(i)+string(9B)+" 0x"+column4[i]+string(9B)+" 0x"+column5[i]+ $
          string(9B)+string(iii)+string(9B)+" 0x"+string(output.SC_CLK1[nn_index2[iii]],format = '(Z08)')+string(9B)+" 0x"+string(output.SC_CLK1_gst[nn_index2[iii]],format = '(Z08)')
        iii=iii+1
      endif
      ii=0
      for i=0,n_elements(output.htime_type)-1 do $
        if  (output.APID[nn_index[0]] EQ 96) and (output.htime_type[i] EQ 1) then begin
        print,column1[i]+string(9B)+column2[i]+string(9B)+column3[i]+string(9B)+string(i)+string(9B)+" 0x"+column4[i]+string(9B)+" 0x"+column5[i]+ $
          string(9B)+string(iii)+string(9B)+" 0x"+string(output.SC_CLK1[nn_index2[iii]],format = '(Z08)')+string(9B)+" 0x"+string(output.SC_CLK1_gst[nn_index2[iii]],format = '(Z08)')
        iii=iii+1
      endif
      ii=0
      for i=0,n_elements(output.htime_type)-1 do $
        if  (output.APID[nn_index[0]] EQ 97) and (output.htime_type[i] EQ 2) then begin
        print,column1[i]+string(9B)+column2[i]+string(9B)+column3[i]+string(9B)+string(i)+string(9B)+" 0x"+column4[i]+string(9B)+" 0x"+column5[i]+ $
          string(9B)+string(iii)+string(9B)+" 0x"+string(output.SC_CLK1[nn_index2[iii]],format = '(Z08)')+string(9B)+" 0x"+string(output.SC_CLK1_gst[nn_index2[iii]],format = '(Z08)')
        iii=iii+1
      endif
      print,'############################ end type ',type,' #####################################'

    ENDIF   ;----------- in case gst is active ----------------------




    ;------------- variable:  HSBM+type L1-raw  ---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum) ,  $           ; double 1-D arr
      'y',    fltarr(nn_pktnum, nn_size+1) )    ;1-D
    ;-------------- derive  time/variable ----------------

    for i=0L,nn_pktnum-1 do begin
      data.x[i]                          = time[time_sort[i]]                  ;sc time only
      data.y[nn_size*i:nn_size*(i+1)-1]  = data_hsbm(*,time_sort[i])
      data.y[i,nn_size+0]                = output.orb_md[nn_index[time_sort[i]]]
    endfor
    str1=['E12 DN'+strarr(nn_size),'Orbit mode']
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'MAVEN LPW RAW HSBM L0b '+type, $
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
      'Time_field'      ,             ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
      'SPICE_kernel_version',        'NaN', $
      'SPICE_kernel_flag'      ,     'SPICE not used', $
      'L0_datafile'     ,            filename_L0 , $
      'cal_source'      ,            'Information from PKT: HSBM '+type+'-raw', $
      'xsubtitle'       ,            '[sec]', $
      'ysubtitle'       ,            '[Raw Packet Information]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'xtitle' ,                      'Time (s/c)'             ,$
      'ytitle' ,                      'Misc'                 ,$
      'labels' ,                      str1                    ,$
      'yrange' ,                      [min(data.y),max(data.y)] )
    ;------------- store --------------------
    store_data,'mvn_lpw_hsbm_'+type+'_l0b',data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------


  ENDIF

  IF output.p20 LE 0 AND type EQ 'lf' THEN print, "mvn_lpw_hsbm.pro skipped for keyword 'lf' as no packets found."
  IF output.p21 LE 0 AND type EQ 'mf' THEN print, "mvn_lpw_hsbm.pro skipped for keyword 'mf' as no packets found."
  IF output.p22 LE 0 AND type EQ 'hf' THEN print, "mvn_lpw_hsbm.pro skipped for keyword 'hf' as no packets found."

end
;*******************************************************************









