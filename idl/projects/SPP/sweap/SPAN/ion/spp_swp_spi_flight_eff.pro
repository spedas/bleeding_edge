;+
;
; SPP_SWP_SPI_FLIGHT_EFF
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31612 $
; $LastChangedDate: 2023-03-09 13:22:18 -0800 (Thu, 09 Mar 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_eff.pro $
;
;-

PRO spp_swp_spi_flight_eff, eff

   eff_start = [0.55, 0.50, 0.48, 0.45, 0.45, 0.44, 0.44, 0.43, 0.43, 0.43, 0.42, 0.42, 0.42, 0.44, 0.45, 0.47]
   eff_stop =  [0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.20, 0.20, 0.20, 0.20, 0.20, 0.20]

   eff = eff_start[1] * eff_stop[1] / 4D
   ;;eff = 0.2
   
END 
