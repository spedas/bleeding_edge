;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2019-08-01 13:38:27 -0700 (Thu, 01 Aug 2019) $
;  $LastChangedRevision: 27529 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_get_bp_bins_04_dc.pro $
;

function SPP_Get_BP_bins_04_DC

  top_sample_rate = 18750d

  freq_hi = top_sample_rate / 2d / (2LL^(indgen(15))); * 0.8d ;; 80% to account for filter roll-off
  freq_lo = top_sample_rate / 4d / (2LL^(indgen(15))); * 0.8d

  freq_avg = (freq_hi + freq_lo) / 2d

  return_struct = {freq_lo:freq_lo, $
    freq_hi:freq_hi, $
    freq_avg:freq_avg}


  return, return_struct


  ;;THE
END

