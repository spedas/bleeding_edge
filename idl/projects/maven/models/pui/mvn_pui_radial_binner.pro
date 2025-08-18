;20180105 Ali
;bins model-data comparisons in log scaled radial distance
;takes in stuff vs r (m) and spits out binned stuff vs binned r (km)

pro mvn_pui_radial_binner,r,n,r2,n2,std,ste

  nosteps=150
  nocounter=replicate(0.,nosteps) ;binning counter
  nologbin1=replicate(0.,nosteps) ;ln densities binned
  nologbin2=replicate(0.,nosteps) ;ln square densities binned

  for i=0,n_elements(r)-1 do begin
    ;  rstep=floor(r[i]/2e6) ;radial distance step (2000 km)
    if ~finite(r[i]) or ~finite(n[i]) or r[i] eq 0. or n[i] eq 0. then continue
    rstep=floor(10.*alog(r[i]/1e3)) ;log radial distance step
    nocounter[rstep]+=1
    nologbin1[rstep]+=alog(n[i])
    nologbin2[rstep]+=(alog(n[i]))^2
  endfor

  rmars=3400. ;mars radius (km)
  ;roavg=(.5+dindgen(nosteps))*2000 ;radial distance steps (2000 km)
  roavg=exp((.5+dindgen(nosteps))/10.) ;log radial distance steps (km)
  alavg=roavg-rmars ;altitude (km)
  noavg=nologbin1/nocounter

  n2=exp(noavg)
  r2=roavg
  
  nostd=sqrt((nologbin2*nocounter-nologbin1^2)/(nocounter-1)/nocounter) ;standard deviation
  noste=nostd/sqrt(nocounter) ;standard error
  std=exp(nostd) ;fraction sd
  ste=exp(noste) ;fraction se
  nosdb=noavg-nostd ;one standard deviation below average
  nosda=noavg+nostd ;one standard deviation above average
  noseb=noavg-noste ;one standard error below average
  nosea=noavg+noste ;one standard error above average

end