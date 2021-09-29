;+
;
; SPP_SWP_SPI_FLIGHT_TBL
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 27801 $
; $LastChangedDate: 2019-09-30 22:35:14 -0700 (Mon, 30 Sep 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_tbl.pro $
;
;-

PRO spp_swp_spi_flight_tbl, mem, tbl

   ;; EModes and Checksums
   ;; --------------------
   ;; Sweep LUT
   ;; Full Sweep LUT
   ;; Targeted Sweep LUT
   spp_swp_spi_tables, tbl1, modeid='0010'x
   spp_swp_spi_tables, tbl2, modeid='0020'x
   spp_swp_spi_tables, tbl3, modeid='0030'x
   spp_swp_spi_tables, tbl4, modeid='0040'x
   spp_swp_spi_tables, tbl5, modeid='0050'x
   spp_swp_spi_tables, tbl6, modeid='0060'x
   spp_swp_spi_tables, tbl7, modeid='0070'x

   ;; TModes
   ;; --------------
   ;; PSUM
   ;; AR_SUM, SR_SUM
   ;; ALLUT, EDLUT
   ;; MRBINS
   ;; PMBINS
   spp_swp_spi_config_mode,  1, mem, cnf1
   spp_swp_spi_config_mode,  2, mem, cnf2
   spp_swp_spi_config_mode,  3, mem, cnf3
   spp_swp_spi_config_mode,  4, mem, cnf4
   spp_swp_spi_config_mode,  5, mem, cnf5
   spp_swp_spi_config_mode,  6, mem, cnf6
   spp_swp_spi_config_mode,  7, mem, cnf7
   spp_swp_spi_config_mode,  8, mem, cnf8
   ;;spp_swp_spi_config_mode,  9, mem, cnf9
   ;;spp_swp_spi_config_mode, 10, mem, cnf10
   

   ;; SWEM Boot
   tbl = {tbl1:tbl1,$
          tbl1b:tbl1,$
          tbl2:tbl2,$
          tbl2b:tbl2,$
          tbl3:tbl3,$
          tbl3b:tbl3,$
          tbl4:tbl4,$
          tbl4b:tbl4,$
          tbl5:tbl5,$
          tbl5b:tbl5,$
          tbl6:tbl6,$
          tbl6b:tbl6,$
          tbl7:tbl7,$
          tbl7b:tbl7,$
          
          cnf1:cnf1,$
          cnf2:cnf2,$
          cnf3:cnf3,$
          cnf4:cnf4,$
          cnf5:cnf5,$
          cnf6:cnf6,$
          cnf7:cnf7}
   
END
