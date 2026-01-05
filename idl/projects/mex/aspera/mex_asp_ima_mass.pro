;+
;
;PROCEDURE:       MEX_ASP_IMA_MASS
;
;PURPOSE:         Calculates the MEX ASPERA-3/IMA Mass table.
;
;INPUTS:          IMA Energy Table and PACC index.
;
;KEYWORDS:
;
;NOTE:            This version is still highly under testing. The usage might change majorly.
;
;CREATED BY:      Takuya Hara on 2021-02-20.
;
;LAST MODIFICATION:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-01 12:17:28 -0800 (Thu, 01 Jan 2026) $
; $LastChangedRevision: 33942 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_ima_mass.pro $
;
;-
PRO mex_asp_ima_mass, eperq, ipacc, verbose=verbose, test=test, table=mass_table
  IF undefined(eperq) OR undefined(ipacc) THEN BEGIN
     COMMON mex_asp_dat, ima, els
     eperq = ima[0].energy
     ipacc = ima[0].pacc
  ENDIF 

  ; See, pages 42-44 at https://archives.esac.esa.int/psa/ftp/MARS-EXPRESS/ASPERA-3/MEX-M-ASPERA3-2-EDR-IMA-V1.0/DOCUMENT/IMA_CALIBRATION_REPORT.PDF

  table = [ $
          [0,  300., 200., 0,  1.913E+01, -2.389E+00,  1.200E+00,  1.200E+00,  2.737E-01, 1.000E+00, -5.000E+01, 1.000E+00], $
          [0,  300., 200., 1,  2.479E-01,  2.392E+00,  5.416E-16, -1.203E-16,  1.517E+00, 2.000E+00, -5.000E+01, 2.000E+00], $
          [0,  300., 200., 2, -1.246E-02, -2.307E-02, -2.604E-17, -4.879E-19, -7.909E-01, 1.700E+01, -4.900E+00, 1.600E+01], $
          [0,  300., 200., 3,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00, 2.800E+01,  0.000E+00, 3.200E+01], $
          [0,  300., 200., 4,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00, 3.900E+01,  1.500E+00, 5.000E+01], $
          [1, 2433., 340., 0,  1.945E+01, -3.707E+00,  1.200E+00,  1.200E+00,  1.067E-01, 1.000E+00, -4.000E+01, 1.000E+00], $
          [1, 2433., 340., 1, -1.134E+00,  2.117E+00, -2.996E-16,  8.844E-17,  1.957E+00, 2.000E+00, -2.500E+01, 2.000E+00], $
          [1, 2433., 340., 2,  8.625E-03,  1.202E-02,  1.765E-17, -1.240E-17, -9.828E-01, 1.700E+01, -3.500E+00, 1.600E+01], $
          [1, 2433., 340., 3,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00, 2.600E+01,  0.000E+00, 3.200E+01], $
          [1, 2433., 340., 4,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00, 3.300E+01,  1.500E+00, 5.000E+01], $
          [2, 4216., 499., 0,  1.132E+01, -1.500E+00,  1.200E+00,  1.200E+00,  3.594E-02, 1.000E+00, -3.000E+01, 1.000E+00], $
          [2, 4216., 499., 1, -4.321E-01,  1.647E+00, -1.451E-16,  4.208E-17,  3.741E-01, 1.800E+00, -2.200E+01, 2.000E+00], $
          [2, 4216., 499., 2,  1.041E-02, -1.065E-02,  2.290E-17,  1.632E-17, -1.731E-01, 1.700E+01, -3.600E+00, 1.600E+01], $
          [2, 4216., 499., 3,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00, 3.200E+01,  0.000E+00, 3.200E+01], $
          [2, 4216., 499., 4,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00,  0.000E+00, 4.500E+01,  1.500E+00, 5.000E+01]  ]

  table = TRANSPOSE(table)
  
  CASE ipacc OF
     0: tbl = table[ 0: 4, *]
     4: tbl = table[ 5: 9, *]
     7: tbl = table[10:14, *]
  ENDCASE 

  elimit = tbl[0, 2]

  mperq = DINDGEN(300) + 1.     ; Artificial M/Q array
  kmass = REFORM(tbl[*,  9])
  omass = REFORM(tbl[*, 11])
  meff = INTERPOL(kmass, omass, mperq)
  
  pacc = tbl[0, 1]              ; PACC in the table (tbl[1, *] is all same)
  kpacc0 = tbl[0, 8]
  kpacc1 = tbl[1, 8]
  kpacc2 = tbl[2, 8]
  
  coeffic = kpacc0 + (kpacc1 / meff)  + (kpacc2 / meff / meff)
  pacceff = pacc * coeffic
  glim = 1.e3 / SQRT( (elimit + pacceff) * meff )

  rm = LIST()
  FOR i=0, N_ELEMENTS(eperq)-1 DO BEGIN
     geff = 1.e3 / SQRT( (eperq[i] + pacceff) * meff )

     IF eperq[i] LT elimit THEN BEGIN
         gfp00 = tbl[0, 4]
         gfp01 = tbl[1, 4]
         gfp02 = tbl[2, 4]
         gfp10 = tbl[0, 5]
         gfp11 = tbl[1, 5]
         gfp12 = tbl[2, 5]

         dM = gfp00 + gfp01 * Glim + gfp02 * Glim * Glim - (gfp10 + gfp11 * Glim + gfp12 * Glim * Glim)
         Rm.add, gfp00 + gfp01 * Geff + gfp02 * Geff * Geff - dM
     ENDIF ELSE BEGIN
        gfp10 = tbl[0, 5]
        gfp11 = tbl[1, 5]
        gfp12 = tbl[2, 5]
        
        Rm.add, gfp10 + gfp11 * Geff + gfp12 * Geff * Geff
     ENDELSE 
  ENDFOR 

  rm = rm.toarray()

  ; Estimating the expected M/Q values at the individual IMA mass ring channels.
  mtable = LIST()
  FOR i=0, N_ELEMENTS(eperq)-1 DO mtable.add, INTERPOL(mperq, REFORM(rm[i, *]), FINDGEN(32))
  mtable = mtable.toarray()

  mass_table = mtable
  mtable = REVERSE(TRANSPOSE(mtable), 2)
  IF KEYWORD_SET(test) THEN BEGIN
     CONTOUR, mtable, FINDGEN(32), REVERSE(eperq), levels=[1, 2, 4, 16, 32, 44], charsize=1.3, xrange=[0, 31], /xst, yrange=[1., 35.e3], /ylog, /yst, $
              xtitle='Mass Ring Number', ytitle='MEX/ASPERA-3 (IMA)!CEnergy [eV/q]', ytickunits='scientific', $
              c_labels=[1, 1, 1, 1, 1, 1]
  ENDIF 
  RETURN
END
