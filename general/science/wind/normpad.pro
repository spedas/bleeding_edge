

pro normpad,names
if not keyword_set(names) then $ ; select names beginning with 'elpd-1' and without 'norm'
  names = strfilter(tnames('elpd-1-*'),'*norm',/neg,/str)
  


if ndimen(names) eq 0 then tn = str_sep(names,' ') else tn=names

n = n_elements(tn)

for i=0,n-1 do begin
   nam = tn[i]
   get_data,nam,data=d,alim=alim
   if keyword_set(d) then begin
   np = dimen2(d.y)
   avg = average(d.y,2,/nan)
   d.y = d.y /(avg # replicate(1.,np))
   zlim,alim,0,2,0
   store_data,nam+'_norm',data=d,dlim=alim
   endif
endfor


end
