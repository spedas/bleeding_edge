
FUNCTION spp_swp_spi_checksum, type, arr, verbose=verbose

   ;;IF keyword_set(arr) THEN BEGIN
   ;;   chksum = 0
   ;;   FOR i=0, n_elements(arr)-1 DO BEGIN
   ;;      tmp1 = arr[i] AND 'FF'x
   ;;      chksum = (chksum+tmp1) AND 'FF'x
   ;;      tmp2 = ishft(arr[i], -8) AND 'FF'x
   ;;      chksum = (chksum+tmp2) AND 'FF'x
   ;;   ENDFOR
   ;;   IF keyword_set(verbose) THEN $      
   ;;    print, format='(A15,A4,z02)', $
   ;;           type,': 0x', chksum
   ;;   return, chksum
   ;;ENDIF

   ;; Sweep LUT
   IF type EQ 'SCI' OR type EQ 'SLUT' THEN BEGIN
      slut = arr
      tmp1 = [[slut.spl_dac], $
              [slut.hem_dac],$
              [slut.def2_dac], $
              [slut.def1_dac]]
      swp = reform(tmp1,4*4096)
      slut_chk = 0
      FOR i=0., 4.*4096.-1. DO BEGIN 
         tmp1 = fix(swp[i]) AND 'FF'x
         slut_chk  = (slut_chk+tmp1) AND 'FF'X
         tmp2 = ishft(fix(swp[i]), -8) AND 'FF'x
         slut_chk  = (slut_chk+tmp2) AND 'FF'X
      ENDFOR
      IF keyword_set(verbose) THEN $
       print, format='(A10,z02)', $
              'SLUT: ', slut_chk
      return, slut_chk
   ENDIF

   ;; Full Sweep LUT
   IF type EQ 'FSLU' THEN BEGIN
      arr = fslut
      fslut_chk = 0
      FOR i=0, n_elements(arr)-1 DO BEGIN
         tmp1 = arr[i] AND 'FF'x
         fslut_chk = (fslut_chk+tmp1) AND 'FF'x
         tmp2 = ishft(arr[i], -8) AND 'FF'x
         fslut_chk = (fslut_chk+tmp2) AND 'FF'x
      ENDFOR
      IF keyword_set(verbose) THEN $      
       print, format='(A10,z02)', $
              'FSINDEX: ', fslut_chk
      return, fslut_chk
   ENDIF

   ;; Targeted Sweep LUT
   IF type EQ 'TSLU' THEN BEGIN
      arr = tslut
      tslut_chk = 0
      FOR i=0, n_elements(arr)-1 DO BEGIN
         tmp1 = arr[i] AND 'FF'x
         tslut_chk = (tslut_chk+tmp1) AND 'FF'x
         tmp2 = ishft(arr[i], -8) AND 'FF'x
         tslut_chk = (tslut_chk+tmp2) AND 'FF'x
      ENDFOR
      IF keyword_set(verbose) THEN $      
       print, format='(A10,z02)', $
              'TSINDEX: ', tslut_chk
      return, tslut_chk
   ENDIF

   ;; Mass LUT
   IF type EQ 'MLUT' THEN BEGIN
      arr = mas
      mas_chk = 0
      FOR i=0, n_elements(arr)-1 DO BEGIN
         tmp1 = fix(arr[i]) AND 'FF'x
         mas_chk = (mas_chk+tmp1) AND 'FF'x
         tmp2 = ishft(fix(arr[i]), -8) AND 'FF'x
         mas_chk = (mas_chk+tmp2) AND 'FF'x 
      ENDFOR
      IF keyword_set(verbose) THEN $
       print, format='(A14,z02)', $
              'Mass Table: 0x', mas_chk
      return, mas_chk
   ENDIF

   return, 0
   
END
