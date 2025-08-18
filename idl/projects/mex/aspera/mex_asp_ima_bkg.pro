;+
;
;PROCEDURE:       MEX_ASP_IMA_BKG
;
;PURPOSE:         
;                 Computes MEX/ASPERA-3 (IMA) background counts, and inserts the results into common blocks.
;
;INPUTS:
;
;KEYWORDS:
;
;NOTE:            See, ftp://psa.esac.esa.int/pub/mirror/MARS-EXPRESS/ASPERA-3/MEX-M-ASPERA3-2-EDR-IMA-EXT5-V1.0/CALIB/CALINFO.TXT
;
;CREATED BY:      Takuya Hara on 2018-01-31.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2021-02-20 14:53:03 -0800 (Sat, 20 Feb 2021) $
; $LastChangedRevision: 29688 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_bkg.pro $
;
;-
PRO mex_asp_ima_bkg, bkg, verbose=verbose, psa=psa
  COMMON mex_asp_dat, mex_asp_ima, mex_asp_els
  
  IF SIZE(mex_asp_ima, /type) NE 8 THEN BEGIN
     dprint, dlevel=2, verbose=verbose, 'No IMA data loaded yet.'
     RETURN
  ENDIF
  
  IF undefined(psa) THEN pflg = 1 ELSE pflg = FIX(psa)

  mex_asp_ima_calib, calib, verbose=verbose, psa=pflg
  mnoise = calib.mnoise
  mratio = calib.mratio

  counts = mex_asp_ima.data
  counts[*, *, 0, *] = 0.
  counts[*, *, 4, *] = 0.5 * (counts[*, *, 3, *] + counts[*, *, 5, *])
  counts[*, *, 10, *] = 0.5 * (counts[*, *, 9, *] + counts[*, *, 11, *])
  counts[*, *, 22, *] = 0.5 * (counts[*, *, 21, *] + counts[*, *, 23, *])

  ndat = N_ELEMENTS(mex_asp_ima)
  nenergy = N_ELEMENTS(counts[*, 0, 0, 0])
  nmass = 32

  avg  = DBLARR(16, ndat)
  dev  = avg
  FOR i=0, 15 DO BEGIN
     avg[i, *] = MEAN(REFORM(counts[*, i, *, *], nenergy*nmass, ndat), dim=1)
     dev[i, *] = STDDEV(REFORM(counts[*, i, *, *], nenergy*nmass, ndat), dim=1)
  ENDFOR 

  bkg = counts
  bkg[*] = 0.

  enoise = mex_asp_ima.enoise
  IF ndimen(enoise) EQ 2 THEN enoise = REBIN(enoise, nenergy, ndat, 16, nmass, /sample)
  enoise = TRANSPOSE(TEMPORARY(enoise), [0, 2, 3, 1])

  FOR i=0, ndat-1 DO BEGIN
     asum = mex_asp_ima[i].hk.asum
     psum = mex_asp_ima[i].hk.psum
     msum = mex_asp_ima[i].hk.msum
     af = FLOAT((2^(asum)) *(2^(psum)) *(2^(msum)))
     FOR j=0, 15 DO BEGIN
        cnt = REFORM(counts[*, j, *, i])
        IF dev[j, i] GT avg[j, i] THEN BEGIN
           w = WHERE(cnt LE avg[j, i] + 2.*dev[j, i], nw)
           IF nw GT 0 THEN mbkg = MEAN(cnt[w]) ELSE mbkg = 0.
           undefine, w, nw
        ENDIF ELSE mbkg = avg[j, i]

        noise = (mbkg * REFORM(enoise[*, j, *, i]) * TRANSPOSE(REBIN(mnoise, nmass, nenergy, /sample))) / af
        ;noise = (mbkg * REFORM(mex_asp_ima[i].enoise[*, j, *]) * TRANSPOSE(REBIN(mnoise, nmass, nenergy, /sample))) / af
        cnt_remove_bkg = ((cnt - noise) > 0.) * TRANSPOSE(REBIN(mratio, nmass, nenergy, /sample))
        
        bkg[*, j, *, i] = (cnt - cnt_remove_bkg) > 0.
        undefine, mbkg, noise, cnt_remove_bkg
     ENDFOR
     undefine, asum, psum, msum, af
  ENDFOR 
  
  mex_asp_ima.bkg = bkg

  RETURN
END
