; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/insert_gaps.pro $
; Created by: Davin Larson


pro insert_gaps,data,gapindices,baddata

if n_elements(baddata) eq 0 then baddata=fill_nan(data[0])

data0 = data[0]
data[0] = baddata

ndata = n_elements(data)
nbad = n_elements(gapindices)

if (nbad gt 0) and (gapindices[0] ge 0) then begin
   ind = indgen(ndata+nbad)
   ind[ndata:*] = gapindices
   ind = ind[sort(ind)]
   u = uniq(ind)
   b = replicate(1b,ndata+nbad)
   b[u] = 0
   w = where(b)
   ind[w] = 0
   data = data[ind]
   data[0] = data0
endif

return
end

