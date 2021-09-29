;+
;NAME: PSP_FLD_COMMON
;
;DESCRIPTION:
;  Common variables used in PSP/FIELDS/UTIL/MISC routines
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-11-03 08:57:10 -0800 (Tue, 03 Nov 2020) $
; $LastChangedRevision: 29319 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/misc/psp_fld_common.pro $
;-

common psp_fld_common, mag_dqf_infostring

mag_dqf_infostring = [ $
  "",$
  "There are 8 data quality flags in the psp_fld_l2_quality_flags variable",$
  "defined at the end of this message.",$
  "",$
  "To filter out flagged data call:",$
  "psp_fld_qf_filter, <tplot variable name or number>, <flag number>",$
  "",$
  "*Tplot variable name or number*",$
  "  Can be scalar or an array of values",$
  "",$
  "*Flag number*",$
  "  Can be scalar or an array of values from the flag definition list below,",$
  "  or 0 to show only data with no set flags.",$
  "",$  
  "  Can use flag of -1 to allow no flags except 128,",$
  "  --------------------------",$
  "Example: Keep only values with no data quality flag issues marked",$
  "         for the 'psp_fld_l2_mag_RTN_1min' variable",$
  "IDL> psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',0", $
  "",$
  "Example: Remove all values where flags 8 or 32 are marked",$
  "         for the 'psp_fld_l2_mag_RTN_1min' variable",$
  "IDL> psp_fld_qf_filter,'psp_fld_l2_mag_RTN_1min',[8,32]",$
  "",$
  "  --------------------------",$    
  "FIELDS quality flag definitions:",$
  "  1: FIELDS antenna bias sweep",$
  "  2: PSP thruster firing",$
  "  4: SCM Calibration",$
  "  8: PSP rotations for MAG calibration (MAG rolls)",$
  "  16: FIELDS MAG calibration sequence",$
  "  32: SWEAP SPC in electron mode",$
  "  64: PSP Solar limb sensor (SLS) test",$
  "  128: PSP spacecraft is off umbra pointing.",$
  "",$    
  "A value of zero corresponds to no set flags.",$ 
  "",$
  "Not all flags are relevant to all FIELDS data products,",$ 
  "refer to notes in the CDF metadata and on the FIELDS SOC website for",$ 
  "information on how the various flags impact FIELDS data. ",$
  "",$
  "These flag descriptions are current as of publicly available version 1 files",$
  "(named: psp_fld_l2_mag_*_v01.cdf)",$
  "Additional flagged items may be added in the future."$
]