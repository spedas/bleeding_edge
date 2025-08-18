
;+
;PROCEDURE:   mvn_lpw_prd_lp_IV_la
;
; Routine takes IV-cureves from both booms and combines them into one tplot variable for L2-production. 
; The default swp1 and swp2 are from different subcycles.
; The sweep length can vary but the number of points in the sweep is fixed
; There will be error both in the current and the sweep potential
; The error information and flag information is taking also into consideration information from other sources such as spacecraft atitude.
;
;INPUTS:         
;   ext                                     ;'l1a' 'l1b' or 'l2'  what level of quality to produce ('l2' is full information to be archived)
;   
;KEYWORDS:
; 
;EXAMPLE:
; mvn_lpw_prd_lp_IV,'l1a'
;
;
;CREATED BY:   Laila Andersson  11-04-13
;FILE:         mvn_lpw_prd_lp_IV.pro
;VERSION:      1.0
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working
;
;-

pro mvn_lpw_prd_lp_IV_la,ext

print,'Running: mvn_lpw_prd_lp_IV',' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_lp_IV  1.0'  ; the version number of this routine
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
    names = tnames(s)                                                              ;names is an array containing all tplot variable names currently in IDL memory.
    variables=['mvn_lpw_swp1_IV','mvn_lpw_swp2_IV']
    missing_variable =' The following variables are missing: '                     ; keep track if the data existed or not

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
       get_data,found_variables(1),data=data,limit=limit                        ; use data for default time array and limit for limit_l2                     
;---------------------------------------------------------------------------------------------------
;                              dlimit and limit created
;---------------------------------------------------------------------------------------------------
 
 ;---------------------------------------------------------------------------------------------------
 ;                             Creating the data_l2 product:  
 ;                             Merge the data 
 ;                             Modify the error information with respect of atitude and other things, for L1b, L2
 ;                             Create a quality flag, for L1b, L2
 ;---------------------------------------------------------------------------------------------------      
       data_l2_x=data.x                                                               ; the default time array
       mvn_lpw_prd_add_time,data_l2_x,data0
       mvn_lpw_prd_add_time,data_l2_x,data1
       nn                = n_elements(data_l2_x)
       nn_swp            = n_elements(data.y(0,*))
       data_l2_y         = fltarr(nn,nn_swp)       
       data_l2_dy         = fltarr(nn,nn_swp)
       data_l2_v         = fltarr(nn,nn_swp)
       data_l2_dv         = fltarr(nn,nn_swp)
       
; -------------- I here use the 'w' flag routine, the 'lp' routine might be the same or different
       IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1 THEN $                               ; what aspects should be evaluates
           check_varariables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $  
           check_varariables=['fake_flag']  ; for now  
           check_variables_str=check_varariables[0]
           for i=1,n_elements(check_varariables)-1 do check_variables_str=check_variables_str+' # '+check_varariables[i]
             
         mvn_lpw_prd_w_flag, data_l2_x,check_varariables,data_l2_flag, flag_info, flag_source, vers_prd  ; this is based on mag resolution                    
; -------------- merge the data        
        mvn_lpw_prd_add_data,data0,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv
        mvn_lpw_prd_add_data,data1,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv         
;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
;   
;                            None    
;                             
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------                              
;-------------------- tplot variable 'mvn_lpw_w_spec_L2' ------------------- 
;--------------------- SIS name: LPW.calibrated.w_spec (act/pas) -------------------  
;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(  $             ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data filed.    
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y
                                         'v',    data_l2_v,  $     ; same size as y
                                         'dv',   data_l2_dv,  $    ;same size as y  <--- here this is frequemcy width
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                 dlimit_l2=create_struct(   $                           
                   'Project',                     dlimit_merge.Project, $                          
                   'Source_name',                 dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                  dlimit_merge.Discipline, $
                   'Var_type',                    dlimit_merge.Var_type, $
                   'Data_type',                   dlimit_merge.Data_type ,  $   
                   'Descriptor',                  dlimit_merge.Descriptor, $                 
                   'Data_version',                dlimit_merge.Data_version, $ 
                   'PI_name',                     dlimit_merge.PI_name, $
                   'PI_affiliation',              dlimit_merge.PI_affiliation, $
                   'TEXT',                        dlimit_merge.TEXT, $
                   'Instrument_type',             dlimit_merge.Instrument_type, $
                   'Mission_group',               dlimit_merge.Mission_group, $
                   'Logical_file_ID',             dlimit_merge.Logical_file_ID, $
                   'Logical_source',              dlimit_merge.Logical_source, $
                   'Logical_source_description',  dlimit_merge.Logical_source_description, $ 
                   'Rules_of_use',                dlimit_merge.Rules_of_use, $   
                   'MONOTON',                     'INCREASE', $
                   'SCALEMIN',                    min(data_l2_y), $
                   'SCALEMAX',                    max(data_l2_y), $        ;..end of required for cdf production.
                   'generated_date'  ,            dlimit_merge.generated_date + ' # ' + t_routine ,$
                   't_epoch'         ,            dlimit_merge.t_epoch, $
                   'Time_start'      ,            dlimit_merge.Time_start, $
                   'Time_end'        ,            dlimit_merge.Time_end, $
                   'Time_field'      ,            dlimit_merge.Time_field, $
                   'SPICE_kernel_version',        dlimit_merge.SPICE_kernel_version, $
                   'SPICE_kernel_flag',           dlimit_merge.SPICE_kernel_flag, $ 
                   'Flag_info'       ,            flag_info, $
                   'Flag_source'     ,            flag_source, $                      
                   'L0_datafile'     ,            dlimit_merge.L0_datafile, $ 
                   'cal_vers'        ,            dlimit_merge.cal_vers+ ' # ' + vers_prd,$     
                   'cal_y_const1'    ,            dlimit_merge.cal_y_const1, $
                   'cal_y_const2'    ,            'Merge level:' +strcompress(1,/remove_all)   ,$
                   'cal_datafile'    ,            ' TBD ', $
                   'cal_source'      ,            dlimit_merge.cal_source, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[V]', $                   
                   'cal_v_const1'    ,            dlimit_merge.cal_v_const1, $
                   'cal_v_const2'    ,            'Merge level:' +strcompress(1,/remove_all) , $
                   'zsubtitle'       ,            '[nA]') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'Sweep pot'    ,$   
                  'yrange' ,                     [min(data_l2_v,/na),max(data_l2_v,/na)]        ,$   
                  'ystyle'  ,                    1        ,$ 
                  'ylog'   ,                     0              ,$ 
                  'ztitle' ,                     'Current' ,$   
                  'zrange' ,                     [min(data_l2_y,/na),max(data_l2_y,/na)],$
                  'zlog'  ,                      0  ,$
                  'spec'  ,                      1  )
                 ; 'noerrorbars',     limit_merge.noerrorbars, $  ; not used for this product
                 ; 'labels' ,        limit.labels,$   ; not used for this product
                 ; 'colors' ,        limit.colors,$   ; not used for this product 
                 ; 'labflag' ,       limit.labflag)   ; not used for this product                    
                ;---------------------------------------------
                store_data,'mvn_lpw_lp_iv_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    

;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
      
ENDIF ELSE print, "#### WARNING #### No data present; mvn_lpw_prd_lp_IV.pro skipped..."  


end
;*******************************************************************

