;+
;
;PROCEDURE:       VEX_ASP_ELS_GF
;
;PURPOSE:         Computes the VEX/ASPERA-4 (ELS) geometric factors.
;
;INPUTS:          None.
;
;KEYWORDS:        None.
;
;NOTE:            See, Table 6 from
;                 https://archives.esac.esa.int/psa/ftp/VENUS-EXPRESS/ASPERA4/VEX-V-SW-ASPERA-2-EXT4-ELS-V1.0/DOCUMENT/ELS_DATA_ANALYSIS_SUMMARY.PDF
;
;CREATED BY:      Takuya Hara on 2018-04-17.
;
;LAST MODIFICATION:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-01 12:18:09 -0800 (Thu, 01 Jan 2026) $
; $LastChangedRevision: 33943 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/aspera/vex_asp_els_gf.pro $
;
;-
PRO vex_asp_els_gf, gfactor, test=test
  ene = [       29.9200,      50.3000,      70.2000,      100.400,      199.990,      970.000,      3021.00,      5994.00,      9990.00,      11997.0]
  gf  = [ [2.07540e-006, 3.37581e-006, 4.73706e-006, 6.46449e-006, 8.85756e-006, 1.08817e-005, 8.04262e-006, 6.94579e-006, 7.42996e-006, 5.75665e-006], $
          [4.57159e-006, 5.38168e-006, 6.13679e-006, 7.10438e-006, 9.63588e-006, 1.07470e-005, 8.32344e-006, 7.52185e-006, 8.14427e-006, 6.11427e-006], $ 
          [5.28905e-006, 5.95252e-006, 6.63087e-006, 7.39277e-006, 9.47093e-006, 9.99465e-006, 8.43561e-006, 7.54510e-006, 7.78974e-006, 5.80410e-006], $
          [4.10182e-006, 5.07612e-006, 5.80111e-006, 6.61061e-006, 8.70769e-006, 9.52572e-006, 8.44829e-006, 7.37566e-006, 7.42463e-006, 5.69616e-006], $
          [2.75657e-006, 4.23158e-006, 5.19947e-006, 6.14290e-006, 8.25067e-006, 9.26740e-006, 8.10313e-006, 6.92202e-006, 7.06366e-006, 5.36508e-006], $
          [3.12045e-006, 4.36811e-006, 5.26247e-006, 6.23110e-006, 8.07105e-006, 8.73019e-006, 7.78427e-006, 6.40499e-006, 6.59983e-006, 4.99699e-006], $
          [3.43856e-006, 4.15704e-006, 4.80389e-006, 5.51189e-006, 7.23690e-006, 8.07841e-006, 7.01710e-006, 5.74396e-006, 5.92093e-006, 4.49043e-006], $
          [4.06785e-006, 4.84366e-006, 5.58990e-006, 6.32900e-006, 8.70944e-006, 9.17226e-006, 7.42745e-006, 5.87616e-006, 6.33978e-006, 4.69977e-006], $
          [4.72466e-006, 5.15194e-006, 5.69955e-006, 6.96500e-006, 8.51592e-006, 9.72213e-006, 8.29093e-006, 6.61914e-006, 7.63213e-006, 5.41397e-006], $
          [4.02959e-006, 4.66755e-006, 5.74074e-006, 7.58045e-006, 9.39149e-006, 1.06782e-005, 9.33263e-006, 6.99206e-006, 8.69915e-006, 5.86279e-006], $
          [3.20888e-006, 4.50439e-006, 5.59275e-006, 6.49422e-006, 8.33294e-006, 9.62592e-006, 8.62126e-006, 6.89954e-006, 7.48176e-006, 5.68084e-006], $
          [4.42217e-006, 5.77331e-006, 6.97938e-006, 8.04752e-006, 1.03845e-005, 1.12857e-005, 9.49013e-006, 6.46349e-006, 8.06194e-006, 6.10723e-006], $
          [3.76111e-006, 5.24365e-006, 6.59177e-006, 8.00591e-006, 1.04415e-005, 1.29351e-005, 1.00476e-005, 9.05845e-006, 9.09767e-006, 7.05230e-006], $
          [4.43609e-006, 5.74996e-006, 7.16811e-006, 8.55046e-006, 1.14662e-005, 1.42535e-005, 1.07045e-005, 9.34059e-006, 9.74682e-006, 7.63039e-006], $
          [5.90117e-006, 6.89419e-006, 8.37360e-006, 9.65106e-006, 1.17197e-005, 1.44310e-005, 1.06524e-005, 8.89006e-006, 9.61936e-006, 7.42696e-006], $
          [6.32660e-006, 7.43104e-006, 9.01837e-006, 1.05006e-005, 1.37654e-005, 1.49384e-005, 1.04071e-005, 8.82440e-006, 9.39500e-006, 7.23438e-006]  ] 

  vex_asp_els_energy, energy

  gfactor = list()
  FOR i=0, 1 DO BEGIN
     e = energy[i]
     g = e
     g[*] = 0.
;     FOR j=0, 15 DO g[j, *] = REVERSE(INTERPOL(ALOG10(REFORM(gf[*, j])), ALOG10(ene), REVERSE(ALOG10(e[j, *]))))

     FOR j=0, 15 DO BEGIN
        lfit = REFORM(POLY_FIT(ALOG10(ene[4:5]), ALOG10(gf[4:5, j]), 1))
        ufit = REFORM(POLY_FIT(ALOG10(ene[5:7]), ALOG10(gf[5:7, j]), 1))
        
        w = WHERE(e[j, *] LT 970., nw, complement=v, ncomplement=nv)        
        IF nw GT 0 THEN g[j, w] = lfit[0] + ALOG10(e[j, w]) * lfit[1]
        IF nv GT 0 THEN g[j, v] = ufit[0] + ALOG10(e[j, v]) * ufit[1]

        undefine, w, v, nw, nv
        undefine, lfit, ufit
     ENDFOR 

     gfactor.add, 10.^g
  ENDFOR 

  IF KEYWORD_SET(test) THEN BEGIN
     wi, 0, wsize=[600, 500]
     FOR i=0, 1 DO FOR j=0, 15 DO BEGIN
        PLOT_OO, ene, gf[*, j], psym=4, symsize=2, charsize=1.3, xtitle='ELS Energy [eV]', ytitle='G-Factor', yrange=[1.e-6, 1.e-4]
        OPLOT, (energy[i])[j, *], (gfactor[i])[j, *], psym=7, col=6, symsize=1.5
        WAIT, 5.
     ENDFOR 
  ENDIF 
  RETURN
END
