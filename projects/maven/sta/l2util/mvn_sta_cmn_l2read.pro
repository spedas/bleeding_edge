;+
;NAME:
; mvn_sta_cmn_l2read
;PURPOSE:
; Reads an L2 file and fills a common block structure.
;CALLING SEQUENCE:
; cmn_dat = mvn_sta_cmn_l2read(filename, trange = trange)
;INPUT:
; filename = the input filename
;OUTPUT:
; cmn_dat = a structrue with the data:
; tags are:   
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
;KEYWORDS:
; trange = if set, then only input data for that time range, the first
;          step would be to input the record times and then obtain a
;          record range to input.
; cdf_info = the full structure from CDF_LOAD_VARS2, not everything in
;            here ends up in the structure for the common blocks
; bkg_sub = if set, then load a background file, for the same apid
;            and date, put background level into structure, and
;            recalculate eflux for that apid
; iv_level = level of the background file, default is iv_level = 1
;HISTORY:
; 2014-05-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-09-20 13:24:28 -0700 (Tue, 20 Sep 2022) $
; $LastChangedRevision: 31108 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/mvn_sta_cmn_l2read.pro $
;-
Function mvn_sta_cmn_l2read, filename, trange = trange, cdf_info = cdfi, $
                             iv_level = iv_level, iv_cdf_info = ivcdfi, $
                             bkg_sub = bkg_sub, _extra = _extra

  otp = -1
;Is there a file?
  If(~is_string(file_search(filename))) Then Begin
     dprint, 'No file: '+filename
     Return, otp
  Endif
;if bkg_sub is set, there should be an equivalent file in a different
;directory with the iv_Level replacing the software version
  If(keyword_set(iv_level)) Then iv_lvl0 = iv_level Else iv_lvl0 = 1
  If(keyword_set(bkg_sub)) Then Begin
     iv_str = strcompress(string(iv_lvl0), /remove_all)
     iv_lvl = 'iv'+iv_str
;so break down the input filename
     fdir = file_dirname(filename)+'/'
     ivdir = ssw_str_replace(fdir, 'l2', iv_lvl)
     fb = file_basename(filename, '.cdf')
     tmp = strsplit(fb, '_', /extract)
     sw_vsn_str = tmp[n_elements(tmp)-1]
     ivfile = ssw_str_replace(fb, sw_vsn_str, iv_lvl)+'.cdf'
     ivfilename = ivdir+ivfile
     If(~is_string(file_search(ivfilename))) Then Begin
        dprint, 'No file: '+ivfilename
        dprint, 'No Background loaded'
     Endif
  Endif

;If trange is set, then use it
  If(n_elements(trange) Eq 2) Then Begin
     tr0 = time_double(trange)
;Read in the time_unix array
     tstr = cdf_load_vars2(filename, varformat = 'time_unix', spdf_dependencies = 0)
     ss_tvar = where(tstr.vars.name Eq 'time_unix', nss_tvar)
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
        dprint, 'No data in time range:'+time_string(tr0)+' for:'+filename
        Return, otp
     Endif
     record = ss_t[0]
     number_records = nss_t
;Read in all of the variables now
     cdfi = cdf_load_vars2(filename, /all, record = record, $
                           number_records = number_records)
     If(keyword_set(bkg_sub)) Then Begin
        ivcdfi = cdf_load_vars2(ivfilename, /all, record = record, $
                                number_records = number_records)
     Endif Else ivcdfi = -1
  Endif Else Begin
;Just read everything
     cdfi = cdf_load_vars2(filename, /all)
     If(keyword_set(bkg_sub)) Then Begin
        ivcdfi = cdf_load_vars2(ivfilename, /all)
     Endif Else ivcdfi = -1
  Endelse

;The vars array will be 2Xnvariables, the first column is the name in
;the cmn_dat structure, and the second column is the name in the CDF
;file.
  apid_var = where(cdfi.vars.name Eq 'apid', napid)
  If(napid Eq 0) Then Begin
     dprint, 'No Apid in filename: '+filename
     return, otp
  Endif
  apid = *cdfi.vars[apid_var].dataptr
  vars = mvn_sta_cmn_l2vararr(apid)

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
  If(count Gt 0) Then Begin
     If(keyword_set(bkg_sub) && is_struct(ivcdfi)) Then Begin
        ;Only extract the bkg array
        this_var = where(strlowcase(ivcdfi.vars.name) Eq 'bkg', nthis_var)
        If(nthis_var Eq 0) Then Begin
           dprint, 'No CDF variable: BKG'
        Endif Else If(~ptr_valid(ivcdfi.vars[this_var[0]].dataptr)) Then Begin
           dprint, 'No data in CDF variable: BKG'
        Endif Else Begin ;no error check
           cmn_dat.bkg = *ivcdfi.vars[this_var[0]].dataptr ;str_element shouldn't be needed
;           str_element, cmn_dat, cmnvars[j], *icdfi.vars[this_var[0]].dataptr, /add_replace
        Endelse
;Recalculate eflux
        mvn_sta_l2eflux, cmn_dat
     Endif
;quick test for iv1 data
;     printf, 1, 'FILE: '+filename ;remember to change this
;     If(tag_exist(cmn_dat, 'eflux')) Then printf, 1,
;     minmax(cmn_dat.eflux)
     If(tag_exist(cmn_dat, 'eflux') && size(cmn_dat.eflux, /type) Eq 5) Then $
        str_element, cmn_dat, 'eflux', float(cmn_dat.eflux), /add_replace
     Return, cmn_dat 
  Endif Else Return, otp

End




     
        
     
