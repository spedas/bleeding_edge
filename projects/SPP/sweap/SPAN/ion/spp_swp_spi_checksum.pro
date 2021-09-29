PRO spp_swp_spi_checksum, tbl=tbl, mas=mas

   ;; Sweep LUT
   IF keyword_set(tbl) THEN BEGIN
      tmp1 = [[tbl.spl_dac], $
              [tbl.hem_dac],$
              [tbl.def2_dac], $
              [tbl.def1_dac]]
      swp = reform(tmp1,4*4096)
      slut_chk = 0
      FOR i=0., 4.*4096.-1. DO BEGIN 
         tmp1 = fix(swp[i]) AND 'FF'x
         slut_chk  = (slut_chk+tmp1) AND 'FF'X
         tmp2 = ishft(fix(swp[i]), -8) AND 'FF'x
         slut_chk  = (slut_chk+tmp2) AND 'FF'X
      ENDFOR 
      print, format='(A10,z02)', $
             'Sweep: ', slut_chk
   ENDIF

   ;; Full Sweep LUT
   IF 0 THEN BEGIN
      arr = tbl.fsindex
      fslut_chk = 0
      FOR i=0, n_elements(arr)-1 DO BEGIN
         tmp1 = arr[i] AND 'FF'x
         fslut_chk = (fslut_chk+tmp1) AND 'FF'x
         tmp2 = ishft(arr[i], -8) AND 'FF'x
         fslut_chk = (fslut_chk+tmp2) AND 'FF'x
      ENDFOR
      print, format='(A10,z02)', $
             'FSINDEX: ', fslut_chk
   ENDIF

   ;; Targeted Sweep LUT
   IF 0 THEN BEGIN
      arr = tbl.fsindex
      tslut_chk = 0
      FOR i=0, n_elements(arr)-1 DO BEGIN
         tmp1 = arr[i] AND 'FF'x
         tslut_chk = (tslut_chk+tmp1) AND 'FF'x
         tmp2 = ishft(arr[i], -8) AND 'FF'x
         tslut_chk = (tslut_chk+tmp2) AND 'FF'x
      ENDFOR
      print, format='(A10,z02)', $
             'TSINDEX: ', tslut_chk
   ENDIF

   ;; Mass LUT
   IF 0 THEN BEGIN
      arr = mas
      mas_chk = 0
      FOR i=0, n_elements(arr)-1 DO BEGIN
         tmp1 = fix(arr[i]) AND 'FF'x
         mas_chk = (mas_chk+tmp1) AND 'FF'x
         tmp2 = ishft(fix(arr[i]), -8) AND 'FF'x
         mas_chk = (mas_chk+tmp2) AND 'FF'x 
      ENDFOR
      print, format='(A14,z02)', 'Mass Table: 0x', mas_chk
   ENDIF
   
   
END
