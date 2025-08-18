;+
;
; ESC_IESA_FM1_SCI
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 31963 $
; $LastChangedDate: 2023-07-21 12:05:49 -0700 (Fri, 21 Jul 2023) $
; $LastChangedBy: rlivi04 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_fm1_sci.pro $
;
;-

PRO esc_iesa_fm1_sci, tbl

   ;; ESCAPADE iESA K Factor
   k = 7.8
   ;; Telemetry Rate
   clock = 16.7e6               ;; 16.7 [MHz] 2^24
   ;; Definition of Second
   ss = 1/clock * 'FFFFFF'x    ;; 1.004 [s] 
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

   ;; Mass Array of 64 DAC boundaries 
   hv_dac = ishft(lindgen(64L),10)

   ;; DAC to V
   hv = (1.*hv_dac)^2 / (1.*'ffff'x)^2 * 4. * 1000.

   ;; Total Particle Energy [eV]
   ev = hv * k + 15000.

   ;; Time intervals of steps
   tim_ustep = ss / (512/8.)
   
   ;; Structure
   tbl = {clock:clock,$
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
