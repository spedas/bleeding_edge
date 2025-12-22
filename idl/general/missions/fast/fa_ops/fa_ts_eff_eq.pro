;+
; FUNCTION:
;        FA_TS_EFF_EQ
;
; DESCRIPTION:
;
;        function to calculate teams survey efficiency on equator angle bins
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
;	 eff_version:       The version of calibration data
;
; CREADED BY:
;	     Li Tang,  University of New Hampshire
;
; LAST MODIFICATION:     8/14/96.    LT
;
;-	      

FUNCTION FA_TS_EFF_EQ, en, pac, spec, mode, spin_section, eff_version

 ang2pix =[[3, 3, 3, 3, 3, 3, 3, 3, 11, 11, 11, 11, 11, 11, 11, 11],     $
          [11, 11, 11, 11, 11, 11, 11, 11, 3, 3, 3, 3, 3, 3, 3, 3]]


   nbins = dimen2(en)
   ebins = dimen1(en)
;print, nbins, ebins
   eff = FLTARR(ebins, nbins)

   tof_eff = FA_TTOF_CALIBRATION(en, spec, pac, eff_version)
  
   IF ((spec EQ 0) OR (spec EQ 3)) AND mode GT 5 THEN BEGIN
      IF spin_section GE 2 THEN BEGIN
   
	FOR j = 0, nbins-1 DO BEGIN
           pix1 = ang2pix(j, 0)
    	   pix2 = pix1 + 1
     	   FOR i = 0, ebins-1 DO BEGIN
       
             eff(i, j) = (tof_eff(i, pix1) + tof_eff(i, pix2))/2.
                        
           ENDFOR
	ENDFOR

      ENDIF ELSE BEGIN

	FOR j = 0, nbins-1 DO BEGIN
     	   pix3 = ang2pix(j, 1)
     	   pix4 = pix3 + 1
     	   FOR i = 0, ebins-1 DO BEGIN

              eff(i, j) = (tof_eff(i, pix3) + tof_eff(i, pix4))/2.
           ENDFOR
	ENDFOR
      ENDELSE

   ENDIF ELSE BEGIN

     FOR j = 0, nbins-1 DO BEGIN
        pix1 = ang2pix(j, 0)
    	pix2 = pix1 + 1
     	pix3 = ang2pix(j, 1)
     	pix4 = pix3 + 1
  	
	FOR i = 0, ebins-1 DO BEGIN

        eff(i, j) =(tof_eff(i, pix1) + tof_eff(i, pix2) +   $
			   tof_eff(i, pix3) + tof_eff(i, pix4))/4.

        ENDFOR
     ENDFOR

   ENDELSE

;print, 'eff:'
;print, eff(*, *)
   RETURN, eff

END
