;+
;NAME: PSP_COMMON_SPC_INFO
;
;DESCRIPTION:
;  Common variables used in PSP/SWEAP/SPC routines 
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/misc/psp_common_spc_flaginfo.pro $
;-

common psp_common_spc_info, spc_dqf_infostring


spc_dqf_infostring = [ $
 "",$
 "There are 32 data quality flags in the psp_spc_DQF variable,",$
 "defined at the end of this message.",$
 "",$
 "Internally, each type of flag is encoded as follows:",$
 "  --------------------------",$
 "  = 0,   good/nominal/condition not present/etc",$
 "  > 1,  bad/problematic/condition present/etc",$
 "  = -1,  status not determined (don't know)",$
 "  < -1,  status does not matter (don't care)",$
 "",$
 "  -1 (don't know) is the default value for all flags.",$
 "",$
 "  The 0th flag array element is the [standardized] global quality flag,",$
 "  signifying whether the data are suitable for use without caveate. ",$
 "",$
 "  --------------------------",$
 "To filter out flagged data call psp_filter_swp with",$
 "<tplot variable name or number>,<flag number>,status=<status code>",$
 "",$
 "*Status code*",$
 "  Is a generalization of the flag encodings described above.",$
 "  From the set {1, 2, 3}. Indicates which flag statuses will be removed.  ",$
 "  (default = 3)",$
 "     1: Remove only where the flag is explicitly marked as having",$
 "         bad/problematic/condition present/etc",$
 "     2: Remove (1) AND where status not determined (don't know)",$
 "     3: Remove all EXCEPT where explicitly marked as",$
 "         good/nominal/condition not present/etc for all selected flags",$
 "       ",$
 "*Tplot variable name or number*",$
 "  Can be scalar or an array of values",$
 "",$
 "*Flag number*",$
 "  Can be scalar or an array of values from the flag definition list below",$
 "",$
"  --------------------------",$
 "Example: Keep only values explicitly marked as good in the general flag",$
 "         for the 'psp_spc_np_fit' variable",$
 "IDL> psp_filter_swp,'psp_spc_np_fit',0,status=3",$
 "",$
 "Example: Remove all values where flags 11 or 12 are explicitly marked as bad",$
 "         for the 'psp_spc_np_fit' variable",$
 "IDL> psp_filter_swp,'psp_spc_np_fit',[11,12],status=1",$
 "",$
 "  --------------------------",$
 "FLAG DEFINITONS:",$
 " 0: general flag",$
 " 1: primary peak low signal",$
 " 2: no primary peak detected",$
 " 3: cold primary peak or current spike detected",$
 " 4: sensor saturated",$
 " 5: primary peak not bound",$
 " 6: poor Maxwellian fit to primary peak",$
 " 7: flow direction poorly constrained or undetermined",$
 " 8: alpha peak low signal / not identified",$
 " 9: poor Maxwellian fit to alpha peak",$
 " 10: alpha peak not bound",$
 " 11: wind speed off scale high",$
 " 12: wind speed off scale low",$
 " 13: wind speed off scale unknown",$
 " 14: likely proton alpha confusion",$
 " 15: unusually high noise levels detected",$
 " 16: proton full-scan mode (not peak-tracked)",$
 " 17: reduced data quality: anomalous periodic noise type A,(>1 Hz)",$
 " 18: reduced data quality: anomalous periodic noise type B,(< 1Hz)",$
 " 19: temperature/survival heater cycling: potential fluctuations",$
 " 20: reduced data quality: broadband or other anomalous noise (type C)",$
 " 21: fragmented or incomplete spectrum measured",$
 " 22: energy ranging/peak tracking error",$
 " 23: spacecraft maneuver",$
 " 24-31: not used",$
 " ",$
 "These flag descriptions are current as of publicly available version 1 files ",$
 "(named: psp_swp_spc_l3i_YYYYMMDD_v01.cdf)",$ 
 "Please refer to CDF metadata to confirm flag meaning for any later file ",$
 "versions."$
 ]