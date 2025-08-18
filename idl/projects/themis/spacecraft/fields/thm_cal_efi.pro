;+
;
;Procedure THM_PUT_ELEMENT()
;
;Purpose:
;  Put data into a substructure (1 level down) given the structure, the substructure tag name, and the data tag name.
;
;Syntax:
;  thm_put_element , struct, sstruct_tag, data_tag, data
;
;  where
;
;  STRUCT:		The structure to receive the data.
;  SSTRUCT_TAG:		The substructure tag name to receive the data (need not exist).
;  DATA_TAG:		The data tag name.
;  DATA:		The data.
;
;Keywords:
;  None.
;
;Code:
;  W. Michael Feuerstein, 16 June, 2009.
;
;-

pro thm_put_element, struct, sstruct_tag, data_tag, data

  ; Was failing for the case when there were no gaps detected
  ; but gap_begin or gap_end args are present.

  if undefined(data) then return

  if undefined(struct) then begin
    struct = create_struct(sstruct_tag, create_struct(data_tag, data))
  endif else begin
    undefine, struct0
    str_element, struct, sstruct_tag, struct0, success = successful, index = index
    if successful && (index ge 0) then begin
      temp = create_struct(struct.(index), data_tag, data)
      wtemp = where(lindgen(n_tags(struct)) ne index)
      if wtemp[0] ne -1 then begin
        tag_names = tag_names(struct)
        temp3 = create_struct(tag_names[wtemp[0]], struct.(wtemp[0]))
        if n_elements(wtemp) gt 1 then begin
          for i = 1, n_elements(wtemp)-1 do temp3 = create_struct(temp3, tag_names[i], struct.(i))
        endif
        temp2 = create_struct(temp3, sstruct_tag, temp)
      endif else temp2 = create_struct(sstruct_tag, temp)
      struct = temporary(temp2)
    endif else begin
      str_element, struct, sstruct_tag, create_struct(data_tag, data), /add
    endelse
  endelse
  
end

;+
;
;function THM_GET_EFI_EDC_OFFSET()
;
;Purpose:
;  Estimate the EDC offset by low-pass filtering the ADC data with a moving estimation window.  Returns all NaNs, if the data interval is shorter than
;  the minimum number of spins (see MIN_N_SPINS kw).
;
;Syntax:
;  result = thm_get_efi_edc_offset(Y, Sample_Rate, N_Spins, Spin_Period [, Offset_Estimation_Window_Truncated] [, NEW_N_SPINS] [, MIN_N_SPINS = <long>])
;
;  where
;
;  Y (n-element array)			Input		The ADC data needing the EDC offset calculation.
;  Sample_Rate 				Input		The data rate.
;  N_Spins 				Input		The width of the estimation window in # of spins
;  Spin_Period 				Input		The period of a spin [s].
;  Edge_Truncate			Input		Passed to SMOOTH, if SMOOTH is the estimation function.
;  Offset_Estimation_Window_Truncated	Output		Indicates that the data interval is shorter than the estimation window requested, so the estimation
;							window has been truncated to the greatest integral number of spins that fit into the data interval.
;  New_N_Spins				Output		If OFFSET_ESTIMATION_WINDOW_TRUNCATED is set, then this will contain the adjusted number of spins.
;
;Keywords:
;  MIN_N_SPINS				I/O, long.  	1 <= MIN_N_SPINS <= NOMINAL_N_SPINS.  Specify the lower limit for NOMINAL_N_SPINS.  Defaults to 1.
;
;-

function thm_get_efi_edc_offset, y, samp_rate, n_spins, spin_period, edge_truncate, offset_estimation_window_truncated, n_spins_temp, min_n_spins = min_n_spins 
  
  compile_opt idl2

; Initialize outputs:
;
  undefine, n_spins_temp
  offset_estimation_window_truncated = 0b
  if undefined(min_n_spins) then min_n_spins = 1L
  
  npts = ceil(float(n_spins)*spin_period*samp_rate) ; width of smoothing window in # of points.
  n_y = n_elements(y)

  if npts ge n_y then begin
    offset_estimation_window_truncated = 1b
    npts = (n_y mod 2) ? n_y-2 : n_y-1 ; if chunk is less than N_SPINS wide, then make NPTS just fit.
    n_spins_temp = floor(npts/spin_period/samp_rate) ; recalculate N_SPINS (N_SPINS_TEMP) as least whole # w/in interval.
;
    if n_spins_temp lt min_n_spins then begin
      undefine, offset_estimation_window_truncated
      undefine, n_spins_temp
      return, replicate(!values.f_nan, n_y)
    endif
;
    npts = ceil(float(n_spins_temp)*spin_period*samp_rate) ; recalculate NPTS.
  endif

  return, smooth(y, npts, /nan, edge_truncate = edge_truncate)

;; Notes on hanning method:
;;
;kernel = hanning(npts)
;for icomp = 0, 1l do d_smooth[*,icomp] = $
;  fix(round(convol(float(d.y[w, icomp]), kernel, total(kernel), /nan)))   ;convol in float, return in int.

end                             ;thm_get_edc_offset_efi 


;+
;
;THM_UPDATE_EFI_LABELS.PRO
;
;PURPOSE:
;To be used on THEMIS EFI 3-vectors.  Labels x-axis as "E12
;(<coordinate system in DLIMITS.LABLES>)" for spinning coordinate
;systems and "Ex (<coord. sys. in DLIMITS.LABELS>)" for despun
;coordinate systems.  Y and Z axes are upadated correspondingly.  Call
;after coordinate transformations.
;
;SYNTAX:
;  thm_update_efi_labels ,<String>
;
;Arguments:
;  <String>: A TPLOT variable name referring to a 3-vector TPLOT variable.
;
;Code: W. Michael Feuerstein, 7/2008.
;
;-

pro thm_update_efi_labels, tvarname
  
  compile_opt idl2, hidden

  coord = cotrans_get_coord(tvarname)
  if where(coord eq ['spg', 'ssl']) ge 0 then $
    options, /default, tvarname, 'labels', ['E12', 'E34', 'E56']+' ('+coord+')' else $
    options, /default, tvarname, 'labels', ['Ex', 'Ey', 'Ez']+' ('+coord+')'

end


;+
;Procedure: THM_CAL_EFI
;
;Purpose:  Converts raw EFI (V, EDC, and EAC waveform) data into physical quantities.
;
;Syntax:  THM_CAL_EFI [, <optional keywords below>]
;keywords:
;   VERBOSE:		Input, >= 1.  Set to enable diagnostic message output.  Higher values of produce more and lower-level diagnostic messages.
;   DATATYPE:		Input, string.  Default setting is to calibrate all raw quantites and also produce all _0 and _dot0 quantities.  Use DATATYPE
;                       kw to narrow the data products.  Wildcards and glob-style patterns accepted (e.g., ef?, *_dot0).
;   PROBE:		Input, string.  Specify space-separated probe letters, or string array (e.g., 'a c', ['a', 'c']).  Defaults to all probes.
;   VALID_NAMES:	Output, string.  Return valid datatypes, print them, and return.
;   COORD:		I/O, string.  Set to coordinate system of output (e.g., 'gse', 'spg', etc,... see THEMIS Sci. Data Anal. Software
;			Users Guide).  Defaults to 'dsl'.
;   IN_SUFFIX:		Input, scalar or array string.  Suffix to expect when parsing input TPLOT variable names.
;   OUT_SUFFIX:		I/O, scalar or array string.  Suffix to append to output TPLOT variable names in place of IN_SUFFIX (usally = IN_SUFFIX).
;   TEST: 		1 or 0.  Disables selected /CONTINUE to MESSAGE.  For QA testing only.
;   STORED_TNAMES: 	OUTPUT, string array.  Returns each TPLOT variable name invoked in a STORE_DATA operation (chron. order).  (Not sorted or uniqued.)
;   ONTHEFLY_EDC_OFFSET:OUTPUT, float.  Return the EDC offset array calculated on-the-fly in a structure (tag name = probe letter, subtagname =
;                       datatype).  *** WARNING: This kw can use a lot
;                       of memory, if processing many datatypes, or
;                       long time periods. ***
;   NO_EDC_OFFSET:      I/O, 0 or 1. If set, do not preform an EDC offset calculation. Will also avoid dot0 and_0 calculations, and not perform coordinate transforms
;   GAP_TRIGGER_VALUE: 	I/O, float, > 0.  For on-the-fly EDC offset calculation, consider anything greater than or equal to GAP_TRIGGER_VALUE to be
;               	a gap in the data.  Default: 0.5 s.
;   NOMINAL_N_SPINS: 	I/O, long, >= 1.  Specify the number of spins for the on-the-fly EDC offset calculation estimation window, or
;                    	read out the default (20 spins).
;   MIN_N_SPINS:	I/O, long, 1 <= MIN_N_SPINS <= NOMINAL_N_SPINS.  Specify the lower limit for NOMINAL_N_SPINS.
;   OFFSET_ESTIMATION_FUNC: OUTPUT, scalar string.  The name of the function used to estimate the EDC offset for the on-the-fly window. 
;   /EDGE_TRUNCATE: 	I/O, numeric, 0 or 1.  Set to 0 to disable edge truncation in SMOOTH (for the on-the-fly offset calculation).  Assign
;                       to a variable to read the default (= 1).  Undefined, if on-the-fly offset not done.
;   GAP_BEGIN, GAP_END: OUTPUT, double, >= 0.  Return (if they exist), the double-precision start and end times of all
;               	gaps detected in preparation for on-the-fly offset calculation.  See kw ONTHEFLY_EDC_OFFSET for structure format and warnings.
;   TRY_DESPIKE:        If set, despike the raw E field data before
;                       calibration, uses function SIMPLE_DESPIKE_1d
;                       for the calculation.
;   DESPIKE_THRESHOLD:  Threshold in ADC units for despike
;                       calculation, the default is 200
;   DESPIKE_WIDTH:      Half Width of the median filter used for the
;                       despike calculation, the default is 11
;   keyword parameters for _dot0 computation:
;
;   MAX_ANGLE:		Input, float.  Maximum angle of B field to spin axis to calculate _dot0.  Typical = 80 degrees.  No default.
;   MIN_BZ:		I/O, float.  Minimum value of Bz.  Typical value is 2.0 nT.  Default= 1.0 nT.  If argument not defined, returns default.  Not
;			compatible with MAX_ANGLE keyword.
;   MAX_BXY_BZ:		Input, float.  Maximum value of abs(bx/bz) or abs(by/bz).  Typical value is 5. ~= tan(79 degrees) (think of Bx/Bz).  Default is
;			not to use this method (no default value).
;   BZ_OFFSET:		I/O, float.  Offset in nT that will be added to Z axis measurement of B.  Defaults to 0.0.  If argument not defined, returns default.
;   FGM_DATATYPE:	Input, string.  'fgl', 'fgh', 'fgs' or 'fge'.
;   FGM_LEVEL:          Input, 'l1' or 'l2', default is 'l2'
;
; use_eclipse_corrections:  Only applies when loading and calibrating
;   Level 1 data. Defaults to 0 (no eclipse spin model corrections 
;   applied).  use_eclipse_corrections=1 applies partial eclipse 
;   corrections (not recommended, used only for internal SOC processing).  
;   use_eclipse_corrections=2 applies all available eclipse corrections.

;
;Example:
;   thm_cal_efi, probe='c'
;
;Modifications:
;  Added boom_shorting_factor_e12, boom_shorting_factor_e34,
;    offset_e12, offset_e34, offset_dsc_x, offset_dsc_y
;    fields to data_att structure in the default limits structure.
;    Also, added mechanism to fill new field from
;    THM_GET_EFI_CAL_PARS.PRO, W.M.Feuerstein, 2/26-27/2008.
;  Changed "History" to "Modifications" in header, made "1000" a float ("."),
;    switched all internal calibration parameters over to those read through
;    THM_GET_EFI_CAL_PARS.PRO, WMF, 3/12/2008.
;  Updated DATA_ATT fields to match revised cal. files, WMF, 3/12/2008.
;  Updated error handling, updated doc'n, WMF, 3/12/2008.
;  Updated doc'n, made datatypes more consistent (speed), WMF, 3/14/2008.
;  Changed "no default" for MIN_BZ kw to default=1.0 nT, fixed MAX_ANGLE
;    and MIN_BZ kwd's "both set" handling, WMF, 3/14/2008.
;  Changed an NaN multiplication to an assignment (speed), simplified MIN_BZ
;    default assignment, turned on good practice compile options,
;    reorganized opening statements (flow), turned off ARG_PRESENT(MAX_BXY_BZ)
;    bug (no default for this kw), updated doc'n, WMF, 3/17/2008.
;  Now calculates Ez (_dot0 section) AFTER implementing MAX_BXY_BZ kw as per
;    J. Bonnell's request (it also happens to be faster), updated doc'n,
;    WMF, 3/18/2008.
;  Removed redundant datatype conversions, WMF, 3/20/2008.
;  Using BOOM_SHORTING_FACTOR in field calibration, WMF, 3/20/2008 (Th).
;  Fixed potential logical vs. bitwise conditional bug, WMF, 3/21/2008 (F).
;  Updated doc'n, WMF, 3/27/2008.
;  Removed "TWEAK_GAINS" kw to THM_EFI_DESPIN.PRO per J.Bonnell's req.,
;    WMF, 4/4/2008 (F).
;  Added TEST kw to disable certain /CONTINUE to MESSAGE, and passed TEST
;    through to THM_GET_EFI_CAL_PARS.PRO, WMF, 4/7/2008 (M).
;  Implemented time-dependent EAD/EDC gain conditional, WMF, 4/22/2008 (Tu).
;  Implemented time-dependent calibration parameters for v?? and
;    e?? datatypes, WMF, 5/21 - 6/5/2008.
;  Reconciled last three changes from non-time-dependent version: COORD kw is now not case
;    sensitive, made sure 'E12','E34','E56' labels go with SSL and SPG coordinates and
;    'Ex','Ey','Ez' go with all other coordinate systems (THM_UPDATE_EFI_LABELS.PRO),
;    fixed COORD='gse' crash, WMF, 8/21/2008.
;  Added error message for hed_ac = 255, WMF, 8/26/2008.
;  Renamed from "thm_cal_efi_td.pro" to "thm_cal_efi.pro", WMF, 9/9/2008.
;  Put in cases for 2 and 4 spin-dependent offsets in the boom plane, WMF, 3/4/2009.
;  Insert on NaN on FGM degap, memory management, WMF, 5/5/2009.
;  added no_edc_offset and _extra keywords, 19-aug-2010, jmm
;
;Notes:
;	-- fixed, nominal calibration pars used (gains and
;          frequency responses), rather than proper time-dependent parameters.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-05-13 14:49:32 -0700 (Tue, 13 May 2025) $
; $LastChangedRevision: 33308 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_cal_efi.pro $
;-
pro thm_cal_efi, probe = probe, datatype = datatype, $
                 valid_names = valid_names, verbose = verbose, coord = coord, $
                 in_suffix = in_suffix, out_suffix = out_suffix, max_angle = max_angle, $
                 min_bz = min_bz, max_bxy_bz = max_bxy_bz, bz_offset = bz_offset, $
                 fgm_datatype = fgm_datatype, fgm_level = fgm_level, test = test, $
                 stored_tnames = stored_tnames, $
                 onthefly_edc_offset = onthefly_edc_offset, $
                 no_edc_offset = no_edc_offset, $
                 calfile_edc_offset = calfile_edc_offset, $
                 gap_trigger_value = gap_trigger_value, $
                 nominal_n_spins = n_spins, $
                 min_n_spins = min_n_spins, $
                 offset_estimation_func = offset_estimation_func, $
                 edge_truncate = edge_truncate, $
                 gap_end = gap_end_struct, gap_begin = gap_begin_struct, $
                 try_despike=try_despike, despike_width=despike_width, $
                 despike_threshold=despike_threshold,$
                 _extra = _extra

  compile_opt idl2, strictarrsubs ;Bring this routine up to date.

  if ~undefined(in_suffix) then in_suf = in_suffix ;Keep these operations internal.
  if ~undefined(out_suffix) then out_suf = out_suffix

  undefine, onthefly_edc_offset ;Output only.

  if ~keyword_set(test) then test = 0

;Check for "max_angle" and "min_bz" kwd's both being set:
;========================================================
;if keyword_set(max_angle) and keyword_set(min_bz) then begin ;Fails on var=0.
  if size(max_angle, /type) ne 0 && size(min_bz, /type) ne 0 then begin ;This way.
    dprint, dlevel=1,'MIN_BZ and MAX_ANGLE keywords are mutually exclusive.  Returning...'
    return
  endif

  thm_init

  vb = size(verbose, /type) ne 0 ? verbose : !themis.verbose

;Define valid EFI "datatypes":
;=============================
  primary_datatypes = ['vaf', 'vap', 'vaw', 'vbf', 'vbp', 'vbw', 'eff', 'efp', 'efw'] ; note that efi_dq is deleted.
  u0s = ['eff_0', 'efp_0', 'efw_0']
  udot0s = ['eff_dot0', 'efp_dot0', 'efw_dot0']
  sfit = ['eff_e12_efs', 'eff_e34_efs', 'efp_e12_efs', 'efp_e34_efs', 'efw_e12_efs', 'efw_e34_efs']
  qflag = ['eff_q_mag', 'eff_q_pha', 'efp_q_mag', 'efp_q_pha', 'efw_q_mag', 'efw_q_pha']
  efi_valid_names = [primary_datatypes, u0s, udot0s, sfit, qflag]

;Return valid datatypes (and return), if they are called for:
;============================================================
  if arg_present(valid_names) then begin
    valid_names = efi_valid_names
    dprint, dlevel=2,string(strjoin(efi_valid_names, ','), format = '("Valid names:",X,A,".")')
    return
  endif

;Set COORD default to 'dsl' (if needed) and make sure COORD is an
;array (and not just a space-separated list), and make lower case: 
;=================================================================
  if not keyword_set(coord) then coord = 'dsl' else $
    coord = n_elements(coord) gt 1 ? strlowcase(coord) : strsplit(strlowcase(coord), ' ', /extract)

; Make sure IN_SUF/OUT_SUF is an array (and not just a space-separated list), and make lower case:
;
  if keyword_set(out_suf) then $
    out_suf = n_elements(out_suf) gt 1 ? strlowcase(out_suf) : strsplit(strlowcase(out_suf), ' ', /extract)
  if keyword_set(in_suf) then $
    in_suf = n_elements(in_suf) gt 1 ? strlowcase(in_suf) : strsplit(strlowcase(in_suf), ' ', /extract)

;Set IN_SUF/OUT_SUF variables to null, if not set:
;=================================================
  if undefined(in_suf) then in_suf = ''
  if undefined(out_suf) then out_suf = ''

; If COORD has > 1 element, then ck that OUT_SUF has the same # of
; elements as COORD.  If not, issue warning and force OUT_SUF = COORD 
;
  if keyword_set(coord) && n_elements(coord) gt 1 then begin
    if n_elements(out_suf) ne n_elements(coord) then begin
      dprint, dlevel=4,'*** WARNING: OUT_SUF keyword must be set and have the same number of elements as COORD when COORD has > 1 ' + $
        "element.  Setting OUT_SUF to '_'+COORD."
      out_suf = '_'+coord
    endif
  endif

  if arg_present(out_suffix) then out_suffix = out_suf ;If the argument is present, then the kw functions as an output also.

;Define "probes" variable ("f" is not a valid probe unless it is the only
;element).  Return if "probes" does not get defined:
;===================================================
  vprobes = ['a', 'b', 'c', 'd', 'e']
  if n_elements(probe) eq 1 then if probe eq 'f' then vprobes = ['f']
  if not keyword_set(probe) then probes = vprobes else $
    probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
  if not keyword_set(probes) then return
  if keyword_set(vb) then printdat, probes, /value, varname = 'Probes'
;Define "dts" (datatypes) variable.  Return if "dts" does not get defined:
;=========================================================================
  eprimary = ['eff', 'efp', 'efw']
  if not keyword_set(datatype) then dts = efi_valid_names $
  else begin
    dts = ssl_check_valid_name(strlowcase(datatype), efi_valid_names, /include_all)
;If there are any _0 or _dot0 variables, add the appropriate eff, efw
;or efp, if not present
    For i = 0, 2 Do Begin
      test_0 = where(dts Eq eprimary[i])
;Only do this if primary dt is not in the list
      If(test_0[0] Eq -1) Then Begin
        test_1 = where((dts Eq eprimary[i]+'_0') Or $
                       (dts Eq eprimary[i]+'_dot0') Or $
                       (dts Eq eprimary[i]+'_e12_efs') Or $
                       (dts Eq eprimary[i]+'_e34_efs') Or $
                       (dts Eq eprimary[i]+'_q_mag') Or $
                       (dts Eq eprimary[i]+'_q_pha'))
        If(test_1[0] Ne -1) Then Begin
          dts = [eprimary[i], dts]
        Endif
      Endif
    Endfor
    dts = ssl_check_valid_name(strlowcase(dts), efi_valid_names) ;just reordering
  endelse
  if not keyword_set(dts) then return
  if keyword_set(vb) then printdat, dts, /value, varname = 'Datatypes'

;Make min_bz = 1.0 nT the default (as long as MAX_ANGLE is not defined!):
;========================================================================
  if ~size(min_bz, /type) && ~size(max_angle, /type) then min_bz = 1.0 ;nT

;Set BZ_OFFSET default to 0.0:
;=============================
  if ~size(bz_offset, /type) then bz_offset = 0.0
;Loop on "probes":
;=================
  for s = 0L, n_elements(probes)-1L do begin
    sc = probes[s]
;Loop on "dts":
;==============
    spinfits_done = bytarr(3) ;don't redo spinfits for each datatype -- they need to be done all at once for each eprimary datatype
    for n = 0L, n_elements(dts)-1L do begin
      name = dts[n]
;NAMERAW= 'aaa', NAME= (e.g.) 'aaa_dot0':
;========================================
      if(where(name eq u0s or name eq udot0s) ne -1) Or $
         (where(name eq sfit or name eq qflag) ne -1) then nameraw = strmid(name, 0, 3) $
      else nameraw = name
; If one of the sfit or qflag variables has been done, then they're
; all done, so skip to the end of the loop
      this_primary = where(eprimary Eq nameraw)
      If(this_primary[0] Ne -1) Then $ ;need to be careful due to voltage variables
        if (where(name eq sfit or name eq qflag) ne -1 And spinfits_done[this_primary] Eq 1) then continue
;*****************************************
;Define tplot var. names and get raw data:
;*****************************************
      tplot_var_raw = thm_tplot_var(sc, nameraw)+in_suf
      tplot_var_orig = thm_tplot_var(sc, name)
      if n_elements(out_suf) le 1 then begin ; If COORD has multiple elements, then the output suffixes will be handled on-the-fly.
        tplot_var = thm_tplot_var(sc, name)+out_suf[0]
      endif else begin
        tplot_var = thm_tplot_var(sc, name)
      endelse
;
;Test for the presence of "veryunusualprefixtempfoo_" prefixed TPLOT vars.  If not present, assume
;this call is not from THM_LOAD_EFI and look for normal (non-temporary) TPLOT vars to calibrate:
;***********************************************************************************************
      if (tnames('veryunusualprefixtempfoo_'+tplot_var_raw))[0] ne '' then begin
        get_data, 'veryunusualprefixtempfoo_'+tplot_var_raw, data = d, limit = l, dlim = dl
      endif else begin
        get_data, tplot_var_raw, data = d, limit = l, dlim = dl
      endelse
      if keyword_set(vb) then dprint, dlevel=2,string(tplot_var, format = '("Working on TPLOT variable",X,A)')
;Check to see if the data has already been calibrated:
;=====================================================
      if(thm_data_calibrated(dl)) then begin
;If DATATYPE = first three letters of DATATYPE, then the data has
;been calibrated already:
;========================
        if nameraw eq name then begin
          if keyword_set(vb) then dprint, dlevel=2,string(tplot_var, format = '(A,X,"has already been calibrated.")')
;Else it's gotta be either "_0", or "_dot0", so get cal_pars ("cp") and
;transform to 'dsl' (via THM_COTRANS for non-'dsl' and non-'spg', else via THM_EFI_DESPIN.PRO):
;==============================================================================================
        endif else begin
          thm_get_efi_cal_pars, d.x, nameraw, sc, cal_pars = cp, test = test  
          dprint, dlevel=2,'Acquiring calibration parameters for probe '+strtrim(sc, 2)+'.'
          if where(cotrans_get_coord(dl) eq ['dsl', 'spg']) lt 0 then begin
            thm_cotrans, tplot_var_raw, tplot_var, out_coord = 'dsl', $
              use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
          endif else begin
            thm_efi_despin, sc, nameraw, cp.dsc_offset[0, *], [1, 1, 1], $ ;Pass [1,1,1] in order to not duplicate boom_shorting factor.
              tplot_name = tplot_var_raw, newname = tplot_var, stored_tnames = foo, $
              use_eclipse_corrections=use_eclipse_corrections, _extra=_extra
            if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, foo] else stored_tnames = foo
          endelse
        endelse
;Otherwise, proceed with the RAW->PHYS transformation:
;=====================================================
      endif else begin
        hed_tplot_var = thm_tplot_var(sc, nameraw)
        tplot_var_hed = hed_tplot_var + '_hed'
        get_data, tplot_var_hed, data = d_hed, limit = l_hed, dlim = dl_hed
;Check that returned data and hed structures are structures
;(get_data returns 0 if no TPLOT variable exists):
;=================================================
        if (size(d, /type) eq 8) and (size(d_hed, /type) eq 8) then begin
          hed_data = thm_unpack_hed(name, d_hed.y) ;Leaving this line for reference, but product not used.  1/27/09.
;Match datatype by a switch statement, get corresponding
;calibration parameters, apply calibration, and update
;default limits structure:
;Removed switch and replaced with if then, jmm, 10-mar-2010
;=========================
          tsname = strlowcase(name) 
          If(tsname Eq 'vaf' || tsname Eq 'vbf' || tsname Eq 'vap' || $
             tsname Eq 'vbp' || tsname Eq 'vaw' || tsname Eq 'vbw') Then Begin
;Grab calibration params, and initialize result:
;***********************************************
            thm_get_efi_cal_pars, d.x, name, sc, cal_pars = cp, test = test
            dprint, dlevel=2,'Acquiring calibration parameters for probe '+strtrim(sc, 2)+'.'
            res = fltarr(size(d.y, /dimensions))
;Remember time-doubles and how many time-dependent intervals span data:
;**********************************************************************
            cptd = time_double(cp.cal_par_time) ;"Calibration Parameter Time Double."
            ntdi = n_elements(cp.cal_par_time) ;"# Time Dependent Indicies".
;Loop on time-dependent calibration intervals calibrating result for each interval:
;**********************************************************************************
            for i = 0, ntdi-1 do begin ;potential opportunity for vectorization.  Can we eliminate this loop?
;Get data time indicies for interval:
;************************************
              if i ne ntdi-1 then begin
                w = where(d.x ge cptd[i] and d.x lt cptd[i+1])
              endif else begin
                w = where(d.x ge cptd[i])
              endelse
;Calibrate, looping over EFI booms:
;**********************************
              for icomp = 0L, 5L do begin
                if ntdi eq 1 then begin
                  res[w, icomp] = cp.gain[icomp]*(d.y[w, icomp] - cp.offset[icomp])
                endif else begin
                  res[w, icomp] = cp.gain[i, icomp]*(d.y[w, icomp] - cp.offset[i, icomp]) ;This will work for both cases, now.
                endelse
              endfor
            endfor
  
;; update the DLIMIT elements to reflect RAW->PHYS
;; transformation, coordinate system, etc.
            units = cp.units    ;Now taken from cal. file.
            str_element, dl, 'data_att', data_att, success = has_data_att
            if has_data_att then begin
              str_element, data_att, 'data_type', 'calibrated', /add
            endif else data_att = {data_type: 'calibrated'}
            str_element, data_att, 'coord_sys',  'efi_sensor', /add
            str_element, data_att, 'units', units[0], /add ;We cheat here.  Only units of first interval are shown!
            str_element, data_att, 'cal_par_time', cp.cal_par_time, /add
  
;"Documented calibration factors" to match expanded
;cal. file params. (3/12/2008):
;==============================
            str_element, data_att, 'offset', cp.offset, /add
            str_element, data_att, 'gain', cp.gain, /add
            str_element, data_att, 'boom_length', cp.boom_length, /add
            str_element, data_att, 'boom_shorting_factor', $
              cp.boom_shorting_factor, /add
            
            str_element, dl, 'data_att', data_att, /add
  
            str_element, dl, 'ytitle', string(tplot_var_orig, units[0], $ ;Only units of first interval are shown!
                                              format = '(A,"!C!C[",A,"]")'), /add
            str_element, dl, 'units', units[0], /add ;Only units of first interval are shown!
            str_element, dl, 'labels', ['V1', 'V2', 'V3', 'V4', 'V5', 'V6'], /add
            str_element, dl, 'labflag', 1, /add
            str_element, dl, 'colors', [1, 2, 3, 4, 5, 6]
  
;; store the transformed spectra back into the original
;; TPLOT variable.
            store_data, tplot_var, data = {x:d.x, y: temporary(res), v:d.v}, lim = l, dlim = dl
            if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, tplot_var] $
            else stored_tnames = [tplot_var]
          Endif Else Begin ; end of {VAF, VBF, VAP, VBP, VAW, VBW} calibration clause.
;; Despike first, if requested:
            if keyword_set(try_despike) then begin
              if ~keyword_set(despike_threshold) then despike_threshold = 200.0
              if ~keyword_set(despike_width) then despike_width = 11
              ;only in spin plane
              for j = 0, 1 do d.y[*,j] = simple_despike_1d(d.y[*,j], spike_threshold=despike_threshold, width=despike_width, /use_nan)
            endif
; Only do the spin interpolation, etc for name = nameraw, which is now always to
; be included if you ewant a _dot0, _0, etc...
            If(name Eq nameraw) Then Begin
; For Metadata/settings:
; Define # of spins
              if undefined(n_spins) then begin
                n_spins = 20L   ;width of smoothing window in spins.
              endif else begin
                case 1 of
                  is_num(n_spins): n_spins = n_spins[0]
                  else: message, 'NUMBER_OF_SPINS keyword input must be scalar numeric.  Please correct input and retry.'
                endcase
              endelse
              offset_estimation_func = 'SMOOTH' ; This may be user-selectable later.
              if undefined(edge_truncate) then edge_truncate = 1b
              offset_estimation_window_truncated = 0b ; Initialize to 0 for each datatype.
              if undefined(gap_trigger_value) then gap_trigger_value = 0.5
              n_gaps = 0L
;These are boom lengths in meters:
;=================================
;e12=49.6           ;These are now taken from the cal. file.
;e34=40.4
;e56=5.63
;
;Grab calibration params, and initialize result:
;***********************************************
              thm_get_efi_cal_pars, d.x, nameraw, sc, cal_pars = cp, test = test
              dprint, dlevel=2,'Acquiring calibration parameters for probe '+strtrim(sc, 2)+'.'
              res = fltarr(size(d.y, /dimensions)) & res0 = res ;res0 is not offset, to be used for spinfits
  
;Remember time-doubles and how many time-dependent intervals span data:
;**********************************************************************
              cptd = time_double(cp.cal_par_time) ;"Calibration Parameter Time Double."
              ntdi = n_elements(cp.cal_par_time) ;"# Time Dependent Indicies".
  
;Loop on time-dependent calibration intervals calibrating result for each interval:
;**********************************************************************************
        
;potential opportunity for vectorization(can we eliminate this loop?)
              for i = 0, ntdi-1 do begin
                exx = cp.boom_length[i, *]*cp.boom_shorting_factor[i, *]

;Get data time indicies for interval:
;************************************
                if i ne ntdi-1 then begin
                  w = where(d.x ge cptd[i] and d.x lt cptd[i+1])
                endif else begin
                  w = where(d.x ge cptd[i])
                endelse
;==================
;Calculate E field:
;==================
;
;================================================================
;Test for header_ac data.  If not found, default to EAC
;gain and print warning.  If found, set accordingly:
;(This step must be done w/in NTDI loop b/c the gain may change.)
;================================================================
                tpname_hed_ac = 'th'+sc+'_'+nameraw+'_hed_ac'
                tpnames = tnames(tpname_hed_ac) ;Avoid known name length bug of TPLOT_NAMES.
                if ~(~size(tpnames, /type)) && tpnames[0] ne '' then begin
                  get_data, tpnames[0], data = data_hed_ac
;
;Index AC vs. DC-coupled points in HED_AC:
;=========================================
                  n_hed_ac = n_elements(data_hed_ac.y)
                  n_hed_ac_2 = n_hed_ac-2
                  if (where(data_hed_ac.y eq 255))[0] ge 0 then message, $
                    'Spurious "hed_ac" flag value of 255 encounterd.  Contact THEMIS software team with this error message!'
                  wac = where(data_hed_ac.y, n_wac, complement = wdc)
;
                  case 1 of
                    n_wac eq n_hed_ac: gain = cp.eac_gain[i, *]
                    n_wac eq 0: gain = cp.edc_gain[i, *]
                    else: begin
;
;GAIN will be set to EAC_GAIN (if all points are 1), EDC_GAIN
;(if all points are 0), or interpolated to TIMES otherwise:
;==========================================================
                      aci = bytarr(n_elements(w)) ;"AC Interpolated".
                      acx = data_hed_ac.x ;Do not make structure ref. inside loop.
                      acy = data_hed_ac.y ;Do not make structure ref. inside loop.
;
;Interpolation of HED_AC data:
;=============================
                      dxw = (d.x)[w] ;Do not repeat array reference inside loop.
                                ;j=0                            ;Index to HED_AC data.
                      w0 = where(acx le dxw[0])
                      j = 0 > w0[n_elements(w0)-1] ;Index of largest HED_AC index where acx le dxw[0] (get the loop started at the right spot).
;potential opportunity for vectorization
                      for k = 0, n_elements(w)-1 do begin
                        if dxw[k]-acx[j] ge acx[j+1]-dxw[k] then j = j ne n_hed_ac_2 ? ++j : j
                        aci[k] = acy[j]
                      endfor
;
;Multiply and merge:
;===================
                      gain = dblarr(n_elements(w), 3)
                      gain[*, 0] = aci*cp.eac_gain[i, 0] + (~aci)*cp.edc_gain[i, 0]
                      gain[*, 1] = aci*cp.eac_gain[i, 1] + (~aci)*cp.edc_gain[i, 1]
                      gain[*, 2] = aci*cp.eac_gain[i, 2] + (~aci)*cp.edc_gain[i, 2]
                    end
                  endcase
                endif else begin
                  message, '*** WARNING!: TPLOT variable "'+ $
                    tpname_hed_ac+ $
                    '" not found.  Defaulting to EDC gain.', $
                    continue = ~test
                  gain = cp.edc_gain[i, *]
                endelse
                case (size(cp.dsc_offset, /dimensions))[1] of
                  5: begin
;***************************************
;4 spin-dependent offsets in boom plane:
;***************************************
;
                    dprint, dlevel=2,'Using 4 spin-dependent offsets in boom plane.'
;
;Interpolate spin phase:
;=======================
;
                    dprint, dlevel=2,'Using spin model for probe '+strtrim(sc, 2)+'.'
                    thm_autoload_support, probe_in=sc, trange=minmax(d.x),/spinmodel,/spinaxis ;check for spin vars, etc.
                    model = spinmodel_get_ptr(sc,use_eclipse_corrections=use_eclipse_corrections)
                    ; These validity checks and calls to thm_load_state should
                    ; be unnecessary if thm_autoload_support works properly.
                    If(obj_valid(model) Eq 0) Then Begin ;load state data
                      thm_load_state, probe = sc, trange = minmax(d.x), /get_support_data
                      model = spinmodel_get_ptr(sc,use_eclipse_corrections=use_eclipse_corrections)
                    Endif
                    If(obj_valid(model)) Then Begin
                      spinmodel_interp_t, model = model, time = (d.x)[w], $
                        spinphase = phase, spinper = spinper, use_spinphase_correction = 1 ;a la J. L.
                      phase *= !dtor
                    Endif Else Begin
                      dprint, dlevel=2,'No state data for spin phase calculation'
                      Return
                    Endelse

;Calculate corrected (SPG) field:
;********************************
                    ex012 = cp.dsc_offset[i, 0]
                    ex034 = cp.dsc_offset[i, 1]
                    ey012 = cp.dsc_offset[i, 2]
                    ey034 = cp.dsc_offset[i, 3]
                    e012 = cp.offset[i, 0]
                    e034 = cp.offset[i, 1]
          
;GAIN is time-independent case:
;==============================
                    if (size(gain, /dimensions))[0] le 1 then begin
                      res[w, 0] = -1000.*(gain[0]/exx[0])*(d.y[w, 0] - e012)  - ex012*cos(phase) - ey012*sin(phase)
                      res[w, 1] = -1000.*(gain[1]/exx[1])*(d.y[w, 1] - e034)  + ex034*sin(phase) - ey034*cos(phase)
                      res[w, 2] = -1000.*gain[2] * (d.y[w, 2] - cp.offset[i, 2])/exx[2] ;Z [mV/m]
                      For icomp = 0, 2 Do res0[w, icomp] = -1000.*gain[icomp]*d.y[w, icomp]/exx[icomp]
;GAIN is an array case:
;======================
                    endif else begin
                      res[w, 0] = -1000.*gain[*, 0]/exx[0]*(d.y[w, 0] - e012)  - ex012*cos(phase) - ey012*sin(phase)
                      res[w, 1] = -1000.*gain[*, 1]/exx[1]*(d.y[w, 1] - e034)  + ex034*sin(phase) - ey034*cos(phase)
                      res[w, 2] = -1000.*gain[*, 2] * (d.y[w, 2] - cp.offset[i, 2])/exx[2] ;Z [mV/m]
                      For icomp = 0, 2 Do res0[w, icomp] = -1000.*gain[*, icomp]*d.y[w, icomp]/exx[icomp]
                    endelse
  
                  end
                  3: begin                    
;On-the-fly EDC offset calculation (smoothing or convolution w/ hanning window):
;*******************************************************************************
                    If(~keyword_set(no_edc_offset) && ~keyword_set(calfile_edc_offset)) Then Begin
;***************************************
;2 spin-dependent offsets in boom plane:
;***************************************
                      dprint, dlevel=2,'Using 2 spin-dependent offsets in boom plane.'
;Calibrate, looping over EFI booms:
;**********************************
; Get spinmodel info:
                      thm_autoload_support, probe_in=sc, trange=minmax(d.x), /spinmodel, /spinaxis  ;check for spin vars, etc.
                      model = spinmodel_get_ptr(sc,use_eclipse_corrections=use_eclipse_corrections)
                      ; These validity checks and calls to thm_load_state may be
                      ; unnecessary if thm_autoload_support works as intended
                      If(obj_valid(model) Eq 0) Then Begin ;load state data
                        thm_load_state, probe = sc, trange = minmax(d.x), /get_support_data
                        model = spinmodel_get_ptr(sc,use_eclipse_corrections=use_eclipse_corrections)
                      Endif
                      dprint, dlevel=2,'Using spin model for probe '+strtrim(sc, 2)+'.'
                      If(obj_valid(model)) Then Begin                          
                        spinmodel_interp_t, model = model, time = (d.x)[w], spinper = spin_period, $
                          use_spinphase_correction = 1 ;a la J. L.
                        spin_period = median(spin_period)
                      Endif Else spin_period = 3.03
; Inform user of on-the-fly offset method:
;
                      dprint, dlevel=2,'Using on-the-fly EDC offset removal with '+strtrim(n_spins, 2)+ $
                        ' spin estimation window assuming a '+ $ ;smooth
                        strtrim(spin_period, 2) +' [s] spin period (median of loaded data spin periods).'
                      dprint, dlevel=2,'Using ' + strtrim(offset_estimation_func, 2)+' for offset estimation function.  ' + $
                        'Edge truncation is '+(edge_truncate ? 'ON.':'OFF.')
  
; Define array for EDC offset calculation:
;
                      d_smooth = fltarr(n_elements(w), 2) ; Smoothing E12 and E34 only -- not E56.
  
; Find any gaps in the data (for E12 and E34 separately):
;
                      ;added n_gaps to fully accommodate change to xdegap - af 2016-05-03
                      xdegap, gap_trigger_value, 0., d.x[w], float(d.y[w, 0:1]), x_out, y_out, iindices = ii, $
                        /onenanpergap, /nowarning, n_gaps=n_gaps, gap_begin = gap_begin, gap_end = gap_end
  
; Smooth each chunk of data individually (if there are N gaps, then there are N+1 chunks):
; *** Truncate N_SPINS, if chunk is too short, and send warning MESSAGE. ***
; ****************************************************************************************
                      for j = 0, 1 do begin ;0 for E12, 1 for E34.
                        dprint, dlevel=2,'Calculating offset estimation for '+(j eq 0 ? 'E12' : 'E34')+'...'
                        if y_out[0] ne -1 && n_gaps gt 0 then q = where(finite(y_out[*, j], /nan)) else q = -1
                        if q[0] ne -1 then begin
                          imap = lindgen(n_elements(ii)) ;Maps indices in x/y_out into d.y[w,*].
;                          n_gaps = n_elements(q)
                          dprint, dlevel=4,string(n_gaps, format = '(i0)') + ' gaps greater than '+$
                            string(gap_trigger_value, format = '(f0.4)')+ ' [s] found.  Gap begin/end times:'
;
                          for m = 0, n_gaps-1 do dprint,  dlevel=2,time_string([gap_begin[m], gap_end[m]])
;
; 1st chunk:
;
                          samp_rate = 1./median(x_out[1:q[0]-1] - x_out[0:q[0]-2]) ; samp/s.
                          wdii = where(ii lt q[0])
                          wd = imap[wdii]
                          result = thm_get_efi_edc_offset(float(d.y[wd, j]), samp_rate, n_spins, spin_period, $
                                                          edge_truncate, window_truncated, $
                                                          new_n_spins, min_n_spins = min_n_spins)
                          if (where(finite(result)))[0] ne -1 then begin
                            if keyword_set(window_truncated) then begin
                              offset_estimation_window_truncated = 1b
                              dprint, dlevel=4,' *** WARNING: smoothing window truncated to '+string(new_n_spins, format = '(i0)')+ $
                                ' spins to fit data sub-interval.'
                            endif
                          endif else begin
                            dprint, dlevel=4,' *** WARNING: Interval less than '+strtrim(min_n_spins, 2)+$
                              ' spins wide.  Interval filled with NaNs.'
                          endelse
                          d_smooth[wd, j] = temporary(result)
;
; Nth chunk:
;
                          if n_gaps ge 2 then begin ; Only do this, if there are at least two gaps.
                            for k = 0, n_elements(q)-2 do begin
                              samp_rate = 1./median(x_out[q[k]+2:q[k+1]-1] - x_out[q[k]+1:q[k+1]-2])
                              wdii = where(ii gt q[k] and ii lt q[k+1])
                              wd = imap[wdii]
                              result = thm_get_efi_edc_offset(float(d.y[wd, j]), samp_rate, n_spins, spin_period, $
                                                              edge_truncate, window_truncated, $
                                                              new_n_spins, min_n_spins = min_n_spins)
                              if (where(finite(result)))[0] ne -1 then begin
                                if keyword_set(window_truncated) then begin
                                  offset_estimation_window_truncated = 1b
                                  dprint, dlevel=4,' *** WARNING: smoothing window truncated to '+string(new_n_spins, format = '(i0)')+ $
                                    ' spins to fit data sub-interval.'
                                endif
                              endif else begin
                                dprint, dlevel=4,' *** WARNING: Interval less than '+strtrim(min_n_spins, 2)+$
                                  ' spins wide.  Interval filled with NaNs.'
                              endelse
                              d_smooth[wd, j] = temporary(result)
                            endfor ;k
                          endif
;
; Last chunk:
;
                          samp_rate = 1./median(x_out[q[n_gaps-1]+2:*] - x_out[q[n_gaps-1]+1: n_elements(x_out)-2])
                          wdii = where(ii gt q[n_gaps-1])
                          wd = imap[wdii]
                          result = thm_get_efi_edc_offset(float(d.y[wd, j]), samp_rate, n_spins, spin_period, $
                                                          edge_truncate, window_truncated, $
                                                          new_n_spins, min_n_spins = min_n_spins)
                          if (where(finite(result)))[0] ne -1 then begin
                            if keyword_set(window_truncated) then begin
                              offset_estimation_window_truncated = 1b
                              dprint, dlevel=4,' *** WARNING: smoothing window truncated to '+string(new_n_spins, format = '(i0)')+ $
                                ' spins to fit data sub-interval.'
                            endif
                          endif else begin
                            dprint, dlevel=4,' *** WARNING: Interval less than '+strtrim(min_n_spins, 2)+$
                              ' spins wide.  Interval filled with NaNs.'
                          endelse
                          d_smooth[wd, j] = temporary(result)
  
                        endif else begin
;
; No gaps detected: No need to loop on chunks -- smooth entire period.
;
                          samp_rate = 1./median(d.x[1:*] - d.x[0: n_elements(d.x)-2])
                          result = thm_get_efi_edc_offset(float(d.y[*, j]), samp_rate, n_spins, spin_period, $
                                                          edge_truncate, window_truncated, $
                                                          new_n_spins, min_n_spins = min_n_spins)
                          if (where(finite(result)))[0] ne -1 then begin
                            if keyword_set(window_truncated) then begin
                              offset_estimation_window_truncated = 1b
                              dprint, dlevel=4,' *** WARNING: smoothing window truncated to '+string(new_n_spins, format = '(i0)')+ $
                                ' spins to fit data sub-interval.'
                            endif
                          endif else begin
                            dprint, dlevel=4,' *** WARNING: Interval less than '+strtrim(min_n_spins, 2)+$
                              ' spins wide.  Interval filled with NaNs.'
                          endelse
                          d_smooth[*, j] = temporary(result)
                        
                        endelse
                      endfor    ;j
; save or append EDC offset and GAP_BEGIN/GAP_END to kw:
;
                      if arg_present(onthefly_edc_offset) then thm_put_element, onthefly_edc_offset, sc, name, d_smooth
                      if arg_present(gap_begin_struct) then thm_put_element, gap_begin_struct, sc, name, gap_begin
                      if arg_present(gap_end_struct) then thm_put_element, gap_end_struct, sc, name, gap_end
                    Endif Else Begin
                      If(keyword_set(calfile_edc_offset)) Then dprint,dlevel=2, 'EDC OFFSET FROM CAL. FILE' $
                      Else dprint, dlevel=2,'NO EDC OFFSET APPLIED'
                      d_smooth = fltarr(n_elements(w), 2) ; Smoothing E12 and E34 only -- not E56.
                      if arg_present(onthefly_edc_offset) then onthefly_edc_offset = -1
                      if arg_present(gap_begin_struct) then gap_begin_struct = -1
                      if arg_present(gap_end_struct) then gap_end_struct = -1
                    Endelse
;GAIN is time-independent case:
;==============================
                    if (size(gain, /dimensions))[0] le 1 then begin
                      If(keyword_set(calfile_edc_offset)) Then Begin
                        for icomp = 0L, 2L do res[w, icomp] = -1000.*gain[icomp] * $
                          (d.y[w, icomp] - cp.offset[i, icomp])/exx[icomp] ;EDC offset from calib. file.
                      Endif Else Begin
                        for icomp = 0L, 1L do res[w, icomp] = -1000.*gain[icomp] * $
                          (d.y[w, icomp] - d_smooth[*, icomp])/exx[icomp] ;EDC removal on-the-fly.
                        for icomp = 2L, 2L do res[w, icomp] = -1000.*gain[icomp] * $
                          (d.y[w, icomp] - cp.offset[i, icomp])/exx[icomp] ;EDC offset from calib. file.
                      Endelse
                      for icomp = 0L, 2L do res0[w, icomp] = -1000.*gain[icomp]*d.y[w, icomp]/exx[icomp] ;no offset
;
;GAIN is an array case:
;======================
                    endif else begin
                      for icomp = 0L, 2L do res[w, icomp] = -1000.*gain[*, icomp] * $
                        (d.y[w, icomp] - cp.offset[i, icomp])/exx[icomp] ;milivolts/meter [mV/m]
                      for icomp = 0L, 2L do res0[w, icomp] = -1000.*gain[*, icomp]*d.y[w, icomp]/exx[icomp] ;milivolts/meter [mV/m]
                    endelse
                  end
                endcase
              endfor            ;i
;; update the DLIMIT elements to reflect RAW->PHYS
;; transformation, coordinate system, etc.
;; ***********************************************
              units = cp.units
;
              str_element, dl, 'data_att', data_att, success = has_data_att
              if has_data_att then begin
                str_element, data_att, 'data_type', 'calibrated', /add
              endif else data_att = {data_type: 'calibrated'}
              str_element, data_att, 'coord_sys',  'spg', /add
              str_element, data_att, 'units', units[0], /add ;We cheat here.  Only units of first interval are shown!
              str_element, data_att, 'cal_par_time', cp.cal_par_time, /add ;Different w/ T-D calibration.
              
;"Documented calibration factors" to match expanded
;cal. file params. (3/12/2008):
;*** All of these need a time dimensions w/ T-D calibration ***
;==============================================================
              str_element, data_att, 'offset', cp.offset, /add
              str_element, data_att, 'edc_gain', cp.edc_gain, /add
              str_element, data_att, 'eac_gain', cp.eac_gain, /add
              str_element, data_att, 'boom_length', cp.boom_length, /add
              str_element, data_att, 'boom_shorting_factor', cp.boom_shorting_factor, /add
              str_element, data_att, 'dsc_offset', cp.dsc_offset, /add
; Store metadata for the on-the-fly EDC offset calculation:
;
              If(~keyword_set(no_edc_offset) && ~keyword_set(calfile_edc_offset)) Then Begin
                str_element, data_att, 'NOMINAL_N_SPINS', n_spins, /add
                str_element, data_att, 'MIN_N_SPINS', min_n_spins, /add
                str_element, data_att, 'gap_trigger_value', gap_trigger_value, /add
                str_element, data_att, 'edge_truncate', edge_truncate, /add
                str_element, data_att, 'offset_estimation_window_truncated', offset_estimation_window_truncated, /add
                str_element, data_att, 'offset_estimation_func', offset_estimation_func, /add
                str_element, data_att, 'number_of_gaps', n_gaps, /add
              Endif
  
              str_element, dl, 'data_att', data_att, /add
              str_element, dl, 'ytitle', string(tplot_var_orig, units[0], format = $ ;Only units of first interval are shown!
                                                '(A,"!C!C[",A,"]")'), /add
  
              str_element, dl, 'labels', ['E12', 'E34', 'E56'], /add
              str_element, dl, 'labflag', 1, /add
              str_element, dl, 'colors', [2, 4, 6]
;Save non-despun data for use for _0 and _dot0, and non-despun,
;non-offset data for use for _efs and _q data.
              tplot_var_primary = thm_tplot_var(sc, nameraw)+'_primary'
              store_data, tplot_var_primary, data = {x:d.x, y: res, v:d.v}, lim = l, dlim = dl
              tplot_var_nooffset = thm_tplot_var(sc, nameraw)+'_nooffset'
              store_data, tplot_var_nooffset, data = {x:d.x, y: res0, v:d.v}, lim = l, dlim = dl
;Store the transformed spectra into the output
;TPLOT variable:
;===============
              store_data, tplot_var, data = {x:d.x, y: temporary(res), v:d.v}, lim = l, dlim = dl
              if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, tplot_var] $
              else stored_tnames = [tplot_var]
              If(~keyword_set(no_edc_offset) && ~keyword_set(calfile_edc_offset)) Then Begin
;Note that these data have not been despun yet; ;handle coordinate transformation here
                if keyword_set(coord) then begin
                  if n_elements(coord) gt 1 then begin
                    for i = 0, n_elements(out_suf)-1 do begin
                      thm_efi_despin, sc, nameraw, cp.dsc_offset[0, *], [1, 1, 1], $ ;Pass [1,1,1] in order to not duplicate boom_shorting
                        tplot_name = tplot_var, newname = tplot_var+out_suf[i], stored_tnames = foo, use_eclipse_corrections=use_eclipse_corrections, _extra=_extra
                      if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, foo] else stored_tnames = foo
                      if coord[i] ne 'dsl' then thm_cotrans, tplot_var+out_suf[i], out_coord = coord[i], $
                        use_spinphase_correction = 1, use_spinaxis_correction = 1,use_eclipse_corrections=use_eclipse_corrections
                      thm_update_efi_labels, tplot_var+out_suf[i]
                    endfor
                  endif else begin
                    if coord ne 'spg' then begin
                      thm_efi_despin, sc, nameraw, cp.dsc_offset[0, *], [1, 1, 1], $ ;Pass [1,1,1] in order to not duplicate boom_shorting
                        tplot_name = tplot_var, newname = tplot_var, stored_tnames = foo, use_eclipse_corrections=use_eclipse_corrections, _extra=_extra
                      if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, foo] else stored_tnames = foo
                      if coord ne 'dsl' then begin
                        if n_elements(out_suf) le 1 then begin
                          thm_cotrans, tplot_var, out_coord = coord, use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
                          thm_update_efi_labels, tplot_var
                        endif else begin
                          thm_cotrans, tplot_var, out_coord = coord, out_suf = out_suf[0], $
                            use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
                          thm_update_efi_labels, tplot_var + out_suf[0]
                        endelse
                      endif else thm_update_efi_labels, tplot_var
                    endif
                  endelse
                endif
              Endif
            Endif
          Endelse               ;end of primary efield calculation
        endif else begin      ; necessary TPLOT variables not present.
          if keyword_set(vb) then dprint, dlevel=1,string(tplot_var_raw, tplot_var_hed, format = $
                   '("necessary TPLOT variables (",A,X,A,") ' + $
                   'not present for RAW->PHYS transformation.")')
        endelse
      endelse                   ; done with RAW->PHYS transformation
;Here is where the _0 , _dot0 and Q flag variables are calculated
      If(keyword_set(no_edc_offset) Or keyword_set(calfile_edc_offset)) Then Continue
      if where(name eq u0s) ne -1 then begin
;=======================================
;Finish processing of _0 quantity, if present
;and transform coordinates as requested:
;=======================================
        tplot_var_primary = thm_tplot_var(sc, nameraw)+'_primary'
;Test for data here, if htere is none, then cuntinue
        get_data, tplot_var_primary, data = d
        If(is_struct(temporary(d)) Eq 0) Then continue
        thm_efi_despin, sc, nameraw, cp.dsc_offset[0, *], [1, 1, 1], $ ;Pass [1,1,1] in order to not duplicate boom_shorting
          tplot_name = tplot_var_primary, newname = tplot_var, stored_tnames = foo, use_eclipse_corrections=use_eclipse_corrections, _extra=_extra
        if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, foo] else stored_tnames = foo
        thm_update_efi_labels, tplot_var
        get_data, tplot_var, data = d, limit = l, dlim = dl
        if size(d, /type) ne 8 then continue
        d.y[*, 2] = 0.0         ;just set the z component to zero
;reset the ytitle
        str_element, dl, 'ytitle', string(tplot_var_orig, units[0], format = $ ;Only units of first interval are shown!
                                          '(A,"!C!C[",A,"]")'), /add
        store_data, tplot_var, data = {x:d.x, y: d.y, v:d.v}, lim = l, dlim = dl
        undefine, d
        if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, tplot_var] $
        else stored_tnames = [tplot_var]
;Coordinate transforms here
        if keyword_set(coord) then begin  
          for i = 0, n_elements(coord)-1 do begin
            if coord[i] ne 'dsl' then begin
              if coord[i] ne 'spg' and coord[i] ne 'ssl' then begin
                thm_update_efi_labels, tplot_var
                dprint, dlevel=4,'Warning: COORD keyword ignored: ' + $
                  'only ssl, dsl, or spg are physically meaningful ' + $
                  'coordinate systems for _0 quantites.'
              endif else begin
                if n_elements(coord) gt 1 then begin
                  thm_cotrans, tplot_var, out_coord = coord[i], out_suf = out_suf[i], $
                    use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
                  thm_update_efi_labels, tplot_var + out_suf[i]
                endif else begin
                  thm_cotrans, tplot_var, out_coord = coord[i], use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
                  thm_update_efi_labels, tplot_var
                endelse
              endelse
            endif
          endfor
        endif
      endif
;================================================
;Finish processing of _dot0 quantity, if present:
;================================================
      if where(name eq udot0s) ne -1 then begin
        tplot_var_primary = thm_tplot_var(sc, nameraw)+'_primary'
;Test for data here, if htere is none, then cuntinue
        get_data, tplot_var_primary, data = d
        If(is_struct(temporary(d)) Eq 0) Then continue
        thm_efi_despin, sc, nameraw, cp.dsc_offset[0, *], [1, 1, 1], $ ;Pass [1,1,1] in order to not duplicate boom_shorting
          tplot_name = tplot_var_primary, newname = tplot_var, stored_tnames = foo, use_eclipse_corrections=use_eclipse_corrections, _extra=_extra
        if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, foo] else stored_tnames = foo
        thm_update_efi_labels, tplot_var
        get_data, tplot_var, data = d, limit = l, dlim = dl
        if size(d, /type) ne 8 then continue
;==========================================
;Temporarily load FGM data as a TPLOT var.:
;First check to see if it is there.
;==========================================
        if keyword_set(fgm_datatype) then ftype = fgm_datatype else begin
          if nameraw eq 'efp' || nameraw eq 'efw' then ftype = 'fgh' $
          else ftype = 'fgl'
        endelse
        if vb ge 2 then dprint, dlevel=2, 'Using '+ftype
        fsuff = '_thm_cal_efi_priv'
        If(is_string(tnames('th'+sc+'_'+ftype+'_dsl'+fsuff)) Eq 0) Then Begin
            If(keyword_set(fgm_level) && fgm_level Eq 'l1') Then Begin
                thm_load_fgm, probe = sc, level = 'l1', coord = 'dsl', suffix = '_dsl'+fsuff, $
                  trange = minmax(d.x), use_eclipse_corrections=use_eclipse_corrections
            Endif Else Begin
                thm_load_fgm, probe = sc, level = 'l2', coord = 'dsl', suffix = fsuff, trange = minmax(d.x)
            Endelse
;===============
;Degap FGM data:
;===============
            tdegap, 'th'+sc+'_'+ftype+'_dsl'+fsuff, /overwrite, /onenanpergap, /nowarning
        Endif
;=======================================================
;Get relevant data:
;=======================================================
        get_data, 'th'+sc+'_'+ftype+'_dsl'+fsuff, data = thx_fgx_dsl, limit = fl, dlim = fdl
;==================================
;Interpolate FGM data to EFI times:
;==================================
        Bx = interpol(thx_fgx_dsl.y[*, 0], thx_fgx_dsl.x, d.x)
        By = interpol(thx_fgx_dsl.y[*, 1], thx_fgx_dsl.x, d.x)
        Bz = interpol(thx_fgx_dsl.y[*, 2], thx_fgx_dsl.x, d.x) + bz_offset
;
        undefine, thx_fgx_dsl, fl, fdl
;=====================
;Initialize Ez to NaN:
;=====================
        d.y[*, 2] = !values.f_nan ;Assign.
;==================================================
;Apply max_angle kw, if present.  If not, apply
;min_bz kw, if present.  If not, let all B's be good.
;there are no good elements, then continue loop:
;==================================================
        if keyword_set(max_angle) then begin
          angle = acos(Bz/sqrt(Bx^2+By^2+Bz^2))*180d/!dpi
          good = where(abs(angle) le max_angle, ngood)
          if ngood eq 0 then continue
        endif else if keyword_set(min_bz) then begin
          good = where(abs(Bz) ge min_bz, ngood)
          if ngood eq 0 then continue
        endif else good = lindgen(n_elements(d.x))
;=================================
;Calculate Bx over Bz, By over Bz:
;=================================
        bx_bz = Bx[good]/Bz[good]
        by_bz = By[good]/Bz[good]
;===================================
;Apply max_bxy_bz kw, if present.  If not, keep all.
;If no good elements, continue loop:
;===================================
        if keyword_set(max_bxy_bz) then begin
          keep = where(abs(bx_bz) lt max_bxy_bz and abs(by_bz) lt max_bxy_bz, nkeep)
          if nkeep eq 0 then continue
        endif else keep = lindgen(ngood)
        goodkeep = good[keep]   ;Otherwise this gets eval'td 3X.
;===========================================
;Calculate Ez and assign directly to result:
;===========================================
        d.y[goodkeep, 2] = -(bx_bz[keep]*d.y[goodkeep, 0] + $
                             by_bz[keep]*d.y[goodkeep, 1])  
;=============
;Store result:
;=============
;reset the ytitle
        str_element, dl, 'ytitle', string(tplot_var_orig, units[0], format = $ ;Only units of first interval are shown!
                                          '(A,"!C!C[",A,"]")'), /add
        store_data, tplot_var, data = {x:d.x, y: d.y, v:d.v}, lim = l, dlim = dl
        if ~(~size(stored_tnames, /type)) then stored_tnames = [stored_tnames, tplot_var] $
        else stored_tnames = [tplot_var]
        undefine, d
;==================================================================================
;At this point, TPLOT_VAR is in dsl.  If COORD ne 'dsl', then transform via THM_COTRANS.PRO
;and set lables (spun coord. systems get "E12,34,56"; despun systems get "Ex,y,z"):
;==================================================================================
        if keyword_set(coord) then begin
          if n_elements(coord) gt 1 then begin
            for i = 0, n_elements(coord)-1 do begin
              if coord[i] ne 'dsl' then begin
                thm_cotrans, tplot_var, out_coord = coord[i], out_suf = out_suf[i], $
                  use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
                thm_update_efi_labels, tplot_var + out_suf[i]
              endif
            endfor
          endif else begin
            if coord ne 'dsl' then begin
              thm_cotrans, tplot_var, out_coord = coord, use_spinphase_correction = 1, use_spinaxis_correction = 1, use_eclipse_corrections=use_eclipse_corrections
              thm_update_efi_labels, tplot_var
            endif
          endelse
        endif
      endif
;Here create _efs variables and quality flags, note that all are done
;if any are asked for
;-- for EFF, EFP, and EFW, EFI_Q_MAG and EFI_Q_PHASE are computed in the
;following manner:
;
;        -- compute the spinfit E-field estimate using both the E12 and E34
;        antennas to get efs_e12 and efs_e34.
;        -- EFI_Q_MAG = |efs_e34|/|efs_e12|.
;        -- EFI_Q_PHA = dot( efs_e12, efs_e34)/(|efs_e12|*|efs_e34|).
;
;        This captures the test of running spinfits through a given region
;of interest and comparing the results from the long and sohrt antennas in
;order to detect wake effects and other non-geophysical fields.
;
;        The indication of "good quality" EFI data would be both Q factors
;near 1, with deteriorating quality as one moves away from that.
      if (where(name eq sfit or name eq qflag) ne -1) then begin
        spinfits_done[this_primary] = 1b
        tplot_var_nooffset = thm_tplot_var(sc, nameraw)+'_nooffset'
        e12_efs = thm_tplot_var(sc, nameraw)+'_e12_efs'
;Test for data here, if htere is none, then cuntinue
        get_data, tplot_var_nooffset, data = d
        If(is_struct(temporary(d)) Eq 0) Then continue
        thm_spinfit, tplot_var_nooffset, axis_dim = 2, plane_dim = 0, sun2sensor = 135, $
          build_efi_var = e12_efs
        e34_efs = thm_tplot_var(sc, nameraw)+'_e34_efs'
        thm_spinfit, tplot_var_nooffset, axis_dim = 2, plane_dim = 1, sun2sensor = 45, $
          build_efi_var = e34_efs
        del_data, tplot_var_nooffset ;not needed anymore?
        e12_efs_orig = e12_efs
        e34_efs_orig = e34_efs
        if out_suf[0] ne '' then begin
          e12_efs = e12_efs_orig + out_suf[0]
          copy_data, e12_efs_orig, e12_efs
          store_data, e12_efs_orig, /delete
          
          e34_efs = e34_efs_orig + out_suf[0]
          copy_data, e34_efs_orig, e34_efs
          store_data, e34_efs_orig, /delete
        endif
        options, e12_efs, 'ytitle', e12_efs_orig
        options, e12_efs, 'labels', ['Ex', 'Ey', 'Ez'], /add
        options, e34_efs, 'ytitle', e34_efs_orig
        options, e34_efs, 'labels', ['Ex', 'Ey', 'Ez'], /add
;get the data to create Q flags
        get_data, e12_efs, data = de12, dlimits = dl12
        get_data, e34_efs, data = de34, dlimits = dl34
;use e12's time array and dlimits
        If(is_struct(de12) && is_struct(de34)) Then Begin
          tim_arr = de12.x
          y34 = data_cut(de34, tim_arr)
;Guard against bad data_cut output
          If(size(y34, /n_dimen) Eq 2) Then Begin
             m34 = sqrt(y34[*, 0]^2+y34[*, 1]^2)
             y12 = de12.y
             m12 = sqrt(y12[*, 0]^2+y12[*, 1]^2)
             mag_test = m34/m12
             pha_test = abs(y12[*, 0]*y34[*, 0]+y12[*, 1]*y34[*, 1])/(m12*m34)
;change some plot options for the data, since these came from field data
             str_element, dl12, 'labels', '', /add
             str_element, dl12, 'labflag', 0, /add
             str_element, dl12, 'colors', 0, /add
             efi_q_mag_orig = thm_tplot_var(sc, nameraw)+'_q_mag' 
             efi_q_mag = efi_q_mag_orig + out_suf[0]
             store_data, efi_q_mag, data = {x:tim_arr, y:mag_test}, dlimits = dl12
             options, efi_q_mag, 'ytitle', efi_q_mag_orig
             ylim, efi_q_mag, 0, 0, 1
             efi_q_pha_orig = thm_tplot_var(sc, nameraw)+'_q_pha' 
             efi_q_pha = efi_q_pha_orig + out_suf[0]
             store_data, efi_q_pha, data = {x:tim_arr, y:pha_test}, dlimits = dl12
             options, efi_q_pha, 'ytitle', efi_q_pha_orig
             ylim, efi_q_pha, 0, 0, 1
          Endif
        Endif
      endif
    endfor                      ; loop over names.
    del_data, thm_tplot_var(sc, 'ef?')+'_primary*'
    del_data, thm_tplot_var(sc, 'ef?')+'_nooffset*'
  endfor                        ; loop over spacecraft.
;Delete any FGM data loaded
  del_data, '*_thm_cal_efi_priv'
end
