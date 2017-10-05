function smooth_counts,data,norm,smpar=smpar,nsmooth=nsmooth,delta_t=delta_t
if not keyword_set(smpar) then smpar=50.
if size(/type,data) eq 7 then begin
  names = tnames(data,n)
  dprint,/phelp,names
  for i=0,n-1 do begin
     dprint,dlevel=2,'Smooth counts in: ',names[i],' length:',smpar
     get_data,names[i],data=d,dlim=dlim
     d.y = smooth_counts(d.y,d.znorm,smpar=smpar)
     store_data,names[i]+'_sm',data=d,dlim=dlim
  endfor
  return,names+'_sm'
endif


dim = size(/dimension,data)
n = dim[0]
nd = n_elements(dim)
d2 = n_elements(dim) eq 2 ? dim[1] : 1
sm_data = replicate(!values.f_nan,dim)
nsmooth = replicate(!values.f_nan,dim)
lval = data[0] > .01
nsm = 1d

for j=0l,d2-1 do begin
for i=0L , n-1 do begin
    val = data[i,j]
    if finite(val) eq 1 then begin        ;lval = data[i,j] 
       if keyword_set(norm) then lcnts= lval * norm[i,j] else lcnts = lval
       nsm = 1.d + smpar/ (lcnts > .0001)  
       lval =  (lval*(nsm-1) + val )/nsm
      sm_data[i,j] = lval
      nsmooth[i,j] = nsm
    endif ;else dprint
endfor
endfor

return,sm_data
end


function smooth_counts2,cnts0,dt

if size(/n_dimen,cnts0) eq 2 then begin
  dim  =size(/dimen,cnts0)
  ret = cnts0
  for i=0,dim[1]-1 do begin
    ret[*,i] = smooth_counts2(cnts0[*,i],dt)
  endfor
  return,ret
endif

n=n_elements(cnts0)
cnts = [cnts0,1]
sm_cnts = float(cnts)

nz = [cnts ne 0]
w1 = where( ~nz and shift(nz,1) , nw1)
w2 = where( nz and ~shift(nz,1) , nw2)

for i = 0l,nw1-1 do begin
  ci = sm_cnts[w2[i]]
  rate = 1./ ( w2[i]-w1[i] + 1)
  sm_cnts[w1[i]:w2[i]] = rate
  sm_cnts[w2[i]] = rate + ci -1
endfor

return,sm_cnts[0:n-1]
end


function smooth_counts3,cnts0,dt
  n=n_elements(cnts0)
  cnts = cnts0
  sm_cnts = float(cnts)
  icnts = total(/preserve,/cumulative,long64(cnts0))
  i0=0
  i2=0
  nstat=3
  for i1=0,n-1 do begin
    while (icnts[i1] - icnts[i0] ) gt nstat && i0 lt i1-1 do i0++ 
    while (icnts[i2] - icnts[i1] ) lt nstat && i2 lt n-1 do i2++
 ;   sm_cnts[i1] = total( cnts[i0:i2] ) / total(dt[i0:i2] )
if i1 lt 20 then begin
    print,[i0,i1,i2]
    print,icnts[[i0,i1,i2]] -icnts[i1] + cnts[i1]
    printdat,cnts[i0 :i2]
    print
endif
  endfor

  return,sm_cnts
end


function smooth_counts4,cnts0,dt
  n=n_elements(cnts0)
  nstat=3
  cnts = [nstat*2+1,cnts0,nstat*2+1]
  sm_cnts = float(cnts)
  icnts = total(/preserve,/cumulative,long64(cnts0))
  di = 0
  for i1=0,n-1 do begin
    
    while (icnts[i1] - icnts[i0] ) gt nstat && i0 lt i1-1 do i0++
    while (icnts[i2] - icnts[i1] ) lt nstat && i2 lt n-1 do i2++
    ;   sm_cnts[i1] = total( cnts[i0:i2] ) / total(dt[i0:i2] )
    if i1 lt 20 then begin
      print,[i0,i1,i2]
      print,icnts[[i0,i1,i2]] -icnts[i1] + cnts[i1]
      printdat,cnts[i0 :i2]
      print
    endif
  endfor

  return,sm_cnts
end






;pro test_smooth_counts,seed
nsamp = 10000
rate = replicate(.2d,nsamp)
rate[3000:4000] = 10.
rate[6000:7000] = 400.
rate[7000:8000] = 4000
rate[7400:7600]= 1
rate[500:1000] = 1
rate[1500:5500]=.001

if keyword_set(x) then rate= interp(y,x,findgen(nsamp))
;rate[*]=.01
delt = replicate(1,nsamp)
avg  = rate * delt
cnts = randomp(avg,seed)
;cnts = float(cnts)
;cnts[6900:7100] = !values.f_nan
plot,cnts,/ylog,yrange=[.0001,10000],psym=3
oplot,avg,color=5

scnts = smooth_counts2(cnts)
oplot,scnts,color=3

scnts = smooth_counts(cnts,nsmooth=nsmooth)
oplot,scnts,color=6
;oplot,scnts,color=4
oplot,nsmooth,color=1
oplot,avg,color=2
oplot,cnts,psym=3
mm_scnts = minmax(scnts)
mm_nsmooth = minmax(nsmooth)
;printdat
printdat,average(scnts)
printdat,average(avg)
printdat,average(cnts)
print,average(scnts)/average(cnts)

dt = cnts*0+1.
ss=smooth_counts3(cnts,dt)


end
