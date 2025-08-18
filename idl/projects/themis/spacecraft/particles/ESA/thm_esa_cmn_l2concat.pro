;+
;NAME:
; thm_esa_cmn_l2concat
;PURPOSE:
; concatenates two THEMIS ESA L2 data structures
;CALLING SEQUENCE:
; dat = thm_esa_cmn_l2concat(dat1, dat2)
;INPUT:
; cmn_dat = a structrue with the data:
;   PROJECT_NAME    STRING    'THEMIS'
;   SPACECRAFT      STRING    'c'
;   DATA_NAME       STRING    'IESA 3D Reduced'
;   APID            INT           1109 (Apids in filenames are hex values)
;   UNITS_NAME      STRING    'eflux'
;   UNITS_PROCEDURE STRING    'thm_convert_esa_units'
;   VALID           BYTE      Array[ntimes]
;   TIME            DOUBLE    Array[ntimes]
;   END_TIME        DOUBLE    Array[ntimes]
;   DELTA_T         DOUBLE    Array[ntimes]
;   INTEG_T         DOUBLE    Array[ntimes]
;   DT_ARR          FLOAT     Array[ntimes,88, 8]
;   CONFIG1         BYTE      Array[ntimes]
;   CONFIG2         BYTE      Array[ntimes]
;   AN_IND          INT       Array[ntimes]
;   EN_IND          INT       Array[ntimes]
;   MODE            INT       Array[ntimes]
;   NENERGY         INT       Array[8] ;there are 8 different possible
;                                      ;modes
;   ENERGY          FLOAT     Array[32, 8]
;   DENERGY         FLOAT     Array[32, 8]
;   NBINS           INT       Array[8]
;   THETA           FLOAT     Array[32, 88, 8]
;   DTHETA          FLOAT     Array[32, 88, 8]
;   PHI             FLOAT     Array[32, 88, 8]
;   DPHI            FLOAT     Array[32, 88, 8]     
;   DOMEGA          FLOAT     Array[32, 88, 8]
;   GF              FLOAT     Array[32, 88, 8]
;   ECLIPSE_DPHI    DOUBLE    Array[ntimes]
;   PHI_OFFSET      FLOAT    Array[ntimes]
;   GEOM_FACTOR     FLOAT        0.00153000
;   DEAD            FLOAT       1.70000e-07
;   MASS            FLOAT         0.0104389
;   CHARGE          FLOAT           1.00000
;   SC_POT          FLOAT     Array[ntimes]
;   MAGF            FLOAT     Array[ntimes, 3]
;   BKG_PSE         FLOAT     Array[ntimes]
;   BKG_PEI         FLOAT     Array[ntimes]
;   BKG             FLOAT     Array[ntimes]
;   BKG_ARR         FLOAT     Array[32, 88, 8]
;Added in this program
;   BINS            BYTE      Array[ntimes, 32, 88]
;   EFF             FLOAT     Array[ntimes, 32, 88]
;   EFLUX           FLOAT     Array[ntimes, 32, 88];
;   NENERGY_MODES   BYTE         8
;   NBIN_MODES      BYTE         8
;   DATA_QUALITY    INT       Array[ntimes]
;OUTPUT:
; dat = a single structure concatenated
;HISTORY:
; Hacked from FAST ESA version 24-Oct-2022, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-11-08 11:44:09 -0800 (Tue, 08 Nov 2022) $
; $LastChangedRevision: 31250 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_cmn_l2concat.pro $
;-
Function thm_esa_cmn_l2concat, dat1, dat2

;Record varying arrays are concatenated, NRV values must be
;equal. rv_flag is one for tags that will be concatenated
  If(dat1.data_name Ne dat2.data_name) Then Begin
     dprint, 'Mismatch in data_name '+dat1.data_name+' '+dat2.data_name
     Return, -1
  Endif
  rv_arr = thm_esa_cmn_l2vararr(dat1.data_name)

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
