;+
;
; SPP_SWP_SPI_FLIGHT_SCI
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 28315 $
; $LastChangedDate: 2020-02-18 15:49:56 -0800 (Tue, 18 Feb 2020) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_flight_sci.pro $
;
;-

PRO spp_swp_spi_flight_sci, dac, tbl

   ;; Telemetry Rate
   clock = 19.2e6               ;; 19.2 [MHz]
   ;; New York Second
   nys = 1/clock * 'FFFFFF'x    ;; 0.87381327 [s] 
   ;; Electron Mass [kg]
   mass_e_kg = 9.10938356e-31
   ;; Electron Mass             (to get grams multiply by 1.6e-22.)
   mass_e = 5.68566e-06         ;; [ev/c2] where c = 299792 [km/s]  
   ;; Proton Mass [kg]
   mass_p_kg = 1.6726219e-27
   ;; Proton Mass               (to get grams multiply by 1.6e-22.)
   mass_p = 0.0104389           ;; [ev/c2] where c = 299792 [km/s]  
   ;; Speed of light
   cc = 299792458d              ;; [m s-1]
   ;; 1 Electronvolt to Joule
   evtoj = 1.602176565e-19      ;; [J] = [kg m2 s-2]
   ;; Boltzmann Constant
   kk = 1.38064852e-23          ;; [m2 kg s-2 K-1]
   ;; 1 AMU to kg
   atokg = 1.66054e-27
   ;; Mass Array of 128 DAC boundaries 
   hv_dac = ishft(lindgen(128L),9)
   ;; DAC to V
   hv = -1*(dac.hemi_fitt[0] + $
            hv_dac*dac.hemi_fitt[1])
   ;; Total Particle Energy [eV]
   ev = hv * 16.7 + 15000.
   ;; Time intervals of steps
   tim_ustep = nys / 4D / 256D
   
   ;; Structure
   tbl = {clock:clock,$
          nys:nys,$
          mass_e:mass_e,$
          mass_e_kg:mass_e_kg,$
          mass_p:mass_p,$
          mass_p_kg:mass_p_kg,$
          hv_dac:hv_dac,$
          hv:hv,$
          ev:ev,$
          cc:cc,$
          evtoj:evtoj,$
          kk:kk,$
          tim_ustep:tim_ustep,$
          atokg:atokg}

END
