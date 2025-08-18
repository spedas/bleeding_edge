;+
;
; ESC_IESA_FLIGHT_PAR
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31964 $
; $LastChangedDate: 2023-07-21 12:09:40 -0700 (Fri, 21 Jul 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_flight_par.pro $
;
;-

PRO esc_iesa_flight_par

   ;; COMMON BLOCK
   COMMON esc_iesa_par, iesa_par, iesa_dict

   ;; Flight Science Product Maps
   ;; esc_iesa_flight_prd, prd

   ;; iESA FM1 Events
   esc_iesa_fm1_evt, evt

   ;; DAC to Deflection
   ;;esc_iesa_flight_def, def

   ;; DAC to Energy
   ;;esc_iesa_flight_nrg, nrg

   ;; Memory Map
   ;;esc_iesa_flight_mem, mem

   ;; Anode Board
   esc_iesa_fm1_ano, ano

   ;; Electrostatic Analyzer
   ;;esc_iesa_flight_esa, esa

   ;; Geometric Factor
   ;;esc_iesa_flight_geo, geo

   ;; Science Parameters
   esc_iesa_fm1_sci, sci
   
   ;; Time-of-Flight Parameters
   esc_iesa_fm1_tof, ano, sci, tof

   ;; Ion Carbon Foil Energy Loss
   ;; Prereq.: sci, tof
   ;;esc_iesa_flight_elo, sci, tof, elo

   ;; Mass Tables
   ;; Prereq.: dac, sci, tof, elo
   ;;esc_iesa_flight_mas, mas, dac, sci, tof, elo

   ;; Sweep Tables
   ;;esc_iesa_flight_tbl, mas, mem, tbl

   ;; Foil Efficiencies
   ;;esc_iesa_flight_eff, eff

   ;; Efficiencies - Anode
   ;;spp_swp_spi_flight_eff_ano, eff_ano
   
   ;; Efficiencies - Deflector
   ;;spp_swp_spi_flight_eff_def, eff_def
   
   ;; Efficiencies - Energy
   ;;spp_swp_spi_flight_eff_nrg, eff_nrg

   ;; Final Structure
   iesa_par = {$ ;;prd:prd,$
              ;;sci:sci,$
              evt:evt, $
              ;;dac:dac,$
              ;;tbl:tbl,$
              ano:ano, $
              ;;esa:esa,$
              ;;elo:elo,$
              ;;def:def,$
              ;;mas:mas,$
              tof:tof $
              ;;mem:mem,$
              ;;eff:eff,$
              ;;geo:geo$
              }
   ;;eff_ano:eff_ano,$
   ;;eff_def:eff_def,$
   ;;eff_nrg:eff_nrg}
   
   ;; Load Dictionary from spi_mram.bin file
   ;;spp_swp_spi_flight_loa
   
END
