;+
; NAME: FRAC_INDICES
;
; PURPOSE: to obtain the fractional indices of one array relative to
;          another. This function would usually precede a call to
;          IDL's INTERPOLATE. 
;
; CALLING SEQUENCE: new_indices = frac_indices(my_times, data_times)
; 
; INPUTS: MY_TIMES: an array of values for which the fractional
;         indices, with respect to DATA_TIMES, will be returned. 
;	
; OUTPUTS: The fractional indices! For example, note that
;          print,frac_indices([5,15],[0,10,30]), produces the output
;               0.50000000      1.2500000, and that in general the
;               function call:
;                  interpolate(x,frac_indices(y,x))  reproduces y. 
;
; RESTRICTIONS: Inputs must be one-dimensional arrays of a type that
;               can be sorted monotonically, i.e. no complex. 
;
; MODIFICATION HISTORY: Written 1 August 1996 by Bill Peria UCBerkeley
;                       Space Sciences Laboratory. 
;
;-
function frac_indices,ff,ww
;
; check to see if inputs make any sense...must be 1-D and sortable...
;
sff = size(ff)
sww = size(ww)
ok_types = [1,2,3,4,5]
if not (((where(ok_types eq sff(sff(0)+1)))(0) gt 0) and  $
        ((where(ok_types eq sww(sww(0)+1)))(0) gt 0) and  $
        (sff(0) eq 1) and $
        (sww(0) eq 1)) then begin
    message,'Improper arguments, can''t do fractional ' + $
      'indices...',/continue
    return,-1
endif

nff = n_elements(ff)
frac = dblarr(nff)
nww = n_elements(ww)




;lump = [ff,ww]                  ; concatenate (lump) fractional and whole number arrays
;ord = sort(lump)                ; keep track of order indices
;slump = lump(ord)               ; make sorted lumped array
;nslump = n_elements(slump)
;
; deal with ends...fractional indices for times less than first whole
; number time are zero; similarly at the other end...
;
tstart = min(ww)
tstop = max(ww)
early = where(ff le tstart,nearly)
late = where(ff ge tstop,nlate)
in_range = select_range(ff,tstart,tstop,nin_range)
indices = fltarr(nff)

if nin_range gt 0 then begin
        indices(in_range) = interp(lindgen(nww),ww,ff(in_range))
endif
if nearly gt 0 then begin
    indices(early) = 0.0
endif
if nlate gt 0 then begin
    indices(late) = float(nww)-1.
endif

return,indices


fpick = where(ord lt nff)       ; indices of fractional array in lumped array
wpick = where(ord ge nff)       ; indices of whole number array in lumped array
pnn = fpick - 1L                ; previous near-neighbors of elements
                                ; from fractional array.
if nearly gt 0 then pnn(early) = 0
;
; check for cases where previous near-neighbor is from fractional
; array also, and decrement pnn for those, also check for NAN's. 
;
repeat begin
    pairs = where((ord(pnn) lt nff) and (pnn gt 0),npairs)
    if (npairs gt 0) then begin
        pnn(pairs) = pnn(pairs) - 1L
    endif
endrep until (npairs eq 0)
neg = where(pnn lt 0,nneg)
if (nneg gt 0) then begin
    pnn(neg) = 0L
endif
;
; now do the same for next near-neighbors...
;
nnn = fpick + 1L
if (nlate gt 0) then nnn(late) = nslump - 1L
repeat begin
    pairs = where((ord(nnn) lt nff) and (nnn lt nslump), npairs)
    if (npairs gt 0) then begin
        nnn(pairs) = nnn(pairs) + 1L
    endif
endrep until (npairs eq 0)
too_big = where(nnn ge nslump,ntb)
;
; now have indices in slump of near neighbor times to ff, so we can
; interpolate the indices of ff. 
; 
i0 = double(ord(pnn)-nff)
i2 = double(ord(nnn)-nff)
i1 = dblarr(nff)
t0 = slump(pnn)
t1 = slump(fpick)
t2 = slump(nnn)

iequal = where(t2 eq t0, nequal)
inequal = where(t2 ne t0, nnequal)

if (nequal gt 0)  then begin
    i1(iequal) = i0(iequal)
endif
if (nnequal gt 0) then begin
    i1(inequal) = (i0(inequal)*(t2(inequal)-t1(inequal)) + $
                  i2(inequal)*(t1(inequal)-t0(inequal)))/(t2(inequal)-t0(inequal)) 
endif

if ntb gt 0 then i1(too_big) = nww-1L
if nneg gt 0 then i1(neg) = 0L

return,i1

bomb:return,-1

end



