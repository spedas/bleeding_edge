pro correlate_wavelet,b,v,width,time,yscale,thresh_mask=thresh_mask, $
   prefix=prefix,resolution=resolution

jv1 = n_elements(width)
dimb = size(/dimen,b)
r = keyword_set(resolution) ? resolution : 0
rdtime = reduce_tres(time,r)

;acorr = make_array(/float,/nozer,dim=dimb)
bcorr = make_array(/float,/nozer,dim=dimb)
;ccorr = make_array(/float,/nozer,dim=dimb)
rcorr = make_array(/float,/nozer,dim=dimb)
for j=0,jv1-1 do begin
   correlate_vect,double(b[*,j]),double(v[*,j]),width[j],a=ac,b=bc,c=cc,r=rr
;   acorr[*,j] = ac
   bcorr[*,j] = bc
;   ccorr[*,j] = abs(cc)^2
   rcorr[*,j] = abs(rr)^2
endfor


if not keyword_set(prefix) then prefix=''
opts = {spec:1,ylog:1,yrange:minmax(yscale),ystyle:1,zrange:[-1.1,1.1]}
;store_data,prefix+'_ac',data={x:rdtime,y:reduce_tres(acorr,r),v:yscale},dlim=opts
store_data,prefix+'_bc',data={x:rdtime,y:reduce_tres(bcorr,r),v:yscale},dlim=opts
;opts.zrange=[0,1]
;store_data,prefix+'_cc',data={x:rdtime,y:reduce_tres(ccorr,r),v:yscale},dlim=opts
opts.zrange=[0,1]
store_data,prefix+'_rc',data={x:rdtime,y:reduce_tres(rcorr,r),v:yscale},dlim=opts

if keyword_set(thresh_mask) then begin
  w = where(rcorr lt thresh_mask,count)
  if count gt 0 then bcorr[w]=!values.f_nan
opts.zrange=[-1,1]
store_data,prefix+'_bcm',data={x:rdtime,y:reduce_tres(bcorr,r),v:yscale},dlim=opts
endif

end




pro tplot_alfven_data,time,wb,wv,period,wid,mask=mask,  $
   resolution=resolution,prefix=prefix,verbose=verbose,  $
   kolom=kolom,  $
   gamthresh=gamthresh, $
   allcross=allcross, $
   crosshel=crosshel, cor1=correlate1, cor2=correlate2, vxb=vxb, stop = stop

; if keyword_set(verbose) then $
  dprint,'Computing power and polarization for TPLOT'

r = keyword_set(resolution) ? resolution : 0
rdtime = reduce_tres(time,r)
yax = keyword_set(per_axis) ? period : 1/period
ytitle = keyword_set(per_axis) ? 'Period (Sec)' : 'f (Hz)' 
mm = minmax(yax)
ztitle=''
polopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zrange:[-1,1],zlog:0,zstyle:1,ytitle:ytitle,ztitle:ztitle}
powopts = {spec:1,yrange:mm,ylog:1,ystyle:1,no_interp:1,zrange:10.^[-1,1],zlog:1,zstyle:1,ytitle:ytitle,ztitle:ztitle}
ratopts = polopts  & ratopts.zrange=[0,1]

if keyword_set(kolom) then tsfx='/P!dk!n'
if not keyword_set(tsfx) then tsfx=''

if not keyword_set(mask) then mask=1.

dim = size(/dimen,wv)
jv1 = dim[1]
nt  = dim[0]

if keyword_set(stop) then stop


if keyword_set(crosshel) or keyword_set(allcross) then begin
w_p = (wb - wv )/2
w_a = (wb + wv )/2

apow = (abs(w_a[*,*,0])^2 + abs(w_a[*,*,1])^2)/2
ppow = (abs(w_p[*,*,0])^2 + abs(w_p[*,*,1])^2)/2

if keyword_set(allcross) then begin
  powopts.ztitle='P!dA+!n'+tsfx
  store_data,prefix+'_xwv_pow_p',data={x:rdtime,y:reduce_tres(ppow*mask,r),v:yax},dlim=powopts
  powopts.ztitle='P!dA-!n'+tsfx
  store_data,prefix+'_xwv_pow_a',data={x:rdtime,y:reduce_tres(apow*mask,r),v:yax},dlim=powopts
endif

pow = apow+ppow
pol = (apow-ppow)/pow
polopts.ztitle='<!19s!x!dc!n>'
store_data,prefix+'_xwv_d_p-a',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts

if keyword_set(allcross) then begin
  polopts.ztitle='<!19s!x!dp+!n>'
  pol = imaginary(w_p[*,*,0]*conj(w_p[*,*,1]))/ppow
  for j=0,jv1-1 do  if wid[j] gt 1 then  pol[*,j] = smooth(pol[*,j],wid[j],/nan,/edge)
  store_data,prefix+'_xwvp(p)',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts

  polopts.ztitle='<!19s!x!dp-!n>'
  pol = imaginary(w_a[*,*,0]*conj(w_a[*,*,1]))/apow
  for j=0,jv1-1 do  if wid[j] gt 1 then  pol[*,j] = smooth(pol[*,j],wid[j],/nan,/edge)
  store_data,prefix+'_xwvp(a)',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=polopts
endif

endif

if keyword_set(vxb) then begin
  wvxb = crossp3(reform(wv,nt*jv1,3),reform(conj(wb),nt*jv1,3))
  wvxb = reform(wvxb,nt,jv1,3)
  apow = total(abs(wv)^2,3)
  ppow = total(abs(wb)^2,3)
  wvxb = total(abs(wvxb),3)/(apow+ppow)
  store_data,prefix+'_vxb',data={x:rdtime,y:reduce_tres(wvxb*mask,r),v:yax},dlim=ratopts
;stop
endif


if keyword_set(correlate1) then begin
   i =complex(0,1)
   correlate_wavelet,wb[*,*,0]+i*wb[*,*,1],wv[*,*,0]+i*wv[*,*,1], $
      wid,time,1/period,prefix=prefix+'_r',thresh_mask=gamthresh,resolution=resolution

   correlate_wavelet,wb[*,*,0]-i*wb[*,*,1],wv[*,*,0]-i*wv[*,*,1], $
      wid,time,1/period,prefix=prefix+'_l',thresh_mask=gamthresh,resolution=resolution

endif

if keyword_set(correlate2) then begin
   i =complex(0,1)
   cross_corr_wavelet,wv[*,*,0]+i*wv[*,*,1],wb[*,*,0]+i*wb[*,*,1],wid,  pol,pow,powb ,crat
   ratopts.ztitle='!19g!x!dr!n'
   store_data,prefix+'_r_wv_gam_lin',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
   polopts.ztitle='C!dr!n'
   store_data,prefix+'_r_wv_coin_lin',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
   polopts.ztitle='Q!dr!n'
   store_data,prefix+'_r_wv_quad_lin',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts
   polopts.ztitle='Crat!dr!n'
   if keyword_set(gamthresh) then tmask= ([!values.f_nan,1.])[pol gt gamthresh] else tmask = 1.
   store_data,prefix+'_r_wv_crat_lin',data={x:rdtime,y:reduce_tres(crat*tmask,r),v:yax},dlim=polopts
     
   cross_corr_wavelet,wv[*,*,0]-i*wv[*,*,1],wb[*,*,0]-i*wb[*,*,1],wid,  pol,pow,powb ,crat
   ratopts.ztitle='!19g!x!dl!n'
   store_data,prefix+'_l_wv_gam_lin',data={x:rdtime,y:reduce_tres(pol*mask,r),v:yax},dlim=ratopts
   polopts.ztitle='C!dl!n'
   store_data,prefix+'_l_wv_coin_lin',data={x:rdtime,y:reduce_tres(pow*mask,r),v:yax},dlim=polopts
   polopts.ztitle='Q!dl!n'
   store_data,prefix+'_l_wv_quad_lin',data={x:rdtime,y:reduce_tres(powb*mask,r),v:yax},dlim=polopts
   polopts.ztitle='Crat!dl!n'
   if keyword_set(gamthresh) then tmask= ([!values.f_nan,1.])[pol gt gamthresh] else tmask = 1.
   store_data,prefix+'_l_wv_crat_lin',data={x:rdtime,y:reduce_tres(crat*tmask,r),v:yax},dlim=polopts
endif


end



pro tplot_quick_alfven,save,_extra=ex
printdat,ex,'_extra'
if not keyword_set(prefix) then prefix='vb'

if save.interp_wv then begin

message,'not working yet!'
  wv = *save.wb
  dim = dimen(wv)
  printdat,dim
  dprint,'Interpolating wavelet'
  for j=0,dim[1]-1 do $ 
     for k=0,dim[2]-1 do $
        wv = interpol(*save.wv[*,j,k],*save.timev,*save.timeb)
  mask = interpol( ([1,!values.f_nan])[*save.v_msk] ,*save.timev,*save.timeb)
  mask = ([1,!values.f_nan])[*save.b_msk or mask]
  tplot_alfven_data,*save.timeb,*save.wb,wv,*save.period,*save.width, $
     mask=mask,prefix=prefix,_extra=ex

endif else begin 
  mask = ([1,!values.f_nan])[*save.b_msk or *save.v_msk]
  tplot_alfven_data,*save.timeb,*save.wb,*save.wv,*save.period,*save.width, $
     mask=mask,prefix=prefix,_extra=ex
endelse

end

; tplot_quick_alfven,save




pro alfven_data,Bname=bname,Vname=vname,Nname=nname,verbose=verbose, $
   prange=prange,save=save,avg_periods=avg_period,maxpoint=maxp,trange=trange, $
   resolution=resolution,recomp=recomp,interp_wv=interp_wv,_extra=ex


if not keyword_set(Bname) then bname = (tnames('wi_B3 magf',/all))[0]
if not keyword_set(vname) then Vname = 'Vp'
if not keyword_set(nname) then Nname = 'Np'

if not keyword_set(prange) then prange = [6,1000.]

kolom = .01
mu0 = 4*!pi*1.609/100
mass = .0104

wav_data,bname,data=b,wavelet=wb,time=timeb,mask=b_msk,avg_period=avg_period, $
   normconst= 1./mu0/2, $
   period=period,/rotate,/magrat, $
   prange=prange,verbose=verbose,kolom=kolom,resolution=resolution, $
   maxpoint=maxp,trange=trange, $
   rotmat=rotmat,get_rotmat=not keyword_set(recomp),wid=wid
   
;zlim,bname+['_wv_pow','_wv_pow_par','_wv_pow_perp'],.001,.1,1
   
interp_wv = keyword_set(interp_wv)
if interp_wv then begin
  get_data,Vname,timev,v
  n = data_cut(Nname,timev)    
endif else begin
  timev = timeb
  n = data_cut(Nname,timev)    
  v = data_cut(vname,timev)    
endelse
   
  
 
wav_data,interp_wv ? vname :0,data=v,wavelet=wv,time=timev,mask=v_msk,avg_period=avg_period,  $
   normval = n, normconst= mass/2 , $
   period=period,/rotate, $   
   prange=prange,verbose=verbose,kolom=kolom,resolution=resolution, $
   rotmat=rotmat,wid=wid,tplot_prefix=vname
   
help,temporary(rotmat)   ; erase rotmat

prefix = bname+'_'+vname

;mask = ([1,!values.f_nan])[b_msk or v_msk]


;tplot_alfven_data,time,wb,wv,period,wid,mask=mask, $
;   resolution=resolution,prefix=prefix, interp_wv=interp_wv, $
;   verbose=verbose,/crosshel,_extra=ex   
   
s   ={wb:ptr_new(wb,/no_copy),  $
        timeb:ptr_new(timeb,/no_copy),   $
        wv:ptr_new(wv,/no_copy),   $
        n:ptr_new(n,/no_copy),  $
        timev:ptr_new(timev,/no_copy),   $
        period:ptr_new(period,/no_copy),   $
        width:ptr_new(wid),  $
        b_msk:ptr_new(b_msk,/no_copy),   $
        v_msk:ptr_new(v_msk,/no_copy),   $
        kolom:kolom , $
        interp_wv:interp_wv   }
        
tplot_quick_alfven,s,/crosshel,verbose=verbose,resolution=resolution, $    
   prefix=prefix

if arg_present(save) then save=s  else begin
  ptr_free,s.wb,s.timeb,s.wv,s.n,s.timev,s.period,s.width,s.b_msk,s.v_msk
endelse


end



