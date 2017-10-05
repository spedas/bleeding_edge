

pro alfven_pow,bwavelet=wbp,vwavelet=wvp, period=period, jv=jv,$
  magname=magname,densname=densname,velname=velname,  $
  bonly=bonly, freq=freq, per_axis=per_axis, $
  minvarfreq =minvarfreq,maxpoints=maxpoints,rbin=rbin,$
  nvalues=n,bvalues=b,vvalues=v,wtime=dtime,time=time, $
  trange=tr,no_tplot=no_tplot,resolution=resolution,verbose=verbose 
  
if not keyword_set(magname) then magname='wi_B3'
if not keyword_set(densname) then densname='Np'
if not keyword_set(velname) then velname='Vp'


get_data,magname,time,B

pad = 2

if keyword_set(rbin) then begin
   n = n_elements(time)
   nrbin = n/rbin
   time = rebin(time[0:nrbin*rbin-1],nrbin)
   B    = rebin(B[0:nrbin*rbin-1,*],nrbin,3)
endif

if not keyword_set(maxpoints) then maxpoints = 32000l ; maxpoints = 2l^16

if n_elements(time) gt maxpoints and not keyword_set(tr) then begin
   Print,'Too many time samples; Select a time range:'
   ctime,tr
endif

if  keyword_set(tr) then trange = tr    ; else get_timespan,trange

if keyword_set(trange) then begin
  if n_elements(trange) eq 1 then begin
     mm = min(abs(time-trange[0]),w)
     rr = [0,maxpoints-1]- maxpoints/2 + w 
     rr = 0 > rr < (n_elements(time)-1)
     time=time[rr[0]:rr[1]]
     B=B[rr[0]:rr[1],*]
  endif else begin
     trange=minmax(time_double(trange))
     w = where(time le trange[1] and time ge trange[0],c)
     if c eq 0 then message,'No data in that time range'
     time = time[w]
     B = B[w,*]
  endelse
endif

interp_gap,time,B   ,verbose=verbose   ; remove nans
help,time,b
n = data_cut(densname,time,gap_thresh=1e5,/extrapolate)
v = data_cut(velname,time,gap_thresh=1e5,/extrapolate)
dt = time[1]-time[0]
if not keyword_set(jv) then jv = 64

if keyword_set(deriv) then begin
  dtime = (time+shift(time,1))[1:*]/2

  n2 = ((n+shift(n,1))/2)[1:*,*] 

  db = ((b-shift(b,1,0))/dt)[1:*,*]
  dv = ((v-shift(v,1,0))/dt)[1:*,*]
  bs = ((b+shift(b,1,0))/2)[1:*,*]
endif else begin
  dtime=time
  n2 = n
  db = b
  dv = v
  bs = b
endelse

dim = [n_elements(dtime),jv+1,3]
nt = dim[0]

wv = make_array(dim=dim,/complex,/noz)
for k=0,2 do $
  wv[*,*,k] = wavelet(db[*,k],dt,j=jv,pad=pad,period=period,verbose=verbose)
if not keyword_set(deriv) then  for j=0,jv do $  
    wv[*,j,*] = wv[*,j,*]*2*!dpi/period[j]
  


if not keyword_set(periods_avg) then periods_avg=8.
if keyword_set(verbose) then printdat,periods_avg,/val,'Num period'
; Rotate to new frame with z along B

wid = round(period/dt*periods_avg)*2+1 < (dim[0]-1)
if keyword_set(verbose) then printdat,wid,'width'
wid2 = round(period/dt*periods_avg/2)*2+1 < (dim[0]-1)
if keyword_set(verbose) then printdat,wid2,'width2'

if keyword_set(minvarfreq) then begin
   minvar = 0> round(interp(findgen(jv+1),1/period,minvarfreq)) <jv
endif
if keyword_set(minvar) then begin
  mvlab = string(minmax(minvar),format='(i0)')
  if n_elements(minvar) eq 1 then mvlab = mvlab[0] else mvlab = mvlab[0]+':'+mvlab[1]
  db = average( float(wv[*,min(minvar):max(minvar),*]) ,2 )
  nt = dim[0]
  
dprint,'Computing minvariance directions.'
printdat,minvar,'minvar',/val
printdat,period[minvar],'Period',/val
printdat,1/period[minvar],'Freq',/val
  
  dbb = fltarr(nt,6)
  dbb[*,0] = db[*,0] * db[*,0]
  dbb[*,1] = db[*,1] * db[*,1]
  dbb[*,2] = db[*,2] * db[*,2]
  dbb[*,3] = db[*,0] * db[*,1]
  dbb[*,4] = db[*,0] * db[*,2]
  dbb[*,5] = db[*,1] * db[*,2]
  
  ns = wid[max(minvar)]
printdat,/val,ns,'Smooth window'
printdat,/val,ns*dt,'Smooth Period'
  for k=0,5 do dbb[*,k] = smooth(dbb[*,k],ns,/edge_truncate)
  
  bsm = fltarr(nt,3)
  for k=0,2 do bsm[*,k] = smooth(bs[*,k],ns,/edge_truncate)
  
  eval= fltarr(nt,3)
  evec= fltarr(nt,3)
 
if keyword_set(eigenval_only) then begin
  bxbx = dbb[*,0]
  byby = dbb[*,1]
  bzbz = dbb[*,2]
  bxby = dbb[*,3]
  bxbz = dbb[*,4]
  bybz = dbb[*,5]
  a2 = bxbx+byby+bzbz
  a1 = bxby*conj(bxby)+bybz*conj(bybz)+bxbz*conj(bxbz)-bxbx*byby-byby*bzbz-bzbz*bxbx
  a0 = bxbx*byby*bzbz-bxbx*(bybz*conj(bybz))-byby*(bxbz*conj(bxbz))-bzbz*(bxby*conj(bxby))+bxby*conj(bxbz)*bybz+conj(bxby)*bxbz*conj(bybz)
  a2 = double(a2)
  a1 = double(a1)
  a0 = double(a0)
  polyroots,a0,a1,a2,-1,z1=z1,z2=z2,z3=z3
  z1=float(z1)
  z2=float(z2)
  z3=float(z3)
  store_data,'wv_eval-'+mvlab,data={x:time,y:[[z1],[z2],[z3]]}

endif else begin
  map = [[0,3,4],[3,1,5],[4,5,2]]
  for i=0l,nt-1 do begin
    a = (reform(dbb[i,*]))[map]
    eval[i,*] = eigenql(a,eigenvect=vs)
    v = vs[*,2]
    if total(v*bsm[i,*]) lt 0 then v=-v
;    lv = v
    evec[i,*] = v
  endfor
  bdotk = total(evec * bsm,2)/sqrt(total(bsm^2,2))
  store_data,'wv_eval-'+mvlab,data={x:time,y:eval},dlim={ylog:1}
  store_data,'wv_evec-'+mvlab,data={x:time,y:evec}
;  store_data,'wv_bdotk-'+mvlab,data={x:time,y:bdotk}
  store_data,'wv_b@k-'+mvlab,data={x:time,y:acos(bdotk)*!radeg}
endelse

endif

;if keyword_set(Rotate_pow) then begin

dprint,'Rotating to B aligned coordinates.'
wv = reform(/over,wv,dim[0]*dim[1],dim[2])

w2 = fltarr(dim[0],dim[1],dim[2])
for j=0,jv do  for k=0,2 do  w2[*,j,k] = smooth(bs[*,k],wid[j],/edge_truncate)

w2 = reform(w2,/over,dim[0]*dim[1],dim[2])
w2 = w2/( sqrt(total(w2^2,2)) # [1,1,1] )
w1 = crossp3(w2,[1.,0.,0.])
w1 = w1/( sqrt(total(w1^2,2)) # [1,1,1] )
w0 = crossp3(w1,w2)

wbp = make_array(dim[0]*dim[1],dim[2],/complex,/noz)
wbp[*,2] = wv[*,0]*w2[*,0] + wv[*,1]*w2[*,1] + wv[*,2]*w2[*,2]
wbp[*,1] = wv[*,0]*w1[*,0] + wv[*,1]*w1[*,1] + wv[*,2]*w1[*,2]
wbp[*,0] = wv[*,0]*w0[*,0] + wv[*,1]*w0[*,1] + wv[*,2]*w0[*,2]
wbp = reform(/over,wbp,dim[0],dim[1],dim[2])

if not keyword_set(bonly) then begin
; Wavelet transform of velocity:
wv = reform(/over,wv,dim[0],dim[1],dim[2])
for k=0,2 do $
   wv[*,*,k] = wavelet(dv[*,k],dt,j=jv,pad=pad,period=period,verbose=verbose)

if not keyword_set(deriv) then  for j=0,jv do $  
    wv[*,j,*] = wv[*,j,*]*2*!dpi/period[j]

wv = reform(/over,wv,dim[0]*dim[1],dim[2])
wvp = make_array(dim[0]*dim[1],dim[2],/complex,/noz)
wvp[*,2] = wv[*,0]*w2[*,0] + wv[*,1]*w2[*,1] + wv[*,2]*w2[*,2]
wvp[*,1] = wv[*,0]*w1[*,0] + wv[*,1]*w1[*,1] + wv[*,2]*w1[*,2]
wvp[*,0] = wv[*,0]*w0[*,0] + wv[*,1]*w0[*,1] + wv[*,2]*w0[*,2]
wvp = reform(/over,wvp,dim[0],dim[1],dim[2])

n2 = smooth(n2,wid[0],/edge_truncate)

n_rat = sqrt(n2)/21.8 
for j=0,jv do  for k=0,2 do   wvp[*,j,k] = wvp[*,j,k] * n_rat

if keyword_set(no_tplot) then return

wv=0 ; not needed
w0=0
w1=0
w2=0
endif


yax = keyword_set(per_axis) ? period : 1/period
ytitle = keyword_set(per_axis) ? 'Seconds' : 'Hz' 

if keyword_set(save_w) then begin
store_data,'wvp',data={x:dtime,y:wvp,v1:yax,v2:[0,1,2]}
store_data,'wbp',data={x:dtime,y:wbp,v1:yax,v2:[0,1,2]}
endif

if keyword_set(verbose) then dprint,'Computing power and polarization for TPLOT'

r = keyword_set(resolution) ? resolution : 0
rdtime = reduce_tres(dtime,r)
mm = minmax(yax)
polopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zrange:[-1,1],zlog:0,zstyle:1};,ytitle:ytitle}
powopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zrange:10.^[-3,-1],zlog:1,zstyle:1};,ytitle:ytitle}


pow = abs(wbp[*,*,2])^2
store_data,'pow(Bpar)',data={x:rdtime,y:reduce_tres(pow,r),v:yax},dlim=powopts

pow = (abs(wbp[*,*,0])^2 + abs(wbp[*,*,1])^2)/2
pol = imaginary(wbp[*,*,0]*conj(wbp[*,*,1]))/pow
for j=0,jv do  if wid[j] gt 1 then pol[*,j] = smooth(pol[*,j],wid2[j],/edge_truncate)
store_data,'pow(Bperp)',data={x:rdtime,y:reduce_tres(pow,r),v:yax},dlim=powopts
store_data,'pol(Bperp)',data={x:rdtime,y:reduce_tres(pol,r),v:yax},dlim=polopts

if keyword_set(bonly) then return

 if 0 then begin
;pow = (abs(wbp[*,*,0])^2 + abs(wbp[*,*,1])^2)/2
;pow = (abs(wvp[*,*,0]/wbp[*,*,0])   ); + abs(wvp[*,*,1]/wbp[*,*,1]))/2
;pol = (imaginary(alog(wvp[*,*,0]/wbp[*,*,0]))) / !pi;  + imaginary(alog(wvp[*,*,1]/wbp[*,*,1]))) )/2
;wid4=wid;(wid*4+1)< (dim[0]-1)

; rat_x = (wvp[*,*,0] / wbp[*,*,0])
; rat_y = (wvp[*,*,1] / wbp[*,*,1])
; rat_r = rat_x + i * rat_y
; rat_l = rat_x - i * rat_y
 
i = complex(0,1)
 vl = wvp[*,*,0] - i * wvp[*,*,1]
 vr = wvp[*,*,0] + i * wvp[*,*,1]
 bl = wbp[*,*,0] - i * wbp[*,*,1]
 br = wbp[*,*,0] + i * wbp[*,*,1]
 
; rat_l = vl/bl
; rat_r = vr/br
 
;for j=0,jv do  if wid4[j] gt 1 then  rat_r[*,j] = smooth(rat_r[*,j],wid4[j],/edge_truncate)
;for j=0,jv do  if wid4[j] gt 1 then  rat_l[*,j] = smooth(rat_l[*,j],wid4[j],/edge_truncate)
;p = period
;reduce_yres,rat_r,p,8
;p = period
;reduce_yres,rat_l,p,8
lrat_r = alog(vr/br)
lrat_l = alog(vl/bl)

;j = 1
;y = imaginary(lrat_l)/!pi
;y = -3> float(lrat_l) < 3
;y = imaginary(lrat_r)/!pi
;y = -3> float(lrat_r) < 3
;tm = findgen(dimen1(y)) # replicate(1.,dimen2(y))

;d = float(histbins2d(tm[*,j:j+dj-1],y[*,j:j+dj-1],xb,yb,xbins=100,nbins=30,/shif))
;specplot,xb,yb,d,/no_interp,lim=struct(zrange=[0,100])
;oplot,tm[*,j:j+dj-1],y[*,j:j+dj-1],ps=3

;plot,-3>float(lrat_r[*,5])<3,ps=3
;plot,-3>float(lrat_l[*,5])<3,ps=3
;plot,imaginary(lrat_r[*,5]),ps=3
;plot,imaginary(lrat_l[*,5]),ps=3
;plot,-3>float(lrat_r[*,1])<3,ps=3
;plot,-3>float(lrat_l[*,1])<3,ps=3


;pow = float(rat
;wbv_a = (wbv_p[*,*,0] + wbv_p[*,*,1])/pow
;pol = (imaginary(alog(wbv_a)))/!pi
;pow = abs(wbv_a)
store_data,'alog(Vl/Bl)',data={x:rdtime,y:reduce_tres(pow,r),v:yax},dlim=polopts
store_data,'phs(V/B)',data={x:rdtime,y:reduce_tres(pol,r),v:yax},dlim=polopts
endif

wbv_p = (wbp + wvp )/2
wbv_a = (wbp - wvp )/2

apow = (abs(wbv_a[*,*,0])^2 + abs(wbv_a[*,*,1])^2)/2
ppow = (abs(wbv_p[*,*,0])^2 + abs(wbv_p[*,*,1])^2)/2
store_data,'pow(A+)',data={x:rdtime,y:reduce_tres(apow,r),v:yax},dlim=powopts
store_data,'pow(A-)',data={x:rdtime,y:reduce_tres(ppow,r),v:yax},dlim=powopts

pow = apow+ppow
pol = (apow-ppow)/pow
;w = where(pow le .0001)
;pol[w] = !values.f_nan

if 0 then begin
store_data,'pow(A)',data={x:rdtime,y:reduce_tres(pow,r),v:yax},dlim=powopts
endif
store_data,'dir(A)',data={x:rdtime,y:reduce_tres(pol,r),v:yax},dlim=polopts

pol = imaginary(wbv_p[*,*,0]*conj(wbv_p[*,*,1]))/ppow
for j=0,jv do  if wid[j] gt 1 then  pol[*,j] = smooth(pol[*,j],wid[j],/edge_truncate)
store_data,'pol(A-)',data={x:rdtime,y:reduce_tres(pol,r),v:yax},dlim=polopts
pol = imaginary(wbv_a[*,*,0]*conj(wbv_a[*,*,1]))/apow
for j=0,jv do  if wid[j] gt 1 then  pol[*,j] = smooth(pol[*,j],wid[j],/edge)
store_data,'pol(A+)',data={x:rdtime,y:reduce_tres(pol,r),v:yax},dlim=polopts


pow = (abs(wbv_a[*,*,2])^2 + abs(wbv_p[*,*,2])^2)
pol = (abs(wbv_a[*,*,2])^2 - abs(wbv_p[*,*,2])^2)/pow
store_data,'pow(Ac)',data={x:rdtime,y:reduce_tres(pow,r),v:yax},dlim=powopts
store_data,'dir(Ac)',data={x:rdtime,y:reduce_tres(pol,r),v:yax},dlim=polopts


end


