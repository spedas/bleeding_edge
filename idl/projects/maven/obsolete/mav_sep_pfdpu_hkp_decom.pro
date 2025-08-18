obsolete
;
;; The purpose of this function is to decommutate housekeeping packets
;Data Should already be in words, not bytes..
function mav_sep_pfdpu_hkp_decom, pkt
data = uint(pkt.data,0,n_elements(pkt.data)/2)
byteorder,data,/swap_if_little_endian

  ; Temperature is given as a 7th order polynomial with the following coefficients
daptemp_conversion_factors = $
  reverse ([0, 0, -5.755E-20,  5.0127E-15,  -1.6784E-10, 2.6907E-06,-0.023287, 93.314]) 
  ; DFE temperature sensors
dfe1_Conversion_factors = $
  reverse ([0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01])
dfe2_Conversion_factors = $
  reverse ([0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01])
  
dprint,dlevel=3,'APID ', pkt.apid,pkt.seq_cntr,pkt.size,format='(a,z02,i,i)'
 hkp =  {time:pkt.time, $
SEPBiasV : fix(data [0]) *0.002943, $
SEPBiasMon : fix (data [1])*0.000076, $
SEPDAPTemp : total (daptemp_conversion_factors*(1.0*fix(data [2])) ^ findgen (8)), $
SEPP5DV : fix (data [3])*0.000191, $
SEPP5AV : fix (data [4])*0.000191, $
SEPN5AV : fix(data [5])*0.000191, $
SEPDFE1T: total (dfe1_conversion_factors*(1.0*fix(data [6])) ^ findgen (8)), $
SEPDFE2T: total (dfe2_conversion_factors*(1.0*fix(data [7])) ^ findgen (8)), $
SEPMAPID : byte(ishft (data [8],-8)), $                    ; map ID
SEPFPGAREV : byte (ishft(ishft (data [8], 8),-8)), $        ; FPGA revision number
SEPCMDPASS : byte (ishft (data [9],-8)), $                   ; valid command count
SEPCMDFAIL : byte (ishft (ishft (data [9], 8), -8)), $      ; invalid command count
SEPBOARD : byte(ishft (data [10], -15)), $                 ; spare
SEPTPENB : byte(ishft (ishft (data [10], 1), -15)), $      ; test pulse enable
SEPTPFTO : string (ishft (ishft (data [10], 2),-10), $; test pulse FTO pattern
                  format = '(b)'), $
SEPBLRMODE : byte(ishft(ishft (data [10], 8), -14)), $     ; baseline restoration mode
SEPDET6ENB : byte(ishft (ishft (data [10], 10), -15)), $   ; detector 6 enable  
SEPDET5ENB : byte(ishft (ishft (data [10], 11), -15)), $   ; detector 5 enable   
SEPDET4ENB : byte(ishft (ishft (data [10], 12), -15)), $   ; detector 4 enable  
SEPDET3ENB : byte(ishft (ishft (data [10], 13), -15)), $   ; detector 3 enable  
SEPDET2ENB : byte(ishft (ishft (data [10], 14), -15)), $   ; detector 2 enable  
SEPDET1ENB : byte(ishft (ishft (data [10], 15), -15)), $   ; detector 1 enable  
SEPDOOR : byte(ishft (data [11], -12)), $                    ; door monitor  
SEPNOISENB: byte (ishft (ishft (data [11], 4), -15)), $      ; noise measurements enable
SEPNOISERES: byte (ishft (ishft (data [11], 5), -13)), $      ; noise resolution
SEPNOISEPER: byte (ishft (ishft (data [11], 8), -8)), $       ; noise period
SEPMEMFILL: data [12], $                                      ; memory fill address
SEPLUTCHKSM: byte(ishft (data [13], -8)), $                   ; Look Up Table (LUT) checksum
SEPPPSCNT: byte(ishft (ishft (data [13], 8), -8)), $          ; PPS counter, rotate 0-255
SEPEVTCNT: data [14], $                                       ; Events Counter: number of events processed
SEPRCNT1O: data [15], $                                       ;Rate Count from telescope 1, O detector
SEPRCNT1T: data [16], $                                       ;Rate Count from telescope 1, T detector
SEPRCNT1F: data [17], $                                       ;Rate Count from telescope 1, F detector
SEPRCNT2O: data [18], $                                       ;Rate Count from telescope 2, O detector
SEPRCNT2T: data [19], $                                       ;Rate Count from telescope 2, T detector
SEPRCNT2F: data [20], $                                       ;Rate Count from telescope 2, F detector
SEPBTOMF: byte (ishft (data [21], -12)), $                    ;Bus timeout count due to memory fill process
SEPBTOTP: byte (ishft (ishft (data [21], 4), -12)), $         ;Bus timeout count due to telemetry process
SEPBTOEP: byte (ishft (ishft (data [21], 8), -12)), $         ;Bus timeout count due to event process
SEPBTONM: byte (ishft (ishft (data [21], 12), -12)), $        ;Bus timeout count due to noise measurement
SEPDTOCNT: byte (ishft (data [22], -8)), $                    ; detector timeout count
SEPNPCNT: byte(ishft (ishft (data [22], 8), -8)), $           ; no-Peaks count
SEPRESRVD: data [23], $                                       ; reserved
SEP1VER: byte (ishft (data [24], -8)), $                      ; SEP table version
SEP1Opts: byte(ishft (ishft (data [24], 8), -8)), $           ; "Options [ xxxxNNCC ]: CC=Compression Type for SCI data; NN=Compression Type for NOI data."
SEP1RTAVG: byte (ishft (data [25], -8)), $                    ;SEP RT Spectra Avg Interval 2^N, N=[0..5]
SEP1ARCAVG: byte(ishft (ishft (data [25], 8), -8)), $         ;SEP Arc Spectra Avg Interval 2^N, N=[0..5]  
SEP1LUTADR:byte (ishft (data [26], -8)), $                    ;Lookup Table Directory Index 
SEP1LUTCSM:byte(ishft (ishft (data [26], 8), -8)), $          ;Lookup Table Checksum Expected
SEP1CSMLMT:byte (ishft (data [27], -8)), $                    ;CSM Failure Limit
SEP1CSMCTR: byte(ishft (ishft (data [27], 8), -8)), $         ;CSM Failure Count
SEP1RSTLMT:byte (ishft (data [28], -8)), $                    ;Reset if No Messages in Seconds
SEP1RSTSEC:byte(ishft (ishft (data [28], 8), -8)), $          ;Reset Seconds Since Last Message
SEP1BINMAX:byte (ishft (data [29], -8)), $                    ; Spectra Bins Maximum
SEP1ATTPER: byte(ishft (ishft (data [29], 8), -8)), $         ; Attenuator Movement Period =2^N
SEP1ATTIN: data [30], $                                       ;Attenuator In Threshold
SEP1ATTOUT: data [31], $                                      ;Attenuator Out Threshold
SEP1T1ODT: data [32], $                                       ;Telescope 1, O Detector Threshold
SEP1T1TDT: data [33], $                                       ;Telescope 1, T Detector Threshold
SEP1T1FDT: data [34], $                                       ;Telescope 1, F Detector Threshold
SEP1T1AUX: data [35], $                                       ;telescope 1 auxiliary
SEP1T2ODT: data [36], $                                       ;Telescope 2, O Detector Threshold
SEP1T2TDT: data [37], $                                       ;Telescope 2, T Detector Threshold
SEP1T2FDT: data [38], $                                       ;Telescope 2, F Detector Thresholdv
SEP1T2AUX: data [39], $                                       ;Telescope 2 auxiliary
SEP1TPH0: data [40], $                                       ;pulse height O
SEP1TPHT: data [41], $                                       ;pulse height T
SEP1TPHF: data [42], $                                       ;pulse height F
SEP1BIAS: data [43] $                                       ;Bias voltage
}                                       ;
Return,hkp
end
