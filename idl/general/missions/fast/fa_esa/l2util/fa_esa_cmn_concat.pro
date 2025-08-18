;+
;NAME:
; fa_esa_cmn_concat
;PURPOSE:
; concatenates two FAST ESA L2 data structures
;CALLING SEQUENCE:
; dat = fa_esa_cmn_concat(dat1, dat2)
;INPUT:
; dat1, dat2 = two FAST ESA data structures: e.g., 
;   PROJECT_NAME    STRING    'FAST'
;   DATA_NAME       STRING    'Iesa Burst'
;   DATA_LEVEL      STRING    'Level 1'
;   UNITS_NAME      STRING    'Compressed'
;   UNITS_PROCEDURE STRING    'fa_convert_esa_units'
;   VALID           INT       Array[59832]
;   DATA_QUALITY    BYTE      Array[59832]
;   TIME            DOUBLE    Array[59832]
;   END_TIME        DOUBLE    Array[59832]
;   INTEG_T         DOUBLE    Array[59832]
;   DELTA_T         DOUBLE    Array[59832]
;   NBINS           BYTE      Array[59832]
;   NENERGY         BYTE      Array[59832]
;   GEOM_FACTOR     FLOAT     Array[59832]
;   DATA_IND        LONG      Array[59832]
;   GF_IND          INT       Array[59832]
;   BINS_IND        INT       Array[59832]
;   MODE_IND        BYTE      Array[59832]
;   THETA_SHIFT     FLOAT     Array[59832]
;   THETA_MAX       FLOAT     Array[59832]
;   THETA_MIN       FLOAT     Array[59832]
;   BKG             FLOAT     Array[59832]
;   ENERGY          FLOAT     Array[96, 32, 2]
;   BINS            BYTE      Array[96, 32]
;   THETA           FLOAT     Array[96, 32, 2]
;   GF              FLOAT     Array[96, 64]
;   DENERGY         FLOAT     Array[96, 32, 2]
;   DTHETA          FLOAT     Array[96, 32, 2]
;   EFF             FLOAT     Array[96, 32, 2]
;   DEAD            FLOAT       1.10000e-07
;   MASS            FLOAT         0.0104389
;   CHARGE          INT              1
;   SC_POT          FLOAT     Array[59832]
;   BKG_ARR         FLOAT     Array[96, 64]
;   HEADER_BYTES    BYTE      Array[44, 59832]
;   DATA            BYTE      Array[59832, 96, 64]
;   EFLUX           FLOAT     Array[59832, 96, 64]
;   ENERGY_FULL     FLOAT     Array[59832, 96, 64]
;   DENERGY_FULL    FLOAT     Array[59832, 96, 64]
;   PITCH_ANGLE     FLOAT     Array[59832, 96, 64]
;   DOMEGA          FLOAT     Array[59832, 96, 64]
;   ORBIT_START     LONG
;   ORBIT_END       LONG
;;OUTPUT:
; dat = a single structure concatenated
;HISTORY:
; 19-may-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-09-09 11:43:35 -0700 (Fri, 09 Sep 2016) $
; $LastChangedRevision: 21811 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_cmn_concat.pro $
;-
Function fa_esa_cmn_concat, dat1, dat2

;Record varying arrays are concatenated, NRV values must be
;equal. rv_flag is one for tags that will be concatenated. This will
;need to be kept up_to_date
  If(dat1.data_name Ne dat2.data_name) Then Begin
     dprint, 'Mismatch in data_name '+dat1.data_name+' '+dat2.data_name
     Return, -1
  Endif
  rv_arr = fa_esa_cmn_l2vararr(dat1.data_name)

  nvar = n_elements(rv_arr[0, *])
  tags1 = tag_names(dat1)
  tags2 = tag_names(dat2)
  ntags1 = n_elements(tags1)
  ntags2 = n_elements(tags2)

  count = 0
  dat = -1
  For j = 0, nvar-1 Do Begin
     x1 = where(tags1 Eq rv_arr[0, j], nx1)
     x2 = where(tags2 Eq rv_arr[0, j], nx2)
     If(nx1 Eq 0 Or nx2 Eq 0) Then Begin
        dprint, dlev = [0], 'Missing tag: '+rv_arr[0, j]
        Return, -1
     Endif Else Begin
        If(rv_arr[2, j] Eq 'N') Then Begin
;Arrays must be equal, unless they are orbit_start and orbit_end
           If(rv_arr[0, j] Eq 'ORBIT_START') Then Begin
              If(count Eq 0) Then undefine, dat
              count = count+1
              str_element, dat, rv_arr[0, j], min([dat1.(x1), dat2.(x2)]), /add_replace
           Endif Else If(rv_arr[0, j] Eq 'ORBIT_END') Then Begin
              If(count Eq 0) Then undefine, dat
              count = count+1
              str_element, dat, rv_arr[0, j], max([dat1.(x1), dat2.(x2)]), /add_replace
           Endif Else Begin
              If(Not array_equal(dat1.(x1), dat2.(x2))) Then Begin
                 dprint, dlev = [0], 'Array mismatch for: '+rv_arr[0, j]+ ' Retaining larger arrays'
              Endif
              If(count Eq 0) Then undefine, dat
              count = count+1
              If(n_elements(dat1.(x1)) Gt n_elements(dat2.(x2))) Then Begin
                 str_element, dat, rv_arr[0, j], dat1.(x1), /add_replace
              Endif Else Begin
                 str_element, dat, rv_arr[0, j], dat2.(x2), /add_replace
              Endelse                 
           Endelse
        Endif Else Begin ;records vary
           t1 = dat1.(x1)
           t2 = dat2.(x2)
           t1 = size(t1[0,*,*,*,*])
           t2 = size(t2[0,*,*,*,*])
           If(Not array_equal(t1, t2)) Then Begin
              dprint, dlev = [0], 'Array mismatch for: '+rv_arr[0,j]
              Return, -1
           Endif Else Begin
              If(count Eq 0) Then undefine, dat
              count = count+1
              str_element, dat, rv_arr[0, j], [dat1.(x1), dat2.(x2)], /add_replace
           Endelse
        Endelse
     Endelse
  Endfor
  Return, dat
End
