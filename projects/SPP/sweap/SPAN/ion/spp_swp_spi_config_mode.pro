;+
; SPP_SWP_SPI_CONFIG_MODE
;
; Keywords:
;
; TMode: The configuration to load
;      Options:
;         Mode=0
;           - Name: RESERVED
;           - Rate: NA
;         Mode=1
;           - Name: SWEM Startup State
;           - Rate:   15 Bytes/s
;         Mode=2 - Flight Background
;           - Name: SWEM Startup State
;           - Rate:   42 Bytes/s
;         Mode=3 - Flight Low Telemetry
;           - Name: SWEM Startup State
;           - Rate:  278 Bytes/s
;         Mode=4 - Flight High Telemetry
;           - Name: SWEM Startup State
;           - Rate: 2326 Bytes/s
;         Mode=6 - Calibration
;           - Name: SWEM Startup State
;           - Rate: 5044 Bytes/s
;         Mode=7 - Cruise
;           - Name: SWEM Startup State
;           - Rate: XXXX Bytes/s
;
;
; $LastChangedDate: 2019-03-17 22:56:35 -0700 (Sun, 17 Mar 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_config_mode.pro $
;
;-

PRO spp_swp_spi_config_mode, mode, mem, info
   
   ;; SPAN-Ion Common Block
   ;;COMMON spi_param, param, dict
   ;;IF ~isa(param) THEN stop   ;;spp_swp_spi_param

   CASE mode OF 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;    Mode 1: SWEM Startup State    ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      1: BEGIN
         enrg_mode = '01'x
         tlm_mode  = '01'x
         tof_mode  = {targ:1,full:0,accu:6,anod:1}
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_swem_state, mem, info
      END 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;    Mode 2: Flight Background     ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      2: BEGIN
         enrg_mode = '01'x
         tlm_mode  = '02'x
         tof_mode  = {targ:1,full:0,accu:8,anod:0}
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_background, mem, info
      END 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;    Mode 3: Flight Low Setup      ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      3: BEGIN
         enrg_mode = '01'x
         tlm_mode  = '03'x
         tof_mode  = {targ:1,full:0,accu:6,anod:1}
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_low, mem, info
      END 
         
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;    Mode 4: Flight High Setup     ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      4: BEGIN    
         enrg_mode = '01'x
         tlm_mode  = '04'x
         tof_mode  = {targ:1,full:0,accu:8,anod:0}
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_high, mem, info
      END 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;  Mode 5: Flight Moments Setup    ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      5: BEGIN
         enrg_mode = '01'x
         tlm_mode  = '05'x
         tof_mode  = {targ:1,full:0,accu:8,anod:0}
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_moments, mem, info
      END 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;    Mode 6: Calibration Setup     ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      6: BEGIN
         enrg_mode = '00'x
         tlm_mode  = '06'x
         tof_mode  = {targ:1,full:0,accu:0,anod:0}
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_calibration, mem, info
      END 

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;          Mode 7: Cruise          ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      7: BEGIN
         ;; Set the Mode ID
         enrg_mode = '01'x
         tlm_mode  = '07'x
         tof_mode  = {targ:1,full:0,accu:8,anod:0}         
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_cruise, mem, info
      END

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;     Mode 8: High Rate Moments    ;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
      8: BEGIN
         ;; Set the Mode ID
         enrg_mode = '01'x
         tlm_mode  = '08'x
         tof_mode  = {targ:1,full:0,accu:8,anod:0}         
         mode_id   = ishft(enrg_mode,4) AND tlm_mode
         spp_swp_spi_config_flight_cruise, mem, info
      END
      
   ENDCASE

END
