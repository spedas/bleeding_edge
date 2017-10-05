;;+
;PROCEDURE:   mvn_lpw_pkt_E12_DC
;PURPOSE:
;  Takes the decumuted data (L0) from either the ACT or PAS packet
;  and turn it the data into L1 and L2 data tplot structures
;  This packet contains the information of V1, V2 and E12_LF
;  
;
;USAGE:
;  mvn_lpw_pkt_E12_DC,output,lpw_const,cdf_istp_lpw,tplot_var,packet
;
;INPUTS:
;       output:         L0 data 
;       lpw_const:      information of lpw calibration etc
;       packet:         'act' => runs routine for the ACT packet
;                       'pas' => runs routine for the PAS packet 
;
;KEYWORDS:
;       tplot_var = 'all' or 'sci'  => 'sci' produces tplot variables with physical units and is the default
;                                   => 'all' produces all tplot variables
;  spice = '/directory/of/spice/=> 1 if SPICE is installed. SPICE is then used to get correct clock times.
;                 => 0 is SPICE is not installed. S/C time is used.                                  
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_pkt_E12_DC.pro
;VERSION:   2.0  <------------------------------- update 'pkt_ver' variable
; Changes:  Time in the header is now associated with the last measurement point
;LAST MODIFICATION:   2013, July 11th, Chris Fowler - added IF statement to check for data.
;                     2013, July 12th, Chris Fowler - added keyword tplot_var
;                     2013, July 15th, Chris Fowler - combined mvn_lpw_pck_act.pro and mvn_lpw_pas.pro into this one file.
;                     2014, March 20, Chris Fowler - added SPICE time
;11/11/13 L. Andersson clean the routine up and change limit/dlimit to fit the CDF labels introduced dy and dv, might need to be disable...
;04/15/14 L. Andersson included L1
;04/22/14 L. Andersson major changes to meet the CDF requirement and allow time to come from spice, added verson number in dlimit, changed version number
;140718 clean up for check out L. Andersson
;2014-10-03: CF: modified dlimit fields for ISTP compliance.
;-

pro mvn_lpw_pkt_E12_DC, output,lpw_const,packet,tplot_var=tplot_var,spice=spice

IF (output.p12 GT 0 AND packet EQ 'act') OR $
   (output.p13 GT 0 AND packet EQ 'pas') THEN BEGIN  ;check for data


If keyword_set(tplot_var) THEN tplot_var = tplot_var ELSE tplot_var = 'SCI'  ;Default setting is science tplot variables only.


      ;--------------------- Constants ------------------------------------          
               t_routine            = SYSTIME(0) 
               t_epoch              = lpw_const.t_epoch
               today_date           = lpw_const.today_date
               cal_ver              = lpw_const.version_calib_routine 
               pkt_ver              = 'pkt_e12_ver  2.0' 
               cdf_istp             = lpw_const.cdf_istp_lpw                                      
               filename_L0          = output.filename
      ;----------------------------------------------------------------         
               inst_phys            = lpw_const.inst_phys
               sensor_distance      = lpw_const.sensor_distance
               boom_shorting_factor = lpw_const.boom_shortening              
               subcycle_length      = lpw_const.sc_lngth
              nn_steps              = long(lpw_const.nn_pa)                                   ;number of samples in one subcycle
              const_V2_readback     = lpw_const.V2_readback
              const_V1_readback     = lpw_const.V1_readback
              const_E12_LF          = lpw_const.E12_lf
              boom1_corr            = lpw_const.boom1_corr
              boom2_corr            = lpw_const.boom2_corr
              e12_corr              = lpw_const.e12_corr
      ;--------------------------------------------------------------------
      IF packet EQ 'act' THEN BEGIN
            output_state_i      = output.act_i
            nn_pktnum           = long(output.p12)
            output_state_V1     = output.act_V1
            output_state_V2     = output.act_V2
            output_state_E12_LF = output.act_E12_LF                   
      ENDIF
      
      IF packet EQ 'pas' THEN BEGIN
            output_state_i      = output.pas_i
            nn_pktnum           = long(output.p13)
            output_state_V1     = output.pas_V1
            output_state_V2     = output.pas_V2
            output_state_E12_LF = output.pas_E12_LF
      ENDIF
        ;--------------------------------------------------------------------    
      nn_pktnum       = nn_pktnum                                                    ; number of data packages 
      nn_size         = nn_pktnum*nn_steps                                           ; number of data points
      dt              = subcycle_length(output.mc_len[output_state_i])/nn_steps
      t_s             = subcycle_length(output.mc_len[output_state_i])*3./64         ;this is how long time each measurement point took
                                                                                    ;the time in the header is associated with the last point in the measurement
                                                                                    ;therefore is the time corrected by the thength of the subcycle_length
      ;--------------------------------------------------------------------
      
      ;------------- Checks ---------------------
      if nn_pktnum NE n_elements(output_state_i) then stop
      ;if output.p12 NE n_elements(output_state_i) then stop
      if n_elements(output_state_i) EQ 0 then print,'(mvn_lpw_act) No packages where found <---------------'
      ;-----------------------------------------
 
  
   
        ;the way we do the clock (fix sc_dt and then spice) gives us a unsertainty of 1e-6/16/64?? SEC in time TBR
 
  
      ;-------------------- Get correct clock time ------------------------------
      dt              =subcycle_length(output.mc_len[output_state_i])/nn_steps
      t_s             =subcycle_length(output.mc_len[output_state_i])*3./64         ;this is how long time each measurement point took
                                                                     ;the time in the header is associated with the last point in the measurement
                                                                     ;therefore is the time corrected by the thength of the subcycle_length
    
    
      ;-------------------- Get correct clock time ------------------------------
     
      time_sc         = double(output.SC_CLK1[output_state_i]) + output.SC_CLK2[output_state_i]/2l^16+t_epoch -t_s 
      time_dt         = dblarr(nn_pktnum*nn_steps)                                                                                  ;will hold times for subcycles within each packet            
      for i=0L,nn_pktnum-1 do time_dt[nn_steps*i:nn_steps*(i+1)-1]  =time_sc[i]+dt[i]*indgen(nn_steps)     
      IF keyword_set(spice)  THEN BEGIN                                                                                                ;if this computer has SPICE installed:
         aa = output.SC_CLK1[output_state_i]
         bb = output.SC_CLK2[output_state_i]
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
 
 
   
      ;----------  variable:   V1 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size))     ;1-D 
                dataA =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps),  $     ; double 1-D arr
                                         'v',    fltarr(nn_pktnum,nn_steps)) 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time_dt
                 dataA.x = time 
                 xx = indgen(nn_steps)
                 for i=0L,nn_pktnum-1 do begin
                         ;data.x[nn_steps*i:nn_steps*(i+1)-1] = time[i] + dindgen(nn_steps) * dt[i]  
                        ; data.y[nn_steps*i:nn_steps*(i+1)-1] = output_state_V1[i,*] * const_V1_readback
                         data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_state_V1[i,*] * const_V1_readback)-boom1_corr(0))/boom1_corr(1)
                         data.dy[nn_steps*i:nn_steps*(i+1)-1] =((                  10 * const_V1_readback)-boom1_corr(0))/boom1_corr(1)  ; 10 DN
                         dataA.y[i,*] =                        ((output_state_V1[i,*] * const_V1_readback)-boom1_corr(0))/boom1_corr(1)
                         dataA.y[i,*] = dataA.y[i,*]  - mean(dataA.y[i,*])
                         dataA.v[i,*] = xx
                 endfor        
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT V1 data, mode: '+strtrim(packet,2), $
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
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
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
                   'cal_y_const1'    ,     'Uses: '+strcompress(const_V1_readback,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                  ; 'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $     
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[uncorr Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$    
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_V1',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$      
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'_V1',data=data,limit=limit,dlimit=dlimit
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'2_V1',data=dataA,limit=limit,dlimit=dlimit
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V1',spec=1
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V1',  no_interp=1
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V1', yrange=[0,64]
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V1', zrange=[-.2,0.2]
                ;--------------------------------------------------
 
      
                ;----------  variable: V2 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size) )     ;1-D 
                dataA =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps),  $     ; double 1-D arr
                                         'v',    fltarr(nn_pktnum,nn_steps)) 
                ;-------------- derive  time/variable ----------------                          
                 data.x = time_dt
                 dataA.x = time
                 xx = indgen(nn_steps)
                 for i=0L,nn_pktnum-1 do begin                                                        
                      ;data.x[nn_steps*i:nn_steps*(i+1)-1] = time[i] + dindgen(nn_steps)*dt[i]  
                      ;data.y[nn_steps*i:nn_steps*(i+1)-1] = output_state_V2[i,*]*const_V2_readback
                      data.y[nn_steps*i:nn_steps*(i+1)-1] =  ((output_state_V2[i,*] * const_V2_readback)-boom2_corr(0))/boom2_corr(1)
                      data.dy[nn_steps*i:nn_steps*(i+1)-1] = ((                  10 * const_V2_readback)-boom2_corr(0))/boom2_corr(1) ;10 DN
                      dataA.y[i,*] =                         ((output_state_V2[i,*] * const_V2_readback)-boom2_corr(0))/boom2_corr(1)
                      dataA.y[i,*] = dataA.y[i,*]  - mean(dataA.y[i,*])
                      dataA.v[i,*] = xx                     
                 endfor
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT V2 data, mode: '+strtrim(packet,2), $
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
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
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
                   'cal_y_const1'    ,     'Uses: '+strcompress(const_V2_readback ,/remove_all)  ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                   ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                   ;'cal_datafile'    ,     'No calibration file used' , $
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]', $   
                   'ysubtitle'       ,     '[uncorr Volt]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_V2',$   
                  'yrange' ,        [min(data.y),max(data.y)] ,$   
                  'ystyle'  ,       1.                       ,$       
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                  'noerrorbars', 1)
                ;------------- store --------------------                              
                store_data,'mvn_lpw_'+strtrim(packet,2)+'_V2',data=data,limit=limit,dlimit=dlimit
                store_data,'mvn_lpw_'+strtrim(packet,2)+'2_V2',data=dataA,limit=limit,dlimit=dlimit
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V2',spec=1
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V2',  no_interp=1
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V2', yrange=[0,64]
                options,'mvn_lpw_'+strtrim(packet,2)+'2_V2', zrange=[-.2,0.2]
                ;---------------------------------------------------
 
      
                ;----------  variable: E12 ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_size) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_size) ,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   fltarr(nn_size)  )   ;1-D 
                dataA =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum,nn_steps),  $     ; double 1-D arr
                                         'v',    fltarr(nn_pktnum,nn_steps)) 
                ;-------------- derive  time/variable ----------------   
                 data.x = time_dt
                 dataA.x=time
                 for i=0L,nn_pktnum-1 do begin
                          ;data.x[nn_steps*i:nn_steps*(i+1)-1] = time[i] + dindgen(nn_steps) * dt[i]                                                                                                                                                                                                   
                         ; data.y[nn_steps*i:nn_steps*(i+1)-1] = output_state_E12_LF[i,*] *const_E12_LF                                                                                                                                                                                                  
                          data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_state_E12_LF[i,*] *const_E12_LF)-e12_corr(0))/e12_corr(1)
                          data.dy[nn_steps*i:nn_steps*(i+1)-1] =((10                       *const_E12_LF)-e12_corr(0))/e12_corr(1)  ;10 DN
                 endfor         
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                          dlimit=create_struct(   $
                             'Product_name',                  'Calibrated PKT Electric field data, mode: '+strtrim(packet,2), $
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
                             'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
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
                             'cal_y_const1'    ,     'Uses: ' +strcompress(const_E12_LF,/remove_all) ,$ ; Fixed convert information from measured binary values to physical units, variables from ground testing and design
                             ;'cal_y_const2'    ,     'Used :' , $  ; Fixed convert information from measured binary values to physical units, variables from space testing
                             ;'cal_datafile'    ,     'No calibration file used' , $
                             'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $
                             'xsubtitle'       ,     '[sec]', $
                             'ysubtitle'       ,     '[uncorr Volt]')
                          ;-------------  limit ----------------
                          limit=create_struct(   $
                            'char_size' ,     lpw_const.tplot_char_size ,$
                            'xtitle' ,        str_xtitle                   ,$
                            'ytitle' ,        'mvn_lpw_'+strtrim(packet,2)+'_e12',$
                            'yrange' ,        [min(data.y),max(data.y)] ,$
                            'ystyle'  ,       1.                       ,$
                            'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                            'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                            'xlim2'    ,      [min(data.x),max(data.x)], $              ;for plotting lpw pkt lab data
                            'noerrorbars', 1)
                          ;------------- store --------------------
                          store_data,'mvn_lpw_'+strtrim(packet,2)+'_e12',data=data,limit=limit,dlimit=dlimit
                          ;---------------------------------------------                
 ;   remove bad points and the DC signal               
 
                 xx=indgen( nn_steps)  ; smallest value 1 second
                 tmp=fltarr(nn_steps)                                                              
                 for i=0L,nn_pktnum-1 do begin
                           tmp[*]=((output_state_E12_LF[i,*] *const_E12_LF)-e12_corr(0))/e12_corr(1)                          
                           tmp[0:1]=  !values.f_nan
                           ;;dataA.y[i,*] = ((output_state_E12_LF[i,*] *const_E12_LF)-e12_corr(0))/e12_corr(1)                   
                           flag= 1. ; (max(tmp) LT 5.)*(min(tmp) GT -5.)
                           tmp0= LADFIT(xx[4:nn_steps-1],tmp[4:nn_steps-1])  ;,nan )
                           dataA.y[i,*]            = (tmp -(tmp0[1]*xx+tmp0[0]) )/flag                           
                           data.y[nn_steps*i:nn_steps*(i+1)-1] = ((output_state_E12_LF[i,*] *const_E12_LF)-e12_corr(0))/e12_corr(1)
                           dataA.v[i,*]=xx    
                           da=i*nn_steps     
                           data.y[da:da+nn_steps-1]=(tmp -(tmp0[1]*xx+tmp0[0]) )/flag  
                 endfor                                 
                         ;------------- store --------------------
  ;                       store_data,'mvn_lpw_'+strtrim(packet,2)+'2_e12',data=data,limit=limit,dlimit=dlimit
  ;                       options,'mvn_lpw_'+strtrim(packet,2)+'2_e12',DATAGAP=60*5
  ;this will give me the matrix to see trends
                         store_data,'mvn_lpw_'+strtrim(packet,2)+'3_e12',data=dataA,limit=limit,dlimit=dlimit
                         options,'mvn_lpw_'+strtrim(packet,2)+'3_e12',spec=1
                         options,'mvn_lpw_'+strtrim(packet,2)+'3_e12',no_interp=1
                         options,'mvn_lpw_'+strtrim(packet,2)+'3_e12',yrange=[0,64]
                         options,'mvn_lpw_'+strtrim(packet,2)+'3_e12',zrange=[-0.02,0.02]
                         
                         

get_data,'mvn_lpw_atr_dac_raw',data=d_dac,limit=limit2
;#             Waves mode bias current = = -[(dac_setting -2048)   (50V/2048)] / 50000000 ohms
yy=-1.0*([[d_dac.y[*,0]],[d_dac.y[*,6]]] -2048.)* (50./2048)* 1.0/50000000 *1e9
store_data,'DAC',data={x:d_dac.x,y:yy}
options,'DAC','labels',limit2.labels[[0,6]]
options,'DAC','ytitle','Bias [nA]'
options,'DAC','colors',[0,6]
options,'DAC','labflag',1
options,'DAC','psym',-2    
                    
                          dataM=dataA
                          
                          for i=0L,nn_pktnum-1 do begin
                             dataA.v[i,*]  = 1.0*xx/nn_steps *subcycle_length[output.mc_len[output_state_i[i]] ]*4. ; smallest value 1 second
                        
                             tmp0=min(abs(d_dac.x-dataA.x[i]),nq)    ; get the DAC value
                             if dataA.x[i] LT d_dac.x[nq] then nq=(nq-1) >0
                             
                             tmp= ((output_state_E12_LF[i,*] *const_E12_LF)-e12_corr(0))/e12_corr(1)  ; this is the potential                         
                             tmp2= LADFIT(xx[4:nn_steps-1],tmp[4:nn_steps-1])  ;,nan )
                             tmp3 = (tmp -(tmp2[1]*xx+tmp2[0]) )                     
                  
                             IF abs(yy[nq,0]+yy[nq,1]) GT 16          then tmp3[*] =  !values.f_nan  ; to large DAC value
                             IF output.orb_md[output_state_i[i]] EQ 8 then tmp3[*] =  !values.f_nan  ; not in electric field mode
                             ;fill in the matrix 
                             if (max(tmp) GT 5.) OR (min(tmp) LT -5.) then  $     ; if saturated void
                                 tmp3[*]  =    !values.f_nan 
                                 tmp3[0:1] =  !values.f_nan                                    ; always remove first two points
                            ; fill in the matrix   presently not used   
                                          ;dataA.y[i,*]   =  tmp3                            
                                          ;dataA.y[i,0]   = max(tmp,/nan) 
                                          ;dataA.y[i,1]   = min(tmp,/nan) 
                            
                            ; fill in the time array  
                             data.y[nn_steps*i:nn_steps*(i+1)-1] = tmp3                           
                             dtmp= fltarr( nn_steps)   ; no corrections 
                            ; if packet EQ 'act' then $
                              void=3   ; finding the if there is a extreme value ignore the first points
                              
                             
                               ;     print,i,' # ',total(tmp3,/nan), max(abs(tmp3),/nan)
                               ;  if max(abs(tmp3),/nan) GT 0.1 then begin
                                    
                                ;    stanna
                                
                                     dtmp[0:void-1]= 1.0 * abs(tmp3[0:void-1])                        ;  first 2 points always 100 % error
                                        
                                      tt =    sort( abs(tmp3[   void:nn_steps-1]))                    ; find the largest values excluding the first points
                                      tmp_mean=mean(abs(tmp3[tt[0   :nn_steps-1-void-3]+void]))       ; <- increase the error on the 3+3 extreme values when they stand out
                                 
                                 ; large spikes, give lare errors (this incase the number of points associated with void is not enough)
                                      if  abs(abs( tmp3[tt[nn_steps-1-void]+void])-tmp_mean)/tmp_mean GT 20 then begin 
                                         dtmp[tt[nn_steps-1-void-5]+void] = abs(1.0 * tmp3[tt[nn_steps-1-void-5]+void])
                                         dtmp[tt[nn_steps-1-void-4]+void] = abs(0.9 * tmp3[tt[nn_steps-1-void-4]+void])                                       
                                         dtmp[tt[nn_steps-1-void-3]+void] = abs(0.8 * tmp3[tt[nn_steps-1-void-3]+void]) 
                                         dtmp[tt[nn_steps-1-void-2]+void] = abs(0.7 * tmp3[tt[nn_steps-1-void-2]+void])
                                         dtmp[tt[nn_steps-1-void-1]+void] = abs(0.6 * tmp3[tt[nn_steps-1-void-1]+void])
                                         dtmp[tt[nn_steps-1-void-0]+void] = abs(0.5 * tmp3[tt[nn_steps-1-void-0]+void])                                                                  
                                      endif                                       
                               ; endif 
                               
                              ; data.y === tmp  ; dtmp is to make the error a fraction of the value at the begining of the time period
                              if total(abs(dataA.y[i,*]),/nan) GT 0 then $
                                data.dy[nn_steps*i:nn_steps*(i+1)-1] = (0.0001  + abs(dtmp))  else $  ;0.01 is the minimum error and then increase the first points based on dtmp
                                data.dy[nn_steps*i:nn_steps*(i+1)-1] =  !values.f_nan
       
                      
                                                                               
                          endfor  
                         ;doublecheck
                         data.dy = (abs(data.dy) < abs(data.y)) > 0.0001
                         tmp = where( 0 EQ (finite(data.y)),nq)
                         data.dy[tmp] = !values.f_nan
     
                          
                    ;     store_data,'mvn_lpw_'+strtrim(packet,2)+'4_e12',data=dataA,limit=limit,dlimit=dlimit
                    ;     options,'mvn_lpw_'+strtrim(packet,2)+'4_e12',spec=1
                    ;     options,'mvn_lpw_'+strtrim(packet,2)+'4_e12',no_interp=1
                    ;     options,'mvn_lpw_'+strtrim(packet,2)+'4_e12',yrange=[0,9]
                    ;     options,'mvn_lpw_'+strtrim(packet,2)+'4_e12',zrange=[-0.02,0.02]
                         store_data,'mvn_lpw_'+strtrim(packet,2)+'5_e12',data=data,limit=limit,dlimit=dlimit
                         options,'mvn_lpw_'+strtrim(packet,2)+'5_e12',yrange=[-0.5,0.5]
                         options,'mvn_lpw_'+strtrim(packet,2)+'5_e12','noerrorbars', 1
                         
                         options,'mvn_lpw_'+strtrim(packet,2)+'3_e12',DATAGAP=60*5                         
                     ;    options,'mvn_lpw_'+strtrim(packet,2)+'4_e12',DATAGAP=60*5                    
                         options,'mvn_lpw_'+strtrim(packet,2)+'5_e12',DATAGAP=60*5
                         
                         ;---------------------------------------------                
                
         
                
                
                 
     
                 ;------------- variable:  mc_len ---------------------------  needed for the spectra
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum))     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                      
                 data.y = subcycle_length[output.mc_len[output_state_i] ]*4.                                      
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT mc_len data, mode: '+strtrim(packet,2), $
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
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data  
                   'MONOTON', 'INCREASE', $
                   'SCALEMIN', 0, $
                   'SCALEMAX', 65, $        ;..end of required for cdf production.
                   't_epoch'         ,     t_epoch, $ 
                   'Time_start'      ,     clock_start_t_dt, $
                   'Time_end'        ,     clock_end_t_dt, $
                   'Time_field'      ,     clock_field_str, $
                   'SPICE_kernel_version', kernel_version, $
                   'SPICE_kernel_flag'      ,     spice_used, $                      
                   'L0_datafile'     ,     filename_L0 , $ 
                   'cal_vers'        ,     cal_ver+' # '+pkt_ver ,$     
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        strtrim(packet,2)+'_mc_len',$   
                  'yrange' ,        [0,65]                   ,$   
                  'ystyle'  ,       1.                       ,$   
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,    [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                 store_data,'mvn_lpw_'+strtrim(packet,2)+'_mc_len',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
      
     IF tplot_var EQ 'ALL' THEN BEGIN 
                ;------------- variable:  mode ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $     ; double 1-D arr
                                         'y',    fltarr(nn_pktnum) )     ;1-D 
                ;-------------- derive  time/variable ---------------- 
                 data.x = time                                                    
                 data.y = output.orb_md[output_state_i]  
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $                           
                   'Product_name',                  'Calibrated PKT Electric field mode data, mode: '+strtrim(packet,2), $
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
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data
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
                   'cal_source'      ,     'Information from PKT: '+strtrim(packet,2), $   
                   'xsubtitle'       ,     '[sec]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $               
                  'char_size' ,     lpw_const.tplot_char_size ,$     
                  'xtitle' ,        str_xtitle                   ,$   
                  'ytitle' ,        strtrim(packet,2)+'_mode',$   
                  'yrange' ,        [-1,18]                  ,$   
                  'ystyle'  ,       1.                       ,$        
                  'xrange2'  ,      [min(data.x),max(data.x)],$           ;for plotting lpw pkt lab data
                  'xstyle2'  ,      1                       , $           ;for plotting lpw pkt lab data
                  'xlim2'    ,      [min(data.x),max(data.x)])              ;for plotting lpw pkt lab data
                ;------------- store --------------------                        
                     store_data,'mvn_lpw_'+strtrim(packet,2)+'_mode',data=data,limit=limit,dlimit=dlimit
                ;---------------------------------------------
     
     
     
     
              ;------------- variable:  act/pas packet L0b-raw  ---------------------------
                data =  create_struct(   $           
                                         'x',    dblarr(nn_pktnum) ,  $               ; double 1-D arr
                                         'y',    fltarr(nn_pktnum, nn_steps*3+2))      ;1-D 
                ;-------------- derive  time/variable ----------------                          
                 for i=0L,nn_pktnum-1 do begin
                   data.x[i]                         = time_sc[i]                     ;sc time only 
                   data.y[i,0:nn_steps-1]            = output_state_V1[i,*] 
                   data.y[i,nn_steps:nn_steps*2-1]   = output_state_V2[i,*] 
                   data.y[i,nn_steps*2:nn_steps*3-1] = output_state_E12_LF[i,*]                  
                   data.y[i,nn_steps*3+0]             = subcycle_length[output.mc_len[output_state_i[i]] ]*4. 
                   data.y[i,nn_steps*3+1]             = output.orb_md[output_state_i[i]]                                
                  endfor             
                str1=[ 'V1 DN'+strarr(nn_steps), $
                       'V2 DN'+strarr(nn_steps), $
                       'E12 DN'+strarr(nn_steps), $
                       'Subcycle  Length','Orbit mode']                                     
                ;-------------------------------------------
                ;--------------- dlimit   ------------------
                dlimit=create_struct(   $ 
                   'Product_name',                  'MAVEN LPW raw L0b PKT Electric field data, mode: '+strtrim(packet,2), $
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
                 'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
        'y_catdesc',                     'See labels for individual lines', $    ;
        'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
        'y_Var_notes',                   'See labels for individual lines', $
        'xFieldnam',                     'x: UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $     
        'yFieldnam',                     'y: see labels for individual lines', $
                 'derivn',                        'Equation of derivation', $    ;####
                   'sig_digits',                    '# sig digits', $ ;#####
                   'SI_conversion',                 'Convert to SI units', $  ;####                                                                            
                   'Var_type',  'Data', $    ;can be data, support data, metadata or ignore data 
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
                   'cal_source'      ,            'Information from PKT: e12 '+strtrim(packet,2)+'-raw', $            
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[Raw Packet Information]')          
                ;-------------  limit ---------------- 
                limit=create_struct(   $                  
                  'xtitle' ,                      'Time (s/c)'            ,$   
                  'ytitle' ,                      'Misc'                 ,$  
                  'labels' ,                      str1                    ,$   
                  'yrange' ,                      [min(data.y),max(data.y)] )
                ;------------- store --------------------                        
                store_data,'mvn_lpw_'+strtrim(packet,2)+'_l0b',data=data,limit=limit,dlimit=dlimit
               ;---------------------------------------------
   
     
      ENDIF
      
ENDIF ELSE  print, 'mvn_lpw_pkt_e12_dc.pro ('+strtrim(packet,2)+') skipped as no packets found.'

end
;*******************************************************************





