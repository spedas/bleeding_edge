;+
; PROCEDURE:
;     kgy_esa_pad_comb
; PURPOSE:
;     generates combined e PAD tplot vairables
; CALLING SEQUENCE:
;     kgy_esa_pad_comb
; OPTIONAL KEYWORDS:
; CREATED BY:
;     Yuki Harada on 2018-05-28
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2021-06-09 22:50:49 -0700 (Wed, 09 Jun 2021) $
; $LastChangedRevision: 30038 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_esa_pad_comb.pro $
;-

pro kgy_esa_pad_comb, trange=trange, gf_thld=gf_thld, thrange=thrange, erange=erange, npa=npa, suffix=suffix, mask_uv=mask_uv, cntcorr=cntcorr

  tr = timerange(trange)

  if ~keyword_set(gf_thld) or n_elements(gf_thld) ne 4 then begin
     gf_thld_esa1 = 2.e-4
     gf_thld_esa2 = 2.e-5
  endif else begin
     gf_thld_esa1 = gf_thld[0]
     gf_thld_esa2 = gf_thld[1]
  endelse
  if size(thrange,/n_ele) ne 2 then thrange = [10,80]
  if size(erange,/n_ele) ne 2 then erange = [150,250]
  if ~keyword_set(suffix) then suffix=''
  if ~keyword_set(npa) then npa = 16
  if size(cntcorr,/type) eq 0 then cntcorr = 1
  
  times = kgy_esa1_get3d(/gettimes)

  wt = where( times ge tr[0] and times lt tr[1] , nwt )
  if nwt eq 0 then begin
     dprint,'No valid ESA-S1 data in the specified time range'
     return
  endif

  times = times[wt]
  ntimes = n_elements(times)

  pads = replicate(!values.f_nan,ntimes,npa)  ;- normalized flux
  aveflux = replicate(!values.f_nan,ntimes)   ;- average flux
  padsc = replicate(!values.f_nan,ntimes,npa) ;- counts
  pangles = transpose( rebin( (findgen(npa)+.5)*180./npa , npa, ntimes) )

  times0 = replicate(!values.d_nan,8*ntimes)
  pads0 = replicate(!values.f_nan,8*ntimes,npa)  ;- normalized flux, ram 0
  aveflux0 = replicate(!values.f_nan,8*ntimes)   ;- average flux, ram 0
  padsc0 = replicate(!values.f_nan,8*ntimes,npa) ;- counts, ram0
  pangles0 = transpose( rebin( (findgen(npa)+.5)*180./npa , npa, 8*ntimes) )

  for it=0,nwt-1 do begin ;- loop through time steps
     now = times[it]
     if it mod 10 eq 0 then dprint,dlevel=1,verbose=verbose,'Comp PADs'+suffix+': ',it,' / ',nwt-1,' : '+time_string(now)

     d1 = kgy_esa1_get3d(now,sabin=1, cntcorr=cntcorr)
     d2 = kgy_esa2_get3d(now,sabin=1, cntcorr=cntcorr)

     if abs(d1.time-d2.time) gt .5d then d2.bins = 0
     if d1.type ne d2.type then d2.bins = 0
     if keyword_set(mask_uv) then if total(d2.bins) eq 0 then d1.bins = 0 ;- Mask S1 data if S2 data are masked
     
     if d1.type eq 2 then begin ;- FIXME: type02
;;         if total(finite(d1.magf)) ne 3 then continue
;;         if d1.svs ne 0 then continue
;;   phi1 = rebin( (findgen(64)+.5)/64. *360. , 64, 16 )
;;   theta1 = transpose( rebin( -(findgen(16)+.5)/16. *90. , 16, 64 ) )
;;   domega1 = 2.*(5.625/!radeg)*cos(theta1/!radeg)*sin(.5*5.625/!radeg)
;;   phi2 = rebin( (findgen(64)+.5)/64. *360. , 64, 16 )
;;   theta2 = transpose( rebin( (findgen(16)+.5)/16. *90. , 16, 64 ) )
;;   domega2 = 2.*(5.625/!radeg)*cos(theta2/!radeg)*sin(.5*5.625/!radeg)
;;         w = where(~d2.bins,nw)
;;         if nw gt 0 then d2.data[w] = 0
;;         xyz_to_polar,d1.magf,theta=bth,phi=bph
;;         pa1 = pangle(theta1,phi1,bth,bph)
;;         pab1 = fix(pa1/180.*32)  < (32-1)
;;         pa2 = pangle(theta2,phi2,bth,bph)
;;         pab2 = fix(pa2/180.*32)  < (32-1)
;;         nbinpa1 = replicate(0,32) & nbinpa2 = replicate(0,32)
;;         omega1 = replicate(0.,32) & omega2 = replicate(0.,32)
;;         for ipa=0,31 do begin
;;            nbinpa1[ipa] = total( pab1 eq ipa )
;;            nbinpa2[ipa] = total( pab2 eq ipa )
;;            omega1[ipa] = total( (pab1 eq ipa)*domega1 )
;;            omega2[ipa] = total( (pab2 eq ipa)*domega2 )
;;         endfor
;;         even = 31 - indgen(16)*2
;;         odd = 30 - indgen(16)*2
;;         padsc[it,*] = d1.data[3,even]/( nbinpa1[indgen(16)*2] >1) $
;;                       + d1.data[3,odd]/( nbinpa1[indgen(16)*2+1] >1) $
;;                       + d2.data[3,even]*d2.bins[3,even]/( nbinpa2[indgen(16)*2] >1) $
;;                       + d2.data[3,odd]*d2.bins[3,odd]/( nbinpa2[indgen(16)*2+1] >1)

;;         ww1 = 1./omega1 & ww2 = 1./omega2
;;         ww1[where(~finite(ww1))] = 0.
;;         ww2[where(~finite(ww2))] = 0.
;;         padsc[it,*] = d1.data[3,even]*ww1[indgen(16)*2] $
;;                       + d1.data[3,odd]*ww1[indgen(16)*2+1] $
;;                       + d2.data[3,even]*d2.bins[3,even]*ww2[indgen(16)*2] $
;;                       + d2.data[3,odd]*d2.bins[3,odd]*ww2[indgen(16)*2+1]

;;         padsc[it,*] =  ( d1.data[3,even] + d1.data[3,odd] $
;;                          d2.data[3,even]*d2.bins[3,even] $
;;                          + d2.data[3,odd]*d2.bins[3,odd] )/4.
;;         pads[it,*] = padsc[it,*] / mean(padsc[it,*] ,/nan)
        continue
     endif

     if ~d1.valid then continue

     w0 = where( d1.gfactor lt gf_thld_esa1 $ ;- mask bins
                 or abs(d1.theta) lt thrange[0] $
                 or abs(d1.theta) gt thrange[1], nw0 )
     if nw0 gt 0 then d1.bins[w0] = 0

     w0 = where( d2.gfactor lt gf_thld_esa2 $ ;- mask bins
                 or abs(d2.theta) lt thrange[0] $
                 or abs(d2.theta) gt thrange[1], nw0 )
     if nw0 gt 0 then d2.bins[w0] = 0

     d1f = conv_units(d1,'eflux')
     d2f = conv_units(d2,'eflux')

     if total(finite(d1.magf)) ne 3 then continue
     xyz_to_polar,d1.magf,theta=bth,phi=bph
     pa1 = pangle(d1.theta,d1.phi,bth,bph)
     pab1 = fix(pa1/180.*npa)  < (npa-1)

     xyz_to_polar,d2.magf,theta=bth,phi=bph
     pa2 = pangle(d2.theta,d2.phi,bth,bph)
     pab2 = fix(pa2/180.*npa)  < (npa-1)

     for ipa=0,npa-1 do begin

        if d1.svs ne 0 then begin
           w1 = where( pab1 eq ipa and d1.bins eq 1 $
                       and d1.energy ge erange[0] and d1.energy le erange[1] $
                       , nw1)
           w2 = where( pab2 eq ipa and d2.bins eq 1 $
                       and d2.energy ge erange[0] and d2.energy le erange[1] $
                       , nw2)

           if nw1 gt 0 and nw2 gt 0 then begin
              ww1 = d1.data * 0. & ww1[w1] = 1.
              ww2 = d2.data * 0. & ww2[w2] = 1.
              pads[it,ipa] = $
                 (total(d1f.data*d1.domega*d1.denergy*ww1,/nan) $
                  +total(d2f.data*d2.domega*d2.denergy*ww2,/nan)) $
                 /(total(d1.domega*d1.denergy*ww1,/nan) $
                   +total(d2.domega*d2.denergy*ww2,/nan))
              padsc[it,ipa] = total(d1.data*ww1,/nan) + total(d2.data*ww2,/nan)
           endif else if nw1 gt 0 and nw2 eq 0 then begin
              ww1 = d1.data * 0. & ww1[w1] = 1.
              pads[it,ipa] = $
                 total(d1f.data*d1.domega*d1.denergy*ww1,/nan) $
                 /total(d1.domega*d1.denergy*ww1,/nan)
              padsc[it,ipa] = total(d1.data*ww1,/nan)
           endif else if nw1 eq 0 and nw2 gt 0 then begin
              ww2 = d2.data * 0. & ww2[w2] = 1.
              pads[it,ipa] = $
                 total(d2f.data*d2.domega*d2.denergy*ww2,/nan) $
                 /total(d2.domega*d2.denergy*ww2,/nan)
              padsc[it,ipa] = total(d2.data*ww2,/nan)
           endif else continue
        endif else begin ;- ram 0
           times[it] = !values.d_nan
           for istep=0,7 do begin

           times0[8*it+istep] = d1.time + d1.delta_t * (istep +.5d)

           ebins1 = d1.bins * 0
           ebins2 = d2.bins * 0
           ebins1[(0+4*istep):(3+4*istep),*] = 1
           ebins2[(0+4*istep):(3+4*istep),*] = 1

           w1 = where( pab1 eq ipa and d1.bins and ebins1 $
                       and d1.energy ge erange[0] and d1.energy le erange[1] $
                       , nw1)
           w2 = where( pab2 eq ipa and d2.bins and ebins2 $
                       and d2.energy ge erange[0] and d2.energy le erange[1] $
                       , nw2)
           if nw1 gt 0 and nw2 gt 0 then begin
              ww1 = d1.data * 0. & ww1[w1] = 1.
              ww2 = d2.data * 0. & ww2[w2] = 1.
              pads0[8*it+istep,ipa] = $
                 (total(d1f.data*d1.domega*d1.denergy*ww1,/nan) $
                  +total(d2f.data*d2.domega*d2.denergy*ww2,/nan)) $
                 /(total(d1.domega*d1.denergy*ww1,/nan) $
                   +total(d2.domega*d2.denergy*ww2,/nan))
              padsc0[8*it+istep,ipa] = total(d1.data*ww1,/nan) + total(d2.data*ww2,/nan)
           endif else if nw1 gt 0 and nw2 eq 0 then begin
              ww1 = d1.data * 0. & ww1[w1] = 1.
              pads0[8*it+istep,ipa] = $
                 total(d1f.data*d1.domega*d1.denergy*ww1,/nan) $
                 /total(d1.domega*d1.denergy*ww1,/nan)
              padsc0[8*it+istep,ipa] = total(d1.data*ww1,/nan)
           endif else if nw1 eq 0 and nw2 gt 0 then begin
              ww2 = d2.data * 0. & ww2[w2] = 1.
              pads0[8*it+istep,ipa] = $
                 total(d2f.data*d2.domega*d2.denergy*ww2,/nan) $
                 /total(d2.domega*d2.denergy*ww2,/nan)
              padsc0[8*it+istep,ipa] = total(d2.data*ww2,/nan)
           endif else continue

           endfor ;- istep
        endelse


     endfor                     ;- ipa

     aveflux[it] = mean( pads[it,*] , /nan )
     pads[it,*] = pads[it,*] / aveflux[it]

     aveflux0[(8*it):(8*it+7)] = average( pads0[(8*it):(8*it+7),*] , 2, /nan )
     pads0[(8*it):(8*it+7),*] = pads0[(8*it):(8*it+7),*] / rebin(aveflux0[(8*it):(8*it+7)],8,npa)
  endfor                        ;- it

  ;;; combine normal and ER data
  w = where( finite(times) , nw )
  w0 = where( finite(times0) , nw0 )
  if nw*nw0 gt 0 then begin
     times = [ times[w] , times0[w0] ]
     pads = [ pads[w,*] , pads0[w0,*] ]
     padsc = [ padsc[w,*] , padsc0[w0,*] ]
     aveflux = [ aveflux[w] , aveflux0[w0] ]
     pangles = [ pangles[w,*] , pangles0[w0,*] ]
  endif

  store_data,'kgy_esa_pad'+suffix,verbose=verbose, $
             data={x:times,y:pads,v:pangles}, $
                dlim={spec:1,ytitle:'ESA!c'+ $
                      string(erange[0],format='(i0)')+'-'+ $
                      string(erange[1],format='(i0)') $
                      +' eV!cPitch angle!c[deg.]', $
                      constant:[90], $
                      yrange:[0,180],ystyle:1,yminor:3,yticks:4, $
                      zlog:1,ztitle:'Norm.!cFlux',zrange:[.1,10], $
                      datagap:63,minzlog:1.e-30}
  tplot_sort,'kgy_esa_pad'+suffix
  store_data,'kgy_esa_pad_aveflux'+suffix,verbose=verbose, $
             data={x:times,y:aveflux}, $
                dlim={ytitle:'ESA!c'+ $
                      string(erange[0],format='(i0)')+'-'+ $
                      string(erange[1],format='(i0)') $
                      +' eV!cAve. EfLux', $
                      datagap:63,minzlog:1.e-30}
  tplot_sort,'kgy_esa_pad_aveflux'+suffix
  store_data,'kgy_esa_pad_counts'+suffix,verbose=verbose, $
             data={x:times,y:padsc,v:pangles}, $
             dlim={spec:1,ytitle:'ESA!c'+ $
                   string(erange[0],format='(i0)')+'-'+ $
                   string(erange[1],format='(i0)') $
                   +' eV!cPitch angle!c[deg.]', $
                   constant:[90], $
                   yrange:[0,180],ystyle:1,yminor:3,yticks:4, $
                   zlog:1,ztitle:'counts', $
                   datagap:63,minzlog:1.e-30}
  tplot_sort,'kgy_esa_pad_counts'+suffix
  store_data,'kgy_esa_pad_eflux'+suffix,verbose=verbose, $
             data={x:times,y:pads*rebin(aveflux,n_elements(times),npa),v:pangles}, $
                dlim={spec:1,ytitle:'ESA!c'+ $
                      string(erange[0],format='(i0)')+'-'+ $
                      string(erange[1],format='(i0)') $
                      +' eV!cPitch angle!c[deg.]', $
                      constant:[90], $
                      yrange:[0,180],ystyle:1,yminor:3,yticks:4, $
                      zlog:1,ztitle:'Eflux', $
                      datagap:63,minzlog:1.e-30}
  tplot_sort,'kgy_esa_pad_eflux'+suffix


end
