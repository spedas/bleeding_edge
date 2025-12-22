;+
; FUNCTION:
;        FA_TS_EFF
;
; DESCRIPTION:
;
;        function to calculate teams survey efficiency.
;
; INPUT:
;        en:   Arrary (nnrgs, nbins) of energy 
;	 pac:  A number for the calculation of post acceleration voltage
;	 spec: Species for which the effciency is calculated. (0--3)
;	 mode: Teams instrument mode. (0--9)
;	 spin_section: The spin section of data readout (0--2)
;		      0: don't care section.1: first half spin, 2: 2nd half spin
; RETURN:
;	 eff(nnrgs, nbins): Efficiency
;	 eff_version:       The version number of calibration data
;
; CREADED BY:
;	     Li Tang,  University of New Hampshire
;
; LAST MODIFICATION:     10/22/96.    L.Tang	
;
;-	

 FUNCTION FA_TS_EFF, en, pac, spec, mode, spin_section, eff_version

  ang2pix =[ [3, 4, 2, 3, 4, 5, 3, 4, 0, 1, 2, 3, 4, 5, 6, 7,		$
            12,11,13,12,11,10,12,11,15,14,13,12,11,10, 9, 8,		$
             3, 4, 2, 3, 4, 5, 3, 4, 0, 1, 2, 3, 4, 5, 6, 7,		$
            12,11,13,12,11,10,12,11,15,14,13,12,11,10, 9, 8],		$
            [12,11,13,12,11,10,12,11,15,14,13,12,11,10, 9, 8, 		$
             3, 4, 2, 3, 4, 5, 3, 4, 0, 1, 2, 3, 4, 5, 6, 7,		$
            12,11,13,12,11,10,12,11,15,14,13,12,11,10, 9, 8,		$
             3, 4, 2, 3, 4, 5, 3, 4, 0, 1, 2, 3, 4, 5, 6, 7]] 


  eff0 = FLTARR(48, 64)
  eff1 = FLTARR(48, 64)
  eff2 = FLTARR(48, 64)
;  pix1 = INTARR(16)
;  pix2 = INTARR(16)

  tof_eff = FA_TTOF_CALIBRATION(en, spec, pac, eff_version)
  pix1 = ang2pix(*,0)
  pix2 = ang2pix(*,1)

  CASE spec OF
      0: BEGIN
          IF mode GT 5 THEN BEGIN
            IF spin_section GE 2 THEN RETURN, tof_eff(*,pix1) ELSE RETURN,  tof_eff(*,pix2)
          ENDIF ELSE RETURN, (tof_eff(*,pix1) + tof_eff(*,pix2))/2.
	 END
      1: RETURN, (tof_eff(*,pix1) + tof_eff(*,pix2))/2.
      2: RETURN, (tof_eff(*,pix1) + tof_eff(*,pix2))/2.
      3: BEGIN
          IF mode GT 5 THEN BEGIN
            IF spin_section GE 2 THEN RETURN, tof_eff(*,pix1) ELSE RETURN, tof_eff(*,pix2)
          ENDIF ELSE RETURN, (tof_eff(*,pix1) + tof_eff(*,pix2))/2.
	 END
   ENDCASE

END
