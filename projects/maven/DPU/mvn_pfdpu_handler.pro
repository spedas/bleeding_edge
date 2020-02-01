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
;    -9.25E-20 7.91E-15  -2.59E-10 4.04E-06  -3.37E-02 168.28
   par_temp = mvn_sep_therm_temp2()
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
       REG_STemp:  func(par=par_temp,data[7] * 2.5/ 2L^15)   ,$  
       REG_TEMP: mav_pfdpu_analog_conversion( (data[7]*2.5/2d^15),coeff=tcoeff), $
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
           dprint,str,dlevel=3
           store_data,/append,'mvn_pfdpu_EVENT_ACT_NOTE',ap24.time,str,dlimit={tplot_routine:'strplot'}
        end
    else:
   endcase
   return,ap24
end




pro mvn_pfdpu_var_save,filename,pathname=pathname,trange=trange,prereq_info=prereq_info,verbose=verbose,description=description
  @mvn_pfdpu_handler_commonblock.pro
  ;common mvn_apid_misc_handler_com   ,manage,realtime,apid20x,apid21x,apid22x,apid23x,apid24x,apid25x   ; from mvn_pfdpu_handler

  if not keyword_set(filename) then begin
    if not keyword_set(trange) then trange = minmax((*(apid20x.x)).time)
    res = 86400.d
    days =  round( time_double(trange )/res)
    ndays = days[1]-days[0]
    tr = days * res
    if not keyword_set(pathname) then pathname =  'maven/pfp/dpu/l1/sav/YYYY/MM/mvn_dpu_l1_$NDAY_YYYYMMDD.sav'
    pn = str_sub(pathname, '$NDAY', strtrim(ndays,2)+'day')
    filename = mvn_pfp_file_retrieve(pn,/daily,trange=tr[0],source=source,verbose=verbose,/create_dir)
    dprint,dlevel=2,verbose=verbose,'Creating: ',filename
  endif

  if 1 then begin
    spice_kernels = spice_test('*')
    dependents = file_checksum(/add_mtime,spice_kernels)

    if keyword_set(apid20x) then ap20 = *apid20x.x
    if keyword_set(apid21x) then ap21 = *apid21x.x
    if keyword_set(apid22x) then ap22 = *apid22x.x
    if keyword_set(apid23x) then ap23 = *apid23x.x
    if keyword_set(apid24x) then ap24 = *apid24x.x
    if keyword_set(apid25x) then ap25 = *apid25x.x

    save,filename=filename,verbose=verbose,dependents,ap20,ap21,ap22,ap23,ap24,ap25,description=description
  endif 
end






pro mvn_pfdpu_handler,ccsds,decom=decom,reset=reset,clear=clear,set_realtime=set_realtime,debug=debug,finish=finish, $
    hkp_tags=hkp_tags,shkp_tags=shkp_tags,oper_tags=oper_tags,lowres=lowres

@mvn_pfdpu_handler_commonblock.pro
;common mvn_apid_misc_handler_com,manage,realtime,apid20x,apid21x,apid22x,apid23x,apid24x,apid25x

    if not keyword_set(ccsds) then begin
        if n_elements(reset) ne 0 then begin
           manage = reset
           clear = keyword_set(reset)
        endif
        if n_elements(set_realtime) ne 0 then realtime=set_realtime
        if keyword_set(debug) then begin
           dprint,phelp=debug,manage,realtime,apid20x,apid21x,apid22x,apid23x,apid24x,apid25x
           return
        endif
        dprint,dlevel=2,'PFDPU handler ' ,keyword_set(clear) ? 'Clearing' : ''
        prefix='mvn_
        if keyword_set(lowres) then begin
          prefix='mvn_5min_'
          if lowres eq 2 then prefix='mvn_01hr_' 
        endif
        if keyword_set(finish) then begin
           if ~keyword_set(hkp_tags) then hkp_tags='*TEMP PFPP28V *28I'
           if ~keyword_set(shkp_tags) then shkp_tags='ACT*'
           if ~keyword_set(oper_tags) then oper_tags='ACT*'        
        endif
        mav_gse_structure_append, clear=clear,  apid20x,   tname=prefix+'pfdpu_shkp', tags=shkp_tags
        mav_gse_structure_append, clear=clear,  apid21x,   tname=prefix+'pfdpu_oper', tags=oper_tags
        mav_gse_structure_append, clear=clear,  apid22x,   tname=prefix+'apid22x'
        mav_gse_structure_append, clear=clear,  apid23x,   tname=prefix+'pfdpu_hkp',  tags=hkp_tags
        mav_gse_structure_append, clear=clear,  apid24x,   tname=prefix+'pfdpu_event'
;        mav_gse_structure_append, clear=clear,  apid25x,   tname='apid25x'
        return
    endif
    if not keyword_set(manage) then return
    dl = 3
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
