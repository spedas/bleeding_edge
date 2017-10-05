pro insert_gaps,data,gapindices,baddata

if n_elements(baddata) eq 0 then baddata=!values.f_nan

data0 = data[0]
data[0] = baddata

ndata = n_elements(data)
nbad = n_elements(gapindices)

if (nbad gt 0) and (gapindices[0] ge 0) then begin
   ind = indgen(ndata+nbad)
   ind(ndata:*) = gapindices
   ind = ind(sort(ind))
   u = uniq(ind)
   b = replicate(1b,ndata+nbad)
   b(u) = 0
   w = where(b)
   ind[w] = 0
   data = data[ind]
   data[0] = data0
endif

return
end

