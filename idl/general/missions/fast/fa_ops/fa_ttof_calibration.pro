;+
; FUNCTION:
;	 FA_TTOF_CALIBRATION
;
; DESCRIPTION:
;	 
;	 to calculate the teams Time Of Flight(TOF)
;
; INPUT:
;        energy: Array (nnrgs, nbins) of energy
;	 pac:    pac:  A number for the calculation of post acceleration voltage
;
; RETURN:
;	 TOF_EFF(nenergy, pixels, species)
;        version:  version of calibration data.
;
; CREADED BY:
;	     Li Tang,  University of New Hampshire, Space Physics Lab
;
; LAST MODIFICATION:     8/14/96.    LT
;
;- 

FUNCTION FA_TTOF_CALIBRATION, energy, spec, pac, version

   sf  = [2, 1, 1]  ;spec factor for energy: sf(0): He++, sf(1): He+, sf(2): O+
   m0 = fltarr(3)
   m1 = fltarr(3)
   m2 = fltarr(3)
   m3 = fltarr(3)
   mh0 = fltarr(16)
   mh1 = fltarr(16)
   pix_adjus = FLTARR(4, 16)
   ebin = dimen1(energy)
   TOF_EFF = FLOAT(REPLICATE(1.,ebin,16))

;   OPENR, 1, '/disks/fast/software/config/tms_cfg/fa_tms_calibrationdata'
   OPENR, 1, GETENV('FASTCONFIG')+'/tms_cfg/fa_tms_calibrationdata'
  
   READF, 1, version, pac_a, pac_b, m0, m1, m2, m3, mh0, mh1, pix_adjus

   CLOSE, 1

   E_pac = pac*pac_a + pac_b
  
   IF spec GT 0 THEN BEGIN
      sp = spec - 1
      FOR en = 0, ebin-1 DO BEGIN
         TOF_Energy = energy(en, 1)/1000. + E_pac
       
         Effi_Curve = m0(sp) + m1(sp)*sf(sp)*TOF_Energy		$
                               + m2(sp)*(sf(sp)*TOF_Energy)^2	$
                               + m3(sp)*(sf(sp)*TOF_Energy)^3
  
         TOF_EFF(en,*)=Effi_Curve/pix_adjus(spec,*)
       ENDFOR     
    ENDIF ELSE BEGIN		; For H+
      FOR en = 0, ebin-1 DO BEGIN
         TOF_Energy = energy(en, 1)/1000. + E_pac
         TOF_EFF(en, *)=(mh0+ mh1*TOF_Energy)/pix_adjus(0,*)
      ENDFOR
    ENDELSE

   RETURN, TOF_EFF

END
