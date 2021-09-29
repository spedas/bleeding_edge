;+
; FUNCTION:
;       kgy_pace_interp
; PURPOSE:
;       Interpolates irregular [phi,theta] sampling into a regular grid
; CALLING SEQUENCE:
;       dnew = kgy_pace_interp(d)
; INPUTS:
;       3d data structure returned by kgy_*_get3d(sabin=0)
; KEYWORDS:
;       thld_gf: ignore data points w/ gfactor < thld_gf (Def: 1e-7)
; CREATED BY:
;       Yuki Harada on 2018-05-10
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-10 19:25:52 -0700 (Thu, 10 May 2018) $
; $LastChangedRevision: 25196 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_pace_interp.pro $
;-

function kgy_pace_interp, dat2, thld_gf=thld_gf

if size(thld_gf,/type) eq 0 then thld_gf = 1e-7

dat = dat2

if size(dat.data,/n_dim) ne 3 then begin ;- check data dimension
   dprint,'Data dimension must be nenergy x ntheta x nphi'
   return,-1
endif

data = dat.data
energy = dat.energy
phi = dat.phi
theta = dat.theta
gfactor = dat.gfactor
nenergy = dat.nenergy
nphi = dat.nphi
ntheta = dat.ntheta
bins = dat.bins
case dat.sensor  of
   0: sss = -1.                 ;- ESA-S1: -90 < theta < 0
   1: sss = 1.                  ;- ESA-S2: 0 < theta < 90
   2: sss = -1.                 ;- IMA: -90 < theta < 0
   3: sss = 1.                  ;- IEA: 0 < theta < 90
endcase


wok = where( gfactor gt thld_gf , nwok, comp=cwok, ncomp=ncwok )
if nwok eq 0 then begin
   dprint,'No data points w/ gfactor > thld_gf'
   return,-1
end
if ncwok gt 0 then bins[cwok] = 0

newenergy = energy*!values.f_nan
newdata = data*!values.f_nan
newtheta = theta*!values.f_nan
dphi = 360./nphi
dtheta = 90./ntheta
phig = (findgen(nphi)+.5)*dphi
thetag = (findgen(ntheta)+.5)*dtheta*sss
for iene=0,nenergy-1 do begin

   ;;; simple linear interp in the same manner as momcal.c
   for ith=0,ntheta-1 do begin  ;- phi interp
      w = where(bins[iene,ith,*],nw)
      if nw eq 0 then continue
      xd = reform(phi[iene,ith,w])
      yd = reform(energy[iene,ith,w])
      yd = yd[sort(xd)]
      xd = xd[sort(xd)]
      xd = [ xd-360., xd, xd + 360 ]
      yd = [ yd, yd, yd ]
      newenergy[iene,ith,*] = interp( yd , xd, phig )
      xd = reform(phi[iene,ith,w])
      yd = reform(data[iene,ith,w])
      yd = yd[sort(xd)]
      xd = xd[sort(xd)]
      xd = [ xd-360., xd, xd + 360 ]
      yd = [ yd, yd, yd ]
      newdata[iene,ith,*] = interp( yd , xd, phig )
      xd = reform(phi[iene,ith,w])
      yd = reform(theta[iene,ith,w])
      yd = yd[sort(xd)]
      xd = xd[sort(xd)]
      xd = [ xd-360., xd, xd + 360 ]
      yd = [ yd, yd, yd ]
      newtheta[iene,ith,*] = interp( yd , xd, phig )
   endfor
   for iph=0,nphi-1 do begin    ;- theta interp
      w = where( finite(newtheta[iene,*,iph]) , nw )
      if nw eq 0 then continue
      xd = reform(newtheta[iene,w,iph])
      yd = reform(newenergy[iene,w,iph])
      yd = yd[sort(xd*sss)]
      xd = xd[sort(xd*sss)]
      xd = [ 0, xd, 90.*sss ]
      yd = [ yd[0], yd, yd[nw-1] ]
      newenergy[iene,*,iph] = interp( yd , xd, thetag )
      xd = reform(newtheta[iene,w,iph])
      yd = reform(newdata[iene,w,iph])
      yd = yd[sort(xd*sss)]
      xd = xd[sort(xd*sss)]
      xd = [ 0., xd, 90.*sss ]
      yd = [ yd[0], yd, yd[nw-1] ]
      newdata[iene,*,iph] = interp( yd , xd, thetag )
   endfor

   ;;; triangulate, slower
;;    w = where( reform(bins[iene,*,*]) , nw )
;;    if nw eq 0 then continue

;;    xd = reform(phi[iene,*,*])
;;    yd = reform(theta[iene,*,*])
;;    zd = reform(data[iene,*,*])
;;    ed = reform(energy[iene,*,*])

;;    xd = xd[w]
;;    yd = yd[w]
;;    zd = zd[w]
;;    ed = ed[w]

;;    xd = [ xd-360., xd, xd+360., xd, xd ] ;- cyclic in phi, mirror in theta
;;    yd = [ yd, yd, yd, -yd, (180.*sss-yd) ]
;;    zd = [ zd, zd, zd, zd, zd ]
;;    ed = [ ed, ed, ed, ed, ed ]

;;    ;;; qhull generally performs better than triangulate (cf. spd_slice2d_2di.pro)
;;    qhull, xd, yd, tr , /delaunay

;;    newzd = trigrid( xd, yd, zd, tr, [ dphi, dtheta ], $
;;                     [ dphi/2,dtheta/2*sss,360.-dphi/2,(90.-dtheta/2)*sss], $
;;                     xgrid=phig, ygrid=thetag )
;;    newed = trigrid( xd, yd, ed, tr, [ dphi, dtheta ], $
;;                     [ dphi/2,dtheta/2*sss,360.-dphi/2,(90.-dtheta/2)*sss], $
;;                     xgrid=phig, ygrid=thetag )
;;    newdata[iene,*,*] = transpose(newzd)
;;    newenergy[iene,*,*] = transpose(newed)

endfor                          ;- iene

dat.data = newdata
dat.energy = newenergy

dat.denergy[0,*,*] = dat.energy[1,*,*] - dat.energy[0,*,*]
dat.denergy[nenergy-1,*,*] = dat.energy[nenergy-1,*,*] - dat.energy[nenergy-2,*,*]
dat.denergy[1:nenergy-2,*,*] $
   = (dat.energy[2:nenergy-1,*,*]-dat.energy[0:nenergy-3,*,*])/2.

newphi = transpose(rebin(phig,nphi,nenergy,ntheta),[1,2,0])
newtheta = transpose(rebin(thetag,ntheta,nenergy,nphi),[1,0,2])
dat.phi = newphi
dat.theta = newtheta

dat.bins = 1

return, dat

end
