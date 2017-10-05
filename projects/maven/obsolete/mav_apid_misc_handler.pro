this file is obsolete and should not be called or compiled


function mav_pfdpu_analog_conversion,x, coeff=coeff
;    tcoeff = [-1.1843E-10,  5.85479E-08,  -1.19147E-05, 1.28754E-03,  -7.9487E-02, 2.80015E+00,  -5.31694E+01, 4.83957E+02]
    temp = 0.d
    for i = 0,n_elements(coeff)-1 do  temp = temp * x + coeff[i]
    return,temp
end


function mav_pfdpu_23x_decom,ccsds
     
     data = fix(ccsds.data,0,n_elements(ccsds.data)/2)  & byteorder,data,/swap_if_little_endian
     dl=2
;     dprint,dlevel=dl,'APID ', ccsds.apid,ccsds.seq_cntr,ccsds.size,format='(a,z02,i,i)'
;     hexprint,data
    tcoeff = [-1.1843E-10,  5.85479E-08,  -1.19147E-05, 1.28754E-03,  -7.9487E-02, 2.80015E+00,  -5.31694E+01, 4.83957E+02]
    tcoeff = [-1.1843E-10,  5.85479E-08,  -1.19147E-05, 1.28754E-03,  -7.9487E-02, 2.80015E+00,  -5.31694E+01, 7.83957E+01]
   par_temp = mav_sep_therm_temp2()
   par_temp.r1 = 10000.
   par_temp.rv = 1e9
   par_temp.xmax = 2.5

    valid = 1
    
    if ccsds.size ne 60 then begin
        dprint,dlevel=3,"Bad APID 23x size:",ccsds.size            ; this seems to occur in version 2.0 but not 2.5
        valid = 0
    endif 

    pfdpu = {  $
       time: ccsds.time,$
       time_diff: ccsds.time_diff, $
       Analog_RAW : data[0:24], $
       PFPN5AV    : mav_pfdpu_analog_conversion( (data[0]),coeff=[0.000305d,0]), $
       PFPP5AV    : mav_pfdpu_analog_conversion( (data[1]),coeff=[0.000305d,0]), $
       PFPP5DV    : mav_pfdpu_analog_conversion( (data[2]),coeff=[0.000305d,0]), $
       PFPP3P3DV  : mav_pfdpu_analog_conversion( (data[3]),coeff=[0.000201d,0]), $
       PFPP1P5DV  : mav_pfdpu_analog_conversion( (data[4]),coeff=[0.000092d,0]), $
       PFPP28V    : mav_pfdpu_analog_conversion( (data[5]),coeff=[0.001709d,0]), $
       SWE28I     : mav_pfdpu_analog_conversion( (data[6]),coeff=[0.002703d,0]), $
 ;      PFPRegT    : mav_pfdpu_analog_conversion( (data[7]),coeff=[1d,0]), $
       SWI28I     : mav_pfdpu_analog_conversion( (data[8]),coeff=[0.005450d,0]), $
       STA28I     : mav_pfdpu_analog_conversion( (data[9]),coeff=[0.011357d,0]), $
       MAG128I    : mav_pfdpu_analog_conversion( (data[10]),coeff=[0.003095d,0]), $
       MAG228I    : mav_pfdpu_analog_conversion( (data[11]),coeff=[0.003095d,0]), $
       SEP28I     : mav_pfdpu_analog_conversion( (data[12]),coeff=[0.004883d,0]), $
       LPW28I     : mav_pfdpu_analog_conversion( (data[13]),coeff=[0.011967d,0]), $
       PFP28OPV   : mav_pfdpu_analog_conversion( (data[14]),coeff=[0.001709d,0]), $
       PFP28OPI   : mav_pfdpu_analog_conversion( (data[15]),coeff=[0.005864d,0]), $
 ;      PFPDCBT    : mav_pfdpu_analog_conversion( (data[16]),coeff=[1d,0]), $
 ;      PFPFPGAT   : mav_pfdpu_analog_conversion( (data[17]),coeff=[1d,0]), $
       PFPFlash0V : mav_pfdpu_analog_conversion( (data[18]),coeff=[0.000201d,0]), $
       PFPFlash1V : mav_pfdpu_analog_conversion( (data[19]),coeff=[0.000201d,0]), $
       PFP3P3DV   : mav_pfdpu_analog_conversion( (data[20]),coeff=[0.000201d,0]), $
       PFP1P5DC   : mav_pfdpu_analog_conversion( (data[21]),coeff=[0.000092d,0]), $
       PFPVREF    : mav_pfdpu_analog_conversion( (data[22]),coeff=[0.000153d,0]), $
       PFPAGND    : mav_pfdpu_analog_conversion( (data[23]),coeff=[0.0001d,0]), $
       spare      : mav_pfdpu_analog_conversion( (data[24]),coeff=[1.d,0]), $
      
;       PFP28V: mav_pfdpu_analog_conversion( (data[7]),coeff=[.001709d,0]), $
;       PFP28OPV: mav_pfdpu_analog_conversion( (data[14]),coeff=[.001709d,0]), $
;       PFP28OPI: mav_pfdpu_analog_conversion( (data[15]),coeff=[.005864d,0]), $
       REG_Temp:  func(par=par_temp,data[7] * 2.5/ 2L^15)   ,$  ; mav_pfdpu_analog_conversion( (data[7]*2.5/2d^15),coeff=tcoeff), $
       DCB_Temp: mav_pfdpu_analog_conversion( (data[16]*2.5/2d^15),coeff=tcoeff), $
       FPGA_Temp: mav_pfdpu_analog_conversion( (data[17]*2.5/2d^15),coeff=tcoeff), $
 ;      SEP28I : data[12] * .004883 , $
       valid:valid }
       
   return,pfdpu
end

function mav_pfdpu_20x_decom,ccsds   ;  apid20
;   dprint,'ap21',dlevel=4
   data2 = uint(ccsds.data,0,(448-80)/16)  & byteorder,data2,/swap_if_little_endian
   data1 = byte(ccsds.data,0,(448-80)/8)
   ap21={time:ccsds.time ,$
       SEQ_CNTR: ccsds.seq_cntr, $
       PFP_ENABLE_FLAG:  data2[(112-80)/16] , $
       act_pwrcntrl_flag:  data1[(368-80)/8] $ 
   }
   return,ap21
end

function mav_pfdpu_21x_decom,ccsds   ; OPER Housekeeping
;   dprint,'ap21',dlevel=4
   data2 = uint(ccsds.data,0,9)  & byteorder,data2,/swap_if_little_endian
   data1 = byte(ccsds.data,0,18)
   ap21={time:ccsds.time ,$
       act_request_flag:  data2[4]  , $
       act_status_flag: data2[5]    , $
       act_ISR_flag:   data1[13]  $
   }
   return,ap21
end

function mav_pfdpu_24x_decom,ccsds   ; EVENT messages 
;   dprint,'ap24',dlevel=4
   ap24={time:ccsds.time ,$
       cntr: ccsds.data[0] * 256u +ccsds.data[1] ,$
       code: ccsds.data[6]  }
       
   case ap24.code of
   'A0'x : begin
           act = ccsds.data[7]
           s = (ccsds.data[8] and '80'x) ne 0
           duration = (ccsds.data[8] and '7f'x) * 256u +ccsds.data[9]
           str = string(act,s,duration,format='("Act",i2,i2,i4)')
           dprint,str,dlevel=1
           store_data,/append,'PFDPU_EVENT_ACT_NOTE',ap24.time,str,dlimit={tplot_routine:'strplot'}
        end
    else:
   endcase
   return,ap24
end



pro mav_apid_misc_handler,ccsds,decom=decom,reset=reset   ;,realtime=realtime

common mav_apid_misc_handler_com,manage,realtime,apid20x,apid21x,apid22x,apid23x,apid24x,apid25x
    if n_elements(reset) ne 0 then begin
        manage = reset
        realtime=1
        return
    endif
    if not keyword_set(manage) then return
    if not keyword_set(ccsds) then return

    dl = 4
    Case ccsds.apid of
      '20'x: mav_gse_structure_append  ,apid20x, realtime=realtime, tname='PFDPU_SHKP',mav_pfdpu_20x_decom(ccsds) ; Slow Housekeeping
      '21'x: mav_gse_structure_append  ,apid21x, realtime=realtime, tname='PFDPU_OPER',mav_pfdpu_21x_decom(ccsds) ; OPER (actuator stuff)
      '22'x: dprint,dlevel=dl,'APID ', ccsds.apid,ccsds.seq_cntr,ccsds.size,format='(a,z02,i,i)'  ; Memory dump  -  Not used much
      '23'x: mav_gse_structure_append  ,apid23x, realtime=realtime, tname='PFDPU_HKP',mav_pfdpu_23x_decom(ccsds)
      '24'x: mav_gse_structure_append  ,apid24x, realtime=realtime, tname='PFDPU_EVENT',mav_pfdpu_24x_decom(ccsds)
;      '24'x: dprint,dlevel=dl,'APID ', ccsds.apid,ccsds.seq_cntr,ccsds.size,format='(a,z02,i,i)'  ; Events
       else: return    ; Do nothing if not a recognized packet
    endcase 
    decom = 1

end
