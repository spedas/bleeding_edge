;+
;NAME:
; mvn_sta_cmn_tclip
;PURPOSE:
; applies a trange to a STATIC common block structure
;CALLING SEQUENCE:
; dat = mvn_sta_cmn_tclip(dat, trange)
;INPUT:
; dat1 = a MAVEN STA data structure: e.g., 
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
;   DEAD            FLOAT     Array[21600, 32, 64]
;   DATA            DOUBLE    Array[21600, 32, 64]
;OUTPUT:
; dat = structure with data only in the time range
;NOTES:
; Only will work if the reocrd varying arrays are 5D or less 
;HISTORY:
; 19-may-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-01-10 13:58:40 -0800 (Tue, 10 Jan 2017) $
; $LastChangedRevision: 22570 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_cmn_tclip.pro $
;-
Function mvn_sta_cmn_tclip, dat1, trange

  If(n_elements(trange) Ne 2) Then Begin
     dprint, dlevel = [0], 'Bad time range:'
     Return, -1
  Endif

;Record varying arrays are clipped rv_flag is 'Y' for tags that will
;be clipped.
  rv_arr = mvn_sta_cmn_l2vararr(dat1.apid)
  
  nvar = n_elements(rv_arr[0, *])
  tags1 = tag_names(dat1)
  ntags1 = n_elements(tags1)

  xtime = where(tags1 Eq 'TIME', nxtime)
  If(nxtime Eq 0) Then Begin
     dprint, dlev = [0], 'Missing tag: TIME'
     Return, -1
  Endif Else Begin
     tr0 = time_double(trange)
     ok = where(dat1.time Ge tr0[0] And dat1.time Lt tr0[1], nok)
     If(nok Eq 0) Then Begin
        dprint, dlev = [0], 'No data in interval: '
        dprint, dlev = [0], time_string(tr0[0])+ ' -- '+time_string(tr0[1])
        Return, -1
     Endif
  Endelse
        
;The ok array exists here
  count = 0
  dat = -1
  For j = 0, nvar-1 Do Begin
     x1 = where(tags1 Eq rv_arr[0, j], nx1)
     If(nx1 Eq 0) Then Begin
        dprint, 'Ignoring missing tag: '+rv_arr[0, j]
     Endif Else Begin
        If(rv_arr[2, j] Eq 'N') Then Begin
           If(count Eq 0) Then undefine, dat
           count = count+1
           str_element, dat, rv_arr[0, j], dat1.(x1), /add_replace
        Endif Else Begin        ;records vary
           t1 = dat1.(x1)
           If(count Eq 0) Then undefine, dat
           count = count+1
           str_element, dat, rv_arr[0, j], t1[ok, *, *, *, *], /add_replace
        Endelse
     Endelse
  Endfor

  Return, dat
End

