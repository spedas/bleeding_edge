;+
;
; SPP_SWP_SPI_FLIGHT_PAR
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31607 $
; $LastChangedDate: 2023-03-09 13:13:18 -0800 (Thu, 09 Mar 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_par.pro $
;
;-

PRO spp_swp_spi_flight_par

   ;; COMMON BLOCK
   COMMON spi_param, param, dict

   ;; Flight Science Product Maps
   spp_swp_spi_flight_prd, prd

   ;; Events
   spp_swp_spi_flight_evt, evt

   ;; DAC to Voltage
   spp_swp_spi_flight_dac, dac

   ;; DAC to Deflection
   spp_swp_spi_flight_def, def

   ;; DAC to Energy
   spp_swp_spi_flight_nrg, nrg

   ;; Memory Map
   spp_swp_spi_flight_mem, mem

   ;; Anode Board
   spp_swp_spi_flight_ano, ano

   ;; Electrostatic Analyzer
   spp_swp_spi_flight_esa, esa

   ;; Geometric Factor
   spp_swp_spi_flight_geo, geo

   ;; Science Parameters
   ;; Prereq.: dac
   spp_swp_spi_flight_sci, dac, sci
   
   ;; Time-of-Flight Parameters
   ;; Prereq.: ano, sci
   spp_swp_spi_flight_tof, ano, sci, tof

   ;; Ion Carbon Foil Energy Loss
   ;; Prereq.: sci, tof
   spp_swp_spi_flight_elo, sci, tof, elo

   ;; Mass Tables
   ;; Prereq.: dac, sci, tof, elo
   spp_swp_spi_flight_mas, mas, dac, sci, tof, elo

   ;; Sweep Tables
   ;; Prereq.: mas, mem
   spp_swp_spi_flight_tbl, mas, mem, tbl

   ;; Foil Efficiencies
   spp_swp_spi_flight_eff, eff

   ;; Efficiencies - Anode
   ;;spp_swp_spi_flight_eff_ano, eff_ano
   
   ;; Efficiencies - Deflector
   ;;spp_swp_spi_flight_eff_def, eff_def
   
   ;; Efficiencies - Energy
   ;;spp_swp_spi_flight_eff_nrg, eff_nrg

   ;; Final Structure
   param = {prd:prd,$
            sci:sci,$
            evt:evt,$
            dac:dac,$
            tbl:tbl,$
            ano:ano,$
            esa:esa,$
            elo:elo,$
            def:def,$
            mas:mas,$
            tof:tof,$
            mem:mem,$
            eff:eff,$
            geo:geo}
            ;;eff_ano:eff_ano,$
            ;;eff_def:eff_def,$
            ;;eff_nrg:eff_nrg}

   ;; Load Dictionary from spi_mram.bin file
   ;;spp_swp_spi_flight_loa
   
END
