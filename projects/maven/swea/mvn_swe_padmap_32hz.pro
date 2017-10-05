;+
;
;FUNCTION:        MVN_SWE_PADMAP_32HZ
;
;PURPOSE:         Maps pitch angle over the SWEA field of view with high time
;                 resolution, taking into account magnetic field variations 
;                 during the 2-second SWEA measurement cycle.  Separate pitch
;                 angle maps are calculated for each of the 64 SWEA energy
;                 steps using 32-Hz MAG data.  The results are appended as new
;                 tags to the PAD data structure.
;
;                 BEWARE!  This routine requires accurate relative timing
;                 between MAG and SWEA.  This is not guaranteed when using 
;                 preliminary data that do not have accurate corrections
;                 for spacecraft clock drift.  If you get a warning message
;                 about using MAG quicklook data, then you are on thin ice!
;                 You might still be OK if you can verify that the MAG and 
;                 SWEA data were processed with the same SCLK kernel.
;
;                 ALSO!  Since the purpose of this routine is to accurately
;                 map pitch angles when the magnetic field varies on time
;                 scales that are shorter than the 2-second SWEA measurement
;                 cycle, you should ask yourself whether the electrons are
;                 magnetized at all.  How good is the adiabatic approximation?
;                 See mvn_swe_eparam.pro for more information.
;
;INPUTS:          PAD data structure obtained from 'mvn_swe_getpad'.
;
;KEYWORDS:
;
;   FBDATA:       Tplot variable name of full resolution magnetic
;                 field data.  Default = 'mvn_B_full'.
;
;   STATUS:       Returns the calculation result
;                 (Success: 1 / Failure: 0).
;
;   MAGLEV:       Returns the MAG data level.  See warning above.
;                   0 -> on-board determination or unknown
;                   1 -> gains and zeroes only (quicklook)
;                   2 -> fully calibrated
;
;   L2ONLY:       Insist on using MAG L2 data.
;
;CREATED BY:      Takuya Hara on 2015-07-20.
;
;LAST MODIFICATION:
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-09 12:58:41 -0800 (Mon, 09 Nov 2015) $
; $LastChangedRevision: 19318 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap_32hz.pro $
;
;-
FUNCTION mvn_swe_padmap_32hz, pdat, fbdata=fbdata, verbose=verbose, status=status, $
                                    maglev=maglev, l2only=l2only

  @mvn_swe_com
  status = 1
  maglev = 0
  opdat = pdat
  fpdat = pdat
  IF ~keyword_set(fbdata) THEN fbdata = 'mvn_B_full'
  get_data, fbdata, data=b, alim=alim, index=index
  IF index EQ 0 THEN BEGIN
     dprint, "No MAG 32Hz data found.", dlevel=2, verbose=verbose
     status = 0
     RETURN, opdat
  ENDIF ELSE BEGIN
     kdx = WHERE(b.x GE pdat.time - 8.d0 AND b.x LE pdat.end_time + 4.d0, nk)
     IF nk GT 0 THEN b = {x: b.x[kdx], y: b.y[kdx, *]} $
     ELSE BEGIN
        dprint, 'No MAG data found at the spcified time period.', dlevel=2, verbose=verbose
        status = 0
        RETURN, opdat
     ENDELSE 
     str_element, alim, 'level', value=maglev
     if (size(maglev,/type) eq 7) then begin
       case strupcase(maglev) of
         'L1' : maglev = 1
         'L2' : maglev = 2
         else : maglev = 0
       endcase
     endif else maglev = 0
     if (maglev lt 2) then begin
       print,"WARNING: Quicklook MAG data - timing may be inaccurate!"
       if keyword_set(l2only) then begin
         status = 0
         return, opdat
       endif
     endif
     IF tag_exist(alim, 'SPICE_FRAME') THEN BEGIN
        IF alim.spice_frame NE 'MAVEN_SWEA' THEN BEGIN
           IF alim.spice_frame EQ 'MAVEN_SPACECRAFT' THEN BEGIN
              idx = WHERE((b.x GT t_mtx[0]) AND (b.x LT t_mtx[2]), nstow, $
                          complement=jdx, ncomplement=ndeploy)
              IF (nstow GT 0L) THEN BEGIN
                 dprint, "Using stowed boom rotation matrix for MAG1.", dlevel=2, verbose=verbose
                 b.y[idx, *] = rotate_mag_to_swe(b.y[idx, *], magu=1, /stow, /payload)
              ENDIF 
              IF (ndeploy GT 0L) THEN BEGIN
                 dprint, "Using deployed boom rotation matrix for MAG1.", dlevel=2, verbose=verbose
                 b.y[jdx, *] = rotate_mag_to_swe(b.y[jdx,*], magu=1, /payload)
              ENDIF 
              undefine, idx, jdx, nstow, ndeploy
           ENDIF ELSE $
              b.y = TRANSPOSE(spice_vector_rotate(TRANSPOSE(b.y), alim.spice_frame, b.x, alim.spice_frame, 'MAVEN_SWEA', $
                                                  check_object='MAVEN_SPACECRAFT', verbose=verbose))
        ENDIF 
     ENDIF ELSE BEGIN
        dprint, 'No SPICE_FRAME info found in tplot.', dlevel=2, verbose=verbose
        status = 0
        RETURN, opdat
     ENDELSE 

     IF tag_exist(pdat, 'time') AND tag_exist(pdat, 'end_time') THEN BEGIN
        dt = pdat.end_time - pdat.time
        ftime = INTERPOL([pdat.time-dt, pdat.time, pdat.end_time], [1, 32, 64], indgen(64)+1)
        str_element, fpdat, 'ftime', ftime, /add_replace
     ENDIF 
  ENDELSE 

  fmagf = FLTARR(64, 3)
  fmagf[*, 0] = SPLINE(b.x, b.y[*, 0], ftime, /double)
  fmagf[*, 1] = SPLINE(b.x, b.y[*, 1], ftime, /double)
  fmagf[*, 2] = SPLINE(b.x, b.y[*, 2], ftime, /double)
  str_element, fpdat, 'fmagf', fmagf, /add_replace

  str_element, pdat, 'Baz', success=ok        ; make sure it's a PAD packet

  if (ok) then begin

; Anode, deflector, and 3D bins for each PAD bin

;    aBaz = pkt.Baz
;    aBel = pkt.Bel
    group = pdat.group

;    i = fix((indgen(16) + aBaz/16) mod 16)   ; 16 anode bins at each time
;    j = swe_padlut[*,aBel]                   ; 16 deflector bins at each time
;    k = j*16 + i                             ; 16 3D angle bins at each time

     i = pdat.iaz
     j = pdat.jel
     k = pdat.k3d

; Magnetic field azimuth and elevation in SWEA coordinates
; Use L1 or L2 MAG data, if available.

     Baz = atan(fmagf[*, 1], fmagf[*, 0])
     iminus = WHERE(Baz LT 0., niminus)
     IF niminus GT 0 THEN Baz[iminus] += 2. * !PI
     Bel = ASIN(fmagf[*, 2] / SQRT(TOTAL(fmagf*fmagf, 2)))

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
    
    fBaz = REBIN(REFORM(TRANSPOSE(REBIN(baz, 64, 16)), [1, 16, 64]), n*n, 16, 64)
    fBel = REBIN(REFORM(TRANSPOSE(REBIN(bel, 64, 16)), [1, 16, 64]), n*n, 16, 64)

    pam = acos(cos(Saz - fBaz)*cos(Sel)*cos(fBel) + sin(Sel)*sin(fBel))

    pa = TRANSPOSE(average(pam,1))             ; mean pitch angle
    pa_min = TRANSPOSE(min(pam,dim=1))         ; minimum pitch angle
    pa_max = TRANSPOSE(max(pam,dim=1))         ; maximum pitch angle
    dpa = pa_max - pa_min           ; pitch angle range

; Inserts the new results
    str_element, fpdat, 'pa', FLOAT(pa), /add_replace
    str_element, fpdat, 'dpa', FLOAT(dpa), /add_replace
    str_element, fpdat, 'pa_min', FLOAT(pa_min), /add_replace
    str_element, fpdat, 'pa_max', FLOAT(pa_max), /add_replace
    str_element, fpdat, 'fBaz', FLOAT(Baz), /add_replace
    str_element, fpdat, 'fBel', FLOAT(Bel), /add_replace

;    pam = { pa     : float(pa)     , $    ; mean pitch angles (radians)
;            dpa    : float(dpa)    , $    ; pitch angle widths (radians)
;            pa_min : float(pa_min) , $    ; minimum pitch angle (radians)
;            pa_max : float(pa_max) , $    ; maximum pitch angle (radians)
;            iaz    : i             , $    ; anode bin (0-15)
;            jel    : j             , $    ; deflector bin (0-5)
;            k3d    : k             , $    ; 3D angle bin (0-95)
;            Baz    : float(Baz)    , $    ; Baz in SWEA coord. (radians)
;            Bel    : float(Bel)       }   ; Bel in SWEA coord. (radians)

  endif else fpdat = opdat
  RETURN, fpdat
END 
