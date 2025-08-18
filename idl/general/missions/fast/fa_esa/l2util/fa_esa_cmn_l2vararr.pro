;+
;NAME:
; fa_esa_cmn_l2vararr
;PURPOSE:
; Returns an array with common block variable names for the input
; data_name.
;CALLING SEQUENCE:
; vars = fa_esa_cmn_l2vararr(data_name)
;INPUT:
; data_name = the data_name for the data type; It turns out that this
;             is unused since all of the L2 structures have the same
;             variables
;OUTPUT:
; vars = a 3, N array with common block variable names for the input
; data_name, with three columns, one is the common block name, the second is
; the name in the CDF file, the third is 'Y' or 'N' for record
; variance.
;HISTORY:
; 1-sep-2015, jmm, Hacked from mvn_sta_cmn_l2vararr
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-03-08 14:31:52 -0800 (Tue, 08 Mar 2016) $
; $LastChangedRevision: 20352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_cmn_l2vararr.pro $
;-
Function fa_esa_cmn_l2vararr, data_name

;Won't need data name
  dname = strlowcase(strcompress(/remove_all, data_name))

  vars = [['PROJECT_NAME', 'PROJECT_NAME', 'N'], $
          ['DATA_NAME', 'DATA_NAME', 'N'], $
          ['DATA_LEVEL', 'DATA_LEVEL', 'N'], $
          ['UNITS_NAME', 'UNITS_NAME', 'N'], $ 
          ['UNITS_PROCEDURE', 'UNITS_PROCEDURE', 'N'], $ 
          ['VALID', 'VALID', 'Y'], $
          ['DATA_QUALITY', 'DATA_QUALITY', 'Y'], $ 
          ['TIME', 'TIME_START', 'Y'], $
          ['END_TIME', 'TIME_END', 'Y'], $
          ['INTEG_T', 'TIME_INTEG', 'Y'], $
          ['DELTA_T', 'TIME_DELTA', 'Y'], $
          ['NBINS', 'NBINS', 'Y'], $
          ['NENERGY', 'NENERGY', 'Y'], $
          ['GEOM_FACTOR', 'GEOM_FACTOR', 'Y'], $
          ['GF_IND', 'GF_IND', 'Y'], $
          ['BINS_IND', 'BINS_IND', 'Y'], $
          ['MODE_IND', 'MODE_IND', 'Y'], $ 
          ['THETA_SHIFT', 'THETA_SHIFT', 'Y'], $
          ['THETA_MAX', 'THETA_MAX', 'Y'], $
          ['THETA_MIN', 'THETA_MIN', 'Y'], $
          ['BKG', 'BKG', 'Y'], $
          ['ENERGY', 'ENERGY', 'N'], $
          ['BINS', 'BINS', 'N'], $
          ['THETA', 'THETA', 'N'], $
          ['GF', 'GF', 'N'], $
          ['DENERGY', 'DENERGY', 'N'], $
          ['DTHETA', 'DTHETA', 'N'], $
          ['EFF', 'EFF', 'N'], $
          ['DEAD', 'DEAD', 'N'], $
          ['MASS', 'MASS', 'N'], $
          ['CHARGE', 'CHARGE', 'N'], $
          ['SC_POT', 'SC_POT', 'Y'], $
          ['BKG_ARR', 'BKG_ARR', 'N'], $
          ['HEADER_BYTES', 'HEADER_BYTES', 'Y'], $
          ['DATA', 'DATA', 'Y'], $
          ['EFLUX', 'EFLUX', 'Y'], $
          ['ENERGY_FULL', 'ENERGY_FULL', 'Y'], $
          ['DENERGY_FULL', 'DENERGY_FULL', 'Y'], $
          ['PITCH_ANGLE', 'PITCH_ANGLE', 'Y'], $
          ['DOMEGA', 'DOMEGA', 'Y'], $
          ['ORBIT_START', 'ORBIT_START', 'N'], $
          ['ORBIT_END', 'ORBIT_END', 'N']]
  Return, vars
End
