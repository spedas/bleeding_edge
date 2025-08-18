;;+
;PROCEDURE:   mvn_lpw_pkt_spectra
;PURPOSE:
;  Takes the decumuted data (L0) from the SPEC packets
;  and turn it the data into L1 and L2 data tplot structures
;  ; Warning for the moment am I not correcting for the number of frequency bins the fpga is operating in.
;  ; if this is changing correct mvn_lpw_wdg_3_spec_freq according to
;  ;Warning for the moment I do not correct that due to the Hanning window 1/2 of the power is missing
;  NOTE E12_HF gain boost is modified manually for the moment
;
;USAGE:
;  mvn_lpw_pkt_spectra,output,lpw_const,cdf_istp_lpw,subcycle,type,tplot_var
;
;INPUTS:
;       output:         L0 data
;       lpw_const:      information of lpw calibration etc
;       subcycle:       'PAS' or 'ACT' subcycle
;       type:           'LF', 'MF' or 'HF' frequency range
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'    => 'sci' produces tplot variables which have physical units associated with them as is the default
;                                     => 'all' produces all tplot variables
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.
;
;CREATED BY:   Laila Andersson 17 august 2011
;FILE: mvn_lpw_pkt_spectra.pro
;VERSION:   3.0  <------------------------------- update 'pkt_spec' variable
;LAST MODIFICATION:
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;2013, July 11th, Chris Fowler - added IF statement to check for data.; 04/15/14 L. Andersson included L1
;04/18/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. Andersson
;2014-10-03: CF: edited dlimits for ISTP compliance.
;2014-12-12 T.McEnulty: input spec calib info from a text file that is named in instrument_constants
;2014-12-12 L.Andersson: added constant to power in spec and spec2, started putting in physical units
;2015-01-08 Tess&Laila making spec and sepc2 ready for pdr_w_n production
;2015-01-08 Tess&Laila making spec and sepc2 ready for pdr_w_n production

pro mvn_lpw_pkt_spectra,output,lpw_const,subcycle,type,tplot_var=tplot_var,spice=spice

  IF (output.p14 GT 0 AND subcycle EQ 'act' AND type EQ 'lf') OR $  ;check for data, for keywords 'act' and 'lf'
    (output.p15 GT 0 AND subcycle EQ 'act' AND type EQ 'mf') OR $  ;check for data, for keywords 'act' and 'mf'
    (output.p16 GT 0 AND subcycle EQ 'act' AND type EQ 'hf') OR $  ;check for data, for keywords 'act' and 'hf'
    (output.p17 GT 0 AND subcycle EQ 'pas' AND type EQ 'lf') OR $  ;check for data, for keywords 'pas' and 'lf'
    (output.p18 GT 0 AND subcycle EQ 'pas' AND type EQ 'mf') OR $  ;check for data, for keywords 'pas' and 'mf'
    (output.p19 GT 0 AND subcycle EQ 'pas' AND type EQ 'hf') $     ;check for data, for keywords 'pas' and 'hf'
    THEN     BEGIN



    If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.


    ;--------------------- Constants Used In This Routine ------------------------------------
    t_routine            = SYSTIME(0)
    t_epoch              = lpw_const.t_epoch
    today_date           = lpw_const.today_date
    cal_ver              = lpw_const.version_calib_routine
    pkt_ver              = 'pkt_spec Ver  V3.0'
    cdf_istp             = lpw_const.cdf_istp_lpw
    filename_L0          = output.filename
    h_window             = lpw_const.h_window
    f_zero_freq0         = lpw_const.f_zero_freq0    ; this is for the lowest fequency bin suggestion from MMS
    hfgain               = 0.                        ; default, only important for HF-data
    ;----------------------------------------------------------------
    calib_file_spec      = lpw_const.calib_file_spec      ; this is where calibration information for the spectras can be added if needed   note time sencitive
    inst_phys            = lpw_const.inst_phys
    sensor_distance      = lpw_const.sensor_distance
    boom_shorting_factor = lpw_const.boom_shortening
    ;--------------------------------------------------------------------

    IF type EQ 'hf' and subcycle EQ 'act' and output.p16 GT 0 then begin
      nn_pktnum      =output.p16          ; number of data packages
      n_bins_spec    =lpw_const.nn_bin_hf
      data_Spec      =output.ACT_S_HF
      timestep       = lpw_const.nn_fft_size/(lpw_const.nn_fft_hf*lpw_const.nn_fft_size)           ; 4MS/s -- 1/datarate of waveform
      center_freq    =lpw_const.center_freq_hf
      nn_index       =output.ACT_S_HF_i
      power_scale    =lpw_const.power_scale_hf * [lpw_const.E12_hf,lpw_const.E12_hf_hg]
      pktarr         =output.act_HF_pktarr
      f_zero_freq    =lpw_const.f_zero_freq_hf

      ;print,'###HF ACT  E12_HF gain boost ####',output.E12_HF_GB[nn_index]
      ;hfgain....const_E12_HF_HG vs const_E12_HF

    endif
    IF type EQ 'mf' and subcycle EQ 'act' and output.p15 GT 0 then begin
      nn_pktnum=output.p15                                    ; number of data packages
      n_bins_spec=lpw_const.nn_bin_mf
      data_Spec=output.ACT_S_MF
      timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_mf*lpw_const.nn_fft_size)            ; 64kS/s -- 1/datarate of waveform
      center_freq=lpw_const.center_freq_mf
      nn_index=output.ACT_S_MF_i
      power_scale=lpw_const.power_scale_mf  * [lpw_const.E12_mf]
      pktarr=output.act_MF_pktarr
      f_zero_freq    =lpw_const.f_zero_freq_mf
    endif
    IF type EQ 'lf' and subcycle EQ 'act' and output.p14 GT 0 then begin
      nn_pktnum       =output.p14                                    ; number of data packages
      n_bins_spec     =lpw_const.nn_bin_lf
      data_Spec       =output.ACT_S_LF
      timestep        = lpw_const.nn_fft_size/(lpw_const.nn_fft_lf*lpw_const.nn_fft_size)            ; kS/s -- 1/datarate of waveform
      center_freq     =lpw_const.center_freq_lf
      nn_index        =output.ACT_S_LF_i
      power_scale     =lpw_const.power_scale_lf  * [lpw_const.E12_lf]
      pktarr          =output.act_LF_pktarr
      f_zero_freq     =lpw_const.f_zero_freq_lf
    endif
    IF type EQ 'hf' and subcycle EQ 'pas' and output.p19 GT 0 then begin
      nn_pktnum      =output.p19                                     ; number of data packages
      n_bins_spec    =lpw_const.nn_bin_hf
      data_Spec      =output.PAS_S_HF
      timestep       = lpw_const.nn_fft_size/(lpw_const.nn_fft_hf*lpw_const.nn_fft_size)           ; 4MS/s -- 1/datarate of waveform
      center_freq    =lpw_const.center_freq_hf
      nn_index       =output.PAS_S_HF_i
      power_scale    =lpw_const.power_scale_hf   * [lpw_const.E12_hf,lpw_const.E12_hf_hg]
      pktarr         =output.pas_HF_pktarr
      f_zero_freq    =lpw_const.f_zero_freq_hf

      ;print,'### HF PAS  E12_HF gain boost ####',output.E12_HF_GB[nn_index]
      ;hfgain....const_E12_HF_HG vs const_E12_HF

    endif
    IF type EQ 'mf' and subcycle EQ 'pas' and output.p18 GT 0 then begin
      nn_pktnum=output.p18                                     ; number of data packages
      n_bins_spec=lpw_const.nn_bin_mf
      data_Spec=output.PAS_S_MF
      timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_mf*lpw_const.nn_fft_size)            ; 64kS/s -- 1/datarate of waveform
      center_freq=lpw_const.center_freq_mf
      nn_index=output.PAS_S_MF_i
      power_scale=lpw_const.power_scale_mf  * [lpw_const.E12_mf]
      pktarr=output.pas_MF_pktarr
      f_zero_freq    =lpw_const.f_zero_freq_mf
    endif
    IF type EQ 'lf' and subcycle EQ 'pas' and output.p17 GT 0 then begin
      nn_pktnum=output.p17 ;n_elements(nn_index)                                  ; number of data packages
      n_bins_spec=lpw_const.nn_bin_lf
      data_Spec=output.PAS_S_LF
      timestep = lpw_const.nn_fft_size/(lpw_const.nn_fft_lf*lpw_const.nn_fft_size)           ; kS/s -- 1/datarate of waveform
      center_freq=lpw_const.center_freq_lf
      nn_index=output.PAS_S_LF_i
      power_scale=lpw_const.power_scale_lf * [lpw_const.E12_lf]
      pktarr=output.pas_LF_pktarr
      f_zero_freq    =lpw_const.f_zero_freq_lf
    endif
    if total(data_Spec) EQ 0 OR nn_pktnum LE 1 then begin
      Print,'(mvn_lpw_spectra) Either no data or wrong cycle/type ',nn_pktnum,subcycle,type
      return;
    endif
    ;------------------
    nn_pktnum_extra=total(pktarr)-nn_pktnum  ; if multiple spectras is in one and the same spectra here is how many

    ;------------------
    n_lines_temp1 = n_bins_spec/2
    ;---------------------------------------------



    ;-------------------- Get correct clock time ------------------------------
    time_sc   = double(output.SC_CLK1[nn_index])+output.SC_CLK2[nn_index]/2l^16 +t_epoch       ;the packet time
    time_dt   = dblarr(nn_pktnum+nn_pktnum_extra)                                              ;time of each spectra
    ; -------- there can be multiple spectra in each packet, identify the time for each data point
    get_data,'mvn_lpw_'+subcycle+'_mc_len',data=data_mc_len                                    ; the information from pas/act is required to be processed first
    ti=0
    for i=0,nn_pktnum-1 do $
      for ii=0,pktarr[i]-1 DO BEGIN                                                            ; each packets can have different number of spectra, look at on packet at a time
      IF MAX(size(data_mc_len)) GT 0 THEN BEGIN                                            ; pas-packet has not been read in?
        qq=min(abs(time_sc[i]-data_mc_len.x),nq)                              ; find the closest, this can be an error around mode switching, WARNING THIS CAN FAIL AT A BOUNDARY OF A MODE CHANGE
        time_dt[ti] = time_sc[i]+ii*data_mc_len.y[nq]                         ; get the right time, one spectra per master cycle
      ENDIF ELSE time_dt[ti] = time_dt[i]+ii*4                                             ; assume 4 second time if the pas-packet has not been read in
      ti=ti+1                                                                              ; this increment time_dt
    ENDFOR                                                                                   ; ii, loop over each packet
    IF keyword_set(spice)  THEN BEGIN                                                                          ; if this computer has SPICE installed:
      aa=floor(time_dt-t_epoch)
      bb=floor(((time_dt-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
      mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,time  ;correct times using SPICE
    ENDIF ELSE BEGIN
      clock_field_str  = ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00']
      time             = time_dt                                                           ;data points in s/c time
      clock_start_t    = [time_sc[0]-t_epoch,          time_sc[0]]                         ;corresponding start times to above string array, s/c time
      clock_end_t      = [time_sc[nn_pktnum-1]-t_epoch,time_sc[nn_pktnum-1]]               ;corresponding end times, s/c time
      spice_used       = 'SPICE not used'
      str_xtitle       = 'Time (s/c)'
      kernel_version    = 'N/A'
    ENDELSE
    ;--------------------------------------------------------------------



    ;----------  variable:  spectra   ------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum+nn_pktnum_extra) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) ,  $    ; same size as y
      'v',    fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) ,  $     ; same size as y
      'dv',   fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec) )     ;1-D
    ;-------------- derive  time/variable ----------------
    data.x = time                                                        ;time_dt derived in SPICE part above
    for i=0,nn_pktnum+nn_pktnum_extra-1 do data.v[i,*] = center_freq                                            ;frequency value
    ; data_cpec will be  nn_pktnum* pktarr*( n_bins_spec+1)   -> where 1 is the packet number witnin each spectra which needs to be striped off
    ;each spectra will be the packet number followed by n_bins_spec/2 numbers make that as a variable:
    nn_bins_total=1+n_bins_spec/2  ;-1
    ;------------- Break into Different Data Points
    split_E_M=fltarr(4)                           ;for each row in the package (n_lines_temp1) there will be 4 values extracted
    ;------------

    iu=0
    for iu1 = 0 , nn_pktnum-1 do begin
      for iu2 = 0 , pktarr[iu1]-1, 1 do begin
        for ie=0L, nn_bins_total-2 do begin ; 0:nn_bins_total-2 is values used to get the information into data.y but they are located inlocated in from 1:nn_bins_total-1 in data_spec
          nn_data_spec=long(iu)*long(nn_bins_total)+long(ie+1) ;+ui1  ;try to read the rigth values from data_spec
          string_tmp=string(data_spec[nn_data_spec],format='(B016)')  ;string(data_spec(i,ie),format='(B016)')
          reads,string_tmp,split_E_M,format='(B005,B003,B005,B003)'         ;break each row into 4 values
          ;-------------                                 Taking every fourth number of array (mattisa+exponent * two_values =4 for each row in the package)
          data.y[iu,ie*2] =    (split_E_M[3] + 8d) * 2d^(split_E_M[2] - 1d)
          data.y[iu,ie*2+1]  = (split_E_M[1] + 8d) * 2d^(split_E_M[0] - 1d)
          ;-------------                                 Checking for exponent = 0, if 0 only mantissa is used
          data.y[iu,ie*2]     = data.y[iu,ie*2]  *(split_E_M[2] NE 0 ) + (split_E_M[2] EQ 0) * split_E_M[3]
          data.y[iu,ie*2+1]   = data.y[iu,ie*2+1] *(split_E_M[0] NE 0 ) + (split_E_M[0] EQ 0) * split_E_M[1]
        endfor                ;ie
        iu=iu+1              ;spectra number
      endfor  ;iu2
    endfor ;iu1

    data.y=data.y +0.5   ; add one half DN as a noise floor

    ;--------- fix gain state if it is HF -------

    gain=fltarr(nn_pktnum+nn_pktnum_extra)

    if 'type' EQ 'hf' then begin
      gain=( total(data.y < 5,2) GT 300 )  ;;should try 5 or 10
    endif
    ;--------

    mvn_lpw_cal_read_spec_data,type,subcycle,hfgain,calib_file_spec,filename,background,f_low,f_high,amp_resp
    major_bin = [80,104,110,112,118,120,121,124,127]


    for j=0, n_elements(data.x)-1 do begin
      data.dv[j,*]   =abs( transpose((f_high-f_low)/2) ) ;get the low and high frequency bins
    endfor

    data.dy   = 0.2 * ABS(data.y)   ; 20 % uncertnaty.....

    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'spec '+type+' '+subcycle, $
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
      'MONOTON',                       'INCREASE', $
      'SCALEMIN',                      0.9*min(center_freq,/nan), $
      'SCALEMAX',                      1.1*max(center_freq,/nan), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t, $
      'Time_end'        ,     clock_end_t, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used '+subcycle+ ': # '+strcompress(power_scale,/remove_all)+' # ' +  $
      strcompress(h_window,/remove_all)+' # '+ strcompress(f_zero_freq,/remove_all),$ ; nned ampitude also ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      'cal_y_const2'    ,     major_bin, $;'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      'cal_datafile'    ,     'No Calibration File used' , $
      'cal_source'      ,     'From PKT: spec_'+type +'_'+ subcycle, $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[Hz]', $
      'cal_v_const1'    ,     'Used: ' + strcompress(min(f_zero_freq0 ), /remove_all) + ' # '+ $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      strcompress(max(f_zero_freq0 ), /remove_all) ,$
      ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
      'zsubtitle'       ,     '[raw]')
    ;-------------  limit ----------------
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        ' Frequency'+subcycle+'_'+type,$
      'yrange' ,        [0.9*min(center_freq,/nan),1.1*max(center_freq,/nan)] ,$
      'ystyle'  ,       1.                       ,$
      'ylog'   ,        1.                       ,$
      'ztitle' ,        'Raw Units'    ,$
      'zrange' ,        [0.1,1e8]                ,$   ;working units, with white background
      'zlog'   ,        1.                       ,$
      'spec'   ,        1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_spec_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
    ;---------------------------------------------

    ;----------  variable:  spectra2  value/freq  ------------------
    ;-------------- derive  time/variable ----------------

    ; this is done allready above:
    ;   mvn_lpw_cal_read_spec_data,type,subcycle,hfgain,calib_file_spec,filename,background,f_low,f_high,amp_resp



    if min(data.dv)                lt 0 then stanna


    ;   data.y               = data.y  ; * power_scale[gain]  * h_window * f_zero_freq     ;C/sensor_distance                           ;get the right y-sacle for the three different frequency ranges
    ;  data.y[*,0]          = data.y[*,0]*f_zero_freq0                                                   ;This is what was needed on MMS to correct for too much power in 0-bin from FPGA algorithm
    dlimit.cal_y_const1  ='Used '+subcycle+': # '+strcompress(power_scale,/remove_all)+' # '+strcompress(h_window,/remove_all)+' # '+ strcompress(f_zero_freq,/remove_all)
    dlimit.zsubtitle     = '[Power/Freq units]'

    if type EQ 'hg' then begin
      ;      background2          = background* power_scale[gain]  * h_window * f_zero_freq  ; get the same units as data.y
      for i=0,n_bins_spec-1 do $
        data.y[*,i]   =(data.y[*,i]-background2[i]) ;/amp_resp[i]);>  ;;the 2's are for the FFT and Hanning
    endif

    if type EQ 'lf' then begin
      major_bin = [0 ,   1]
      low_bin   = [3 ,   3]
      mag_bin   = [5 ,3]
      corr=1.2
      rc_l1=1.75e-3
      rc_l2=1.75e-3
      tt=1./SQRT(1+(rc_l1*data.v[0,*])^2) * 1./SQRT(1+(rc_l2*data.v[0,*])^2)
      tt_norm=tt[0,*]/max(tt[0,*])

      tt=(1./SQRT(1+(0.015*data.v[0,*])^2))
      tt_norm=tt[0,*]/max(tt[0,*])
      corr= 1. ; 1./200



      rr_norm= fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec)
      for rr=0,n_bins_spec-1 do rr_norm[*,rr]=(1.0/tt_norm[rr])^2*corr


    end

    if type EQ 'mf' then begin
      major_bin = [0,   1, 38]
      low_bin   = [3,   3, 37]
      mag_bin   = [1e6,5e5,1e3]
      corr=0.15 * 0.2
      rc_l=1.18e-4   ;
      rc_h=0.31e-2   ;
      tt= 1./SQRT(1+(rc_l*data.v[0,*])^2) * rc_h*data.v[0,*]/SQRT(1+(rc_h*data.v[0,*])^2)
      tt_norm=tt[0,*]/max(tt[0,*])
      tt_norm[0:4]=tt_norm[0:4]*[19,4.5,2.2,1.45,1.1]


      tt=(1./SQRT(1+(0.00045*data.v[0,*])^2))
      tt_norm=tt[0,*]/max(tt[0,*])

      corr=  1./4.



      rr_norm= fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec)
      for rr=0,n_bins_spec-1 do rr_norm[*,rr]=(1.0/tt_norm[rr])^2*corr
    endif
    if type EQ 'hf' then begin  ;'hfhg'
      major_bin = [0,      1,  2, 3,56,64,79,80,83,103,104,108,110,112,118,119,120,123,124,127]
      low_bin   = [4,      4,  4, 4,54,62,77,77,82,101,101,106,106,106,116,116,116,122,122,126]
      mag_bin   = [2000,2000,500,2.,4.,2.,4.,8.,6., 4., 10., 4., 6., 8., 4., 7., 10., 4, 8.,20.]

      ;this is for no gain
      ;hf
      corr0=0.005
      rc_l=1.18e-4   ;
      rc_h=0.15e-2   ;
      rc_l3=0.8e-6   ;
      rc_h3=1.8e-5   ;
      a2=0.35

      ;      corr0=0.001*2 ;0.008
      ;      rc_l=1.e-4   ;
      ;      rc_h=0.4e-2   ;
      ;      rc_l3=1.2e-6/0.6   ;
      ;      rc_h3=1.3e-5   ;
      ;      a2=0.40
      tt= rc_h3*data.v[0,*]/SQRT(1+(rc_h3*data.v[0,*])^2)*  a2/SQRT(1+(rc_l3*data.v[0,*])^2)+ 1./SQRT(1+(rc_l*data.v[0,*])^2) * rc_h*data.v[0,*]/SQRT(1+(rc_h*data.v[0,*])^2)
      tt_norm0=tt/max(tt)
      ;adjust the lowest bins
      ;  tt=(1./SQRT(1+(0.00005*data.v[0,*])^2))  ;lowest bin
      ; tt=(1./SQRT(1+(0.0005*data.v[0,*])^2))  ;lowest second bin
      tt_norm0=SQRT(tt/max(tt))    *0.095*alog10(129.-indgen(128))

      ;this is for gain 1  hg
      corr1=0.001
      rc_l=1.e-4   ;
      rc_h=0.4e-2   ;
      rc_l3=1.2e-6   ;
      rc_h3=1.3e-5   ;
      a2=0.40
      tt=rc_h3*data.v[0,*]/SQRT(1+(rc_h3*data.v[0,*])^2)*  a2/SQRT(1+(rc_l3*data.v[0,*])^2)+ 1./SQRT(1+(rc_l*data.v[0,*])^2) * rc_h*data.v[0,*]/SQRT(1+(rc_h*data.v[0,*])^2)
      tt_norm1=tt/max(tt)
      ;adjust the lowest bins
      tt=(1./SQRT(1+(0.000002*data.v[0,*])^2))  ;lowest bin
      tt=(1./SQRT(1+(0.00002*data.v[0,*])^2))  ;lowest second bin
      tt_norm1=tt/max(tt)



      ;get the correction right

      gain=( total(data.y < 5,2) GT 300 )  ;;should try 5 or 10

      rr_norm= fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec)
      rr_norm2= fltarr(nn_pktnum+nn_pktnum_extra)
      for rr=0,n_bins_spec-1 do begin
        rr_norm[*,rr]=(1.0/tt_norm0[rr])^2*(gain EQ 0)*corr0+(1.0/tt_norm1[rr])^2*(gain EQ 1)*corr1
        rr_norm2[*]=                       (gain EQ 0)*corr0+                     (gain EQ 1)*corr1
      endfor

    end



    ;remove_background
    for i=0l,n_elements(major_bin)-1  do   data.y[*,major_bin[i]]=data.y[*,major_bin[i]]/mag_bin[i] >data.y[*,low_bin[i]]
    ;get units
    df=data.v[0,2]-data.v[0,1]
    dl=12.68
    for i=0l,n_elements(data.y[0,*])-1 do   data.y[*,i]=(data.y[*,i]*rr_norm[*,i]/4096)/6815744/5/0.8/dl^2



    data.dy   = data.y * 0.3  ; this needs to be reevaluated
    zmin                =1e-14   ; not used ;fine tune if this is the right value to use as minimum
    data.y              =data.y
    limit.zrange        =[1e-14,1e-8]
    limit.ztitle        = '[(V/m)^2/Hz]'
    dlimit.cal_datafile = filename
    dlimit.data_type = 'CAL>calibrated'
    ;=====
    ;we need also corr_pas_hg and corr_pas_hg
    ;
    ;-------------------------------------------
    store_data,'mvn_lpw_spec2_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
    if type EQ 'hf' then  store_data,'mvn_lpw_spec2_hg_'+subcycle,data={x:data.x,y:rr_norm2}
    ;---------------------------------------------



    if min(data.dv)                lt 0 then stanna


    ;-------------  HSBM FFT power---------------------------
    data =  create_struct(   $
      'x',    dblarr(nn_pktnum+nn_pktnum_extra) ,  $     ; double 1-D arr
      'y',    fltarr(nn_pktnum+nn_pktnum_extra,2) ,  $     ; most of the time float and 1-D or 2-D
      'dy',   fltarr(nn_pktnum+nn_pktnum_extra,2) )     ;1-D
    ;-------------- derive  time/variable ----------------
    get_data,'mvn_lpw_spec_'+type+'_'+subcycle,data=data2
    data.x=data2.x
    data.y[*,0]=alog10(total(data2.y,2))
    for i=0,nn_pktnum+nn_pktnum_extra-1 do $
      data.y[i,1]=alog10(total(   data2.y[i,2:n_elements(data2.y[0,*])-1]   ))
    data.dy=0
    ;-------------------------------------------
    ;--------------- dlimit   ------------------
    dlimit=create_struct(   $
      'Product_name',                  'spec total '+type+' '+subcycle, $
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
      'SCALEMIN', 0.95*min(data.y,/nan), $
      'SCALEMAX', 1.05*max(data.y,/nan), $        ;..end of required for cdf production.
      't_epoch'         ,     t_epoch, $
      'Time_start'      ,     clock_start_t, $
      'Time_end'        ,     clock_end_t, $
      'Time_field'      ,     clock_field_str, $
      'SPICE_kernel_version', kernel_version, $
      'SPICE_kernel_flag'      ,     spice_used, $
      'L0_datafile'     ,     filename_L0 , $
      'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
      'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
      ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
      ;'cal_datafile'    ,     'No calibration file used' , $
      'cal_source'      ,     'Information from PKT: SPEC_'+type +' and ACT/PAS', $
      'xsubtitle'       ,     '[sec]', $
      'ysubtitle'       ,     '[alog 10 raw]')
    ;-------------  limit ----------------
    qq=where(data.y[*,0] GT 0,nq) ; only sum over points > 0 to get the lower yrange correct
    limit=create_struct(   $
      'char_size' ,     1.2                      ,$
      'xtitle' ,        str_xtitle                   ,$
      'ytitle' ,        'mvn_lpw_spec_tot_power_'+type,$
      'yrange' ,        [0.95*min(data.y[qq,0],/nan),1.05*max(data.y,/nan)],$
      'ystyle'  ,       1.                       ,$
      'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
      'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
      'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
      'noerrorbars', 1)
    ;------------- store --------------------
    store_data,'mvn_lpw_spec_total_'+type+'_'+subcycle,data=data,limit=limit,dlimit=dlimit
    ;--------------------------------------------------


    IF tplot_var EQ 'ALL' THEN BEGIN
      ;------------- variable:  smp_avg ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum))     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time_sc                      ; time of the packet, not time of each data point
      data.y = output.smp_avg[nn_index]
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'Spec '+type+' '+subcycle+' smp average', $
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
        'SCALEMAX', max(data.y)+1, $        ;..end of required for cdf production.
        't_epoch'         ,     t_epoch, $
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: SPEC_'+type, $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'Spectra_'+type+'_smp_avg',$
        'yrange' ,        [-1,max(data.y)+1] ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_spec_'+type+'_'+subcycle+'_smp_avg',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------


      ;------------- variable:  spec_mode --------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
        'y',    fltarr(nn_pktnum) )     ;1-D
      ;-------------- derive  time/variable ----------------
      data.x = time_sc                      ; time of the packet, not time of each data point
      data.y = output.orb_md[nn_index]
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'Spec '+type+' '+subcycle+' mode', $
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
        'Time_start'      ,     clock_start_t, $
        'Time_end'        ,     clock_end_t, $
        'Time_field'      ,     clock_field_str, $
        'SPICE_kernel_version', kernel_version, $
        'SPICE_kernel_flag'      ,     spice_used, $
        'L0_datafile'     ,     filename_L0 , $
        'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$
        'cal_y_const1'    ,     'Used: '  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
        ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
        ;'cal_datafile'    ,     'No calibration file used' , $
        'cal_source'      ,     'Information from PKT: SPEC_'+type, $
        'xsubtitle'       ,     '[sec]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'char_size' ,     1.2                      ,$
        'xtitle' ,        str_xtitle                   ,$
        'ytitle' ,        'Spectra_'+type+'_mode'  ,$
        'yrange' ,        [-1,18]                  ,$
        'ystyle'  ,       1.                       ,$
        'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
        'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
        'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
      ;------------- store --------------------
      store_data,'mvn_lpw_spec_'+type+'_'+subcycle+'_mode',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------



      ;####!!!!  print,this is not correct>........
      ;------------- variable:  spectra type L1-raw  ---------------------------
      data =  create_struct(   $
        'x',    dblarr(nn_pktnum+nn_pktnum_extra) ,  $                   ; double 1-D arr
        'y',    fltarr(nn_pktnum+nn_pktnum_extra, n_bins_spec+2))
      ;-------------- derive  time/variable ----------------
      data.x=time_sc                     ; time of each packet!
      nn_bins_total=1+n_bins_spec/2                                                     ;-1
      ;-------------                                                                            Break into Different Data Points
      split_E_M=fltarr(4)                                                               ;for each row in the package (n_lines_temp1) there will be 4 values extracted
      ;------------
      iu=0
      for iu1 = 0 , nn_pktnum-1 do begin
        for iu2 = 0 , pktarr[iu1]-1, 1 do begin
          for ie=0L, nn_bins_total-2 do begin                                       ; 0:nn_bins_total-2 is values used to get the information into data.y but they are located inlocated in from 1:nn_bins_total-1 in data_spec
            nn_data_spec=long(iu)*long(nn_bins_total)+long(ie+1)                   ;+ui1  ;try to read the rigth values from data_spec
            string_tmp=string(data_spec[nn_data_spec],format='(B016)')             ;string(data_spec(i,ie),format='(B016)')
            reads,string_tmp,split_E_M,format='(B005,B003,B005,B003)'              ;break each row into 4 values
            ;-------------                                                                              Taking every fourth number of array (mattisa+exponent * two_values =4 for each row in the package)
            data.y[iu,ie*2] =    (split_E_M[3] + 8d) * 2d^(split_E_M[2] - 1d)
            data.y[iu,ie*2+1]  = (split_E_M[1] + 8d) * 2d^(split_E_M[0] - 1d)
            ;-------------                                                                              Checking for exponent = 0, if 0 only mantissa is used
            data.y[iu,ie*2]     = data.y[iu,ie*2]  *(split_E_M[2] NE 0 ) + (split_E_M[2] EQ 0) * split_E_M[3]
            data.y[iu,ie*2+1]   = data.y[iu,ie*2+1] *(split_E_M[0] NE 0 ) + (split_E_M[0] EQ 0) * split_E_M[1]
          endfor                                                                    ;ie
          iu=iu+1                                                                    ;spectra number
        endfor                                                                          ;iu2
      endfor                                                                              ;iu1
      ;------------                                                                               ;add last information into data-stucture
      iu=0
      for iu1 = 0 , nn_pktnum-1 do $
        for iu2 = 0 , pktarr[iu1]-1, 1 do begin
        data.x[iu]                = time_dt[iu]                                                    ;sc time only
        data.y[iu,n_bins_spec]    = output.smp_avg[nn_index[iu1]]
        data.y[iu,n_bins_spec+1]  = output.orb_md[nn_index[iu1]]
        iu=iu+1
      endfor
      str1=['E12 DN'+strarr(n_bins_spec),'Subcycle Length','Orbit mode']
      ;-------------------------------------------
      ;--------------- dlimit   ------------------
      dlimit=create_struct(   $
        'Product_name',                  'Spec '+type+' '+subcycle+' L0b', $
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
        'derivn',                        'Raw data', $    ;####
        'sig_digits',                    '# sig digits', $ ;#####
        'SI_conversion',                 'Convert to SI units', $  ;####
        'MONOTON',                     'INCREASE', $
        'SCALEMIN',                    min(data.y), $
        'SCALEMAX',                    max(data.y), $
        't_epoch'         ,            t_epoch, $
        'Time_start'      ,            [time_sc[0]-t_epoch,          time_sc[0]] , $
        'Time_end'        ,            [time_sc[nn_pktnum-1]-t_epoch,time_sc[nn_pktnum-1]], $
        'Time_field'      ,            ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00'], $
        'SPICE_kernel_version',        'NaN', $
        'SPICE_kernel_flag'      ,     'SPICE not used', $
        'L0_datafile'     ,            filename_L0 , $
        'cal_source'      ,            'Information from PKT: spectra_'+type+'-raw', $
        'xsubtitle'       ,            '[sec]', $
        'ysubtitle'       ,            '[Raw Packet Information]')
      ;-------------  limit ----------------
      limit=create_struct(   $
        'xtitle' ,                      'Time (s/c)'             ,$
        'ytitle' ,                      'Misc'                 ,$
        'labels' ,                      str1                    ,$
        'yrange' ,                      [min(data.y),max(data.y)] )
      ;------------- store --------------------
      store_data,'mvn_lpw_spec'+type+subcycle+'_l0b',data=data,limit=limit,dlimit=dlimit
      ;---------------------------------------------





    ENDIF


    options, 'mvn_lpw_*spec*', no_interp=1


  ENDIF else print, 'mvn_lpw_spectra.pro skipped for keywords '+subcycle+' and '+type+' as no packets found.'

END
;*******************************************************************







