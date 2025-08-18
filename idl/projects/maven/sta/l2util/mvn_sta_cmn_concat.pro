;+
;NAME:
; mvn_sta_cmn_concat
;PURPOSE:
; concatenates two MAVEN STA commonblick structures
;CALLING SEQUENCE:
; dat = mvn_sta_cmn_concat(dat1, dat2)
;INPUT:
; dat1, dat2 = two MAVEN STA data structures: e.g., 
;   PROJECT_NAME    STRING    'MAVEN'
;   SPACECRAFT      STRING    '0'
;   DATA_NAME       STRING    'C6 Energy-Mass'
;   APID            STRING    'C6'
;   UNITS_NAME      STRING    'counts'
;   UNITS_PROCEDURE STRING    'mvn_sta_convert_units'
;   VALID           INT       Array[21600]
;   QUALITY_FLAG    INT       Array[21600]
;   TIME            DOUBLE    Array[21600]
;   END_TIME        DOUBLE    Array[21600]
;   DELTA_T         DOUBLE    Array[21600]
;   INTEG_T         DOUBLE    Array[21600]
;   MD              INT       Array[21600]
;   MODE            INT       Array[21600]
;   RATE            INT       Array[21600]
;   SWP_IND         INT       Array[21600]
;   MLUT_IND        INT       Array[21600]
;   EFF_IND         INT       Array[21600]
;   ATT_IND         INT       Array[21600]
;   NENERGY         INT             32
;   ENERGY          FLOAT     Array[9, 32, 64]
;   DENERGY         FLOAT     Array[9, 32, 64]
;   NBINS           INT              1
;   BINS            INT       Array[1]
;   NDEF            INT              1
;   NANODE          INT              1
;   THETA           FLOAT           0.00000
;   DTHETA          FLOAT           90.0000
;   PHI             FLOAT           0.00000
;   DPHI            FLOAT           360.000
;   DOMEGA          FLOAT           8.88577
;   GF              FLOAT     Array[9, 32, 4]
;   EFF             FLOAT     Array[128, 32, 64]
;   GEOM_FACTOR     FLOAT       0.000195673
;   NMASS           INT             64
;   MASS            FLOAT         0.0104389
;   MASS_ARR        FLOAT     Array[9, 32, 64]
;   TOF_ARR         FLOAT     Array[5, 32, 64]
;   TWT_ARR         FLOAT     Array[5, 32, 64]
;   CHARGE          FLOAT           1.00000
;   SC_POT          FLOAT     Array[21600]
;   MAGF            FLOAT     Array[21600, 3]
;   QUAT_SC         FLOAT     Array[21600, 4]
;   QUAT_MSO        FLOAT     Array[21600, 4]
;   BINS_SC         LONG      Array[21600]
;   POS_SC_MSO      FLOAT     Array[21600, 3]
;   BKG             FLOAT     Array[21600, 32, 64]
;   DEAD            DOUBLE    Array[21600, 32, 64]
;   DATA            DOUBLE    Array[21600, 32, 64]
;OUTPUT:
; dat = a single structure concatenated
;HISTORY:
; 19-may-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-02-22 12:07:21 -0800 (Wed, 22 Feb 2023) $
; $LastChangedRevision: 31504 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_cmn_concat.pro $
;-
Function mvn_sta_cmn_concat, dat1, dat2

;Record varying arrays are concatenated, NRV values must be
;equal. rv_flag is one for tags that will be concatenated. This will
;need to be kept up_to_date
  If(dat1.apid Ne dat2.apid) Then Begin
     dprint, 'Mismatch in apid '+dat1.apid+' '+dat2.apid
     Return, -1
  Endif
  rv_arr = mvn_sta_cmn_l2vararr(dat1.apid)

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
;Arrays must be equal
           If(Not array_equal(dat1.(x1), dat2.(x2))) Then Begin
;If the two arrays have the same number of elements, then use the
;first anyway
              dprint, dlev = [0], 'Array mismatch for: '+rv_arr[0, j]
              If(n_elements(dat1.(x1)) Eq n_elements(dat2.(x2))) Then Begin
                 dprint, dlev = [0], 'Using first value for conacatenation:'+rv_arr[0, j]
                 If(count Eq 0) Then undefine, dat
                 count = count+1
                 str_element, dat, rv_arr[0, j], dat1.(x1), /add_replace
              Endif Else Begin
                 dprint, dlev = [0], 'Not concatenating and returning'
                 Return, -1
              Endelse
           Endif Else Begin
              If(count Eq 0) Then undefine, dat
              count = count+1
              str_element, dat, rv_arr[0, j], dat1.(x1), /add_replace
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
