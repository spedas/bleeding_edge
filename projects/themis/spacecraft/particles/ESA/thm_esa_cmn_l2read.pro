;+
;NAME:
; thm_esa_cmn_l2read.pro
;PURPOSE:
; Inputs a THEMIS ESA common block structure from an L2 CDF.
;CALLING SEQUENCE:
; cmn_dat = thm_esa_cmn_l2load(filename, trange = trange, cdf_info=cdf_info)
;INPUT:
; filename = the input filename
;OUTPUT:
; cmn_dat = a structrue with the data:
;e.g.,
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
;                                      ;modes for reduced electrons
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
;   DATA_LEVEL      STRING    'Level 2'
;   BINS            BYTE      Array[ntimes, 32, 88]
;   EFF             FLOAT     Array[ntimes, 32, 88]
;   EFLUX           FLOAT     Array[ntimes, 32, 88]
;   NENERGY_MODES   BYTE         8
;   NBIN_MODES      BYTE         8
;   DATA_QUALITY    INT       Array[ntimes]
;KEYWORDS:
; trange = if set, then only input data for that time range, the first
;          step would be to input the record times and then obtain a
;          record range to input.
; cdf_info = the full structure from CDF_LOAD_VARS2
; gatt = the global attributes from the CDF file
; vatt = the variable attributes for the variables included in the output
;HISTORY:
; 2022-10-31, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-11-07 12:26:32 -0800 (Mon, 07 Nov 2022) $
; $LastChangedRevision: 31243 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_cmn_l2read.pro $
;-
Function thm_esa_cmn_l2read, filename, trange = trange, $
                             cdf_info = cdfi, gatt = gatt, $
                             cmn_att = cmn_att, _extra = _extra

  otp = -1
;Is there a file?
  If(~is_string(file_search(filename))) Then Begin
     dprint, 'No file: '+filename
     Return, otp
  Endif
;If trange is set, then use it
  If(n_elements(trange) Eq 2) Then Begin
     tr0 = time_double(trange)
;Read in the time array
     tstr = cdf_load_vars2(filename, varformat = 'time', spdf_dependencies = 0)
     ss_tvar = where(tstr.vars.name Eq 'time', nss_tvar)
     If(nss_tvar Eq 0) Then Begin
        dprint, 'Oops, no time variable in: '+filename
        Return, otp
     Endif
     If(~ptr_valid(tstr.vars[ss_tvar].dataptr)) Then Begin
        dprint, 'Oops, no valid time pointer in: '+filename
        Return, otp
     Endif
     t = *tstr.vars[ss_tvar].dataptr
     ss_t = where(t Ge tr0[0] And t Lt tr0[1], nss_t)
     If(nss_t Eq 0) Then Begin
        dprint, 'No data in time range:'+time_string(tr0)+' for:'+filename
        Return, otp
     Endif
     record = ss_t[0]
     number_records = nss_t
;Read in all of the variables now
     cdfi = cdf_load_vars2(filename, /all, record = record, $
                           number_records = number_records)
  Endif Else Begin
;Just read everything
     cdfi = cdf_load_vars2(filename, /all)
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
  vars = thm_esa_cmn_l2vararr(data_name)

  cmnvars = strlowcase(reform(vars[0, *]))
  cdfvars = strlowcase(reform(vars[1, *]))
 
;Now recover the common block array
  nv = n_elements(cmnvars)
  count = 0
;It's a good idea to undefine the output arrays, str_element will 
;redefine
  undefine, cmn_dat
  undefine, cmn_att
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
        avar = *cdfi.vars[this_var[0]].attrptr
        str_element, cmn_att, cmnvars[j]+'_attr', avar, /add
     Endelse
  Endfor
;Done, cmn_dat is only defined if count > 0
  If(count Gt 0) Then Return, cmn_dat Else Return, otp

End
