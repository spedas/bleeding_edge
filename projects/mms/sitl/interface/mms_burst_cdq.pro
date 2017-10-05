;+
; FUNCTION: MMS_BURST_CDQ, TDN, WEIGHT, OFFSET, NEGATIVE=NEGATIVE
;
; PURPOSE: Calculates CDQ from TDNs using weight and offset tables.
;
; INPUT:
;   TDN              - REQUIRED. Npts by Ntdq array of TDN values. 
;   WEIGHT           - REQUIRED. Weights for TDQ values. Ntdq elements.
;                      RECOMMEND that WEIGHT totals to 1.
;   OFFSET           - REQUIRED. Offsets for TDQ values. Ntdq elements.
;
; CAUTION!             Npts and Ntdq determined from TDN array. WEIGHT and
;                      OFFSET must have Ntdq elements or program exits.
;
; KEYWORDS:
;   NEGATIVE         - OPTIONAL. If set, TDN-WEIGHT and be less than zero.
;
; OUTPUT: A floating-point array of CDQ values, Npts elements.
;
; INITIAL VERSION: REE 2011-02-15
; LASP, University of Colorado
;
; MODIFICATION HISTORY:
;
;-

function mms_burst_cdq, TDN, WEIGHT, OFFSET, NEGATIVE=NEGATIVE

;NOTE
; result (= size(TDN)) is a vector.
; The first element is the number of dimensions. zero if scalar
; The next elements contain the size of each dimension, one element per dim.

;CHECK TDN INPUT
CDQ = 0
sz = size(TDN)
if sz(0) NE 2 then return, CDQ; TDN must be a 2D array

; ASSIGN Npts and Ntdq
Npts = sz(1); the size of the first dimension
Ntdq = sz(2); the size of the second dimension

; CHECK WEIGHT AND OFFSET
sz = size(weight)
if (sz(0) NE 1) OR (sz(1) NE Ntdq) then return, CDQ
sz = size(offset)
if (sz(0) NE 1) OR (sz(1) NE Ntdq) then return, CDQ

; SET MIN
low = 0.0
if keyword_set(negative) then low = min(TDN) - max(offset)

; CALCULATION
CDQ = fltarr(Npts)
for i=0L, Npts-1 do CDQ(i) = total( ( (TDN(i,*) - offset) > low) * weight)

return, CDQ
end






