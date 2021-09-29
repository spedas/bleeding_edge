;+
;
; SPP_SWP_SPI_FLIGHT_GEO
;
; Purpose:
;
; Taken from SWP_TN_011 SPAN Optics.pdf
;
; SVN Properties
; --------------
; $LastChangedRevision: 28314 $
; $LastChangedDate: 2020-02-18 15:49:41 -0800 (Tue, 18 Feb 2020) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_geo.pro $
;
;-

PRO spp_swp_spi_flight_geo, geo

   ;;      UNITS
   ;; [cm^2 sr eV/eV]
   
   ;; SPAN-Ai Geometric Factor
   ;; 360 degrees, no grid/efficiency
   geo_tot = 0.00152

   ;; Grid Efficiencies
   ;; Five grids at 90%
   geo_grd = geo_tot * 0.9^5

   ;; MCP Efficiencies
   ;; e- on MCP at 70%
   geo_e_mcp = geo_grd * 0.7

   ;; From 360 to 247.5 degrees
   ;;geo_fov = geo_mcp * (247.5/360.)

   
   ;; Final result
   geo = 0.000304
   
END 
