;;+
;PROCEDURE:   mvn_lpw_pkt_swp
;PURPOSE:
;  Takes the decumuted data (L0) from the SWP1 or SWP2 packet
;  and turn it into L1 and L2 data in tplot structures
;  Noter to get all tplot variables both ATR packets and PAS packets are needed in tplot-structures
;
;USAGE:
;  mvn_lpw_pkt_swp,output,lpw_const,cdf_istp_lpw, swpn, tplot_var
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       cdf_istp_lpw:   istp required fields for cdf production
;       swpn:           sweep number; = 1 or 2
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'     => 'sci' produces tplot variables which have physical units associated with them and is the default
;                                      => 'all' produces all tplot variables
;
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.                                  
;                 
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_swp.pro
;VERSION:   3.0  <------------------------------- update 'pkt_ver' variable
;LAST MODIFICATION:   05/16/13
;                     2013, July 12th, Chris Fowler - combined mvn_lpw_swp1.pro and mvn_lpw_swp2.pro into this one file; added
;                           keyword tplot_var                           
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;17/01/14 C Fowler: added keyword cdf_istp_lpw to carry across istp required fields for cdf production.
;; 04/15/14 L. Andersson included L1
;04/18/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. Andersson
;20211110  updated the version number L.Andersson
;-

pro mvn_lpw_pkt_swp, output,lpw_const,swpn,tplot_var=tplot_var,spice=spice

If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'sci'  ;Default setting is science tplot variables only.

;Check if we have data packets before continuing:
IF (swpn EQ 1 AND output.p10 GT 0) OR $
   (swpn EQ 2 AND output.p11 GT 0) THEN BEGIN
               
       ;--------------------- Constants ------------------------------------          
               t_routine            = SYSTIME(0) 
               t_epoch              = lpw_const.t_epoch
               today_date           = lpw_const.today_date
               cal_ver              = lpw_const.version_calib_routine 
               pkt_ver              = 'pkt_swp_ver  V3.0' 
               cdf_istp             = lpw_const.cdf_istp_lpw                                      
               filename_L0          = output.filename
      ;----------------------------------------------------------------         
               inst_phys            = lpw_const.inst_phys
               sensor_distance      = lpw_const.sensor_distance
               boom_shorting_factor = lpw_const.boom_shortening              
               subcycle_length      = lpw_const.sc_lngth
               nn_steps             = long(lpw_const.nn_swp)                                   ;number of samples in one subcycle SWP
               nn_pa                = long(lpw_const.nn_pa)                                    ;number of samples in one subcycle PAS for the izero correction
               sample_aver          = lpw_const.sample_aver
               const_sign           = lpw_const.sign
       ;--------------------------------------------------------------------     
       mvn_lpw_cal_read_bias,bias_arr,bias_file     
       ;--------------------------------------------------------------------      
      CASE swpn OF 
         1: BEGIN
            ;--------------------- Constants SWP 1 specific ------------------------------------
            const_I_readback        = lpw_const.I1_readback
            const_V_readback        = lpw_const.V2_readback
            boom_corr               = lpw_const.boom2_corr   ; this should be the same number as for potential
            epsilon                 = lpw_const.const_epsilon1           
            ;-------------------------information from output-------------------------------------------
            boom_corr               = lpw_const.boom2_corr
            output_swp_i            = output.swp1_i
            output_swp_ii           = output.swp1_I1
            output_swp_V            = output.swp1_V2
            output_I_ZERO           = output.I_ZERO1
            output_swp_dyn_offset   = output.swp1_dyn_offset1  
            nn_pktnum               = output.p10            ; number of data packages 
            vnum                    = 2                     ;voltage number (2 for swp1; 1 for swp2)   
       END
         2: BEGIN
            ;--------------------- Constants SWP 2 specific------------------------------------
            const_I_readback        = lpw_const.I2_readback
            const_V_readback        = lpw_const.V1_readback
             boom_corr              = lpw_const.boom1_corr  ; this should be the same number as for potential
            epsilon                 =lpw_const.const_epsilon2
            ;-------------------------------information from output-------------------------------------
            boom_corr               = lpw_const.boom1_corr
            output_swp_i            = output.swp2_i
            output_swp_ii           = output.swp2_I2
            output_swp_V            = output.swp2_V1
            output_I_ZERO           = output.I_ZERO2
            output_swp_dyn_offset   = output.swp2_dyn_offset2  
            nn_pktnum               = output.p11        ; number of data packages 
            vnum                    = 1             ;voltage number (2 for swp1; 1 for swp2)   
         END
      ENDCASE
      ;--------------------------------------------------------------------      
      nn_size                       = long(nn_pktnum)*long(nn_steps)                     ; number of data points
      ;---------------------------------------------
      
      ;------------- Checks ---------------------
      if output.p10 NE n_elements(output_swp_i) AND swpn EQ 1 then stanna
      if n_elements(output_swp_i) EQ 0 AND swpn EQ 1 then print,'(mvn_lpw_swp1) No packages where found <---------------'
      if output.p11 NE n_elements(output_swp_i) AND swpn EQ 2 then stanna
      if n_elements(output_swp_i) EQ 0 AND swpn EQ 2 then print,'(mvn_lpw_swp2) No packages where found <---------------'
      ;-----------------------------------------
          
      
      ;-------------------- Get correct clock time ------------------------------     
      ;#############
      ;NOTE: is packet header pointing to first or last time point in sequence? This affects time[i]+indgen(nn_steps)*dt[i].
      ;#############
      dt  = subcycle_length[output.mc_len[output_swp_i]]/nn_steps
      t_s = subcycle_length[output.mc_len[output_swp_i]]*3./128      ;this is how long time each measurement point took
                                                                     ;the time in the header is associated with the last point in the measurement
                                                                     ;therefore is the time corrected by the thength of the subcycle_length
      time_sc   = double(output.SC_CLK1[output_swp_i]) + output.SC_CLK2[output_swp_i]/2l^16+t_epoch  -t_s  
      time_dt   = dblarr(nn_pktnum*nn_steps)    
      for i=0L,nn_pktnum-1 do time_dt[nn_steps*i:nn_steps*(i+1)-1]  =time_sc[i]+dt[i]*indgen(nn_steps)     
      IF keyword_set(spice)  THEN BEGIN                                                     ;if this computer has SPICE installed:
         aa=floor(time_sc-t_epoch)
         bb=floor(((time_sc-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
         mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t,clock_end_t,spice,spice_used,str_xtitle,kernel_version,time  ;correct times using SPICE    
         aa=floor(time_dt-t_epoch)
         bb=floor(((time_dt-t_epoch) MOD 1) *2l^16)                                                                                    ;if this computer has SPICE installed:
         mvn_lpw_anc_clocks_spice, aa, bb,clock_field_str,clock_start_t_dt,clock_end_t_dt,spice,spice_used,str_xtitle,kernel_version,time_dt  ;correct times using SPICE    
      ENDIF ELSE BEGIN
          clock_field_str  = ['Spacecraft Clock ', 's/c time seconds from 1970-01-01/00:00']
          time             = time_sc                                                                                            ;data points in s/c time
          clock_start_t    = [time_sc[0]-t_epoch,          time_sc[0]]                         ;corresponding start times to above string array, s/c time
          clock_end_t      = [time_sc[nn_pktnum-1]-t_epoch,time_sc[nn_pktnum-1]]               ;corresponding end times, s/c time
          spice_used       = 'SPICE not used'
          str_xtitle       = 'Time (s/c)'  
          kernel_version    = 'N/A'
          clock_start_t_dt = [time_dt[0]-t_epoch,          time_dt[0]]                                        
          clock_end_t_dt   = [time_dt[nn_pktnum-1]-t_epoch,time_dt[nn_pktnum-1]]
      ENDELSE           
      ;--------------------------------------------------------------------
 
      
            ;--------------- variable: V   ------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                ;-------------- derive  time/variable ----------------     
                data.x=time_dt                     
                for i=0L,nn_pktnum-1 do begin
  ;                    data.y[nn_steps*i:nn_steps*(i+1)-1]  = output_swp_V[i, *] * const_V_readback 
  ;                    data.dy[nn_steps*i:nn_steps*(i+1)-1] = 2.                 * const_V_readback   ; ERROR assume two bit wrong
                       data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_swp_V[i,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                       data.dy[nn_steps*i:nn_steps*(i+1)-1] =((               10 * const_V_readback)-boom_corr[0])/boom_corr[1]  ; 10 DN
                endfor                      
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2), $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.y), $
                   'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
                   't_epoch' ,                      t_epoch, $  
                   'Time_start'      ,              clock_start_t_dt, $
                   'Time_end'        ,              clock_end_t_dt, $
                   'Time_field'      ,              clock_field_str, $
                   'SPICE_kernel_version',          kernel_version, $
                   'SPICE_kernel_flag'      ,       spice_used, $                     
                   'L0_datafile'     ,              filename_L0 , $ 
                   'cal_vers'        ,              cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,                'Used: ' + strcompress(const_V_readback ,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'cal_datafile'    ,              'NA' , $
                   'cal_source'      ,              'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,              '[sec]', $   
                   'ysubtitle'       ,              '[uncorr Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2),$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars',    1)
                ;------------- store --------------------                               
                   store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2),data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
                ;  remove DC DC signal to see fluctuation, base zero on the last half
                ;---------------------------------------------
                for i=0L,nn_pktnum-1 do begin
                    aa= ((output_swp_V[i,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                  data.y[nn_steps*i:nn_steps*(i+1)-1] = aa - mean(aa[64:127])
                  data.dy[nn_steps*i:nn_steps*(i+1)-1] =((               10 * const_V_readback)-boom_corr[0])/boom_corr[1]  ; 10 DN
                endfor
                limit.ytitle ='mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2)+'_filt'
                limit.yrange =[min(data.y),max(data.y)] 
                ;------------- store --------------------
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2)+'_filt',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
                ;---------------------------------------------
                ;  remove DC DC signal to see fluctuation,remove median baselien
                ;---------------------------------------------
                if nn_pktnum GT 6 then begin
                
                for i=0L+3,nn_pktnum-1-3 do begin
                   
                     aa1= ((output_swp_V[i-3,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                     aa2= ((output_swp_V[i-2,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                     aa3= ((output_swp_V[i-1,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                     aa4= ((output_swp_V[i+0,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                     aa5= ((output_swp_V[i+1,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                     aa6= ((output_swp_V[i+2,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                     aa7= ((output_swp_V[i+3,*] * const_V_readback)-boom_corr[0])/boom_corr[1]                 
                   aaa=fltarr(128)   ;empty array
                   for ii=0,127 do aaa[ii] = median([aa1[ii],aa2[ii],aa3[ii],aa4[ii],aa5[ii],aa6[ii],aa7[ii]])
               
                  aa= ((output_swp_V[i,*] * const_V_readback)-boom_corr[0])/boom_corr[1]
                  data.y[nn_steps*i:nn_steps*(i+1)-1] = aa - aaa
                  data.dy[nn_steps*i:nn_steps*(i+1)-1] =((               10 * const_V_readback)-boom_corr[0])/boom_corr[1]  ; 10 DN
                endfor
                limit.ytitle ='mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2)+'_filt2'
                limit.yrange =[min(data.y),max(data.y)]
                ;------------- store --------------------
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2)+'_filt2',data=data,limit=limit,dlimit=dlimit
                endif
                ;---------------------------------------------

 
 
 
  
             IF tplot_var EQ 'ALL'  and nn_pktnum GT 2 THEN BEGIN   
                ;--------------- variable:  offsets: dynamic ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum ) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum ) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x       = time  
                tmp = where( output_swp_dyn_offset LT -2048 or  output_swp_dyn_offset GT 2048,gg)                                                                                                              
                if gg GT 0 then output_swp_dyn_offset[tmp] = 0
                for i=0L,nn_pktnum-1 do begin
                  data.y[i]  = bias_arr[2048-output_swp_dyn_offset[i],swpn]    ; Volt 
                  data.dy[i] = (bias_arr[(output_swp_dyn_offset[i]-1)>0,1]-bias_arr[(output_swp_dyn_offset[i]+1)<4095,1])*0.5  
                                                                         ; the derived error is the dV/2 of the two next to each other bins              
                 endfor  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_dynoff', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.y), $
                   'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $    
                   'Time_start'      ,              clock_start_t_dt, $
                   'Time_end'        ,              clock_end_t_dt, $
                   'Time_field'      ,              clock_field_str, $
                   'SPICE_kernel_version',          kernel_version, $
                   'SPICE_kernel_flag'      ,       spice_used, $                   
                   'L0_datafile'     ,              filename_L0 , $ 
                   'cal_vers'        ,              cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,              'Used: '+bias_file  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,             'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,             'No calibration file used' , $
                   'cal_source'      ,              'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,              '[sec]', $   
                   'ysubtitle'       ,              '[Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'Dyn_offset',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                 ; 'labels' ,        ['Dyn!Doffset!N'],$  
                 ; 'colors' ,        [0,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                               
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_dynoff',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
               ENDIF
               
 
 
                
            get_data,'mvn_lpw_atr_swp_raw',data=data2,limit=limit2,dlimit=dlimit2  ; to get what sweep potential we are using
            tmp=size(data2)
            if tmp[0] EQ 1 then begin           
                 ;--------------- variable:  I*_pot, sweep potential used for L2 production  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size)  )     ;1-D 
                ;-------------- derive  time/variable ----------------       
                data.x=time_dt                 ;time of the swp packet                                                  
                for i=0L,nn_pktnum-1 do begin
                   aa             = long(nn_steps*i)
                   bb             = long(nn_steps*(i+1))-1
                   tmp            = min(abs(data.x[aa]-data2.x) +1e9*(data.x[aa]-data2.x LT -0.2) ,ui)                      ; find matching time, needs to check that it works at mode switches                                            
             ;  data.y[aa:bb]  = (data2.y[ui,0:nn_steps-1] - const_sign +  output_swp_dyn_offset[i] ) * const_lp_bias_DAC     ;this is the potential of the sweep corrected for the dyn_offset
                   data.y[aa:bb]  = bias_arr[ data2.y[ui,0:nn_steps-1]  +  output_swp_dyn_offset[i] ,swpn]    ;this is the potential of the sweep corrected for the dyn_offset     
                 ;  data.dy[aa:bb] = bias_arr[ 2                         +  2                        ,swpn]    ;assume error from both the table sweep and the measured dynamic offset
                  ;for now assume dy is SQRT(y)
                   data.dy[aa:bb] = SQRT(abs(data.y[aa:bb]))
               endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_pot', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.y), $
                   'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $    
                   'Time_start'      ,              clock_start_t_dt, $
                   'Time_end'        ,              clock_end_t_dt, $
                   'Time_field'      ,              clock_field_str, $
                   'SPICE_kernel_version',          kernel_version, $
                   'SPICE_kernel_flag'      ,       spice_used, $                   
                   'L0_datafile'     ,              filename_L0 , $ 
                   'cal_vers'        ,              cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,              'Used: '+bias_file+' # '+dlimit2.cal_y_const1,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,             'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,             'No calibration file used' , $
                   'cal_source'      ,              'Used PKT: SWP'+strtrim(swpn,2)+ ' ATR sweep table', $     
                   'xsubtitle'       ,              '[sec]', $   
                   'ysubtitle'       ,              '[V]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,         'I'+strtrim(swpn,2)+'_pot sweep for L2',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars',    1)
                ;------------- store -------------------- 
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_pot',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
          endif   
         
    

       IF tplot_var EQ 'ALL' THEN BEGIN   ;< ----  
         ;--------------- variable:  offsets:izero  this is the individual measurements, not used in the L2 production ---------------------------

         data =  create_struct(   $
           'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
           'y',    fltarr(nn_pktnum,2) ,  $     ; most of the time float and 1-D or 2-D
           'dy',   fltarr(nn_pktnum,2) )     ;1-D
         ;-------------- derive  time/variable ----------------
         data.x = time
         ;--------------
            get_data,'mvn_lpw_pas_V'+strtrim(vnum,2),data=data2,limit=limit2,dlimit=dlimit2   ;to correct for the potential
            tmp=size(data2)
            if tmp[0] EQ 1 then begin           ;<---------- double check that PAS information exists   
                pas_v = ' Potential from PAS subcycle used for calibration'
                index_pas_v=nn_pa*(lindgen(n_elements(data2.x)/nn_pa)) +(nn_pa-1) ; find the last voltage point in each packet               
                pas_time=data2.x(index_pas_v)
                pas_volt=data2.y(index_pas_v)                  
                for i=0L,nn_pktnum-1 do begin                                        
                      data.y[i,0] = output_I_ZERO[i]*16                             ; this is the i_zero uncorrected from each packet,converted to the same resolution as all the other currents                               
                      data.dy[i,0]  = 1.*16
                      tmp2           = min( abs(data.x(i) -   pas_time),nq )   ;find the last measurement in the PAS paket which was taken at the same time as the i_zero measurement   
                      if  pas_time[nq] GT data.x(i) then nq=nq-1       ;make sure that the order of the packets are correct
                      nq            = (nq > 1) <(n_elements(data2.x)-1)                                                      
                       if tmp2 LT 300 then begin   ; smaller than the longest master cycle
                             data.y[i,1]   =  mvn_lpw_cal_swp_izero(pas_volt[nq],output_I_ZERO[i]*16,0,swpn)  
                             data.dy[i,1]  =  mvn_lpw_cal_swp_izero(pas_volt[nq],1.*16,0,swpn)  
                      endif else begin
                             data.y[i,1]   =  0.0  
                             data.dy[i,1]  =  0.0  
                      endelse
                 endfor
               ENDIF ELSE BEGIN
                 get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_V'+strtrim(vnum,2),data=data2,limit=limit2,dlimit=dlimit2   ;to correct for the potential
                 pas_v = ' Potential for calibration from boom 2 this subcycle  ZEROED OUT'
                 index_pas_v=nn_pa*(lindgen(n_elements(data2.x)/nn_pa)) +(nn_pa-1) ; find the last voltage point in each packet
                 pas_time=data2.x(index_pas_v)
                 pas_volt=data2.y(index_pas_v) *0.0
               for i=0L,nn_pktnum-1 do begin                                        
                      data.y[i,0] = output_I_ZERO[i]*16                             ; this is the i_zero uncorrected from each packet,converted to the same resolution as all the other currents                               
                      data.dy[i,0]  = 1.*16
                      tmp2           = min( abs(data.x(i) -   pas_time),nq )   ;find the last measurement in the PAS paket which was taken at the same time as the i_zero measurement   
                      if  pas_time[nq] GT data.x(i) then nq=nq-1       ;make sure that the order of the packets are correct
                      nq            = (nq > 1) <(n_elements(data2.x)-1)                                                      
                       if tmp2 LT 300 then begin   ; smaller than the longest master cycle
                             data.y[i,1]   =  mvn_lpw_cal_swp_izero(pas_volt[nq],output_I_ZERO[i]*16,0,swpn)  
                             data.dy[i,1]  =  mvn_lpw_cal_swp_izero(pas_volt[nq],1.*16,0,swpn)  
                      endif else begin
                             data.y[i,1]   =  0.0  
                             data.dy[i,1]  =  0.0  
                      endelse
                 endfor
               ENDELSE
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_izero', $
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
                   'Generation_date',               today_date+' # '+t_routine, $
                   'Rules of use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $    
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.y), $
                   'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $    
                   'Time_start'      ,              clock_start_t_dt, $
                   'Time_end'        ,              clock_end_t_dt, $
                   'Time_field'      ,              clock_field_str, $
                   'SPICE_kernel_version',          kernel_version, $
                   'SPICE_kernel_flag'      ,       spice_used, $                   
                   'L0_datafile'     ,              filename_L0 , $ 
                   'cal_vers'        ,              cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,              'Used: '+' # '+dlimit2.cal_y_const1 +' # and cal-izero '+ pas_v,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,             'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,             'No calibration file used' , $
                   'cal_source'      ,              'Used PKT: SWP'+strtrim(swpn,2)+' and from PAS toget the voltage associated with the measured izero', $     
                   'xsubtitle'       ,              '[sec]', $   
                   'ysubtitle'       ,              '[DN]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'I_zero  DN & DN corr',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        ['i!Dzero UnCorr!N','i!Dzero!NCorr!DV!N'],$  
                  'colors' ,        [0,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                               
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_izero',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
             ENDIF
          
                
                            
                
                       
                get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_izero',data=data1,limit=limit1,dlimit=dlimit1  
                get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_dynoff',data=data2,limit=limit2,dlimit=dlimit2  
                tmp1=size(data1)
                tmp2=size(data2)
                if tmp1[0]*tmp2[0]  EQ 1 then begin           ;<---------- double check that PAS information exists               
               ;--------------- variable:  offsets (izero and dyn_offset together) ---------------------------
               ;----------------- Keep this because old routines use this variable ------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum ,2) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_pktnum ,2) )     ;1-D 
                ;-------------- derive  time/variable ----------------                          
                data.x       = data1.x
                data.y[*,0]  = data1.y[*,0]  ;this is the uncorrected 
                data.y[*,1]  = data2.y 
                data.dy[*,0] = data1.dy[*,0]  
                data.dy[*,1] = data2.dy  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_offset', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.y), $
                   'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $    
                   'Time_start'      ,              clock_start_t_dt, $
                   'Time_end'        ,              clock_end_t_dt, $
                   'Time_field'      ,              clock_field_str, $
                   'SPICE_kernel_version',          kernel_version, $
                   'SPICE_kernel_flag'      ,       spice_used, $                   
                   'L0_datafile'     ,              filename_L0 , $ 
                   'cal_vers'        ,              cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,              'Used: '+dlimit1.cal_y_const1+' # '+dlimit2.cal_y_const1  ,$ 
                   ;'cal_y_const2'    ,             'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,             'No calibration file used' , $
                   'cal_source'      ,              'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,              '[sec]', $   
                   'ysubtitle'       ,              '[Raw/Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'I_zero and Dyn_offset',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        ['i!Dzero UnCorr!N','Dyn!Doffset!N'],$  
                  'colors' ,        [0,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                               
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_offset',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
              ENDIF
          
    
             get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_pot',data=data1,limit=limit1,dlimit=dlimit1;this isneeded to correct the measured current                  
             get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_izero'                   ,data=data2,dlimit=dlimit2               ; this is just to get one offest value
             tmp1=size(data1)
             tmp2=size(data2)
             get_data,'mvn_lpw_pas_V'+strtrim(vnum,2),data=data3,limit=limit3,dlimit=dlimit3   ;to correct for the potential
             tmp3=size(data3)

             if tmp1[0]*tmp2[0] EQ 1 then begin                                          ;<---------- double check izero information exists       
                ;--------------- variable:  current from the sweep I_basic , uncorrectedc and corrected for i_zero   ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size,4) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size,4)  )     ;1-D 
                ;-------------- derive  time/variable ----------------       
                ;---------------- Use one value for all sweeps in one file, used multiple places below ---------
                  
                  ;i_zero=[-353277., -353270.,-353263., -353281., -353280., -353287., -353281.,-353277., -353282.]
                  I_ZERO =   -353278 +fltarr(nn_size)  ;set this to default 2.^18=262144
                  if tmp3[0] EQ 1 then begin              ;    PAS data exist to correct of voltage when i_zero was measured
                    
                     if total(data2.y[*,1] EQ 0) LT 0.4*n_elements(data2.y[*,1]) then begin
                       ;use LADFIT insted 
                        x      = data2.x[1:*]-data2.x[0]           ; ignore first point in the file
                        y      = data2.y[1:*,1]                    ;<---- this is i_zero corrected for potential.....
                        result = LADFIT(x,y)     
                        value  = x*result[1]+result[0]             
                        I_ZERO = [value[0],value]                 ; this is alows a linear fit over a file, later we might do this as function of orbit...
                        ;this needs to be verified if it works over the file or if we need to look over an orbit 
                     endif  else begin; if there are too many zeros then do not use izero
                     ; defalut value
                     endelse
                  endif else begin                            ;    i_zero is the only information that exsits, one number for a full file          
;                      tmp2=sort(output_I_ZERO)
;                      notmp2=n_elements(tmp2)
;                      I_ZERO =output_I_ZERO*0.0+ mean(output_I_ZERO[tmp2[0+0.1*notmp2:notmp2-1-0.1*notmp2]])  ; remove the 10% etreme points
;this will never happen....
               
                 endelse
                
                
         ;       stanna 
                 ;--------------------------------------------------------------------
                 data.x=time_dt     
                 i_error=2.0*indgen(nn_steps)                                
                 for i=0L,nn_pktnum-1 do begin                                                               ; work with one sweep at the time
                   aa=long(nn_steps*i)
                   bb=long(nn_steps*(i+1))-1
                   data.y[aa:bb,2]  = output_swp_ii[i,*]                                                      ;this just the DN
                   data.y[aa:bb,3]  = mvn_lpw_cal_swp_izero(data1.y[aa:bb],data.y[aa:bb,2],I_ZERO[i],swpn)                    ;this is current corrected in DN
                   data.y[aa:bb,0]  = data.y[aa:bb,2] * const_I_readback                                      ;this is DN * constant       
                   data.y[aa:bb,1]  = data.y[aa:bb,3] * const_I_readback                                      ;this is the current corrected using only the measures i_zero
                   data.dy[aa:bb,2] = i_error
                   data.dy[aa:bb,3] = mvn_lpw_cal_swp_izero(data1.y[aa:bb],data.dy[aa:bb,2],I_ZERO[i],swpn) 
                   data.dy[aa:bb,0] = data.dy[aa:bb,2] * const_I_readback
                   data.dy[aa:bb,1] =  10e-9   ; data.dy[aa:bb,3] * const_I_readback   ; for now use 10 nA as uncertenty
                 endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_basic', $
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
                   'Generation_date',               today_date+' # '+t_routine, $
                   'Rules of use',                  cdf_istp[11], $
                   'Acknowledgement',               cdf_istp[13],   $    
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.y), $
                   'SCALEMAX',                      max(data.y), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $    
                   'Time_start'      ,              clock_start_t_dt, $
                   'Time_end'        ,              clock_end_t_dt, $
                   'Time_field'      ,              clock_field_str, $
                   'SPICE_kernel_version',          kernel_version, $
                   'SPICE_kernel_flag'      ,       spice_used, $                   
                   'L0_datafile'     ,              filename_L0 , $ 
                   'cal_vers'        ,              cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,              'Used: ' +strcompress(const_I_readback,/remove_all)+' # '+dlimit1.cal_y_const1+' # '+dlimit2.cal_y_const1 +' # and cal-izero',$ 
                   'cal_source'      ,              'Used PKT: SWP'+strtrim(swpn,2) +'ATR for sweep and PAS for izero', $     
                   'xsubtitle'       ,              '[sec]', $   
                   'ysubtitle'       ,              '[A]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,         'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),$   
                  'yrange' ,        [min(data.y[*,0:1]),max(data.y[*,0:1])] ,$   
                  'ystyle'  ,       1.                       ,$  
                  'labels' ,        ['i!DNoCorr!N','i corr!Dizero!N','i!DUnCorr!Dizero!N [DN]','i!Dcorr!Dizero!N [DN]'],$  
                  'colors' ,        [0,4,2,6]                      ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store -------------------- 
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_basic',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
             endif  
   
                     
             get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_basic',data=data1,limit=limit1,dlimit=dlimit1    
             tmp1=size(data1)
             if tmp1[0] EQ 1 then begin           ;<---------- double check that atr information exists   
                 ;------------------------- I_zero correction and epsilon -------------------------------------
                 ;--------------- variable:  I; this is the variable that is used for L2 production  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size)  )     ;1-D 
                ;-------------- derive  time/variable ----------------     
                get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_basic',data=data1,limit=limit1,dlimit=dlimit1                            
                      data.x  = data1.x
                      data.y  = data1.y[*,1]                ; not working yet correction for epsilon based on sweep-potential       
                      data.dy =  data1.dy[*,1]              
   ;######## warning ##########
   print, 'WARNING laila is testting something on the sweep'
   
   if strtrim(swpn,2) EQ '2' then  data.y  = data1.y[*,1]-0.9e-8  else data.y  = data1.y[*,1]
   
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=dlimit1          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,         'I'+strtrim(swpn,2)+' for L2',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                          ,$   
                  'labflag' ,       1                        ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store -------------------- 
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
             ENDIF
      
      
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_basic',data=data2,limit=limit2,dlimit=dlimit2
            tmp=size(data2)
            if tmp[0] EQ 1 then begin           ;<---------- double check that PAS information exists        
                  ;--------------- variable:  IV-bin-spectra ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------                                                                                                                                                                             
                   ss=LINDGEN(nn_pktnum)*nn_steps                  ; start of each sweep                  
                  data.x = data2.x(ss) 
                  rt=0  ; which variable to use from  'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_basic'  
                  for i=0L,nn_pktnum-1 do  begin
                      data.y[i,*]=data2.y[ss[i]:ss[i]+nn_steps-1,rt]           ; this will be the fully corrected current
                      data.v[i,*]=indgen(nn_steps)                      ; the potential-sweep based on the atr, do not use output information!!!
                      data.dy[i,*]=data2.dy[ss[i]:ss[i]+nn_steps-1,rt]         ; keep the error
                      data.dv[i,*]=0                               
                  endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_IV_bin', $
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
                   'cal_y_const1'    ,     'Used:'+strcompress(const_I_readback,/remove_all)+' # '+dlimit2.cal_y_const1  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[Bin number]', $        
                   'cal_v_const1'    ,     'Used: N/A' , $ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[A]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'Bin'                 ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$
                  'ztitle' ,        limit2.labels(rt)     ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_IV_bin',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
         ENDIF
  
  
 
      
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),       data=data1,dlimit=dlimit1
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_pot',data=data2,dlimit=dlimit2 ; this is created with the same time array as data2
            tmp1=size(data1)            
            tmp2=size(data2)            
            if tmp1[0]*tmp2[0] EQ 1 then begin           ;<---------- double check that atr information exists              
              ;--------------- variable:  IV-spectra ---------------------------
                            data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------     
                  ss=LINDGEN(nn_pktnum)*nn_steps                  ; start of each sweep                  
                  data.x = data1.x(ss)                            ; this should be the dame as time! but just to make sure use data2 and select one time per sweep  
                  If total(data1.x-data2.x) NE 0 then stanna  ; this indicate something wrong in the processing, this should not occur                 
                  for i=0L,nn_pktnum-1 do  begin
                      sort_order= ss[i]+SORT(data2.y[ss[i]:ss[i]+nn_steps-1]) 
                      data.y[i,*]=data1.y(sort_order)           ;        ; this will be the fully corrected current
                      data.v[i,*]=data2.y(sort_order)           ;this is the potential corrected for dynamic offset  this contains infor from 'mvn_lpw_atr_swp'
                      data.dy[i,*]=data1.dy(sort_order)         ; keep the error
                      data.dv[i,*]=0.1                          ; fix error keep the error                             
                  endfor                        
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_IV', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.v), $
                   'SCALEMAX',                      max(data.v), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $ 
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                      
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Used: '+strcompress(const_I_readback,/remove_all)+' # '+'i_zero smoothed' +' # ' +$
                                            dlimit1.cal_y_const1 + ' # '+dlimit2.cal_y_const1  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2)+' and ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[V]', $        
                   'cal_v_const1'    ,     dlimit2.cal_y_const1 , $  
                  ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[A]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'Sweep from ATR-file'     ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$
                  'ztitle' ,        'Current '   ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------    
                 store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_IV',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------          
                 ENDIF 
                 
                 
     
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),       data=data1,dlimit=dlimit1
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_pot',data=data2,dlimit=dlimit2 ; this is created with the same time array as data2
            tmp1=size(data1)            
            tmp2=size(data2)            
            if tmp1[0]*tmp2[0] EQ 1 then begin           ;<---------- double check that atr information exists              
              ;--------------- variable:  IV-spectra ---------------------------
                            data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------     
                  ss=LINDGEN(nn_pktnum)*nn_steps                  ; start of each sweep                  
                  data.x = data1.x[ss]                            ; this should be the dame as time! but just to make sure use data2 and select one time per sweep  
                  for i=0L,nn_pktnum-1 do  begin
                      sort_order= ss[i]+SORT(data2.y[ss[i]:ss[i]+nn_steps-1]) 
                      data.y[i,*]=alog10(abs(data1.y[sort_order]))          ; this will be the fully corrected current
                      data.v[i,*]=data2.y[sort_order]           ;this is the potential corrected for dynamic offset  this contains infor from 'mvn_lpw_atr_swp'
                      data.dy[i,*]=data1.dy[sort_order]         ; keep the error
                      data.dv[i,*]=data2.dy[sort_order]         ; keep the error                             
                  endfor                        
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_IV', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.v), $
                   'SCALEMAX',                      max(data.v), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $ 
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                      
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Used: '+strcompress(const_I_readback,/remove_all)+' # '+'i_zero smoothed' +' # ' +$
                                            dlimit1.cal_y_const1 + ' # '+dlimit2.cal_y_const1  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2)+' and ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[V]', $        
                   'cal_v_const1'    ,     dlimit2.cal_y_const1 , $  
                  ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[nA]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'Sweep from ATR-file'     ,$   
                  'yrange' ,        [min(data.v),max(data.v)] ,$   
                  'ystyle'  ,       1.                       ,$
                  'ztitle' ,        'log10(|I|)(corrected)'   ,$   
                  'zrange' ,        [min(data.y),max(data.y)],$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------    
                 store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_IV_log',data=data,limit=limit,dlimit=dlimit
     
                 options,'*log',zrange=[-9,-4]
                 options,'*log',yrange=[-10,10]
                ;---------------------------------------------          
              ENDIF 
   
      
      
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2),       data=data1,dlimit=dlimit1
            get_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_I'+strtrim(swpn,2)+'_pot',data=data2,dlimit=dlimit2 ; this is created with the same time array as data2
            tmp1=size(data1)            
            tmp2=size(data2)            
            if tmp1[0]*tmp2[0] EQ 1 then begin           ;<---------- double check that atr information exists              
              ;--------------- variable:  IV-spectra ---------------------------
                            data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps) ,  $     ; most of the time float and 1-D or 2-D
                                         'v',    fltarr(nn_pktnum,nn_steps) ,  $     ; same size as y
                                         'dy',   fltarr(nn_pktnum,nn_steps) ,  $    ; same size as y
                                         'dv',   fltarr(nn_pktnum,nn_steps) )     ;1-D 
                ;-------------- derive  time/variable ----------------     
                  ss=LINDGEN(nn_pktnum)*nn_steps                  ; start of each sweep                  
                  data.x = data1.x[ss]                            ; this should be the dame as time! but just to make sure use data2 and select one time per sweep                                    
                  tmp=fltarr(nn_steps)
                  iu=indgen(nn_steps-1) 
                 ; vv=[0,1,2,3,4]
                  edge=3   ; remove end points in the sweep
                  for i=0L,nn_pktnum-1 do  begin
                    ;  tmp_vv      = data2.y[ss[i]:ss[i]+nn_steps-1]
                    ;  tmp_vv[           vv] = tmp_vv[5]           -(5-vv)*0.01 
                    ;  tmp_vv[nn_steps-1-vv] = tmp_vv[nn_steps-1-5]+vv*0.01 
                     ; sort_order=  i*nn_steps+SORT(tmp_vv)    
                     ; tmp[*]=data1.y[ss[i]:ss[i]+nn_steps-1]
                     ; tmp[iu]= tmp_vv[iu+1]-tmp_vv[iu] 
                      
                      
                       tmp_vv      = data2.y[ss[i]+edge:ss[i]+nn_steps-1-2.*edge]
                       sort_order   =  ss[i]+edge+SORT(tmp_vv) 
                      
   ;                print,i,' # ',ss[i],ss[i]+nn_steps-1,tmp[10],tmp[11],tmp[12],tmp[13],sort_order[0],sort_order[1],sort_order[2],sort_order[3]   
                      data.y[i ,edge:nn_steps-1-2.*edge]=data1.y[sort_order]         ; current diff
                      data.v[i ,edge:nn_steps-1-2.*edge]=data2.y[sort_order]           ;this is the potential corrected for dynamic offset  this contains infor from 'mvn_lpw_atr_swp'
                      data.v[i ,               0:edge-1]    =data.v[edge] +200
                      data.v[i ,nn_steps-2.*edge:nn_steps-1]=data.v[nn_steps-2.*edge-1] -200
                      data.dy[i,edge:nn_steps-1-2.*edge]=data1.dy[sort_order]         ; keep the error
                      data.dv[i,edge:nn_steps-1-2.*edge]=data2.dy[sort_order]         ; keep the error                             
                  endfor                        
               
                   U      = fltarr(nn_steps)
                   I      = fltarr(nn_steps)
                   y_norm = fltarr(nn_pktnum,nn_steps)
                 for ii=0L,nn_pktnum-1 do begin
                      U[*] = data.v[ii,*]  ;data2.y(ss[ii]:ss[ii]+nn_steps-1) ; transpose(data2.y(ss[i]:ss[i]+nn_steps-1))
                      I[*] = data.y[ii,*]  ;data1.y(ss[ii]:ss[ii]+nn_steps-1) ; transpose(data1.y(ss[i]:ss[i]+nn_steps-1))
                      U_sort = sort(U)
                      U      = U[U_sort]
                      I      = I[U_sort]
                    if U[1] eq U[2] then begin    ;????
                      pp = where(ts_diff(U,1) eq 0)
                   
                  
                      for jj=0,n_elements(pp)-2 do begin
                         I[pp[jj]]   = mean(I[[pp[jj],pp[jj]+1]])
                         I[pp[jj]+1] = !values.F_nan
                         U[pp[jj]+1] = !values.F_nan
                      endfor
                      U_sort = sort(U)
                      U      = U[U_sort]
                      I      = I[U_sort]
                   endif       
                  data.v[ii,*] = U
                 ; data.y[ii,*] = deriv(U,I)
                  data.y[ii,*] = deriv(U,I)/max(deriv(U,I),/nan)
                  data.v[ii,               0:edge-1]    =0
                  data.v[ii,nn_steps-2.*edge:nn_steps-1]=0
                  data.dy[ii,*] = data.y[ii,*]*0.2
                  data.dv[ii,*] = data.v[ii,*]*0.2
                endfor
                 
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_IV', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      min(data.v), $
                   'SCALEMAX',                      max(data.v), $        ;..end of required for cdf production.
                   't_epoch'         ,              t_epoch, $ 
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                      
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Used: '+strcompress(const_I_readback,/remove_all)+' # '+'i_zero smoothed' +' # ' +$
                                            dlimit1.cal_y_const1 + ' # '+dlimit2.cal_y_const1  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2)+' and ATR', $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[V]', $        
                   'cal_v_const1'    ,     dlimit2.cal_y_const1 , $  
                  ;'cal_v_const2'    ,     'Used :'   ; Fixed convert information from measured binary values to physical units, variables from space testing
                   'zsubtitle'       ,     '[nA]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'Sweep from ATR-file'     ,$   
                  'yrange' ,        [-10,10] ,$   
                  'ystyle'  ,       1.                       ,$
                  'ztitle' ,        'dI (corrected)'   ,$   
                  'zrange' ,        [0.,1.],$  
                  'spec'   ,        1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------    
                 store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_dIV',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------          
              ENDIF 
   
      
      
      IF tplot_var EQ 'ALL' THEN BEGIN
            ;------------- variable:  swp_mc_len ---------------------------    
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )    ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                     
                 data.y = subcycle_length[output.mc_len[output_swp_i]]*4.   ;ORB_MD 
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_mc_len', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      0, $
                   'SCALEMAX',                      300, $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $  
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Used: N/A'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'swp'+strtrim(swpn,2)+'_mc_len',$   
                  'yrange' ,        [0,300]                 ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------    
                  store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_mc_len',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
       
     
                ;------------- variable:  smp_avg ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )    ;1-D 
                ;-------------- derive  time/variable ----------------  
                data.x = time                                                  
                data.y = sample_aver[output.smp_avg[output_swp_i]]       ; from ICD table  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_smp_avg', $
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
                   'MONOTON',                       'INCREASE', $
                   'SCALEMIN',                      0, $
                   'SCALEMAX',                      2050, $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $   
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Used: N/A'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'swp'+strtrim(swpn,2)+'_smp_avg',$   
                  'yrange' ,        [0,2050]                 ,$   
                  'ystyle'  ,       1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                  store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_smp_avg',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
   
      
                ;------------- variable:  swp_mode ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ----------------   
                  data.x = time                                                     
                  data.y = output.orb_md[output_swp_i]  ;ORB_MD   
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_mode', $
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
                   'MONOTON',                      'INCREASE', $
                   'SCALEMIN',                     -1, $
                   'SCALEMAX',                     18, $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $  
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                    
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_y_const1'    ,     'Used: N/A'  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: SWP'+strtrim(swpn,2), $     
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'swp'+strtrim(swpn,2)+'_mode',$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store -------------------- 
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
    
    
    
    
              ;------------- variable:  SWP swpn L1-raw  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $                                     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum, nn_steps*3+3) )                           ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 for i=0L,nn_pktnum-1 do begin
                   data.x[i]                          = time_sc[i]                                          ;sc time only      
                   data.y[i,nn_steps*0:nn_steps*1-1]  = output_swp_V[i, *] 
                   data.y[i,nn_steps*1:nn_steps*2-1]  = (output_swp_ii[i,*]-output_I_ZERO[i]*16)            ;with zero correction
                   data.y[i,nn_steps*2:nn_steps*3-1]  = (output_swp_ii[i,*])                                ;without zero correction                                           
                   data.y[i,nn_steps*3+0]             = subcycle_length[output.mc_len[output_swp_i[i]]]*4.   ;ORB_MD                   
                   data.y[i,nn_steps*3+1]             = sample_aver[output.smp_avg[output_swp_i[i]]]         ; from ICD table                                
                   data.y[i,nn_steps*3+2]             = output.orb_md[output_swp_i[i]]                       ;ORB_MD
                 endfor             
                str1=['V sweep no'+strarr(nn_steps),'Current corrected with I zero'+strarr(nn_steps), $
                      'Current only'+strarr(nn_steps), $
                      'Number of averaged samples','Subcycle  Length','Orbit mode']                                  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $ 
                   'Product_name',                  'swp'+strtrim(swpn,2)+'_l0b', $
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
                   'Time_start'      ,            [time_sc[0]-t_epoch,          time_sc[0]] , $
                   'Time_end'        ,            [time_sc[nn_pktnum-1]-t_epoch,time_sc[nn_pktnum-1]], $
                   'Time_field'      ,            'SC packet time given, t_epoch is the 0-time of sc clock', $
                   'SPICE_kernel_version',        'NaN', $
                   'SPICE_kernel_flag'      ,     'SPICE not used', $    
                   'L0_datafile'     ,            filename_L0 , $ 
                   'cal_source'      ,            'Information from PKT: SWP'+strtrim(swpn,2)+'-raw', $            
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[Raw Packet Information]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $                  
                  'xtitle' ,                      'Time (s/c)'             ,$   
                  'ytitle' ,                      'Misc'                 ,$  
                  'labels' ,                      str1                    ,$   
                  'yrange' ,                      [min(data.y),max(data.y)] )
                ;------------- store --------------------                        
                store_data,'mvn_lpw_swp'+strtrim(swpn,2)+'_l0b',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
    
      ENDIF
ENDIF


options, 'mvn_lpw_*IV*', no_interp=1

IF swpn EQ 1 AND output.p10 LE 0 THEN print, "mvn_lpw_pkt_swp(1) skipped as no packets found."
IF swpn EQ 2 AND output.p11 LE 0 THEN print, "mvn_lpw_pkt_swp(2) skipped as no packets found."

end
;*******************************************************************









