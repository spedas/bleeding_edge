;+
; FUNCTION:
;       kgy_svm_get
; PURPOSE:
;       Returns model lunar B vector computed from SVM (Tsunakawa et al., 2015)
;       Works in selenographic coordinates
; CALLING SEQUENCE:
;       bvec = kgy_svm_get(rvec)
; INPUT:
;       rvec: 3xN array containing X, Y, Z in km
; OUTPUT:
;       bvec: 3xN array containing Bx, By, Bz in nT
; CREATED BY:
;       Yuki Harada on 2018-05-02
;       Modified from Bcal.f90 written by H. Tsunakawa
;       The original version is available at
;       http://www.geo.titech.ac.jp/lab/tsunakawa/Kaguya_LMAG
; REFERENCE:
;       Tsunakawa, H., F. Takahashi, H. Shimizu, H. Shibuya, and M. Matsushima (2015), Surface vector mapping of magnetic anomalies over the Moon using Kaguya and Lunar Prospector observations, J. Geophys. Res. Planets, 120, 1160–1185, doi:10.1002/2014JE004785.
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-08 16:47:27 -0700 (Tue, 08 May 2018) $
; $LastChangedRevision: 25186 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/lmag/kgy_svm_get.pro $
;-

function kgy_svm_get, rvec, verbose=verbose


@kgy_svm_com

if size(svm_dat,/type) eq 0 then kgy_svm_load


Rm = 1737.4
alt1 = 6.05 ;- Altitude should not be lower than alt1(=6.05km) due to the grid size.
alt = reform( sqrt(rvec[0,*]^2.+rvec[1,*]^2.+rvec[2,*]^2.) - Rm ) ;- np
sa0 = (.2*!dtor)^2               ;- domega at equator

np = n_elements(rvec[0,*])
rp = rvec / Rm                  ;- 3 x np

;;; svm_dat = [    Lon     Lat      Be      Bn      Br      Bt ] x 1621800
ns = n_elements(svm_dat[0,*])
rs = [ [reform(cos(svm_dat[0,*]*!dtor) * cos(svm_dat[1,*]*!dtor))], $
       [reform(sin(svm_dat[0,*]*!dtor) * cos(svm_dat[1,*]*!dtor))], $
       [reform(sin(svm_dat[1,*]*!dtor))] ]
rs = transpose(rs)              ;- 3 x ns

brs = reform(svm_dat[4,*])                  ;- only Br is used, ns
sak = reform(cos(svm_dat[1,*]*!dtor)) * sa0 ;- domega, ns


bvec = make_array(value=!values.f_nan,3,np) ;- output container

syst0 = systime(/sec)
secnow = 0.
for ip=0,np-1 do begin          ;- loop through input positions
   if systime(/sec)-syst0 gt secnow+2 then begin
      secnow = secnow+1
      dprint,dlevel=0,verbose=verbose,'svm Bcal: ',ip,' / ',np-1,100.*ip/(np-1),' %'
   endif

   rpnow = reform(rp[*,ip])
   altnow = alt[ip]

   rrs = total( (rebin(rpnow,3,ns) - rs)^2, 1 )^.5 ;- ns

   ;;; ignore large-distance sources after Bcal.f90
   ws = where( rrs/(altnow/Rm) le 10 , nws )
   if nws eq 0 then continue

   rrarr = replicate(total(rpnow^2)^.5,3,nws) ;- 3 x nws
   rparr = rebin(rpnow,3,nws)                 ;- 3 x nws
   rrsarr = transpose(rebin(rrs[ws],nws,3))   ;- 3 x nws
   rsarr = rs[*,ws]                           ;- 3 x nws

   gradk = (rparr - rsarr) / rrsarr^3 $ ;- see Eq (3.31) of Tsunakawa+2010
           - ( rparr/rrarr + (rparr - rsarr)/rrsarr ) $
           / ( (rrarr+rrsarr+1.)*(rrarr+rrsarr-1.) ) ;- 3 x nws

   bcal = total( 1/(2.*!pi)*gradk $
                 *transpose(rebin(brs[ws],nws,3)) $
                 *transpose(rebin(sak[ws],nws,3)) , 2) ;- 3

   bvec[*,ip] = bcal[*]

endfor                          ;- ip



;;; replace invalid data by NaNs
wnan = where( alt lt alt1 , nwnan )
if nwnan gt 0 then bvec[*,wnan] = !values.f_nan

dprint,dlevel=0,verbose=verbose,'svm calc time = ',systime(/sec)-syst0,' s'

return,bvec

end
