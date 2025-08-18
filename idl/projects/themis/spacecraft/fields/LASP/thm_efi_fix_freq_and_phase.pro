;+
; FUNCTION: THM_EFI_FIX_FREQ_AND_PAHSE, E, freq=freq, ghf=ghf, dt=dt, axial=axial
;
; PURPOSE: A routine which integrates data to fix the gain and remove the
;          phase shift due to resistive to capacitive crossover of the  
;          THEMIS preamps. ONLY USEFUL FOR BURST DATA.
;
; INPUT: 
;       data -        REQUIRED. Data to be fixed. DEFAULT = SPIN PLANE
;
; KEYWORDS: 
;       axial -       OPTIONAL. Changes freq and gh to AXIAL default values.
;       freq -        OPTIONAL. Crossover frequency in HZ. DEFAULT = SPIN PLANE
;                     Careful! Derived from Rsheath(Csheath+Cin)
;       ghf -         OPTIONAL. Gain at high frequency. DEFAULT = SPIN PLANE
;                     Csheath/(Csheath+Cin)
;       dt -          OPTIONAL. Time between samples (s). DEFAULT = 1/8192
;
; CALLING: Esp = thm_efi_fix_freq_and_phase(Esp) or 
;          Eax = thm_efi_fix_freq_and_phase(Ex, /ax)
;
; OUTPUT: Data is integrated to remove gain/phase error from preamp RC 
;         crossover.
;
; NOTE ON DEFAULTS: Spin Plane: The front-end network, R=100k, C = 10pF is  
;    ignored. Instead, I fudge Csh = 14 pF  and Cin = 11.5 pF to realize a close 
;    approximation of measured gain/phase (see Bonnell et al. paper).
;    Axial: Same system. I use Csh = 4 pf, Cin = 13 pF to approximate. 
;    One could improve the calculation with 2 poles, but the location of Cin
;    (before or after the input network) would need to be questioned.
;    Rsh is assumed to be 20 MOhm
;        
; BEHAVIOR: 
;    (1) USE /AX for AXIAL SIGNALS!!!
;    (2) DATA AT BEGINNING OF AN ARRAY MAY NOT BE CORRECTED. 
;    Use large arrays if possible. The program relaxes by one
;    e-fold every 3 ms. 
;    (3) Electric field is improved for all plasma conditions. However, 
;    PHASE/GAIN CORRECTION MAY NOT BE ENOUGH FOR ALL PLASMA CONDITIONS.
;    (4) PROBES MUST BE IN SUNLIGHT!
;    (5) ONLY USEFUL FOR BURST DATA!
;    (6) BE SURE TO SET DT = 1/16384 FOR AC BURST!!!
;
; INITIAL VERSION: REE 08-08-26
; MODIFICATION HISTORY: 
; LASP, CU
; 
;-

function thm_efi_fix_freq_and_phase, E, freq=freq, ghf=ghf, dt=dt, axial=axial

; SPIN PLANE
Csh  = 14.0e-12 ; F (Fudged to account for missing RC network)
Cin  = 11.5e-12 ; F (Fudged to account for missing RC network)
Rsh  = 20.0e6   ; Ohm

; AXIAL 
IF keyword_set(axial) then BEGIN
  Csh  = 4.0e-12 ; F
  Cin  = 13.0e-12 ; F
  Rsh  = 20.0e6   ; Ohm
ENDIF

; SET DT, FREQ, AND GHF
if not keyword_set(freq) then freq = 1.0/(2.0*!pi*Rsh*(Csh+Cin))
if not keyword_set(ghf)  then ghf  = Csh/(Csh+Cin)
if not keyword_set(dt)   then dt   = 1.0/8192.0

; CALCULATE FORWARD FILTER COEFFICIENTS
a0 = (freq * dt * 5.5) < 1.d
a1 = (1.d - a0)

; FORWARD FILTER PROVIDED FOR TESTING PURPOSE
;x = E
;for i=1l, n_elements(x)-1 do x[i] = E[i]*a0 + x[i-1]*a1
;x = x+ghf*(E-x)
; ABOVE FILTER MIMICS GAIN/PHASE OF RC CROSSOVER

; REVERSE COEFFICIENTS
cnst0 = 1.0-ghf + ghf/a0
x0    = 1.0/a0/cnst0
x1    = -a1/a0/cnst0
x2    = a1*ghf/a0/cnst0

; REVERSE FILTER
R = E                     ; RECONSTRUCTED SIGNAL
for i=1l, n_elements(R)-1 do R(i) = E(i)*x0 + E(i-1)*x1 + R(i-1)*x2

; ALL DONE
return, R
end
            
 
