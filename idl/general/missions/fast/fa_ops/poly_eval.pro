function poly_eval,t,c

n = n_elements(c)
nt = n_elements(t)
fit = fltarr(nt)

for i=n-1,0,-1 do begin
   fit = c(i)+fit*t
endfor

return,fit
end
