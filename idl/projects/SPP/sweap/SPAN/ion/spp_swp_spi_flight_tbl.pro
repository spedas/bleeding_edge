;+
;
; SPP_SWP_SPI_FLIGHT_TBL
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31607 $
; $LastChangedDate: 2023-03-09 13:13:18 -0800 (Thu, 09 Mar 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_tbl.pro $
;
;-

PRO spp_swp_spi_flight_tbl, mas, mem, tbl

   ;; EModes and Checksums
   ;; --------------------
   ;; Sweep LUT
   ;; Full Sweep LUT
   ;; Targeted Sweep LUT
   ;;spp_swp_spi_tables, tbl1, modeid='0010'x
   ;;spp_swp_spi_tables, tbl2, modeid='0020'x
   ;;spp_swp_spi_tables, tbl3, modeid='0030'x
   ;;spp_swp_spi_tables, tbl4, modeid='0040'x
   ;;spp_swp_spi_tables, tbl5, modeid='0050'x
   ;;spp_swp_spi_tables, tbl6, modeid='0060'x
   ;;spp_swp_spi_tables, tbl7, modeid='0070'x
   ;;spp_swp_spi_tables, tbl8, modeid='0080'x

   spp_swp_spi_tables, tbl1,  emode=1
   spp_swp_spi_tables, tbl2,  emode=2
   spp_swp_spi_tables, tbl3,  emode=3
   spp_swp_spi_tables, tbl4,  emode=4
   spp_swp_spi_tables, tbl5,  emode=5
   spp_swp_spi_tables, tbl6,  emode=6
   spp_swp_spi_tables, tbl7,  emode=7
   spp_swp_spi_tables, tbl8,  emode=8
   spp_swp_spi_tables, tbl9,  emode=9
   spp_swp_spi_tables, tbl10,  emode=10
   

   ;; TModes
   ;; --------------
   ;; PSUM
   ;; AR_SUM, SR_SUM
   ;; ALLUT, EDLUT
   ;; MRBINS
   ;; PMBINS
   spp_swp_spi_config_mode,  1,  mem, cnf1
   spp_swp_spi_config_mode,  2,  mem, cnf2
   spp_swp_spi_config_mode,  3,  mem, cnf3
   spp_swp_spi_config_mode,  4,  mem, cnf4
   spp_swp_spi_config_mode,  5,  mem, cnf5
   spp_swp_spi_config_mode,  6,  mem, cnf6
   spp_swp_spi_config_mode,  7,  mem, cnf7
   spp_swp_spi_config_mode,  8,  mem, cnf8
   spp_swp_spi_config_mode,  9,  mem, cnf9
   ;;spp_swp_spi_config_mode,  10, mem, cnf10

   ;; Associated Mass Bins

   ;; Index of only energy steps (32) into fsindex (256)
   ind = indgen(32)*8

   ;; Only use 7 most significant bits for index
   mi1  = ishft(reform( tbl1.hem_dac[tbl1.fsindex[0,ind]]), -9)
   mi2  = ishft(reform( tbl2.hem_dac[tbl2.fsindex[0,ind]]), -9)
   mi3  = ishft(reform( tbl3.hem_dac[tbl3.fsindex[0,ind]]), -9)
   mi4  = ishft(reform( tbl4.hem_dac[tbl4.fsindex[0,ind]]), -9)
   mi5  = ishft(reform( tbl5.hem_dac[tbl5.fsindex[0,ind]]), -9)
   mi6  = ishft(reform( tbl6.hem_dac[tbl6.fsindex[0,ind]]), -9)
   mi7  = ishft(reform( tbl7.hem_dac[tbl7.fsindex[0,ind]]), -9)
   mi8  = ishft(reform( tbl8.hem_dac[tbl8.fsindex[0,ind]]), -9)
   mi9  = ishft(reform( tbl9.hem_dac[tbl9.fsindex[0,ind]]), -9)
   mi10 = ishft(reform(tbl10.hem_dac[tbl10.fsindex[0,ind]]),-9)

   ;; Summation Value
   msu1  = mas.mt_bin[ mi1,*]
   msu2  = mas.mt_bin[ mi2,*]
   msu3  = mas.mt_bin[ mi3,*]
   msu4  = mas.mt_bin[ mi4,*]
   msu5  = mas.mt_bin[ mi5,*]
   msu6  = mas.mt_bin[ mi6,*]
   msu7  = mas.mt_bin[ mi7,*]
   msu8  = mas.mt_bin[ mi8,*]
   msu9  = mas.mt_bin[ mi9,*]
   msu10 = mas.mt_bin[mi10,*]
      
   ;; Mass per Charge Value
   mpq1  = mas.mt_mpq[ mi1,*]
   mpq2  = mas.mt_mpq[ mi2,*]
   mpq3  = mas.mt_mpq[ mi3,*]
   mpq4  = mas.mt_mpq[ mi4,*]
   mpq5  = mas.mt_mpq[ mi5,*]
   mpq6  = mas.mt_mpq[ mi6,*]
   mpq7  = mas.mt_mpq[ mi7,*]
   mpq8  = mas.mt_mpq[ mi8,*]
   mpq9  = mas.mt_mpq[ mi9,*]
   mpq10 = mas.mt_mpq[mi10,*]
   
   ;; Time-of-Flight Value
   mtf1  = mas.mt_tof[ mi1,*]
   mtf2  = mas.mt_tof[ mi2,*]
   mtf3  = mas.mt_tof[ mi3,*]
   mtf4  = mas.mt_tof[ mi4,*]
   mtf5  = mas.mt_tof[ mi5,*]
   mtf6  = mas.mt_tof[ mi6,*]
   mtf7  = mas.mt_tof[ mi7,*]
   mtf8  = mas.mt_tof[ mi8,*]
   mtf9  = mas.mt_tof[ mi9,*]
   mtf10 = mas.mt_tof[mi10,*]
   

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
          tbl8:tbl8,$
          tbl8b:tbl8,$
          tbl9:tbl9,$
          ;;tbl9b:tbl9,$
          tbl10:tbl10,$
          ;;tbl10b:tbl10,$

          msu1:msu1,$
          msu2:msu2,$
          msu3:msu3,$
          msu4:msu4,$
          msu5:msu5,$
          msu6:msu6,$
          msu7:msu7,$
          msu8:msu8,$
          msu9:msu9,$
          msu10:msu10,$

          mpq1:mpq1,$
          mpq2:mpq2,$
          mpq3:mpq3,$
          mpq4:mpq4,$
          mpq5:mpq5,$
          mpq6:mpq6,$
          mpq7:mpq7,$
          mpq8:mpq8,$
          mpq9:mpq9,$
          mpq10:mpq10,$
          

          mtf1:mtf1,$
          mtf2:mtf2,$
          mtf3:mtf3,$
          mtf4:mtf4,$
          mtf5:mtf5,$
          mtf6:mtf6,$
          mtf7:mtf7,$
          mtf8:mtf8,$
          mtf9:mtf9,$
          mtf10:mtf10,$
          
          
          cnf1:cnf1,$
          cnf2:cnf2,$
          cnf3:cnf3,$
          cnf4:cnf4,$
          cnf5:cnf5,$
          cnf6:cnf6,$
          cnf7:cnf7,$
          cnf8:cnf8,$
          cnf9:cnf9}
          ;;cnf10:cnf10}
   
END
