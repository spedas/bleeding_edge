;+
;FUNCTION:   mvn_swe_padmap
;PURPOSE:
;  Calculates the pitch angle map for a PAD.  See mvn_swe_fovmap for the 
;  initialization of the SWEA field of view.
;
;USAGE:
;  pam = mvn_swe_padmap(pkt)
;
;INPUTS:
;       pkt  :         A raw PAD packet (APID A2 or A3).
;
;KEYWORDS:
;       MAGF :         Magnetic field direction in SWEA coordinates.  Overrides
;                      the nominal direction contained in the A2 or A3 packet.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-15 11:28:20 -0700 (Thu, 15 May 2025) $
; $LastChangedRevision: 33313 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap.pro $
;
;CREATED BY:    David L. Mitchell  03-18-14
;FILE: mvn_swe_padmap.pro
;-
function mvn_swe_padmap, pkt, magf=magf

  @mvn_swe_com

; Anode, deflector, and 3D bins for each PAD bin

  i = fix((indgen(16) + pkt.Baz/16) mod 16)   ; 16 anode bins at each time
  j = swe_padlut[*,pkt.Bel]                   ; 16 deflector bins at each time
  k = j*16 + i                                ; 16 solid angle bins at each time

  Sx = Sx3d[*,k,*,pkt.group]                  ; FOV unit vector, x component (n*n,16,64)
  Sy = Sy3d[*,k,*,pkt.group]                  ; FOV unit vector, y component (n*n,16,64)
  Sz = Sz3d[*,k,*,pkt.group]                  ; FOV unit vector, z component (n*n,16,64)

; Magnetic field azimuth and elevation in SWEA coordinates
; Use L1 or L2 MAG data, if available.

  if (n_elements(magf) eq 3) then begin
    B = sqrt(total(magf[0:2]*magf[0:2]))
    Bx = magf[0]/B
    By = magf[1]/B
    Bz = magf[2]/B
    Baz = atan(By, Bx)
    if (Baz lt 0.) then Baz += (2.*!pi)
    Bel = asin(Bz)
  endif else begin
    mvn_swe_magdir, pkt.time, pkt.Baz, pkt.Bel, Baz, Bel
    cosBel = cos(Bel)
    Bx = cos(Baz)*cosBel
    By = sin(Baz)*cosBel
    Bz = sin(Bel)
  endelse

; Calculate the nominal (center) pitch angle for each bin
;   This is a function of energy because the deflector high voltage supply
;   tops out above ~2 keV, and it's function of time because the magnetic
;   field varies: pam -> 16 angles X 64 energies.

  SxBx = temporary(Sx)*Bx
  SyBy = temporary(Sy)*By
  SzBz = temporary(Sz)*Bz
  SdotB = (SxBx + SyBy + SzBz)
  pam = acos(SdotB < 1D > (-1D))        ; (n*n,16,64)

  pa = mean(pam, dim=1)                 ; mean pitch angle
  pa_min = min(pam, dim=1, max=pa_max)  ; min and max pitch angle
  dpa = pa_max - pa_min                 ; pitch angle range

; Package the result

  pam = { pa     : float(pa)     , $    ; mean pitch angles (radians)
          dpa    : float(dpa)    , $    ; pitch angle widths (radians)
          pa_min : float(pa_min) , $    ; minimum pitch angle (radians)
          pa_max : float(pa_max) , $    ; maximum pitch angle (radians)
          iaz    : i             , $    ; anode bin (0-15)
          jel    : j             , $    ; deflector bin (0-5)
          k3d    : k             , $    ; 3D angle bin (0-95)
          Baz    : float(Baz)    , $    ; Baz in SWEA coord. (radians)
          Bel    : float(Bel)       }   ; Bel in SWEA coord. (radians)

  return, pam

end
