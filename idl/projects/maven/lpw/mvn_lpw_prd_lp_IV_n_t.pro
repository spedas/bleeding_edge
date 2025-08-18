
;+
;PROCEDURE:   mvn_lpw_prd_lp_IV_n_t_
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
;VERSION:      2.1
;LAST MODIFICATION: 
; 2014-05-22   L. Andersson   sigificant update and working
; 2015-05-22   L. Andersson   update to get the L2 working
;
;-

pro mvn_lpw_prd_lp_IV_n_t,ext


print,'Running: mvn_lpw_prd_lp_IV_n_t',' ',ext
t_routine    = SYSTIME(0) 
vers_prd     = 'version prd_lp_IV_n_t  2.1'  ; the version number of this routine
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
                 
              
  ;if max(data.x) LT time_double('2015-01-31') then  mvn_lpw_prd_iv_fitflag_2014,data,data_l2_x,data_l2_y,data_l2_dy,data_l2_dv,data_flag,data_l2_boom,data_version    
  ;if min(data.x) GE time_double('2015-01-31') then  mvn_lpw_prd_iv_fitflag_2015,data,data_l2_x,data_l2_y,data_l2_dy,data_l2_dv,data_flag,data_l2_boom,data_version   
 
  ;note where I can controll what data to use
 ; removed 20160203 if max(data.x) LT time_double('2015-01-31') then  data_version = 'model_19'
if max(data.x) LT time_double('2015-01-31') then  data_version = 'model_21'
if max(data.x) GT time_double('2015-01-31') then  data_version = 'model_20'
if max(data.x) GT time_double('2016-01-01') then  data_version = 'model_21'  ; get the new thing here
;  mvn_lpw_prd_iv_fitflag_2015c,data,data_l2_x,data_l2_y,data_l2_dy,data_l2_dv,data_flag,data_l2_boom,data_version,str_arr,str_col 
  mvn_lpw_prd_iv_fitflag_2016,data,data_l2_x,data_l2_y,data_l2_dy,data_l2_dv,data_flag,data_l2_boom,data_version,str_arr,str_col
 
 
; this is the order  This is now defined in mvn_lpw_prd_iv_fitflag_20*
  ;                 0      1          2       3             4
    str_arr=['ne [cc]','te [K]','usc [V]','ne_hi [cc]','vsc_hi [V]','not used yet','not used yet', 'not used yet', 'not used yet','not used yet']   ;['u0','u1','usc','ne','ne1','ne2','Te','Te1','Te2','nsc']
    str_col=[        0,       6,        4,           2,            1,            3,              3,             3,              3,             3]
         
   ;remove  bad points     this is done in the fitflag routine now
   ;data_l2_flag = data_flag *( data_flag LT 100) *(data_flag GT 0)   ; this should result data_l2_flag to be 0 to 100 where 0 is best...
   ;data_l2_flag = (100 -  data_l2_flag)  *0.3 + 50   +0.05 * (data_flag EQ 88888)                ; if they are good they should be above 50 but presently only go to 80
   ; if SC potential is == 0 then set the flag to 40
   ;tmp = where( data_l2_y[*,2] LE 0 ,nq)
   ;if nq GT 0 then data_l2_flag[tmp]=data_l2_flag[tmp] - floor(data_l2_flag[tmp]) + 40 ; this could

  ;#########################  Units
     
   ; get the temperature in the right units
   unit=1./8.6173324*1e5  ;change to eV
   data_l2_y[*,1]= data_l2_y[*,1]  *unit
   data_l2_dy[*,1]=data_l2_dy[*,1] *unit
   data_l2_dv[*,1]=data_l2_dv[*,1] *unit
   
 ;#########################  Now populate the finalstructure



      ;------------------------------------------
      ;   calibration errorflag etc
      ;-----------------------------------------

      IF  (ext EQ 'l2') THEN BEGIN      ;(ext EQ 'l2')
        IF strpos(dlimit_merge.spice_kernel_flag, 'not') eq -1  THEN $                               ; what aspects should be evaluates
          check_varariables=['wake','sc_shadow','planet_shadow','sc_att','sc_pos','thrusters','gyros'] ELSE $
          check_varariables=['fake_flag']  ; for now

        mvn_lpw_prd_w_flag, data_l2_x,check_varariables,flag, flag_info, flag_source, vers_prd ,scale ; this is based on mag resolution

        get_data,'mvn_lpw_anc_mvn_alt_iau',data=data,limit=limit9,dlimit=dlimit9
        store_data,'l2_nt_alt',data=data,limit=limit9,dlimit=dlimit9

      ENDIF     ELSE BEGIN  ;(ext EQ 'l1a') OR  (ext EQ 'l1b')
        ; this is just so we can do l1a and l1b data products
        check_varariables =  'fake_flag'  ;
        flag_info         = ' The uncertanty of the values 100. is the best quality '
        flag_source       = 'Example '+ ' mvn_lpw_anc_angles '+' mvn_lpw_anc_pos_mso '
        scale             = 1.0
        flag              = 0.0
      ENDELSE

     data_l2_flag   = scale* data_flag + data_l2_boom  + flag  
     ;double check the flag value
     data_l2_flag0 = data_l2_flag
     tmp=where( (data_l2_y GT 1 and data_l2_y LT 1e7) EQ 0, nq) ;find when no value is identified
     if nq GT 0 then $
       data_l2_flag0[tmp] = data_l2_flag[tmp] - floor(data_l2_flag[tmp])
            
; -------------- merge the data        
 
               
;---------------------------------------------------------------------------------------------------
;                                end of creating the data_l2 product  
;---------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------
;                            Create the L2 tplot variables
;---------------------------------------------------------------------------------------------------
;------------------ Variables created not stored in CDF files -------------------    
;   
store_data,'ivnt_dflag'        ,data={x:data_l2_x,y:flag}
store_data,'ivnt_flag'         ,data={x:data_l2_x,y:data_flag}
store_data,'ivnt_final_flag'   ,data={x:data_l2_x,y:data_l2_flag0}
;                             
;------------------ Variables created not stored in CDF files -------------------     
;------------------All information based on the SIS document-------------------                              
;-------------------- tplot variable 'mvn_lpw_w_spec_L2' ------------------- 
;--------------------- SIS name: LPW.calibrated.w_spec (act/pas) -------------------  
;-------------------  There will be 1 CDF file per day --------------------   
                data_l2 =  create_struct(  $             ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data filed.    
                                         'x',    data_l2_x,  $     ; double 1-D arr
                                         'y',    data_l2_y,  $     ; most of the time float and 1-D or 2-D
                                         'dy',   data_l2_dy,  $    ; same size as y  upper error
                                         'dv',   data_l2_dv,  $    ; same size as y  lower error
                                         'flag', data_l2_flag)     ;1-D 
                ;-------------------------------------------
                  dlimit_l2=create_struct(   $                           
                   'Product_name',                  'MAVEN LPW IV-fitted products Level: '+ext, $
                   'Project',                       dlimit_merge.Project, $
                   'Source_name',                   dlimit_merge.Source_name, $     ;Required for cdf production...
                   'Discipline',                    dlimit_merge.Discipline, $
                   'Instrument_type',               dlimit_merge.Instrument_type, $
                   'Data_type',                     'DER> derived',  $
                   'Data_version',                  dlimit_merge.Data_version + ' Model Versions: '+data_version, $  ;Keep this text string, need to add v## when we make the CDF file (done later)
                   'Descriptor',                    dlimit_merge.Descriptor, $
                   'PI_name',                       dlimit_merge.PI_name, $
                   'PI_affiliation',                dlimit_merge.PI_affiliation, $
                   'TEXT',                          dlimit_merge.TEXT, $
                   'Mission_group',                 dlimit_merge.Mission_group, $
                   'Generated_by',                  dlimit_merge.Generated_by,  $
                   'Generation_date',               t_routine,$ ;dlimit_merge.Generation_date+' # '+t_routine, $   ;Gives the date and time the data is derived and the CDF file was created - can be multiple times ponts
                   'Rules_of_use',                  dlimit_merge.Rules_of_use, $
                   'Acknowledgement',               dlimit_merge.Acknowledgement,   $  
                   'x_catdesc',                     'Timestamps for each data point, in UNIX time.', $
                   'y_catdesc',                     'Different quantities derived from IV-fit ' + $
                                                    '(Electron density [cm-3], Electron temperature [K], Spacecraft potential [V] etc see labels)', $    ;### ARE UNITS CORRECT? v/m?
                   'v_catdesc',                     'NA', $    ;###
                   'dy_catdesc',                    'Upper Uncertainty of each quantity', $     ;###
                   'dv_catdesc',                    'Lower Uncertainty of each quantity', $   ;###
                   'flag_catdesc',                  'Quality of Density.'+ flag_info, $   ; 
                   'x_Var_notes',                   'UNIX time: Number of seconds elapsed since 1970-01-01/00:00:00.', $
                   'y_Var_notes',                   'Different quantities derived from IV-fit (Electron density (Ne), Electron Temperature (Te), '+ $
                                                    'Spacecraft potential (Vsc) etc see labels)', $ 
; this is where we can write a long text   <-------
                   'v_Var_notes',                   'NA', $
                   'dy_Var_notes',                  ' Upper Uncertainty of each quantity', $
                   'dv_Var_notes',                  ' Lower Uncertainty of each quantity', $
                   'flag_Var_notes',                'Flag variable', $
                   'xFieldnam',                     'x: Time', $      ;###
                   'yFieldnam',                     'y: Different Quantities', $
                   'vFieldnam',                     'NA', $
                   'dyFieldnam',                    'dy: Upper Uncertainty of each quantity', $
                   'dvFieldnam',                    'dv: Lower Uncertainty of each quantity', $
                   'flagFieldnam',                  'flag: Quality Flag', $
                   'derivn',                        'Model fit see instrument SIS and instrument paper TBD', $    ;####
                   'sig_digits',                    '2 sig digits', $ ;#####
                   'SI_conversion',                 'Convert to SI units 1 cm-3 = 1e6 m-3, 1 eV =8.61739e-5 * K, 1 V =  1V]', $  ;#### 
                   'MONOTON',                     dlimit_merge.MONOTON, $
                   'SCALEMIN',                    min(data_l2_y), $
                   'SCALEMAX',                    max(data_l2_y), $        ;..end of required for cdf production.
                   'generated_date'  ,            ' ' ,$;dlimit_merge.generated_date + ' # ' + t_routine ,$
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
                   'cal_datafile'    ,            'na', $
                   'cal_source'      ,            dlimit_merge.cal_source, $     
                   'xsubtitle'       ,            '[sec]', $   
                   'ysubtitle'       ,            '[misc]', $                   
                   'cal_v_const1'    ,            'NA', $
                   'cal_v_const2'    ,            'NA', $
                   'zsubtitle'       ,            'NA') 
                ;-------------------------------------------
                limit_l2=create_struct(   $                ; Which are used should follow the SIS document for this variable !! Look at: Table 14: Contents for LPW.calibrated.w_spec_act and LPW.calibrated.w_spec_pas calibrated data file.
                  'char_size' ,                  limit.char_size   ,$    
                  'xtitle' ,                     limit.xtitle    ,$   
                  'ytitle' ,                     'Misc'    ,$   
                  'yrange' ,                     [min(data_l2_y,/na),max(data_l2_y,/na)]        ,$   
                  'noerrorbars',                  1, $  
                  'labels' ,                      str_arr,$   
                  'colors' ,                      str_col,$   
                  'labflag' ,                     1)                      
                ;---------------------------------------------
                store_data,'mvn_lpw_lp_n_t_'+ext,data=data_l2,limit=limit_l2,dlimit=dlimit_l2 
                ;---------------------------------------------    

                ;---------------------------------------------------------------------------------------------------
                ;                             for view the result
                ;---------------------------------------------------------------------------------------------------

                store_data,'mvn_lpw_lp_mod_ne',  data={x:data_l2.x,y:[[data_l2.y[*,0]],[data_l2.y[*,0]-1.0*data_l2.dv[*,0]],[data_l2.y[*,0]+data_l2.dy[*,0]]]}
                options,'mvn_lpw_lp_mod_ne',yrange=[0.1,2e5]
                options,'mvn_lpw_lp_mod_ne',ylog=1
                options,'mvn_lpw_lp_mod_ne',ystyle=1
                options,'mvn_lpw_lp_mod_ne',colors=[0,3,4]
                store_data,'mvn_lpw_lp_mod_te',  data={x:data_l2.x,y:[[data_l2.y[*,1]],[data_l2.y[*,1]-1.0*data_l2.dv[*,1]],[data_l2.y[*,1]+data_l2.dy[*,1]]]}
                options,'mvn_lpw_lp_mod_te',yrange=[0.05,2]
                options,'mvn_lpw_lp_mod_te',yrange=[10,50000]  ;K
                options,'mvn_lpw_lp_mod_te',ylog=1
                options,'mvn_lpw_lp_mod_te',ystyle=1
                options,'mvn_lpw_lp_mod_te',colors=[0,3,4]
                store_data,'mvn_lpw_lp_mod_vsc',  data={x:data_l2.x,y:[[data_l2.y[*,2]],[data_l2.y[*,2]-1.0*data_l2.dv[*,2]],[data_l2.y[*,2]+data_l2.dy[*,2]]]}
                options,'mvn_lpw_lp_mod_vsc',yrange=[-15,5]
                options,'mvn_lpw_lp_mod_vsc',ystyle=1
                options,'mvn_lpw_lp_mod_vsc',colors=[0,3,4]
                options,'mvn_lpw_lp_mod_*',psym=1
                store_data,'mvn_lpw_lp_mod_flag',  data={x:data_l2.x,y:data_l2.flag}

;---------------------------------------------------------------------------------------------------
;                              end tplot production
;---------------------------------------------------------------------------------------------------
     


;---------------------------------------------------------------------------------------------------
;                              Make a plot of what is created
;---------------------------------------------------------------------------------------------------
  
       
nn=n_elements(data.x)     
date=time_string(data.x[nn/2])
result=strsplit(date,'/',/extract)
st=result[0]
print,'Working with date: ',st
; test_iv_peri,st  ;  assume the w_n L2 is in memeory


if 'yes' EQ 'nyes' then begin
  
  
  unit=1./8.6173324*1e5  ;change to eV
 get_data,'mvn_lpw_lp_n_t_l2',data=data
 aa=10000; 0 ;4000
 bb=14000 ;80000 ;7000
 t0=data.x[0]
 !p.multi=[0,1,4]
 plot_io, data.x-t0,data.y[*,0]*(data.flag GT 50),xrange=[aa,bb],yrange=[1,5e5],psym=-4
 oplot, data.x-t0,(data.y[*,0]+data.dy[*,0])*(data.flag GT 50),color=1,psym=-4
 oplot, data.x-t0,(data.y[*,0]-data.dv[*,0])*(data.flag GT 50),color=6,psym=-4
 get_data,'ne_all',data=nee
; oplot,nee.x-t0,nee.y[*,0],color=4,psym=1
; oplot,nee.x-t0,nee.y[*,1],color=2,psym=1
;p oplot,nee.x-t0,nee.y[*,2],color=3,psym=1
 plot_io, data.x-t0,data.y[*,1]*(data.flag GT 50),xrange=[aa,bb],yrange=[500,100000],psym=-4
 oplot, data.x-t0,(data.y[*,1]+data.dy[*,1])*(data.flag GT 50),color=1,psym=-4
 oplot, data.x-t0,(data.y[*,1]-data.dv[*,1])*(data.flag GT 50),color=6,psym=-4
 get_data,'te_all',data=tee
; oplot,tee.x-t0,tee.y[*,0]*unit,color=4,psym=1
; oplot,tee.x-t0,tee.y[*,1]*unit,color=2,psym=1
; oplot,tee.x-t0,tee.y[*,2]*unit,color=3,psym=1
tmp=where(data.flag GT 50)
 plot, data.x[tmp]-t0,data.y[tmp,2],xrange=[aa,bb],psym=-4, yrange=[-4,4]
 oplot, data.x[tmp]-t0,(data.y[tmp,2]+data.dy[tmp,2]),color=1,psym=-4
 oplot, data.x[tmp]-t0,(data.y[tmp,2]-data.dv[tmp,2]),color=6,psym=-4
 get_data,'vs_all',data=vsc
; oplot,vsc.x-t0,-1.0*vsc.y[*,0],color=4,psym=1
; oplot,vsc.x-t0,-1.0*vsc.y[*,1],color=2,psym=1
; oplot,vsc.x-t0,-1.0*vsc.y[*,2],color=3,psym=1
 get_data,'ree_erra_1',data=err
 plot_io,err.x-t0,err.y,xrange=[aa,bb],psym=-4  ;,yrange=[0,110]
 oplot,[0,1e6],[100,100],col=4
 oplot,[0,1e6],[50,50],col=4
 oplot,data.x-t0,data.flag,col=6,psym=-4
 oplot,vsc.x-t0,vsc.y[*,3],color=2,psym=1
 !p.multi=[0,1,1]
  
  stanna
  
  
endif  

test_iv_peri_plot,data_version,0  ;  assume the w_n L2 is in memeory

;#####################################
; remove all variables that was made here to get the routines to work
names = tnames(s)                               ;names is an array containing all tplot variable names currently in IDL memory.
nn=n_elements(var_names)
for ii=0,nn-1 do begin
  get_data,names[ii],data=data
  if n_elements(data.x) LT 3 then begin
       store_data,names[ii],/delete
  endif
endfor
;#####################################




;---------------------------------------------------------------------------------------------------
;                              end Make a plot of what is created
;---------------------------------------------------------------------------------------------------
   
        
ENDIF ELSE print, "#### WARNING #### No data present; mvn_lpw_prd_lp_IV.pro skipped..."  

end
;*******************************************************************

