;+
;PROCEDURE:   mvn_swe_init
;PURPOSE:
;  Initializes SWEA common block (mvn_swe_com).
;
;
;USAGE:
;  mvn_swe_init
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-03-02 11:48:36 -0800 (Tue, 02 Mar 2021) $
; $LastChangedRevision: 29728 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_init.pro $
;
;CREATED BY:    David L. Mitchell  02-01-15
;FILE: mvn_swe_init.pro
;-
pro mvn_swe_init

  @mvn_swe_com

; Decompression: 19-to-8
;   16-bit instrument messages are summed into 19-bit counters 
;   in the PFDPU.  These 19-bit values are rounded down onboard
;   to fit into the 8-bit compression scheme, so each compressed
;   value corresponds to a range of possible counts.  I take the
;   middle of each range for decompression, so there are half 
;   counts.  This is less than a ~3% (systematic) correction.
;
;   Compression introduces digitization noise, which dominates
;   the variance at high count rates.  I treat digitization noise
;   as additive white noise.

  decom = fltarr(16,16)
  decom[0,*] = findgen(16)
  decom[1,*] = 16. + findgen(16)
  for i=2,15 do decom[i,*] = 2.*decom[(i-1),*]
    
  d_floor = reform(transpose(decom),256)        ; FSW rounds down
  d_ceil = shift(d_floor,-1) - 1.
  d_ceil[255] = 2.^19. - 1.                     ; 19-bit counter max
  d_mid = (d_ceil + d_floor)/2.                 ; mid-point
  n_pts = d_ceil - d_floor + 1.                 ; number of values in range
  d_var = d_mid + (n_pts^2. - 1.)/12.           ; variance w/ dig. noise
    
  decom = d_mid  ; decompressed counts
  devar = d_var  ; variance w/ digitization noise

; Housekeeping names

  swe_hsk_names = ['LVPST'  , $   ;  0: LVPS Temperature
                   'MCPHV'  , $   ;  1: MCP HV Voltage
                   'NRV'    , $   ;  2: NRHV +5V Supply Voltage
                   'ANALV'  , $   ;  3: Analyzer Voltage
                   'DEF1V'  , $   ;  4: Deflector 1 Voltage
                   'DEF2V'  , $   ;  5: Deflector 2 Voltage
                   ''       , $   ;  6: ground/spare
                   ''       , $   ;  7: ground/spare
                   'V0V'    , $   ;  8: V0 Voltage
                   'ANALT'  , $   ;  9: Analyzer Temperature
                   'P12V'   , $   ; 10: +12V Voltage
                   'N12V'   , $   ; 11: -12V Voltage
                   'MCP28V' , $   ; 12: +28V Voltage (after MCPHV enable plug)
                   'NR28V'  , $   ; 13: +28V Voltage (after NRHV enable plug)
                   ''       , $   ; 14: ground/spare
                   ''       , $   ; 15: ground/spare
                   'DIGT'   , $   ; 16: Digital Temperature
                   'P2P5DV' , $   ; 17: +2.5V Digital Voltage
                   'P5DV'   , $   ; 18: +5V Digital Voltage
                   'P3P3DV' , $   ; 19: +3.3V Digital Voltage
                   'P5AV'   , $   ; 20: +5V Analog Voltage
                   'N5AV'   , $   ; 21: -5V Analog Voltage
                   'P28V'   , $   ; 22: +28V Voltage
                   ''          ]  ; 23: ground/spare

; Housekeeping conversions

  swe_v = [ 1.000     , $   ;  0: LVPS Temperature
           -0.153355  , $   ;  1: MCP HV Voltage
           -0.000203  , $   ;  2: NRHV +5V Supply Voltage
           -0.030795  , $   ;  3: Analyzer Voltage
           -0.076870  , $   ;  4: Deflector 1 Voltage
           -0.075839  , $   ;  5: Deflector 2 Voltage
            1.000     , $   ;  6: ground/spare
            1.000     , $   ;  7: ground/spare
            0.000763  , $   ;  8: V0 Voltage
            1.000     , $   ;  9: Analyzer Temperature
           -0.000459  , $   ; 10: +12V Voltage
           -0.000459  , $   ; 11: -12V Voltage
           -0.001055  , $   ; 12: +28V Voltage (after MCPHV enable plug)
           -0.001055  , $   ; 13: +28V Voltage (after NRHV enable plug)
            1.000     , $   ; 14: ground/spare
            1.000     , $   ; 15: ground/spare
            1.000     , $   ; 16: Digital Temperature
           -0.000169  , $   ; 17: +2.5V Digital Voltage
           -0.000191  , $   ; 18: +5V Digital Voltage
           -0.000169  , $   ; 19: +3.3V Digital Voltage
           -0.000191  , $   ; 20: +5V Analog Voltage
           -0.000191  , $   ; 21: -5V Analog Voltage
           -0.001055  , $   ; 22: +28V Voltage
            1.000        ]  ; 23: ground/spare

  swe_t = [1.6484d2, 3.9360d-2, 5.6761d-6, 4.4329d-10, 1.6701d-14, 2.4223d-19]

  pfp_v = [ 0.000173  , $   ;  0: DCB -5V Analog Voltage
            0.000173  , $   ;  1: DCB +5V Analog Voltage
            0.000173  , $   ;  2: DCB +5V Digital Voltage
            0.000108  , $   ;  3: DCB +3.3V Digital Voltage
            0.000076  , $   ;  4: DCB +1.3V Digital Voltage
            0.001046  , $   ;  5: PFP +28V Voltage
            0.006409  , $   ;  6: SWEA 28V Primary Current
            1.000     , $   ;  7: PFP Regulator Temperature
            0.019302  , $   ;  8: SWIA 28V Primary Current
            0.025558  , $   ;  9: STATIC 28V Primary Current
            0.009918  , $   ; 10: MAG1 28V Primary Current
            0.009918  , $   ; 11: MAG2 28V Primary Current
            0.020676  , $   ; 12: SEP 28V Primary Current
            0.025406  , $   ; 13: LPW 28V Primary Current
            0.001425  , $   ; 14: PFP 28V Primary Voltage
            7.7065d-5 , $   ; 15: PFP 28V Primary Current
            1.000     , $   ; 16: DCB Temperature
            1.000     , $   ; 17: DCB FPGA Daughter Board Temperature
            0.000153  , $   ; 18: Flash Bank 0 Voltage
            0.000153  , $   ; 19: Flash Bank 1 Voltage
            0.000153  , $   ; 20: +3.3V Digital Voltage
            0.000076  , $   ; 21: +1.5V Digital Voltage
            0.000076  , $   ; 22: Voltage Ref (Spare)
            0.000000  , $   ; 23: Analog Ground
            1.000        ]  ; 24: Spare

  pfp_t = [1.6828d2, -3.3664d-2, 4.0411d-6, -2.5861d-10, 7.9111d-15, -9.2462d-20]

; Grouping and Period

  swe_ne = [64, 32, 16, 0]       ; number of energy bins for group=0,1,2
  swe_dt = 2D^(dindgen(6) + 1D)  ; sample interval (sec) for period=0,1,2,3,4,5

; Define structures for raw and processed data

  mvn_swe_struct

; Define times of configuration changes

  mvn_swe_config

; Set verbosity

  if (size(swe_verbose,/type) eq 0) then swe_verbose = 0

  return

end
