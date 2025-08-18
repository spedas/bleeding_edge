;+
;FUNCTION: THM_LSP_MEDIAN_SMOOTH, x, nsmooth
;
;           NOT FOR GENERAL USE. CALLED BY THM_EFI...
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;PURPOSE:
;    Smooth data with median rather than average - removes spikes.
;
;INPUT:
;    x             -NEEDED. Array
;    nsmooth       -OPTIONAL. Number of points in smoothing. DEFAULT = 11
;                  -MUST BE ODD.
;
;KEYWORDS:
;
;HISTORY:
;   2009-04-28: REE. 
;-

function thm_lsp_median_smooth, x, nsmooth

; CHECK NS
if not keyword_set(nsmooth) then ns = 11 else ns = nsmooth
if ((ns mod 2) EQ 0) then ns = ns + 1
nh = (ns-1)/2

; GET READY FOR LOOP
nx_ = n_elements(x) - 1
xx = x

; LOOP
for i = 0L, nx_ do xx(i) = median(x( ((i-nh)>0) : ((i+nh)<nx_) ))

return, xx
end
