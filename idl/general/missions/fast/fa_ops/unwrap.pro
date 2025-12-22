;       @(#)unwrap.pro	1.4     03/11/99
;+
; NAME: UNWRAP
;
; PURPOSE:
; This function unwraps things that have been modulo'd by x, (like the
; output from atan), and positions the first point between 0 and x. X
; is 2Pi by default.
; 
; INPUTS: PHASEC - an array of numbers, which may or may not have some
;         jumps in it, which need to be unwrapped.
;
; KEYWORD PARAMETERS: DIVISOR - the size of the current range of
;                     X. The default is 2Pi. 
;
; OUTPUTS: The return value is the unwrapped version of X. 
;
; EXAMPLE: big_long_line = unwrap(phase_angle)
;
; MODIFICATION HISTORY: Removed from FA_FIELDS_PHASE, 9-March-1998, by
;                       Bill Peria UCB/SSL. 
;
;-

function unwrap,phasec, DIVISOR = div

twopi = 2.d*!dpi
if not defined(div) then div = twopi 
maxjmp = div/2.0

fin = where(finite(phasec), nfin)
if nfin eq 0 then begin
    message,'No finite points',/continue
    return,phasec
endif

phase = phasec[fin]

nphase = n_elements(phase)
if nphase lt 2 then return,phase
dphase = phase(1L:nphase-1L)-phase(0L:nphase-2L)
ujumps = where(dphase gt maxjmp,nujumps)
djumps = where(dphase le -maxjmp,ndjumps)

while ((nujumps+ndjumps) gt 0) do begin
    phase(djumps(0)+1L:nphase-1L) = $
      phase(djumps(0)+1L:nphase-1L)+div 
    phase(ujumps(0)+1L:nphase-1L) = $
      phase(ujumps(0)+1L:nphase-1L)-div
    dphase = phase(1L:nphase-1L)-phase(0L:nphase-2L)
    ujumps = where(dphase gt maxjmp,nujumps)
    djumps = where(dphase le -maxjmp,ndjumps)
endwhile

oops = double(long(phase(0)/div))*div
phase = phase - oops
while phase(0) lt 0 do begin
    phase = phase + div
endwhile

phasec[fin] = phase
return,phasec
end
