;+
;PROCEDURE:   mvn_swe_struct
;PURPOSE:
;  Defines data structures for 3D, PAD, and ENGY products.  These work for both survey
;  and archive.
;
;  All times are for the center of the sample.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-03 11:54:58 -0700 (Tue, 03 Jun 2025) $
; $LastChangedRevision: 33361 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_struct.pro $
;
;CREATED BY:	David L. Mitchell  2013-07-26
;FILE:  mvn_swe_struct.pro
;-
pro mvn_swe_struct

  @mvn_swe_com

  n_e =  64                       ; number of energy bins
  n_az = 16                       ; number of azimuth bins
  n_el =  6                       ; number of elevation bins
  n_a  = n_az*n_el                ; number of solid angle bins

; Raw telemetry structures

  pfp_hsk_str =  {time    : 0D            , $    ; packet unix time
                  met     : 0D            , $    ; packet mission elapsed time
                  addr    : -1L           , $    ; packet address
                  ver     : 0B            , $    ; CCSDS Version
                  type    : 0B            , $    ; CCSDS Type
                  hflg    : 0B            , $    ; CCSDS Secondary header flag
                  APID    : 0U            , $    ; CCSDS APID
                  gflg    : 0B            , $    ; CCSDS Group flags
                  npkt    : 0B            , $    ; packet counter
                  plen    : 0U            , $    ; packet length
                  N5AV    : 0.            , $    ; DCB -5V Analog (V)
                  P5AV    : 0.            , $    ; DCB +5V Analog (V)
                  P5DV    : 0.            , $    ; DCB +5V Digital (V)
                  P3P3DV  : 0.            , $    ; DCB +3.3V Digital (V)
                  P1P5DV  : 0.            , $    ; DCB +1.5V Digital (V)
                  P28V    : 0.            , $    ; PFP 28V (V)
                  SWE28I  : 0.            , $    ; SWEA 28V Primary Current (mA)
                  REGT    : 0.            , $    ; PFP Regulator Temperature (C)
                  SWI28I  : 0.            , $    ; SWIA 28V Primary Current (mA)
                  STA28I  : 0.            , $    ; STATIC 28V Primary Current (mA)
                  MAG128I : 0.            , $    ; MAG1 28V Primary Current (mA)
                  MAG228I : 0.            , $    ; MAG2 28V Primary Current (mA)
                  SEP28I  : 0.            , $    ; SEP 28V Primary Current (mA)
                  LPW28I  : 0.            , $    ; LPW 28V Primary Current (mA)
                  PFP28V  : 0.            , $    ; PFP 28V Primary Voltage (V)
                  PFP28I  : 0.            , $    ; PFP 28V Primary Current (mA)
                  DCBT    : 0.            , $    ; DCB Temperature (C)
                  FPGAT   : 0.            , $    ; FPGA Daughter Temperature (C)
                  FLASH0V : 0.            , $    ; Flash Bank 0 Voltage (V)
                  FLASH1V : 0.            , $    ; Flash Bank 1 Voltage (V)
                  PF3P3DV : 0.            , $    ; +3.3V Digital (V)
                  PF1P5DV : 0.            , $    ; +1.5V Digital (V)
                  PFPVREF : 0.            , $    ; PFP Voltage Reference
                  PFPAGND : 0.               }   ; PFP Analog Ground

  swe_hsk_str =  {time    : 0D            , $    ; packet unix time
                  met     : 0D            , $    ; packet mission elapsed time
                  addr    : -1L           , $    ; packet address
                  ver     : 0B            , $    ; CCSDS Version
                  type    : 0B            , $    ; CCSDS Type
                  hflg    : 0B            , $    ; CCSDS Secondary header flag
                  APID    : 0U            , $    ; CCSDS APID
                  gflg    : 0B            , $    ; CCSDS Group flags
                  npkt    : 0B            , $    ; packet counter
                  plen    : 0U            , $    ; packet length
                  LVPST   : 0.            , $    ; LVPS temperature (C)
                  MCPHV   : 0.            , $    ; MCP HV (V)
                  NRV     : 0.            , $    ; NR HV readback (V)
                  ANALV   : 0.            , $    ; Analyzer voltage (V)
                  DEF1V   : 0.            , $    ; Deflector 1 voltage (V)
                  DEF2V   : 0.            , $    ; Deflector 2 voltage (V)
                  V0V     : 0.            , $    ; V0 voltage (V)
                  ANALT   : 0.            , $    ; Analyzer temperature (C)
                  P12V    : 0.            , $    ; +12 V
                  N12V    : 0.            , $    ; -12 V
                  MCP28V  : 0.            , $    ; +28-V MCP supply (V)
                  NR28V   : 0.            , $    ; +28-V NR supply (V)
                  DIGT    : 0.            , $    ; Digital temperature (C)
                  P2P5DV  : 0.            , $    ; +2.5 V Digital (V)
                  P5DV    : 0.            , $    ; +5 V Digital (V)
                  P3P3DV  : 0.            , $    ; +3.3 V Digital (V)
                  P5AV    : 0.            , $    ; +5 V Analog (V)
                  N5AV    : 0.            , $    ; -5 V Analog (V)
                  P28V    : 0.            , $    ; +28 V Primary (V)
                  modeID  : 0B            , $    ; Parameter Table Mode ID
                  opts    : 0B            , $    ; Options
                  DistSvy : 0B            , $    ; 3D Survey Options     (CCGGxNNN)
                  DistArc : 0B            , $    ; 3D Archive Options    (CCGGxNNN)
                  PadSvy  : 0B            , $    ; PAD Survey Options    (CCGGxNNN)
                  PadArc  : 0B            , $    ; PAD Archive Options   (CCGGxNNN)
                  SpecSvy : 0B            , $    ; ENGY Survey Options   (CCxxxNNN)
                  SpecArc : 0B            , $    ; ENGY Archive Options  (CCxxxNNN)
                  LUTADR  : bytarr(4)     , $    ; LUT Address 0-3
                  CSMLMT  : 0B            , $    ; CSM Failure Limit
                  CSMCTR  : 0B            , $    ; CSM Failure Count
                  RSTLMT  : 0B            , $    ; Reset if no message in seconds
                  RSTSEC  : 0B            , $    ; Reset seconds since last message
                  MUX     : bytarr(4)     , $    ; Fast Housekeeping MUX 0-3
                  DSF     : fltarr(6)     , $    ; Deflection scale factor 0-5
                  SSCTL   : 0U            , $    ; Active LUT
                  SIFCTL  : bytarr(16)    , $    ; SIF control register
                  MCPDAC  : 0U            , $    ; MCP DAC
                  ChkSum  : bytarr(4)     , $    ; Checksum LUT 0-3
                  CmdCnt  : 0U            , $    ; Command counter
                  HSKREG  : bytarr(16)       }   ; Digital housekeeping register

; SIF Control Register Bits
;   0 -> HV enable allow
;   1 -> HV sync enable (always 0)
;   2 -> Test pulser enable
;   3 -> spare
;   4 -> spare
;   5 -> spare
;   6 -> spare
;   7 -> spare
;   8 -> sweep diagnostic mode (ANALV)
;   9 -> sweep diagnostic mode (DEF1)
;  10 -> sweep diagnostic mode (DEF2)
;  11 -> sweep diagnostic mode (V0)
;  12 -> spare
;  13 -> spare
;  14 -> spare
;  15 -> sweep enable
;
              
  swe_a0_str =  {time    : 0D            , $    ; packet unix time
                 met     : 0D            , $    ; packet mission elapsed time
                 addr    : -1L           , $    ; packet address
                 npkt    : 0B            , $    ; packet counter
                 cflg    : 0B            , $    ; compression flag
                 modeID  : 0B            , $    ; mode ID
                 ctype   : 0B            , $    ; compression type
                 group   : 0B            , $    ; grouping (2^N adjacent bins)
                 period  : 0B            , $    ; sampling interval (2*2^period sec)
                 lut     : 0B            , $    ; LUT in use (0-8)
                 e0      : 0             , $    ; starting energy step (0, 16, 32, 48)
                 data    : fltarr(80,16) , $    ; data array (80A x 16E)
                 var     : fltarr(80,16)    }   ; variance array (80A x 16E)

  swe_a2_str =  {time    : 0D            , $    ; packet unix time
                 met     : 0D            , $    ; packet mission elapsed time
                 addr    : -1L           , $    ; packet address
                 npkt    : 0B            , $    ; packet counter
                 cflg    : 0B            , $    ; compression flag
                 modeID  : 0B            , $    ; mode ID
                 ctype   : 0B            , $    ; compression type
                 group   : 0B            , $    ; grouping (2^N adjacent bins)
                 period  : 0B            , $    ; sampling interval (2*2^period sec)
                 lut     : 0B            , $    ; LUT in use (0-8)
                 Baz     : 0B            , $    ; magnetic field azimuth (0-255)
                 Bel     : 0B            , $    ; magnetic field elevation (0-39)
                 data    : fltarr(16,64) , $    ; data array (16A x 64E)
                 var     : fltarr(16,64)    }   ; variance array (16A x 64E)

  swe_a4_str = {time    : 0D            , $    ; packet unix time
                met     : 0D            , $    ; packet mission elapsed time
                addr    : -1L           , $    ; packet address
                npkt    : 0B            , $    ; packet counter
                cflg    : 0B            , $    ; compression flag
                modeID  : 0B            , $    ; mode ID
                ctype   : 0B            , $    ; compression type
                smode   : 0B            , $    ; summing mode (0 = off, 1 = on)
                period  : 0B            , $    ; sampling interval (2*2^period sec)
                lut     : 0B            , $    ; LUT in use (0-8)
                data    : fltarr(64,16) , $    ; data array (64E x 16T)
                var     : fltarr(64,16)    }   ; variance array (64E x 16T)

  swe_a6_str = {time    : 0D            , $    ; packet unix time
                met     : 0D            , $    ; packet mission elapsed time
                addr    : -1L           , $    ; packet address
                npkt    : 0B            , $    ; packet counter
                cflg    : 0B            , $    ; compression flag
                mux     : bytarr(4)     , $    ; housekeeping channel numbers
                name    : strarr(4)     , $    ; housekeeping channel names
                value   : fltarr(224,4)    }   ; housekeeping channel values

; Define 3D data structure

  swe_3d_struct = {project_name    : 'MAVEN'                 , $
                   data_name       : 'SWEA 3D Survey'        , $
                   apid            : 'A0'XB                  , $
                   units_name      : 'counts'                , $
                   units_procedure : 'mvn_swe_convert_units' , $
                   chksum          : 0B                      , $  ; LUT checksum
                   lut             : 0B                      , $  ; active LUT
                   met             : 0D                      , $  ; mission elapsed time
                   time            : 0D                      , $  ; unix time
                   end_time        : 0D                      , $
                   delta_t         : 0D                      , $  ; sample cadence
                   integ_t         : 0D                      , $  ; integration time
		           dt_arr          : fltarr(n_e,n_a)         , $  ; weighting array for summing bins
		           group           : 0                       , $  ; energy grouping parameter
                   nenergy         : n_e                     , $  ; number of energies
                   energy          : fltarr(n_e,n_a)         , $  ; energy sweep
		           denergy         : fltarr(n_e,n_a)         , $  ; energy widths for each energy/angle bin
		           eff             : fltarr(n_e,n_a)         , $  ; MCP efficiency
                   nbins           : n_a                     , $  ; number of angle bins
                   theta           : fltarr(n_e,n_a)         , $  ; elevation angle
                   dtheta          : fltarr(n_e,n_a)         , $  ; elevation angle width
                   phi             : fltarr(n_e,n_a)         , $  ; azimuth angle
                   dphi            : fltarr(n_e,n_a)         , $  ; azimuth angle width
                   domega          : fltarr(n_e,n_a)         , $  ; solid angle
                   gf              : fltarr(n_e,n_a)         , $  ; geometric factor per energy/angle bin
                   dtc             : fltarr(n_e,n_a)         , $  ; dead time correction
                   mass            : 0.                      , $  ; electron rest mass [eV/(km/s)^2]
                   sc_pot          : 0.                      , $  ; spacecract potential
                   magf            : fltarr(3)               , $  ; magnetic field
                   maglev          : 0B                      , $  ; MAG data level (0-2)
                   v_flow          : fltarr(3)               , $  ; bulk flow velocity
                   bkg             : fltarr(n_e,n_a)         , $  ; background/contamination
                   data            : fltarr(n_e,n_a)         , $  ; data
                   valid           : replicate(1B,n_e,n_a)   , $  ; used for masking
                   quality         : 1B                      , $  ; quality (2B = good, 1B = ?, 0B = bad)
                   var             : fltarr(n_e,n_a)            } ; variance

; Stripped down 3D structure for common block storage

  swe_3d_l2_str = {met             : 0D                      , $  ; mission elapsed time
                   time            : 0D                      , $  ; unix time
		           group           : 0                       , $  ; energy grouping parameter
                   counts          : fltarr(n_e,n_a)            } ; raw counts

; Define PAD data structure
;  The magnetic field appears twice.  Baz and Bel are the magnetic field angles in SWEA coordinates
;  that are calculated in FSW and used to sort pitch angles for the PAD data product.  Magf is the
;  magnetic field calculated on the ground from MAG packets.

  swe_pad_struct = {project_name    : 'MAVEN'                 , $
                    data_name       : 'SWEA PAD Survey'       , $
                    apid            : 'A2'XB                  , $
                    units_name      : 'counts'                , $
                    units_procedure : 'mvn_swe_convert_units' , $
                    chksum          : 0B                      , $  ; LUT checksum
                    lut             : 0B                      , $  ; active LUT
                    met             : 0D                      , $  ; mission elapsed time
                    time            : 0D                      , $  ; unix time
                    end_time        : 0D                      , $
                    delta_t         : 0D                      , $  ; sample cadence
                    integ_t         : 0D                      , $  ; integration time
	 	            dt_arr          : fltarr(n_e,n_az)        , $  ; weighting array for summing bins
		            group           : 0                       , $  ; energy grouping parameter
                    nenergy         : n_e                     , $  ; number of energies
                    energy          : fltarr(n_e,n_az)        , $  ; energy sweep
		            denergy         : fltarr(n_e,n_az)        , $  ; energy widths for each energy/angle bin
		            eff             : fltarr(n_e,n_az)        , $  ; MCP efficiency
                    nbins           : n_az                    , $  ; number of angle bins
                    pa              : fltarr(n_e,n_az)        , $  ; pitch angle
                    dpa             : fltarr(n_e,n_az)        , $  ; pitch angle width
                    pa_min          : fltarr(n_e,n_az)        , $  ; pitch angle minimum
                    pa_max          : fltarr(n_e,n_az)        , $  ; pitch angle maximum
                    theta           : fltarr(n_e,n_az)        , $  ; elevation angle
                    dtheta          : fltarr(n_e,n_az)        , $  ; elevation angle width
                    phi             : fltarr(n_e,n_az)        , $  ; azimuth angle
                    dphi            : fltarr(n_e,n_az)        , $  ; azimuth angle width
                    domega          : fltarr(n_e,n_az)        , $  ; solid angle
                    gf              : fltarr(n_e,n_az)        , $  ; geometric factor
                    dtc             : fltarr(n_e,n_az)        , $  ; dead time correction
                    Baz             : 0.                      , $  ; raw magnetic field azimuth in SWEA coord.
                    Bel             : 0.                      , $  ; raw magnetic field elevation in SWEA coord.
                    iaz             : intarr(16)              , $  ; anode bin numbers (0-15)
                    jel             : intarr(16)              , $  ; deflection bin numbers (0-5)
                    k3d             : intarr(16)              , $  ; 3D bin numbers (0-95)
                    mass            : 0.                      , $  ; electron rest mass [eV/(km/s)^2]
                    sc_pot          : 0.                      , $  ; spacecract potential
                    magf            : fltarr(3)               , $  ; magnetic field
                    maglev          : 0B                      , $  ; MAG data level (0-2)
                    v_flow          : fltarr(3)               , $  ; bulk flow velocity
                    bkg             : fltarr(n_e,n_az)        , $  ; background/contamination
                    data            : fltarr(n_e,n_az)        , $  ; data
                    valid           : replicate(1B,n_e,n_az)  , $  ; used for masking
                    quality         : 1B                      , $  ; quality (2B = good, 1B = ?, 0B = bad)
                    var             : fltarr(n_e,n_az)           } ; variance

; Stripped down PAD structure for common block storage

  swe_pad_l2_str = {met             : 0D                      , $  ; mission elapsed time
                    time            : 0D                      , $  ; unix time
		            group           : 0                       , $  ; energy grouping parameter
                    Baz             : 0.                      , $  ; raw magnetic field azimuth in SWEA coord.
                    Bel             : 0.                      , $  ; raw magnetic field elevation in SWEA coord.
                    data            : fltarr(n_e,n_az)           } ; data

; Define Energy Spectrum (SPEC) data structure

  swe_engy_struct = {project_name    : 'MAVEN'                 , $
                     data_name       : 'SWEA SPEC Survey'      , $
                     apid            : 'A4'XB                  , $
                     units_name      : 'counts'                , $
                     units_procedure : 'mvn_swe_convert_units' , $
                     chksum          : 0B                      , $  ; LUT checksum
                     lut             : 0B                      , $  ; active LUT
                     met             : 0D                      , $  ; mission elapsed time
                     time            : 0D                      , $  ; unix time
                     end_time        : 0D                      , $
                     delta_t         : 0D                      , $  ; sample cadence
                     integ_t         : 0D                      , $  ; integration time
	 	             dt_arr          : fltarr(n_e)             , $  ; weighting array for summing bins
                     nenergy         : n_e                     , $  ; number of energies
                     energy          : fltarr(n_e)             , $  ; energy sweep
		             denergy         : fltarr(n_e)             , $  ; energy widths for each energy/angle bin
		             eff             : fltarr(n_e)             , $  ; MCP efficiency
                     gf              : fltarr(n_e)             , $  ; geometric factor
                     dtc             : fltarr(n_e)             , $  ; dead time correction
                     mass            : 0.                      , $  ; electron rest mass [eV/(km/s)^2]
                     sc_pot          : 0.                      , $  ; spacecract potential
                     magf            : fltarr(3)               , $  ; magnetic field
                     maglev          : 0B                      , $  ; MAG data level (0-2)
                     bkg             : fltarr(n_e)             , $  ; background/contamination
                     data            : fltarr(n_e)             , $  ; data
                     valid           : replicate(1B,n_e)       , $  ; used for masking
                     quality         : 1B                      , $  ; quality (2B = good, 1B = ?, 0B = bad)
                     var             : fltarr(n_e)                } ; variance

; Stripped down SPEC structure for common block storage

  swe_engy_l2_str = {met             : 0D                      , $  ; mission elapsed time
                     time            : 0D                      , $  ; unix time
                     chksum          : 0B                      , $  ; LUT checksum
                     dt_arr          : fltarr(n_e,n_az)        , $  ; weighting array for summing bins
                     data            : fltarr(n_e,n_az)           } ; data

; Define Magnetic Field data structure

  swe_mag_struct = {project_name    : 'MAVEN'                 , $
                    data_name       : 'SWEA PAD MAG'          , $
                    units_name      : 'nT'                    , $
                    spice_frame     : 'MAVEN_SWEA'            , $
                    level           : 0B                      , $
                    valid           : 0B                      , $
                    time            : 0D                      , $  ; unix time
                    Bamp            : 0.                      , $  ; amplitude (nT)
                    Bphi            : 0.                      , $  ; SWEA azimuth (radians)
                    Bthe            : 0.                      , $  ; SWEA elevation (radians)
                    magf            : fltarr(3)                  } ; vector in SWEA frame (nT)

  return

end
