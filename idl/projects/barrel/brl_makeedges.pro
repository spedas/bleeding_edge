;+  construct energy edges for spectrum products
;
; INPUT: all inputs through keywords
;
; KEYWORD: keyword parameters
;        flightID=flightID      2 char identifier (e.g., '1S')
;        dpu_temp=dpu_temp      dpu temperature in C
;        xtal_temp=xtal_temp    scintillator temperature in C
;        peak511=peak511        sspc location for 511keV; 200
;                               nominal; 0<peak511<4095 
;            
; OUTPUT: 3 lists of bin edges are populated with energy values
;        slo is a fltarr(257)
;        med is a fltarr(49)
;        fst is a fltarr(5)
;        For these 3 lists, each pair of edges brackets one of the
;          256/48/4 spectrum bins. Energy units are keV.
;        Energy values below 0 are forced to 0, so it is
;        possible for multiple low-end slo bins to have 0
;        energy. Counts in these bins should be ignored.
;
; METHOD: invert an empirical model of bin(Energy). The model
;        is bin(E) = k*(offset + gain*E + nonlin*E*Log(E))
;        where offset, gain, and nonlin are linear functions
;        of DPU temperature, and k is a quadratic function
;        of crystal temperature. The dpu
;        temperature-dependent linear functions use coefficients
;        extracted from thermal chamber data, and are
;        retrieved via a function call. Because the coupling
;        between scintillator and crystal can change with air
;        pressure, the peak511 parameter should be used to
;        improve the model for flight data.
;
;        default values for missing options are probably not
;        sufficiently accurate
;
;
; CALLS: brl_dpucoeffs(flightID) returns temperature model
;                coefficients for associated dpu hardware.
;        brl_binvert(start,f) inverts bin(energy) function;
;                needs a start value and factor f
;
; REVISION HISTORY:
;	works, tested mm/Oct 2012
;       25Nov2012: added temperature compensation and
;                  corrections for crystal nonlinearity
;       14Sep2013: re-parameterized & re-built bin-energy model
;
;-
function brl_makeedges, $
  flightID=flightID, xtal_temp=xtal_temp, $
  dpu_temp=dpu_temp, peak511=peak511

;
; initialize the uncalibrated bin edges
;
  fst = [0., 75, 230, 350, 620]
  med = [42., 46, 50, 53, 57, 60, 64, 70, 78, 84, 92, 100, $
    106, 114, 120, 128, 140, 156, 168, 184, 200, 212, 228, $
    240, 256, 280, 312, 336, 368, 400, 424, 456, 480, 512, $
    560, 624, 672, 736, 800, 848, 912, 960, 1024, 1120, $
    1248, 1344, 1472, 1600, 1696]
  slo=[0., 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, $
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, $
    30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, $
    44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, $
    58, 59, 60, 61, 62, 63, 64, 66, 68, 70, 72, 74, 76, 78, $
    80, 82, 84, 86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, $
    108, 110, 112, 114, 116, 118, 120, 122, 124, 126, 128, 132, $
    136, 140, 144, 148, 152, 156, 160, 164, 168, 172, 176, $
    180, 184, 188, 192, 196, 200, 204, 208, 212, 216, 220, $
    224, 228, 232, 236, 240, 244, 248, 252, 256, 264, 272, $
    280, 288, 296, 304, 312, 320, 328, 336, 344, 352, 360, $
    368, 376, 384, 392, 400, 408, 416, 424, 432, 440, 448, $
    456, 464, 472, 480, 488, 496, 504, 512, 528, 544, 560, $
    576, 592, 608, 624, 640, 656, 672, 688, 704, 720, 736, $
    752, 768, 784, 800, 816, 832, 848, 864, 880, 896, 912, $
    928, 944, 960, 976, 992, 1008, 1024, 1056, 1088, 1120, $
    1152, 1184, 1216, 1248, 1280, 1312, 1344, 1376, 1408, $
    1440, 1472, 1504, 1536, 1568, 1600, 1632, 1664, 1696, $
    1728, 1760, 1792, 1824, 1856, 1888, 1920, 1952, 1984, $
    2016, 2048, 2112, 2176, 2240, 2304, 2368, 2432, 2496, $
    2560, 2624, 2688, 2752, 2816, 2880, 2944, 3008, 3072, $
    3136, 3200, 3264, 3328, 3392, 3456, 3520, 3584, 3648, $
    3712, 3776, 3840, 3904, 3968, 4032, 4096]

;
; set model parameters
;
  if (not keyword_set(xtal_temp)) then $
    xtal_temp=0
  if (not keyword_set(dpu_temp)) then $
    dpu_temp=0
  if (not keyword_set(flightID)) then $
    flightID='XX'

  constants = brl_dpucoeffs(flightID)
  xtal_compensate = 1.022 - 1.0574e-4 * (xtal_temp-10.7)^2
  dpu_compensate = [1.,dpu_temp]#constants
  factor = dpu_compensate[2]/dpu_compensate[1]
;
; calculate a correction from 511keV location
;
  if (keyword_set(peak511)) then begin
      start=(peak511/xtal_compensate-dpu_compensate[0])/dpu_compensate[1]
      fac511 = 511. / brl_binvert(start,factor)
  endif else $
      fac511 = 1.
;
; calculate energies for the 3 spectral products
;
  start = (slo/xtal_compensate - dpu_compensate[0])/dpu_compensate[1]
  slo = fac511 * brl_binvert(start,factor)

  start = (med/xtal_compensate - dpu_compensate[0])/dpu_compensate[1]
  med = fac511 * brl_binvert(start,factor)

  start = (fst/xtal_compensate - dpu_compensate[0])/dpu_compensate[1]
  fst = fac511 * brl_binvert(start,factor)

  return,{slo:slo, med:med, fst:fst}
end
