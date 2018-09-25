;+
; NAME:
;   SPP_FLD_CDF_TIMESPAN
;
; PURPOSE:
;   Define a timestring for SPP FIELDS CDF files.
;
; CALLING SEQUENCE:
;   spp_fld_cdf_timespan, trange = trange, success = success, $
;     filename_timestring = filename_timestring
;
; INPUTS:
;   TRANGE: An optional one or two element input specifying the time range.
;     A one element input implies a daily 24 hour file.  Two elements imply
;     a specific start and end time.
;
; OUTPUTS:
;   SUCCESS: Returns 1 if the timespan and timestring are set.
;   FILENAME_TIMESTRING: Returns a string specifying the time string
;     portion of the CDF file that will be created.  If the file is
;     a daily file, the format is YYYYMMDD.  If the file is not
;     a daily file, the format is YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS, with
;     the two halves of the string corresponding to the start and
;     end of the interval.
;
; EXAMPLE:
;   See call in SPP_FLD_MAKE_CDF_L1.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupa $
; $LastChangedDate: 2018-09-24 11:18:10 -0700 (Mon, 24 Sep 2018) $
; $LastChangedRevision: 25856 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_timespan.pro $
;-
pro spp_fld_cdf_timespan, trange = trange, success = success, $
  filename_timestring = filename_timestring, daily = daily

  success = 0

  if not keyword_set(trange) then begin

    get_timespan, trange

  endif else begin

    if n_elements(trange) GT 2 then return

    if n_elements(trange) EQ 1 then daily = 1 else daily = 0

    timespan, time_string(trange)

  endelse

  trange_str = time_string(trange,format=2)

  if keyword_set(daily) then begin

    filename_timestring = (trange_str[0]).SubString(0,7)

  endif else begin

    filename_timestring = trange_str.Join('_')

  endelse

  success = 1 ; TODO: add error reporting here

end