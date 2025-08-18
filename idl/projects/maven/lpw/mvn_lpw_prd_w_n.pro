
;+
;PROCEDURE:   mvn_lpw_prd_w_n
;
;Takes active and passive HF spectra data and searches for the plasma line for L2-production. 
;Act and Pas occur at different points in the master cycle so they never overlap in time.
;The error information and flag information is also taken into consideration as well as information from other sources such as spacecraft attitude.
;This routine is expected to be refined so that the preliminary density from the LP-sweep can guide the Langmuir line search in the spectra, not yet implemented
;   The tplot variables mvn_lpw_spec_act_hf and mvn_lpw_spec_act_hf must be loaded into tplot memory before running this routine. 
;   There are additional variables that need to be loaded
;   Presently this routine does not go and grab them if they are missing.
;
;INPUTS:         
;   ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
;KEYWORDS:
; 
;EXAMPLE:
; mvn_lpw_prd_w_n
;
;
;CREATED BY:   Laila Andersson  03-30-15
;FILE:         mvn_lpw_prd_w_n.pro
;VERSION:      2.1
;LAST MODIFICATION:  
; 2014-05-22   L. Andersson   sigificant update and working
; 2014-12-01   T. McEnulty  updated sort flag of merged arrays, commented out flags that aren't working
; 2014-12-09   T. McEnulty added a flag of 80 with a decimal for the sorting (0.1 for act and 0.2 for pas)
; 2014-12-12   T. McEnulty updated dlimit
; 2015-01-08 T. McEnulty and L. Andersson - updated limit and dlimit to make tplot output easier to see
;2015 - 03-30   L. Andersson prep it for L2 production
;2015 - 05-25   L. Andersson update for L2 production

pro mvn_lpw_prd_w_n,ext




print,'Running: mvn_lpw_prd_w_n', ' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_w_n 2.1'  ; the version number of this routine
;---------------------------------------------------------------------------------------------------
;Check Inputs:
;---------------------------------------------------------------------------------------------------
IF size(ext, /type) NE 7 THEN BEGIN
    print, "### WARNING ###: Input 'ext' must be a string: l1a, l1b or l2. Returning."
    retall
ENDIF
;---------------------------------------------------------------------------------------------------
;    Check tplot variables exist before using them:
;---------------------------------------------------------------------------------------------------
    names = tnames(s)                      ;names is an array containing all tplot variable names currently in IDL memory.
    variables=['mvn_lpw_spec2_hf_act','mvn_lpw_spec2_hf_pas'] ; ** change to spec2 after you add the calibration 
    missing_variable ='The following variables are missing: '  ; keep track if the data existed or not

    IF total(strmatch(names, variables[0])) EQ 1 THEN get_data,variables[0],data=data0,limit=limit0,dlimit=dlimit0  ELSE missing_variable=[missing_variable,variables[0]+' was not found']
    IF total(strmatch(names, variables[1])) EQ 1 THEN get_data,variables[1],data=data1,limit=limit1,dlimit=dlimit1  ELSE missing_variable=[missing_variable,variables[1]+' was not found']
     found_variables='found :'
    If size(data0, /type) EQ 8 then found_variables=[found_variables,variables(0)]
    If size(data1, /type) EQ 8 then found_variables=[found_variables,variables(1)]

    IF n_elements(found_variables) GT 1 THEN BEGIN                                  ;big loop         
;---------------------------------------------------------------------------------------------------
;                  Merge the dlimit and limit information for tplot production in a routine called mvn_lpw_prd_limit_dlimt
;---------------------------------------------------------------------------------------------------  
       dlimit_merge = mvn_lpw_prd_merge_dlimit(found_variables)         
       get_data,found_variables(1),data=data,limit=limit,dlimit=dlimit                        ; use data for default time array and limit for limit_l2                     
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------
 
 ;---------------------------------------------------------------------------------------------------
 ;                             Creating the data_l2 product:  
 ;                             Merge the data 
 ;                             Modify the error information with respect of attitude and other things, for L1b, L2
 ;                             Create a quality flag, for L1b, L2
 ;---------------------------------------------------------------------------------------------------      
 ;  evaluate the two data set separately and then merge the two data sets      
      if ext EQ 'l2' then    mvn_lpw_prd_w_n_find_l1a,found_variables(1),data_out=data_out                 
      if ext NE 'l2' then    mvn_lpw_prd_w_n_find_l1a,found_variables(1),data_out=data_out  ; first variable
     
     
   density_version=' Density V6 ' ; this need to come out above  
     
     
  ;   print,found_variables(1),ext NE 'l2'
  ;   help,data_out
     
      
      data_l2_x       = data_out.x
      data_l2_y       = data_out.y
      data_l2_dy      = data_out.dy    
      data_l2_dv      = data_out.dv
      data_l2_flag1   = data_out.flag  ;flag representing how well we identified the plasma line
      data_l2_so      = fltarr(n_elements(data_out.x)) + 0.1   ; 1 is the first variable
     
      if n_elements(found_variables) EQ 3 THEN BEGIN     ; more than one variable
     
       if ext EQ 'l2' then     mvn_lpw_prd_w_n_find_l1a,found_variables(2),data_out=data_out   ;make it 70 if only spec is used, increase to 80 if atitude ia also used
       if ext NE 'l2' then     mvn_lpw_prd_w_n_find_l1a,found_variables(2),data_out=data_out   ;make it 70 if only spec is used, increase to 80 if atitude ia also used  
    
           data_x        = [data_l2_x, data_out.x]
           data_y        = [data_l2_y, data_out.y]
           data_dy       = [data_l2_dy, data_out.dy] *(2.+3.*data_y/3e4*(data_y GE 2e4)+(30.*data_y/2e4)*(data_y GT 2e3 and data_y LT 2e4))  ; increase the upper error, uppre end larger error bars
           data_dv       = [data_l2_dv, data_out.dv]
           data_flag1    = [data_l2_flag1, data_out.flag]           
           data_so       = [data_l2_so,fltarr(n_elements(data_out.x)) + 0.1]   ; 2 is the second variable
 
           tmp           = sort(data_x)    ; get the times correct
           
           data_l2_x     = data_x(tmp)
           data_l2_y     = data_y(tmp)
           data_l2_dy    = data_dy(tmp)
           data_l2_dv    = data_dv(tmp)
           data_l2_flag1 = data_flag1(tmp)
           data_l2_so    = data_so(tmp)                     
      ENDIF
      
; double check the values >10 %
tmp= where(data_l2_y GT 1 and data_l2_y LT 1e7,nq)
if nq GT 0 then $
  data_l2_dv[tmp] = data_l2_dv[tmp] >0.1 *data_l2_y[tmp]
  if nq GT 0 then $
  data_l2_dy[tmp] = data_l2_dy[tmp] >0.1 *data_l2_y[tmp]
tmp=where(data_l2_y LT 15,nq)
if nq GT 0 then $
  data_l2_dv[tmp] = data_l2_y[tmp]

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



       data_l2_flag  =double( (data_l2_flag1 - 30.*(data_l2_y LT 200)) *scale + data_l2_so  + flag ) ; data_l2_so above contain information of  which subcycle
 
 
 ;double check theflag value
 tmp=where( (data_l2_y GT 1 and data_l2_y LT 1e7) EQ 0, nq) ;find when no value is identified
 if nq GT 0 then $
 data_l2_flag[tmp] = data_l2_flag[tmp] - floor(data_l2_flag[tmp])
 
 
;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
;   


store_data,'wn_dflag',data={x:data_l2_x,y:flag}
store_data,'wn_flag',data={x:data_l2_x,y:data_l2_flag}
;                             
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------                              
;-------------------- tplot variable 'mvn_lpw_w_spec_L2' ------------------- 
;--------------------- SIS name: LPW.calibrated.w_spec (act/pas) -------------------  
;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(  $             ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data filed.    
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy, $     ; same size as y
                                         'dv',   data_l2_dv, $     ; same size as y
                                         'flag', data_l2_flag)     ;1-D                  
                ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Product_name',                'MVN LPW Densities from Plasma Line, level: '+ext, $                       
                   'Project',                     dlimit_merge.Project, $                          
                   'Source_name',                 dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                  dlimit_merge.Discipline, $
                   'Instrument_type',             dlimit_merge.Instrument_type, $
                   'Data_type',                   'DDR>derived' ,  $   
                   'Data_version',                dlimit_merge.Data_version, $ 
                   'Descriptor',                  dlimit_merge.Descriptor, $                 
                   'PI_name',                     dlimit_merge.PI_name, $
                   'PI_affiliation',              dlimit_merge.PI_affiliation, $
                   'TEXT',                        dlimit_merge.TEXT, $
                   'Mission_group',               dlimit_merge.Mission_group, $   
                   'Generated_by',                dlimit_merge.Generated_by, $
                   'Generation_date'  ,           dlimit_merge.generation_date + ' # ' + t_routine, $ 
                   'Rules_of_use',                dlimit_merge.Rules_of_use, $  
                   'Acknowledgement',             dlimit_merge.Acknowledgement, $
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $ ;autoplot info
                   'y_catdesc',                     'Density derived from the plasma line [cm-3]', $     ;autoplot info;### ARE UNITS CORRECT? v/m?
                   ;'v_catdesc',                     'test dlimit file, v', $    ;###
                   'dy_catdesc',                    'Upper Uncertainty in Density [cm-3]', $     ;###
                   'dv_catdesc',                    'Lower Uncertainty in Density [cm-3]', $   ;###
                   'flag_catdesc',                  'Quality of Density.'+ flag_info, $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Density [cm-3]', $
                   ;'v_Var_notes',                   'Frequency bins', $
                   'dy_Var_notes',                  'Upper Uncertainty in Density [cm-3]', $
                   'dv_Var_notes',                  'Lower Uncertainty in Density [cm-3]', $
                   'flag_Var_notes',                'Quality of Density', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: Density', $ 
                ;   'vFieldnam',                     'v: More information', $ 
                   'dyFieldnam',                    'dy: Upper Uncertainty', $ 
                   'dvFieldnam',                    'dv: Lower Uncertainty', $ 
                   'flagFieldnam',                  'flag: Quality of Density (see also Flag_info/Flag_source)', $ 
                   'derivn',                        ' n = (freq/8980)^2 : n in cm-3  and freq in Hz', $    ;####
                   'sig_digits',                      3, $ ;#####
                   'SI_conversion',               '1 cm-3 == 1e6 m-3', $  ;####                                                                          
                   ;'Var_type',                    'TBD', $   ; scalar?? Chris will add during cdf production
                   'MONOTON',                     'INCREASE', $
                   'SCALEMIN',                    min(data_l2_y), $
                   'SCALEMAX',                    max(data_l2_y), $        ;..end of required for cdf production.
                   't_epoch'         ,            dlimit_merge.t_epoch, $
                   'Time_start'      ,            dlimit_merge.Time_start, $  
                   'Time_end'        ,            dlimit_merge.Time_end, $  
                   'Time_field'      ,            dlimit_merge.Time_field, $
                   'SPICE_kernel_version',        dlimit_merge.SPICE_kernel_version, $
                   'SPICE_kernel_flag',           dlimit_merge.SPICE_kernel_flag, $ 
                   'Flag_info'       ,            flag_info, $
                   'Flag_source'     ,            flag_source, $                      
                   'L0_datafile'     ,            dlimit_merge.L0_datafile, $ 
                   'cal_vers'        ,            dlimit_merge.cal_vers+ ' # ' + vers_prd+ ' # '+  density_version,$     
                   'cal_y_const1'    ,            ' Not applicable ', $
                   'cal_y_const2'    ,            ' n = (freq/8980)^2 ',$
                   'cal_datafile'    ,            ' NA ', $ ;dlimit_merge.cal_datafile, $ ;(after getting the text file into dlimit) 
                   'cal_source'      ,            dlimit_merge.cal_source, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[cm!U-3!N]') ;, $                   
                   ;'cal_v_const1'    ,            'NA', $
                   ;'cal_v_const2'    ,            'NA', $
                   ;'zsubtitle'       ,            'NA') 
;                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  1.2   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'Density'    ,$   
                  'yrange' ,                     [5,2e5]        ,$   
                  'ystyle'  ,                    1        ,$ 
                  'ylog'   ,                     1        ,$ 
                  'psym'  ,                      4        ,$ 
                 ; 'ztitle' ,                     'Power' ,$   
                 ; 'zrange' ,                     [1e-2,1e6],$
                 ; 'zlog'  ,                      1  ,$
                 ; 'spec'  ,                      1  )
                  'noerrorbars',                  1)  ;for this product
                 ; 'colors' ,        limit.colors,$   ; not used for this product 
                 ; 'labflag' ,       limit.labflag)   ; not used for this product                    
                ;---------------------------------------------
                store_data,'mvn_lpw_w_n_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    

;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, "#### WARNING #### No act or pas data present; mvn_lpw_prd_w_spec.pro skipped..."  




end
;*******************************************************************

