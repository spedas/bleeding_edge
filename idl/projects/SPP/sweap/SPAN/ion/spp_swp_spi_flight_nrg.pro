;+
;
; SPP_SWP_SPI_FLIGHT_NRG
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26429 $
; $LastChangedDate: 2019-01-06 22:06:59 -0800 (Sun, 06 Jan 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_nrg.pro $
;
;-

PRO spp_swp_spi_flight_nrg, nrg


   ;; K Values from Calibration
   kval = [16.9059, 17.4086, 17.3547, 17.4056, 16.9689, $
           17.0019, 17.4656, 16.7100, 16.5611, 16.4142, $
           16.6191, 16.6381, 16.5431, 16.1663, 16.1003, 16.1353]

   nrg = {kval:kval}

   return
   
END



   
