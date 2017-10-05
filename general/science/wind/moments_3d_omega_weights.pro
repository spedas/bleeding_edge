;+
;FUNCTION:  moments_3d_omega_weights
; 
;PURPOSE:
;       Helper function used by moments_3d and moments_3du
;KEYWORDS:

;
;CREATED BY:    Davin Larson, Jim McTiernan
;
;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-25 14:55:35 -0700 (Mon, 25 Jun 2012) $
;$LastChangedRevision: 10636 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/wind/moments_3d_omega_weights.pro $
;$Id: moments_3d_omega_weights.pro 10636 2012-06-25 21:55:35Z lphilpott $
;-
;Helper function, main routine is below.
function moments_3d_omega_weights,th,ph,dth,dph ,order=order  ;, tgeom   inputs may be up to 3 dimensions

dim = size(/dimen,th)
if array_equal(dim,size(/dimen,ph)) eq 0 then message,'Bad Input'
if array_equal(dim,size(/dimen,dth)) eq 0 then message,'Bad Input'
if array_equal(dim,size(/dimen,dph)) eq 0 then message,'Bad Input'
omega = dblarr([13,dim])

; Angular moment integrals
ph2 = ph+dph/2
ph1 = ph-dph/2
th2 = th+dth/2
th1 = th-dth/2

sth1 = sin(th1 *!dpi/180)
cth1 = cos(th1 *!dpi/180)
sph1 = sin(ph1 *!dpi/180)
cph1 = cos(ph1 *!dpi/180)

sth2 = sin(th2 *!dpi/180)
cth2 = cos(th2 *!dpi/180)
sph2 = sin(ph2 *!dpi/180)
cph2 = cos(ph2 *!dpi/180)

ip = dph * !dpi/180
ict =  sth2 - sth1
icp =  sph2 - sph1
isp = -cph2 + cph1
is2p = dph/2* !dpi/180 - sph2*cph2/2 + sph1*cph1/2
ic2p = dph/2* !dpi/180 + sph2*cph2/2 - sph1*cph1/2
ic2t = dth/2* !dpi/180 + sth2*cth2/2 - sth1*cth1/2
ic3t = sth2 - sth1 - (sth2^3 - sth1^3) /3
ictst = (sth2^2 - sth1^2) / 2
icts2t = (sth2^3 - sth1^3)/3
ic2tst = (-cth2^3 + cth1^3)/3
icpsp = (sph2^2 - sph1^2) / 2

omega[0,*,*,*] = ict    * ip
omega[1,*,*,*] = ic2t   * icp
omega[2,*,*,*] = ic2t   * isp
omega[3,*,*,*] = ictst  * ip
omega[4,*,*,*] = ic3t   * ic2p
omega[5,*,*,*] = ic3t   * is2p
omega[6,*,*,*] = icts2t * ip
omega[7,*,*,*] = ic3t   * icpsp
omega[8,*,*,*] = ic2tst * icp
omega[9,*,*,*] = ic2tst * isp
omega[10,*,*,*] = omega[1,*,*,*]
omega[11,*,*,*] = omega[2,*,*,*]
omega[12,*,*,*] = omega[3,*,*,*]

;for i=0,12 do begin
;    omega[i,*,*,*] /= tgeom
;endfor

return,omega

end