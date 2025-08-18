;New for 3.6

pro barrel_sp_testratio_mono,altitude,emono, emono_ratios
;let's get the hardness ratio/efolding thing by using the DRM:

spect=barrel_sp_make(numsrc=1,numbkg=2,/slow)
barrel_sp_make_drm, spect,altitude=altitude
drm = spect.drm
e=spect.ebins
edge_products,e,mean=mean,width=width
w1=where(mean GT 110. and mean LT 150.)
w2=where(mean GT 200. and mean LT 250.)
x=50.

for startpar=50.,2000.,20. do begin
    if startpar GT 50. then x=[x,startpar]
    diff = abs(mean-startpar)
    tryspecin = fltarr(n_elements(mean))
    tryspecin[(where(diff EQ min(diff)))[0]] = 1.
    tryspec = tryspecin#drm
    rat = total(tryspec[w2])/total(tryspec[w1])
    if startpar EQ 50. then rats=rat else rats=[rats,rat]
 endfor

for i=0,n_elements(x)-2 do begin
   if rats[i] gt 0 and i gt 0 then begin
      rats[0:i-1] = rats[i]*x[0:i-1]/x[i]
      break
   endif
endfor

emono=x
emono_ratios=rats

end
