;----------------------
;
;   pro mvn_lpw_read_gse_file
;
;----------------------
;
; Get the expected variables into the variables that will be used later
; ;The tables are spread out in time for the testing period.
;
;----------------------
;  contains routines/procedures:
;  mvn_lpw_read_gse_file   
;----------------------
;example
; to run
;     mvn_lpw_read_gse_file
;----------------------
; history:
; original file atr_check made by Corinne Vannatta  17 August  2011
; last changed: 2011  Oct 3  by LA
;----------------------
;
;*******************************************************************

pro mvn_lpw_read_gse_file,expected,lpw_const

;--------------------- Constants ------------------------------------
nn_pktnum=lpw_const.nn_modes
nn_swp=lpw_const.nn_swp  
nn_dac=lpw_const.nn_dac
t_epoch=lpw_const.t_epoch_expected
const_1=lpw_const.sign

const_lp_bias1_DAC = lpw_const.lp_bias1_DAC
const_lp_bias2_DAC = lpw_const.lp_bias2_DAC


const_lp_guard1_DAC = lpw_const.lp_guard1_DAC
const_w_guard1_DAC = lpw_const.w_guard1_DAC 
const_lp_stub1_DAC = lpw_const.lp_stub1_DAC
const_w_stub1_DAC = lpw_const.w_stub1_DAC
const_lp_guard2_DAC = lpw_const.lp_guard2_DAC
const_w_guard2_DAC = lpw_const.w_guard2_DAC 
const_lp_stub2_DAC = lpw_const.lp_stub2_DAC
const_w_stub2_DAC = lpw_const.w_stub2_DAC  

;--------------------------------------------------------------------

;------------- variable:  expected_dac ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_dac) )
dlimit=create_struct(   $      
   'datafile'     ,  expected.name  ,$
   'data_att'     ,  'datatype.type')   
;-------------- derive the time ----------------                                                     
 data.x=expected.time_opened+ t_epoch + (expected.time_closed-expected.time_opened)  *indgen(nn_pktnum)/(nn_pktnum -1)  ;this spreds the modes out through the test time 
 data.y=expected.DAC_table    ; when all modes is not activated then 00 is in the matrix
;-------------
str1=['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
      'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2'] 
print,'(mvn_lpw_read_gse_file) I removed the ATR in the naming because I think that is wrong'
;print, 'LP_GUARD1: exp =', output.EXP_LP_GUARD1(pktNum), '  act =', output.ADR_LP_GUARD1(pktNum)*RB_GAIN
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'expected_dac', $
    'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'yrange', [0,128] )                             
;-------------  
store_data,'mvn_lpw_expected_dac',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
;if total(where(output.ATR_W_BIAS1 - expected.DAC_table(z,0) NE 0)) NE -1 then print, 'W_BIAS1 error'
;if total(where(output.ATR_W_GUARD1 - expected.DAC_table(z,1) NE 0)) NE -1 then print, 'W_GUARD1 error'
;if total(where(output.ATR_W_STUB1 - expected.DAC_table(z,2) NE 0)) NE -1 then print, 'W_STUB1 error'
;if total(where(output.ATR_LP_BIAS1 - expected.DAC_table(z,3) NE 0)) NE -1 then print, 'ATR_LP_BIAS1 error'
;if total(where(output.ATR_LP_GUARD1 - expected.DAC_table(z,4) NE 0)) NE -1 then print, 'ATR_LP_GUARD1 error'
;if total(where(output.ATR_LP_STUB1 - expected.DAC_table(z,5) NE 0)) NE -1 then print, 'ATR_LP_STUB1 error'
;if total(where(output.ATR_W_BIAS2 - expected.DAC_table(z,6) NE 0)) NE -1 then print, 'ATR_W_BIAS2 error'
;if total(where(output.ATR_W_GUARD2 - expected.DAC_table(z,7) NE 0)) NE -1 then print, 'ATR_W_GUARD2 error'
;if total(where(output.ATR_W_STUB2 - expected.DAC_table(z,8) NE 0)) NE -1 then print, 'ATR_W_STUB2 error'
;if total(where(output.ATR_LP_BIAS2 - expected.DAC_table(z,9) NE 0)) NE -1 then print, 'ATR_LP_BIAS2 error'
;if total(where(output.ATR_LP_GUARD2 - expected.DAC_table(z,10) NE 0)) NE -1 then print, 'ATR_LP_GUARD2 error'
;if total(where(output.ATR_LP_STUB2 - expected.DAC_table(z,11) NE 0)) NE -1 then print, 'ATR_LP_STUB2 error'

;------------- variable:  expected_swp ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_pktnum)  ,$
   'y'     ,  fltarr(nn_pktnum,nn_swp) ,$    
   'v'     ,  fltarr(nn_pktnum,nn_swp))
dlimit=create_struct(   $      
   'datafile'     ,  expected.name  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
 data.x=expected.time_opened+ t_epoch + (expected.time_closed-expected.time_opened)  *indgen(nn_pktnum)/(nn_pktnum -1) ;this spreds the modes out through the test time   
 flip_the_order= nn_swp-1-indgen(nn_swp) ; it is used in opposite order!!! to represent how in time the sweep is implemented
 for i=0,nn_pktnum-1 do begin  
      data.y(i,*)=expected.SWP_table(i,flip_the_order) ;output.ATR_SWP(i,flip_the_order)
      data.v(i,*)=indgen(nn_swp) ;flip_the_order  ;indgen(nn_swp) 
endfor
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'expected_sweep_table', $
   'yrange', [0,128] )                             
;-------------  
store_data,'mvn_lpw_expected_swp',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

tmp=size(expected.orb_mode_change)
IF tmp(0) EQ 1 then ss=1 ELSE ss=tmp(2)
;------------- variable:  expected_mode ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(ss)  ,$
   'y'     ,  fltarr(ss))
dlimit=create_struct(   $      
   'datafile'     ,  expected.name  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                    
 If ss eq 1 then begin
      data.x=expected.orb_mode_change(0)+t_epoch
      data.y=expected.orb_mode_change(1)
 ENDIF ELSE BEGIN
      data.x=expected.orb_mode_change(0,*)+t_epoch
      data.y=expected.orb_mode_change(1,*)
ENDELSE     
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'expected_orbit_mode', $
   'yrange', [-1,18] , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$        
   'xrange2'  , [expected.time_opened,expected.time_closed]+t_epoch, $   ;when the experiment started and closed!!! 
   'xstyle2'  ,   1  , $                                        ;for plotting putpuses 
   'xlim2'    , [expected.time_opened,expected.time_closed]+t_epoch)   ;when the experiment started and closed!!! 
                               
;-------------  
store_data,'mvn_lpw_expected_mode',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

tmp=size(expected.freq)
IF tmp(0) GE 1 THEN BEGIN   ;if any information is even there
IF tmp(0) EQ 1 then ss=1 ELSE ss=tmp(2)
;------------- variable:  expected_freq ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(ss)  ,$
   'y'     ,  fltarr(ss))
dlimit=create_struct(   $      
   'datafile'     ,  expected.name  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                    
 If ss eq 1 then begin
      data.x=expected.freq(0)+t_epoch
      data.y=expected.freq(1)
 ENDIF ELSE BEGIN
      data.x=expected.freq(0,*)+t_epoch
      data.y=expected.freq(1,*) 
ENDELSE     
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'expected_orbit_frequency', $
   'yrange', [0.9*min(data.y),1.1*max(data.y)], $
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                        
   'xrange2'  , [expected.time_opened,expected.time_closed]+t_epoch, $   ;when the experiment started and closed!!! 
   'xstyle2'  ,   1  , $                                        ;for plotting putpuses 
   'xlim2'    , [expected.time_opened,expected.time_closed]+t_epoch)   ;when the experiment started and closed!!!                           
;-------------  
store_data,'mvn_lpw_expected_freq',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
endif


tmp=size(expected.volt)
IF tmp(0) GE 1 THEN BEGIN   ;if any information is even there
IF tmp(0) EQ 1 then ss=1 ELSE ss=tmp(2)
;------------- variable:  expected_volt ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(ss)  ,$
   'y'     ,  fltarr(ss))
dlimit=create_struct(   $      
   'datafile'     ,  expected.name  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                    
 If ss eq 1 then begin
      data.x=expected.volt(0)+t_epoch
      data.y=expected.volt(1)
 ENDIF ELSE BEGIN
      data.x=expected.volt(0,*)+t_epoch
      data.y=expected.volt(1,*) 
ENDELSE     
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'expected_orbit_amplitude', $
   'yrange', [0.9*min(data.y),1.1*max(data.y)], $
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                        
   'xrange2'  , [expected.time_opened,expected.time_closed]+t_epoch, $   ;when the experiment started and closed!!! 
   'xstyle2'  ,   1  , $                                        ;for plotting putpuses 
   'xlim2'    , [expected.time_opened,expected.time_closed]+t_epoch)   ;when the experiment started and closed!!!                           
;-------------  
store_data,'mvn_lpw_expected_volt',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------
endif



;************************************************************************************************************************
;****************** here is where different comparisons are made and a new variable is created **********************************
get_data,'mvn_lpw_expected_dac',data=data0  ;variable info data.y=expected.DAC_table  ;'y',fltarr(nn_pktnum,nn_dac) )
get_data,'mvn_lpw_adr_lp_bias1_raw',data=data1        ;variable info: data.y=output.adr_lp_bias1*RB_GAIN ;'y',fltarr(nn_pktnum,nn_steps)
get_data,'mvn_lpw_adr_lp_bias2_raw',data=data2        ;variable info: data.y=output.adr_lp_bias2*RB_GAIN ;'y',fltarr(nn_pktnum,nn_steps)
get_data,'mvn_lpw_adr_surface_pot1',data=data3        ;variable info:  data.y(*,3)=output.adr_w_v1*RB_GAIN; 'y',fltarr(nn_pktnum,6) )
get_data,'mvn_lpw_adr_surface_pot2',data=data4        ;variable info:  data.y(*,3)=output.adr_w_v2*RB_GAIN ; 'y',fltarr(nn_pktnum,6) )
get_data,'mvn_lpw_adr_mode',data=data5
nn_size=n_elements(data5.x)
;----------  variable: expecteded_potentials   ---------------------------  THis is a variable that provides information of what potentials is expecteded on the board
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,8) ,$
   'v'     ,  fltarr(nn_size,8))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[raw units]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
print,'(mvn_lpw_read_gse_file) Testing to compare'
; Base everything on the expected information
data.x=data5.x                                                                                                                
for i=0,nn_size-1 do  begin
z_orbital_mode=data5.y(i)
 ;     LP_FG1 = output.ADR_LP_BIAS1(i,const_active_steps)*RB_GAIN                                    ;LP_FG1 = output.ADR_LP_BIAS1(i,126)*RB_GAIN
 ;     LP_FG2 = output.ADR_LP_BIAS2(i,const_active_steps)*RB_GAIN                                    ;LP_FG2 = output.ADR_LP_BIAS2(i,126)*RB_GAIN
      data.y(i,0)=-((data0.y(z_orbital_mode,5)  - const_1)*const_lp_stub1_DAC) + data1.y(i,126)             ;EXP_LP_STUB1(i) = -((expected.DAC_table(z,5) - 2048)*(10./2l^11)) + LP_FG1
      data.y(i,1)=-((data0.y(z_orbital_mode,11) - const_1)*const_lp_stub2_DAC) + data2.y(i,126)             ;EXP_LP_STUB2(i) = -((expected.DAC_table(z,11) - 2048)*(10./2l^11)) + LP_FG2
      data.y(i,2)=-((data0.y(z_orbital_mode,4)  - const_1)*const_lp_guard1_DAC) + data1.y(i,126)             ;EXP_LP_GUARD1(i) = -((expected.DAC_table(z,4) - 2048)*(10./2l^11)) + LP_FG1
      data.y(i,3)=-((data0.y(z_orbital_mode,10) - const_1)*const_lp_guard2_DAC) + data2.y(i,126)             ;EXP_LP_GUARD2(i) = -((expected.DAC_table(z,10) - 2048)*(10./2l^11)) + LP_FG2
 ;     W_FG1 = output.ADR_W_V1(i)*RB_GAIN                                                            ;W_FG1 = output.ADR_W_V1(i)*RB_GAIN
 ;     W_FG2 = output.ADR_W_V2(i)*RB_GAIN                                                            ;W_FG2 = output.ADR_W_V2(i)*RB_GAIN
      data.y(i,4)=-((data0.y(z_orbital_mode,2) - const_1)*const_w_stub1_DAC) + data3.y(i,3)              ;EXP_W_STUB1(i) = -((expected.DAC_table(z,2) - 2048)*(10./2l^11)) + W_FG1
      data.y(i,5)=-((data0.y(z_orbital_mode,8) - const_1)*const_w_stub2_DAC) + data4.y(i,3)              ;EXP_W_STUB2(i) = -((expected.DAC_table(z,8) - 2048)*(10./2l^11)) + W_FG2
      data.y(i,6)=-((data0.y(z_orbital_mode,1) - const_1)*const_w_guard2_DAC) + data3.y(i,3)            ;EXP_W_GUARD1(i) = -((expected.DAC_table(z,1) - 2048)*(10./2l^11)) + W_FG1
      data.y(i,7)=-((data0.y(z_orbital_mode,7) - const_1)*const_w_guard2_DAC) + data4.y(i,3)             ;EXP_W_GUARD2(i) = -((expected.DAC_table(z,7) - 2048)*(10./2l^11)) + W_FG2
endfor
str1=['LP_STUB1','LP_STUB2','LP_GUARD1','LP_GUARD2','W_STUB1','W_STUB2','W_GUARD1','W_GUARD2']
print,'(mvn_lpw_read_gse_file) Why is the LP_FG1 derived with the ADR_LP_BIAS1-s last point?'
;-------------
limit=create_struct(   $                                         ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'LP(W)_FG-DACtable' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                        ;this is not a tplot  
   'spec',        0, $                                          ;line plots
   'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'ystyle'    , 1  ,$                                          ;for plotting purpuses 
   'yrange'  , [min(data.y),max(data.y)], $                     ;for plotting purpuses   working in tplot
   'xrange2'  , [min(data.x),max(data.x)], $                    ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                        ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)])                      ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_expecteded_potentials',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

get_data,'mvn_lpw_expected_swp',data=data0
get_data,'mvn_lpw_adr_dyn_offset1',data=data1
get_data,'mvn_lpw_adr_mode',data=data2
nn_size=n_elements(data2.x)
;----------  variable: expecteded_bias1   ---------------------------  This is a variable that provides information of what potentials is expecteded on the board
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,nn_swp) ,$
   'v'     ,  fltarr(nn_size,nn_swp))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[ RAW]', $
   'zsubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x=data2.x                                                                                            
for i=0,nn_size-1 do  begin
    mode_z=data2.y(i)
    data.y(i,*) =-(data0.y(mode_z,*) +data1.y(i) - const_1)*const_lp_bias1_DAC      ;EXP_LP_BIAS1(i,*) = -(expected.SWP_table(z,*) + output.ADR_DYN_OFFSET1(i) - 2048)*(130./2l^11)  
    data.v(i,*)=indgen(nn_swp)
ENDFOR
;-------------
limit=create_struct(   $                                         ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_expecteded_bias1' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                        ;this is not a tplot  
   'spec',        1, $                                          ;spec plots
   'xrange2'  , [min(data.x),max(data.x)], $                    ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                        ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $
   'ztitle',  'Raw'  ,$ 
   'zlog',        1.,  $ 
   'ylog',        1.,  $
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.v,/nan),max(data.v,/nan)]+1, $             ;make sure zero is not the smallest, should be between 0 and 127 now 1-128
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [0.9*min(data.y,/nan),1.1*max(data.y,/nan)])                      ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_expecteded_bias1',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

get_data,'mvn_lpw_expected_swp',data=data0
get_data,'mvn_lpw_adr_dyn_offset1',data=data1
get_data,'mvn_lpw_adr_mode',data=data2
nn_size=n_elements(data2.x)
;----------  variable: expecteded_bias2   ---------------------------  This is a variable that provides information of what potentials is expecteded on the board
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,nn_swp) ,$
   'v'     ,  fltarr(nn_size,nn_swp))
dlimit=create_struct(   $      
   'datafile'     ,  'Info of file used'  ,$
   'xsubtitle'    ,  '[sec]', $
   'ysubtitle'    ,  '[ RAW]', $
   'zsubtitle'    ,  '[RAW]', $
   'data_att'     ,  datatype.type)   
;-------------- derive the time ---------------- 
data.x=data2.x                                                                                            
for i=0,nn_size-1 do  begin
    mode_z=data2.y(i)
    data.y(i,*) =-(data0.y(mode_z,*) +data1.y(i) - const_1)*const_lp_bias1_DAC      ;EXP_LP_BIAS2(i,*) = -(expected.SWP_table(z,*) + output.ADR_DYN_OFFSET2(i) - 2048)*(130./2l^11)  
    data.v(i,*)=indgen(nn_swp)
ENDFOR
;-------------
limit=create_struct(   $                                         ;this one I set up the fields as I need, not directly after tplot options
   'ytitle',  'mvn_lpw_expecteded_bias2' , $  
   'xtitle',  'Time'  ,$  
   'char_size' ,  2.  ,$                                        ;this is not a tplot  
   'spec',        1, $                                          ;spec plots
   'xrange2'  , [min(data.x),max(data.x)], $                    ;for plotting purpuses   not working in tplot 
   'xstyle2'  ,   1  , $                                        ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)] , $ 
   'ztitle',  'Raw'  ,$ 
   'zlog',        1.,  $ 
   'ylog',        1.,  $
   'ystyle'    , 1  ,$                                        ;for plotting purpuses 
   'yrange'  , [min(data.v,/nan),max(data.v,/nan)]+1, $             ;make sure zero is not the smallest, should be between 0 and 127 now 1-128
   'zstyle'    , 1  ,$                                        ;for plotting purpuses 
   'zrange'  , [0.9*min(data.y,/nan),1.1*max(data.y,/nan)])                      ;this is the true range
;-------------  
store_data,'mvn_lpw_adr_expecteded_bias2',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

;****************** Store the variables from the expected files **********************************
get_data,'mvn_lpw_expected_dac',data=data0,limit=limit0; order of the variables
                      ;  ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
                      ;        'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2'] 
get_data,'mvn_lpw_atr_dac',data=data1,limit=limit1   ; order of the variables
                      ;  ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
                      ;    'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2'] 
If total(limit0.labels NE limit1.labels) then stanna    ; not in the same order
get_data,'mvn_lpw_atr_mode',data=data2 
nn_size=n_elements(data2.x)
;------------- variable:  atr_error ---------------------------
datatype=create_struct('type', '{ raw}')
data=create_struct(   $        
   'x'     ,  dblarr(nn_size)  ,$
   'y'     ,  fltarr(nn_size,nn_dac) )
dlimit=create_struct(   $      
   'datafile'     ,  'file name'  ,$
   'data_att'     ,  datatype.type)   
;-------------- derive the time ----------------                                                     
 data.x=data2.x   
for i=0,nn_size-1 do begin
      orb_mode=data2.y(i)
      data.y(i,0)=data1.y(i,0)    - data0.y(orb_mode,0)        ;NE -1 then print, 'W_BIAS1 error'
      data.y(i,1)=data1.y(i,1)    - data0.y(orb_mode,1)        ;NE -1 then print, 'W_GUARD1 error'
      data.y(i,2)=data1.y(i,2)     - data0.y(orb_mode,2)         ;NE -1 then print, 'W_STUB1 error'
      data.y(i,3)=data1.y(i,3)    - data0.y(orb_mode,3)        ;NE -1 then print, 'ATR_LP_BIAS1 error'
      data.y(i,4)=data1.y(i,4)   - data0.y(orb_mode,4)       ;NE -1 then print, 'ATR_LP_GUARD1 error'
      data.y(i,5)=data1.y(i,5)    - data0.y(orb_mode,5)        ;NE -1 then print, 'ATR_LP_STUB1 error'
      data.y(i,6)=data1.y(i,6)     - data0.y(orb_mode,6)        ;NE -1 then print, 'ATR_W_BIAS2 error'
      data.y(i,7)=data1.y(i,7)    - data0.y(orb_mode,7)      ;NE -1 then print, 'ATR_W_GUARD2 error'
      data.y(i,8)=data1.y(i,8)    - data0.y(orb_mode,8)        ;NE -1 then print, 'ATR_W_STUB2 error'
      data.y(i,9)=data1.y(i,9)    - data0.y(orb_mode,9)      ;NE -1 then print, 'ATR_LP_BIAS2 error'
      data.y(i,10)=data1.y(i,10)  - data0.y(orb_mode,10)    ;NE -1 then print, 'ATR_LP_GUARD2 error'
      data.y(i,11)=data1.y(i,11)   - data0.y(orb_mode,11)       ;NE -1 then print, 'ATR_LP_STUB2 error'     
endfor
str1= ['W_BIAS1','W_GUARD1','W_STUB1','LP_BIAS1','LP_GUARD1','LP_STUB1', $
                        'W_BIAS2','W_GUARD2','W_STUB2','LP_BIAS2','LP_GUARD2','LP_STUB2'] 
;-------------
limit=create_struct(   $                          ;this one I set up the fields as I need, not directly after tplot options
  'labels',   str1, $                                          ;lable the different lines
   'labflag',    1 ,$ 
   'ytitle',  'ATR-Expected', $
   'char_size' ,  2.  ,$                                ;this is not a tplot variable
   'xrange2'  , [min(data.x),max(data.x)], $            ;for plotting purpuses   
   'xstyle2'  ,   1  , $                                ;for plotting putpuses 
   'xlim2'    , [min(data.x),max(data.x)], $                ;this is the true range
   'ystyle'    , 1  ,$   
   'yrange', [min(data.y)-1,max(data.y)+1] )                            ;this is the true range
;-------------  
store_data,'mvn_lpw_atr_error',data=data,limit=limit,dlimit=dlimit
;---------------------------------------------

end
;*******************************************************************






