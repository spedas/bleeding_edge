function rotate_tensor,tens,rot
;Purpose:  rotate an nth rank tensor in 3 dimensions.
;caveats:  Not well tested. tensor should probably be symmetric.
;   all dimensions are typically 3 in 3 space
;Author:  Davin Larson

rank = ndimen(tens)
if rank le 0 then return,tens
if rank eq 1 then return,transpose(rot ## tens)

dim = dimen(tens)   ; all elements should be the same
d   = dim[0]        ; typically 3 (3 dimensions)
ns  = d^(rank-1)
ind = shift(indgen(rank),1)

rtens = tens
for i = 0,rank-1 do begin
   rtens = reform(rot ## reform(rtens,ns,d),dim)
   rtens = transpose(rtens,ind)
endfor
return,rtens

end


