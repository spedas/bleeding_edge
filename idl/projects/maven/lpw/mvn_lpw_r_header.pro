;+
;PROCEDURE:   mvn_lpw_r_header
;PURPOSE:
;  Decomutater of the LPW telemetry data, this is the old mvn_lpw_r_header THIS IS NOT WORKING ON L0-files
;          r_header orignal written by Corinne Vanatta and David Meyer;          
;          This routine reads the data file as WORD
; This routine strips the packet headers off the data, and stores the data in various ways.
; The data is stored in one long structure 
; The routine also prints out how many of each tpye of packet are present in the file.
; filename: the name of the file the data is in
; output:   this is a dummy variable input, but output holds all the data for
;           the subsequent plotting routines
; samplerate: Sample rate in Hz. Used to get time, as well as units on subsequent plots  
;  
;USAGE:
;  mvn_lpw_r_header, filename, output,strip_pad = strip_pad, wrapper = wrapper, compressed=compressed, packet=packet
;
;INPUTS:
;       filename:      The full filename (including path) of a binary file containing 
;                      zero or more LPW APID's.  
;
;KEYWORDS:
;       strip_pad:  Default? -not in use ?? test purpuses 
;       wrapper:    Default? -not in use ?? test purpuses
;       compressed: Default compressed. For test purpuses the data stream can be uncompressed by the FPGA.
;       packet:     Which packets to read into memeory, default all packets Options: ['HSK','EUV','AVG','SPEC','HSBM','WPK']  
;
;CREATED BY:   Laila Andersson  06-01-11
;FILE: mvn_lpw_r_header.pro
;VERSION:   2.0
;LAST MODIFICATION:   04/20/13
; ;140718 clean up for check out L. Andersson
;-

pro mvn_lpw_r_header, filename,output,strip_pad = strip_pad, wrapper = wrapper, compressed=compressed,packet=packet


    t_start=SYSTIME(1,/seconds)                                            ;to check on speed
    t1=SYSTIME(1,/seconds)                  
    tmp=strsplit(filename,'/',/extract)                                ; should be mac way
    if n_elements(tmp) EQ 1 then tmp=strsplit(filename,'\',/extract)   ; should be PC way
    filename_short  =tmp(n_elements(tmp)-1)                            ; this is the name that is stored in the CDF file, the directory information is not of interest only the file name 
    print,'lpw_loader filename ',filename,' short ', filename_short
    
    newfile_unsigned = read_binary(filename, data_type = 12,endian='big')
    newfile_signed   = read_binary(filename, data_type = 2,endian='big')    ;can I get rid of this? used in ATR, EUV, ADR ...more?
    ;newfile_byte     = read_binary(filename, data_type = 1,endian='big')   ;can I get rid of this?; can we change this so only the byte is used???

   ;this is to make quick conversions later on 
     mvn_lpw_r_mask,mask16,mask8,bin_c,index_arr,flip_8 
     
    size_file = size(newfile_unsigned)    ;is this one used
    samplerate = samplerate
    concatention = 'on'  

    ;--------------------------------------------------------------------
    If (keyword_set(compressed)) Then compression = 'on' Else compression = 'off'
                                                                            ; this so that only a group of packets is selected and stored
    If(keyword_set(wrapper)) Then place = 3 Else place = 1   ;0/3 for SSL 1/4 for LASP
    place         = 0; -- permanently set to not have message header in telemetry data
                                                                            ;Autodetect if message header is in file
    if ishft(newfile_unsigned[0],-11) eq 1 then place=0 else place=1
                                                                            ;place = 1;
    If(keyword_set(strip_pad)) Then offset3 = -1 Else offset3 = 0
    offset1 = 7
    offset2 = -1
                                                                            ;Difference between length reported in length2() and amount of non-header data in a packet
                                                                            ;used in checking if decompression decompresses the correct amount of compressed data 
    len_offset=9

If (keyword_set(packet)) EQ 0 Then packet=['HSK','EUV','AVG','SPEC','HSBM','WPK']  ELSE BEGIN
     IF total(strmatch(packet, 'noHSBM')) EQ 1 then packet=['HSK','EUV','AVG','SPEC']
     IF total(strmatch(packet, 'SPEC')) EQ 1 AND total(strmatch(packet, 'AVG')) EQ 0 then packet=[packet,'AVG']
ENDELSE 
                                                                            ; this is so that the grouping can be change to anything
    
    
                                                                            ;example for only get one group eg: packet=['EUV']   
tmp              = where(packet EQ 'HSK',nn_act_ATR) 
tmp              = where(packet EQ 'EUV',nn_act_EUV)  
tmp              = where(packet EQ 'HSK',nn_act_ADR) 
tmp              = where(packet EQ 'HSK',nn_act_HSK) 
tmp              = where(packet EQ 'AVG',nn_act_SWP1) 
tmp              = where(packet EQ 'AVG',nn_act_SWP2) 
tmp              = where(packet EQ 'AVG',nn_act_ACT) 
tmp              = where(packet EQ 'AVG',nn_act_PAS)
tmp              = where(packet EQ 'SPEC',nn_act_ACT_LF) 
tmp              = where(packet EQ 'SPEC',nn_act_ACT_MF) 
tmp              = where(packet EQ 'SPEC',nn_act_ACT_HF)
tmp              = where(packet EQ 'SPEC',nn_act_PAS_LF) 
tmp              = where(packet EQ 'SPEC',nn_act_PAS_MF) 
tmp              = where(packet EQ 'SPEC',nn_act_PAS_HF) 
tmp              = where(packet EQ 'HSBM',nn_act_HSBM_LF) 
tmp              = where(packet EQ 'HSBM',nn_act_HSBM_MF) 
tmp              = where(packet EQ 'HSBM',nn_act_HSBM_HF) 
tmp              = where(packet EQ 'WPK',nn_act_w1) 
tmp              = where(packet EQ 'WPK',nn_act_w2) 
tmp              = where(packet EQ 'WPK',nn_act_w3) 
tmp              = where(packet EQ 'WPK',nn_act_w4) 
tmp              = where(packet EQ 'WPK',nn_act_w5) 
tmp              = where(packet EQ 'HSBM',nn_act_htime) 

;--------------------------------------------------------------------
   t2=systime(1,/seconds)
   Print,' ## Read the binary file took ',t2-t1,' seconds ##'
   SC_CLK1_gst  = !values.f_nan
   SC_CLK2_gst  = !values.f_nan
   APID2        = !values.f_nan
   length2      = !values.f_nan
   SC_CLK3_gst  = !values.f_nan
   SC_CLK4_gst  = !values.f_nan
 
 ;------ the following is just for specific fiels ----------
   if newfile_unsigned(0) eq 60304 then begin
      t1=systime(1,/seconds)
                                                                ;*******this is where laila is changing things DECEMBER 2011......
      nn_size   = n_elements(newfile_unsigned)
      tmp1      = newfile_unsigned[0:nn_size-1-18]  EQ 60304    ;find where 'eb90' can be found in the data set 
      tmp2      = newfile_unsigned[9:nn_size-1-9]   EQ 260      ;find where '0104' can be found 9 words shifted
      tmp3      = newfile_unsigned[10:nn_size-1-8]  EQ 256      ;find where '0100' can be found 10 words shifted
      tmp4      = newfile_unsigned[15:nn_size-1-3]  EQ 43049    ;find where 'a829' can be found 15 words shifted
      tmp5      = newfile_unsigned[16:nn_size-1-2]  EQ 195      ;find where '00c3' can be found 16 words shifted
      qq        = where(tmp1*tmp2*tmp3*tmp4*tmp5 ,nq)           ; where is this true
      qq        =qq+19                                          ; this is where the packet starts and it is from here that we want to keep the packege
      APID2     = newfile_unsigned(qq)  mod 256                 ; this will give us values between ~81- ~97
      SC_CLK1_gst    = double(newfile_unsigned[qq-13]*16.^4)+double(newfile_unsigned[qq-12])  ;ground support time -> gsp
      SC_CLK2_gst    = double(newfile_unsigned[qq-11]   )
      SC_CLK3_gst    = double(newfile_unsigned[qq+3]*16.^4) +double(newfile_unsigned[qq+4])   ;check the other old clock is the same as this place = 0 assumed
      SC_CLK4_gst    = double(newfile_unsigned[qq+5]    )
      length2           = newfile_unsigned[qq+2]+2              ;packet length, this is a special iteration
      tmp               = 0*newfile_signed
      for ii=0,nq-1 do tmp[ qq[ii] : (qq[ii]+length2[ii]/2+2)]=1
      qq1               = where(tmp EQ 1,nq1)
      newfile_unsigned  = reform(newfile_unsigned[qq1])
      newfile_signed    = reform(newfile_signed[qq1])            ;only used for apid 81
      tmp               = 0*newfile_byte                         ;twice the size
      for ii=0,nq-1 do tmp[ 2* qq[ii] : 2* (qq[ii]+length2[ii]/2+2) +1  ]=1
      qq1               = where(tmp EQ 1,nq1)
      t2=systime(1,/seconds)
      Print,' ## Remove extra information took ',t2-t1,' seconds ##'
    endif
   ;------ the following is just for specific fiels ----------
    
    t1=systime(1,/seconds)
   counter=0d
   counter_all1=counter
   while counter LT n_elements(newfile_unsigned) do begin  ;find the start of each packet - counter - and get all into -counter_all1
;;print,counter, floor(newfile_unsigned[counter+place+2]+1)/2 + 3
       counter=double(counter + floor(newfile_unsigned[counter+place+2]+1)/2 + 3) + place   ; this is stepping using the end of the packet information   
        
        if counter+2 LT  n_elements(newfile_unsigned)-1 then $    
           if total(mask16(newfile_unsigned(counter+place+0),5:15) * bin_c[10-index_arr[0:10]] ) LT 5*16+1 or $
              total(mask16(newfile_unsigned(counter+place+0),5:15) * bin_c[10-index_arr[0:10]] ) GT 6*16*7 then begin   ; check that it is one of our packets                
              print,'##### Warning ##### Jumper out ##3 lost packet pointing # error at ',counter,' files size ',n_elements(newfile_unsigned) , '  This was how much the last stepping was ', $
                    floor(newfile_unsigned[counter+place+2]+1)/2 + 3,' the stepping is usually < 1010 '
              counter= n_elements(newfile_unsigned) 
           endif
       if counter+2 LT  n_elements(newfile_unsigned)-1 then $                               ; end of file issues
              counter_all1  = [counter_all1,counter]
   endwhile
  
 
   nnn=n_elements(newfile_unsigned)
   INAPID=(newfile_unsigned GE 0*(2.^12)+8*(2.^8)+5*(2.^4)+1*(2.^0)) and (newfile_unsigned LE 0*(2.^12)+8*(2.^8)+6*(2.^4)+7*(2.^0))
   EXTRA1=(newfile_unsigned LT  0*(2.^12)+8*(2.^8)+0*(2.^4)+0*(2.^0))
   EXTRA2=(newfile_unsigned GE 2.^15+2.^14) and (newfile_unsigned LT 2.^15+2.^14+2.^12)
   tmp_ss1= INAPID(0:nnn-3)*EXTRA1(2:*)*EXTRA2(1:*)
   nn=n_elements(tmp_ss1)
   qq=where(tmp_ss1(0:nn-8),nq)
; print,'%%%%%%'
 ;  for iu=0,nq-1 do $
 ;  print,iu,qq(iu),newfile_unsigned(qq(iu)+0),newfile_unsigned(qq(iu)+1),newfile_unsigned(qq(iu)+2), $
 ;                  newfile_unsigned(qq(iu)+3),$   ;source sequencse counts 14 bits
 ;                  newfile_unsigned(qq(iu)+4), $  ;lenght           
 ;                  newfile_unsigned(qq(iu)+5), $
 ;                  newfile_unsigned(qq(iu)+6), $
 ;                  newfile_unsigned(qq(iu)+7), $  
 ;                  format='(2i,3z,5z)'
 ;  print,'%%%%%%'
  ; print,'Number of packets ',nq,' using WHERE:'           
   nn=min([n_elements(counter_all1),n_elements(qq)])
 ;  print,'##### '
 ;  print,'   #####    ',n_elements(counter_all1), n_elements(qq), nn,' C-using counter/length and P-searching for pattern'
 ;  print,'##### '
   if counter_all1[n_elements(counter_all1)-1] GE n_elements(newfile_unsigned) then counter_all1=counter_all1[0:n_elements(counter_all1)-2]   ; make sure that we have only identified full packets
   length=newfile_unsigned[counter_all1+place+2]     ; get an array of lenght, however the is the distance to next packet :double(counter + floor(newfile_unsigned[counter+place+2]+1)/2 + 3) + place

;Preallocating
sizelength       = size(length)
data_fft         = fltarr(sizelength(1),max(length)-6)
DFB_header       = strarr(sizelength(1),16)
vers             = fltarr(sizelength(1))
type_s           = fltarr(sizelength(1))
SHF              = fltarr(sizelength(1))
APID             = fltarr(sizelength(1))
GF               = fltarr(sizelength(1))
SC               = fltarr(sizelength(1))
length2          = fltarr(sizelength(1))          ; this variable is reset here
data             = fltarr(1)
y                = fltarr(sizelength(1),30)
SC_CLK1          = dblarr(sizelength(1))
SC_CLK2          = fltarr(sizelength(1))
course_clk       = fltarr(sizelength(1))
ORB_MD           = fltarr(sizelength(1)) 
MC_LEN           = fltarr(sizelength(1))
SMP_AVG          = fltarr(sizelength(1))
wave_config      = fltarr(sizelength(1))
EUV_config       = fltarr(sizelength(1))
ADR_config       = fltarr(sizelength(1))
HSK_config       = fltarr(sizelength(1))
ATR_config       = fltarr(sizelength(1))
GB_e12_hf        = intarr(sizelength(1))   ;this is one bit in the tertiary header 
;Resetting dummy variables   keep these, used to check that data was put into the arrays
p1  = 0L
p2  = 0L
p3  = 0L
p4  = 0L
p5  = 0L
p6  = 0L
p7  = 0L
p8  = 0L
p9  = 0L
p10 = 0L
p11 = 0L
p12 = 0L
p13 = 0L
p14 = 0L
p15 = 0L
p16 = 0L
p17 = 0L
p18 = 0L
p19 = 0L
p20 = 0L
p21 = 0L
p22 = 0L
p23 = 0L
i   = 0L
iii = 0L

   t2=systime(1,/seconds)
   Print,' ## First while-loop, it took ',t2-t1,' seconds ##'
   t1=systime(1,/seconds)

   counter=0d             ;stepping through this based on double(counter + floor(length[i]+1)/2 + 3) + place
;Putting data into an array of packets and headers into an arrays of headers
;while counter LT n_elements(newfile_unsigned) do begin  
;
; OLD this is stepin in the file again 
;for ni=0L, n_elements(length)-1 do begin 
;NEW we know the locations lets loop over counter_all1
   for ni=0L, n_elements(counter_all1)-1 do begin
      counter=counter_all1(ni)      
        tmp          = [[mask16(newfile_unsigned(counter+place+0),*)],[mask16(newfile_unsigned(counter+place+1),*)]]
        vers(i)      = total(tmp[0:2] *bin_c[2-index_arr[0:2]] )
        type_s(i)      = tmp[3]
        SHF(i)       = tmp[4]
        APID(i)      = total(tmp[5:15] *bin_c[10-index_arr[0:10]] )
        GF(i)        = tmp[16]*2+tmp[17]
        SC(i)        = total(tmp[18:31] *bin_c[13-index_arr[0:13]] )
        tmp          = [mask16[newfile_unsigned[counter+place+2],*]]
        length_dummy = total(tmp[0:15] *bin_c[15-index_arr[0:15]] )
        length2(i)   = length_dummy + 2
      tmp        =  double([[mask16[newfile_unsigned[counter+place+3],*]],[mask16[newfile_unsigned[counter+place+4],*]]])
      SC_CLK1(i) =double( total(tmp[0,0:31] *bin_c[31-index_arr[0:31]] ) ) 
      tmp        = double([mask16[newfile_unsigned[counter+place+5],*]])
      SC_CLK2(i) = total(tmp[0,0:15] *bin_c[15-index_arr[0:15]] )
 
  
;  if type_s(i) NE 0 then begin
 ;;    print,'# AA## ', n_elements(counter_all1),ni,i,type_s(i),SHF(i),APID(i),GF(i),' counter ', SC(i) ,length_dummy, length2(i),SC_CLK1(i),SC_CLK2(i)
;     print,'####### check ####### ', 'if never this happens then this can be a way to identify wrongly identifire packets'
     ;stanna
;  endif    
     
   ; if type_s(i) EQ  0 and SHF(i) EQ 1 then  BEGIN
  if   APID(i) GE 80 AND APID(i) LE 103 THEN BEGIN
      if length2(i) GT 2048 then  begin
          print,'#err## ', n_elements(counter_all1),ni,i,type_s(i),SHF(i),APID(i),GF(i),' counter ', SC(i) ,length_dummy, length2(i),SC_CLK1(i),SC_CLK2(i)
        stanna  ; solution active the else on the next line ;<- some thing is wrong, identified something that is not a LPW/EUV pkt
       endif ;ELSE $ 
      i                   = i + 1L  
               
    endif  
     
   
       
   endfor ;ni
   
   help,APID
  APID=APID(0:i-1)
  length2=length2(0:i-1)
  SC_CLK1=SC_CLK1(0:i-1)
  SC_CLK2=SC_CLK2(0:i-1)
  print,ni,i
  help,length2,APID
  ; stanna
   
   IF total(length2 GT 2048) GT 0 then print,'Warning: the length of ',total(length2 GT 2048),' packet are too long'
   IF total(length2 GT 2048) GT 0 then begin
           qq=where(length2 GT 2048,nq)
                  print,'Sizes ',n_elements(length), n_elements(length2),total(length2 GT 2048),nq,n_elements(counter_all1)
                  print,'##'
                  print,length2(qq)
                  print,'%%'
                  print,newfile_unsigned(counter_all1(qq)) 
                  print,'&&'
                  qq=indgen(n_elements(length2))
                  for iii=0,n_elements(qq)-1 do $ 
                  print,string(newfile_signed[(counter_all1(qq(iii))+place+offset1-1)-6:(counter_all1(qq(iii))+place+offset1-1)+6],format = '(z)') ;'(B016)')
      ;             stanna  ;chrash the program...
   endif
   t2=systime(1,/seconds)
   Print,' ## Second loop find APID took ',t2-t1,' seconds ##'
   t1=systime(1,/seconds)
;-------------------------------------------------
;number of pakets and which packets for each APID
;these are all minimum 1
; use only p1 to p24 to check i there is any packagets in the file
pkt_ATR             = where(APID EQ 81,nn_ATR) 
pkt_EUV             = where(APID EQ 82,nn_EUV)  
pkt_ADR             = where(APID EQ 83,nn_ADR) 
pkt_HSK             = where(APID EQ 84,nn_HSK) 
pkt_SWP1            = where(APID EQ 85,nn_SWP1) 
pkt_SWP2            = where(APID EQ 86,nn_SWP2) 
pkt_ACT             = where(APID EQ 87,nn_ACT) 
pkt_PAS             = where(APID EQ 88,nn_PAS)
pkt_ACT_LF          = where(APID EQ 89,nn_ACT_LF) 
pkt_ACT_MF          = where(APID EQ 90,nn_ACT_MF) 
pkt_ACT_HF          = where(APID EQ 91,nn_ACT_HF)
pkt_PAS_LF          = where(APID EQ 92,nn_PAS_LF) 
pkt_PAS_MF          = where(APID EQ 93,nn_PAS_MF) 
pkt_PAS_HF          = where(APID EQ 94,nn_PAS_HF) 
pkt_HSBM_LF         = where(APID EQ 95,nn_HSBM_LF) 
pkt_HSBM_MF         = where(APID EQ 96,nn_HSBM_MF) 
pkt_HSBM_HF         = where(APID EQ 97,nn_HSBM_HF) 
pkt_w1              = where(APID EQ 98,nn_w1) 
pkt_w2              = where(APID EQ 99,nn_w2) 
pkt_w3              = where(APID EQ 100,nn_w3) 
pkt_w4              = where(APID EQ 101,nn_w4) 
pkt_w5              = where(APID EQ 102,nn_w5) 
pkt_htime           = where(APID EQ 103,nn_htime) 
   ;-------------------------------------------------
   HSBM_LF_i     = -1.                 ;pkt_HSBM_LF will this be
   HSBM_MF_i     = -1.                 ;pkt_HSBM_MF will this be
   HSBM_HF_i     = -1.                 ;pkt_HSBM_FF will this be
   length        = length + 2
   counter_specific=counter_all1  ; to replace this variavle
   t2=systime(1,/seconds)
   Print,' ## Third while-loop, it took ',t2-t1,' seconds ##'
   
;############ Now for each type of packet will data be extracted into the created above structures ################

;ATR Packet
  total_ATR_length = 0
  if nn_ATR GT 0 and nn_act_ATR GT 0 then begin     
   t1=SYSTIME(1,/seconds)                   ;to check on speed
     ;ATR preallocations
     SWP           = fltarr(nn_ATR,128)
     ATR_W_BIAS1   = fltarr(nn_ATR)
     ATR_W_GUARD1  = fltarr(nn_ATR)
     ATR_W_STUB1   = fltarr(nn_ATR)
     Reserved1     = fltarr(nn_ATR)
     ATR_LP_BIAS1  = fltarr(nn_ATR)
     ATR_LP_GUARD1 = fltarr(nn_ATR)
     ATR_LP_STUB1  = fltarr(nn_ATR)
     Reserved2     = fltarr(nn_ATR)
     ATR_W_BIAS2   = fltarr(nn_ATR)
     ATR_W_GUARD2  = fltarr(nn_ATR)
     ATR_W_STUB2   = fltarr(nn_ATR)
     Reserved3     = fltarr(nn_ATR)
     ATR_LP_BIAS2  = fltarr(nn_ATR)
     ATR_LP_GUARD2 = fltarr(nn_ATR)
     ATR_LP_STUB2  = fltarr(nn_ATR)
     Reserved4     = fltarr(nn_ATR)
     FOR ni=0L,nn_ATR-1 do begin
      i                = pkt_ATR[ni]                      ;which paket in the large file     
      counter               = counter_specific[i]         ;get the right counter     
      dummy = string(newfile_signed[counter+place+offset1-1],format = '(B016)')
      reads,dummy,notused_dummy,orbmode_dummy,rpt_rate_dummy,notused_dummy,checksum_dummy,enb_dummy,format = '(B04,B04,B03,B03,B01,B01)'    
       SMP_AVG[i]            = rpt_rate_dummy              ;use to record 
       reads,dummy,orbmode_dummy,ATRconfig_dummy,format = '(B04,B012)'        
      ORB_MD(i)         = orbmode_dummy
      ATR_config(i)     = ATRconfig_dummy            
      SWP(p6,*)         = newfile_signed[counter+place+offset1:counter+place+128+offset1+offset2]
      ATR_W_BIAS1(p6)   = newfile_signed[counter+place+offset1+offset2+128+1]
      ATR_W_GUARD1(p6)  = newfile_signed[counter+place+offset1+offset2+128+2]
      ATR_W_STUB1(p6)   = newfile_signed[counter+place+offset1+offset2+128+3]
      Reserved1(p6)     = newfile_signed[counter+place+offset1+offset2+128+4]
      ATR_LP_BIAS1(p6)  = newfile_signed[counter+place+offset1+offset2+128+5]
      ATR_LP_GUARD1(p6) = newfile_signed[counter+place+offset1+offset2+128+6]
      ATR_LP_STUB1(p6)  = newfile_signed[counter+place+offset1+offset2+128+7]
      Reserved2(p6)     = newfile_signed[counter+place+offset1+offset2+128+8]
      ATR_W_BIAS2(p6)   = newfile_signed[counter+place+offset1+offset2+128+9]
      ATR_W_GUARD2(p6)  = newfile_signed[counter+place+offset1+offset2+128+10]
      ATR_W_STUB2(p6)   = newfile_signed[counter+place+offset1+offset2+128+11]
      Reserved3(p6)     = newfile_signed[counter+place+offset1+offset2+128+12]
      ATR_LP_BIAS2(p6)  = newfile_signed[counter+place+offset1+offset2+128+13]
      ATR_LP_GUARD2(p6) = newfile_signed[counter+place+offset1+offset2+128+14]
      ATR_LP_STUB2(p6)  = newfile_signed[counter+place+offset1+offset2+128+15]
      Reserved4(p6)     = newfile_signed[counter+place+offset1+offset2+128+16]
      p6 = p6 + 1
      ENDFOR                                                ;loop over the packets
      t2=SYSTIME(1,/seconds)                                ;to check on speed
       print,'#### ATR ',ni,i,' time ', t2-t1 ,' seconds '
      ATR_SC = SC[pkt_ATR]
      for seqIndx = 1, nn_ATR-1 do $
          if ATR_SC[seqIndx] NE ATR_SC[seqIndx-1]+1 then print, 'ATR Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ATR_SC[seqIndx-1], '  SC(seqIndx) =', ATR_SC[seqIndx]
      if (ATR_SC[nn_ATR-1]-ATR_SC[0]+1) NE p6 then print, 'ATR Sequence Count Failed. Should be', p6, ' Reporting ',(ATR_SC[nn_ATR-1]-ATR_SC[0]+1) 
      total_ATR_length = total(length[pkt_ATR]+7)     
  endif else begin                                            ; create defauls values -1 if not packets where found
      SWP           = -1 &  ATR_W_BIAS1   =  -1 & ATR_W_GUARD1  = -1 & ATR_W_STUB1   =  -1 & $
      Reserved1     =  -1 & ATR_LP_BIAS1  =  -1 & ATR_LP_GUARD1 =  -1 & ATR_LP_STUB1  =  -1 & $
      Reserved2     =  -1 & ATR_W_BIAS2   =  -1 & ATR_W_GUARD2  =  -1 & ATR_W_STUB2   =  -1 & $
      Reserved3     =  -1 & ATR_LP_BIAS2  =  -1 & ATR_LP_GUARD2 =  -1 & ATR_LP_STUB2  =  -1 & $
      Reserved4     =  -1 & ENDELSE


;EUV Packet
   total_euv_length = 0
   if nn_EUV GT 0 and nn_act_EUV GT 0 then begin     
    t1=SYSTIME(1,/seconds)                                     ;to check on speed
     ;EUV Preallocations
     THERM   = fltarr(nn_EUV,16)
     DIODE_A = fltarr(nn_EUV,16)
     DIODE_B = fltarr(nn_EUV,16)
     DIODE_C = fltarr(nn_EUV,16)
     DIODE_D = fltarr(nn_EUV,16)
     FOR ni=0L,nn_EUV-1 do begin
       i                     = pkt_EUV[ni]                      ;which paket in the large file 
       counter               = counter_specific[i]              ;get the right counter 
       dummy                 = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')     
       reads,dummy,notused_dummy,SMPAVG_dummy,notused_dummy,euv_enable_dymmmy,format = '(B08,B04,B03,B01)'
       SMP_AVG[i]            = SMPAVG_dummy       
       EUV_config[i] = newfile_unsigned[counter+place+offset1-1]
    if compression EQ 'on' then begin    
          ptr=1L*(counter+place+offset1)                       ; which 16 bit package to start with
          ptr_end=ptr+(length2[i]-len_offset)                  ; this has to be checked!!!
          nn_e=0  
          therm[ni,*]    = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV temp'
          diode_a[ni,*]  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE A'
          diode_b[ni,*]  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE B'
          diode_c[ni,*]  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE C'
          diode_d[ni,*]  = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,16,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_all1[i],' pointer ',ptr,nn_e,' Packet EUV DIODE D'
                                                                ;Check the amount of data left over - ptr is moved (by mvn_lpw_r_multi_decompress) up to the first bit after the compressed data, so 0 is ok.
                                                                ;     if ptr_end-ptr lt 0 or ptr_end-ptr gt 32 then message,/info,string(ptr_end-ptr,format='(%"Did not decompress the right amount of data, %d bytes left over")')
     end else begin
      for z = 0,31,2 do begin
        dummy = string(newfile_signed[counter+place+offset1+z],format='(B016)')+string(newfile_signed[counter+place+offset1+z+1],format = '(B016)')
        reads, dummy, THERM_dummy, format = '(B032)'
        THERM[ni,z/2] = THERM_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+32],format = '(B016)')
        reads, dummy, DIODEA_dummy, format = '(B032)'
        DIODE_A[ni,z/2] = DIODEA_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+2*32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+2*32], format = '(B016)')
        reads, dummy, DIODEB_dummy, format = '(B032)'
        DIODE_B[ni,z/2] = DIODEB_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+3*32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+3*32], format = '(B016)')
        reads, dummy, DIODEC_dummy, format = '(B032)'
        DIODE_C[ni,z/2] = DIODEC_dummy
        dummy = string(newfile_signed[counter+place+offset1+z+4*32],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+1+4*32], format = '(B016)')
        reads, dummy, DIODED_dummy, format = '(B032)'
        DIODE_D[ni,z/2] = DIODED_dummy
      endfor
    end       
    p7 = p7 + 1                                                   ; keeps track of how many EUV packets there are   
      ENDFOR                                                      ;loop over the packets
      t2=SYSTIME(1,/seconds)                                      ;to check on speed
      print,'#### EUV ',ni,i,' time ', t2-t1,' seconds' 
      EUV_SC = SC[pkt_EUV]
      for seqIndx = 1, nn_EUV-1 do $
          if EUV_SC[seqIndx] NE EUV_SC[seqIndx-1]+1 then print, 'EUV Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', EUV_SC[seqIndx-1], '  SC(seqIndx) =', EUV_SC[seqIndx]
      if (EUV_SC[nn_EUV-1]-EUV_SC[0]+1) NE p7 then print, 'EUV Sequence Count Failed. Should be', p7, ' Reporting ',(EUV_SC[nn_EUV-1]-EUV_SC[0]+1)
      total_euv_length = total(length[pkt_EUV]+7)  
  endif  ELSE BEGIN                                               ; if no packet was found
      THERM   = -1 &     DIODE_A = -1 &     DIODE_B = -1 &     DIODE_C = -1 &     DIODE_D = -1 & ENDELSE


;ADR Packet
   total_adr_length = 0
   if nn_ADR GT 0 and nn_act_ADR GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                          ;to check on speed
     ;ADR preallocations
     ADR_DYN_OFFSET1   = fltarr(nn_ADR)
     ADR_LP_BIAS1      = fltarr(nn_ADR,127)
     ADR_DYN_OFFSET2   = fltarr(nn_ADR)
     ADR_LP_BIAS2      = fltarr(nn_ADR,127)
     ADR_W_BIAS1       = fltarr(nn_ADR)
     ADR_W_GUARD1      = fltarr(nn_ADR)
     ADR_W_STUB1       = fltarr(nn_ADR)
     ADR_W_V1          = fltarr(nn_ADR)
     ADR_LP_GUARD1     = fltarr(nn_ADR)
     ADR_LP_STUB1      = fltarr(nn_ADR)
     ADR_W_BIAS2       = fltarr(nn_ADR)
     ADR_W_GUARD2      = fltarr(nn_ADR)
     ADR_W_STUB2       = fltarr(nn_ADR)
     ADR_W_V2          = fltarr(nn_ADR)
     ADR_LP_GUARD2     = fltarr(nn_ADR)
     ADR_LP_STUB2      = fltarr(nn_ADR)
     FOR ni=0L,nn_ADR-1 do begin      
      i                       = pkt_ADR[ni]                         ;which paket in the large file     
      counter               = counter_specific[i]                   ;get the right counter     
      dummy                   = string(newfile_signed[counter+place+offset1-1],format = '(B016)')        
      reads,dummy,orbmode_dummy,notused_dummy,SMPAVG_dummy,notused_dummy,ENB_dummy,format = '(B04,B04,B4,B03,B01)'   
      reads,dummy,orbmode_dummy,ADRconfig_dummy,format = '(B04,B012)'
      ORB_MD[i]               = orbmode_dummy
      SMP_AVG[i]              = SMPAVG_dummy    
      ADR_config[i]           = ADRconfig_dummy      
      ADR_DYN_OFFSET1(p8)     = newfile_signed[counter+place+offset1]
      ADR_LP_BIAS1(p8,*)      = newfile_signed[counter+place+offset1+1:counter+place+offset1+1+127+offset2]
      ADR_DYN_OFFSET2(p8)     = newfile_signed[counter+place+offset1+2+127+offset2]
      ADR_LP_BIAS2(p8,*)      = newfile_signed[counter+place+offset1+3+127+offset2:counter+place+offset1+3+2*(127+offset2)]
      ADR_W_BIAS1(p8)         = newfile_signed[counter+place+offset1+4+2*(127+offset2)]
      ADR_W_GUARD1(p8)        = newfile_signed[counter+place+offset1+5+2*(127+offset2)]
      ADR_W_STUB1(p8)         = newfile_signed[counter+place+offset1+6+2*(127+offset2)]
      ADR_W_V1(p8)            = newfile_signed[counter+place+offset1+7+2*(127+offset2)]
      ADR_LP_GUARD1(p8)       = newfile_signed[counter+place+offset1+8+2*(127+offset2)]
      ADR_LP_STUB1(p8)        = newfile_signed[counter+place+offset1+9+2*(127+offset2)]
      ADR_W_BIAS2(p8)         = newfile_signed[counter+place+offset1+10+2*(127+offset2)]
      ADR_W_GUARD2(p8)        = newfile_signed[counter+place+offset1+11+2*(127+offset2)]
      ADR_W_STUB2(p8)         = newfile_signed[counter+place+offset1+12+2*(127+offset2)]
      ADR_W_V2(p8)            = newfile_signed[counter+place+offset1+13+2*(127+offset2)]
      ADR_LP_GUARD2(p8)       = newfile_signed[counter+place+offset1+14+2*(127+offset2)]
      ADR_LP_STUB2(p8)        = newfile_signed[counter+place+offset1+15+2*(127+offset2)]
      p8 = p8 + 1
     ENDFOR                                                         ;loop over the packets
     t2=SYSTIME(1,/seconds)                                         ;to check on speed
     print,'#### ADR ',ni,i,' time ', t2-t1,' seconds' 
      ADR_SC = SC[pkt_ADR]
      for seqIndx = 1, nn_ADR-1 do $
            if ADR_SC[seqIndx] NE ADR_SC[seqIndx-1]+1 then print, 'ADR Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ADR_SC[seqIndx-1], '  SC(seqIndx) =', ADR_SC[seqIndx]
      if (ADR_SC[nn_ADR-1]-ADR_SC[0]+1) NE p8 then print, 'ADR Sequence Count Failed. Should be', p8, ' Reporting ',(ADR_SC[nn_ADR-1]-ADR_SC[0]+1) 
      total_adr_length = total(length[pkt_ADR]+7)    
  endif ELSE BEGIN                                                  ;created the variables with -1 as values since no data exist for this package
  ADR_DYN_OFFSET1   = -1 & ADR_LP_BIAS1      = -1 & ADR_DYN_OFFSET2   = -1 & ADR_LP_BIAS2      = -1 & $
  ADR_W_BIAS1       = -1 & ADR_W_GUARD1      = -1 &  ADR_W_STUB1      = -1 & ADR_W_V1          = -1 & $
  ADR_LP_GUARD1     = -1 & ADR_LP_STUB1      = -1 & ADR_W_BIAS2       = -1 & ADR_W_GUARD2      = -1 & $
  ADR_W_STUB2       = -1 & ADR_W_V2          = -1 & ADR_LP_GUARD2     = -1 & ADR_LP_STUB2      = -1 & ENDELSE
    

;HSK Packet
   total_hsk_length = 0
   if nn_HSK GT 0 and nn_act_HSK GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                             ;to check on speed
     ;HSK preallocations
     Preamp_Temp1      = fltarr(nn_HSK)
     Preamp_Temp2      = fltarr(nn_HSK)
     Beb_Temp          = fltarr(nn_HSK)
     plus12va          = fltarr(nn_HSK)
     minus12va         = fltarr(nn_HSK)
     plus5va           = fltarr(nn_HSK)
     minus5va          = fltarr(nn_HSK)
     plus90va          = fltarr(nn_HSK)
     minus90va         = fltarr(nn_HSK)
     CMD_ACCEPT        = fltarr(nn_HSK)
     CMD_REJECT        = fltarr(nn_HSK)
     MEM_SEU_COUNTER   = fltarr(nn_HSK)
     INT_STAT          = fltarr(nn_HSK)
     CHKSUM            = fltarr(nn_HSK)
     EXT_STAT          = fltarr(nn_HSK)
     DPLY1_CNT         = fltarr(nn_HSK)
     DPLY2_CNT         = fltarr(nn_HSK)
     FOR ni=0L,nn_HSK-1 do begin
      i                   = pkt_HSK[ni]                                 ;which paket in the large file      
      counter               = counter_specific[i]                       ;get the right counter   
      dummy                   = string(newfile_signed[counter+place+offset1-1],format = '(B016)')     
      reads,dummy,orbmode_dummy,notused_dummy,SMPAVG_dummy,notused_dummy,ENB_dummy,format = '(B04,B04,B4,B03,B01)'
      ORB_MD[i]               = orbmode_dummy  
      SMP_AVG[i]              = SMPAVG_dummy 
      HSK_config(i)       = newfile_unsigned[counter+place+offset1-1]
      Preamp_Temp1(p9)    = newfile_signed[counter+place+offset1]
      Preamp_Temp2(p9)    = newfile_signed[counter+place+offset1+1]
      Beb_Temp(p9)        = newfile_signed[counter+place+offset1+2]
      plus12va(p9)        = newfile_signed[counter+place+offset1+3]
      minus12va(p9)       = newfile_signed[counter+place+offset1+4]
      plus5va(p9)         = newfile_signed[counter+place+offset1+5]
      minus5va(p9)        = newfile_signed[counter+place+offset1+6]
      plus90va(p9)        = newfile_signed[counter+place+offset1+7]
      minus90va(p9)       = newfile_signed[counter+place+offset1+8]
      CMD_ACCEPT(p9)      = newfile_signed[counter+place+offset1+9]
      CMD_REJECT(p9)      = newfile_signed[counter+place+offset1+10]
      MEM_SEU_COUNTER(p9) = newfile_signed[counter+place+offset1+11]
      INT_STAT(p9)        = newfile_signed[counter+place+offset1+12]
      CHKSUM(p9)          = newfile_signed[counter+place+offset1+13]
      EXT_STAT(p9)        = newfile_signed[counter+place+offset1+14]
      DPLY1_CNT(p9)       = newfile_signed[counter+place+offset1+15]
      DPLY2_CNT(p9)       = newfile_signed[counter+place+offset1+16]
      p9 = p9 + 1
     ENDFOR                                                             ;loop over the packets
     t2=SYSTIME(1,/seconds)                                             ;to check on speed
     print,'#### HSK ',ni,i,' time ', t2-t1,' seconds'  
      HSK_SC = SC[pkt_HSK]
      for seqIndx = 1, nn_HSK-1 do $
         if HSK_SC[seqIndx] NE HSK_SC[seqIndx-1]+1 then print, 'HSK Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSK_SC[seqIndx-1], '  SC(seqIndx) =', HSK_SC[seqIndx]
      if (HSK_SC[nn_HSK-1]-HSK_SC[0]+1) NE p9 then print, 'HSK Sequence Count Failed. Should be', p9, ' Reporting ',(HSK_SC(nn_HSK-1)-HSK_SC(0)+1) 
      total_hsk_length = total(length[pkt_HSK]+7)   
  endif  ELSE BEGIN                                                     ; in case of no package
    Preamp_Temp1      = -1 & Preamp_Temp2      = -1 & Beb_Temp          = -1 & plus12va          = -1 & minus12va         = -1 & $
    plus5va           = -1 & minus5va          = -1 & plus90va          = -1 & minus90va         = -1 & CMD_ACCEPT        = -1 & CMD_REJECT        = -1 & $
    MEM_SEU_COUNTER   = -1 & INT_STAT          = -1 & CHKSUM            = -1 & EXT_STAT          = -1 & $
    DPLY1_CNT         = -1 & DPLY2_CNT         = -1 & ENDELSE

;SWP1_AVG Packet
  total_swp1_length = 0
  if nn_SWP1 GT 0 and nn_act_SWP1 GT 0 then begin     
  t1=SYSTIME(1,/seconds)                                                ;to check on speed
     ;SWP1_AVG prealloctions
     SWP1_I1           = fltarr(nn_SWP1,128)
     SWP1_V2           = fltarr(nn_SWP1,128)
     I_ZERO1           = fltarr(nn_SWP1)
     SWP1_DYN_OFFSET1  = fltarr(nn_SWP1)
     FOR ni=0L,nn_SWP1-1 do begin
      i                     = pkt_SWP1[ni]                               ;which paket in the large file      
      counter               = counter_specific[i]                        ;get the right counter  
      dummy                 = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
      reads,dummy,orbmode_dummy,nothing,MClen_dummy,nothing2,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
      ORB_MD[i]             = orbmode_dummy
      MC_LEN[i]             = MClen_dummy
      SMP_AVG[i]            = SMPAVG_dummy
      I_ZERO1[ni]          = newfile_signed[counter+place+offset1]
      SWP1_DYN_OFFSET1(ni) = newfile_signed[counter+place+offset1+1]
       if compression EQ 'on' then begin
           ptr=1L*(counter+place+offset1+2)                               ; which 16 bit package to start with
           ptr_end=ptr+(length2[i]-len_offset-4)                           ; this has to be checked!!!
           nn_e=0                                                         ; this is when the data is not eact a factor of 16 
           SWP1_I1[ni,*] = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,128,edac_on) 
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP1 I1'
           SWP1_V2[ni,*] = mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,128,edac_on) 
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP1 V2'       
      endif else begin                                                     ;no compression
            for z = 0,128*2-1,2 do begin
                dummy = string(newfile_signed[counter+place+offset1+z+2],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+3],format = '(B016)')
                reads, dummy, SWPI1_dummy, format = '(B032)'
                SWP1_I1[ni,z/2] = double(SWPI1_dummy)
            endfor
            SWP1_V2[ni,*]       = newfile_signed[counter+place+offset1+128*2+2:counter+place+offset1+128*3+1]
       endelse
       p10 = p10 + 1
     ENDFOR                                                                  ;loop over the packets
     t2=SYSTIME(1,/seconds)                                                  ;to check on speed
     print,'#### SWP1 ',ni,i,' time ', t2-t1 ,' seconds'   
      SWP1_SC = SC[pkt_SWP1]
      for seqIndx = 1, nn_SWP1-1 do $
          if SWP1_SC[seqIndx] NE SWP1_SC[seqIndx-1]+1 then print, 'SWP1 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', SWP1_SC[seqIndx-1], '  SC(seqIndx) =', SWP1_SC[seqIndx]
      if (SWP1_SC[nn_SWP1-1]-SWP1_SC[0]+1) NE p10 then print, 'SWP1 Sequence Count Failed. Should be', p10, ' Reporting ',(SWP1_SC(nn_SWP1-1)-SWP1_SC(0)+1) 
      total_swp1_length = total(length[pkt_SWP1]+7) 
  endif ELSE BEGIN                                                            ; if no packet was found
       SWP1_I1           = -1 & SWP1_V2           = -1 & I_ZERO1           = -1 & SWP1_DYN_OFFSET1  = -1 & ENDELSE
    

;SWP2_AVG Packet
  total_swp2_length = 0
  if nn_SWP2 GT 0 and nn_act_SWP2 GT 0 then begin     
  t1=SYSTIME(1,/seconds)                                                       ;to check on speed
     ;SWP2_AVG prealloctions
     SWP2_I2           = fltarr(nn_SWP2,128)
     SWP2_V1           = fltarr(nn_SWP2,128)
     I_ZERO2           = fltarr(nn_SWP2)
     SWP2_DYN_OFFSET2  = fltarr(nn_SWP2)     
     FOR ni=0L,nn_SWP2-1 do begin
      i                   = pkt_SWP2[ni]                                        ;which paket in the large file
      counter             = counter_specific[i]                                 ;get the right counter     
      dummy               = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
      reads,dummy,orbmode_dummy,nothing,MClen_dummy,nothing2,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
      ORB_MD[i]           = orbmode_dummy
      MC_LEN[i]           = MClen_dummy
      SMP_AVG[i]          = SMPAVG_dummy
       i                     = pkt_SWP2[ni]                                      ;which paket in the large file      
      counter               = counter_specific[i]                                ;get the right counter  
      dummy                 = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
      reads,dummy,orbmode_dummy,nothing,MClen_dummy,nothing2,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
      ORB_MD[i]             = orbmode_dummy
      MC_LEN[i]             = MClen_dummy
      SMP_AVG[i]            = SMPAVG_dummy
      I_ZERO2[ni]        = newfile_signed[counter+place+offset1]
      SWP2_DYN_OFFSET2[ni] = newfile_signed[counter+place+offset1+1]
         if compression EQ 'on' then begin     
           ptr=1L*(counter+place+offset1+2)                                       ; which 16 bit package to start with
           ptr_end=ptr+(length2[i]-len_offset-4)                                  ; this has to be checked!!!
           nn_e=0                                                                 ; this is when the data is not eact a factor of 16
           swp2_I2[ni,*] = mvn_lpw_r_block16(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,128,edac_on)              
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP2 I2'
            swp2_V1[ni,*] = mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,128,edac_on)                 
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP2 V1'
         end else begin
           for z = 0,128*2-1,2 do begin
                dummy            = string(newfile_signed[counter+place+offset1+z+2],format = '(B016)')+string(newfile_signed[counter+place+offset1+z+3],format = '(B016)')
                reads, dummy, SWP2I2_dummy, format = '(B032)'
                SWP2_I2[ni,z/2] = double(SWP2I2_dummy)
            endfor
              SWP2_V1[ni,*]     = newfile_signed[counter+place+offset1+128*2+2:counter+place+offset1+128*3+1]
        endelse
        p11 = p11 + 1
     ENDFOR                                                                       ;loop over the packets
     t2=SYSTIME(1,/seconds)                                                       ;to check on speed
     print,'#### SWP2 ',ni,i,' time ', t2-t1 ,' seconds' 
      SWP2_SC = SC[pkt_SWP2] 
      for seqIndx = 1, nn_SWP2-1 do $
          if SWP2_SC[seqIndx] NE SWP2_SC[seqIndx-1]+1 then print, 'SWP2 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', SWP2_SC[seqIndx-1], '  SC(seqIndx) =', SWP2_SC[seqIndx]
      if (SWP2_SC[nn_SWP2-1]-SWP2_SC[0]+1) NE p11 then print, 'SWP2 Sequence Count Failed. Should be', p11, ' Reporting ',(SWP2_SC[nn_SWP2-1]-SWP2_SC[0]+1)
      total_swp2_length = total(length[pkt_SWP2]+7) 
  endif ELSE BEGIN                                                                ; in case no packages
  SWP2_I2           = -1 &     SWP2_V1           = -1 &     I_ZERO2           = -1 &     SWP2_DYN_OFFSET2  = -1 & ENDELSE



;ACT_AVG Packet
  total_act_length = 0
  if nn_ACT GT 0 and nn_act_ACT GT 0  then begin     
t1=SYSTIME(1,/seconds)                                                            ;to check on speed
     ;ACT preallocations
     ACT_V1            = fltarr(nn_ACT,64)
     ACT_V2            = fltarr(nn_ACT,64)
     ACT_E12_LF        = fltarr(nn_ACT,64)
     FOR ni=0L,nn_ACT-1 do begin    
      i                   = pkt_ACT[ni]                                           ;which paket in the large file
      counter             = counter_specific[i]                                   ;get the right counter     
      dummy             = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
      reads,dummy,orbmode_dummy,nothing,MClen_dummy,nothing2,format = '(B04,B01,B03,B08)'
      ORB_MD(i)         = orbmode_dummy
      MC_LEN(i)         = MClen_dummy
      if compression EQ 'on' then begin
           ptr             = 1L*(counter+place+offset1)                           ; which 16 bit package to start with
           ptr_end         =  ptr+(length2[i]-len_offset)                         ; this has to be checked!!!
           nn_e            = 0                                                    ; this is when the data is not eact a factor of 16
          act_v1[ni,*]    = mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,64,edac_on)  
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet ACT V1'      
           act_v2[ni,*]    = mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,64,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet ACT V2'
           act_e12_lf[ni,*]= mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,64,edac_on) 
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet ACT E12' 
                                                                                  ;Check the amount of data left over - ptr is moved (by mvn_lpw_r_multi_decompress) up to the first bit after the compressed data, so 0 is ok.
                                                                                  ;        if ptr_end-ptr lt 0 or ptr_end-ptr gt 32 then message,/info,string(ptr_end-ptr,format='(%"Did not decompress the right amount of data, %d bytes left over")')
      end else begin
          ACT_V1[ni,*]     = newfile_signed[counter+place+offset1                 :counter+place+offset1+offset2+64]
          ACT_V2[ni,*]     = newfile_signed[counter+place+offset1+offset2+64+1    :counter+place+offset1+2*(offset2+64)+1]
          ACT_E12_LF[ni,*] = newfile_signed[counter+place+offset1+2*(offset2+64)+2:counter+place+offset1+3*(offset2+64)+2]
      endelse
      p12                = p12 + 1
     ENDFOR                                                                       ;loop over the packets
     t2=SYSTIME(1,/seconds)                                                       ;to check on speed
     print,'#### ACT ',ni,i,' time ', t2-t1,' seconds'  
      ACT_SC = SC[pkt_ACT] 
      for seqIndx = 1, nn_ACT-1 do $
          if ACT_SC[seqIndx] NE ACT_SC[seqIndx-1]+1 then print, 'ACT Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_SC[seqIndx-1], '  SC(seqIndx) =', ACT_SC[seqIndx]
      if (ACT_SC[nn_ACT-1]-ACT_SC[0]+1) NE p12 then print, 'ACT Sequence Count Failed. Should be', p12, ' Reporting ',(ACT_SC[nn_ACT-1]-ACT_SC[0]+1) 
      total_act_length = total(length[pkt_ACT]+7)
  endif ELSE BEGIN                                                                ; in case no packages
      ACT_V1            = -1 &     ACT_V2            = -1 &     ACT_E12_LF        = -1 & ENDELSE


    

 ;PAS_AVG Packet
   total_pas_length = 0
   if nn_PAS GT 0  and nn_act_PAS GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                                           ;to check on speed
     ;PAS preallocations
     PAS_V1            = fltarr(nn_PAS,64)
     PAS_V2            = fltarr(nn_PAS,64)
     PAS_E12_LF        = fltarr(nn_PAS,64)
     FOR ni=0L,nn_PAS-1 do begin
      i                   = pkt_PAS[ni]                                             ;which paket in the large file
      counter             = counter_specific[i]                                     ;get the right counter     
      dummy               = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
      reads,dummy,orbmode_dummy,nothing,MClen_dummy,nothing2,format = '(B04,B01,B03,B08)'
      ORB_MD[i]           = orbmode_dummy
      MC_LEN[i]           = MClen_dummy            
      if compression EQ 'on' then begin
           ptr=1L*(counter+place+offset1)                                           ; which 16 bit package to start with
           ptr_end=ptr+(length2[i]-len_offset)                                      ; this has to be checked!!!
           nn_e=0                                                                   ; this is when the data is not eact a factor of 16
            pas_v1[ni,*]    = mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,64,edac_on)  
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet PAS V1'      
            pas_v2[ni,*]    = mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,64,edac_on)
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet PAS V2'
            pas_e12_lf[ni,*]= mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,64,edac_on) 
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet PAS E12' 
                                                  ;Check the amount of data left over - ptr is moved (by mvn_lpw_r_multi_decompress) up to the first bit after the compressed data, so 0 is ok.
                                                  ;if ptr_end-ptr lt 0 or ptr_end-ptr gt 32 then message,/info,string(ptr_end-ptr,format='(%"Did not decompress the right amount of data, %d bytes left over")')
      end else begin
      PAS_V1[ni,*]     = newfile_signed[counter+place+offset1                 :counter+place+offset1+offset2+64]
      PAS_V2[ni,*]     = newfile_signed[counter+place+offset1+offset2+64+1    :counter+place+offset1+2*(offset2+64)+1]
      PAS_E12_LF[ni,*] = newfile_signed[counter+place+offset1+2*(offset2+64)+2:counter+place+offset1+3*(offset2+64)+2]
      end
      p13              = p13 + 1
   ENDFOR                                                                           ;loop over the packets
   t2=SYSTIME(1,/seconds)                                                           ;to check on speed
   print,'#### PAS ',ni,i,' time ', t2-t1 ,' seconds'   
      PAS_SC = SC[pkt_PAS]
      for seqIndx = 1, nn_PAS-1 do $
          if PAS_SC[seqIndx] NE PAS_SC[seqIndx-1]+1 then print, 'PAS Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_SC[seqIndx-1], '  SC(seqIndx) =', PAS_SC[seqIndx]
      if (PAS_SC[nn_PAS-1]-PAS_SC[0]+1) NE p13 then print, 'PAS Sequence Count Failed. Should be', p13, ' Reporting ',(PAS_SC[nn_PAS-1]-PAS_SC[0]+1) 
      total_pas_length = total(length[pkt_PAS]+7)
  endif ELSE BEGIN
  PAS_V1            = -1 & PAS_V2            = -1 & PAS_E12_LF        = -1 & ENDELSE
  



 ; ACT_S_LF packet
    total_act_s_lf_length = 0
    if nn_ACT_LF GT 0  and nn_act_ACT_LF GT 0 then begin     
    t1=SYSTIME(1,/seconds)                                                         ;to check on speed
     ACT_S_LF          = !values.f_nan                                             ;variable length fltarr(nn_ACT_LF*116)
     ACT_LF_PKTCNT     = fltarr(nn_ACT_LF)
     ACT_LF_PKTARR     = fltarr(nn_ACT_LF)
     FOR ni=0L,nn_ACT_LF-1 do begin
       i                   = pkt_ACT_LF[ni]                                       ;which paket in the large file
       counter             = counter_specific[i]                                  ;get the right counter     
       dummy                = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
       reads,dummy,orbmode_dummy,GB_dummy,MCLEN_dummy,notused_dummy,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
       ORB_MD[i]           = orbmode_dummy
       MC_LEN[i]           = MClen_dummy
       SMP_AVG[i]          = SMPAVG_dummy   
       GB_e12_hf[i]        = GB_dummy
       ACT_LF_PKTCNT[ni]   = newfile_unsigned[counter+place+offset1] 
       n_packets            = floor((((length[i]-1)/2)-4)/29)
       ACT_LF_pktarr[ni]   = n_packets 
       if ni EQ 0 then ACT_S_LF =                         [newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]] else  $  ;variable length!!
                       ACT_S_LF =               [ACT_S_LF, newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]]      
       if concatention EQ 'off' then ACT_LF_array[ni,*] = [newfile_unsigned[counter+place+offset1+1:counter+place+offset1+floor(length[i]+1)/2+2+offset2+1-8]]
       p14                  = p14 + 1
   ENDFOR                                                                           ;loop over the packets
   t2=SYSTIME(1,/seconds)                                                           ;to check on speed
   print,'#### ACT_LF ',ni,i,' time ', t2-t1 ,' seconds' 
      ACT_LF_SC = SC[pkt_ACT_LF]
      for seqIndx = 1, nn_ACT_LF-1 do $
          if ACT_LF_SC[seqIndx] NE ACT_LF_SC[seqIndx-1]+1 then print, 'ACT_S_LF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_LF_SC[seqIndx-1], '  SC(seqIndx) =', ACT_LF_SC[seqIndx]
      if (ACT_LF_SC[nn_ACT_LF-1]-ACT_LF_SC[0]+1) NE p14 then print, 'ACT_S_LF Sequence Count Failed. Should be', p14, ' Reporting ',(ACT_LF_SC[nn_ACT_LF-1]-ACT_LF_SC[0]+1)
      total_act_s_lf_length = total(length[pkt_ACT_LF]+7) 
  endif  ELSE BEGIN                                                                  ; case on no pkt
   ACT_S_LF          = -1 &   ACT_LF_PKTCNT     = -1 &    ACT_LF_PKTARR     = -1 & ENDELSE
  


; ACT_S_MF Packet
    total_act_s_mf_length = 0
   if nn_ACT_MF GT 0 and nn_act_ACT_MF GT 0  then begin     
   t1=SYSTIME(1,/seconds)                                                            ;to check on speed
     ACT_S_MF          = !values.f_nan                                                ;variable length fltarr(nn_ACT_LF*116)
     ACT_MF_PKTCNT     = fltarr(nn_ACT_MF)
     ACT_MF_PKTARR     = fltarr(nn_ACT_MF)
     FOR ni=0L,nn_ACT_MF-1 do begin
         i                   = pkt_ACT_MF[ni]                                         ;which paket in the large file
         counter             = counter_specific[i]                                    ;get the right counter     
         dummy              = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
       reads,dummy,orbmode_dummy,GB_dummy,MCLEN_dummy,notused_dummy,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
       ORB_MD[i]           = orbmode_dummy
       MC_LEN[i]           = MClen_dummy
       SMP_AVG[i]          = SMPAVG_dummy   
       GB_e12_hf[i]        = GB_dummy
         ACT_MF_PKTCNT[ni] = newfile_unsigned[counter+place+offset1] 
         n_packets          = floor((((length[i]-1)/2)-4)/29)
         ACT_MF_pktarr[ni] = n_packets        
         if ni EQ 0 then ACT_S_MF =                         [newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]] $  ;variable length
                    else ACT_S_MF =               [ACT_S_MF, newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]]
         if concatention EQ 'off' then ACT_MF_array[ni,*] = [newfile_unsigned[counter+place+offset1+1:counter+place+offset1+floor(length(i)+1)/2+3+offset2+1-9]]
         p15                = p15 + 1
   ENDFOR                                                                               ;loop over the packets
   t2=SYSTIME(1,/seconds)                                                               ;to check on speed
   print,'#### ACT_MF ',ni,i,' time ', t2-t1 ,' seconds'  
      ACT_MF_SC = SC[pkt_ACT_MF]
      for seqIndx = 1, nn_ACT_MF-1 do $
          if ACT_MF_SC[seqIndx] NE ACT_MF_SC[seqIndx-1]+1 then print, 'ACT_S_MF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_MF_SC[seqIndx-1], '  SC(seqIndx) =', ACT_MF_SC[seqIndx]
      if (ACT_MF_SC[nn_ACT_MF-1]-ACT_MF_SC[0]+1) NE p15 then print, 'ACT_S_MF Sequence Count Failed. Should be', p15, ' Reporting ',(ACT_MF_SC[nn_ACT_MF-1]-ACT_MF_SC[0]+1)
      total_act_s_mf_length = total(length[pkt_ACT_MF]+7)
    endif  ELSE BEGIN                                                                    ; case on no pkt
   ACT_S_MF          = -1 &   ACT_MF_PKTCNT     = -1 &    ACT_MF_PKTARR     = -1 & ENDELSE
  

  
;ACT_S_HF Packets 
   total_act_s_hf_length = 0 
   if nn_ACT_HF GT 0 and nn_act_ACT_HF GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                                                 ;to check on speed
     ACT_S_HF          = !values.f_nan                                                    ;variable length fltarr(nn_ACT_LF*116)
     ACT_HF_PKTCNT     = fltarr(nn_ACT_HF)
     ACT_HF_PKTARR     = fltarr(nn_ACT_HF)
     FOR ni=0L,nn_ACT_HF-1 do begin
         i                   = pkt_ACT_HF[ni]                                             ;which paket in the large file
         counter             = counter_specific[i]                                        ;get the right counter     
         dummy              = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
       reads,dummy,orbmode_dummy,GB_dummy,MCLEN_dummy,notused_dummy,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
       ORB_MD[i]           = orbmode_dummy
       MC_LEN[i]           = MClen_dummy
       SMP_AVG[i]          = SMPAVG_dummy   
       GB_e12_hf[i]        = GB_dummy
         ACT_HF_PKTCNT[ni] = newfile_unsigned[counter+place+offset1]
         n_packets          = floor((((length[i]-1)/2)-4)/65)
         ACT_HF_pktarr[ni] = n_packets
         if ni EQ 0 then ACT_S_HF =                         [newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*65)-1]] $    ;variable length
                    else ACT_S_HF =               [ACT_S_HF, newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*65)-1]]
         if concatention EQ 'off' then ACT_HF_array(ni,*) = [newfile_unsigned[counter+place+offset1+1:counter+place+offset1+floor(length[i]+1)/2+2+offset2+1-8]]
         p16 = p16 + 1
   ENDFOR                                                                                 ;loop over the packets
   t2=SYSTIME(1,/seconds)                                                                  ;to check on speed
   print,'#### ACT_HF ',ni,i,' time ', t2-t1 ,' seconds' 
      ACT_HF_SC = SC[pkt_ACT_HF]
      for seqIndx = 1, nn_ACT_HF-1 do $
         if ACT_HF_SC[seqIndx] NE ACT_HF_SC[seqIndx-1]+1 then print, 'ACT_S_HF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_HF_SC[seqIndx-1], '  SC(seqIndx) =', ACT_HF_SC[seqIndx]
      if (ACT_HF_SC[nn_ACT_HF-1]-ACT_HF_SC[0]+1) NE p16 then print, 'ACT_S_HF Sequence Count Failed. Should be', p16, ' Reporting ',(ACT_HF_SC[nn_ACT_HF-1]-ACT_HF_SC[0]+1)
      total_act_s_hf_length = total(length[pkt_ACT_HF]+7)
   endif ELSE BEGIN                                                                       ; case on no pkt
   ACT_S_HF          = -1 &   ACT_HF_PKTCNT     = -1 &    ACT_HF_PKTARR     = -1 & ENDELSE

  
; PAS_S_LF Packet 
   total_pas_s_lf_length = 0
   if nn_PAS_LF GT 0 and nn_act_PAS_LF GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                                                 ;to check on speed
     PAS_S_LF          = !values.f_nan                                                    ;variable length fltarr(nn_ACT_LF*116)
     PAS_LF_PKTCNT     = fltarr(nn_PAS_LF)
     PAS_LF_PKTARR     = fltarr(nn_PAS_LF)
     FOR ni=0L,nn_PAS_LF-1 do begin
         i                   = pkt_PAS_LF[ni]                                             ;which paket in the large file
         counter             = counter_specific[i]                                        ;get the right counter     
         dummy               = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
       reads,dummy,orbmode_dummy,GB_dummy,MCLEN_dummy,notused_dummy,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
       ORB_MD[i]           = orbmode_dummy
       MC_LEN[i]           = MClen_dummy
       SMP_AVG[i]          = SMPAVG_dummy   
       GB_e12_hf[i]        = GB_dummy
         PAS_LF_PKTCNT[ni]  = newfile_unsigned[counter+place+offset1]        
         n_packets           = floor((((length[i]-1)/2)-4)/29)
         PAS_LF_pktarr[ni]  = n_packets         
           if n_packets GT 0 then $        
          if ni EQ 0 then PAS_S_LF =                        [newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]]  $ ;variable length
                     else PAS_S_LF =              [PAS_S_LF, newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]]
         if concatention EQ 'off' then PAS_LF_array(ni,*) = [newfile_unsigned[counter+place+offset1+1:counter+place+offset1+floor(length[i]+1)/2+2+offset2+1-8]]
         p17                 = p17 + 1
   ENDFOR                                                                                   ;loop over the packets
   t2=SYSTIME(1,/seconds)                                                                   ;to check on speed
   print,'#### PAS_LF ',ni,i,' time ', t2-t1 ,' seconds' 
   PAS_LF_SC = SC[pkt_PAS_LF] 
   for seqIndx = 1, nn_PAS_LF-1 do begin
      if PAS_LF_SC[seqIndx] NE PAS_LF_SC[seqIndx-1]+1 then print, 'PAS_S_LF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_LF_SC[seqIndx-1], '  SC(seqIndx) =', PAS_LF_SC[seqIndx]
   endfor 
   if (PAS_LF_SC[nn_PAS_LF-1]-PAS_LF_SC[0]+1) NE p17 then print, 'PAS_S_LF Sequence Count Failed. Should be', p17, ' Reporting ',(PAS_LF_SC[nn_PAS_LF-1]-PAS_LF_SC[0]+1)
   total_pas_s_lf_length = total(length[pkt_PAS_LF]+7)
  endif ELSE BEGIN                                                                          ; case on no pkt
   PAS_S_LF          = -1 &   PAS_LF_PKTCNT     = -1 &    PAS_LF_PKTARR     = -1 & ENDELSE

 
;PAS_S_MF Packet   
   total_pas_s_mf_length = 0
   if nn_PAS_MF GT 0 and nn_act_PAS_MF GT 0 then begin     
      t1=SYSTIME(1,/seconds)                                                                ;to check on speed
     PAS_S_MF          = !values.f_nan                                                      ;variable length fltarr(nn_ACT_LF*116)
     PAS_MF_PKTCNT     = fltarr(nn_PAS_MF)
     PAS_MF_PKTARR     = fltarr(nn_PAS_MF)
     FOR ni=0L,nn_PAS_MF-1 do begin
         i                   = pkt_PAS_MF[ni]                                               ;which paket in the large file
         counter             = counter_specific[i]                                          ;get the right counter     
         dummy               = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
       reads,dummy,orbmode_dummy,GB_dummy,MCLEN_dummy,notused_dummy,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
       ORB_MD[i]           = orbmode_dummy
       MC_LEN[i]           = MClen_dummy
       SMP_AVG[i]          = SMPAVG_dummy   
       GB_e12_hf[i]        = GB_dummy
         PAS_MF_PKTCNT[ni]  = newfile_unsigned[counter+place+offset1]
         n_packets           = floor((((length[i]-1)/2)-4)/29)
         PAS_MF_pktarr[ni]  = n_packets 
      if n_packets GT 0 then $
          if ni EQ 0 then PAS_S_MF =                        [newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]] $  ;variable length
                     else PAS_S_MF =              [PAS_S_MF, newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*29)-1]]
         if concatention EQ 'off' then PAS_MF_array[ni,*] = [newfile_unsigned[counter+place+offset1+1:counter+place+offset1+floor(length[i]+1)/2+2+offset2+1-8]]
         p18                 = p18 + 1
   ENDFOR                                                                                   ;loop over the packets
 t2=SYSTIME(1,/seconds)                                                                     ;to check on speed
print,'#### PAS_MF ',ni,i,' time ', t2-t1 ,' seconds'    
      PAS_MF_SC = SC[pkt_PAS_MF]
      for seqIndx = 1, nn_PAS_MF-1 do $
          if PAS_MF_SC[seqIndx] NE PAS_MF_SC[seqIndx-1]+1 then print, 'PAS_S_MF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_MF_SC[seqIndx-1], '  SC(seqIndx) =', PAS_MF_SC[seqIndx]
      if (PAS_MF_SC[nn_PAS_MF-1]-PAS_MF_SC[0]+1) NE p18 then print, 'PAS_S_MF Sequence Count Failed. Should be', p18, ' Reporting ',(PAS_MF_SC(nn_PAS_MF-1)-PAS_MF_SC(0)+1)
      total_pas_s_mf_length = total(length[pkt_PAS_MF]+7)
  endif ELSE BEGIN                                                                          ; case on no pkt
   PAS_S_MF          = -1 &   PAS_MF_PKTCNT     = -1 &    PAS_MF_PKTARR     = -1 & ENDELSE

 
;PAS_S_HF Packet 
   total_pas_s_hf_length = 0
   if nn_PAS_HF GT 0 and nn_act_PAS_HF GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                                                   ;to check on speed
     PAS_S_HF          = !values.f_nan                                                      ;variable length fltarr(nn_ACT_LF*116)
     PAS_HF_PKTCNT     = fltarr(nn_PAS_HF)
     PAS_HF_PKTARR     = fltarr(nn_PAS_HF)
     FOR ni=0L,nn_PAS_HF-1 do begin
         i                   = pkt_PAS_HF[ni]                                               ;which paket in the large file
         counter             = counter_specific[i]                                          ;get the right counter     
         dummy               = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
       reads,dummy,orbmode_dummy,GB_dummy,MCLEN_dummy,notused_dummy,SMPAVG_dummy,format = '(B04,B01,B03,B05,B03)'
       ORB_MD[i]           = orbmode_dummy
       MC_LEN[i]           = MClen_dummy
       SMP_AVG[i]          = SMPAVG_dummy   
       GB_e12_hf[i]        = GB_dummy 
         PAS_HF_PKTCNT[ni]  = newfile_unsigned[counter+place+offset1]        
         n_packets           = floor((((length[i]-1)/2)-4)/65)
         PAS_HF_pktarr[ni]  = n_packets 
         if ni EQ 0 then PAS_S_HF =                         [newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*65)-1]]  $   ;variable length
                    else PAS_S_HF =               [PAS_S_HF, newfile_unsigned[counter+place+offset1  :counter+place+offset1+(n_packets*65)-1]]
         if concatention EQ 'off' then PAS_HF_array(ni,*) = [newfile_unsigned[counter+place+offset1+1:counter+place+offset1+floor(length[i]+1)/2+2+offset2+1-8]]
         p19                 = p19 + 1
    ENDFOR                                                                                    ;loop over the packets
    t2=SYSTIME(1,/seconds)                                                                    ;to check on speed
    print,'#### PAS_HF ',ni,i,' time ', t2-t1 ,' seconds' 
      PAS_HF_SC = SC[pkt_PAS_HF]
      for seqIndx = 1, nn_PAS_HF-1 do $
          if PAS_HF_SC[seqIndx] NE PAS_HF_SC[seqIndx-1]+1 then print, 'PAS_S_HF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_HF_SC[seqIndx-1], '  SC(seqIndx) =', PAS_HF_SC[seqIndx]
       if (PAS_HF_SC[nn_PAS_HF-1]-PAS_HF_SC[0]+1) NE p19 then print, 'PAS_S_HF Sequence Count Failed. Should be', p19, ' Reporting ',(PAS_HF_SC[nn_PAS_HF-1]-PAS_HF_SC[0]+1)
       total_pas_s_hf_length = total(length[pkt_PAS_HF]+7)  
  endif  ELSE BEGIN                                                                           ; case on no pkt
   PAS_S_HF          = -1 &   PAS_HF_PKTCNT     = -1 &    PAS_HF_PKTARR     = -1 & ENDELSE




;HSBM LF packets
  total_hsbm_lf_length = 0
  if nn_HSBM_LF GT 0 and nn_act_HSBM_LF GT 0 then BEGIN 
  t1=SYSTIME(1,/seconds)                                                                      ;to check on speed      
      FOR ni=0L,nn_HSBM_LF-1 do begin  
         i                     = pkt_HSBM_LF[ni]                                              ;which paket in the large file
         counter               = counter_specific[i]                                          ;get the right counter       
         dummy                 = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
         reads,dummy,orbmode_dummy,nothing,format = '(B04,B12)'
         ORB_MD[i]             = orbmode_dummy   
         if compressed EQ 1 then  begin   
           ptr     = 1L*(counter+place+offset1)                                                ; which 16 bit package to start with (counter+place+offset1:counter+place+floor(length(i)+1)/2+2+offset2)  
           ptr_end = ptr+(floor(length[i]+1)/2+2+offset2-offset1+1)                            ; this has to be checked!!!
           nn_e    = 0                                                                          ; this is when the data is not eact a factor of 16     
    ptr_old=ptr
           decomp  =                                    mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,32,edac_on)            
 ; print,'@@@@ ',newfile_unsigned(ptr:ptr+31),format='(a16,32z5)'
  ;   print,'$HSBMLF$$$$$',(sc_clk1[i]+sc_clk2[i]/65536d)-4.395e+8, ' s ',ptr_old,' d ',ptr_end-ptr, ' s ', nn_e ,' X '  , $
  ;        decomp[0] ,decomp[14]  ,decomp[15]  ,decomp[16]  ,decomp[17]  ,decomp[30]  ,decomp[31] ,'# ',newfile_unsigned[15+ptr_old:18+ptr_old],'$ ',newfile_unsigned[15+ptr_old:18+ptr_old], $
  ;        format='(a12,f12.3,a3,i6,a3,i4,a3,i3,a3,7f9.0,a3,4b16,a3,4z4)'  
 ;print,'----'
 ; print,'----' 
 ;if (sc_clk1[i]+sc_clk2[i]/65536d)-4.395e+8 GT 41033.  THEN stanna
            if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat HSBM_LF'          
           while ((ptr_end-ptr)*16-nn_e) ge (16+7+(31*2)) do begin            
               decomp = [decomp,mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,32,edac_on)] ;the rest of the times
           endwhile
           p                = ptr_new(decomp)                                       ; if compressed                               
          endif else p         = ptr_new(d)                                         ; if not compressed     
          if ni EQ 0 then BEGIN
              hsbm_lf_i             =  i                                             ; keeps track of where in the file the hsbm_i packets are    
              hsbm_lf_comp_t        = sc_clk1[i]+sc_clk2[i]/65536d                   ;keeps track of the first time stamp since it might be multiple packages           
              hsbm_lf_comp_p        = p                                              ;keeps track of the pointer
          ENDIF ELSE BEGIN
             hsbm_lf_i             = [hsbm_lf_i, i]                                ; keeps track of where in the file the hsbm_i packets are    
             hsbm_lf_comp_t        = [hsbm_lf_comp_t,sc_clk1[i]+sc_clk2[i]/65536d]  ;keeps track of the first time stamp since it might be multiple packages           
             hsbm_lf_comp_p        = [hsbm_lf_comp_p,p]                             ;keeps track of the pointer     
         ENDELSE   
      ENDFOR                                                                        ;loop over  nn_HSBM_LF 
      t2=SYSTIME(1,/seconds)                                                        ;to check on speed
      print,'#### HSBM LF ',ni,i,' time ', t2-t1,' seconds' 
      HSBM_LF_SC = SC[HSBM_LF_i]
      nn=n_elements(HSBM_LF_i)
      for seqIndx = 1, nn-1 do $
          if HSBM_LF_SC[seqIndx] NE HSBM_LF_SC[seqIndx-1]+1 then print, 'HSBM_LF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSBM_LF_SC[seqIndx-1], '  SC(seqIndx) =', HSBM_LF_SC[seqIndx]
      if (HSBM_LF_SC[nn-1]-HSBM_LF_SC[0]+1) NE nn then print, 'HSBM_LF Sequence Count Failed. Should be', nn, ' Reporting ',(HSBM_LF_SC[nn-1]-HSBM_LF_SC[0]+1)
      total_hsbm_lf_length = total(length[HSBM_LF_i]+7)
   endif ;HSBM_LF

 


;HSBM MF packets
  total_hsbm_mf_length = 0
  if nn_HSBM_MF GT 0 and nn_act_HSBM_MF GT 0 then BEGIN 
    t1=SYSTIME(1,/seconds)                                                            ;to check on speed     
      FOR ni=0L,nn_HSBM_MF-1 do begin  
         i                     = pkt_HSBM_MF[ni]                                      ;which paket in the large file
         counter               = counter_specific[i]                                  ;get the right counter       
         dummy                 = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
         reads,dummy,orbmode_dummy,nothing,format = '(B04,B12)'
         ORB_MD[i]             = orbmode_dummy   
           if compressed EQ 1 then  begin    
                ptr     = 1L*(counter+place+offset1)                                   ; which 16 bit package to start with (counter+place+offset1:counter+place+floor(length(i)+1)/2+2+offset2)  
                ptr_end = ptr+(floor(length[i]+1)/2+2+offset2-offset1+1)               ; this has to be checked!!!  
                nn_e    = 0                                                            ; this is when the data is not eact a factor of 16   
                decomp  =                                    mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,32,edac_on)        
          if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat HSBM_MF'
                while ((ptr_end-ptr)*16-nn_e) ge (16+7+(31*2)) do   decomp = [decomp,mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,32,edac_on)] ;the rest of the times
                p             = ptr_new(decomp)                                        ; if compressed             
          endif else p         = ptr_new(d)                                             ; if not compressed     
      if ni EQ 0 then BEGIN
         hsbm_mf_i             =  i                                             ; keeps track of where in the file the hsbm_i packets are    
         hsbm_mf_comp_t        = sc_clk1[i]+sc_clk2[i]/65536d                   ;keeps track of the first time stamp since it might be multiple packages           
         hsbm_mf_comp_p        = p                                              ;keeps track of the pointer
      ENDIF ELSE BEGIN
          hsbm_mf_i             = [hsbm_mf_i, i]                                ; keeps track of where in the file the hsbm_i packets are    
          hsbm_mf_comp_t        = [hsbm_mf_comp_t,sc_clk1[i]+sc_clk2[i]/65536d]  ;keeps track of the first time stamp since it might be multiple packages           
          hsbm_mf_comp_p        = [hsbm_mf_comp_p,p]                             ;keeps track of the pointer     
      ENDELSE   
     ENDFOR                                                                             ;loop over  nn_HSBM_MF 
     t2=SYSTIME(1,/seconds)                                                             ;to check on speed
     print,'#### HSBM MF ',ni,i,' time ', t2-t1 ,' seconds'
      HSBM_MF_SC = SC[HSBM_MF_i]
      nn=n_elements(HSBM_MF_i)
      for seqIndx = 1, nn-1 do $
          if HSBM_MF_SC[seqIndx] NE HSBM_MF_SC[seqIndx-1]+1 then print, 'HSBM_MF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSBM_MF_SC[seqIndx-1], '  SC(seqIndx) =', HSBM_MF_SC[seqIndx]
      if (HSBM_MF_SC[nn-1]-HSBM_MF_SC[0]+1) NE nn then print, 'HSBM_MF Sequence Count Failed. Should be', nn, ' Reporting ',(HSBM_MF_SC[nn-1]-HSBM_MF_SC[0]+1)
      total_hsbm_mf_length = total(length[HSBM_MF_i]+7)
   endif ;HSBM_MF
  
 


 ;HSBM HF packets
  total_hsbm_hf_length = 0
  if nn_HSBM_HF GT 0 and nn_act_HSBM_HF GT 0 then BEGIN 
  t1=SYSTIME(1,/seconds)                                                                ;to check on speed
      FOR ni=0L,nn_HSBM_HF-1 do begin  
         i                     = pkt_HSBM_HF[ni]                                        ;which paket in the large file
         counter               = counter_specific[i]                                    ;get the right counter       
         dummy                 = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')
         reads,dummy,orbmode_dummy,nothing,format = '(B04,B12)'
         ORB_MD[i]             = orbmode_dummy   
         if compressed EQ 1 then  begin    
                ptr     = 1L*(counter+place+offset1)                                    ; which 16 bit package to start with (counter+place+offset1:counter+place+floor(length(i)+1)/2+2+offset2)  
                ptr_end = ptr+(floor(length[i]+1)/2+2+offset2-offset1+1)                ; this has to be checked!!!  
                nn_e    = 0                                                             ; this is when the data is not eact a factor of 16   
                decomp  =                                    mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,32,edac_on)        
         if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat HSBM_HF'
                while ((ptr_end-ptr)*16-nn_e) ge (16+7+(31*2)) do  decomp = [decomp,mvn_lpw_r_block32(newfile_unsigned,ptr,nn_e,mask16,bin_c,index_arr,32,edac_on)] ;the rest of the times
                 p             = ptr_new(decomp)                                        ; if compressed          
          endif else p         = ptr_new(d)                                             ; if not compressed     
      if ni EQ 0 then BEGIN
         hsbm_hf_i             =  i                                             ; keeps track of where in the file the hsbm_i packets are    
         hsbm_hf_comp_t        = sc_clk1[i]+sc_clk2[i]/65536d                   ;keeps track of the first time stamp since it might be multiple packages           
         hsbm_hf_comp_p        = p                                              ;keeps track of the pointer
      ENDIF ELSE BEGIN
          hsbm_hf_i             = [hsbm_hf_i, i]                                ; keeps track of where in the file the hsbm_i packets are    
         hsbm_hf_comp_t        = [hsbm_hf_comp_t,sc_clk1[i]+sc_clk2[i]/65536d]  ;keeps track of the first time stamp since it might be multiple packages           
         hsbm_hf_comp_p        = [hsbm_hf_comp_p,p]                             ;keeps track of the pointer     
      ENDELSE   
     ENDFOR                                                                              ;loop over  nn_HSBM_HF 
     t2=SYSTIME(1,/seconds)                                                              ;to check on speed
     print,'#### HSBM HF ',ni,i,' time ', t2-t1 ,' seconds'    
      HSBM_HF_SC = SC[HSBM_HF_i]
      nn=n_elements(HSBM_HF_i)
      for seqIndx = 1, nn-1 do $
          if HSBM_HF_SC[seqIndx] NE HSBM_HF_SC[seqIndx-1]+1 then print, 'HSBM_HF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSBM_HF_SC[seqIndx-1], '  SC(seqIndx) =', HSBM_HF_SC[seqIndx]
      if (HSBM_HF_SC[nn-1]-HSBM_HF_SC[0]+1) NE nn then print, 'HSBM_HF Sequence Count Failed. Should be', nn, ' Reporting ',(HSBM_HF_SC[nn-1]-HSBM_HF_SC[0]+1)
      total_hsbm_hf_length = total(length[HSBM_HF_i]+7)
   endif ;HSBM_HF
   

  ; htime packets
    total_htime_length = 0
    if nn_htime GT 0 and nn_act_htime GT 0 then begin     
    t1=SYSTIME(1,/seconds)                                                                ;to check on speed
     FOR ni=0L,nn_htime-1 do begin
         i                   = pkt_htime[ni]                                              ;which paket in the large file
         counter             = counter_specific[i]                                        ;get the right counter     
             
         dummy               = string(newfile_unsigned[counter+place+offset1-1],format = '(B016)')         
         reads,dummy,HTIMErate_dummy,notused_dummy,ENB_dummy,notused_dummy,DISDLY_dummy,HFBUF_dummy,MFBUF_dummy,LFBUF_dummy,format = '(B04,B03,B01,B01,B01,B02,B02,B02)'            
         SMP_AVG[i]          = HTIMErate_dummy                                            ;use this to get it out  Rate = 2 ^rpt_rate second  ICD table 7.8
         nn                  = (((long(length[i])-1)/2)-7)/2+1
   If nn GT 0 then begin
         cap_time2           = fltarr(nn)
         htime_type2         = intarr(nn)
         xfer_time2          = fltarr(nn)
      for iii = 0,nn-1 do begin
          cap_time2(iii)     =          newfile_signed[counter+place+offset1+2*iii] 
          dummy              = string(newfile_unsigned[counter+place+offset1+2*iii+1],format = '(B016)')
          reads,dummy,type_dummy,xfertime_dummy,format = '(B02,B014)'
          htime_type2[iii]   = type_dummy 
          xfer_time2[iii]    = xfertime_dummy 
      endfor
      if ni EQ 0 then cap_time   = cap_time2    ELSE cap_time              = [cap_time   ,cap_time2]
      if ni EQ 0 then htime_type = htime_type2  ELSE htime_type            = [htime_type ,htime_type2]
      if ni EQ 0 then xfer_time  = xfer_time2   ELSE xfer_time             = [xfer_time  ,xfer_time2]       
      p23 = p23 + 1
 ENDIF                                                                                    ;nn GT 0
      ENDFOR                                                                              ;loop over packets     
      t2=SYSTIME(1,/seconds)                                                              ;to check on speed
      print,'#### htime ',ni,i,' time ', t2-t1 ,' seconds'  
       HTIME_SC = SC[pkt_htime]
      for seqIndx = 1, nn_htime-1 do $
          if HTIME_SC[seqIndx] NE HTIME_SC[seqIndx-1]+1 then print, 'HTIME Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HTIME_SC[seqIndx-1], '  SC(seqIndx) =', HTIME_SC[seqIndx]
      if (HTIME_SC[nn_htime-1]-HTIME_SC[0]+1) NE p23 then print, 'HTIME Sequence Count Failed. Should be', p23, ' Reporting ',(HTIME_SC[nn_htime-1]-HTIME_SC[0]+1)
      total_htime_length = total(length[pkt_htime]+7)
   endif ELSE BEGIN                                                                       ; case on no pkt
    xfer_time     = !values.f_nan &   cap_time      = !values.f_nan &    htime_type    = !values.f_nan & ENDELSE  ;htime



;Waveform packets w1 to w5
;Waveform preallocations   - 
if nn_w2        GT 1 then w2_length       = floor(length(pkt_w2)+1)/2+3+offset3 else w2_length = 1
if nn_w4        GT 1 then w4_length       = floor(length(pkt_w4)+1)/2+3+offset3 else w4_length = 1
if nn_w5        GT 1 then w5_length       = floor(length(pkt_w5)+1)/2+3+offset3 else w5_length = 1
if nn_w2        GT 1 then waveform2_array = fltarr(n_elements(w2_length),w2_length(0)-8)    else waveform2_array = fltarr(1)
if nn_w4        GT 1 then waveform4_array = fltarr(n_elements(w4_length),w4_length(0)-8)    else waveform4_array = fltarr(1)
if nn_w5        GT 1 then waveform5_array = fltarr(n_elements(w5_length),w5_length(0)-8)    else waveform5_array = fltarr(1)
                                                          ;warning wave_config is not explicit for the packet w1 to w5 it just usest the last defined one
   total_w1_length = 0
   if nn_w1 GT 0 and nn_act_w1 GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                    ;to check on speed
     w1_length             = floor(length[pkt_w1]+1)/2+3+offset3
     waveform1_array       = fltarr(nn_w1,w1_length[0]-8)
     ;waveform1             = fltarr(total(w1_length))
     wave_config          = newfile_unsigned[counter_all1[pkt_w1]+place+offset1-1]
    FOR ni=0,nn_w1-1 do begin
       w_length_ni         = floor(length[pkt_w1[ni]]+1)/2-5+offset2+offset3+1
       if w_length_ni EQ (w1_length[0]-8) THEN $ 
            waveform1_array[ni,*] = newfile_signed[counter_all1[pkt_w1[ni]] +place+offset1:counter_all1[pkt_w1[ni]] +place+offset1+floor(length[pkt_w1[ni]]+1)/2-5+offset2+offset3] $
       ELSE  Print,' THIS packet w1 had something strange in it ',APID(pkt_w1(ni)),ni,' this ', w_length_ni,' should be this ',(w1_length(0)-8) 
    ENDFOR     
    p1                       = nn_w1
    t2=SYSTIME(1,/seconds)                                   ;to check on speed
    print,'#### w1 ',ni,i,' time ', t2-t1 ,' seconds'  
      W1_SC = SC[pkt_w1]
      nn=n_elements(pkt_w1)
      for seqIndx = 1, nn-1 do $
          if W1_SC[seqIndx] NE W1_SC[seqIndx-1]+1 then print, 'Waveform 1 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', W1_SC[seqIndx-1], '  SC(seqIndx) =', W1_SC[seqIndx]
      if (W1_SC[nn-1]-W1_SC[0]+1) NE p1 then print, 'Waveform 1 Sequence Count Failed. Should be', p1, ' Reporting ',(W1_SC[nn-1]-W1_SC[0]+1)
      total_w1_length = total(length[pkt_w1]+7)
   endif else waveform1_array = fltarr(1)                      ;w1

  total_w2_length = 0
   if nn_w2 GT 0 and nn_act_w2 GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                     ;to check on speed
     w2_length             = floor(length[pkt_w2]+1)/2+3+offset3
     waveform2_array       = fltarr(nn_w2,w2_length[0]-8)
     ;waveform2             = fltarr(total(w2_length))
     wave_config          = newfile_unsigned[counter_all1[pkt_w2]+place+offset1-1]
    FOR ni=0,nn_w2-1 do begin
       w_length_ni         = floor(length[pkt_w2[ni]]+1)/2-5+offset2+offset3+1
       if w_length_ni EQ (w2_length[0]-8) THEN $ 
            waveform2_array[ni,*] = newfile_signed[counter_all1[pkt_w2[ni]] +place+offset1:counter_all1[pkt_w2[ni]] +place+offset1+floor(length[pkt_w2[ni]]+1)/2-5+offset2+offset3] $
       ELSE  Print,' THIS packet w2 had something strange in it ',APID[pkt_w2[ni]],ni,' this ', w_length_ni,' should be this ',(w2_length[0]-8) 
    ENDFOR     
    p2                       = nn_w2
    t2=SYSTIME(1,/seconds)                                      ;to check on speed
    print,'#### w2 ',ni,i,' time ', t2-t1 ,' seconds'  
      W2_SC = SC[pkt_w2]
      nn=n_elements(pkt_w2)
      for seqIndx = 1, nn-1 do $
          if W2_SC[seqIndx] NE W2_SC[seqIndx-1]+1 then print, 'Waveform 2 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', W2_SC[seqIndx-1], '  SC(seqIndx) =', W2_SC[seqIndx]
      if (W2_SC[nn-1]-W2_SC[0]+1) NE p2 then print, 'Waveform 2 Sequence Count Failed. Should be', p2, ' Reporting ',(W2_SC[nn-1]-W2_SC[0]+1)
      total_w2_length = total(length[pkt_w2]+7)
   endif else waveform2_array = fltarr(1)                         ;w2

   total_w3_length = 0
   if nn_w3 GT 0 and nn_act_w3 GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                       ;to check on speed
     w3_length             = floor(length[pkt_w3]+1)/2+3+offset3
     waveform3_array       = fltarr(nn_w3,w3_length[0]-8)
     ;waveform3             = fltarr(total(w3_length))
     wave_config          = newfile_unsigned[counter_all1[pkt_w3]+place+offset1-1]
    FOR ni=0,nn_w3-1 do begin
       w_length_ni         = floor(length[pkt_w3[ni]]+1)/2-5+offset2+offset3+1
       if w_length_ni EQ (w3_length[0]-8) THEN $ 
            waveform3_array[ni,*] = newfile_signed[counter_all1[pkt_w3[ni]] +place+offset1:counter_all1[pkt_w3[ni]] +place+offset1+floor(length[pkt_w3[ni]]+1)/2-5+offset2+offset3] $
       ELSE  Print,' THIS packet w3 had something strange in it ',APID[pkt_w3[ni]],ni,' this ', w_length_ni,' should be this ',(w3_length[0]-8) 
    ENDFOR     
    p3                       = nn_w3
    t2=SYSTIME(1,/seconds)                                        ;to check on speed
    print,'#### w3 ',ni,i,' time ', t2-t1 ,' seconds'  
      W3_SC = SC[pkt_w3]
      nn=n_elements(pkt_w3)
      for seqIndx = 1, nn-1 do $
          if W3_SC[seqIndx] NE W3_SC[seqIndx-1]+1 then print, 'Waveform 3 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', W3_SC[seqIndx-1], '  SC(seqIndx) =', W3_SC[seqIndx]
      if (W3_SC[nn-1]-W3_SC[0]+1) NE p3 then print, 'Waveform 3 Sequence Count Failed. Should be', p3, ' Reporting ',(W3_SC[nn-1]-W3_SC[0]+1)
      total_w3_length = total(length[pkt_w3]+7)
   endif else waveform3_array = fltarr(1)                        ;w3

  total_w4_length = 0
   if nn_w4 GT 0 and nn_act_w4 GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                         ;to check on speed
     w4_length             = floor(length[pkt_w4]+1)/2+3+offset3
     waveform4_array       = fltarr(nn_w4,w4_length[0]-8)
     ;waveform4             = fltarr(total(w4_length))
     wave_config          = newfile_unsigned[counter_all1[pkt_w4]+place+offset1-1]
    FOR ni=0,nn_w4-1 do begin
       w_length_ni         = floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3+1      
       print,'$$$$ w4 ',1.0*((counter_all1[pkt_w4[ni]] +place+offset1+floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3) - (floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3)), $
                     counter_all1[pkt_w4[ni]] +place+offset1,counter_all1[pkt_w4[ni]] +place+offset1+floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3
       if 1.0*((counter_all1[pkt_w4[ni]] +place+offset1+floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3) - (floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3)) GT 0 then $
       if w_length_ni EQ (w4_length[0]-8) THEN $ 
            waveform4_array[ni,*] = newfile_signed[counter_all1[pkt_w4[ni]] +place+offset1:counter_all1[pkt_w4[ni]] +place+offset1+floor(length[pkt_w4[ni]]+1)/2-5+offset2+offset3] $
       ELSE  Print,' THIS packet w4 had something strange in it ',APID[pkt_w4[ni]],ni,' this ', w_length_ni,' should be this ',(w4_length[0]-8) 
    ENDFOR     
    p4                       = nn_w4
    t2=SYSTIME(1,/seconds)                                        ;to check on speed
    print,'#### w4 ',ni,i,' time ', t2-t1 ,' seconds'  
      W4_SC = SC[pkt_w4]
      nn=n_elements(pkt_w4)
      for seqIndx = 1, nn-1 do $
          if W4_SC[seqIndx] NE W4_SC[seqIndx-1]+1 then print, 'Waveform 4 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', W4_SC[seqIndx-1], '  SC(seqIndx) =', W4_SC[seqIndx]
      if (W4_SC[nn-1]-W4_SC[0]+1) NE p4 then print, 'Waveform 4 Sequence Count Failed. Should be', p4, ' Reporting ',(W4_SC[nn-1]-W4_SC[0]+1)
      total_w4_length = total(length[pkt_w4]+7)
   endif else waveform4_array = fltarr(1)                         ;w4

  total_w5_length = 0
   if nn_w5 GT 0 and nn_act_w5 GT 0 then begin     
   t1=SYSTIME(1,/seconds)                                         ;to check on speed
     w5_length             = floor(length[pkt_w5]+1)/2+3+offset3
     waveform5_array       = fltarr(nn_w5,w5_length[0]-8)
     ;waveform5             = fltarr(total(w5_length))
     wave_config          = newfile_unsigned[counter_all1[pkt_w5]+place+offset1-1]
    FOR ni=0,nn_w5-1 do begin
       w_length_ni         = floor(length[pkt_w5[ni]]+1)/2-5+offset2+offset3+1
       if w_length_ni EQ (w5_length[0]-8) THEN $ 
            waveform5_array[ni,*] = newfile_signed[counter_all1[pkt_w5[ni]] +place+offset1:counter_all1[pkt_w5[ni]] +place+offset1+floor(length[pkt_w5[ni]]+1)/2-5+offset2+offset3] $
       ELSE  Print,' THIS packet w5 had something strange in it ',APID[pkt_w5[ni]],ni,' this ', w_length_ni,' should be this ',(w5_length[0]-8) 
    ENDFOR     
    p5                       = nn_w5
    t2=SYSTIME(1,/seconds)                                        ;to check on speed
    print,'#### w5 ',ni,i,' time ', t2-t1 ,' seconds'  
      W5_SC = SC[pkt_w5]
      nn=n_elements(pkt_w5)
      for seqIndx = 1, nn-1 do $
          if W5_SC[seqIndx] NE W5_SC[seqIndx-1]+1 then print, 'Waveform 5 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', W5_SC[seqIndx-1], '  SC(seqIndx) =', W5_SC[seqIndx]
      if (W5_SC[nn-1]-W5_SC[0]+1) NE p5 then print, 'Waveform 5 Sequence Count Failed. Should be', p5, ' Reporting ',(W5_SC[nn-1]-W5_SC[0]+1)
      total_w5_length = total(length[pkt_w5]+7)
   endif else waveform5_array = fltarr(1)                         ;w5

  
  
  
   ;-------------------------------------- THe different packets read in ---------------------------------     
           
 
t1=SYSTIME(1,/seconds)   
  ;group together the matching hsbm packets
  ; DM - this code needs to be below the sequence number checking since hsbm_lf_i is used by the sequence number check
  ;      and is modified in this code
  hsbm_lf              =  !values.f_nan
  hsbm_mf              =  !values.f_nan 
  hsbm_hf              =  !values.f_nan
  
if n_elements(hsbm_lf_comp_t) gt 0 and nn_act_HSBM_LF GT 0 then mvn_lpw_r_group_hsbm,hsbm_lf_comp_t,hsbm_lf_comp_p,1024,hsbm_lf,p20,hsbm_lf_i
if n_elements(hsbm_mf_comp_t) gt 0 and nn_act_HSBM_MF GT 0 then mvn_lpw_r_group_hsbm,hsbm_mf_comp_t,hsbm_mf_comp_p,4096,hsbm_mf,p21,hsbm_mf_i
if n_elements(hsbm_hf_comp_t) gt 0 and nn_act_HSBM_HF GT 0 then mvn_lpw_r_group_hsbm,hsbm_hf_comp_t,hsbm_hf_comp_p,4096,hsbm_hf,p22,hsbm_hf_i

t2=SYSTIME(1,/seconds)                              ;to check on speed
print,'#### HSBM grouping ',' time ', t2-t1 ,' seconds'    

 ;--------------------------------------  Store it in the output structure  --------------------------------     

output=create_struct(   $                          ;To export the data in workable form
   'filename'            ,  filename        ,$
   'counter_all'     ,  counter_all1    ,$          ;the start of each packet
   'length'          ,  length          ,$
   'p1'              ,  p1              ,$
   'p2'              ,  p2              ,$
   'p3'              ,  p3              ,$
   'p4'              ,  p4              ,$
   'p5'              ,  p5              ,$
   'p6'              ,  p6              ,$
   'p7'              ,  p7              ,$
   'p8'              ,  p8              ,$
   'p9'              ,  p9              ,$
   'p10'             ,  p10             ,$
   'p11'             ,  p11             ,$
   'p12'             ,  p12             ,$
   'p13'             ,  p13             ,$
   'p14'             ,  p14             ,$
   'p15'             ,  p15             ,$
   'p16'             ,  p16             ,$
   'p17'             ,  p17             ,$
   'p18'             ,  p18             ,$
   'p19'             ,  p19             ,$  
   'p20'             ,  p20             ,$
   'p21'             ,  p21             ,$
   'p22'             ,  p22             ,$
   'p23'             ,  p23             ,$
   'i'               ,  i               ,$
   'ADR_i'           ,  pkt_ADR         ,$
   'ATR_i'           ,  pkt_ATR         ,$
   'HSK_i'           ,  pkt_HSK         ,$
   'EUV_i'           ,  pkt_EUV         ,$
   'SWP1_i'          ,  pkt_SWP1        ,$
   'SWP2_i'          ,  pkt_SWP2        ,$
   'PAS_i'           ,  pkt_PAS         ,$
   'ACT_i'           ,  pkt_ACT         ,$
   'ACT_S_HF_i'      ,  pkt_ACT_HF      ,$
   'ACT_S_MF_i'      ,  pkt_ACT_MF      ,$
   'ACT_S_LF_i'      ,  pkt_ACT_LF      ,$
   'PAS_S_HF_i'      ,  pkt_PAS_HF      ,$
   'PAS_S_MF_i'      ,  pkt_PAS_MF      ,$
   'PAS_S_LF_i'      ,  pkt_PAS_LF      ,$
   'W1_i'            ,  pkt_w1          ,$
   'W2_i'            ,  pkt_w2          ,$
   'W3_i'            ,  pkt_w3          ,$
   'W4_i'            ,  pkt_w4          ,$
   'W5_i'            ,  pkt_w5          ,$
   'HSBM_LF_i'       ,  hsbm_LF_i       ,$
   'HSBM_MF_i'       ,  hsbm_MF_i       ,$
   'HSBM_HF_i'       ,  hsbm_HF_i       ,$
   'HTIME_i'         ,  pkt_htime       ,$
   'APID'            ,  APID            ,$
   'SC_CLK1'         ,  SC_CLK1         ,$
   'SC_CLK2'         ,  SC_CLK2         ,$
   'DFB_header'      ,  DFB_header      ,$
   'waveform1_array' ,  waveform1_array ,$
   'waveform2_array' ,  waveform2_array ,$
   'waveform3_array' ,  waveform3_array ,$
   'waveform4_array' ,  waveform4_array ,$
   'waveform5_array' ,  waveform5_array ,$
   'ATR_SWP'         ,  SWP             ,$
   'ATR_W_BIAS1'     ,  ATR_W_BIAS1     ,$
   'ATR_W_GUARD1'    ,  ATR_W_GUARD1    ,$
   'ATR_W_STUB1'     ,  ATR_W_STUB1     ,$
   'Reserved1'       ,  Reserved1       ,$
   'ATR_LP_BIAS1'    ,  ATR_LP_BIAS1    ,$
   'ATR_LP_GUARD1'   ,  ATR_LP_GUARD1   ,$
   'ATR_LP_STUB1'    ,  ATR_LP_STUB1    ,$
   'Reserved2'       ,  Reserved2       ,$
   'ATR_W_BIAS2'     ,  ATR_W_BIAS2     ,$
   'ATR_W_GUARD2'    ,  ATR_W_GUARD2    ,$
   'ATR_W_STUB2'     ,  ATR_W_STUB2     ,$
   'Reserved3'       ,  Reserved3       ,$
   'ATR_LP_BIAS2'    ,  ATR_LP_BIAS2    ,$
   'ATR_LP_GUARD2'   ,  ATR_LP_GUARD2   ,$
   'ATR_LP_STUB2'    ,  ATR_LP_STUB2    ,$
   'Reserved4'       ,  Reserved4       ,$
   'THERM'           ,  THERM           ,$
   'DIODE_A'         ,  DIODE_A         ,$
   'DIODE_B'         ,  DIODE_B         ,$
   'DIODE_C'         ,  DIODE_C         ,$
   'DIODE_D'         ,  DIODE_D         ,$
   'ADR_DYN_OFFSET1' ,  ADR_DYN_OFFSET1 ,$
   'ADR_LP_BIAS1'    ,  ADR_LP_BIAS1    ,$
   'ADR_DYN_OFFSET2'  , ADR_DYN_OFFSET2 ,$
   'ADR_LP_BIAS2'    ,  ADR_LP_BIAS2    ,$
   'ADR_W_BIAS1'     ,  ADR_W_BIAS1     ,$
   'ADR_W_GUARD1'    ,  ADR_W_GUARD1    ,$
   'ADR_W_STUB1'     ,  ADR_W_STUB1     ,$
   'ADR_W_V1'        ,  ADR_W_V1        ,$
   'ADR_LP_GUARD1'   ,  ADR_LP_GUARD1   ,$
   'ADR_LP_STUB1'    ,  ADR_LP_STUB1    ,$
   'ADR_W_BIAS2'     ,  ADR_W_BIAS2     ,$
   'ADR_W_GUARD2'    ,  ADR_W_GUARD2    ,$
   'ADR_W_STUB2'     ,  ADR_W_STUB2     ,$
   'ADR_W_V2'        ,  ADR_W_V2        ,$
   'ADR_LP_GUARD2'   ,  ADR_LP_GUARD2   ,$
   'ADR_LP_STUB2'    ,  ADR_LP_STUB2    ,$
   'Preamp_Temp1'    ,  Preamp_Temp1    ,$
   'Preamp_Temp2'    ,  Preamp_Temp2    ,$
   'Beb_Temp'        ,  Beb_Temp        ,$
   'plus12va'        ,  plus12va        ,$
   'minus12va'       ,  minus12va       ,$
   'plus5va'         ,  plus5va         ,$
   'minus5va'        ,  minus5va        ,$
   'plus90va'        ,  plus90va        ,$
   'minus90va'       ,  minus90va       ,$
   'CMD_ACCEPT'      ,  CMD_ACCEPT      ,$
   'CMD_REJECT'      ,  CMD_REJECT      ,$
   'MEM_SEU_COUNTER' ,  MEM_SEU_COUNTER ,$
   'INT_STAT'        ,  INT_STAT        ,$
   'CHKSUM'          ,  CHKSUM          ,$
   'EXT_STAT'        ,  EXT_STAT        ,$
   'DPLY1_CNT'       ,  DPLY1_CNT       ,$
   'DPLY2_CNT'       ,  DPLY2_CNT       ,$
   'SWP1_I1'         ,  SWP1_I1         ,$
   'SWP1_V2'         ,  SWP1_V2         ,$
   'I_ZERO1'         ,  I_ZERO1         ,$
   'SWP1_DYN_OFFSET1',  SWP1_DYN_OFFSET1,$
   'SWP2_I2'         ,  SWP2_I2         ,$
   'SWP2_V1'         ,  SWP2_V1         ,$
   'I_ZERO2'         ,  I_ZERO2         ,$
   'SWP2_DYN_OFFSET2',  SWP2_DYN_OFFSET2,$
   'ACT_V1'          ,  ACT_V1          ,$
   'ACT_V2'          ,  ACT_V2          ,$
   'ACT_E12_LF'      ,  ACT_E12_LF      ,$
   'PAS_V1'          ,  PAS_V1          ,$
   'PAS_V2'          ,  PAS_V2          ,$
   'PAS_E12_LF'      ,  PAS_E12_LF      ,$
   'course_clk'      ,  course_clk      ,$
   'ACT_S_HF'        ,  ACT_S_HF        ,$
   'ACT_S_MF'        ,  ACT_S_MF        ,$
   'ACT_S_LF'        ,  ACT_S_LF        ,$
   'PAS_S_HF'        ,  PAS_S_HF        ,$
   'PAS_S_MF'        ,  PAS_S_MF        ,$
   'PAS_S_LF'        ,  PAS_S_LF        ,$
   'ORB_MD'          ,  ORB_MD          ,$
   'E12_HF_GB'       ,  GB_e12_hf       ,$  
   'MC_LEN'          ,  MC_LEN          ,$
   'SMP_AVG'         ,  SMP_AVG         ,$
   'wave_config'     ,  wave_config     ,$  ;warning wave_config is not explicit for the packet w1 to w5 it just usest the last defined one
   'EUV_config'      ,  EUV_config      ,$
   'ADR_config'      ,  ADR_config      ,$
   'HSK_config'      ,  HSK_config      ,$
   'ATR_config'      ,  ATR_config      ,$
   'ACT_LF_PKTCNT'   ,  ACT_LF_PKTCNT   ,$
   'ACT_MF_PKTCNT'   ,  ACT_MF_PKTCNT   ,$
   'ACT_HF_PKTCNT'   ,  ACT_HF_PKTCNT   ,$
   'PAS_LF_PKTCNT'   ,  PAS_LF_PKTCNT   ,$
   'PAS_MF_PKTCNT'   ,  PAS_MF_PKTCNT   ,$
   'PAS_HF_PKTCNT'   ,  PAS_HF_PKTCNT   ,$
   'ACT_LF_PKTARR'   ,  ACT_LF_PKTARR   ,$
   'ACT_MF_PKTARR'   ,  ACT_MF_PKTARR   ,$
   'ACT_HF_PKTARR'   ,  ACT_HF_PKTARR   ,$
   'PAS_LF_PKTARR'   ,  PAS_LF_PKTARR   ,$
   'PAS_MF_PKTARR'   ,  PAS_MF_PKTARR   ,$
   'PAS_HF_PKTARR'   ,  PAS_HF_PKTARR   ,$
   'HSBM_LF'         ,  hsbm_lf         ,$   
   'HSBM_MF'         ,  hsbm_mf         ,$ 
   'HSBM_HF'         ,  hsbm_hf         ,$
   'xfer_time'       ,  xfer_time       ,$
   'htime_type'      ,  htime_type      ,$
   'cap_time'        ,  cap_time        , $
   'SC_CLK1_gst'     ,  SC_CLK1_gst      , $     ; time when the gst stamped the packet
   'SC_CLK2_gst'     ,  SC_CLK2_gst      , $     ; time when the gst stamped the packet
   'APID2'           ,  APID2      , $           ; should be the same as apid
   'length2'         ,  length2      , $         ; should be the same as packet length
   'SC_CLK3_gst'     ,  SC_CLK3_gst      , $     ; should be the same as sc_clk1
   'SC_CLK4_gst'     ,  SC_CLK4_gst      )       ; should be the same as sc_clk2
   


print,'Waveform 1:', p1,  ' packets  ',total_w1_length,' bytes'
print,'Waveform 2:', p2,  ' packets  ',total_w2_length,' bytes'
print,'Waveform 3:', p3,  ' packets  ',total_w3_length,' bytes'
print,'Waveform 4:', p4,  ' packets  ',total_w4_length,' bytes'
print,'Waveform 5:', p5,  ' packets  ',total_w5_length,' bytes'
print,'ATR:       ', p6,  ' packets  ',total_ATR_length,' bytes'
print,'EUV:       ', p7,  ' packets  ',total_euv_length,' bytes'
print,'ADR:       ', p8,  ' packets  ',total_adr_length,' bytes' 
print,'HSK:       ', p9,  ' packets  ',total_hsk_length,' bytes'
print,'SWP1_AVG:  ', p10, ' packets  ',total_swp1_length,' bytes'
print,'SWP2_AVG:  ', p11, ' packets  ',total_swp2_length,' bytes'
print,'ACT_AVG:   ', p12, ' packets  ',total_act_length,' bytes'
print,'PAS_AVG:   ', p13, ' packets  ',total_pas_length,' bytes'
print,'ACT_S_LF:  ', p14, ' packets  ',total_act_s_lf_length,' bytes'
print,'ACT_S_MF:  ', p15, ' packets  ',total_act_s_mf_length,' bytes'
print,'ACT_S_HF:  ', p16, ' packets  ',total_act_s_hf_length,' bytes'
print,'PAS_S_LF:  ', p17, ' packets  ',total_pas_s_lf_length,' bytes'
print,'PAS_S_MF:  ', p18, ' packets  ',total_pas_s_mf_length,' bytes'
print,'PAS_S_HF:  ', p19, ' packets  ',total_pas_s_hf_length,' bytes'
print,'HSBM_LF:   ', p20, ' buffers  ',total_hsbm_lf_length,' bytes'
print,'HSBM_MF:   ', p21, ' buffers  ',total_hsbm_mf_length,' bytes'
print,'HSBM_HF:   ', p22, ' buffers  ',total_hsbm_hf_length,' bytes'
print,'HTIME:     ', p23, ' packets  ',total_htime_length,' bytes'


t_end=SYSTIME(1,/seconds)                   ;to check on speed
print,' TOTAL time to read ',t_end-t_start, ' seconds'

end
