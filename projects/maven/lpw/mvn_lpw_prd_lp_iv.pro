
;+
;PROCEDURE:   mvn_lpw_prd_lp_IV
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
;VERSION:      2.0
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working
; 2015-05-26   L. Andersson   update for the L2 processing
;
;-

pro mvn_lpw_prd_lp_IV,ext

print,'Running: mvn_lpw_prd_lp_IV',' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_lp_IV  2.0'  ; the version number of this routine
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
       mvn_lpw_prd_add_time,data_l2_x,data1            ; making the time array to use and thereafter the information to go into it
       nn                   = n_elements(data_l2_x)
       nn_swp               = n_elements(data.y(0,*))
       data_l2_y            = fltarr(nn,nn_swp)       
       data_l2_dy           = fltarr(nn,nn_swp)
       data_l2_v            = fltarr(nn,nn_swp)
       data_l2_dv           = fltarr(nn,nn_swp)
       data_l2_boom         = fltarr(nn)
       data_l2_flag         = dblarr(nn)
 
 
 ;----------------------------------------------------
 ;use boom 1 and boom 2 to indentify bad sweeps on boom 2
 ;this is hardcoded
 if 'aug2015' EQ 'sep2015' then begin  ;   this is how bad sweeps was identifiec when only boom 2 was effected
 value_neg_boom1 = total(data0.y*(data0.v LT -3),2)/total((data0.v LT -3),2) ;boom 1
 value_neg_boom2 = total(data1.y*(data1.v LT -3),2)/total((data1.v LT -3),2) ;boom 2
 value_neg_boom1_x2=fltarr(n_elements(value_neg_boom2))
 value_pos_boom1 = total(data0.y*(data0.v GT -1)*(data0.v LT 5),2)/total((data0.v GT -1)*(data0.v LT 5),2)
 value_pos_boom2 = total(data1.y*(data1.v GT -1)*(data1.v LT 5),2)/total((data1.v GT -1)*(data1.v LT 5),2)
 value_pos_boom1_x2=fltarr(n_elements(value_pos_boom2))
 for i=0,n_elements(value_neg_boom2)-1 do begin
   tmp=min(abs(data0.x-data1.x[i]),nq)
   value_neg_boom1_x2[i]=value_neg_boom1[nq]
   value_pos_boom1_x2[i]=value_pos_boom1[nq]
 endfor
 tmp0= ((abs(value_neg_boom2 -value_neg_boom1_x2)/abs(value_neg_boom1_x2)   LT  0.45)  + $
        (value_pos_boom1_x2 GT 1.e-8)+ $
        (value_neg_boom1_x2 GT -1.e-8) < 1) * $
        (value_pos_boom2 GT -3e-8)
 tmp1= ((abs(value_neg_boom2 -value_neg_boom1_x2)/abs(value_neg_boom1_x2)   LT  0.2)  + $
        (value_pos_boom1_x2 GT 1.e-8)+ $
        (value_neg_boom1_x2 GT -1.e-8) < 1) * $
        (value_pos_boom2 GT -3e-8)
 ;---------------------------------------------------- 
 ; -------------- merge the data  udo this for each boom seperately
       boom=0.1
       mvn_lpw_prd_add_data,data0,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv,data_l2_boom=data_l2_boom,boom=boom
       tmp = where(data_l2_boom EQ boom,qq)
       if qq GT 0 then   data_l2_flag[tmp] =double(70.*(data_l2_y[tmp,5] LT 1e-5) )  ;boom 1   put it to 70%  where n is derived
       boom=0.2
       mvn_lpw_prd_add_data,data1,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv,data_l2_boom=data_l2_boom,boom=boom
       tmp = where(data_l2_boom EQ boom,qq)
       if qq GT 0 then   data_l2_flag[tmp] =double(70.*(data_l2_y[tmp,5] LT 1e-5)*tmp0 +1*(tmp0 EQ 0))  ;boom 1   put it to 70%  where n is derived
;--------------------------
endif else begin ; seperate routine fo find bad sweeps on both boom 1 and 2
  ;----------------------END------------------------------
  ;----------------------------------------------------

; Boom 1
tt_size0=size(data0)
if tt_size0[0] GT 0 then begin
  tmp = mvn_lpw_anc_sweep_info(data0.v, data0.y) ; 1 is bad and 0 is good
  tmp0=tmp.badsweep
  store_data, 't0', data={x:data0.x, y:tmp0}
  ylim, 't0', -1,2
  ; now add the dat to the structure one at a time and then put the flag to 70% unless tmp0/tmp1 is bad
  boom=0.1
  mvn_lpw_prd_add_data,data0,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv,data_l2_boom=data_l2_boom,boom=boom
  tmp = where(data_l2_boom EQ boom,qq)
  if qq GT 0 then   data_l2_flag[tmp] =double(70.*(data_l2_y[tmp,5] LT 1e-5)*(tmp0 EQ 0) )  ;boom 1   put it to 70%  where n is derived
endif

;boom 2
tt_size1=size(data1)
if tt_size1[0] GT 0 then begin
  tmp = mvn_lpw_anc_sweep_info(data1.v, data1.y)
  tmp1=tmp.badsweep
  store_data, 't1', data={x:data1.x, y:tmp1}
  ylim, 't1', -1,2
  boom=0.2
  ; now add the dat to the structure one at a time and then put the flag to 70% unless tmp0/tmp1 is bad
  mvn_lpw_prd_add_data,data1,data_l2_x,data_l2_y,data_l2_dy,data_l2_v=data_l2_v,data_l2_dv=data_l2_dv,data_l2_boom=data_l2_boom,boom=boom
  tmp = where(data_l2_boom EQ boom,qq)
  if qq GT 0 then   data_l2_flag[tmp] =double(70.*(data_l2_y[tmp,5] LT 1e-5)*(tmp1 EQ 0) )  ;boom 2   put it to 70%  where n is derived
endif

 
endelse
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

         data_l2_flag  = data_l2_flag *scale + data_l2_boom  + flag  ; data_l2_flag above contain information of  which boom

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
                   'Product_name',                'MVN LPW IV-curve Level: '+ext, $
                   'Project',                     dlimit_merge.Project, $
                   'Source_name',                 dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                  dlimit_merge.Discipline, $
                   'Instrument_type',             dlimit_merge.Instrument_type, $
                   'Data_type',                   'CAL>calibrated' ,  $
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
                   'y_catdesc',                     'Current [A]', $     ;autoplot info;### ARE UNITS CORRECT? v/m?
                   'v_catdesc',                     'Sweep Potential [V]', $    ;###
                   'dy_catdesc',                    'Uncertainty in measured current', $     ;###
                   'dv_catdesc',                    'Uncertainty in potential', $   ;###
                   'flag_catdesc',                  'Quality of Current'+ flag_info, $   ; ###
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Current ', $
                   'v_Var_notes',                   'Potential', $
                   'dy_Var_notes',                  'Uncertainty in current ', $
                   'dv_Var_notes',                  'Uncertainty in potential', $
                   'flag_Var_notes',                'Quality of IV-sweep', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: Current', $
                   'vFieldnam',                     'v: Sweep potential', $
                   'dyFieldnam',                    'dy: Uncertainty in current ', $
                   'dvFieldnam',                    'dv: Uncertainty in potential', $
                   'flagFieldnam',                  'flag: Quality of IV-sweep (see also Flag_info/Flag_source)', $
                   'derivn',                        'NA', $    ;####
                   'sig_digits',                     3, $ ;#####
                   'SI_conversion',                  '1A = 1e9 nA', $  ;####
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
                   'cal_vers'        ,            dlimit_merge.cal_vers+ ' # ' + vers_prd,$
                   'cal_y_const1'    ,            dlimit_merge.cal_y_const1, $
                   'cal_y_const2'    ,            'Merge level:' +strcompress(1,/remove_all) ,$
                   'cal_datafile'    ,            ' NA' , $ ;dlimit0.cal_datafile, $ ;(after getting the text file into dlimit)
                   'cal_source'      ,            dlimit_merge.cal_source, $
                   'xsubtitle'       ,            '[sec]', $
                   'ysubtitle'       ,            '[V]', $
                   'cal_v_const1'    ,            dlimit_merge.cal_v_const1, $
                   'cal_v_const2'    ,            'Merge level:' +strcompress(1,/remove_all), $
                   'zsubtitle'       ,            '[A]')
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'Sweep Pot'    ,$   
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

