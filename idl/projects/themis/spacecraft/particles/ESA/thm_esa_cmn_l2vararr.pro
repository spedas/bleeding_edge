;+
;NAME:
; thm_esa_cmn_l2vararr
;PURPOSE:
; Returns an array with common block variable names for the input
; data_name.
;CALLING SEQUENCE:
; vars = thm_esa_cmn_l2vararr(data_name)
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
; 24-Oct-2022, jmm, Hacked from fa_esa_cmn_l2vararr
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-10-30 16:00:06 -0700 (Mon, 30 Oct 2023) $
; $LastChangedRevision: 32212 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_cmn_l2vararr.pro $
;-
Function thm_esa_cmn_l2vararr, data_name

;Won't need data name
  dname = strlowcase(strcompress(/remove_all, data_name))

  vars = [['PROJECT_NAME', 'PROJECT_NAME', 'N'], $
          ['SPACECRAFT', 'SPACECRAFT', 'N'], $
          ['DATA_NAME', 'DATA_NAME', 'N'], $
          ['APID', 'APID', 'N'], $
          ['DATA_LEVEL', 'DATA_LEVEL', 'N'], $
          ['UNITS_NAME', 'UNITS_NAME', 'N'], $ 
          ['UNITS_PROCEDURE', 'UNITS_PROCEDURE', 'N'], $ 
          ['VALID', 'VALID', 'Y'], $
          ['TIME', 'TIME', 'Y'], $
          ['END_TIME', 'END_TIME', 'Y'], $
          ['INTEG_T', 'INTEG_T', 'Y'], $
          ['DELTA_T', 'DELTA_T', 'Y'], $
          ['DT_ARR', 'DT_ARR', 'N'], $
          ['CS_PTR', 'CS_PTR', 'Y'], $
          ['CS_IND', 'CS_IND', 'Y'], $
          ['CONFIG1', 'CONFIG1', 'Y'], $
          ['CONFIG2', 'CONFIG2', 'Y'], $
          ['AN_IND', 'AN_IND', 'Y'], $
          ['EN_IND', 'EN_IND', 'Y'], $
          ['MD_IND', 'MD_IND', 'Y'], $
          ['NENERGY', 'NENERGY', 'N'], $
          ['ENERGY', 'ENERGY', 'N'], $
          ['DENERGY', 'DENERGY', 'N'], $
          ['NBINS', 'NBINS', 'N'], $
          ['THETA', 'THETA', 'N'], $
          ['DTHETA', 'DTHETA', 'N'], $
          ['PHI', 'PHI', 'N'], $
          ['DPHI', 'DPHI', 'N'], $
          ['PHI_OFFSET', 'PHI_OFFSET', 'Y'], $
          ['DOMEGA', 'DOMEGA', 'N'], $
          ['GF', 'GF', 'N'], $
          ['AN_MAP', 'AN_MAP', 'N'], $
          ['ECLIPSE_DPHI', 'ECLIPSE_DPHI', 'Y'], $
          ['REL_GF', 'REL_GF', 'Y'], $
          ['AN_EFF', 'AN_EFF', 'N'], $
          ['EN_EFF', 'EN_EFF', 'N'], $
          ['AN_EN_EFF', 'AN_EN_EFF', 'N'], $
          ['GEOM_FACTOR', 'GEOM_FACTOR', 'N'], $
          ['DEAD', 'DEAD', 'N'], $
          ['MASS', 'MASS', 'N'], $
          ['CHARGE', 'CHARGE', 'N'], $
          ['SC_POT', 'SC_POT', 'Y'], $ ;Not included, so will be needed to be input later
          ['MAGF', 'MAGF', 'Y'], $
          ['BKG_PSE', 'BKG_PSE', 'Y'], $
          ['BKG_PEI', 'BKG_PEI', 'Y'], $
          ['BKG_PEE', 'BKG_PEE', 'Y'], $
          ['BKG', 'BKG', 'Y'], $
          ['BKG_ARR', 'BKG_ARR', 'N'], $
          ['BINS', 'BINS', 'Y'], $
          ['EFF', 'EFF', 'Y'], $
          ['EFLUX', 'EFLUX', 'Y'], $
          ['NENERGY_MODES', 'NENERGY_MODES', 'N'], $
          ['NBIN_MODES', 'NBIN_MODES', 'N'], $
          ['DATA_QUALITY', 'DATA_QUALITY', 'Y']]

  Return, vars
End
