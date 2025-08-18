;+
;NAME:
; fa_esa_cmn_l2read
;PURPOSE:
; Reads an L2 file and fills a common block structure.
;CALLING SEQUENCE:
; cmn_dat = fa_esa_cmn_l2read(filename, trange = trange)
;INPUT:
; filename = the input filename
;OUTPUT:
; cmn_dat = a structrue with the data:
; tags are:   
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
;KEYWORDS:
; trange = if set, then only input data for that time range, the first
;          step would be to input the record times and then obtain a
;          record range to input.
; cdf_info = the full structure from CDF_LOAD_VARS, not everything in
;            here ends up in the structure for the common blocks
;HISTORY:
; 2014-05-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-03-28 15:56:35 -0700 (Mon, 28 Mar 2016) $
; $LastChangedRevision: 20609 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_cmn_l2read.pro $
;-
Function fa_esa_cmn_l2read, filename, trange = trange, cdf_info = cdfi, _extra = _extra

  otp = -1
;Is there a file?
  If(~is_string(file_search(filename))) Then Begin
     dprint, 'No file: '+filename
     Return, otp
  Endif

;If trange is set, then use it
  If(n_elements(trange) Eq 2) Then Begin
     tr0 = time_double(trange)
;Read in the time_unix array
     tstr = cdf_load_vars(filename, varformat = 'time_unix', spdf_dependencies = 0)
     ss_tvar = where(tstr.names Eq 'time_unix', nss_tvar)
     If(nss_tvar Eq 0) Then Begin
        dprint, 'Oops, no time_unix variable in: '+filename
        Return, otp
     Endif
     If(~ptr_valid(tstr.vars[ss_tvar].dataptr)) Then Begin
        dprint, 'Oops, no valid time_unix pointer in: '+filename
        Return, otp
     Endif
     t = *tstr.vars[ss_tvar].dataptr
     ss_t = where(t Ge tr0[0] And t Lt tr0[1], nss_t)
     If(nss_t Eq 0) Then Begin
        dprint, 'No data in time range:'+time_string(tr0)
        Return, otp
     Endif
     record = ss_t[0]
     number_records = nss_t
;Read in all of the variables now
     cdfi = cdf_load_vars(filename, /all, record = record, number_records = number_records)
  Endif Else Begin
;Just read everything
     cdfi = cdf_load_vars(filename, /all)
  Endelse

;The vars array will be 2Xnvariables, the first column is the name in
;the cmn_dat structure, and the second column is the name in the CDF
;file.
  data_name_var = where(cdfi.vars.name Eq 'data_name', ndata_name)
  If(ndata_name Eq 0) Then Begin
     dprint, 'No Data_Name in filename: '+filename
     return, otp
  Endif
  data_name = *cdfi.vars[data_name_var].dataptr
  vars = fa_esa_cmn_l2vararr(data_name)

  cmnvars = strlowcase(reform(vars[0, *]))
  cdfvars = strlowcase(reform(vars[1, *]))
 
;Now recover the common block array
  nv = n_elements(cmnvars)
  count = 0
;It's a good idea to undefine the output array, str_element will 
;redefine it
  undefine, cmn_dat
  For j = 0, nv-1 Do Begin
     this_var = where(cdfi.vars.name Eq cdfvars[j], nthis_var)
     dvar = ''
     If(nthis_var Eq 0) Then Begin
        dprint, 'No CDF variable: '+cdfvars[j]
     Endif Else If(~ptr_valid(cdfi.vars[this_var[0]].dataptr)) Then Begin
        dprint, 'No data in CDF variable: '+cdfvars[j]	
     Endif Else Begin
	dvar = *cdfi.vars[this_var[0]].dataptr
        str_element, cmn_dat, cmnvars[j], dvar, /add
        count = count+1
     Endelse
  Endfor

;Done, cmn_dat is only defined if count > 0
  If(count Gt 0) Then Return, cmn_dat Else Return, otp

End




     
        
     
