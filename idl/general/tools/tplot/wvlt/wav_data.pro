;+
;  Procedure:  wav_data,'name'
;  Purpose:  computes the wavelet transform of tplot variables.
;            Uses Morlet mother wavelet.
;
;  Author: Davin Larson
;
;$LastChangedBy: davin-mac $
;$LastChangedDate: 2025-06-12 05:18:03 -0700 (Thu, 12 Jun 2025) $
;$LastChangedRevision: 33388 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/wvlt/wav_data.pro $
;
;-

pro smooth_wavelet,wv,wid,gaussian=gaussian
  dim = [size(/dimen,wv),1,1]
  nk = dim[2]
  nj = dim[1]
  nt = dim[0]
  ;printdat,dim,'dim'
  widi = 3 > (round(wid/2)*2+1) < (nt-1)

  if keyword_set(gaussian) then begin
    for k=0,nk-1 do $
      for j=0,nj-1 do  if widi[j] gt 1 then begin
      dprint,k,j,widi[j],dlevel=3
      kernal = exp(-(dgen(widi[j],range=[-2,2]))^2)
      kernal = kernal / total(kernal)
      wv[*,j,k] = convol(wv[*,j,k],kernal,/edge_truncate)
    endif
    return
  endif

  widi = 3 > round(wid) < (nt-1)

  for k=0,nk-1 do $
    for j=0,nj-1 do $
    if widi[j] gt 1 then wv[*,j,k] = smooth(wv[*,j,k],widi[j] < (nt-1),/edge_truncate,/nan)
end


pro cross_corr_wavelet,wa,wb,wid,gam,coinc,quad,crat,gsmooth=gsmooth
  p = wa*conj(wb)
  coinc = float(p)
  quad  = imaginary(p)
  smooth_wavelet,coinc,wid,gauss=gsmooth
  smooth_wavelet,quad ,wid,gauss=gsmooth
  p  = abs(wa)^2
  smooth_wavelet,p,wid,gauss=gsmooth
  gam  = abs(wb)^2
  smooth_wavelet,gam,wid,gauss=gsmooth
  if arg_present(crat) then  crat = coinc/gam

  p = p*gam
  gam = (coinc^2 + quad^2)/p
  p = sqrt(p)
  coinc = coinc/p
  quad = quad/p
end


function interp_wavelet,wv,time,newtime
  dim1 = size(/dimen,wv)
  nt = dim1[0]
  jv1 = dim1[1]
  nk = (n_elements(dim1) eq 3) ? dim1[2] : 1
  dim2 = dim1
  dim2[0] = n_elements(newtime)
  wv2 = make_array(/complex,dimen=dim2,/noz)

  for j = 0,jv1-1 do   $
    for k = 0,nk-1 do   $
    wv2[*,j,k] = interpol(wv[*,j,k],time,newtime)

  return,wv2
end


function rotate_wavelet2,wv,dir=B,xdir=xdir,wid=wid,rotmats=rotmats,verbose=verbose,get_rotmats=get_rotmats

  ;if n_elements(xdir) ne 3 then xdir = [1.,0,0]
  if n_elements(xdir) ne 3 then xdir = [0.,0,1.]
  dim = dimen(wv)
  nt  = dim[0]
  jv  = dim[1]-1
  if dim[2] ne 3 then message,'Must have 3 dimensions'

  rot = fltarr(dim[0],3,3)
  wvp = make_array(dim[0],dim[1],dim[2],/complex,/noz)

  dprint,dlevel=2,verbose=verbose,'Rotating wavelets'
  time0 = systime(1)

  use_rotmat =  keyword_set(rotmats) and (keyword_set(get_rotmats) eq 0)
  if arg_present(rotmats) and keyword_set(get_rotmats) then rotmats=fltarr(dim[0],dim[1],3,3)

  ;help,rotmats
  ;help,use_rotmat
  ;help,get_rotmats

  for j=0,jv do begin
    dprint,verbose=verbose,dlevel=3,dwait=10.,j,' of ',jv
    if use_rotmat then rot=reform(rotmats[*,j,*,*]) else begin
      for k=0,2 do $
        rot[*,k,2] = smooth(B[*,k],wid[j] < (nt-1),/edge_truncate)
      rot[*,*,2] = rot[*,*,2] / (sqrt(total(rot[*,*,2]^2,2)) # [1,1,1] )
      rot[*,*,1] = crossp2(rot[*,*,2],xdir)
      rot[*,*,1] = rot[*,*,1] / (sqrt(total(rot[*,*,1]^2,2)) # [1,1,1] )
      rot[*,*,0] = crossp2(rot[*,*,1],rot[*,*,2])
      if keyword_set(get_rotmats) then rotmats[*,j,*,*] = rot
    endelse

    wvp[*,j,2] = wv[*,j,0]*rot[*,0,2] + wv[*,j,1]*rot[*,1,2] + wv[*,j,2]*rot[*,2,2]
    wvp[*,j,1] = wv[*,j,0]*rot[*,0,1] + wv[*,j,1]*rot[*,1,1] + wv[*,j,2]*rot[*,2,1]
    wvp[*,j,0] = wv[*,j,0]*rot[*,0,0] + wv[*,j,1]*rot[*,1,0] + wv[*,j,2]*rot[*,2,0]
  endfor
  dprint,dlevel=3,verbose=verbose,systime(1)-time0,' Seconds'

  return,wvp
end


function rotate_wavelet,wv,B,w0,w1,w2,wid=wid

  dim = dimen(wv)
  nt  = dim[0]
  jv = dim[1]-1
  if dim[2] ne 3 then message,'Must have 3 dimensions'
  wv = reform(/over,wv,dim[0]*dim[1],dim[2])
  xdir =[1.,0.,0.]

  if keyword_set(wid)  then begin
    dprint,dlevel=2,verbose=verbose,'Computing Rotation matrices.'
    w2 = fltarr(dim[0],dim[1],dim[2])
    for j=0,jv do  for k=0,2 do  w2[*,j,k] = smooth(B[*,k],wid[j],/edge_truncate)

    w2 = reform(w2,/over,dim[0]*dim[1],dim[2])
    w2 = w2/( sqrt(total(w2^2,2)) # [1,1,1] )
    w1 = crossp2(w2,xdir)
    w1 = w1/( sqrt(total(w1^2,2)) # [1,1,1] )
    w0 = crossp2(w1,w2)
  endif
  dprint,dlevel=2,verbose=verbose,'Rotating wavelets.'

  wvp = make_array(dim[0]*dim[1],dim[2],/complex,/noz)
  wvp[*,2] = wv[*,0]*w2[*,0] + wv[*,1]*w2[*,1] + wv[*,2]*w2[*,2]
  wvp[*,1] = wv[*,0]*w1[*,0] + wv[*,1]*w1[*,1] + wv[*,2]*w1[*,2]
  wvp[*,0] = wv[*,0]*w0[*,0] + wv[*,1]*w0[*,1] + wv[*,2]*w0[*,2]
  wvp = reform(/over,wvp,dim[0],dim[1],dim[2])
  wv =  reform(/over,wv,dim[0],dim[1],dim[2])
  return,wvp

end


function wave_data,varname,frange=frange,param=param,magrat=magrat, $
  trange=tr,data=data,dimennum=dimennum, tplot_prefix=tplot_prefix, $
  verbose=verbose

  if size(/type,varname) eq 7  then begin
    name=keyword_set(tplot_prefix) ? tplot_prefix : varname

    get_data,varname,time,data

    ;if keyword_set(normname) then normval=data_cut(normname,time)

    if n_elements(dimennum) eq 1 then begin
      data=data[*,dimennum]
      name=name+strcompress(/rem,string('(',dimennum,')'))
    endif

    if keyword_set(rbin) then begin
      n = n_elements(time)
      nrbin = n/rbin
      time = rebin(time[0:nrbin*rbin-1],nrbin)
      data    = rebin(data[0:nrbin*rbin-1,*],nrbin,3)
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
        data=data[rr[0]:rr[1],*]
      endif else begin
        trange=minmax(time_double(trange))
        w = where(time le trange[1] and time ge trange[0],c)
        if c eq 0 then message,'No data in that time range'
        time = time[w]
        data = data[w,*]
      endelse
    endif

  endif else name = keyword_set(tplot_prefix) ? tplot_prefix : ''

  dtime=(time-shift(time,1))[1:*]
  dt = average(dtime)
  printdat,/pgmtrace,dt
  printdat,/pgmtrace,minmax(dtime),'dt range'
  if total(abs(minmax(dtime)/dt-1)) gt .05 then message,'invalid time sampling'


  interp_gap,time,data,index=bad_index ,count=nbad_index  ,verbose=verbose   ; remove nans
  if 1 then printdat,/pgmtrace,bad_index,'bad index'

  pad = 2


  wv=wavelet2(data,dt,pad=pad,period=period,frange=frange,prange=prange,$
    verbose=verbose,param=param)


  data_ptr = {name:name, $
    dt:dt, $
    param: param, $
    period:period, $
    freq:1/period, $
    time: ptr_new(), $
    badtime: ptr_new(), $
    data: ptr_new(), $
    wv: ptr_new()  }

  dim = size(/dimen,wv)
  nt = dim[0]
  jv1 = dim[1]
  nk = (n_elements(dim) eq 3) ? dim[2] : 1

  badtime = bytarr(nt)
  if keyword_set(nbad_index)  then   badtime[bad_index] = 1

  if keyword_set(magrat) then begin
    dprint,'Doing magnitude now'
    wvmag= wavelet2(sqrt(total(data^2,2)),dt,pad=pad,period=period,frange=frange,prange=prange,$
      verbose=verbose,param=param)
    str_element,/add,data_ptr,'wvmag',ptr_new(/no_copy,wvmag)
  endif

  data_ptr.data = ptr_new(/no_copy,data)
  data_ptr.time = ptr_new(/no_copy,time)
  data_ptr.wv = ptr_new(/no_copy,wv)
  data_ptr.badtime = ptr_new(/no_copy,badtime)

  return,data_ptr
end


pro wav_tplot,p,avg_period,tplot_prefix=tplot_prefix,rotate_pow=rotate_pow,cross_corr=cross_corr

  name = p.name
  period = p.period
  dt = p.dt
  yax = keyword_set(per_axis) ? period : p.freq
  ysubtitle = keyword_set(per_axis) ? 'Seconds' : 'f [Hz]'
  mm = minmax(yax)

  dim = size(/dimen,*p.wv)
  nt = dim[0]
  jv1 = dim[1]
  nk = (n_elements(dim) eq 3) ? dim[2] : 1

  if not keyword_set(avg_period) then avg_period=12.
  if 1 then printdat,/pgmtrace,avg_period,/val,'Num period'

  if not keyword_set(wid) then   wid = 3 > round(period/2/dt*avg_period)*2+1 < (nt-1)
  if 1 then printdat,/pgmtrace,wid,'width'

  if 1 then begin
    mask = *p.badtime # replicate(1.,jv1)
    bad_index = where(*p.badtime,nbad_index)
    if nbad_index ne 0 then  mask[bad_index,*] = 1.
    mask[0,*] = 1.
    mask[nt-1,*] = 1.
    smooth_wavelet,mask,wid  ;,/gaussian
    msk = mask gt .2
    mask = ([1.,!values.f_nan])[msk]
  endif else mask=1.

  if not keyword_set(normconst) then normconst=1.
  ;printdat,normconst,'normconst'

  if keyword_set(foo) then stop

  if keyword_set(normval) then begin
    if n_elements(normval) eq nt then begin
      dprint,'Calculating Normalization'
      normpow = normval # replicate(normconst,jv1)
      smooth_wavelet,normpow,wid
    endif
    if n_elements(normval) eq 1 then normpow=normval
  endif else normpow=normconst

  if keyword_set(foo) then stop
  ;printdat,normpow,'Normpow'


  tsfx=''

  if keyword_set(frac) then begin
    normpow = ( (nk eq 1) ? B^2 : total(B^2,2) ) # replicate(1,jv1)
    dprint,'Fraction Normalization'
    smooth_wavelet,normpow,wid
    normpow = 1/normpow
    tsfx=tsfx+'/<B!u2!n>'
  endif

  ;printdat,normpow,'Normpow'

  if keyword_set(kolom) then begin
    normpow = normpow / (replicate(1.,nt) # (kolom*period^(5./3.)) )
    tsfx=tsfx+'/P!dK!n'
    if not keyword_set(zrange) then  zrange = [.1,10]
  endif else begin
    if keyword_set(tint_pow) then begin
      normpow = normpow / (replicate(1.,dim[0]) # (period^(tint_pow)) )
      tsfx=tsfx+'*f'
      if tint_pow ne 1 then $
        tsfx=tsfx+'!u'+string(tint_pow,format='(f4.2)')+'!d'
      if not keyword_set(zrange) then  zrange = [.01,1]
    endif
  endelse
  ;printdat,normpow,'Normpow'

  for k=0,nk-1 do wv[*,*,k] = wv[*,*,k] * sqrt(normpow)

  if keyword_set(wvmag) then wvmag = wvmag * sqrt(normpow)

  if nk eq 1 then pow = abs(wv)^2 else pow = total(abs(wv)^2,3)

  if not keyword_set(zrange) then zrange = roundsig(10^(average(alog(pow*mask),/nan)/alog(10)),sigfi=.2) * [.1,10]

  ztitle=''
  r = keyword_set(resolution) ? resolution : 0
  rdtime = reduce_tres(time,r)
  polopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zrange:[-1,1],zlog:0,zstyle:1,ztitle:ztitle,ysubtitle:ysubtitle}
  powopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zlog:1,zstyle:1,zrange:zrange,ztitle:ztitle,ysubtitle:ysubtitle}

  powopts.ztitle='P!dTot!n'+tsfx
  store_data,name+'_wv_pow',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts

  if nk eq 1  then return     ; scaler quantities...
  if nk eq 2 then stop

  if keyword_set(magrat) then begin
    powb = abs(wvmag)^2
    ratopts=polopts
    ztitle='P!dmag!n/P!dtot!n'
    pol = powb/pow
    smooth_wavelet,pol,wid    & ztitle = '<'+ztitle+'>'
    ratopts.ztitle=ztitle
    ratopts.zrange=[0,1]
    store_data,name+'_wv_rat_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
  endif

  if 0 then begin
    smooth_wavelet,pow,wid
    powopts.ztitle='<P!dTot!n>'+tsfx
    store_data,name+'_wvs_pow',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
    if keyword_set(magrat) then begin
      smooth_wavelet,powb,wid
      ratopts.ztitle='<P!dmag!n>/<P!dtot!n>'
      pol = powb/pow
      store_data,name+'_wvs_rat_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
    endif
  endif


  if keyword_set(rotate_pow) then begin
    ;   wv = rotate_wavelet(wv,B,w0,w1,w2,wid= keyword_set(w2) ? 0 :wid)
    wv = rotate_wavelet2(wv,dir=B,rotmat=rotmat,wid=wid,get_rotmat=arg_present(rotmat) and keyword_set(get_rotmat),verbose=verbose)

    if 1 then dprint,'Computing power and polarization for TPLOT'

    i=complex(0,1)
    powr = abs(wv[*,*,0]+i*wv[*,*,1])^2
    powl = abs(wv[*,*,0]-i*wv[*,*,1])^2
    powb = abs(wv[*,*,2])^2
    ;   smooth_wavelet,powb,wid
    ;   pow = (abs(wv[*,*,0])^2 + abs(wv[*,*,1])^2)
    ;   smooth_wavelet,pow,wid

    pol = powb/(powb+powl+powr)
    smooth_wavelet,pol,wid
    ratopts=polopts
    ratopts.ztitle='<P!d||!n/P!dtot!n>'
    ratopts.zrange=[0,1]
    store_data,name+'_wv_pol_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts

    ;   pol = imaginary(wv[*,*,0]*conj(wv[*,*,1]))/pow*2
    pol = (powr-powl)/(powl+powr)
    ;   polopts.ztitle='!19s!x!dp!n'
    ;   store_data,name+'_wv_pol2_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts
    smooth_wavelet,pol,wid
    polopts.ztitle='<!19s!x!dp!n>'
    store_data,name+'_wv_pol_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts

    smooth_wavelet,powr,wid
    smooth_wavelet,powl,wid
    smooth_wavelet,powb,wid

    if 0 then begin
      pol = powb/(powb+powl+powr)
      ratopts.ztitle='<P!d||!n>/<P!dtot!n>'
      store_data,name+'_wvs_pol_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts

      pol = (powr-powl)/(powr+powl)
      polopts.ztitle='!19s!x!d<p>!n'
      store_data,name+'_wvs_pol_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts
    endif

    if keyword_set(all) then begin
      i=complex(0,1)
      powopts.ztitle='P!dB!n'+tsfx
      store_data,name+'_wv_pow_par',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=powopts
      powopts.ztitle='P!dperp!n'+tsfx
      store_data,name+'_wv_pow_perp',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
      pow = abs(wv[*,*,0]+i*wv[*,*,1])^2/2
      powopts.ztitle='P!dR!n'+tsfx
      store_data,name+'_wv_pow_r',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
      pow = abs(wv[*,*,0]-i*wv[*,*,1])^2/2
      powopts.ztitle='P!dL!n'+tsfx
      store_data,name+'_wv_pow_l',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
    endif

    if keyword_set(cross_cor1) then begin
      i=complex(0,1)
      cross_corr_wavelet,wv[*,*,0]+i*wv[*,*,1],wv[*,*,0]-i*wv[*,*,1],wid,pol,pow,powb
      ratopts.ztitle='!19g!x!dl!n'
      store_data,name+'_wv_gam_lin',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
      polopts.ztitle='C!dl!n'
      store_data,name+'_wv_coin_lin',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
      polopts.ztitle='Q!dl!n'
      store_data,name+'_wv_quad_lin',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts

      cross_corr_wavelet,wv[*,*,0],wv[*,*,1],wid,pol,pow,powb
      ratopts.ztitle='!19g!x!dp!n'
      store_data,name+'_wv_gam_cir',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
      polopts.ztitle='C!dp!n'
      store_data,name+'_wv_coin_cir',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
      polopts.ztitle='Q!dp!n'
      store_data,name+'_wv_quad_cir',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts
    endif
    if keyword_set(cross_cor2) then begin
      cross_corr_wavelet,wv[*,*,2],wv[*,*,0]+i*wv[*,*,1],wid,pol,pow,powb
      ratopts.ztitle='!19g!x!dpr!n'
      store_data,name+'_wv_gam_pr',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
      polopts.ztitle='C!dpr!n'
      store_data,name+'_wv_coin_pr',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
      polopts.ztitle='Q!dpr!n'
      store_data,name+'_wv_quad_pr',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts

      cross_corr_wavelet,wv[*,*,2],wv[*,*,0]-i*wv[*,*,1],wid,pol,pow,powb
      ratopts.ztitle='!19g!x!dpl!n'
      store_data,name+'_wv_gam_pl',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
      polopts.ztitle='C!dpl!n'
      store_data,name+'_wv_coin_pl',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
      polopts.ztitle='Q!dpl!n'
      store_data,name+'_wv_quad_pl',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts

    endif


  endif
  if keyword_set(stop) then stop


end


pro wav_data,varname, period=period,prange=prange,frange=frange, $
  param=param,avg_period=avg_period, $,
  nmorlet = nmorlet, $
  tplot_prefix=tplot_prefix, $
  data=b, wavelet=wv, time=time, mask=msk,$
  magrat=magrat, $
  per_axis=per_axis, $
  kolom=kolom, normval=normval, normconst=normconst,normname=normname, $
  get_components=get_components, $
  tint_pow = tint_pow, $
  fraction = frac, $
  rotmat=rotmat, get_rotmat=get_rotmat, $
  wid=wid, $
  hermition_k = hermition_k, $
  dimennum=dimennum,rotate_pow=rotate_pow, $
  maxpoints=maxpoints,rbin=rbin,$
  cross1=cross_cor1, cross2=cross_cor2, $
  trange=tr,resolution=resolution,verbose=verbose, $
  display_object=display_obj

  t0=systime(1)
  if keyword_set(varname)   then begin

    if keyword_set(nmorlet) then begin
      param = nmorlet * 2* !dpi
    endif

    name=keyword_set(tplot_prefix) ? tplot_prefix : (tnames(varname))[0]

    get_data,name,time,B
    if(n_elements(time) eq 1 and time[0] eq 0) then begin
      msg = 'Variable: '+name+': has no data.'
      dprint, verbose = verbose,  dlevel = 0,  msg, display_obj=display_obj
      return
    endif

    if keyword_set(normname) then normval=data_cut(normname,time)

    if n_elements(dimennum) eq 1 then begin
      B=B[*,dimennum]
      name=name+strcompress(/rem,string('(',dimennum,')'))
    endif

    if n_elements(frange) eq 2 then prange = reverse(1/double(frange))

    if keyword_set(rbin) then begin
      n = n_elements(time)
      nrbin = n/rbin
      time = rebin(time[0:nrbin*rbin-1],nrbin)
      B    = rebin(B[0:nrbin*rbin-1,*],nrbin,3)
    endif

    if not keyword_set(maxpoints) then maxpoints =2l^15; maxpoints =  32000l

    if n_elements(time) gt maxpoints and not keyword_set(tr) then begin
      msg = 'Too many time samples, (Pts:' + strtrim(n_elements(time),2) + ',Limit: '+ strtrim(maxpoints,2) + '). Please select a different time range'
      dprint,verbose=verbose,dlevel=0, display_obj=display_obj,msg
      ctime,tr,/silent
    endif

    if  keyword_set(tr) then trange = tr    ; else get_timespan,trange

    if keyword_set(trange) then begin
      if n_elements(trange) eq 1 then begin
        mm = min(abs(time-trange[0]),w)
        rr = [0,maxpoints-1]- maxpoints/2 + w
        rr = 0 > rr < (n_elements(time)-1)
        time=time[rr[0]:rr[1]]
        B=B[rr[0]:rr[1],*]
        trange= minmax(time)
        dprint,verbose=verbose,dlevel=2,'rr=',rr
      endif else begin

        trange=minmax(time_double(trange))
        w = where(time le trange[1] and time ge trange[0],c)

        ;I took out the loop sanitizing the time range selection when fixing this. Users can select a new time range and re-call the routine. --pcruce
        if c le 0 then begin
          msg = 'Variable: '+name+': Not enough data in time range: '+$
            time_string(trange[0], /msec)+' -- '+time_string(trange[1], /msec)
          dprint,  verbose = verbose, dlevel = 0, msg, display_obj=display_obj
          return
        endif

        if c gt maxpoints then begin
          msg = 'Too many time samples. (Pts:' + strtrim(c,2) + ',Limit: '+ strtrim(maxpoints,2) + '). Please select a different time range'
          dprint, verbose = verbose, dlevel = 0, msg, display_obj=display_obj
          return
        endif

        time = time[w]
        B = B[w,*]
      endelse
    endif

    ;if keyword_set(interp_time) then begin
    ;  nt = size(/n_elements,interp_time)
    ;  dim = size(/dimen,b)
    ;  b2 = replicate(b[1],nt, (n_elements(dim) eq 2) ? dim[1] : 1)
    ;  for d=0,d2-1 do $
    ;    b2[*,d] = interp(time,b[*,d],interp_time)
    ;  b = temporary(b2)
    ;  help,b
    ;endif

  endif else name = keyword_set(tplot_prefix) ? tplot_prefix : ''

  dtime=(time-shift(time,1))[1:*]
  dt = average(dtime)
  dprint,dlevel=2,verbose=verbose,'Performing Wavelet analysis for ',n_elements(time),' samples.',display_obj=display_obj
  dprint,dlevel=3,verbose=verbose,time,dt,minmax(dtime),/phelp
  if n_elements(tgap_threshold) ne 1 then tgap_threshold = 0.1
  if total(abs(minmax(dtime)/dt-1)) gt tgap_threshold then begin    ; insert missing data values
    resample=1
  endif
  if keyword_set(resample) then begin
    msg = 'Warning!!! Resampling data onto a uniform period'
    dprint,verbose=verbose,dlevel=1,msg, display_obj=display_obj
    dsample = round(dtime/median(dtime))
    samples = [0,total(/cumulative,/preserve,dsample)]
    re_time = replicate(!values.d_nan,max(samples)+1)
    re_time[samples] = time
    time=temporary(re_time)
    interp_gap,dindgen(n_elements(time)),time
    dim = size(/dimension,B)
    dim[0] = max(samples)+1
    re_B = replicate(B[0]*!values.f_nan,dim)
    re_B[samples,*] = B
    B = temporary(re_B)
    dtime=(time-shift(time,1))[1:*]
    dt = average(dtime)
  endif

  interp_gap,time,B,index=bad_index ,count=nbad_index  ,verbose=verbose   ; remove nans
  dprint,dlevel=3,verbose=verbose,/phelp,bad_index

  pad = 2

  wv=wavelet2(B,dt,pad=pad,period=period,prange=prange,verbose=verbose,param=param)

  ;If wv is -1, then the time range is too short, return
  If(n_elements(wv) Eq 1 && wv[0] Eq -1) Then Begin
    msg = 'Time interval too short, Returning'
    dprint, verbose = verbose, dlevel = 0, msg, display_obj=display_obj
    return
  Endif

  dim = size(/dimen,wv)
  nt = dim[0]
  jv1 = dim[1]
  nk = (n_elements(dim) eq 3) ? dim[2] : 1


  if keyword_set(magrat) then begin
    dprint,verbose=verbose,dlevel=2,'Computing magnitude now'
    wvmag= wavelet2(sqrt(total(B^2,2)),dt,pad=pad,period=period,prange=prange,$
      verbose=verbose,param=param)
  endif


  yax = keyword_set(per_axis) ? period : 1/period
  ysubtitle = keyword_set(per_axis) ? 'Seconds' : 'f (Hz)'
  mm = minmax(yax)

  if n_elements(avg_period) eq 0  then avg_period=6.
  dprint,verbose=verbose,dlevel=3,/phelp,avg_period

  ;if not keyword_set(wid) then  wid = 3 > round(period/2/dt*avg_period)*2+1 < (nt-1)
  if not keyword_set(wid) then  wid = (period/2/dt*avg_period)*2+1

  wid = long(wid > 3)


  dprint,dlevel=3,verbose=verbose,/phelp,wid

  if 0 then begin
    mask = replicate(1.,nt,jv1)
    if nbad_index ne 0 then  mask[bad_index,*] = 0.
    mask[0,*] = -wid
    mask[nt-1,*] = -wid
    smooth_wavelet,mask,wid
    msk = mask lt .05
    mask = ([1.,!values.f_nan])[msk]
  endif else if 0 then begin
    mask = fltarr(nt,jv1)
    if nbad_index ne 0 then  mask[bad_index,*] = 1.
    mask[0,*] = 1.
    mask[nt-1,*] = 1.
    smooth_wavelet,mask,wid  ;,/gaussian
    msk = mask gt .2
    mask = ([1.,!values.f_nan])[msk]
  endif else mask=1.

  if not keyword_set(normconst) then normconst=1.
  ;printdat,normconst,'normconst'

  if keyword_set(foo) then stop

  if keyword_set(normval) then begin
    if n_elements(normval) eq nt then begin
      dprint,dlevel=2,verbose=verbose,'Calculating Normalization'
      normpow = normval # replicate(normconst,jv1)
      smooth_wavelet,normpow,wid
    endif
    if n_elements(normval) eq 1 then normpow=normval
  endif else normpow=normconst


  tsfx=''

  if keyword_set(frac) then begin
    normpow = ( (nk eq 1) ? B^2 : total(B^2,2) ) # replicate(1,jv1)
    dprint,'Fraction Normalization'
    smooth_wavelet,normpow,wid
    normpow = 1/normpow
    tsfx=tsfx+'/<B!u2!n>'
  endif

  ;printdat,normpow,'Normpow'

  if keyword_set(kolom) then begin
    normpow = normpow / (replicate(1.,nt) # (kolom*period^(5./3.)) )
    tsfx=tsfx+'/P!dK!n'
    if not keyword_set(zrange) then  zrange = [.1,10]
  endif else begin
    if keyword_set(tint_pow) then begin
      normpow = normpow / (replicate(1.,dim[0]) # (period^(tint_pow)) )
      tsfx=tsfx+'*f'
      if tint_pow ne 1 then tsfx=tsfx+'!u'+string(tint_pow,format='(f4.2)')+'!d'
      if not keyword_set(zrange) then  zrange = [.0001,.1]
    endif
  endelse
  ;printdat,normpow,'Normpow'

  for k=0,nk-1 do wv[*,*,k] = wv[*,*,k] * sqrt(normpow)

  if keyword_set(wvmag) then wvmag = wvmag * sqrt(normpow)

  if nk eq 1 then pow = abs(wv)^2 else pow = total(abs(wv)^2,3)

  if not keyword_set(zrange) then  $
    zrange = roundsig(10^(average(alog(pow*mask),/nan)/alog(10)),sigfi=.2) * [.1,10]



  ztitle=''
  r = keyword_set(resolution) ? resolution : 0
  rdtime = reduce_tres(time,r)
  polopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zrange:[-1,1],zlog:0,zstyle:1,ztitle:ztitle,ysubtitle:ysubtitle}
  powopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zlog:1,zstyle:1,zrange:zrange,ztitle:ztitle,ysubtitle:ysubtitle}

  wvs = '_wv'
  if keyword_set(nmorlet) then wvs += strtrim(fix(nmorlet),2)
  powopts.ztitle='P!dTot!n'+tsfx
  store_data,name+wvs+'_pow',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts

  if nk eq 1 then return     ; scaler quantities...
  ;if nk eq 2 then stop


  if keyword_set(get_components)  then begin
    dprint,dlevel=4,verbose=verbose,'dim=',dim,'nk=',nk
    cstr = ['x','y','z','4']
    for i=0,nk-1 do begin
      powopts.ztitle='P!d'+cstr[i]+'!n'+tsfx
      pow = (abs(wv[*,*,i])^2)
      store_data,name+'_'+cstr[i]+wvs+'_pow',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
    endfor

  endif


  if keyword_set(magrat) then begin
    powb = abs(wvmag)^2
    ratopts=polopts
    ztitle='P!dmag!n/P!dtot!n'
    pol = powb/pow
    smooth_wavelet,pol,wid    & ztitle = '<'+ztitle+'>'
    ratopts.ztitle=ztitle
    ratopts.zrange=[0,1]
    store_data,name+wvs+'_rat_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
  endif

  if 0 then begin
    smooth_wavelet,pow,wid
    powopts.ztitle='<P!dTot!n>'+tsfx
    store_data,name+wvs+'s_pow',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
    if keyword_set(magrat) then begin
      smooth_wavelet,powb,wid
      ratopts.ztitle='<P!dmag!n>/<P!dtot!n>'
      pol = powb/pow
      store_data,name+wvs+'s_rat_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
    endif
  endif

  ratopts=polopts
  ratopts.ztitle='<P!d||!n/P!dtot!n>'
  ratopts.zrange=[0,1]

  if nk eq 2 then begin
    i=complex(0,1)
    powr = abs(wv[*,*,0]+i*wv[*,*,1])^2
    powl = abs(wv[*,*,0]-i*wv[*,*,1])^2
    pol = (powr-powl)/(powl+powr)
    ;   polopts.ztitle='!19s!x!dp!n'
    ;   store_data,name+wvs+'_pol2_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts
    smooth_wavelet,pol,wid
    polopts.ztitle='<!19s!x!dp!n>'
    store_data,name+wvs+'_pol_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts


  endif

  if keyword_set(rotate_pow) then begin
    ;   wv = rotate_wavelet(wv,B,w0,w1,w2,wid= keyword_set(w2) ? 0 :wid)
    wv = rotate_wavelet2(wv,dir=B,rotmat=rotmat,wid=wid,get_rotmat=arg_present(rotmat) and keyword_set(get_rotmat),verbose=verbose)

    dprint,dlevel=2,verbose=verbose,'Computing power and polarization for TPLOT'

    i=complex(0,1)
    powr = abs(wv[*,*,0]+i*wv[*,*,1])^2
    powl = abs(wv[*,*,0]-i*wv[*,*,1])^2   ; should divide by 2?
    powb = abs(wv[*,*,2])^2
    ;   smooth_wavelet,powb,wid
    ;   pow = (abs(wv[*,*,0])^2 + abs(wv[*,*,1])^2)
    ;   smooth_wavelet,pow,wid

    pol = powb/(powb+powl+powr)
    smooth_wavelet,pol,wid
    store_data,name+wvs+'_pol_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts

    ;   pol = imaginary(wv[*,*,0]*conj(wv[*,*,1]))/pow*2
    pol = (powr-powl)/(powl+powr)
    ;   polopts.ztitle='!19s!x!dp!n'
    ;   store_data,name+wvs+'_pol2_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts
    smooth_wavelet,pol,wid
    polopts.ztitle='<!19s!x!dp!n>'
    store_data,name+wvs+'_pol_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts

    smooth_wavelet,powr,wid
    smooth_wavelet,powl,wid
    smooth_wavelet,powb,wid

    if 0 then begin
      pol = powb/(powb+powl+powr)
      ratopts.ztitle='<P!d||!n>/<P!dtot!n>'
      store_data,name+wvs+'s_pol_par',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts

      pol = (powr-powl)/(powr+powl)
      polopts.ztitle='!19s!x!d<p>!n'
      store_data,name+wvs+'s_pol_perp',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts
    endif

    if keyword_set(all) then begin
      i=complex(0,1)
      powopts.ztitle='P!dB!n'+tsfx
      store_data,name+wvs+'_pow_par',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=powopts
      powopts.ztitle='P!dperp!n'+tsfx
      store_data,name+wvs+'_pow_perp',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
      pow = abs(wv[*,*,0]+i*wv[*,*,1])^2/2
      powopts.ztitle='P!dR!n'+tsfx
      store_data,name+wvs+'_pow_r',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
      pow = abs(wv[*,*,0]-i*wv[*,*,1])^2/2
      powopts.ztitle='P!dL!n'+tsfx
      store_data,name+wvs+'_pow_l',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=powopts
    endif


  endif

  ;hermition=1
  if keyword_set(hermition_k) then begin
    ;wv_hm = dcomplexarr(nt,jv1,nk,nk)
    dprint,yax
    wv_hm = dcomplexarr(nt,nk,nk)
    for j=0,nk-1 do for k=0,nk-1 do wv_hm[*,j,k] = conj(wv[*,hermition_k,j]) * wv[*,hermition_k,k]
    wv_pow = wv_hm[*,0,0] + wv_hm[*,1,1] + wv_hm[*,2,2]
    dbb = reform(wv_hm,nt,nk*nk)
    dbb = dbb[*,[0,4,8,1,2,5]]
    printdat,wv_pow,wv_hm
    dprint,dlevel=2,'Herm Freq = ',yax[hermition_k]
    store_data,name+wvs+'_H_pow',time,wv_pow
    ;  store_data,name+wvs+'_H_real',time,float(dbb)
    store_data,name+wvs+'_HN_real',time,float(dbb)/ (wv_pow # [1,1,1,1,1,1])
    ;  store_data,name+wvs+'_H_imag',time,imaginary(dbb)
    store_data,name+wvs+'_HN_imag',time,imaginary(dbb)/ (wv_pow # [1,1,1,1,1,1])
    if 1 then begin
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
      eigenvalues = [[z1],[z2],[z3]]
    endif else   begin
      eigenvalues = fltarr(nt,3)
      for n=0,nt-1 do begin
        array = reform(wv_hm[n,*,*])
        H = LA_ELMHES(array, q,   PERMUTE_RESULT = permute, SCALE_RESULT = scale)
        ; Compute eigenvalues, T, and QZ arrays:
        eigenvalues[n,*] = LA_HQR(h, q, PERMUTE_RESULT = permute)
        ; Compute eigenvectors corresponding to
        ; the first 3 eigenvalues.
        ;   select = [1, 1, 1, REPLICATE(0, nk - 3)]
        ;   eigenvectors = LA_EIGENVEC(H, Q,  PERMUTE_RESULT = permute, SCALE_RESULT = scale ) ;,   EIGENINDEX = eigenindex,  SELECT = select)
        ;   PRINT, 'LA_EIGENVEC eigenvalues:'
        ;   PRINT, eigenvalues[eigenindex]
      endfor
    endelse
    store_data,name+wvs+'_H_eval',time,float(eigenvalues)


  endif


  if keyword_set(cross_cor1) then begin
    i=complex(0,1)
    cross_corr_wavelet,wv[*,*,0]+i*wv[*,*,1],wv[*,*,0]-i*wv[*,*,1],wid,pol,pow,powb,gsmooth=1
    ratopts.ztitle='!19g!x!dl!n'
    store_data,name+wvs+'_gam_lin',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
    polopts.ztitle='C!dl!n'
    store_data,name+wvs+'_coin_lin',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
    polopts.ztitle='Q!dl!n'
    store_data,name+wvs+'_quad_lin',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts

    cross_corr_wavelet,wv[*,*,0],wv[*,*,1],wid,pol,pow,powb,gsmooth=1
    ratopts.ztitle='!19g!x!dp!n'
    store_data,name+wvs+'_gam_cir',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
    polopts.ztitle='C!dp!n'
    store_data,name+wvs+'_coin_cir',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
    polopts.ztitle='Q!dp!n'
    store_data,name+wvs+'_quad_cir',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts
  endif
  if keyword_set(cross_cor2) then begin
    cross_corr_wavelet,wv[*,*,2],wv[*,*,0]+i*wv[*,*,1],wid,pol,pow,powb
    ratopts.ztitle='!19g!x!dpr!n'
    store_data,name+wvs+'_gam_pr',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
    polopts.ztitle='C!dpr!n'
    store_data,name+wvs+'_coin_pr',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
    polopts.ztitle='Q!dpr!n'
    store_data,name+wvs+'_quad_pr',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts

    cross_corr_wavelet,wv[*,*,2],wv[*,*,0]-i*wv[*,*,1],wid,pol,pow,powb
    ratopts.ztitle='!19g!x!dpl!n'
    store_data,name+wvs+'_gam_pl',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
    polopts.ztitle='C!dpl!n'
    store_data,name+wvs+'_coin_pl',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
    polopts.ztitle='Q!dpl!n'
    store_data,name+wvs+'_quad_pl',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts

  endif

  dprint,'Finished in '+strtrim(systime(1)-t0,2)+' seconds.'
  if keyword_set(stop) then stop

end


