;+
;FUNCTION:   mvn_swe_padmap
;PURPOSE:
;  Calculates the pitch angle map for a PAD.
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
; $LastChangedDate: 2015-05-25 17:12:25 -0700 (Mon, 25 May 2015) $
; $LastChangedRevision: 17705 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap.pro $
;
;CREATED BY:    David L. Mitchell  03-18-14
;FILE: mvn_swe_padmap.pro
;-
function mvn_swe_padmap, pkt, magf=magf

  @mvn_swe_com

  str_element, pkt, 'Baz', success=ok        ; make sure it's a PAD packet

  if (ok) then begin

; Anode, deflector, and 3D bins for each PAD bin

    aBaz = pkt.Baz
    aBel = pkt.Bel
    group = pkt.group

    i = fix((indgen(16) + aBaz/16) mod 16)   ; 16 anode bins at each time
    j = swe_padlut[*,aBel]                   ; 16 deflector bins at each time
    k = j*16 + i                             ; 16 3D angle bins at each time

; Magnetic field azimuth and elevation in SWEA coordinates
; Use L1 or L2 MAG data, if available.

    if (n_elements(magf) eq 3) then begin
      Baz = atan(magf[1],magf[0])
      if (Baz lt 0.) then Baz += 2.*!pi
      Bel = asin(magf[2]/sqrt(total(magf*magf)))
    endif else mvn_swe_magdir, pkt.time, aBaz, aBel, Baz, Bel

; nxn azimuth-elevation array for each of the 16 PAD bins
; Elevations are energy dependent above ~2 keV.

    ddtor = !dpi/180D
    ddtors = replicate(ddtor,64)
    n = 17                                   ; patch size - odd integer

    daz = double((indgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
    Saz = reform(replicate(1D,n*n) # double(swe_az[i]) + daz, n*n*16) # ddtors
    
    Sel = dblarr(n*n*16, 64)
    for m=0,63 do begin
      del = reform(replicate(1D,n) # double(indgen(n) - (n-1)/2)/double(n-1), n*n) # double(swe_del[j,m,group])
      Sel[*,m] = reform(replicate(1D,n*n) # double(swe_el[j,m,group]) + del, n*n*16)
    endfor
    Sel = Sel*ddtor
    
    Saz = reform(Saz,n*n,16,64)  ; nxn az-el patch, 16 pitch angle bins, 64 energies
    Sel = reform(Sel,n*n,16,64)

; Calculate the nominal (center) pitch angle for each bin
;   This is a function of energy because the deflector high voltage supply
;   tops out above ~2 keV, and it's function of time because the magnetic
;   field varies: pam -> 16 angles X 64 energies.

    pam = acos(cos(Saz - Baz)*cos(Sel)*cos(Bel) + sin(Sel)*sin(Bel))

    pa = average(pam,1)             ; mean pitch angle
    pa_min = min(pam,dim=1)         ; minimum pitch angle
    pa_max = max(pam,dim=1)         ; maximum pitch angle
    dpa = pa_max - pa_min           ; pitch angle range

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

  endif else pam = 0

  return, pam

end
