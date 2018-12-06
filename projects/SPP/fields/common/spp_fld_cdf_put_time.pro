;+
; NAME:
;   SPP_FLD_CDF_PUT_TIME
;
; PURPOSE:
;   Add time data to a SPP FIELDS CDF file, in several formats.
;   The formats are TT2000 time (which is stored in the CDF file as
;   'epoch'), Unix time, and MET.
;
; CALLING SEQUENCE:
;   spp_fld_cdf_put_time, fileid, times
;
; INPUTS:
;   FILEID: The file ID of the destination CDF file.
;   TIME: An array of times.
;   SUFFIX: An optional parameter which adds a suffix
;
; OUTPUTS:
;   No explicit outputs are returned.  After completion, the input times
;   are stored in the CDF file.
;
; EXAMPLE:
;   See call in SPP_FLD_MAKE_CDF_L1.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2018-12-05 11:45:41 -0800 (Wed, 05 Dec 2018) $
; $LastChangedRevision: 26248 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_put_time.pro $
;-

pro spp_fld_cdf_put_time, fileid, time, met, subseconds, utcstr, $
  suffix = suffix, $
  compression = compression, level = level

  if n_elements(level) EQ 0 then level = 1

  if n_elements(compression) EQ 0 then compression = 6

  if not keyword_set(suffix) then suffix = '' else suffix = suffix + '_'

  cdf_leap_second_init

  unix_time_valid = time_double(['2010-01-01/00:00','2049-12-31/23:59'])
  met_time_valid = long(unix_time_valid - time_double('2010-01-01/00:00:00'))
  tt2000_time_valid = long64((add_tt2000_offset(unix_time_valid)-time_double('2000-01-01/12:00:00'))*1d9)

  get_timespan, ts

  unix_time_scale = ts
  met_time_scale = long(ts - time_double('2010-01-01/00:00:00'))
  tt2000_time_scale = long64((add_tt2000_offset(ts)-time_double('2000-01-01/12:00:00'))*1d9)

  tmlib_time = time

  unix_time = time_double(utcstr)
  met_time = met

  if level EQ 1 then begin
    tt2000_time = long64((add_tt2000_offset(unix_time)-time_double('2000-01-01/12:00:00'))*1d9)

  endif else begin

    yy = long(strmid(utcstr,  0,4))
    mm = long(strmid(utcstr,  5,2))
    dd = long(strmid(utcstr,  8,2))
    hh = long(strmid(utcstr, 11,2))
    mn = long(strmid(utcstr, 14,2))
    ss = long(strmid(utcstr, 17,2))
    ms = long(strmid(utcstr, 20,3))
    us = long(strmid(utcstr, 23,3))
    ns = long(strmid(utcstr, 26,3))

    cdf_tt2000, tt2000_time, yy, mm, dd, hh, mn, ss, ms, us, ns, /COMPUTE_EPOCH

  endelse

  ; TT2000 Time

  name_ep = 'epoch' + suffix
  varid_ep = cdf_varcreate(fileid, name_ep, /CDF_time_tt2000, /REC_VARY, /ZVARIABLE)

  if n_elements(compression) GT 0 then begin
    CDF_COMPRESSION, fileid, $
      SET_VAR_GZIP_LEVEL=compression, $
      VARIABLE=varid_ep, $
      /ZVARIABLE
  end

  cdf_attput, fileid, 'FIELDNAM',     varid_ep, name_ep, /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid_ep, 'I22', /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid_ep, name_ep, /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid_ep, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid_ep, -9223372036854775808, /ZVARIABLE,/CDF_EPOCH
  cdf_attput, fileid, 'DISPLAY_TYPE', varid_ep, 'time_series', /ZVARIABLE
  cdf_attput, fileid, 'VALIDMIN',     varid_ep, tt2000_time_valid[0], /ZVARIABLE,/CDF_EPOCH
  cdf_attput, fileid, 'VALIDMAX',     varid_ep, tt2000_time_valid[1], /ZVARIABLE,/CDF_EPOCH
  cdf_attput, fileid, 'SCALEMIN',     varid_ep, tt2000_time_scale[0], /ZVARIABLE,/CDF_EPOCH
  cdf_attput, fileid, 'SCALEMAX',     varid_ep, tt2000_time_scale[1], /ZVARIABLE,/CDF_EPOCH
  cdf_attput, fileid, 'UNITS',        varid_ep, 'ns', /ZVARIABLE
  cdf_attput, fileid, 'MONOTON',      varid_ep, 'INCREASE', /ZVARIABLE
  cdf_attput, fileid, 'CATDESC',      varid_ep, 'Time in TT2000', /ZVARIABLE

  cdf_varput, fileid, name_ep, tt2000_time

  ; Unix Time

  if level NE 1 then begin

    name_unix = 'time_unix' + suffix
    varid_unix = cdf_varcreate(fileid, name_unix, /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

    if n_elements(compression) GT 0 then begin
      CDF_COMPRESSION, fileid, $
        SET_VAR_GZIP_LEVEL=compression, $
        VARIABLE=varid_unix, $
        /ZVARIABLE
    end

    cdf_attput, fileid, 'FIELDNAM',     varid_unix, name_unix, /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid_unix, 'F15.9', /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid_unix, name_unix, /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid_unix, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid_unix, -1.0d31, /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid_unix, 'time_series', /ZVARIABLE
    cdf_attput, fileid, 'VALIDMIN',     varid_unix, unix_time_valid[0], /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX',     varid_unix, unix_time_valid[1], /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN',     varid_unix, unix_time_scale[0], /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX',     varid_unix, unix_time_scale[1], /ZVARIABLE
    cdf_attput, fileid, 'UNITS',        varid_unix, 's', /ZVARIABLE
    cdf_attput, fileid, 'MONOTON',      varid_unix, 'INCREASE', /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',      varid_unix, 'Time in Unix time', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0',     varid_unix, name_ep, /ZVARIABLE

    cdf_varput, fileid, name_unix, unix_time

  endif

  ; TMlib Time

  if level NE 1 then begin

    name_tmlib = 'time_tmlib' + suffix
    varid_tmlib = cdf_varcreate(fileid, name_tmlib, /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

    if n_elements(compression) GT 0 then begin
      CDF_COMPRESSION, fileid, $
        SET_VAR_GZIP_LEVEL=compression, $
        VARIABLE=varid_tmlib, $
        /ZVARIABLE
    end

    cdf_attput, fileid, 'FIELDNAM',     varid_tmlib, name_tmlib, /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid_tmlib, 'F15.9', /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid_tmlib, name_tmlib, /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid_tmlib, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid_tmlib, -1.0d31, /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid_tmlib, 'time_series', /ZVARIABLE
    cdf_attput, fileid, 'VALIDMIN',     varid_tmlib, unix_time_valid[0], /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX',     varid_tmlib, unix_time_valid[1], /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN',     varid_tmlib, unix_time_scale[0], /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX',     varid_tmlib, unix_time_scale[1], /ZVARIABLE
    cdf_attput, fileid, 'UNITS',        varid_tmlib, 's', /ZVARIABLE
    cdf_attput, fileid, 'MONOTON',      varid_tmlib, 'INCREASE', /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',      varid_tmlib, 'Time in TMlib time', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0',     varid_tmlib, name_ep, /ZVARIABLE

    cdf_varput, fileid, name_tmlib, time

  endif

  ; MET Time

  if level EQ 1 then begin

    name_met = 'time_met' + suffix
    varid_met = cdf_varcreate(fileid, name_met, /CDF_UINT4, /REC_VARY, /ZVARIABLE)

    if n_elements(compression) GT 0 then begin
      CDF_COMPRESSION, fileid, $
        SET_VAR_GZIP_LEVEL=compression, $
        VARIABLE=varid_met, $
        /ZVARIABLE
    end

    cdf_attput, fileid, 'FIELDNAM',     varid_met, name_met, /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid_met, 'I12', /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid_met, name_met, /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid_met, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid_met, 4294967294, /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid_met, 'time_series', /ZVARIABLE
    cdf_attput, fileid, 'VALIDMIN',     varid_met, met_time_valid[0], /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX',     varid_met, met_time_valid[1], /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN',     varid_met, met_time_scale[0], /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX',     varid_met, met_time_scale[1], /ZVARIABLE
    cdf_attput, fileid, 'UNITS',        varid_met, 's', /ZVARIABLE
    cdf_attput, fileid, 'MONOTON',      varid_met, 'INCREASE', /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',      varid_met, 'Time in MET', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0',     varid_met, name_ep, /ZVARIABLE

    cdf_varput, fileid, name_met, met_time

  endif

  ; Subseconds

  if level EQ 1 then begin

    name_ssec = 'time_subseconds' + suffix
    varid_ssec = cdf_varcreate(fileid, name_ssec, /CDF_UINT4, /REC_VARY, /ZVARIABLE)

    if n_elements(compression) GT 0 then begin
      CDF_COMPRESSION, fileid, $
        SET_VAR_GZIP_LEVEL=compression, $
        VARIABLE=varid_ssec, $
        /ZVARIABLE
    end

    cdf_attput, fileid, 'FIELDNAM',     varid_ssec, name_ssec, /ZVARIABLE
    cdf_attput, fileid, 'FORMAT',       varid_ssec, 'I8', /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid_ssec, name_ssec, /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid_ssec, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid_ssec, 4294967294, /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid_ssec, 'time_series', /ZVARIABLE
    cdf_attput, fileid, 'VALIDMIN',     varid_ssec, 0, /ZVARIABLE
    cdf_attput, fileid, 'VALIDMAX',     varid_ssec, 65535, /ZVARIABLE
    cdf_attput, fileid, 'SCALEMIN',     varid_ssec, 0, /ZVARIABLE
    cdf_attput, fileid, 'SCALEMAX',     varid_ssec, 65535, /ZVARIABLE
    cdf_attput, fileid, 'UNITS',        varid_ssec, '1/50000 s (S/C) or 1/65536 (FIELDS)', /ZVARIABLE
    cdf_attput, fileid, 'MONOTON',      varid_ssec, 'INCREASE', /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',      varid_ssec, 'Subseconds', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0',     varid_ssec, name_ep, /ZVARIABLE

    cdf_varput, fileid, name_ssec, subseconds

  endif

  ; UTC time string

  if level NE 1 then begin

    name_utcstr = 'time_utcstr' + suffix
    varid_utcstr = cdf_varcreate(fileid, name_utcstr, numelem = strlen(utcstr[0]), /CDF_CHAR, /REC_VARY, /ZVARIABLE)

    if n_elements(compression) GT 0 then begin
      CDF_COMPRESSION, fileid, $
        SET_VAR_GZIP_LEVEL=compression, $
        VARIABLE=varid_utcstr, $
        /ZVARIABLE
    end

    cdf_attput, fileid, 'FIELDNAM',     varid_utcstr, name_met, /ZVARIABLE
    cdf_attput, fileid, 'LABLAXIS',     varid_utcstr, name_met, /ZVARIABLE
    cdf_attput, fileid, 'VAR_TYPE',     varid_utcstr, 'support_data', /ZVARIABLE
    cdf_attput, fileid, 'FILLVAL',      varid_utcstr, string('', format = '(A29)'), /ZVARIABLE
    cdf_attput, fileid, 'DISPLAY_TYPE', varid_utcstr, 'time_series', /ZVARIABLE
    cdf_attput, fileid, 'CATDESC',      varid_utcstr, 'Time in UTC (String)', /ZVARIABLE
    cdf_attput, fileid, 'DEPEND_0',     varid_utcstr, name_ep, /ZVARIABLE

    cdf_varput, fileid, name_utcstr, utcstr

  endif

end