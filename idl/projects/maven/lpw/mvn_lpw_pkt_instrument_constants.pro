;;+
;PROCEDURE:   mvn_lpw_pkt_instrument_constants
;PURPOSE:
;  This allowes different constants and calibration information to be located in one place
;  Old calibration data should be keept so that this routine can be used as a historic document 
;  The calibrations numbers are seperated also based on the board
;  the common structure is used in the initially laboratory software  
;  keep the common structure so that that the old software still work
;  For flight analysis, more common to use lpw_const2=lpw_const2 
;
;USAGE:
;        mvn_lpw_pkt_instrument_constants,board,lpw_const2,cdf_istp_lpw2
;
;INPUTS:
;       board:         which electronics board is used 'EM1' 'EM2' 'EM3' 'FM', default: 'FM'
;
;KEYWORDS:
;       lpw_const2:   if common block is not used then the information can be called for as one large structure 
;       cdf_istp_lpw2:  if common block is not used then the information can be called for as one large structure 
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE:         mvn_lpw_pkt_instrument_constants.pro
;VERSION:      2.0      <------------------------------- update 'version_calibration_routine' variable
;LAST MODIFICATION:  
; 17/01/14 CF: added keyword cdf_istp_lpw to carry across istp parameters for cdf file production.
; 05/01/14 The HSK calibration numbers is moved here now.
; ;140718 clean up for check out L. Andersson
; 20141003 the bias/stub/guard values is replaced by different separate routines reading the calfiles, only FM is fixed!!! L. Andersson
;-

pro mvn_lpw_pkt_instrument_constants,board,lpw_const2=lpw_const2

;common  data_info,output,expected,lpw_const,cdf_istp_lpw

;---------------------
; Get the date, version, and files associated with the calibrations

today_date=SYSTIME(0)                               ;produce a string when the calibration file was read
version_calib_routine   = 'Constant_ver 2.0'                     ;keep track of major changes 
tplot_char_size= 1.2
 ;---------------------

print,'(mvn_lpw_pkt_instrument_constants) Selected Board: x',board,'x'

;--------------- Board Unique Variables ----------------------- 
case board of
 'RAW': BEGIN   
                 const_lp_bias1_DAC=   1.0
                 const_w_bias1_DAC=    1.0
                 const_lp_guard1_DAC=  1.0
                 const_w_guard1_DAC=   1.0
                 const_lp_stub1_DAC=   1.0
                 const_w_stub1_DAC=    1.0
                 const_lp_bias2_DAC=   1.0
                 const_w_bias2_DAC=    1.0
                 const_lp_guard2_DAC=  1.0
                 const_w_guard2_DAC=   1.0
                 const_lp_stub2_DAC=   1.0
                 const_w_stub2_DAC=    1.0
                 ; Constants associated with Boom 1                
                 const_I1_readback=     1.                       
                 const_V1_readback=     1.
                 const_bias1_readback=  1.
                 const_guard1_readback= 1.
                 const_stub1_readback=  1.
                 const_epsilon1=        0.           
                  ; Constants associated with Sweep/boom 2
                 const_I2_readback=     1.
                 const_V2_readback=     1.             
                 const_bias2_readback=  1.
                 const_guard2_readback= 1.
                 const_stub2_readback=  1.                  
                 const_epsilon2=        0.         
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         1.
                 const_E12_MF =         1.
                 const_E12_HF =         1.                            
                 const_E12_HF_HG =  1.
 ; if complex correction is needed  
boom1_corr=[0.,1.]
boom2_corr=[0.,1.]
e12_corr=[0.,1.]     
e12_lf_corr=[0.,1.]
e12_mf_corr=[0.,1.]
e12_hf_corr=[0.,1.]                            
 
        END
 'EM1': BEGIN
                                                                           ; constants associated with DAC
                                                                           ;const_DAC_volt = 130./2048.                              
                                                                           ;20110916 EM1 & EM2 DAC conversion factor                
                 const_lp_bias1_DAC=   -1.0*(130./2048.)
                 const_w_bias1_DAC=    -1.0*(50./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(10./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(10./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(130./2048.)
                 const_w_bias2_DAC=    -1.0*(50./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(10./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(10./2048.)
                
                 
                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10                                 ;20110916 EM1 & EM2 no change  
                                                                               ;const_V2_readback=2.5/2d^15 * 50                          
                 const_V1_readback=     2.5/2d^15 * 238.                       ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.
                const_epsilon1=        -6.25                                     ;20140815 L. Anderssons eyball value                             
                  
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                   ;20110916 EM1 & EM2 no change
                                                                                 ;const_V1_readback=2.5/2d^15 * 50                            ;old
                 const_V2_readback=     2.5/2d^15 * 238.                         ;20110916 EM1 & EM2 From Bryans calculated and measured gain                 
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.
                  const_epsilon2=       -6.25                
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         6.25 / 2d^15                               ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)                                 
const_E12_HF_HG =  6.25 / 2d^15 
 ; if complex correction is needed 
boom1_corr=[0.,1.]
boom2_corr=[0.,1.]
e12_corr=[0.,1.]     
e12_lf_corr=[0.,1.]
e12_mf_corr=[0.,1.]
e12_hf_corr=[0.,1.]                          
 
        END
 'EM2': BEGIN
            print,'(mvn_lpw_pkt_instrument_constants) EM2 not activated yet below from EM1 on october 5'           
                 ; constants associated with DAC                             ;20110916 EM1 & EM2 DAC conversion factor
                 const_lp_bias1_DAC=   -1.0*(130./2048.)
                 const_w_bias1_DAC=    -1.0*(50./2048.)
;                 const_lp_bias1_DAC=   -1.0*(180./2048.)
;                 const_w_bias1_DAC=    -1.0*(85./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(10./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(10./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(130./2048.)
                 const_w_bias2_DAC=    -1.0*(50./2048.)
;                 const_lp_bias2_DAC=   -1.0*(80./2048.)
;                 const_w_bias2_DAC=    -1.0*(85./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(10./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(10./2048.)
 
                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10                                     ;20110916 EM1 & EM2 no change                           
                 const_V1_readback=     2.5/2d^15 * 238.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.                 
                const_epsilon1=        -6.25                                     ;20140815 L. Anderssons eyball value                             

                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                     ;20110916 EM1 & EM2 no change                          ;old
                 const_V2_readback=     2.5/2d^15 * 238.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain                
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.                
                 const_epsilon2=        -6.25                                     ;20140815 L. Anderssons eyball value                              
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         6.25 / 2d^15                               ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)                               
 const_E12_HF_HG =  6.25 / 2d^15 
 ; if complex correction is needed 
boom1_corr=[0.,1.]
boom2_corr=[0.,1.]
e12_corr=[0.,1.]     
e12_lf_corr=[0.,1.]
e12_mf_corr=[0.,1.]
e12_hf_corr=[0.,1.]                            
 
        END
 'EM3': BEGIN
            print,'(mvn_lpw_pkt_instrument_constants) EM3 not activated yet below from EM1 on october 5'           
                 ; constants associated with DAC                             ;20110916 EM1 & EM2 DAC conversion factor
                 const_lp_bias1_DAC=   -1.0*(50./2048.)
                 const_w_bias1_DAC=    -1.0*(85./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(12./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(12./2048.)
                 
                 const_lp_bias2_DAC=   -1.0*(50./2048.)
                 const_w_bias2_DAC=    -1.0*(85./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(12./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(12./2048.)
                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10     ;amps/count                    ;20110916 EM1 & EM2 no change                           
                 const_V1_readback=     2.5/2d^15 * 50.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.                 
                const_epsilon1=        -6.25                                     ;20140815 L. Anderssons eyball value                             
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                    ;20110916 EM1 & EM2 no change                          ;old
                 const_V2_readback=     2.5/2d^15 * 50.                           ;20110916 EM1 & EM2 From Bryans calculated and measured gain                
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.                
                 const_epsilon2=        -6.25                                     ;20140815 L. Anderssons eyball value                             
                ; Constants associated with Pass, Active and HSBM                          
                 const_E12_LF =         2.22 * 2.5  / 2d^15                        ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         1.667 * 2.0 / 2d^13                        ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)   
                 const_E12_HF_HG =      0.333 * 2.0 / 2d^13                            
 
 ; if complex correction is needed 
boom1_corr=[0.,1.]
boom2_corr=[0.,1.]
e12_corr=[0.,1.]     
e12_lf_corr=[0.,1.]
e12_mf_corr=[0.,1.]
e12_hf_corr=[0.,1.]                          
 
       END
 'FM': BEGIN

if 'yes' EQ 'yes' then begin  ; this is replaced 
                 ; constants associated with DAC                                   ;20110916 EM1 & EM2 DAC conversion factor
                 const_lp_bias2_DAC=   -1.0*(50./2048.)
                 ; from Greg 20140610  quickly read from our 20120718 surface tests:  For V1: max =  49.5091 at DAC setting 0x0000, min = -49.4798 at DAC setting 0x0ffc
                 const_lp_bias1_DAC=   -1.0*(49.5091+49.4798)/2/2048  ; expecting DN to be corrected to be centered at 2048               
                 const_w_bias1_DAC=    -1.0*(60./2048.)
                 const_lp_guard1_DAC=  -1.0*(10./2048.)
                 const_w_guard1_DAC=   -1.0*(12./2048.)
                 const_lp_stub1_DAC=   -1.0*(10./2048.)
                 const_w_stub1_DAC=    -1.0*(12./2048.)
                 
                 ;const_lp_bias2_DAC=   -1.0*(50./2048.)
                 ; from Greg 20140610  quickly read from our 20120718 surface tests: For V2: max = 49.3259 at DAC setting 0x0000, min = -49.3355 at DAC setting 0x0ffc
                 const_lp_bias2_DAC=   -1.0*(49.3259+49.3355)/2/2048  ; expecting DN to be corrected to be centered at 2048                   
                 const_w_bias2_DAC=    -1.0*(60./2048.)
                 const_lp_guard2_DAC=  -1.0*(10./2048.)
                 const_w_guard2_DAC=   -1.0*(12./2048.)
                 const_lp_stub2_DAC=   -1.0*(10./2048.)
                 const_w_stub2_DAC=    -1.0*(12./2048.)
endif
;the above has been replaced by the following routines called directly in the pkt-routines
;      mvn_lpw_cal_read_bias,bias_arr,bias_file
;      mvn_lpw_cal_read_guard,guard_arr,guard_file   ;><<<<<<< not working yet!!!!!
;      mvn_lpw_cal_read_stub,stub_arr,stub_file





;For V1: max =  49.5091 at DAC setting 0x0000, min = -49.4798 at DAC setting 0x0ffc
;For V2: max = 49.3259 at DAC setting 0x0000, min = -49.3355 at DAC setting 0x0ffc
; const_lp_bias1_DAC =  

                 ; Constants associated with Boom 1                
                 const_I1_readback=     2.E-10                                         ;20110916 EM1 & EM2 no change                           
                 const_V1_readback=     2.5/2d^15 * 50.                                ;20110916 EM1 & EM2 From Bryans calculated and measured gain
                 const_bias1_readback=  2.5/2d^15 *50.
                 const_guard1_readback= 2.5/2d^15 *50.
                 const_stub1_readback=  2.5/2d^15 *50.                 
                 const_epsilon1=        -6.25                                     ;20140815 L. Anderssons eyball value                             
                 ; Constants associated with Sweep/boom 2
                 const_I2_readback=     2.E-10                                          ;20110916 EM1 & EM2 no change                          ;old
                 const_V2_readback=     2.5/2d^15 * 50.                                 ;20110916 EM1 & EM2 From Bryans calculated and measured gain                
                 const_bias2_readback=  2.5/2d^15 *50.
                 const_guard2_readback= 2.5/2d^15 *50.
                 const_stub2_readback=  2.5/2d^15 *50.                
                 const_epsilon2=        -6.25                                     ;20140815 L. Anderssons eyball value                             
                ; Constants associated with Pass, Active and HSBM  
                 const_E12_LF =         2.22 * 2.5  / 2d^15                               ;20110921 EM1 & EM2 From David M  (used in PAS_AVG, ACT_AVG and LF_HSBM) 
                 const_E12_MF =         2.5  / 2d^15                                      ;20110921 EM1 & EM2 From David M  (used in MF_HSBM)
                 const_E12_HF =         1.667 * 2.0 / 2d^13                               ;20110921 EM1 & EM2 From David M   (used in HF_HSBM)   
                 const_E12_HF_HG =      0.333 * 2.0 / 2d^13                                                         
              
  
;  this is numbers Laila has started to derive from the calibration files
;yy1=(data1.y(a1:a2)-0.862597 )/0.982399
;yy2=(data1.y(a1:a2)-0.844507 )/0.980091
boom1_corr=[0.862597,0.982399]       ; to modify V1 in pkt_e12
boom2_corr=[0.844507,0.980091]       ; to modify V2 in pkt_e12

;yy1=(data1.y(a1:a2)-0.00177851)*0.974763
;yy2=(data1.y(a1:a2)-0.00177851)*0.974763
e12_corr=[0.00177851,0.974763]        ; to modify e12 in pkt_e12   
e12_corr[1] = e12_corr[1] / 0.95    ;amplitude  decresed based on cal_wave_20120719_210940_telemetry.dat  LA20150315   
    
; tt=(data1.y(tmp1)-0.00169450)* 0.983679
e12_lf_corr=[0.00169450, 0.983679] 
    
;; tt=(data2.y(tmp2)+0.00039)*1.175  
e12_mf_corr=[-0.00039, 1.175]    
e12_mf_corr[1] = e12_mf_corr[1] / 1.3    ;amplitude  increase 1.25 to 1.4 based on cal_wave_20120719_210940_telemetry.dat  LA20150315  
                                
; tt=(data2.y(tmp2)-0.0024)*1.10
e12_hf_corr=[0.0024, 1.10]  
e12_hf_corr[1] = e12_hf_corr[1] / 0.85    ;amplitude  decresed  0.5 to 1.2 based on cal_wave_20120719_210940_telemetry.dat  LA20150315                             
                          
   
   
   
              ;   const_E12_LF =         0.9*2.22 * 2.5  / 2d^15                          ;20120413  Laila's attempt to correct the above
              ;   const_E12_MF =         0.94*2.5  / 2d^15                                ;20120413  Laila's attempt to correct the above
              ;   const_E12_HF =         0.9*1.667 * 2.0 / 2d^13                          ;20120413  Laila's attempt to correct the above
              ;   const_E12_HF_HG =      0.333 * 2.0 / 2d^13                                                         
 
       END
ENDCASE        
;--------------- LPW Variables Independend of Board ----------------------- 


    ;------------------------- TIME: unique information ---------------------------------------------
    ;t_epoch=time_double('2000-01-02/00:00:00')
    t_epoch = time_double('2000-01-01/12:00:00')                    ; Working for ATLO fall 2012 
    ;t_epoch=time_double('2001-01-01/00:00:00')                     ; the GSE epoch time     
    ; From Tim Quin December 21, 2012 9:37 AM
    ;    The Spacecraft Simulator GSE (SSG) Software on the EM laptop has been updated
    ;    so the EPOCH now matches the LM spacecraft EPOCH of 1Jan2000, 12:00 UTC.
    
    ;
    ;t_epoch_expected=t_epoch  +6.*60.*60.      ;summer  the GSE epoch time   seems to be UT vs local time difference
    t_epoch_expected=t_epoch  +7.*60.*60.      ;winter  the GSE epoch time   seems to be UT vs local time difference
   ;-------------------------END: TIME ---------------------------------------------
   
  
   ;-------------------------Operation constants ---------------------------------------------
    const_sign      = 2048                                              ; to convert value to a sign value
    subcycle_length = [4.,8.,16.,32., 64.,128,256.]/4.                  ; table from ICD 7.12.3 and a subcycle is a quarter of the time
    nn_modes        = 16                                                ; assumption, number of modes.....
    nn_dac          = 12                                                ; number of predefined DAC points pre mode , note there are 16 slots, 4 are reserve therefore is the number 12
    sample_aver     = [16,32,64,128,256,512,1024,2048]                  ; table from ICD  7.12.3
   ;-------------------------END: Operation constants ---------------------------------------------
     
     
    ;-------------------------HSK: unique information ---------------------------------------------   
    ;hsk unique numbers
    ;const_hsk_temp=[[0.033113, 262.68], $        ; Preamp 1 temp constants  2013 Suart's diode responce numbers
    ;                [0.033113, 262.68], $        ; Preamp 2 temp constants  2013 Suart's diode responce numbers
    ;                [0.0325, 256.29]]            ; BEB temp constants from 2013 spring David S/David M
    ; From Greg Dec 23, 2013  Preamp 2: T = 0.0330299*DN + 256.166  
    ;From Greg Dec 23, 2013   V1: T (deg C) =  0.0330322*DN + 255.662
    ;From Greg Dec 23, 2013   V2: T (deg C) =  0.0330299*DN + 256.166         
    const_hsk_temp=[[0.0330322, 255.662], $       ; Preamp 1 temp constants  2013 Suart's diode responce numbers
                    [0.0330299, 256.166], $       ; Preamp 2 temp constants  2013 Suart's diode responce numbers
                    [0.0325,    256.29]]          ; BEB temp constants from 2013 spring David S/David M  
    ;From Dave Curtis February 18, 2014 3:31 PM
    ;FYI, the proposed new conversion factors are:
    ;FM1 preamp = 253.3 + ADC*0.0330322
    ;FM2 preamp = 251.0 + ADC*0.0330299
    ;The CCB discussed these today and we are moving forward with finalizing the paperwork. 
    const_hsk_temp=[[0.0330322, 253.3], $      
                    [0.0330299, 251.0], $       
                    [0.0325,    256.29]]                                         
    const_hsk_voltage=[ 0.0004581,  0.0004699, $  ;plus and minus 12 V conversion               
                        0.0001913,  0.0001923, $  ;plus and minus 5 V conversion               
                        0.0077058,  0.0077058]    ;plus and minus 90 V conversion   
    const_hsk_misc=[1.0,1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]    ;variables 9 to 16 i.e.:   
                     ;CMD_ACCEPT,CMD_REJECT,MEM_SEU_COUNTER,INT_STAT,CHKSUM,EXT_STAT,DPLY1_CNT,DPLY2_CNT  
    ;-------------------------END: HSK ---------------------------------------------
    
    ;-------------------- Instrument information -------------------------------------    
    inst_phys=[7,2]  ;Units [m], boom length, average boom diameter , boom surface, sensor length, sensor diameter, preamp/guard diameter
    sensor_distance= 10    ;[m]
    boom_shorting_factor=1.0      
    ;--------------------END: Instrument information -------------------------------------
       
       
    ;-------------------------SWEEP: unique information ---------------------------------------------   
    ;swp specific  (this is the number of table element in the sweep hance also adr specific)
    nn_swp          = 128                   ; number of sampels per subcycle -for the potential in sweep cycle
    nn_swp_steps    = 127                   ; for the sweep wait the first point to settle then sample
    nn_active_steps = 126                   ; the last point is omitted, do not contain important information   
    calib_file_iv   = ['mvn_lpw_calibration_file_iv_131101_v1.txt', $
                       'mvn_lpw_calibration_file_iv_140101_v1.txt'] ; the file needs to be located with the mvn_lpw-procedures to be found   
    ;-------------------------END: SWEEP ---------------------------------------------
   
   
    ;------------------------- HSBM: unique inforamtion --------------------------------------------- 
    ;hsbm sepcific
    nn_hsbm_lf       = 1024L
    nn_hsbm_mf       = 4096L
    nn_hsbm_hf       = 4096L
    nn_bin_lf        = 56
    f_bin_lf         = intarr(nn_bin_lf)   ;64ks/s channel 
    f_bin_lf[ 0:15]  = 1
    f_bin_lf[16:23]  = 2
    f_bin_lf[24:31]  = 4
    f_bin_lf[32:39]  = 8
    f_bin_lf[40:47]  =16
    f_bin_lf[48:55]  = 32
    nn_bin_mf        = 56
    f_bin_mf         = intarr(nn_bin_mf)   ;64ks/s channel 
    f_bin_mf[ 0:15]  = 1
    f_bin_mf[16:23]  = 2
    f_bin_mf[24:31]  = 4
    f_bin_mf[32:39]  = 8
    f_bin_mf[40:47]  = 16
    f_bin_mf[48:55]  = 32   
    nn_bin_hf        = 128
    f_bin_hf         = intarr(nn_bin_hf)   ;4Ms/s channel 
    f_bin_hf[ 0:47]  = 1
    f_bin_hf[48:71]  = 2
    f_bin_hf[72:95]  = 4
    f_bin_hf[96:119] = 8
    f_bin_hf[120:127]=16                                 ;mf and hf is the same
    dt_hsbm_lf       = 1./(2.^10)                                    ;1024 samples /sec
    dt_hsbm_mf       = 1./(2.^16)                                    ;~64k samples /sec
    dt_hsbm_hf       = 1./(2.^22)                                    ;~4M samples /sec
     ;-------------------------END: HSBM ---------------------------------------------
  
  
     ;-------------------------POWER SPECTRAS: unique information---------------------------------------------    
    ;pas/act specific
    nn_pa            = 64 ; number of sampels per subcycle   
    ;I cannot find this used yet, not yet included in lpw_const
    new_name_lf      = [1,2,4,8,16,32,64,128]                      ;pas_spec number of 1024 FFT's to ave together on E12_LF channel   ; table from ICD 7.12.3
    new_name_mf      = [1,2,4,8,16,32,64,128]                      ;pas_spec number of 1024 FFT's to ave together on E12_MF channel reserve   ; table from ICD 7.12.3
    new_name_hf      = [1,2,4,8,16,32,64,128]                      ;pas_spec number of 1024 FFT's to ave together on E12_HF channel reserve   ; table from ICD 7.12.3
    
    ;spectra specific
    nn_fft_size      = 1024d                                              ;number of points the fft in the FPGA work with, fix
    nn_fft_lf        =   1d                                               ;n_bins_spec: 1 ks/S = 56
    nn_fft_mf        =  64d                                               ;n_bins_spec: 64 ks/S = 56
    nn_fft_hf        =  4096d                                             ;n_bins_spec: 4 Ms/S = 128 
    power_scale_hf   = 1./16                          ;dt_hsbm_lf  ;^2    ;yscale  smallest value ->1 count level
    power_scale_mf   = 1./16                          ;dt_hsbm_mf ;^2     ;yscale smallest value ->1 count level
    power_scale_lf   = 1./16                          ;dt_hsbm_hf ;^2     ;yscale smallest value ->1 count level
    h_window         =  8./3.                         ;onboard window 
                                                      ; pre-define spectra frequency ranges in the fpga:
     center_freq_lf = 1.0*[.25,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16.5,18.5,20.5,22.5,24.5,26.5,28.5,30.5,$
                   33.5,37.5,41.5,45.5,49.5,53.5,57.5,61.5,67.5,75.5,83.5,91.5,99.5,107.5,115.5,123.5,$
                   135.5,151.5,167.5,183.5,199.5,215.5,231.5,247.4,271.5,303.5,335.5,367.5,399.5,431.5,$
                   463.5,495.5] 
  ;   f_low_mf=1.0*[10,32,96,160,224,288,352,416,480,544,608,672,736,800,864,928,992,1120,1248,1376,1504,1632, $  
  ;                 1760,1888,2016,2272,2528,2784,3040,3296,3552,3808,4064,4576,5088,5600,6112,6624,7136,7648,8160, $
  ;                 9184,10208,11232,12256,13280,14304,15328,16352,18400,20448,22496,24544,26592,28640,30688]
    center_freq_mf=1.0*[16,64,128,192,256,320,384,448,512,576,640,704,768,832,896,960,1056,1184,1312,1440,1568, $
                   1696,1824,1952,2144,2400,2656,2912,3168,3424,3680,3936,4320,4832,5344,5856,6368,6880,7392,7904, $
                   8672,9696,10720,11744,12768,13792,14816,15840,17376,19424,21472,23520,25568,27616,29664,31712]  
     center_freq_hf = 1.0*[1,4,8,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,$
                   112,116,120,124,128,132,136,140,144,148,152,156,160,164,168,172,176,180,184,188,194,202,210,$
                   218,226,234,242,250,258,266,274,282,290,298,306,314,322,330,338,346,354,362,370,378,390,406,422,438,$
                   454,470,486,502,518,534,550,566,582,598,614,630,646,662,678,694,710,726,742,758,782,814,846,878,$
                   910,942,974,1006,1038,1070,1102,1134,1166,1198,1230,1262,1294,1326,1358,1390,1422,1454,1486,1518,$
                   1566,1630,1694,1758,1822,1886,1950,2014]*nn_fft_size  
                   
      ;----------- NOTE! the low and high and center is also defined in the  calib_file_spec.txt and the values in the text file are the ones used ------           
                   
f_low_lf = 1.0*[0,.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5,11.5,12.5,13.5,14.5,15.5,17.5,19.5,21.5,23.5,$
  25.5,27.5,29.5,31.5,35.5,39.5,43.5,47.5,51.5,55.5,59.5,63.5,71.5,79.5,87.5,95.5,103.5,111.5,$
  119.5,127.5,143.5,159.5,175.5,191.5,207.5,223.5,239.5,255.5,287.5,319.5,351.5,383.5,415.5,$
  447.5,479.5]
  
f_high_lf = 1.0*[.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5,11.5,12.5,13.5,14.5,15.5,17.5,19.5,21.5,23.5,$
  25.5,27.5,29.5,31.5,35.5,39.5,43.5,47.5,51.5,55.5,59.5,63.5,71.5,79.5,87.5,95.5,103.5,111.5,$
  119.5,127.5,143.5,159.5,175.5,191.5,207.5,223.5,239.5,255.5,287.5,319.5,351.5,383.5,415.5,$
  447.5,479.5,511.5]
  
f_low_mf=1.0*[0,32,96,160,224,288,352,416,480,544,608,672,736,800,864,928,992,1120,1248,1376,1504,1632, $
  1760,1888,2016,2272,2528,2784,3040,3296,3552,3808,4064,4576,5088,5600,6112,6624,7136,7648,8160, $
  9184,10208,11232,12256,13280,14304,15328,16352,18400,20448,22496,24544,26592,28640,30688]
  
f_high_mf=1.0*[32,96,160,224,288,352,416,480,544,608,672,736,800,864,928,992,1120,1248,1376,1504,1632, $
  1760,1888,2016,2272,2528,2784,3040,3296,3552,3808,4064,4576,5088,5600,6112,6624,7136,7648,8160, $
  9184,10208,11232,12256,13280,14304,15328,16352,18400,20448,22496,24544,26592,28640,30688,32736]
  
f_low_hf = 1.0*[0,2,6,10,14,18,22,26,30,34,38,42,46,50,54,58,62,66,70,74,78,82,86,90,94,98,102,106,110,114,118,122,126,130,$
  134,138,142,146,150,154,158,162,166,170,174,178,182,186,190,198,206,214,222,230,238,246,254,262,$
  270,278,286,294,302,310,318,326,334,342,350,358,366,374,382,398,414,430,446,462,478,494,510,526,$
  542,558,574,590,606,622,638,654,670,686,702,718,734,750,766,798,830,862,894,926,958,990,1022,$
  1054,1086,1118,1150,1182,1214,1246,1278,1310,1342,1374,1406,1438,1470,1502,1534,1598,1662,1726,$
  1790,1854,1918,1982]*nn_fft_size
  
f_high_hf = 1.0*[2,6,10,14,18,22,26,30,34,38,42,46,50,54,58,62,66,70,74,78,82,86,90,94,98,102,106,110,114,118,122,126,130,$
  134,138,142,146,150,154,158,162,166,170,174,178,182,186,190,198,206,214,222,230,238,246,254,262,$
  270,278,286,294,302,310,318,326,334,342,350,358,366,374,382,398,414,430,446,462,478,494,510,526,$
  542,558,574,590,606,622,638,654,670,686,702,718,734,750,766,798,830,862,894,926,958,990,1022,$
  1054,1086,1118,1150,1182,1214,1246,1278,1310,1342,1374,1406,1438,1470,1502,1534,1598,1662,1726,$
  1790,1854,1918,1982,2046]*nn_fft_size
                    
      ;----------- 
   
   f_zero_freq0 = 1./1.                                                          ;This is what was needed on MMS to correct for too much power in 0-bin from FPGA algorithm                                     
                                                                                 ; is the FPGA code corrected such that all power is not dumped in the zero bin? 
                                                                                 ;print,'(mvn_lpw_spectra )  Check with Max what and if we need to correct the first bin!!!' 
 f_zero_freq_lf=1./(f_high_lf[0]-f_low_lf[0])                                ;1./df_0   for FFT value = constant* amp_resp* POWER */zero_freq *power_scale*h_window   20141212 LA
 f_zero_freq_mf=1./(f_high_mf[0]-f_low_mf[0])                                ;1./df_0   for FFT value = constant* amp_resp* POWER */zero_freq *power_scale*h_window   20141212 LA
 f_zero_freq_hf=1./(f_high_hf[0]-f_low_hf[0])                                ;1./df_0   for FFT value = constant* amp_resp* POWER */zero_freq *power_scale*h_window   20141212 LA      
                                       
     calib_file_spec=['mvn_lpw_cal_spec_141009_v1.txt']   ; the file needs to be located with the mvn_lpw-procedures to be found      
     
    ;-------------------------END: POWER SPECTRAS---------------------------------------------
   
     
    ;------------------------- EUV  unique information ---------------------------------------------
    ;euv specific
    nn_euv         = 16                                      ;number of samples in one package (constant, not associated with the subcycle period)
    nn_euv_diodes  = 4                                       ;number of diodes   
    dt_euv         = double(1.0)                                     ;sampling rate [sec]   this is only valid for normal operations.....check the number of points averaged....
    
    ;euv_temp=1.0                                            ; conversion number to be identified, start number  
    ;from David Summers 2012 July
    ;If you take the 20 bit temperature data and divide it by 16 to get 16 bit numbers, the numbers should follow the following conversion:
    ;Temp_in_DN(16 bit) = 41.412 x Temp_in_deg_C - 8160.7
    euv_temp       = [1.0/16 ,  8160.7,  41.412]               ; (measured *  euv_temp(0) +   euv_temp(1)) /euv_temp(2)  = Temp_in_deg_C
    
    ;the different calibration values for the four diodes and the field of view will be in a ascii file
    ;here keep track of the file name and send the file name forward.
    
    euv_diod_A     = 1.0                                       ; conversion number to be identified, start number  
    euv_diod_B     = 1.0                                       ; conversion number to be identified, start number  
    euv_diod_C     = 1.0                                       ; conversion number to be identified, start number  
    euv_diod_D     = 1.0                                       ; conversion number to be identified, start number      
    calib_file_euv = ['mvn_lpw_calibration_file_euv_131101_v1.txt']    ; the file needs to be located with the mvn_lpw-procedures to be found      
    
     ;-------------------------END: EUV---------------------------------------------
   
   
   ;-------------------- EEPROM LOADs ---------------------------
  
  eeprom=[ $ 
   ['2012-08-01','2013-06-26','PF_EEPROM_LPW_v1.0'] , $ 
   ['2013-06-27','2014-10-05','PF_EEPROM_LPW_v2.0'] , $
   ['2014-10-06','2040-01-01','PF_EEPROM_LPW_v2.3']]
 
  eeprom_monopol=[['PF_EEPROM_LPW_v1.0','na'], $   ;  means no mode  ,use the same order as above!
                  ['PF_EEPROM_LPW_v2.0','8'], $
                  ['PF_EEPROM_LPW_v2.3','8']]
 
   ;-----------------------------------------------
  
    ;------------------------- CDF-production  unique information ---------------------------------------------
           
     
     ;Redo arrays:
     cdf_istp_lpw=strarr(14)  ;Have left a dummy entry whilst editing all PKT routines, to avoid crashes with wrong sized array.
     cdf_istp_lpw[0] =  'MAVEN>Mars Atmosphere And Volatile EvolutioN Mission'         ;  Global ISTP required attribute 'Source_name'
     cdf_istp_lpw[1] =  'Planetary Physics>Particles and fields'                       ;  Global ISTP required attribute 'Discipline'
     cdf_istp_lpw[2] =  'Electric Fields (space), plasma and solar wind'                ;  Global ISTP required attribute 'Instrument_type'
     cdf_istp_lpw[3] =  'CAL>calibrated'                                               ;  Global ISTP required attribute 'Data_type'
     cdf_istp_lpw[4] =  version_calib_routine                                           ;  Global ISTP required attribute 'Data_version'
     cdf_istp_lpw[5] = 'LPW>Langmuir Probe and Waves'                                                           ; 'Descriptor'
     cdf_istp_lpw[6] =  'Data production PI: L. Andersson, LASP/CU'                     ;  Global ISTP required attribute 'PI_name'
     cdf_istp_lpw[7] =  'LASP University of Colorado'                                   ;  Global ISTP required attribute 'PI_affiliation'
     cdf_istp_lpw[8] =  'Langmuir Probe and Waves (LPW) measurements of electron density and temperature in ionosphere.'+$
       ' Also spectral power density of waves in Mars ionosphere. NEED REFERENCE TO PAPER.'           ;  Global ISTP required attribute 'TEXT'
   
   ;above get reference to papaer
   
   
     cdf_istp_lpw[9] =  'MAVEN>Mars Atmosphere And Volatile EvolutioN Mission'                                                         ;  Global ISTP required attribute 'Mission_group'
     cdf_istp_lpw[10] = 'LPW/LASP/CU'                                    ;  Global ISTP required attribute 'generated_by'
     cdf_istp_lpw[11] = 'http://lasp.colorado.edu/home/maven/science/'                               ; web link to be inserted
     cdf_istp_lpw[12] = 'MAVEN project'                                                 ; project
     cdf_istp_lpw[13] ='Andersson, L., R. E. Ergun, G. T. Delory, A. Eriksson, J. Westfall,  '+ $
      'H. Reed, J. McCauly, D. Summers, and D. Meyers (2015), ' + $
      'The langmuir probe and waves (lpw) instrument for MAVEN, SPAC-D-14-00089R1, Space Science Review.'                        ;Acknowledgement

; get acknowlwejghghdfgzhi/k

     cdf_istp_euv=strarr(14)
     cdf_istp_euv[0] = 'MAVEN>Mars Atmosphere And Volatile EvolutioN Mission'        ;  Global ISTP required attribute 'Source_name'
     cdf_istp_euv[1] = 'Planetary Physics>Particles and fields'                      ;  Global ISTP required attribute 'Discipline'
     cdf_istp_euv[2] = 'Gamma and X-Rays'                                             ;  Global ISTP required attribute 'Instrument_type'
     cdf_istp_euv[3] = 'CAL>calibrated'                                              ;  Global ISTP required attribute 'Data_type'
     cdf_istp_euv[4] =  version_calib_routine                                         ;  Global ISTP required attribute 'Data_version'
     cdf_istp_euv[5] = 'EUV>Extreme Ultraviolet'                                                         ; 'Descriptor'
     cdf_istp_euv[6] = 'Data production PI: F. Eparvier, LASP/CU'                     ;  Global ISTP required attribute 'PI_name'
     cdf_istp_euv[7] = 'LASP University of Colorado'                                  ;  Global ISTP required attribute 'PI_affiliation'
     cdf_istp_euv[8] = 'Extreme Ultra Violet (EUV) observations of solar irradiation in 3 band pass wavelengths. NEED REFERENCE TO PAPER.'  ;Global ISTP required attribute 'TEXT'
     cdf_istp_euv[9] = 'MAVEN>Mars Atmosphere And Volatile EvolutioN Mission'                                                        ;  Global ISTP required attribute 'Mission_group'
     cdf_istp_euv[10] = 'LPW/LASP/CU'                                               ;  Global ISTP required attribute 'generated_by'
     cdf_istp_euv[11] = 'http://lasp.colorado.edu/home/maven/science/'                             ; web link to be inserted
     cdf_istp_euv[12] = 'MAVEN project'                                               ; project
     cdf_istp_euv[13] = 'CITE for data reference'                            ;Acknowledgement
  
    ;------------------------- CDF: END ---------------------------------------------
      
       
    
;------------- Put the information into a structure: LPW_const,LPW_const2 -------------

if 'yes' EQ 'yes' then $  ;since variables iare removed for FM the structure below is the one working now
lpw_const=create_struct(   $                                     ;To export the data in workable form
   'today_date',                 today_date, $                   ;string
   'version_calib_routine',      version_calib_routine, $        ;float  
   't_epoch',                   t_epoch,  $
   't_epoch_expected',          t_epoch_expected,$
   'sign',                      const_sign, $
   'sc_lngth',                  subcycle_length,$ 
   'sample_aver',               sample_aver,$
   'nn_modes',                  nn_modes ,$ 
   'nn_dac',                    nn_dac,$
   'nn_pa',                     nn_pa,$
   'nn_swp',                    nn_swp,$  
   'nn_swp_steps',              nn_swp_steps,$ 
   'nn_active_steps',           nn_active_steps,$
   'nn_hsbm_lf',                nn_hsbm_lf,$
   'nn_hsbm_mf',                nn_hsbm_mf, $
   'nn_hsbm_hf',                nn_hsbm_hf, $
   'nn_bin_lf',                 nn_bin_lf, $
   'nn_bin_mf',                 nn_bin_mf, $
   'nn_bin_hf',                 nn_bin_hf, $
   'nn_fft_size',               nn_fft_size,$  
   'nn_fft_lf',                 nn_fft_lf,$  
   'nn_fft_mf',                 nn_fft_mf,$  
   'nn_fft_hf',                 nn_fft_hf,$    
   'nn_euv',                    nn_euv, $
   'nn_euv_diodes',             nn_euv_diodes, $
   'hsk_temp',                  const_hsk_temp, $
   'hsk_voltage',               const_hsk_voltage, $
   'hsk_misc',                  const_hsk_misc, $
   'inst_phys',                 inst_phys,$
   'sensor_distance',           sensor_distance, $
   'boom_shortening',           boom_shorting_factor, $ 
   'lp_bias1_DAC',              const_lp_bias1_DAC, $
   'w_bias1_DAC',               const_w_bias1_DAC, $
   'lp_guard1_DAC',             const_lp_guard1_DAC, $
   'w_guard1_DAC',              const_w_guard1_DAC, $  
   'lp_stub1_DAC',              const_lp_stub1_DAC, $
   'w_stub1_DAC',               const_w_stub1_DAC, $       
   'lp_bias2_DAC',              const_lp_bias2_DAC, $
   'w_bias2_DAC',               const_w_bias2_DAC, $
   'lp_guard2_DAC',             const_lp_guard2_DAC, $
   'w_guard2_DAC',              const_w_guard2_DAC, $  
   'lp_stub2_DAC',              const_lp_stub2_DAC, $
   'w_stub2_DAC',               const_w_stub2_DAC, $     
   'I1_readback',               const_I1_readback, $
   'V1_readback',               const_V1_readback, $ 
   'bias1_readback',            const_bias1_readback, $
   'guard1_readback',           const_guard1_readback, $
   'stub1_readback',            const_stub1_readback, $
   'I2_readback',               const_I2_readback, $
   'V2_readback',               const_V2_readback, $ 
   'bias2_readback',            const_bias2_readback, $
   'guard2_readback',           const_guard2_readback, $
   'stub2_readback',            const_stub2_readback, $ 
   'const_epsilon1',            const_epsilon1, $ 
   'const_epsilon2',            const_epsilon2, $ 
   'boom1_corr',                boom1_corr, $
   'boom2_corr',                boom2_corr, $
   'e12_corr',                  e12_corr, $
   'e12_lf_corr',               e12_lf_corr, $
   'e12_mf_corr',               e12_mf_corr, $
   'e12_hf_corr',               e12_hf_corr, $
   'E12_lf',                    const_E12_lf, $   
   'E12_mf',                    const_E12_mf, $  
   'E12_hf',                    const_E12_hf, $ 
   'E12_hf_hg',                 const_E12_HF_HG,$ 
   'f_bin_lf',                  f_bin_lf,$
   'f_bin_mf',                  f_bin_mf, $  
   'f_bin_hf',                  f_bin_hf, $
   'h_window',                  h_window, $
   'f_zero_freq_lf' ,              f_zero_freq_lf, $
   'f_zero_freq_mf' ,              f_zero_freq_mf, $
   'f_zero_freq_hf' ,              f_zero_freq_hf, $
   'f_zero_freq0' ,              f_zero_freq0, $
   'power_scale_lf',            power_scale_lf,$  
   'power_scale_mf',            power_scale_mf,$  
   'power_scale_hf',            power_scale_hf,$  
   'center_freq_lf',            center_freq_lf,$  
   'center_freq_mf',            center_freq_mf ,$  
   'center_freq_hf',            center_freq_hf,$  
   'f_low_freq_lf',             f_low_lf,$  
   'f_low_freq_mf',             f_low_mf ,$  
   'f_low_freq_hf',             f_low_hf,$  
   'f_high_freq_lf',            f_high_lf,$  
   'f_high_freq_mf',            f_high_mf ,$  
   'f_high_freq_hf',            f_high_hf,$  
   'dt_hsbm_lf',                dt_hsbm_lf ,$                               
   'dt_hsbm_mf',                dt_hsbm_mf ,$                               
   'dt_hsbm_hf',                dt_hsbm_hf ,$                                  
   'dt_euv',                    dt_euv, $                     ;number of points per package
   'euv_diod_A',                euv_diod_A, $
   'euv_diod_B',                euv_diod_B, $
   'euv_diod_C',                euv_diod_C, $
   'euv_diod_D',                euv_diod_D, $
   'euv_temp',                  euv_temp, $
   'calib_file_euv',            calib_file_euv ,$
   'calib_file_spec',           calib_file_spec, $
   'calib_file_iv',             calib_file_iv, $
   'cdf_istp_euv',              cdf_istp_euv, $
   'cdf_istp_lpw',              cdf_istp_lpw, $
   'tplot_char_size',           tplot_char_size)



 if 'yes' EQ 'no' then $  ;since variables iare removed for FM the structure below is the one working now
lpw_const=create_struct(   $                                     ;To export the data in workable form
   'today_date',                 today_date, $                   ;string
   'version_calib_routine',      version_calib_routine, $        ;float  
   't_epoch',                   t_epoch,  $
   't_epoch_expected',          t_epoch_expected,$
   'sign',                      const_sign, $
   'sc_lngth',                  subcycle_length,$ 
   'sample_aver',               sample_aver,$
   'nn_modes',                  nn_modes ,$ 
   'nn_dac',                    nn_dac,$
   'nn_pa',                     nn_pa,$
   'nn_swp',                    nn_swp,$  
   'nn_swp_steps',              nn_swp_steps,$ 
   'nn_active_steps',           nn_active_steps,$
   'nn_hsbm_lf',                nn_hsbm_lf,$
   'nn_hsbm_mf',                nn_hsbm_mf, $
   'nn_hsbm_hf',                nn_hsbm_hf, $
   'nn_bin_lf',                 nn_bin_lf, $
   'nn_bin_mf',                 nn_bin_mf, $
   'nn_bin_hf',                 nn_bin_hf, $
   'nn_fft_size',               nn_fft_size,$  
   'nn_fft_lf',                 nn_fft_lf,$  
   'nn_fft_mf',                 nn_fft_mf,$  
   'nn_fft_hf',                 nn_fft_hf,$    
   'nn_euv',                    nn_euv, $
   'nn_euv_diodes',             nn_euv_diodes, $
   'hsk_temp',                  const_hsk_temp, $
   'hsk_voltage',               const_hsk_voltage, $
   'hsk_misc',                  const_hsk_misc, $
   'inst_phys',                 inst_phys,$
   'sensor_distance',           sensor_distance, $
   'boom_shortening',           boom_shorting_factor, $ 
   'I1_readback',               const_I1_readback, $
   'V1_readback',               const_V1_readback, $ 
   'I2_readback',               const_I2_readback, $
   'V2_readback',               const_V2_readback, $ 
   'const_epsilon1',            const_epsilon1, $ 
   'const_epsilon2',            const_epsilon2, $ 
   'boom1_corr',                boom1_corr, $
   'boom2_corr',                boom2_corr, $
   'e12_corr',                  e12_corr, $
   'e12_lf_corr',               e12_lf_corr, $
   'e12_mf_corr',               e12_mf_corr, $
   'e12_hf_corr',               e12_hf_corr, $
   'E12_lf',                    const_E12_lf, $   
   'E12_mf',                    const_E12_mf, $  
   'E12_hf',                    const_E12_hf, $ 
   'E12_hf_hg',                 const_E12_HF_HG,$ 
   'f_bin_lf',                  f_bin_lf,$
   'f_bin_mf',                  f_bin_mf, $  
   'f_bin_hf',                  f_bin_hf, $  
   'h_window',                  h_window, $
   'f_zero_freq_lf' ,              f_zero_freq_lf, $
   'f_zero_freq_mf' ,              f_zero_freq_mf, $
   'f_zero_freq_hf' ,              f_zero_freq_hf, $
   'f_zero_freq0' ,              f_zero_freq0, $
   'power_scale_lf',            power_scale_lf,$  
   'power_scale_mf',            power_scale_mf,$  
   'power_scale_hf',            power_scale_hf,$  
   'center_freq_lf',            center_freq_lf,$  
   'center_freq_mf',            center_freq_mf ,$  
   'center_freq_hf',            center_freq_hf,$  
   'dt_hsbm_lf',                dt_hsbm_lf ,$                               
   'dt_hsbm_mf',                dt_hsbm_mf ,$                               
   'dt_hsbm_hf',                dt_hsbm_hf ,$                                  
   'dt_euv',                    dt_euv, $                     ;number of points per package
   'euv_diod_A',                euv_diod_A, $
   'euv_diod_B',                euv_diod_B, $
   'euv_diod_C',                euv_diod_C, $
   'euv_diod_D',                euv_diod_D, $
   'euv_temp',                  euv_temp, $
   'calib_file_euv',            calib_file_euv ,$
   'calib_file_spec',           calib_file_spec, $
   'calib_file_iv',             calib_file_iv, $
   'cdf_istp_euv',              cdf_istp_euv, $
   'cdf_istp_lpw',              cdf_istp_lpw, $
   'eeprom',                    eeprom , $
   'eeprom_monopol',            eeprom_monopol, $
   'tplot_char_size',           tplot_char_size)

    
   lpw_const2=lpw_const 
end

;*********************************************************************************

