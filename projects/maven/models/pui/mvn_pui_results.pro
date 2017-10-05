;20160525 Ali
;manipulating pickup ion model results, doing statistics, etc.
;can be used to compute exospheric neutral densities using a reverse method

pro mvn_pui_results

@mvn_pui_commonblock.pro ;common mvn_pui_common
common mvn_pui_results_common,sizenoefi,sizenhefi,meannoefi,meannhefi

ebinlimo=20 ;energy bin limit for oxygen
ebinlimh=23 ;energy bin limit for hydrogen
radmin=5e3 ;minimum radius (km)
radmax=20e3;maximum radius (km)
szamax=70; max sza (degree)

;ctime,trange,/silent
;timespan,trange

;secinday=86400L ;number of seconds in a day
;timespan,'16-2-14',1
;get_timespan,trange
;ndays=round((trange[1]-trange[0])/secinday) ;number of days

;sizenoefi=replicate(0.,ndays)
;sizenhefi=replicate(0.,ndays)
;meannoefi=replicate(0.,ndays)
;meannhefi=replicate(0.,ndays)

;for j=0,ndays-1 do begin

;tr=trange[0]+[j,j+1]*secinday
;if ~keyword_set(swics) and ~keyword_set(swics) then continue
;mvn_pui_model,/do3d,/exoden,binsize=32,trange=tr
;mvn_pui_tplot,/tplot1d

no=swiaef3d/kefswio3d/(~kefswih3d) ;exospheric neutral O density (cm-3) data/model ratio
nh=swiaef3d/kefswih3d/(~kefswio3d) ;exospheric neutral H density (cm-3) data/model ratio

ro=(sqrt(krxswio3d^2+kryswio3d^2+krzswio3d^2))/knnswio3d/1e3 ;radial distance (km)
rh=(sqrt(krxswih3d^2+kryswih3d^2+krzswih3d^2))/knnswih3d/1e3 ;radial distance (km)
so=!radeg*acos(krxswio3d/knnswio3d/1e3/ro) ;solar zenith angle (degrees)
sh=!radeg*acos(krxswih3d/knnswih3d/1e3/rh) ;solar zenith angle (degrees)

swkey=where(finite(swalt)) ;times when in the solar wind

noe=no[swkey,0:ebinlimo,*,*] ;only high energy bins
nhe=nh[swkey,0:ebinlimh,*,*]
roe=ro[swkey,0:ebinlimo,*,*]
rhe=rh[swkey,0:ebinlimh,*,*]
soe=so[swkey,0:ebinlimo,*,*]
she=sh[swkey,0:ebinlimh,*,*]
krxswio3de=krxswio3d[swkey,0:ebinlimo,*,*]/knnswio3d[swkey,0:ebinlimo,*,*]/1e3
kryswio3de=kryswio3d[swkey,0:ebinlimo,*,*]/knnswio3d[swkey,0:ebinlimo,*,*]/1e3
krzswio3de=krzswio3d[swkey,0:ebinlimo,*,*]/knnswio3d[swkey,0:ebinlimo,*,*]/1e3
krxswih3de=krxswih3d[swkey,0:ebinlimh,*,*]/knnswih3d[swkey,0:ebinlimh,*,*]/1e3
kryswih3de=kryswih3d[swkey,0:ebinlimh,*,*]/knnswih3d[swkey,0:ebinlimh,*,*]/1e3
krzswih3de=krzswih3d[swkey,0:ebinlimh,*,*]/knnswih3d[swkey,0:ebinlimh,*,*]/1e3
noel=where(finite(noe) and ~(~noe) and (roe lt radmax) and (roe gt radmin) and (soe lt szamax),/null,sizenoef) ;non-zero density locations
nhel=where(finite(nhe) and ~(~nhe) and (rhe lt radmax) and (rhe gt radmin) and (she lt szamax),/null,sizenhef)
noef=noe(noel) ;only finite non-zero densities
nhef=nhe(nhel)
roef=roe(noel)
rhef=rhe(nhel)
soef=soe(noel)
shef=she(nhel)
krxswio3def=krxswio3de(noel)
kryswio3def=kryswio3de(noel)
krzswio3def=krzswio3de(noel)
krxswih3def=krxswih3de(nhel)
kryswih3def=kryswih3de(nhel)
krzswih3def=krzswih3de(nhel)

if ~sizenoef then noef=0
if ~sizenhef then nhef=0

meannoef=exp(mean(alog(noef)))
meannhef=exp(mean(alog(nhef)))

soefscaled=bytscl(soef,min=0,max=100)
shefscaled=bytscl(shef,min=0,max=100)

nosteps=150
nocounter=replicate(0.,nosteps) ;binning counter
nhcounter=replicate(0.,nosteps) ;binning counter
nologbin1=replicate(0.,nosteps) ;ln densities binned
nhlogbin1=replicate(0.,nosteps) ;ln densities binned
nologbin2=replicate(0.,nosteps) ;ln square densities binned
nhlogbin2=replicate(0.,nosteps) ;ln square densities binned

for i=0,sizenoef-1 do begin
;  rostep=floor(roef[i]/2e3) ;radial distance step (2000 km)
  rostep=floor(10.*alog(roef[i])) ;log radial distance step
  nocounter[rostep]+=1
  nologbin1[rostep]+=alog(noef[i])
  nologbin2[rostep]+=(alog(noef[i]))^2
endfor

for i=0,sizenhef-1 do begin
  rhstep=floor(10.*alog(rhef[i])) ;log radial distance step
  nhcounter[rhstep]+=1
  nhlogbin1[rhstep]+=alog(nhef[i])
  nhlogbin2[rhstep]+=(alog(nhef[i]))^2
endfor

rmars=3400. ;mars radius (km)
;roavg=(.5+dindgen(nosteps))*2000 ;radial distance steps (2000 km)
roavg=exp((.5+dindgen(nosteps))/10.) ;log radial distance steps (km)
alavg=roavg-rmars ;altitude (km)
noavg=nologbin1/nocounter
nhavg=nhlogbin1/nhcounter
nostd=sqrt((nologbin2*nocounter-nologbin1^2)/(nocounter-1)/nocounter) ;standard deviation
nhstd=sqrt((nhlogbin2*nhcounter-nhlogbin1^2)/(nhcounter-1)/nhcounter) ;standard deviation
noste=nostd/sqrt(nocounter) ;standard error
nhste=nhstd/sqrt(nhcounter) ;standard error
nosdb=noavg-nostd ;one standard deviation below average
nhsdb=nhavg-nhstd ;one standard deviation below average
nosda=noavg+nostd ;one standard deviation above average
nhsda=nhavg+nhstd ;one standard deviation above average
noseb=noavg-noste ;one standard error below average
nhseb=nhavg-nhste ;one standard error below average
nosea=noavg+noste ;one standard error above average
nhsea=nhavg+nhste ;one standard error above average

dprint,'O counts='+strtrim(sizenoef,2)
dprint,'H counts='+strtrim(sizenhef,2)
dprint,'meannoef='+strtrim(meannoef,2)
dprint,'meannhef='+strtrim(meannhef,2)

;sizenoefi[j]=sizenoef
;sizenhefi[j]=sizenhef
;meannoefi[j]=meannoef
;meannhefi[j]=meannhef

;endfor

w=getwindows(/current)
if keyword_set(w) then w.erase
;p11=scatterplot(noef,roef-rmars,/xlog,/ylog,xtitle='Neutral Density (cm-3)',ytitle='Altitude (km)',symbol='o',sym_size=.2,/sym_filled,magnitude=soefscaled,rgb_table=33,/current)
;p11=scatterplot(nhef,rhef-rmars,/xlog,xtitle='Neutral Density (cm-3)',ytitle='Altitude (km)',symbol='o',sym_size=.2,/sym_filled,magnitude=shefscaled,rgb_table=33,/current)
;p12=scatterplot3d(krxswio3def,kryswio3def,krzswio3def,xtitle='X (km)',ytitle='Y (km)',ztitle='Z (km)',symbol='o',sym_size=.2,/sym_filled,/aspect_z,/aspect_r,magnitude=soefscaled,rgb_table=33,/current)
;p13=scatterplot3d(scp[*,0]/1e3,scp[*,1]/1e3,scp[*,2]/1e3,symbol='o',sym_size=.5,/sym_filled,/overplot)
;p13=scatterplot3d(krxswih3def,kryswih3def,krzswih3def,symbol='.',/overplot)
;p14=scatterplot3d([rmars,0,-rmars,0,0,0],[0,0,0,0,-rmars,rmars],[0,rmars,0,-rmars,0,0],symbol='o',sym_color='red',/sym_filled,/overplot)
;p10=colorbar(range=[0,100],position=[.2,.97,.8,1],title='Solar Zenith Angle (degrees)')
;p=plot([0],/xlog,title='Hot O Retrieval from SWIA Pickup Ions: 2016-02-21 to 2016-02-29',xtitle='Atomic Oxygen Exospheric Neutral Density (cm-3)',ytitle='Altitude (km)',xrange=[1,1e5],yrange=[0,5e4],/o)
p0=plot(exp(noavg),alavg,color='red',linestyle='',symbol='o',/overplot,name='Mean')
p1=plot(exp(noseb),alavg,color='red',linestyle='-',/overplot,name='Standard Error')
p2=plot(exp(nosea),alavg,color='red',linestyle='-',/overplot,name='1 SE above')
p3=plot(exp(nosdb),alavg,color='red',linestyle='--',/overplot,name='Standard Deviation')
p4=plot(exp(nosda),alavg,color='red',linestyle='--',/overplot,name='1 SD above')
p5=legend(target=[p0,p1,p3],position=[.77,.77])
p0=plot(exp(nhavg),alavg,color='blue',linestyle='',symbol='o',/overplot,name='Average')
p1=plot(exp(nhseb),alavg,color='blue',linestyle='-',/overplot,name='1 SE below')
p2=plot(exp(nhsea),alavg,color='blue',linestyle='-',/overplot,name='1 SE above')
p3=plot(exp(nhsdb),alavg,color='blue',linestyle='--',/overplot,name='1 SD below')
p4=plot(exp(nhsda),alavg,color='blue',linestyle='--',/overplot,name='1 SD above')
mvn_pui_plot_exoden,/overplot
t1=text(.51,.3,'O',color='red')
t2=text(.7,.3,'H',color='blue')
p0.title='SWIA Pickup Ion Analysis, 2014-12-20, 17:30-19:30 UTC'

end
