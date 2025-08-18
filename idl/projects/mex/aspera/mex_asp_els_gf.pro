;+
;
;PROCEDURE:       MEX_ASP_ELS_GF
;
;PURPOSE:         
;                 Computes MEX/ASPERA-3 (ELS) geometoric factor.
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_els_gf.pro $
;
;-
PRO mex_asp_els_gf, gfactor, verbose=verbose
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  
  IF SIZE(mex_asp_els, /type) NE 8 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'MEX ASPERA-3/ELS data has not been loaded yet.'
     RETURN
  ENDIF 

  mex_asp_els_rel_eff, rel_eff, verbose=verbose, calib=calib

  ea = (calib.ea)[0]
  gf = (calib.gf)[0]
  mt = (calib.mt)[0]
  gd = (calib.grid)[0]
  aa = (calib.aa)[0]
  
  re = calib.re
  sf = calib.sf

  els  = mex_asp_els
  nene = N_ELEMENTS(els[0].data[*, 0])
  ndat = N_ELEMENTS(els)

  re = REBIN(REBIN(calib.re, 16, nene, /sample), 16, nene, ndat, /sample)
  sf = REBIN(REBIN(calib.sf, 16, nene, /sample), 16, nene, ndat, /sample)
  
  re = TRANSPOSE(re, [1, 0, 2])
  sf = TRANSPOSE(sf, [1, 0, 2])

  er = rel_eff
  gfactor = ((ea / er) * gf * mt * gd * aa * re) / sf 

  RETURN
END
