;+
; PROCEDURE:
;         mms_hpca_energies
;
; PURPOSE:
;         Returns the hard-coded energy table; this is only used when
;         the energy table is missing from the CDF (either not there, or
;         all 0s)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-04-13 15:23:28 -0700 (Wed, 13 Apr 2016) $
;$LastChangedRevision: 20808 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_hpca_energies.pro $
;-
function mms_hpca_energies
  return, [1.35500, 1.57180, 1.84280, 2.22220, 2.60160, 3.08940, 3.63140, 4.28180, $
    5.04060, 5.96200, 6.99180, 8.23840, 9.75600, 11.4904, 13.5500, 15.9890, $
    18.8616, 22.2762, 26.2328, 30.9482, 36.5308, 43.0890, 50.7854, 59.9452, $
    70.6768, 83.4138, 98.3730, 116.042, 136.855, 161.462, 190.459, 224.659, $
    264.984, 312.571, 368.723, 434.955, 513.057, 605.197, 713.868, 842.051, $
    993.323, 1171.70, 1382.10, 1630.28, 1923.07, 2268.43, 2675.80, 3156.28, $
    3723.11, 4391.72, 5180.44, 6110.72, 7208.11, 8502.57, 10029.5, 11830.6, $
    13955.2, 16461.4, 19417.5, 22904.6, 27017.9, 31869.8, 37593.1]
end