;+
; PROCEDURE:
;       mex_marsis_radargram
; PURPOSE:
;       generates tplot variables of MARSIS radargrams
; CALLING SEQUENCE:
;       mex_marsis_radargram, frange=[1,2.5]
; KEYWORDS:
;       frange: [fmin,fmax]
;               if fmin = fmax or frange contains only one element,
;               uses one specific frequency step (Def. 1.5 MHz)
; CREATED BY:
;       Yuki Harada on 2017-05-11
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-04-06 01:38:33 -0700 (Fri, 06 Apr 2018) $
; $LastChangedRevision: 25009 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/marsis/mex_marsis_radargram.pro $
;-

pro mex_marsis_radargram, frange=frange, suffix=suffix, tceonly=tceonly, centtimes=centtimes

if keyword_set(frange) then fr = minmax(frange) else fr = [1.5,1.5]
if ~keyword_set(suffix) then suffix = ''
if keyword_set(tceonly) then if fr[0] eq fr[1] then fr = [0,.3]
if keyword_set(centtimes) then tadd = 7.543d/2 else tadd = 0d ;- adjust times so that the left edges of pixels represent the event time of the first transmit pulse

@mex_marsis_com

if size(marsis_ionograms,/type) eq 0 then begin
   dprint,'No ionogram data are loaded'
   return
endif

t = marsis_ionograms.time
ff = transpose(marsis_ionograms.freq) /1e6
sss = transpose(marsis_ionograms.spec,[2,0,1])
ww = ff * 0.
www = sss * 0.

if fr[0] eq fr[1] then begin
   fr_str = string(fr[0],f='(f3.1)')+' MHz'
   tmp = min( abs(ff-fr[0]), idxmin, dim=2 )
   ww[idxmin] = 1.
   www = rebin(ww,n_elements(t),160,80)
endif else begin
   fr_str = string(fr[0],f='(f3.1)')+'-'+string(fr[1],f='(f3.1)')+' MHz'
   fff = rebin(ff,n_elements(t),160,80)
   w = where( fff gt fr[0] and fff lt fr[1] , nw )
   if nw gt 0 then begin
      www[w] = 1.
   endif else dprint,'No freq in the specified frange'
endelse


if keyword_set(tceonly) then begin ;- obsolete
   w = where(www eq 0 , nw)
   if nw gt 0 then www[w] = !values.f_nan

   ;;; excl. fpe lines (use only freq w/ weaker half spec dens)
   plines = median(sss*www,dim=3)
   w2 = where( rebin(plines,n_elements(t),160,80) $
               gt rebin(median(plines,dim=2),n_elements(t),160,80) ,nw2)
   if nw2 gt 0 then www[w2] = !values.f_nan
   fr_str = fr_str + '!cexcl. fpe lines'

   sdensmed = median(sss*www,dim=2)
   store_data,'mex_marsis_dt_sdens_med'+suffix, $
              data={x:t+tadd,y:sdensmed,v:marsis_delay_times/1e3}, $
              dlim={spec:1, $
                    ytitle:fr_str+'!cTime Delay!c[ms]', $
                    yrange:[6,0], $
                    ztitle:'Median!cSpectral Density!c[(V/m)!u2!n/Hz]', $
                    zrange:[1e-18,1e-10],zlog:1,datagap:10}
   return
endif


sdens = total(sss*www,2,/nan) / total(www,2)
arange = transpose(rebin( 0.1499 * marsis_delay_times , 80, n_elements(t) ))

store_data,'mex_marsis_arange_sdens'+suffix, $
           data={x:t+tadd,y:sdens,v:arange}, $
           dlim={spec:1, $
                 ytitle:fr_str+'!cApparent Range!c[km]', $
                 yrange:[max(arange),0], $
                 ztitle:'Spectral Density!c[(V/m)!u2!n/Hz]',zlog:1, $
                 zrange:[1e-18,1e-10],datagap:10}

if size(marsis_geometry,/type) ne 0 then begin
   alt = interp(marsis_geometry.alt,marsis_geometry.time,t,interp=10)
   aalt = rebin(alt,n_elements(t),80) - arange
   store_data,'mex_marsis_aalt_sdens'+suffix, $
              data={x:t+tadd,y:sdens,v:aalt}, $
              dlim={spec:1,yrange:[-900,1200],ystyle:1, $
                    ytitle:fr_str+'!cApparent Alt.!c[km]', $
                    ztitle:'Spectral Density!c[(V/m)!u2!n/Hz]',zlog:1, $
                    zrange:[1e-18,1e-10],datagap:10}
endif


;;; test trace
;; aaltr = [50,150]
;; thld_ss = 1e-15
;; get_data,'mex_marsis_aalt_sdens',data=drad,dlim=dlim,lim=lim
;; ss = drad.y
;; aa = drad.v
;; w = where( drad.v gt aaltr[0] and drad.v lt aaltr[1] $
;;            and drad.y gt thld_ss , comp=cw, ncomp=ncw )
;; if ncw gt 0 then ss[cw] = !values.f_nan
;; store_data,'tmp',data={x:drad.x,y:ss,v:drad.v},dlim=dlim,lim=lim
;; tmp = max( ss, idx, dim=2, /nan )
;; aa2 = aa*!values.f_nan
;; aa2[idx] = aa[idx]
;; apeak = average(aa2,2,/nan)
;; w = where( apeak gt aaltr[0] and apeak lt aaltr[1], comp=cw, ncomp=ncw)
;; if ncw gt 0 then apeak[w] = !values.f_nan
;; store_data,'tmp2',data={x:drad.x,y:apeak},dlim={psym:1,symsize:.2}



end
