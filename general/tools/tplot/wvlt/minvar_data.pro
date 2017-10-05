pro get_eigenv,db,ns,eval,max_evec=evec2,min_evec=evec0,  $
   bdotk=bdotk,eval_only=eval_only,bdir=B,thresh_ratio=thresh_ratio $
   ,vdir=vdir,vdotk=vdotk,bsm=bsm

  dim = size(/dimen,db)
  nt = dim[0]
  dbb = fltarr(nt,6)
dbs = fltarr(nt,3)
for k=0,2 do dbs[*,k] = smooth(db[*,k],ns,/edge_truncate,/nan)
dbs = db-dbs
  dbb[*,0] = dbs[*,0] * dbs[*,0]
  dbb[*,1] = dbs[*,1] * dbs[*,1]
  dbb[*,2] = dbs[*,2] * dbs[*,2]
  dbb[*,3] = dbs[*,0] * dbs[*,1]
  dbb[*,4] = dbs[*,0] * dbs[*,2]
  dbb[*,5] = dbs[*,1] * dbs[*,2]

  for k=0,5 do dbb[*,k] = smooth(dbb[*,k],ns,/edge_truncate,/nan)

  if keyword_set(B) then begin
    bsm = fltarr(nt,3)
    for k=0,2 do bsm[*,k] = smooth(B[*,k],ns,/edge_truncate,/nan)
    bsm2 = crossp2(bsm,[1.,0,0])
    help,bsm,bsm2
  endif
  if keyword_set(vdir) then begin
    vsm = fltarr(nt,3)
    for k=0,2 do vsm[*,k] = smooth(vdir[*,k],ns,/edge_truncate,/nan)
    help,vsm
  endif

  eval= replicate(!values.f_nan,nt,3)
  if arg_present(evec0) then evec0= replicate(!values.f_nan,nt,3)
  if arg_present(evec2) then evec2= replicate(!values.f_nan,nt,3)

  if keyword_set(eval_only) then begin
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
    eval = [[z1],[z2],[z3]]
;    store_data,'wv_eval-'+mvlab,data={x:time,y:evals}

  endif else begin
    map = [[0,3,4],[3,1,5],[4,5,2]]
    lv0 = 0
    lv2 = 0
    frac = .1
    for i=0l,nt-1 do begin
      if finite(total(dbb[i,*])) then begin
        a = (reform(dbb[i,*]))[map]
        eval[i,*] = eigenql(a,eigenvect=vs,/ascend)
        if keyword_set(evec0) then begin
          v0 = vs[*,0]
          if keyword_set(bsm) then lv0=bsm[i,*]
          if total(v0*lv0) lt 0 then v0=-v0
          lv0 = v0
          evec0[i,*] = v0
        endif
        if keyword_set(evec2) then begin
          v2 = vs[*,2]
          if keyword_set(bsm2) then lv2=reform(bsm2[i,*])
          if total(v2*lv2) lt 0 then v2= -v2
          lv2 = frac*v2+(1.-frac)*lv2
          evec2[i,*] = v2
        endif
      endif
    endfor
    if keyword_set(thresh_ratio) then begin
      w = where(eval[*,0] gt (eval[*,1]/thresh_ratio) ,c)
      if c ne 0 then evec0[w,*]=!values.f_nan
      w = where(eval[*,2] lt (eval[*,1]*thresh_ratio) ,c)
      if c ne 0 then evec2[w,*]=!values.f_nan
    endif
    if keyword_set(bsm) then $
      bdotk = total(evec0 * bsm ,2)/sqrt(total(bsm ^2,2))
    if keyword_set(vsm) then $
      vdotk = total(evec0 * vsm ,2)/sqrt(total(vsm ^2,2))
endelse

end





pro minvar_data,varname,frange=frange,$
  avg_period=avg_period, $
  tplot_prefix=tplot_prefix, $
  data=b, wavelet=wv, time=time, bad_index=bad_index,$
  per_axis=per_axis, $
  thresh_ratio=thresh_ratio, $
  wid=wid, $
  minvarfreq =minvarfreq,maxpoints=maxpoints,rbin=rbin,$
  trange=tr,resolution=resolution,verbose=verbose , $
  vname=vname

if size(/type,varname) eq 7  then begin
name=keyword_set(tplot_prefix) ? tplot_prefix : varname

get_data,varname,time,B

if keyword_set(vname) then vsw=data_cut(vname,time)

if keyword_set(rbin) then begin
   n = n_elements(time)
   nrbin = n/rbin
   time = rebin(time[0:nrbin*rbin-1],nrbin)
   B    = rebin(B[0:nrbin*rbin-1,*],nrbin,3)
endif

if not keyword_set(maxpoints) then maxpoints  = 2L^20

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

endif else name = keyword_set(tplot_prefix) ? tplot_prefix : ''


interp_gap,time,B,index=bad_index ,count=nbad_index  ,verbose=verbose   ; remove nans
if keyword_set(verbose) then printdat,bad_index,'index'
dt = time[1]-time[0]

printdat,dt,varn='dt'
pad = 2

n1 = dimen1(b)

db = b
if n_elements(df_f) ne 1 then df_f = .2

for k=0,2 do begin
   b2 = padfftarray(b[*,k],pad)
   n = n_elements(b2)
   b2 = fft(b2,/over)
   f = (dindgen(n/2) + 1)/(n*dt)
   f = [0d,f,-REVERSE(f(0:(n-1)/2 - 1))]
   if keyword_set(df_f) then begin
     f = abs(f)
     filter = exp(-( (alog(f/frange[0])/df_f) < 0 )^2)
     filter = filter * exp(-( (alog(f/frange[1])/df_f) > 0 )^2)
   endif else      filter = abs(f) ge frange[0] and abs(f) le frange[1]
   b2 = fft(b2 * filter,/over,/inverse)
   db[*,k] = float( b2[0:n1-1] )
endfor

if not keyword_set(avg_period) then avg_period=12.

ns = round(avg_period/2/dt/frange[0])*2+1
printdat,ns,varn='ns'

dprint,'Computing minvariance directions.'
mvlab='0'
ename = name+'_mv'   ;('+mvlab+')'

get_eigenv,db,ns,eval,min_evec=evec0,max_evec=evec2,bdotk=bdotk $
  ,eval_only=eval_only,bdir=B,thresh_ratio=thresh_ratio,vdir=vsw,vdotk=vdotk,bsm=bsm

if keyword_set(nbad_index) then begin
  evec0[bad_index,*] = !values.f_nan
  evec2[bad_index,*] = !values.f_nan
  eval[bad_index,*] = !values.f_nan
  bdotk[bad_index] = !values.f_nan
endif

store_data,ename+'_eval',data={x:time,y:eval},dlim={ylog:1}
store_data,ename+'_evec0',data={x:time,y:evec0}
store_data,ename+'_evec2',data={x:time,y:evec2}
;store_data,ename+'_evalr',data={x:time,y:(eval[*,2] # [1,1,1])/eval},dlim={ylog:1}
store_data,ename+'_evalr',data={x:time,y:eval/ (total(eval,2) # [1,1,1])},dlim={ylog:1,yrange:[.01,1]}
store_data,ename+'_smooth',data={x:time,y:bsm}
if keyword_set(bdotk) then begin
  store_data,ename+'_b@k',data={x:time,y:acos(bdotk)*!radeg}
endif
if keyword_set(vdotk) then begin
  store_data,ename+'_v@k',data={x:time,y:acos(vdotk)*!radeg}
endif

printdat,/val,ns,varname='Smooth window'
printdat,/val,ns*dt,varname='Smooth Period'
;stop

end

