;+
;
;PROCEDURE:       VEX_ASP_ELS_ENERGY
;
;PURPOSE:
;                 Returns the VEX/ASPERA-4 (ELS) energy table.
;
;INPUTS:          None.
;
;OUTPUTS:         Energy table by using LIST function.
;
;KEYWORDS:        None.
;
;NOTE:            See, Tables 4 & 5 from
;                 https://archives.esac.esa.int/psa/ftp/VENUS-EXPRESS/ASPERA4/VEX-V-SW-ASPERA-2-EXT4-ELS-V1.0/DOCUMENT/ELS_DATA_ANALYSIS_SUMMARY.PDF
;
;CREATED BY:      Takuya Hara on 2017-04-15 -> 2018-04-16.
;
;LAST MODIFICATION:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-01 12:18:09 -0800 (Thu, 01 Jan 2026) $
; $LastChangedRevision: 33943 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_energy.pro $
;
;-
PRO vex_asp_els_energy, energy
  ; k-factors
  a = FINDGEN(16)
  k = 10.518 + (0.0424 * a) + (0.0573 * (a^2)) - (0.00889 * (a^3)) + (0.000323 * (a^4))

  ene = list()
  FOR i=0, 1 DO BEGIN
     IF i EQ 0 THEN BEGIN
        tm = [16, 18, 19, 21, 23, 25, 27, 29, 32, 35, 38, 41, 45, 49, 53, 57, 62, 68, 74, 80, 87, 95, $
              103, 112, 121, 132, 143, 155, 169, 183, 199, 216, 235, 255, 277, 301, 327, 355, 385,    $
              419, 455, 494, 536, 582, 632, 687, 746, 810, 880, 955, 1037, 1127, 1223, 1329, 1443,    $
              1567, 1702, 1848, 2007, 2179, 2336, 2570, 2791, 3031, 3291, 3574, 3881, 31, 34, 37,     $
              40, 43, 47, 51, 56, 61, 66, 72, 78, 84, 92, 100, 108, 118, 128, 139, 151, 164, 178,     $
              193, 210, 228, 248, 269, 292, 317, 345, 374, 407, 442, 480, 521, 566, 614, 667, 724,    $
              787, 854, 928, 1008, 1094, 1188, 1291, 1402, 1522, 1653, 1795, 1949, 2117, 2299, 2496,  $
              2711, 2944, 3197, 3472, 3770, 4095]

        volts = FLTARR(N_ELEMENTS(tm))
        volts[0:66] = FLOAT(tm[0:66]) * (21.8/4095)   ; Low Range Reference Deflection Voltage
        volts[67:*] = FLOAT(tm[67:*]) * (2777.0/4095) ; High Range Reference Deflection Voltage
     ENDIF ELSE BEGIN
        tm = [151, 168, 188, 209, 234, 261, 291, 325, 363, 406, 453, 505, 564, 630, 703, 785, 877, 979, $
              1092, 1220, 1362, 1520, 1697, 1895, 2115, 2361, 2636, 2943, 3286, 3668, 4095]
        volts = FLOAT(tm) * (21.8/4095) ; Low Range Reference Deflection Voltage
     ENDELSE

     volts = REVERSE(volts)
     energy = (volts # k)

     ; Interpolating the lowest energy step
     ; This last energy step should be disregard for analyses.
     mene = MEAN(energy, dim=2)
     nene = N_ELEMENTS(mene)
     lene = 10^INTERP(ALOG10(mene), FINDGEN(nene), nene)

     lene = REPLICATE(lene, 16)
     energy = [energy, TRANSPOSE(lene)]
     energy = TRANSPOSE(energy)
     ene.add, TEMPORARY(energy)
  ENDFOR
  energy = ene
  RETURN
END 
