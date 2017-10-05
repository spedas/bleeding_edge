
;+
;PROCEDURE:   mvn_lpw_prd_mrg_ExB
;
;Routine takes mvn_lpw_w_E12_L2 data and Magnetometer-L2 data and procduse the poynting flux based on the 1-D electrci field information
;the resulting E, B, ExB=S is down sampled so the S product represent a time interal 
;The error information provide information of the uncurtanty in the qunatity weighted by the dynamics in the E and B on shorter time scales
;the flag provide the confidnece level of the result
;this product will be the last we finnish working with
;
;INPUTS:         
;   ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
;KEYWORDS:
; 
;EXAMPLE:
; mvn_lpw_prd_mgr_ExB
;
;
;CREATED BY:   Laila Andersson 11-06-2013
;FILE:         mvn_lpw_prd_mgr_ExB.pro
;VERSION:      1.0
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working 
; 2014-10-06: CF: modified dlimits for ISTP comliance.
;
;-

pro mvn_lpw_prd_mrg_exb,ext

; Get the time this routine was run into the tplot variable
t_routine=SYSTIME(0) 
vers_prd= 'Ver. prd_mgr_ExB 1.0'  ; the version number of this routine

;---------------------------------------------------------------------------------------------------
;    Check which variables exists for this routine
;    for the moment all variables has to be loaded in all ready, this routine do not call on any other routines 
;---------------------------------------------------------------------------------------------------

print,'Running: mvn_lpw_prd_mgr_ExB'

;===============
;Check Inputs:
IF size(ext, /type) NE 7 THEN BEGIN
    print, "### WARNING ###: Input 'ext' must be a string: l1a, l1b or l2. Returning."
    retall
ENDIF
;---------------------------------------------------------------------------------------------------
;    Check tplot variables exist before using them:
;---------------------------------------------------------------------------------------------------
    names = tnames(s)                                                              ;names is an array containing all tplot variable names currently in IDL memory.
    variables=['mvn_lpw_w_e12_l2','mvn_lpw_w_e12_l1b','mvn_lpw_w_e12_l1a','mvn_mag_time_l2']
    variables=['mvn_lpw_w_e12_l2','mvn_lpw_w_e12_l1','mvn_lpw_w_e12_l1a','mvn_lpw_w_e12_l1a']   ; fejk
    missing_variable =' The following variables are missing: '                     ; keep track if the data existed or not

    IF total(strmatch(names, variables[0])) EQ 1 THEN  get_data,variables[0],data=data0,limit=limit0,dlimit=dlimit0  ELSE $ 
         IF total(strmatch(names, variables[1])) EQ 1 THEN  get_data,variables[1],data=data0,limit=limit0,dlimit=dlimit0  ELSE $ 
             IF total(strmatch(names, variables[2])) EQ 1 THEN  get_data,variables[2],data=data0,limit=limit0,dlimit=dlimit0  ELSE $
                      missing_variable=[missing_variable,variables[0]+' was not found']
    IF total(strmatch(names, variables[3])) EQ 1 THEN get_data,variables[3],data=data1,limit=limit1,dlimit=dlimit1  ELSE missing_variable=[missing_variable,variables[1]+' was not found']
 
    
    IF n_elements(missing_variable) EQ 1 THEN BEGIN                          ;big loop         
;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production in a routine called mvn_lpw_prd_limit_dlimt
;---------------------------------------------------------------------------------------------------  
       dlimit_merge = dlimit0       
       limit_merge = limit0
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------

   
      ;------------------------------------------
      ;   calibration errorflag etc
      ;-----------------------------------------

      IF  (ext EQ 'l2') THEN BEGIN      ;(ext EQ 'l2')
        IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1  THEN $                               ; what aspects should be evaluates
          check_varariables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $
          check_varariables=['fake_flag']  ; for now

        mvn_lpw_prd_w_flag, data_l2_x,check_varariables,flag, flag_info, flag_source, vers_prd ,scale ; this is based on mag resolution

      ENDIF     ELSE BEGIN  ;(ext EQ 'l1a') OR  (ext EQ 'l1b')
        ; this is just so we can do l1a and l1b data products
        check_varariables =  'fake_flag'  ;
        flag_info         = ' The uncertanty of the values 100. is the best quality '
        flag_source       = 'Example '+ ' mvn_lpw_anc_angles '+' mvn_lpw_anc_pos_mso '
        scale             = 1.0
        flag              = 0.0
      ENDELSE

      data_l2_flag   = scale   + flag  ; data_l2_flag above contain information of  which boom

     
      ;------------------------------------------
      ;   derive value
      ;-----------------------------------------

     
     
      mvn_lpw_prd_mrg_exb_derive,data0,data1,flag1,data_l2_x,data_l2_y,data_l2_dy,data_l2_flag,data_names,data_colors      
    
      ;---------------------------------------------------------------------------------------------------
      ;                                end of creating the data_l2 product  
      ;---------------------------------------------------------------------------------------------------
    
  
      ;---------------------------------------------------------------------------------------------------
      ;                            Create the L2 tplot variables
      ;---------------------------------------------------------------------------------------------------
      ;------------------ Variables created not stored in CDF files -------------------    
   
      ;------------------All information based on the SIS document-------------------         
                              
                    ;-------------------- tplot variable 'mvn_lpw_w_E12_L2' ------------------- 
                    ;--------------------- SIS name: LPW.calibrated.w_E12 -------------------  
                    ;-------------------  There will be 1 CDF file per day --------------------   
                    data_l2 =  create_struct(        $       ; Which are used should follow the SIS document for this variable !! Look at: Table 13: : Contents for LPW.calibrated.w_E12, LPW.calibrated.w_E12_burst_lf, LPW.calibrated.w_E12_burst_mf, and LPW.calibrated.w_E12_burst_hf calibrated data files.     
                                             'x',    data_l2_x,  $     ; double 1-D arr
                                             'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                             'dy',   data_l2_dy,  $    ; same size as y
                                             'flag', data_l2_flag)     ;1-D 
                 ;-------------------------------------------
                 ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Product_name',                  'MAVEN LPW ExB Calibrated level '+ext, $
                   'Project',                       dlimit_merge.Project, $
                   'Source_name',                   dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                    dlimit_merge.Discipline, $
                   'Instrument_type',               dlimit_merge.Instrument_type, $
                   'Data_type',                     'DDR>Derived',  $
                   'Data_version',                  dlimit_merge.Data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    dlimit_merge.Descriptor, $
                   'PI_name',                       dlimit_merge.PI_name, $
                   'PI_affiliation',                dlimit_merge.PI_affiliation, $
                   'TEXT',                          dlimit_merge.TEXT, $
                   'Mission_group',                 dlimit_merge.Mission_group, $
                   'Generated_by',                  dlimit_merge.Generated_by,  $
                   'Generation_date',               dlimit_merge.Generation_date+' # '+t_routine, $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
                   'Rules_of_use',                  dlimit_merge.Rules_of_use, $
                   'Acknowledgement',               dlimit_merge.Acknowledgement,   $  
                   'Title',                         'MAVEN LPW ExB L2', $   ;####            ;As this is L0b, we need all info here, as there's no prd file for this
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'ExB', $    ;### ARE UNITS CORRECT? v/m?
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Error on the data.', $     ;###
                   ;'dv_catdesc',                    'test dlimit file, dv', $   ;###
                   'flag_catdesc',                  'test dlimit file, flag.', $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'ExB notes', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'The value of dy is the +/- error value on the data.', $
                   ;'dv_Var_notes',                   'Error on frequency', $
                   'flag_Var_notes',                'Flag variable', $
                   'xFieldnam',                     'x: More information', $      ;###
                   'yFieldnam',                     'y: More information', $
                   'vFieldnam',                     'v: More information', $
                   'dyFieldnam',                    'dy: More information', $
                   'dvFieldnam',                    'dv: More information', $
                   'flagFieldnam',                  'flag: More information', $
                   'derivn',                        'Equation of derivation', $    ;####
                   'sig_digits',                    '# sig digits', $ ;#####
                   'SI_conversion',                 'Convert to SI units', $  ;####                    
                   'MONOTON',                     dlimit_merge.MONOTON, $
                   'SCALEMIN',                    min(data_l2_y,/na), $
                   'SCALEMAX',                    max(data_l2_y,/na), $        ;..end of required for cdf production.
                   't_epoch'         ,            dlimit_merge.t_epoch, $
                   'Time_start'      ,            dlimit_merge.Time_start, $
                   'Time_end'        ,            dlimit_merge.Time_end, $
                   'Time_field'      ,            dlimit_merge.Time_field, $
                   'SPICE_kernel_version',        dlimit_merge.SPICE_kernel_version, $
                   'SPICE_kernel_flag',           dlimit_merge.SPICE_kernel_flag, $ 
                   'Flag_info'       ,            flag_info, $
                   'Flag_source'     ,            flag_source, $                      
                   'L0_datafile'     ,            dlimit_merge.L0_datafile       +' # '+' Mag Info TBR', $ 
                   'cal_vers'        ,            dlimit_merge.cal_vers+ ' # ' + vers_prd + ' # '+' Mag Info TBR',$     
                   'cal_y_const1'    ,            dlimit_merge.cal_y_const1      + ' # '+' Mag Info TBR', $
                   'cal_y_const2'    ,            'Merge level: ' + strcompress(1,/remove_all)   ,$
                   'cal_datafile'    ,            'NA', $
                   'cal_source'      ,            dlimit_merge.cal_source        + ' # '+check_variables_str, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[Misc]', $                   
                   'cal_v_const1'    ,            'NA', $
                   'cal_v_const2'    ,            'NA', $
                   'zsubtitle'       ,            'NA') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit0.char_size   ,$    
                  'xtitle' ,                     limit0.xtitle    ,$   
                  'ytitle' ,                     'Misc'    ,$   
                  'yrange' ,                     [min(data_l2_y,/na),max(data_l2_y,/na)]        ,$   
                  'ystyle'  ,                    1        ,$ 
                  'noerrorbars',                 1, $  
                  'labels' ,                     data_names,$   
                  'colors' ,                     data_colors,$   
                  'labflag' ,                    1 )                                       
                 ; 'ylog'   ,                     1              ,$ 
                 ; 'ztitle' ,                     'Power' ,$   
                 ; 'zrange' ,                     [1e-2,1e6],$
                 ; 'zlog'  ,                      1  ,$
                 ; 'spec'  ,                      1  )
                  ;---------------------------------------------
                  store_data,'mvn_lpw_mrg_exb_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                  ;---------------------------------------------    
       
      ;---------------------------------------------------------------------------------------------------
      ;                              end tplot production
      ;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, "#### WARNING #### No  data present; mvn_lpw_prd_mrg_exb.pro skipped..." ,missing_variable



end
;*******************************************************************

