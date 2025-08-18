;+
; Calculate moment weighting factors
; Davin Larson, 2005
;-

function calc_omega_flt2,theta,phi,dtheta,dphi, tgeom


if size(/n_dimen,theta) eq 1 then begin
   nth = n_elements(theta)
   nph = n_elements(phi)
   omega = dblarr(13,nth,nph)

   th = theta # replicate(1,nph)
   ph = replicate(1,nth) # phi
   dth = dtheta # replicate(1,nph)
   dph = replicate(1,nth) # dphi

   tg = tgeom # replicate(1,nph)
endif else begin
   dim = size(/dimension,theta)
   th = theta
   ph = phi
   dth = dtheta
   dph = dphi
   tg = tgeom
   omega = dblarr([13,dim])
endelse



if 0 then begin
omega[0,*,*] = cosd(th) * dth * dph
omega[1,*,*] = cosd(th) * dth * dph * cosd(th)*cosd(ph)
omega[2,*,*] = cosd(th) * dth * dph * cosd(th)*sind(ph)
omega[3,*,*] = cosd(th) * dth * dph * sind(th)
omega[4,*,*] = cosd(th) * dth * dph * cosd(th)^2*cosd(ph)^2
omega[5,*,*] = cosd(th) * dth * dph * cosd(th)^2*sind(ph)^2
omega[6,*,*] = cosd(th) * dth * dph * sind(th)^2
omega[7,*,*] = cosd(th) * dth * dph * cosd(th)^2*cosd(ph)*sind(ph)
omega[8,*,*] = cosd(th) * dth * dph * cosd(th)*sind(th)*cosd(ph)
omega[9,*,*] = cosd(th) * dth * dph * cosd(th)*sind(th)*sind(ph)
omega[10,*,*] = omega[1,*,*]
omega[11,*,*] = omega[2,*,*]
omega[12,*,*] = omega[3,*,*]
omega = omega * (!dpi/180)^2
endif

;more accurate method:
ph2 = ph+dph/2
ph1 = ph-dph/2
th2 = th+dth/2
th1 = th-dth/2

ip = dph * !dpi/180
ict =  sind(th2) - sind(th1)
icp =  sind(ph2) - sind(ph1)
isp = -cosd(ph2) + cosd(ph1)
is2p = dph/2* !dpi/180 - sind(ph2)*cosd(ph2)/2 + sind(ph1)*cosd(ph1)/2
ic2p = dph/2* !dpi/180 + sind(ph2)*cosd(ph2)/2 - sind(ph1)*cosd(ph1)/2
ic2t = dth/2* !dpi/180 + sind(th2)*cosd(th2)/2 - sind(th1)*cosd(th1)/2
ic3t = sind(th2) - sind(th1) - (sind(th2)^3 - sind(th1)^3) /3
ictst = (sind(th2)^2 - sind(th1)^2) / 2
icts2t = (sind(th2)^3 - sind(th1)^3)/3
ic2tst = (-cosd(th2)^3 + cosd(th1)^3)/3
icpsp = (sind(ph2)^2 - sind(ph1)^2) / 2

omega[0,*,*] = ict    * ip
omega[1,*,*] = ic2t   * icp
omega[2,*,*] = ic2t   * isp
omega[3,*,*] = ictst  * ip
omega[4,*,*] = ic3t   * ic2p
omega[5,*,*] = ic3t   * is2p
omega[6,*,*] = icts2t * ip
omega[7,*,*] = ic3t   * icpsp
omega[8,*,*] = ic2tst * icp
omega[9,*,*] = ic2tst * isp
omega[10,*,*] = omega[1,*,*]
omega[11,*,*] = omega[2,*,*]
omega[12,*,*] = omega[3,*,*]

for i=0,12 do omega[i,*,*] = omega[i,*,*] / tg

return,omega

end

