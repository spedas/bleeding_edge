;+
;
; SPP_SWP_SPI_FLIGHT_PRD
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 28310 $
; $LastChangedDate: 2020-02-18 15:48:09 -0800 (Tue, 18 Feb 2020) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_prd.pro $
;
;-

PRO spp_swp_spi_flight_prd, prd

   ;; Common Block
   COMMON spi_param, para, dict

   ;; Load all avaiable products
   prod_1D = spp_swp_spi_flight_product_tables('prod_1D')
   prod_08D = spp_swp_spi_flight_product_tables('prod_08D')
   prod_32E = spp_swp_spi_flight_product_tables('prod_32E')
   prod_16A = spp_swp_spi_flight_product_tables('prod_16A')
   prod_32E_16A = spp_swp_spi_flight_product_tables('prod_32E_16A')
   prod_08D_32E = spp_swp_spi_flight_product_tables('prod_08D_32E')
   prod_08D_16A = spp_swp_spi_flight_product_tables('prod_08D_16A')
   prod_08D_32E_16A = spp_swp_spi_flight_product_tables('prod_08D_32E_16A')
   prod_08D_32E_08A = spp_swp_spi_flight_product_tables('prod_08D_32E_08A')
   prod_08D_32E_08A_v2 = spp_swp_spi_flight_product_tables('prod_08D_32E_08A_v2')
   prod_08D_32E_08A_v3 = spp_swp_spi_flight_product_tables('prod_08D_32E_08A_v3')
   
   ;; Insert into Structure
   prd = {prod_1D:prod_1D,$
          prod_08D:prod_08D,$
          prod_32E:prod_32E,$
          prod_16A:prod_16A,$
          prod_32E_16A:prod_32E_16A,$
          prod_08D_32E:prod_08D_32E,$
          prod_08D_16A:prod_08D_16A,$
          prod_08D_32E_16A:prod_08D_32E_16A,$
          prod_08D_32E_08A:prod_08D_32E_08A,$
          prod_08D_32E_08A_v2:prod_08D_32E_08A_v2,$
          prod_08D_32E_08A_v3:prod_08D_32E_08A_v3}

   

END
