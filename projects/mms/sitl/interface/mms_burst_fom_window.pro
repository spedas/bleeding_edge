;+
; FUNCTION: MMS_BURST_FOM_WINDOW, WSIZE, SLOPE, SKEW, BIAS
;
; PURPOSE: Creates a window for sort_convol.
;
; INPUT:
;   WSize            - REQUIRED. The size (in number of 10s buffers) of the 
;                      window. 
;                      DEFAULT: SearchWindowSize = MinSegemntSize
;
;   Slope            - REQUIRED. A value between 0 and infinity.
;                      0 gives flat window (for averaging).;
;                      100 gives a step function.
;
;   Skew             - REQUIRED. A value between 0 and 1.
;                      0 gives flat window (for averaging).
;                      1 favors finding spikes. 
;
;   Bias            -  REQUIRED. Skew bias. A value between 0 and 1.
;                      0 favors short segments.
;                      1 favors long segments.
;
;                      NOTE: Set SLOPE and POSITION higher to
;                      favor a spike. Set lower to favor a straight average.
;
; CAUTION!             NO INPUT CHECKING WITHIN FUNCTION! All inputs must
;                      be valid.
;
; KEYWORDS:
;;
; OUTPUT: A flaoting-point array of WSIZE values.
;
; INITIAL VERSION: REE 2010-11-02
; LASP, University of Colorado
;
; MODIFICATION HISTORY:
;
;-

function mms_burst_fom_window, wsize, slope, skew, bias

; CHECK INPUTS
slope  = float(slope) > 0.0
skew   = (float(skew) < 1.0) > 0.0
bias   = (float(bias) < 1.0) > 0.0

; CREATE WINDOW
wslope = slope/wsize
position = skew + (1.0-skew)*(bias-0.5) * (2.0 - 2.0/sqrt(wsize))
out = ( tanh( (findgen(wsize) - position * float(wsize-1) ) * wslope) + 1)/2
return, out/total(out)
END

