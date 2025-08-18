;+
;
;PROCEDURE:       MEX_ASP_ELS_REL_EFF
;
;PURPOSE:         
;                 Computes MEX/ASPERA-3 (ELS) relative efficiency per energy channel.
;
;INPUTS:          
;
;KEYWORDS:
;
;CREATED BY:      Takuya Hara on 2018-01-29.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2018-04-04 13:51:13 -0700 (Wed, 04 Apr 2018) $
; $LastChangedRevision: 24995 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_els_rel_eff.pro $
;
;-
PRO mex_asp_els_rel_eff, rel_eff, verbose=verbose, calib=calib
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  
  IF SIZE(mex_asp_els, /type) NE 8 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'MEX ASPERA-3/ELS data has not been loaded yet.'
     RETURN
  ENDIF 

  mex_asp_els_calib, calib, verbose=verbose
  kf = calib.kf
  er = calib.er

  data = mex_asp_els
  ndat = N_ELEMENTS(data)
  energy = TEMPORARY(data.energy)
  nene = N_ELEMENTS(energy[*, 0, 0])

  energy = DOUBLE(energy)
  re     = energy
  re[*]  = 0.d0

  FOR i=0L, ndat-1L DO BEGIN
     ene     = REFORM(energy[*, *, i])
     kfactor = TRANSPOSE(REBIN(kf, 16, nene, /sample))
     ene     = ene / kfactor    ; Converting back to deflection potential.
           
     dv = DBLARR(nene, 16, 11)
     dv[*, *, 0] = 1.d0
     FOR j=1, 10 DO dv[*, *, j] = ene^j
     FOR j=0, 15 DO re[*, j, i] = REFORM(dv[*, j, *]) # REFORM(er[j, *])
  ENDFOR 
  undefine, ene, kfactor, dv, data
  undefine, ndat, energy, nene

  rel_eff = re
  RETURN
END
