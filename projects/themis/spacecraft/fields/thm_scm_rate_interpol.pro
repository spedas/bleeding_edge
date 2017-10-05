; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

  PRO thm_scm_rate_interpol, time_head, TMrate, time_scm, TMrate_int

; ----------------------------------------------------------------------
; interpolation of TM rate to have same time resolution than time_scm
;
; P. Robert, CETP, January 2007
; K. Bromund, SPSystems/NASA/GSFC. adapted from scm_rate_interpol
; ----------------------------------------------------------------------

  nhea=N_ELEMENTS(time_head)
  nscm=N_ELEMENTS(time_scm)
  TMrate_int=FLTARR(nscm)

; we keep the same value until a new values appears

  TMrate_int(*)=TMrate(0)

  FOR j=1L,nhea-1L DO BEGIN
  IF(TMrate(j) NE TMrate(j-1) ) THEN BEGIN
                                sel=WHERE(time_scm GE time_head(j),kk)
                                IF(kk NE 0) THEN $
                                            TMrate_int(sel)=TMrate(j) $
                                            ELSE $
                                            RETURN

                                ENDIF
  ENDFOR

  END

; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
