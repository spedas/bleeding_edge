;+
;
; SPP_SWP_SPI_FLIGHT_DAC
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26427 $
; $LastChangedDate: 2019-01-06 22:05:44 -0800 (Sun, 06 Jan 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_dac.pro $
;
;-

PRO spp_swp_spi_flight_dac, table

   ;;------------------------------------------------------
   ;; DAC to Voltage (DVM from HV Calibration Test)

   ;; Hemisphere 
   hemi_dacs = ['0000'x,'0040'x,'0080'x,'00C0'x,'0100'x,$
                '0280'x,'0500'x,'0800'x,'0C00'x,'1000'x]
   hemi_volt = [0.006,-3.903,-7.8,-11.7,-15.61,$
                -39.04,-78.1,-125,-187.5,-250]

   ;; Deflector 1
   def1_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def1_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Deflector 2
   def2_dacs = ['0000'x,'0080'x,'0100'x,'0180'x,'0300'x,$
                '0700'x,'0D00'x,'1300'x,'1C80'x,'2600'x]

   def2_volt = [0.0016,-3.15,-6.31,-9.48,-18.98,-44.3,$
                -82.3,-120.3,-180.5,-240.6]

   ;; Spoiler 
   splr_dacs = ['0000'x,'0100'x,'0200'x,'0400'x,'1000'x,'4000'x]
   splr_volt = [0.0003,-0.31,-0.62,-1.243,-4.974,-19.9]

   hemi_fitt = linfit(hemi_dacs,hemi_volt)
   def1_fitt = linfit(def1_dacs,def1_volt)
   def2_fitt = linfit(def2_dacs,def2_volt)
   splr_fitt = linfit(splr_dacs,splr_volt)

   table = {hemi_fitt:hemi_fitt,$
            def1_fitt:def1_fitt,$
            def2_fitt:def2_fitt,$
            splr_fitt:splr_fitt} 

END
