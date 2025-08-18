;+
;PROCEDURE:   mvn_lpw_r_header_l0
;PURPOSE:
;  Decomutater of the LPW telemetry data, THIS IS FOR L0-files, splitted files and gourn data use mvn_lpw_r_heared.pro
;          r_header orignal written by Corinne Vanatta and David Meyer
;          This routine reads the data file as BYTE
; This routine strips the packet headers off the data, and stores the data in various ways.
; The data is stored in one long structure
; The routine also prints out how many of each tpye of packet are present in the file.
; filename: the name of the file the data is in
; No WPK-packet will be in a L0-file and the data is always compressed
; SC gitter/clitch is corrected for
; More stricter rules to find the packets
;
;USAGE:
;  mvn_lpw_r_header, filename, output, packet=packet
;
;INPUTS:
;       filename:      The full filename (including path) of a binary file containing
;                      zero or more LPW APID's.
;
;KEYWORDS:
;       packet:     Which packets to read into memeory, default all packets Options: ['HSK','EUV','AVG','SPEC','HSBM']
;
;CREATED BY:   Laila Andersson  06-01-11
;FILE: mvn_lpw_r_header_l0.pro
;VERSION:   2.0
;VERSION:   2.0
;LAST MODIFICATION:  2019-12-30  L. Andersson
;2019-12-30 bad sc clock is removed but was time limeted to ~jan 2020, this is now expanded on 
;140718 FIs so that HSBM packets can be read
;Added the correction features for the 0.5 SC clock gitter  (C Fowler)
;Added a additional feature to find the packets using the SC variable (L. Andersson)
;;140718 clean up for check out L. Andersson
;2014-10-06: CF: 'packet' can now be uppper or lower input; mvn-lpw-load-file converts all to upper case.
;-

pro mvn_lpw_r_header_l0, filename,output,packet=packet

  t_start=SYSTIME(1,/seconds)                                            ;to check on speed
  t1=SYSTIME(1,/seconds)
  tmp=strsplit(filename,'/',/extract)                                ; should be mac way
  if n_elements(tmp) EQ 1 then tmp=strsplit(filename,'\',/extract)   ; should be PC way
  filename_short  =tmp[n_elements(tmp)-1]                            ; this is the name that is stored in the CDF file, the directory information is not of interest only the file name
  print,'lpw_loader filename ',filename,' short ', filename_short

  newfile_byte     = read_binary(filename, data_type = 1,endian='big')   ;read byte only  --note many packets have signed information
  concatention = 'on'                                                    ; this is the only option for this version
  ;--------------------------------------------------------------------
  ;THESE offset is not activated in this latest load routine, was needed in the different laboratory settings
  place         = 0; -- permanently set to not have message header in telemetry data
  offset1    = 7
  offset2    = -1
  len_offset =  9


  If (keyword_set(packet)) EQ 0 Then packet=['HSK','EUV','AVG','SPEC','HSBM','WPK']  ELSE BEGIN
    IF total(strmatch(packet, 'NOHSBM')) EQ 1 then packet=['HSK','EUV','AVG','SPEC']
    IF total(strmatch(packet, 'SPEC')) EQ 1 AND total(strmatch(packet, 'AVG')) EQ 0 then packet=[packet,'AVG']
  ENDELSE
  ; this is so that the grouping can be change to anything
  ;example for only get one group
  ;packet=['EUV']
  ;This is to identify which different type of LPW packets the loader should process, whch pkt are active:
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
  ;;
  ;
  ;WARNING ID DO NOT THE THE CHECK newfile_unsigned(0) eq 60304 that was in the original r_header!!!!
  ;-----------------------------------------------------------------------

  ; Data files with sc_headers
  ;********** THIS is where there is a need to flip *********** ; 5E last survey 5F, 60 and 61 HSBM and 67 HTIME
  ;print,'******* Searching for Old SC APID numbers !!! **********'
  ;SCAPID1=(newfile_byte GE 5*16+0) and (newfile_byte LE 5*16+2)  ;sc number 50,51, 52 this worked untill aug 2013
  ;SCAPID2=SCAPID1
  ;SCAPID1=(newfile_byte GE 5*16+0) and (newfile_byte LE 5*16+2)  ;sc number  52   <--- all other APID
  ;SCAPID2=(newfile_byte EQ 5*16+0)  ;sc number 50   <--- HSK APID 0x54

  ;from Tim Quin after aug 2013: S/C APID 0x50 is engineering, S/C APID 0x62 is science
  print,'******* Searching for NEW SC APID numbers !!! **********'
  SCAPID1=(newfile_byte EQ 6*16+2)  ;sc number  62
  SCAPID2=(newfile_byte EQ 5*16+0)  ;sc number 50
  ;***********************************************************
  INAPID1=((newfile_byte GE 5*16+0) and (newfile_byte LE 5*16+3)) or  $
    ((newfile_byte GE 5*16+5) and (newfile_byte LE 6*16+1)) or  $
    ((newfile_byte EQ 6*16+7))                              ;LPW inst number 50-67,omitting 54,62-66,HSBM has a second check
  ;INAPID1=((newfile_byte EQ 5*16+15))                            ;LPW inst number 50-67,omitting 54,62-66,HSBM has a second check
  INAPID2=(newfile_byte EQ 5*16+4)                                ;LPW inst number HSK
  NNAPID =(newfile_byte EQ 8)                                     ;08
  LEAPID =(newfile_byte LT 8)                                     ;try to avoid SC APID 52....make sure the length is LT 2048, i.e. byte +15 is less than 8
  ;this is a test....
  ADD1ID = (newfile_byte EQ 1*16+10) ; expect 1a  location 17

  ADDCLbyte = (newfile_byte[0:*]*256+newfile_byte[1:*]*256 GT 1*4096+12*256+5*16)    ; that first clock byte (byte no 17) are Greater or Equal to c1-hex and second  clock byte (byte no 18 ) are Greater or Equal to c1-hex

  ;THese are where the LPW packets are locates 12 appart
  tmp_ss1=SCAPID1[1:*]*INAPID1[12:*]*NNAPID[0:*]*NNAPID[11:*]*LEAPID[15:*]  * ADDCLbyte[17:*]
  tmp_ss2=SCAPID2[1:*]*INAPID2[12:*]*NNAPID[0:*]*NNAPID[11:*]*LEAPID[15:*]
  ;since there is problem with getting false HSBM packet test thefollowing
  ;;this is a test....find the clock to use that as a discriminator - this assumes the first packet is correct
  tmp1=newfile_byte[tmp_ss1[0]+17]   ; first time stamp
  ADD1ID = (newfile_byte GE tmp1-1)
  ADD2ID = (newfile_byte LE tmp1+1) ; look at the clock and only allow a narrow change in the clock over the file

  tmp_ss1=SCAPID1[1:*]*INAPID1[12:*]*NNAPID[0:*]*NNAPID[11:*]*LEAPID[15:*] ;changed 20141029  *ADD1ID(17:*)*ADD2ID(17:*)
  tmp_ss2=SCAPID2[1:*]*INAPID2[12:*]*NNAPID[0:*]*NNAPID[11:*]*LEAPID[15:*]

  min_length=(2L^8*newfile_byte[15:*]+newfile_byte[16:*])  GT 10
  tmp_ss=(tmp_ss1 +tmp_ss2)*min_length
  nn=n_elements(tmp_ss)
  qq=where(tmp_ss[0:nn-8],nq)

  ;******* special treatmenet
  keep=where((newfile_byte[qq+12] NE 94) or ((newfile_byte[qq+12] EQ 94) and (2L^8*newfile_byte[qq+15]+newfile_byte[qq+16] GT 256)) ,nq ) ;have issue with APID 5e == 94 , needs a longer packet to be an hit
  qq=qq[keep]
  ;******* special treatmenet

  APID=newfile_byte[qq+12]



  ;plot,newfile_byte(qq+17)


  ;print,'Number of packets ',nq,' using WHERE:SCAPID1(1:*)*INAPID1(12:*)*NNAPID(0:*)*NNAPID(11:*)*LEAPID(15:*)'
  ;print,' $$$$  number of short packets: ',total(2L^8*newfile_byte(qq)+newfile_byte(qq) LT 10)
  ;tmp=where((APID GE 6*16+2)*(APID LE 6*16+6) ,ntmp)
  ;print,'%% NO %%% ',tmp
  ;print,'%% NO %%% ',qq(tmp)
  ;print,'%%APID%%% ',APID(tmp) ;EQ  5*16+14
  ;print,'%%APID%%% ',newfile_byte(qq(tmp)+12) ;EQ  5*16+14
  ;print,'%%Q%% ',newfile_byte(qq(tmp)+0),newfile_byte(qq(tmp)+1),newfile_byte(qq(tmp)+11),newfile_byte(qq(tmp)+12),format='(a8,4z)' ;EQ  5*16+14


  If nq GT 0 then begin                                                         ; there is packets found in the file
    counter_specific=qq+11                                                        ;where should I point???? this points to the CCSDS Primary header location
    vers=newfile_byte[qq+11] /32                                                  ;it should be the first 3 bits in this byte (1 byte is 8 bits)
    type= newfile_byte[qq+11] /16 mod 8                                           ;packet type this should be bit no 4  0 indicate always telemetry
    SHF = newfile_byte[qq+11] /8 mod 16                                           ;secondary header flag should be 1 - this should be bit no 5
    GF= newfile_byte[qq+13]/ 64                                                   ;group flag first 2 bits
    SC=1L * (2L^8*(newfile_byte[qq+13] mod 2L^6)+newfile_byte[qq+14] )                ;source sequencse counts 14 bits
    length=2L^8*newfile_byte[qq+15]+newfile_byte[qq+16]                           ;the length of each packet  16 bits
    length_byte=(length+2)*2                                                      ;total length in 8 bits incl MSG header (16 bits before CCSDS prim header)
    SC_CLK1=double(2LL^24*newfile_byte[qq+17]+2LL^16*newfile_byte[qq+18]+2LL^8*newfile_byte[qq+19]+newfile_byte[qq+20])    ;seconds clock 32 bits
    SC_CLK2=double(2LL^8*newfile_byte[qq+21]+newfile_byte[qq+22])                 ;sub-secongs   16 bits
    length2=max(length)

    IF total(length2 GT 2048) GT 0 then print,'Warning: the length of ',total(length GT 2048),' packet are too long'
    IF total(length2 GT 2048) GT 0 then stanna                                    ;crash the program...
    t2=systime(1,/seconds)
    ;Print,' ## Find the APID took ',t2-t1,' seconds ##','   number of packets with lengths above 10 ',total(length GT 10),' less ',total(length LE 10)
    t1=systime(1,/seconds)


    ;  ;--------------------------------------------------------------------
    ;  ; there has been incorrect timestamps found
    ;  ;remove the extreme from the array by removing them in the APID array
    ;
    time_sc          = double(SC_CLK1) + SC_CLK2/2l^16
    tmp              = where( (time_sc GT 3.8e8 and time_sc LT 6.3e8*2) EQ 0,nq)  ; after ~jan 2012 while before ~jan 2020 based on zero is Jan 2000 (t_epoch)
    if nq GT 0 then APID[tmp] = 0   ; remove these packets
    ;--------------------------------------------------------------------


    ;****************
    ;THESE are variables defined in the original reader, needs to be defined for the output structure
    waveform1_array=0
    waveform2_array=0
    waveform3_array=0
    waveform4_array=0
    waveform5_array=0
    SC_CLK1_gst=0
    SC_CLK2_gst=0
    APID2 =0
    SC_CLK3_gst=0
    SC_CLK4_gst=0
    total_w1_length=0
    total_w2_length=0
    total_w3_length=0
    total_w4_length=0
    total_w5_length=0
    ;****************

    ;-------------------------------------------------
    ;number of pakets and which packets for each APID
    pkt_ATR             = where(APID EQ 81,nn_ATR)     ;5*16+1
    pkt_EUV             = where(APID EQ 82,nn_EUV)
    pkt_ADR             = where(APID EQ 83,nn_ADR)
    pkt_HSK             = where(APID EQ 84,nn_HSK)     ;5*16+4
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
    pkt_HSBM_MF         = where(APID EQ 96,nn_HSBM_MF) ;6*16
    pkt_HSBM_HF         = where(APID EQ 97,nn_HSBM_HF) ;6*16+1
    pkt_w1              = where(APID EQ 98,nn_w1)      ;6*16+2
    pkt_w2              = where(APID EQ 99,nn_w2)
    pkt_w3              = where(APID EQ 100,nn_w3)
    pkt_w4              = where(APID EQ 101,nn_w4)
    pkt_w5              = where(APID EQ 102,nn_w5)
    pkt_htime           = where(APID EQ 103,nn_htime)

    ;-------------------------------------------------

    sizelength       = size(length)                    ; total number of LPW packets
    If max(length) LT 6 and  sizelength[1]  EQ 0 then begin
      print,'### There was no LPW packets found in this file: ', filename,' ###'
    ENDIF ELSE BEGIN                                   ; there is LPW packets in the file
      print,'### There is LPW packets found in this file: ', filename,' ###'
      ;Preallocating values common over multiple packets
      data_fft         = fltarr(sizelength[1],max(length)-6)
      DFB_header       = strarr(sizelength[1],16)
      data             = fltarr(1)
      y                = fltarr(sizelength[1],30)
      course_clk       = fltarr(sizelength[1])
      ORB_MD           = fltarr(sizelength[1])
      MC_LEN           = fltarr(sizelength[1])
      SMP_AVG          = fltarr(sizelength[1])
      wave_config      = fltarr(sizelength[1])
      EUV_config       = fltarr(sizelength[1])
      ADR_config       = fltarr(sizelength[1])
      HSK_config       = fltarr(sizelength[1])
      ATR_config       = fltarr(sizelength[1])
      GB_e12_hf        = intarr(sizelength[1])          ;this is one bit in the tertiary header
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
      HSBM_LF_i     = -1.                 ;pkt_HSBM_LF will this be
      HSBM_MF_i     = -1.                 ;pkt_HSBM_MF will this be
      HSBM_HF_i     = -1.                 ;pkt_HSBM_FF will this be
      length        = length + 2          ;still true?
      ;this is to make quick conversions for the compressed data
      mvn_lpw_r_mask,mask16,mask8,bin_c,index_arr,flip_8
      mask16=0.                 ;;; no longer read the file as word, only as byte
      t2=systime(1,/seconds)
      ;         Print,' ## Allocation it took ',t2-t1,' seconds ##'

      ;############ Now for each type of packet will data be extracted into the created above structures ################

      ;ATR Packet   <---- only unsigned
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
          i                     = pkt_ATR[ni]
          counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
          ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B04,B03,B03,B01,B01)'
          SMP_AVG[i]            = newfile_byte[counter+1] /  2^5        ;rpt_rate DFB Tertiary header: format = '(B04,B04,B03,B03,B01,B01)'
          CHECKSUM              = newfile_byte[counter+1]/2 mod 2       ;checksum DFB Tertiary header: format = '(B04,B04,B03,B03,B01,B01)'
          ENB                   = newfile_byte[counter+1]   mod 2       ;enb      DFB Tertiary header: format = '(B04,B04,B03,B03,B01,B01)'
          merge_large=indgen(128)*2    +2                                 ; every other even
          merge_small=merge_large       +1                                ; every other odd
          SWP[p6,*]         = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
          nn=max(merge_small)+1                                            ; add the 2 directly
          ATR_W_BIAS1[p6]   = 2L^8*newfile_byte[counter+nn+0] + newfile_byte[counter+nn+1]
          ATR_W_GUARD1[p6]  = 2L^8*newfile_byte[counter+nn+2] + newfile_byte[counter+nn+3]
          ATR_W_STUB1[p6]   = 2L^8*newfile_byte[counter+nn+4] + newfile_byte[counter+nn+5]
          Reserved1[p6]     = 2L^8*newfile_byte[counter+nn+6] + newfile_byte[counter+nn+7]
          ATR_LP_BIAS1[p6]  = 2L^8*newfile_byte[counter+nn+8] + newfile_byte[counter+nn+9]
          ATR_LP_GUARD1[p6] = 2L^8*newfile_byte[counter+nn+10] + newfile_byte[counter+nn+11]
          ATR_LP_STUB1[p6]  = 2L^8*newfile_byte[counter+nn+12] + newfile_byte[counter+nn+13]
          Reserved2[p6]     = 2L^8*newfile_byte[counter+nn+14] + newfile_byte[counter+nn+15]
          ATR_W_BIAS2[p6]   = 2L^8*newfile_byte[counter+nn+16] + newfile_byte[counter+nn+17]
          ATR_W_GUARD2[p6]  = 2L^8*newfile_byte[counter+nn+18] + newfile_byte[counter+nn+19]
          ATR_W_STUB2[p6]   = 2L^8*newfile_byte[counter+nn+20] + newfile_byte[counter+nn+21]
          Reserved3[p6]     = 2L^8*newfile_byte[counter+nn+22] + newfile_byte[counter+nn+23]
          ATR_LP_BIAS2[p6]  = 2L^8*newfile_byte[counter+nn+24] + newfile_byte[counter+nn+25]
          ATR_LP_GUARD2[p6] = 2L^8*newfile_byte[counter+nn+26] + newfile_byte[counter+nn+27]
          ATR_LP_STUB2[p6]  = 2L^8*newfile_byte[counter+nn+28] + newfile_byte[counter+nn+29]
          Reserved4[p6]     = 2L^8*newfile_byte[counter+nn+30] + newfile_byte[counter+nn+31]
          p6 = p6 + 1
        ENDFOR                                                          ;loop over the packets
        t2=SYSTIME(1,/seconds)                                          ;to check on speed
        ;      print,'#### ATR ',ni,i,' time ', t2-t1 ,' seconds '
        ATR_SC = SC[pkt_ATR]
        for seqIndx = 1, nn_ATR-1 do $
          if ATR_SC[seqIndx] NE ATR_SC[seqIndx-1]+1 then print, 'ATR Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ATR_SC[seqIndx-1], '  SC(seqIndx) =', ATR_SC[seqIndx]
        if (ATR_SC[nn_ATR-1]-ATR_SC[0]+1) NE p6 then print, 'ATR Sequence Count Failed. Should be', p6, ' Reporting ',(ATR_SC[nn_ATR-1]-ATR_SC[0]+1)
        total_ATR_length = total(length[pkt_ATR]+7)
      endif else begin                                                    ; create defauls values -1 if not packets where found
        SWP           = -1 &  ATR_W_BIAS1   =  -1 & ATR_W_GUARD1  = -1 & ATR_W_STUB1   =  -1 & $
          Reserved1     =  -1 & ATR_LP_BIAS1  =  -1 & ATR_LP_GUARD1 =  -1 & ATR_LP_STUB1  =  -1 & $
          Reserved2     =  -1 & ATR_W_BIAS2   =  -1 & ATR_W_GUARD2  =  -1 & ATR_W_STUB2   =  -1 & $
          Reserved3     =  -1 & ATR_LP_BIAS2  =  -1 & ATR_LP_GUARD2 =  -1 & ATR_LP_STUB2  =  -1 & $
          Reserved4     =  -1 & ENDELSE


        ;EUV Packet    <--- have signed values but are compressed
        total_euv_length = 0
        if nn_EUV GT 0 and nn_act_EUV GT 0 then begin
          t1=SYSTIME(1,/seconds)                                           ;to check on speed
          ;EUV Preallocations
          THERM   = fltarr(nn_EUV,16)
          DIODE_A = fltarr(nn_EUV,16)
          DIODE_B = fltarr(nn_EUV,16)
          DIODE_C = fltarr(nn_EUV,16)
          DIODE_D = fltarr(nn_EUV,16)
          FOR ni=0L,nn_EUV-1 do begin
            i                     = pkt_EUV[ni]
            counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
            SMP_AVG[i]            =  newfile_byte[counter+1]/2L^4          ;DFB Tertiary header: 8-bits NaN; 4-bits SMP_AVE; 3-bits NaN; 1 bit EUV_ENABLE
            EUV_config[i]         =  newfile_byte[counter+1] mod 1        ;DFB Tertiary header: 8-bits NaN; 4-bits SMP_AVE; 3-bits NaN; 1 bit EUV_ENABLE
            ptr=1L*(counter+2)                                          ;which 16 bit package to start with, checked O
            ptr_end=ptr+length_byte[i]-2*len_offset                     ;(length2[i]-len_offset)                       ; this has to be checked!!!
            nn_e=0                                                      ;keep track of the loops/bits
            therm[ni,*]    = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,16,edac_on)
            if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_specific[i],' pointer ',ptr,nn_e,' Packet EUV temp'
            diode_a[ni,*]  = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,16,edac_on)
            if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_specific[i],' pointer ',ptr,nn_e,' Packet EUV DIODE A'
            diode_b[ni,*]  = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,16,edac_on)
            if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_specific[i],' pointer ',ptr,nn_e,' Packet EUV DIODE B'
            diode_c[ni,*]  = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,16,edac_on)
            if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_specific[i],' pointer ',ptr,nn_e,' Packet EUV DIODE C'
            diode_d[ni,*]  = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,16,edac_on)
            if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,counter,counter_specific[i],' pointer ',ptr,nn_e,' Packet EUV DIODE D'
            p7 = p7 + 1                                                     ; keeps track of how many EUV packets there are
          ENDFOR

          mvn_lpw_r_clock_check, 'EUV', pkt_EUV, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)
          ;loop over the packets
          t2=SYSTIME(1,/seconds)                                          ;to check on speed
          ;     print,'#### EUV ',ni,i,' time ', t2-t1,' seconds'
          EUV_SC = SC[pkt_EUV]
          for seqIndx = 1, nn_EUV-1 do $
            if EUV_SC[seqIndx] NE EUV_SC[seqIndx-1]+1 then print, 'EUV Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', EUV_SC[seqIndx-1], '  SC(seqIndx) =', EUV_SC[seqIndx]
          if (EUV_SC[nn_EUV-1]-EUV_SC[0]+1) NE p7 then print, 'EUV Sequence Count Failed. Should be', p7, ' Reporting ',(EUV_SC[nn_EUV-1]-EUV_SC[0]+1)
          total_euv_length = total(length[pkt_EUV]+7)
        endif  ELSE BEGIN                                                   ; if no packet was found
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
              i                     = pkt_ADR[ni]
              counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
              ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B04,B04,B03,B01)'
              SMP_AVG[i]            = newfile_byte[counter+1] /  2^4        ;rpt_rate DFB Tertiary header: format = '(B04,B04,B04,B03,B01)'
              ENB                   = newfile_byte[counter+1]   mod 2       ;enb      DFB Tertiary header: format = '(B04,B04,B04,B03,B01)'
              merge_large            = counter+indgen(1+127+1+127+13)*2     +2   ; every other value: even
              merge_small            = merge_large       +1              ; every other value: odd
              tmp                    = long(2L^8*newfile_byte[merge_large] + newfile_byte[merge_small])    ;<---- signed value -- correct if it is positive
              tmp_neg                = -1.* float((ulong(tmp mod 2L^15) xor (2L^15-1) ) +1)          ;<---- signed value -- correct if it is negative
              tmp_type               =  ulong(tmp)/2L^15                                             ; 0 if pos  but 1 if neg
              ADR_DYN_OFFSET1[p8]     = (1-1*tmp_type[0])      *tmp[0]      +tmp_type[0]      *tmp_neg[0]
              ADR_LP_BIAS1[p8,*]      = (1-1*tmp_type[1:127])  *tmp[1:127]  +tmp_type[1:127]  *tmp_neg[1:127]
              ADR_DYN_OFFSET2[p8]     = (1-1*tmp_type[128])    *tmp[128]    +tmp_type[128]    *tmp_neg[128]
              ADR_LP_BIAS2[p8,*]      = (1-1*tmp_type[129:255])*tmp[129:255]+tmp_type[129:255]*tmp_neg[129:255]
              ADR_W_BIAS1[p8]         = (1-1*tmp_type[256])    *tmp[256]    +tmp_type[256]    *tmp_neg[256]
              ADR_W_GUARD1[p8]        = (1-1*tmp_type[257])    *tmp[257]    +tmp_type[257]    *tmp_neg[257]
              ADR_W_STUB1[p8]         = (1-1*tmp_type[258])    *tmp[258]    +tmp_type[258]    *tmp_neg[258]
              ADR_W_V1[p8]            = (1-1*tmp_type[259])    *tmp[259]    +tmp_type[259]    *tmp_neg[259]
              ADR_LP_GUARD1[p8]       = (1-1*tmp_type[260])    *tmp[260]    +tmp_type[260]    *tmp_neg[260]
              ADR_LP_STUB1[p8]        = (1-1*tmp_type[261])    *tmp[261]    +tmp_type[261]    *tmp_neg[261]
              ADR_W_BIAS2[p8]         = (1-1*tmp_type[262])    *tmp[262]    +tmp_type[262]    *tmp_neg[262]
              ADR_W_GUARD2[p8]        = (1-1*tmp_type[263])    *tmp[263]    +tmp_type[263]    *tmp_neg[263]
              ADR_W_STUB2[p8]         = (1-1*tmp_type[264])    *tmp[264]    +tmp_type[264]    *tmp_neg[264]
              ADR_W_V2[p8]            = (1-1*tmp_type[265])    *tmp[265]    +tmp_type[265]    *tmp_neg[265]
              ADR_LP_GUARD2[p8]       = (1-1*tmp_type[266])    *tmp[266]    +tmp_type[266]    *tmp_neg[266]
              ADR_LP_STUB2[p8]        = (1-1*tmp_type[267])    *tmp[267]    +tmp_type[267]    *tmp_neg[267]
              p8 = p8 + 1
            ENDFOR                                                           ;loop over the packets
            t2=SYSTIME(1,/seconds)                                           ;to check on speed
            ;    print,'#### ADR ',ni,i,' time ', t2-t1,' seconds'
            ADR_SC = SC[pkt_ADR]
            for seqIndx = 1, nn_ADR-1 do $
              if ADR_SC[seqIndx] NE ADR_SC[seqIndx-1]+1 then print, 'ADR Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ADR_SC[seqIndx-1], '  SC(seqIndx) =', ADR_SC[seqIndx]
            if (ADR_SC[nn_ADR-1]-ADR_SC[0]+1) NE p8 then print, 'ADR Sequence Count Failed. Should be', p8, ' Reporting ',(ADR_SC[nn_ADR-1]-ADR_SC[0]+1)
            total_adr_length = total(length[pkt_ADR]+7)
          endif ELSE BEGIN                                                    ;created the variables with -1 as values since no data exist for this package
            ADR_DYN_OFFSET1   = -1 & ADR_LP_BIAS1      = -1 & ADR_DYN_OFFSET2   = -1 & ADR_LP_BIAS2      = -1 & $
              ADR_W_BIAS1       = -1 & ADR_W_GUARD1      = -1 &  ADR_W_STUB1      = -1 & ADR_W_V1          = -1 & $
              ADR_LP_GUARD1     = -1 & ADR_LP_STUB1      = -1 & ADR_W_BIAS2       = -1 & ADR_W_GUARD2      = -1 & $
              ADR_W_STUB2       = -1 & ADR_W_V2          = -1 & ADR_LP_GUARD2     = -1 & ADR_LP_STUB2      = -1 & ENDELSE


            ;HSK Packet
            total_hsk_length = 0
            if nn_HSK GT 0 and nn_act_HSK GT 0 then begin
              t1=SYSTIME(1,/seconds)                                          ;to check on speed
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
                i                     = pkt_HSK[ni]
                counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B04,B04,B03,B01)'
                SMP_AVG[i]            = newfile_byte[counter+1] /  2^4        ;rpt_rate DFB Tertiary header: format = '(B04,B04,B04,B03,B01)'
                ENB                   = newfile_byte[counter+1]   mod 2       ;enb      DFB Tertiary header: format = '(B04,B04,B04,B03,B01)'
                HSK_config[i]       =  2L^8*newfile_byte[counter+0] + newfile_byte[counter+1]
                merge_large            = counter+indgen(10)*2     +2           ; every other value: even
                merge_small            = merge_large       +1                  ; every other value: odd
                tmp                    = long(2L^8*newfile_byte[merge_large] + newfile_byte[merge_small])    ;<---- signed value -- correct if it is positive
                tmp_neg                = -1.* float((ulong(tmp mod 2L^15) xor (2L^15-1) ) +1)          ;<---- signed value -- correct if it is negative
                tmp_type               =  ulong(tmp)/2L^15                                             ; 0 if pos  but 1 if neg
                Preamp_Temp1[p9]    =  (1-1*tmp_type[0])      *tmp[0]      +tmp_type[0]      *tmp_neg[0]
                Preamp_Temp2[p9]    =  (1-1*tmp_type[1])      *tmp[1]      +tmp_type[1]      *tmp_neg[1]
                Beb_Temp[p9]        =  (1-1*tmp_type[2])      *tmp[2]      +tmp_type[2]      *tmp_neg[2]
                plus12va[p9]        =  (1-1*tmp_type[3])      *tmp[3]      +tmp_type[3]      *tmp_neg[3]
                minus12va[p9]       =  (1-1*tmp_type[4])      *tmp[4]      +tmp_type[4]      *tmp_neg[4]
                plus5va[p9]         =  (1-1*tmp_type[5])      *tmp[5]      +tmp_type[5]      *tmp_neg[5]
                minus5va[p9]        =  (1-1*tmp_type[6])      *tmp[6]      +tmp_type[6]      *tmp_neg[6]
                plus90va[p9]        =  (1-1*tmp_type[7])      *tmp[7]      +tmp_type[7]      *tmp_neg[7]
                minus90va[p9]       =  (1-1*tmp_type[8])      *tmp[8]      +tmp_type[8]      *tmp_neg[8]
                CMD_ACCEPT[p9]      =  2L^8*newfile_byte[counter+20] + newfile_byte[counter+21]
                CMD_REJECT[p9]      =  2L^8*newfile_byte[counter+22] + newfile_byte[counter+23]
                MEM_SEU_COUNTER[p9] =  2L^8*newfile_byte[counter+24] + newfile_byte[counter+25]
                INT_STAT[p9]        =  2L^8*newfile_byte[counter+26] + newfile_byte[counter+27]
                CHKSUM[p9]          =  2L^8*newfile_byte[counter+28] + newfile_byte[counter+29]
                EXT_STAT[p9]        =  2L^8*newfile_byte[counter+30] + newfile_byte[counter+31]
                DPLY1_CNT[p9]       =  2L^8*newfile_byte[counter+32] + newfile_byte[counter+33]
                DPLY2_CNT[p9]       =  2L^8*newfile_byte[counter+34] + newfile_byte[counter+35]
                p9 = p9 + 1
              ENDFOR                                                          ;loop over the packets

              mvn_lpw_r_clock_check, 'HSK', pkt_HSK, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

              t2=SYSTIME(1,/seconds)                                         ;to check on speed
              ;      print,'#### HSK ',ni,i,' time ', t2-t1,' seconds'
              HSK_SC = SC[pkt_HSK]
              for seqIndx = 1, nn_HSK-1 do $
                if HSK_SC[seqIndx] NE HSK_SC[seqIndx-1]+1 then print, 'HSK Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSK_SC[seqIndx-1], '  SC(seqIndx) =', HSK_SC[seqIndx]
              if (HSK_SC[nn_HSK-1]-HSK_SC[0]+1) NE p9 then print, 'HSK Sequence Count Failed. Should be', p9, ' Reporting ',(HSK_SC[nn_HSK-1]-HSK_SC[0]+1)
              total_hsk_length = total(length[pkt_HSK]+7)
            endif  ELSE BEGIN                                                   ; in case of no package
              Preamp_Temp1      = -1 & Preamp_Temp2      = -1 & Beb_Temp          = -1 & plus12va          = -1 & minus12va         = -1 & $
                plus5va           = -1 & minus5va          = -1 & plus90va          = -1 & minus90va         = -1 & CMD_ACCEPT        = -1 & CMD_REJECT        = -1 & $
                MEM_SEU_COUNTER   = -1 & INT_STAT          = -1 & CHKSUM            = -1 & EXT_STAT          = -1 & $
                DPLY1_CNT         = -1 & DPLY2_CNT         = -1 & ENDELSE

              ;SWP1_AVG Packet
              total_swp1_length = 0
              if nn_SWP1 GT 0 and nn_act_SWP1 GT 0 then begin
                t1=SYSTIME(1,/seconds)                                           ;to check on speed
                ;SWP1_AVG prealloctions
                SWP1_I1           = fltarr(nn_SWP1,128)
                SWP1_V2           = fltarr(nn_SWP1,128)
                I_ZERO1           = fltarr(nn_SWP1)
                SWP1_DYN_OFFSET1  = fltarr(nn_SWP1)
                FOR ni=0L,nn_SWP1-1 do begin
                  i                   = pkt_SWP1[ni]
                  counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                  ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                  MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                  SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                  tmp1                   = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]    ;<---- signed value
                  IF ulong(tmp1)/2L^15 EQ 0 then  I_ZERO1[ni]          = tmp1  ELSE $
                    I_ZERO1[ni]                   = -1.* float((ulong(tmp1 mod 2L^15) xor (2L^15-1) ) +1)
                  tmp2                   = 2L^8*newfile_byte[counter+4] + newfile_byte[counter+5]    ;<---- signed value
                  IF ulong(tmp2)/2L^15 EQ 0 then  SWP1_DYN_OFFSET1[ni] = tmp2  ELSE $
                    SWP1_DYN_OFFSET1[ni]          = -1.* float((ulong(tmp2 mod 2L^15) xor (2L^15-1) ) +1)
                  ptr=1L*(counter+6)                                       ; which 8 bit package to start with
                  ptr_end=ptr+length_byte[i]-14                             ; this has to be checked!!!
                  nn_e=0                                                    ; this is when the data is not exact a factor of 16
                  SWP1_I1[ni,*] = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,128,edac_on)
                  if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP1 I1'
                  SWP1_V2[ni,*] = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,128,edac_on)
                  if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP1 V2'
                  p10 = p10 + 1
                ENDFOR                                                         ;loop over the packets

                mvn_lpw_r_clock_check, 'SWP1', pkt_SWP1, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                t2=SYSTIME(1,/seconds)                                         ;to check on speed
                ;      print,'#### SWP1 ',ni,i,' time ', t2-t1 ,' seconds'
                SWP1_SC = SC[pkt_SWP1]
                for seqIndx = 1, nn_SWP1-1 do $
                  if SWP1_SC[seqIndx] NE SWP1_SC[seqIndx-1]+1 then print, 'SWP1 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', SWP1_SC[seqIndx-1], '  SC(seqIndx) =', SWP1_SC[seqIndx]
                if (SWP1_SC[nn_SWP1-1]-SWP1_SC[0]+1) NE p10 then print, 'SWP1 Sequence Count Failed. Should be', p10, ' Reporting ',(SWP1_SC[nn_SWP1-1]-SWP1_SC[0]+1)
                total_swp1_length = total(length[pkt_SWP1]+7)
              endif ELSE BEGIN                                                  ; if no packet was found
                SWP1_I1           = -1 & SWP1_V2           = -1 & I_ZERO1           = -1 & SWP1_DYN_OFFSET1  = -1 & ENDELSE


                ;SWP2_AVG Packet   <---- signed
                total_swp2_length = 0
                if nn_SWP2 GT 0 and nn_act_SWP2 GT 0 then begin
                  t1=SYSTIME(1,/seconds)                                         ;to check on speed
                  ;SWP2_AVG prealloctions
                  SWP2_I2           = fltarr(nn_SWP2,128)
                  SWP2_V1           = fltarr(nn_SWP2,128)
                  I_ZERO2           = fltarr(nn_SWP2)
                  SWP2_DYN_OFFSET2  = fltarr(nn_SWP2)
                  FOR ni=0L,nn_SWP2-1 do begin

                    i                   = pkt_SWP2[ni]
                    counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                    ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                    MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                    SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                    tmp                   = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]    ;<---- signed value
                    IF tmp/2L^15 EQ 0 then  I_ZERO2[ni]          = tmp  ELSE $
                      I_ZERO2[ni]          = -1.* float((ulong(tmp mod 2L^15) xor (2L^15-1) ) +1)
                    tmp                   = 2L^8*newfile_byte[counter+4] + newfile_byte[counter+5]     ;<---- signed value
                    IF tmp/2L^15 EQ 0 then  SWP2_DYN_OFFSET2[ni] = tmp  ELSE $
                      SWP2_DYN_OFFSET2[ni] = -1.* float((ulong(tmp mod 2L^15) xor (2L^15-1) ) +1)
                    ptr=1L*(counter+6)                                        ; which 8 bit package to start with
                    ptr_end=ptr+length_byte[i]-14                             ; this has to be checked!!!
                    nn_e=0                                                    ; this is when the data is not exact a factor of 16


                    SWP2_I2[ni,*] = mvn_lpw_r_block16_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,128,edac_on)
                    if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP1 I1'
                    SWP2_V1[ni,*] = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,128,edac_on)
                    if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat SWP1 V2'

                    p11 = p11 + 1



                  ENDFOR                                                         ;loop over the packets

                  mvn_lpw_r_clock_check, 'SWP2', pkt_SWP2, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                  t2=SYSTIME(1,/seconds)                                        ;to check on speed
                  ;      print,'#### SWP2 ',ni,i,' time ', t2-t1 ,' seconds'
                  SWP2_SC = SC[pkt_SWP2]
                  for seqIndx = 1, nn_SWP2-1 do $
                    if SWP2_SC[seqIndx] NE SWP2_SC[seqIndx-1]+1 then print, 'SWP2 Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', SWP2_SC[seqIndx-1], '  SC(seqIndx) =', SWP2_SC[seqIndx]
                  if (SWP2_SC[nn_SWP2-1]-SWP2_SC[0]+1) NE p11 then print, 'SWP2 Sequence Count Failed. Should be', p11, ' Reporting ',(SWP2_SC[nn_SWP2-1]-SWP2_SC[0]+1)
                  total_swp2_length = total(length[pkt_SWP2]+7)
                endif ELSE BEGIN                                                  ; in case no packages
                  SWP2_I2           = -1 &     SWP2_V1           = -1 &     I_ZERO2           = -1 &     SWP2_DYN_OFFSET2  = -1 & ENDELSE






                  ;ACT_AVG Packet   <---- signed
                  total_act_length = 0
                  if nn_ACT GT 0 and nn_act_ACT GT 0  then begin
                    t1=SYSTIME(1,/seconds)                                        ;to check on speed
                    ;ACT preallocations
                    ACT_V1            = fltarr(nn_ACT,64)
                    ACT_V2            = fltarr(nn_ACT,64)
                    ACT_E12_LF        = fltarr(nn_ACT,64)
                    FOR ni=0L,nn_ACT-1 do begin
                      i                   = pkt_ACT[ni]
                      counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                      ORB_MD[i]             = newfile_byte[counter+0] /  2^4         ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                      MC_LEN[i]             = newfile_byte[counter+0] mod 2^3        ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                      SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3        ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                      ptr             = 1L*(counter+2)                           ; which 8 bit package to start with
                      ptr_end=ptr+length_byte[i]-14                              ; this has to be checked!!!
                      nn_e            = 0                                        ; this is when the data is not eact a factor of 16
                      act_v1[ni,*]    = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,64,edac_on)
                      if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet ACT V1'
                      act_v2[ni,*]    = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,64,edac_on)
                      if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet ACT V2'
                      act_e12_lf[ni,*]= mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,64,edac_on)
                      if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet ACT E12'
                      p12                = p12 + 1
                    ENDFOR                                                         ;loop over the packets

                    mvn_lpw_r_clock_check, 'ACT', pkt_ACT, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                    t2=SYSTIME(1,/seconds)                                         ;to check on speed
                    ;     print,'#### ACT ',ni,i,' time ', t2-t1,' seconds'
                    ACT_SC = SC[pkt_ACT]
                    for seqIndx = 1, nn_ACT-1 do $
                      if ACT_SC[seqIndx] NE ACT_SC[seqIndx-1]+1 then print, 'ACT Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_SC[seqIndx-1], '  SC(seqIndx) =', ACT_SC[seqIndx]
                    if (ACT_SC[nn_ACT-1]-ACT_SC[0]+1) NE p12 then print, 'ACT Sequence Count Failed. Should be', p12, ' Reporting ',(ACT_SC[nn_ACT-1]-ACT_SC[0]+1)
                    total_act_length = total(length[pkt_ACT]+7)
                  endif ELSE BEGIN                                                   ; in case no packages
                    ACT_V1            = -1 &     ACT_V2            = -1 &     ACT_E12_LF        = -1 & ENDELSE




                    ;PAS_AVG Packet
                    total_pas_length = 0
                    if nn_PAS GT 0  and nn_act_PAS GT 0 then begin
                      t1=SYSTIME(1,/seconds)                                          ;to check on speed
                      ;PAS preallocations
                      PAS_V1            = fltarr(nn_PAS,64)
                      PAS_V2            = fltarr(nn_PAS,64)
                      PAS_E12_LF        = fltarr(nn_PAS,64)
                      FOR ni=0L,nn_PAS-1 do begin
                        i                   = pkt_PAS[ni]
                        counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                        ORB_MD[i]             = newfile_byte[counter+0] /  2^4         ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                        MC_LEN[i]             = newfile_byte[counter+0] mod 2^3        ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                        ptr=1L*(counter+2)                                         ; which 16 bit package to start with
                        ptr_end=ptr+length_byte[i]-14                              ; this has to be checked!!!
                        nn_e=0                                                     ; this is when the data is not eact a factor of 16
                        pas_v1[ni,*]     = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,64,edac_on)
                        if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p13,i,ni,' pointer ',ptr,nn_e,' Packet: PAS V1'
                        pas_v2[ni,*]     = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,64,edac_on)
                        if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p13,i,ni,' pointer ',ptr,nn_e,' Packet: PAS V2'
                        pas_e12_lf[ni,*] = mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,64,edac_on)
                        if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p13,i,ni,' pointer ',ptr,nn_e,' Packet PAS E12'
                        p13              = p13 + 1
                      ENDFOR                                                             ;loop over the packets

                      mvn_lpw_r_clock_check, 'PAS', pkt_PAS, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                      t2=SYSTIME(1,/seconds)                                             ;to check on speed
                      ;   print,'#### PAS ',ni,i,' time ', t2-t1 ,' seconds'
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
                        t1=SYSTIME(1,/seconds)                                          ;to check on speed
                        ACT_S_LF          = !values.f_nan                                ;variable length fltarr(nn_ACT_LF*116)
                        ACT_LF_PKTCNT     = fltarr(nn_ACT_LF)
                        ACT_LF_PKTARR     = fltarr(nn_ACT_LF)
                        FOR ni=0L,nn_ACT_LF-1 do begin
                          i                   = pkt_ACT_LF[ni]
                          counter               = 12L + counter_specific[i]             ;pointing to the start of the DFB teriary header
                          ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                          GB_e12_hf[i]          = newfile_byte[counter+0] / 2^3 mod 0   ;Gain     DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                          MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                          SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                          ACT_LF_PKTCNT[ni]          = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]
                          n_packets             = floor((((length[i]-1)/2)-4)/29)        ;this is how to merge them
                          ACT_LF_pktarr[ni]     = n_packets
                          merge_large           = indgen(n_packets*29)*2    +2           ; every other even
                          merge_small           = merge_large       +1                   ; every other odd
                          data_array            = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
                          if ni EQ 0 then ACT_S_LF =                         [data_array] else  $  ;variable length!!
                            ACT_S_LF =               [ACT_S_LF, data_array]
                          p14                  = p14 + 1
                        ENDFOR                                                             ;loop over the packets

                        mvn_lpw_r_clock_check, 'ACT_LF', pkt_ACT_LF, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                        t2=SYSTIME(1,/seconds)                                             ;to check on speed
                        ;   print,'#### ACT_LF ',ni,i,' time ', t2-t1 ,' seconds'
                        ACT_LF_SC = SC[pkt_ACT_LF]
                        for seqIndx = 1, nn_ACT_LF-1 do $
                          if ACT_LF_SC[seqIndx] NE ACT_LF_SC[seqIndx-1]+1 then print, 'ACT_S_LF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_LF_SC[seqIndx-1], '  SC(seqIndx) =', ACT_LF_SC[seqIndx]
                        if (ACT_LF_SC[nn_ACT_LF-1]-ACT_LF_SC[0]+1) NE p14 then print, 'ACT_S_LF Sequence Count Failed. Should be', p14, ' Reporting ',(ACT_LF_SC[nn_ACT_LF-1]-ACT_LF_SC[0]+1)
                        total_act_s_lf_length = total(length[pkt_ACT_LF]+7)
                      endif  ELSE BEGIN                                                   ; case on no pkt
                        ACT_S_LF          = -1 &   ACT_LF_PKTCNT     = -1 &    ACT_LF_PKTARR     = -1 & ENDELSE



                        ; ACT_S_MF Packet
                        total_act_s_mf_length = 0
                        if nn_ACT_MF GT 0 and nn_act_ACT_MF GT 0  then begin
                          t1=SYSTIME(1,/seconds)                                          ;to check on speed
                          ACT_S_MF          = !values.f_nan                                ;variable length fltarr(nn_ACT_LF*116)
                          ACT_MF_PKTCNT     = fltarr(nn_ACT_MF)
                          ACT_MF_PKTARR     = fltarr(nn_ACT_MF)
                          FOR ni=0L,nn_ACT_MF-1 do begin
                            i                   = pkt_ACT_MF[ni]
                            counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                            ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                            GB_e12_hf[i]          = newfile_byte[counter+0] / 2^3 mod 0   ;Gain     DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                            MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                            SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                            ACT_MF_PKTCNT[ni]     = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]
                            n_packets             = floor((((length[i]-1)/2)-4)/29)        ;this is how to merge them
                            ACT_MF_pktarr[ni]     = n_packets
                            merge_large           = indgen(n_packets*29)*2    +2           ; every other even
                            merge_small           = merge_large       +1                   ; every other odd
                            data_array            = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
                            if ni EQ 0 then ACT_S_MF =                         [data_array] else  $  ;variable length!!
                              ACT_S_MF =               [ACT_S_MF, data_array]
                            p15                = p15 + 1
                          ENDFOR   ;loop over the packets

                          mvn_lpw_r_clock_check, 'ACT_MF', pkt_ACT_MF, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                          t2=SYSTIME(1,/seconds)                                             ;to check on speed
                          ;   print,'#### ACT_MF ',ni,i,' time ', t2-t1 ,' seconds'
                          ACT_MF_SC = SC[pkt_ACT_MF]
                          for seqIndx = 1, nn_ACT_MF-1 do $
                            if ACT_MF_SC[seqIndx] NE ACT_MF_SC[seqIndx-1]+1 then print, 'ACT_S_MF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_MF_SC[seqIndx-1], '  SC(seqIndx) =', ACT_MF_SC[seqIndx]
                          if (ACT_MF_SC[nn_ACT_MF-1]-ACT_MF_SC[0]+1) NE p15 then print, 'ACT_S_MF Sequence Count Failed. Should be', p15, ' Reporting ',(ACT_MF_SC[nn_ACT_MF-1]-ACT_MF_SC[0]+1)
                          total_act_s_mf_length = total(length[pkt_ACT_MF]+7)
                        endif  ELSE BEGIN                                                 ; case on no pkt
                          ACT_S_MF          = -1 &   ACT_MF_PKTCNT     = -1 &    ACT_MF_PKTARR     = -1 & ENDELSE



                          ;ACT_S_HF Packets
                          total_act_s_hf_length = 0
                          if nn_ACT_HF GT 0 and nn_act_ACT_HF GT 0 then begin
                            t1=SYSTIME(1,/seconds)                                           ;to check on speed
                            ACT_S_HF          = !values.f_nan                                ;variable length fltarr(nn_ACT_LF*116)
                            ACT_HF_PKTCNT     = fltarr(nn_ACT_HF)
                            ACT_HF_PKTARR     = fltarr(nn_ACT_HF)
                            FOR ni=0L,nn_ACT_HF-1 do begin
                              i                   = pkt_ACT_HF[ni]
                              counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                              ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                              GB_e12_hf[i]          = newfile_byte[counter+0] / 2^3 mod 0   ;Gain     DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                              MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                              SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                              ACT_HF_PKTCNT[ni]     = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]
                              n_packets             = floor((((length[i]-1)/2)-4)/65)        ;floor((((length[i]-1)/2)-4)/29)        ;this is how to merge them
                              ACT_HF_pktarr[ni]     = n_packets
                              ;make the array
                              merge_large           = indgen(n_packets*65)*2    +2           ; every other even
                              merge_small           = merge_large       +1                   ; every other odd
                              data_array            = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
                              if ni EQ 0 then ACT_S_HF =                         [data_array] else  $  ;variable length!!
                                ACT_S_HF =               [ACT_S_HF, data_array]
                              p16 = p16 + 1
                            ENDFOR                                                             ;loop over the packets

                            mvn_lpw_r_clock_check, 'ACT_HF', pkt_ACT_HF, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                            t2=SYSTIME(1,/seconds)                                            ;to check on speed
                            ;   print,'#### ACT_HF ',ni,i,' time ', t2-t1 ,' seconds'
                            ACT_HF_SC = SC[pkt_ACT_HF]
                            for seqIndx = 1, nn_ACT_HF-1 do $
                              if ACT_HF_SC[seqIndx] NE ACT_HF_SC[seqIndx-1]+1 then print, 'ACT_S_HF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', ACT_HF_SC[seqIndx-1], '  SC(seqIndx) =', ACT_HF_SC[seqIndx]
                            if (ACT_HF_SC[nn_ACT_HF-1]-ACT_HF_SC[0]+1) NE p16 then print, 'ACT_S_HF Sequence Count Failed. Should be', p16, ' Reporting ',(ACT_HF_SC[nn_ACT_HF-1]-ACT_HF_SC[0]+1)
                            total_act_s_hf_length = total(length[pkt_ACT_HF]+7)
                          endif ELSE BEGIN                                                   ; case on no pkt
                            ACT_S_HF          = -1 &   ACT_HF_PKTCNT     = -1 &    ACT_HF_PKTARR     = -1 & ENDELSE


                            ; PAS_S_LF Packet
                            total_pas_s_lf_length = 0
                            if nn_PAS_LF GT 0 and nn_act_PAS_LF GT 0 then begin
                              t1=SYSTIME(1,/seconds)                                          ;to check on speed
                              PAS_S_LF          = !values.f_nan                                ;variable length fltarr(nn_ACT_LF*116)
                              PAS_LF_PKTCNT     = fltarr(nn_PAS_LF)
                              PAS_LF_PKTARR     = fltarr(nn_PAS_LF)
                              FOR ni=0L,nn_PAS_LF-1 do begin
                                i                   = pkt_PAS_LF[ni]
                                counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                                ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                GB_e12_hf[i]          = newfile_byte[counter+0] / 2^3 mod 0   ;Gain     DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                PAS_LF_PKTCNT[ni]     = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]
                                n_packets             = floor((((length[i]-1)/2)-4)/29)        ;this is how to merge them
                                PAS_LF_pktarr[ni]     = n_packets
                                ;make the array
                                merge_large           = indgen(n_packets*29)*2    +2           ; every other even
                                merge_small           = merge_large       +1                   ; every other odd
                                data_array            = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
                                if ni EQ 0 then PAS_S_LF =                         [data_array] else  $  ;variable length!!
                                  PAS_S_LF =               [PAS_S_LF, data_array]
                                p17                 = p17 + 1
                              ENDFOR                                                             ;loop over the packets

                              mvn_lpw_r_clock_check, 'PAS_LF', pkt_PAS_LF, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                              t2=SYSTIME(1,/seconds)                                             ;to check on speed
                              ;   print,'#### PAS_LF ',ni,i,' time ', t2-t1 ,' seconds'
                              PAS_LF_SC = SC[pkt_PAS_LF]
                              for seqIndx = 1, nn_PAS_LF-1 do begin
                                if PAS_LF_SC[seqIndx] NE PAS_LF_SC[seqIndx-1]+1 then print, 'PAS_S_LF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_LF_SC[seqIndx-1], '  SC(seqIndx) =', PAS_LF_SC[seqIndx]
                              endfor
                              if (PAS_LF_SC[nn_PAS_LF-1]-PAS_LF_SC[0]+1) NE p17 then print, 'PAS_S_LF Sequence Count Failed. Should be', p17, ' Reporting ',(PAS_LF_SC[nn_PAS_LF-1]-PAS_LF_SC[0]+1)
                              total_pas_s_lf_length = total(length[pkt_PAS_LF]+7)
                            endif ELSE BEGIN                                                      ; case on no pkt
                              PAS_S_LF          = -1 &   PAS_LF_PKTCNT     = -1 &    PAS_LF_PKTARR     = -1 & ENDELSE


                              ;PAS_S_MF Packet
                              total_pas_s_mf_length = 0
                              if nn_PAS_MF GT 0 and nn_act_PAS_MF GT 0 then begin
                                t1=SYSTIME(1,/seconds)                                            ;to check on speed
                                PAS_S_MF          = !values.f_nan                                  ;variable length fltarr(nn_ACT_LF*116)
                                PAS_MF_PKTCNT     = fltarr(nn_PAS_MF)
                                PAS_MF_PKTARR     = fltarr(nn_PAS_MF)
                                FOR ni=0L,nn_PAS_MF-1 do begin
                                  i                   = pkt_PAS_MF[ni]
                                  counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                                  ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                  GB_e12_hf[i]          = newfile_byte[counter+0] / 2^3 mod 0   ;Gain     DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                  MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                  SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                  PAS_MF_PKTCNT[ni]     = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]
                                  n_packets             = floor((((length[i]-1)/2)-4)/29)        ;this is how to merge them
                                  PAS_MF_pktarr[ni]     = n_packets
                                  merge_large           = indgen(n_packets*29)*2    +2           ; every other even
                                  merge_small           = merge_large       +1                   ; every other odd
                                  data_array            = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
                                  if ni EQ 0 then PAS_S_MF =                         [data_array] else  $  ;variable length!!
                                    PAS_S_MF =               [PAS_S_MF, data_array]
                                  p18                 = p18 + 1
                                ENDFOR                                                             ;loop over the packets

                                if n_elements(pkt_PAS_MF) GT 1 then $
                                  mvn_lpw_r_clock_check, 'PAS_MF', pkt_PAS_MF, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                                t2=SYSTIME(1,/seconds)                                          ;to check on speed
                                ;      print,'#### PAS_MF ',ni,i,' time ', t2-t1 ,' seconds'
                                PAS_MF_SC = SC[pkt_PAS_MF]
                                for seqIndx = 1, nn_PAS_MF-1 do $
                                  if PAS_MF_SC[seqIndx] NE PAS_MF_SC[seqIndx-1]+1 then print, 'PAS_S_MF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_MF_SC[seqIndx-1], '  SC(seqIndx) =', PAS_MF_SC[seqIndx]
                                if (PAS_MF_SC[nn_PAS_MF-1]-PAS_MF_SC[0]+1) NE p18 then print, 'PAS_S_MF Sequence Count Failed. Should be', p18, ' Reporting ',(PAS_MF_SC[nn_PAS_MF-1]-PAS_MF_SC[0]+1)
                                total_pas_s_mf_length = total(length[pkt_PAS_MF]+7)
                              endif ELSE BEGIN                                                    ; case on no pkt
                                PAS_S_MF          = -1 &   PAS_MF_PKTCNT     = -1 &    PAS_MF_PKTARR     = -1 & ENDELSE


                                ;PAS_S_HF Packet
                                total_pas_s_hf_length = 0
                                if nn_PAS_HF GT 0 and nn_act_PAS_HF GT 0  then begin
                                  t1=SYSTIME(1,/seconds)                                          ;to check on speed
                                  PAS_S_HF          = !values.f_nan                                ;variable length fltarr(nn_ACT_LF*116)
                                  PAS_HF_PKTCNT     = fltarr(nn_PAS_HF)
                                  PAS_HF_PKTARR     = fltarr(nn_PAS_HF)
                                  FOR ni=0L,nn_PAS_HF-1 do begin
                                    i                   = pkt_PAS_HF[ni]
                                    counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                                    ORB_MD[i]             = newfile_byte[counter+0] /  2^4        ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                    GB_e12_hf[i]          = newfile_byte[counter+0] / 2^3 mod 0   ;Gain     DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                    MC_LEN[i]             = newfile_byte[counter+0] mod 2^3       ;mclen    DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                    SMP_AVG[i]            = newfile_byte[counter+1] mod 2^3       ;rpt_rate DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                    PAS_HF_PKTCNT[ni]     = 2L^8*newfile_byte[counter+2] + newfile_byte[counter+3]
                                    n_packets             = floor((((length[i]-1)/2)-4)/65)        ;this is how to merge them
                                    test= counter_specific[i]
                                    PAS_HF_pktarr[ni]     = n_packets
                                    merge_large           = indgen(n_packets*65)*2    +2           ; every other even
                                    merge_small           = merge_large       +1                   ; every other odd
                                    data_array            = 2L^8*newfile_byte[counter+merge_large] + newfile_byte[counter+merge_small]
                                    if ni EQ 0 then PAS_S_HF =                         [data_array] else  $  ;variable length!!
                                      PAS_S_HF =               [PAS_S_HF, data_array]
                                    p19                 = p19 + 1
                                  ENDFOR                                                            ;loop over the packets

                                  mvn_lpw_r_clock_check, 'PAS_HF', pkt_PAS_HF, SC, sc_clk1, sc_clk2  ;look for and correct and clock jitter (~0.5s)

                                  t2=SYSTIME(1,/seconds)                                          ;to check on speed
                                  ;      print,'#### PAS_HF ',ni,i,' time ', t2-t1 ,' seconds'
                                  PAS_HF_SC = SC[pkt_PAS_HF]
                                  for seqIndx = 1, nn_PAS_HF-1 do $
                                    if PAS_HF_SC[seqIndx] NE PAS_HF_SC[seqIndx-1]+1 then print, 'PAS_S_HF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', PAS_HF_SC[seqIndx-1], '  SC(seqIndx) =', PAS_HF_SC[seqIndx]
                                  if (PAS_HF_SC[nn_PAS_HF-1]-PAS_HF_SC[0]+1) NE p19 then print, 'PAS_S_HF Sequence Count Failed. Should be', p19, ' Reporting ',(PAS_HF_SC[nn_PAS_HF-1]-PAS_HF_SC[0]+1)
                                  total_pas_s_hf_length = total(length[pkt_PAS_HF]+7)
                                endif  ELSE BEGIN                                                   ; case on no pkt
                                  PAS_S_HF          = -1 &   PAS_HF_PKTCNT     = -1 &    PAS_HF_PKTARR     = -1 & ENDELSE




                                  ;HSBM LF packets
                                  total_hsbm_lf_length = 0
                                  if nn_HSBM_LF GT 0 and nn_act_HSBM_LF GT 0 then BEGIN
                                    t1=SYSTIME(1,/seconds)                                            ;to check on speed
                                    FOR ni=0L,nn_HSBM_LF-1 do begin
                                      i                   = pkt_HSBM_LF[ni]
                                      counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                                      ORB_MD[i]             = newfile_byte[counter+0] /  2^4         ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                      ptr                   = 1L*(counter+2)
                                      ptr_end               = ptr+(floor(length[i]+1)/2+2+offset2-offset1+1) *2  ; this has to be checked!!!; the factor of 2 is due to byte vs word
                                      nn_e                  = 0                                      ; this is when the data is not eact a factor of 16
                                      decomp                =     mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,32,edac_on)
                                      if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packet HSBM_LF'
                                      while ((ptr_end-ptr)*16-nn_e) ge (16+7+(31*2)) do begin
                                        decomp           = [decomp,mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,32,edac_on)] ;the rest of the times
                                      endwhile
                                      p                     = ptr_new(decomp)
                                      if ni EQ 0 then BEGIN
                                        hsbm_lf_i             =  i                                             ; keeps track of where in the file the hsbm_i packets are
                                        hsbm_lf_comp_t        = sc_clk1[i]+sc_clk2[i]/65536d                   ;keeps track of the first time stamp since it might be multiple packages
                                        hsbm_lf_comp_p        = p                                              ;keeps track of the pointer
                                      ENDIF ELSE BEGIN
                                        hsbm_lf_i             = [hsbm_lf_i, i]                                ; keeps track of where in the file the hsbm_i packets are
                                        hsbm_lf_comp_t        = [hsbm_lf_comp_t,sc_clk1[i]+sc_clk2[i]/65536d]  ;keeps track of the first time stamp since it might be multiple packages
                                        hsbm_lf_comp_p        = [hsbm_lf_comp_p,p]                             ;keeps track of the pointer
                                      ENDELSE
                                    ENDFOR                                                             ;loop over  nn_HSBM_LF

                                    t2=SYSTIME(1,/seconds)                                            ;to check on speed
                                    ;      print,'#### HSBM LF ',ni,i,n_elements(hsbm_lf_i),p20,' time ', t2-t1,' seconds'
                                    HSBM_LF_SC = SC[HSBM_LF_i]
                                    nn=n_elements(HSBM_LF_i)
                                    for seqIndx = 1, nn-1 do $
                                      if HSBM_LF_SC[seqIndx] NE HSBM_LF_SC[seqIndx-1]+1 then print, 'HSBM_LF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSBM_LF_SC[seqIndx-1], '  SC(seqIndx) =', HSBM_LF_SC[seqIndx]
                                    if (HSBM_LF_SC[nn-1]-HSBM_LF_SC[0]+1) NE nn then print, 'HSBM_LF Sequence Count Failed. Should be', nn, ' Reporting ',(HSBM_LF_SC[nn-1]-HSBM_LF_SC[0]+1)
                                    total_hsbm_lf_length = total(length[HSBM_LF_i]+7)
                                  endif ;HSBM_LF




                                  ;HSBM MF packets
                                  total_hsbm_mf_length = 0
                                  if nn_HSBM_MF GT 0 and nn_act_HSBM_MF GT 0  then BEGIN
                                    t1=SYSTIME(1,/seconds)                                            ;to check on speed
                                    FOR ni=0L,nn_HSBM_MF-1 do begin
                                      i                   = pkt_HSBM_MF[ni]
                                      counter               = 12L + counter_specific[i]                ;pointing to the start of the DFB teriary header
                                      ORB_MD[i]             = newfile_byte[counter+0] /  2^4           ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                      ptr     = 1L*(counter+2)
                                      ptr_end = ptr+(floor(length[i]+1)/2+2+offset2-offset1+1) * 2 ; this has to be checked!!!  factor 2 for byte vs word
                                      nn_e    = 0                                              ; this is when the data is not eact a factor of 16
                                      decomp  =                                    mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,32,edac_on)
                                      if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat HSBM_MF'
                                      while ((ptr_end-ptr)*16-nn_e) ge (16+7+(31*2)) do   decomp = [decomp,mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,32,edac_on)] ;the rest of the times
                                      p             = ptr_new(decomp)                          ; if compressed
                                      if ni EQ 0 then BEGIN
                                        hsbm_mf_i             =  i                                             ; keeps track of where in the file the hsbm_i packets are
                                        hsbm_mf_comp_t        = sc_clk1[i]+sc_clk2[i]/65536d                   ;keeps track of the first time stamp since it might be multiple packages
                                        hsbm_mf_comp_p        = p                                              ;keeps track of the pointer
                                      ENDIF ELSE BEGIN
                                        hsbm_mf_i             = [hsbm_mf_i, i]                                ; keeps track of where in the file the hsbm_i packets are
                                        hsbm_mf_comp_t        = [hsbm_mf_comp_t,sc_clk1[i]+sc_clk2[i]/65536d]  ;keeps track of the first time stamp since it might be multiple packages
                                        hsbm_mf_comp_p        = [hsbm_mf_comp_p,p]                             ;keeps track of the pointer
                                      ENDELSE
                                    ENDFOR                                                             ;loop over  nn_HSBM_MF

                                    t2=SYSTIME(1,/seconds)                                            ;to check on speed
                                    ;      print,'#### HSBM MF ',ni,i,n_elements(hsbm_mf_i),' time ', t2-t1 ,' seconds'
                                    HSBM_MF_SC = SC[HSBM_MF_i]
                                    nn=n_elements(HSBM_MF_i)
                                    for seqIndx = 1, nn-1 do $
                                      if HSBM_MF_SC[seqIndx] NE HSBM_MF_SC[seqIndx-1]+1 then print, 'HSBM_MF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSBM_MF_SC[seqIndx-1], '  SC(seqIndx) =', HSBM_MF_SC[seqIndx]
                                    if (HSBM_MF_SC[nn-1]-HSBM_MF_SC[0]+1) NE nn then print, 'HSBM_MF Sequence Count Failed. Should be', nn, ' Reporting ',(HSBM_MF_SC[nn-1]-HSBM_MF_SC[0]+1)
                                    total_hsbm_mf_length = total(length[HSBM_MF_i]+7)
                                  endif ;HSBM_MF




                                  ;HSBM HF packets
                                  total_hsbm_hf_length = 0
                                  if nn_HSBM_HF GT 0 and nn_act_HSBM_HF GT 0  then BEGIN
                                    t1=SYSTIME(1,/seconds)                                            ;to check on speed
                                    FOR ni=0L,nn_HSBM_HF-1 do begin
                                      i                   = pkt_HSBM_HF[ni]
                                      counter               = 12L + counter_specific[i]               ;pointing to the start of the DFB teriary header
                                      ORB_MD[i]             = newfile_byte[counter+0] /  2^4          ;orb      DFB Tertiary header: format = '(B04,B01,B03,B05,B03)'
                                      ptr                   = 1L*(counter+2)
                                      ptr_end               = ptr+(floor(length[i]+1)/2+2+offset2-offset1+1)*2 ; this has to be checked!!!  factor 2 for byte vs word
                                      nn_e                  = 0                                       ; this is when the data is not eact a factor of 16
                                      decomp                 =                                    mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,32,edac_on)
                                      if edac_on EQ 1 then print,'The compression check EDAC failed in packet no ',p7,i,ni,' pointer ',ptr,nn_e,' Packat HSBM_HF'
                                      while ((ptr_end-ptr)*16-nn_e) ge (16+7+(31*2)) do  decomp = [decomp,mvn_lpw_r_block32_byte(newfile_byte,ptr,nn_e,mask8,bin_c,index_arr,32,edac_on)] ;the rest of the times
                                      p             = ptr_new(decomp)
                                      if ni EQ 0 then BEGIN
                                        hsbm_hf_i             =  i                                             ; keeps track of where in the file the hsbm_i packets are
                                        hsbm_hf_comp_t        = sc_clk1[i]+sc_clk2[i]/65536d                   ;keeps track of the first time stamp since it might be multiple packages
                                        hsbm_hf_comp_p        = p                                              ;keeps track of the pointer
                                      ENDIF ELSE BEGIN
                                        hsbm_hf_i             = [hsbm_hf_i, i]                                ; keeps track of where in the file the hsbm_i packets are
                                        hsbm_hf_comp_t        = [hsbm_hf_comp_t,sc_clk1[i]+sc_clk2[i]/65536d]  ;keeps track of the first time stamp since it might be multiple packages
                                        hsbm_hf_comp_p        = [hsbm_hf_comp_p,p]                             ;keeps track of the pointer
                                      ENDELSE
                                    ENDFOR                                                             ;loop over  nn_HSBM_HF

                                    t2=SYSTIME(1,/seconds)                                            ;to check on speed
                                    ;      print,'#### HSBM HF ',ni,i,n_elements(hsbm_hf_i),' time ', t2-t1 ,' seconds'
                                    HSBM_HF_SC = SC[HSBM_HF_i]
                                    nn=n_elements(HSBM_HF_i)
                                    for seqIndx = 1, nn-1 do $
                                      if HSBM_HF_SC[seqIndx] NE HSBM_HF_SC[seqIndx-1]+1 then print, 'HSBM_HF Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HSBM_HF_SC[seqIndx-1], '  SC(seqIndx) =', HSBM_HF_SC[seqIndx]
                                    if (HSBM_HF_SC[nn-1]-HSBM_HF_SC[0]+1) NE nn then print, 'HSBM_HF Sequence Count Failed. Should be', nn, ' Reporting ',(HSBM_HF_SC[nn-1]-HSBM_HF_SC[0]+1)
                                    total_hsbm_hf_length = total(length[HSBM_HF_i]+7)
                                  endif ;HSBM_HF


                                  ; htime packets    <---- signed
                                  total_htime_length = 0
                                  if nn_htime GT 0 and nn_act_htime GT 0 then begin
                                    t1=SYSTIME(1,/seconds)                                          ;to check on speed
                                    FOR ni=0L,nn_htime-1 do begin
                                      i                   = pkt_htime[ni]
                                      counter               = 12L + counter_specific[i]              ;pointing to the start of the DFB teriary header
                                      SMP_AVG[i]            = newfile_byte[counter+0] /  2^4         ;use this to get it out  Rate = 2 ^rpt_rate second  ICD table 7.8
                                      nn                    = (((long(length[i])-1)/2)-7)/2+1        ; this is based on words
                                      merge_large            = counter+indgen(nn*2)*2     +2         ; every other value: even
                                      merge_small            = merge_large       +1                  ; every other value: odd
                                      tmp                    = long(2L^8*newfile_byte[merge_large] + newfile_byte[merge_small])    ;<---- signed value -- correct if it is positive
                                      tmp_neg                = -1.* float((ulong(tmp mod 2L^15) xor (2L^15-1) ) +1)          ;<---- signed value -- correct if it is negative
                                      tmp_type               =  ulong(tmp)/2L^15                                             ; 0 if pos  but 1 if neg
                                      If nn GT 0 then begin
                                        cap_time2           = fltarr(nn)
                                        htime_type2         = intarr(nn)
                                        xfer_time2          = fltarr(nn)
                                        for iii = 0,nn-1 do begin
                                          cap_time2[iii]     =          (1-1*tmp_type[2*iii])      *tmp[2*iii]      +tmp_type[2*iii]      *tmp_neg[2*iii]
                                          htime_type2[iii]   = tmp[2*iii+1]/2L^14
                                          xfer_time2[iii]    = tmp[2*iii+1] mod 2L^14
                                        endfor
                                        if ni EQ 0 then cap_time   = cap_time2    ELSE cap_time              = [cap_time   ,cap_time2]
                                        if ni EQ 0 then htime_type = htime_type2  ELSE htime_type            = [htime_type ,htime_type2]
                                        if ni EQ 0 then xfer_time  = xfer_time2   ELSE xfer_time             = [xfer_time  ,xfer_time2]
                                        p23 = p23 + 1
                                      ENDIF                                                                ;nn GT 0
                                    ENDFOR                                                          ;loop over packets
                                    t2=SYSTIME(1,/seconds)                                          ;to check on speed
                                    ;    print,'#### htime ',ni,i,' time ', t2-t1 ,' seconds'
                                    HTIME_SC = SC[pkt_htime]
                                    for seqIndx = 1, nn_htime-1 do $
                                      if HTIME_SC[seqIndx] NE HTIME_SC[seqIndx-1]+1 then print, 'HTIME Sequence Count Skipped. seqIndex =', seqIndx, '  SC(seqIndx-1) =', HTIME_SC[seqIndx-1], '  SC(seqIndx) =', HTIME_SC[seqIndx]
                                    if (HTIME_SC[nn_htime-1]-HTIME_SC[0]+1) NE p23 then print, 'HTIME Sequence Count Failed. Should be', p23, ' Reporting ',(HTIME_SC[nn_htime-1]-HTIME_SC[0]+1)
                                    total_htime_length = total(length[pkt_htime]+7)
                                  endif ELSE BEGIN                                                   ; case on no pkt
                                    xfer_time     = !values.f_nan &   cap_time      = !values.f_nan &    htime_type    = !values.f_nan & ENDELSE  ;htime


                                    ;**** Waveform packets w1 to w5  - is not prodused on spacecraft  - these are not fixes with the move from WORD to BYTE.***
                                    ;
                                    if (nn_w1  NE 0) OR (nn_w2  NE 0) OR (nn_w3  NE 0) OR (nn_w4  NE 0) OR (nn_w5  NE 0)  then BEGIN
                                      print,' These pkt can only be produced on ground ',nn_w1,nn_w2,nn_w3,nn_w4,nn_w5
                                      print,'This reader cannot read wave packets, use the original mvn_lpw_r_header without SC headers'
                                      stanna
                                    endif

                                    ;-------------------------------------- The different packets read in DONE ---------------------------------
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
                                    t2=SYSTIME(1,/seconds)                       ;to check on speed
                                    ; print,'#### HSBM grouping ',' time ', t2-t1 ,' seconds'
                                    ;--------------------------------------  Store it in the output structure  --------------------------------

                                    output=create_struct(   $        ;To export the data in workable form
                                      'filename'        ,  filename_short        ,$
                                      'counter_all'     ,  counter_specific ,$ ;   counter_all1    ,$  ;the start of each packet
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
                                      'cap_time'        ,  cap_time        ,$
                                      'SC_CLK1_gst'     ,  SC_CLK1_gst     ,$     ; time when the gst stamped the packet
                                      'SC_CLK2_gst'     ,  SC_CLK2_gst     ,$     ; time when the gst stamped the packet
                                      'APID2'           ,  APID2           ,$     ; should be the same as apid
                                      'length2'         ,  length2         ,$     ; should be the same as packet length
                                      'SC_CLK3_gst'     ,  SC_CLK3_gst     ,$     ; should be the same as sc_clk1
                                      'SC_CLK4_gst'     ,  SC_CLK4_gst      )     ; should be the same as sc_clk2



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


                                    t_end=SYSTIME(1,/seconds)                                       ;to check on speed
                                    print,' TOTAL time to read ',t_end-t_start, ' seconds'

                                  ENDELSE                                                         ; there was LPW packets in the file
                                ENDIf  ELSE BEGIN                                               ; there is packets found in the file
                                  output = -1
                                  print,'No LPW packets was found in the data file ',filename
                                ENDELSE                                                         ; there is packets found in the file

                              end
