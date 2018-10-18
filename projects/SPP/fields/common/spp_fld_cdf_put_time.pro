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
; $LastChangedDate: 2018-10-10 12:00:08 -0700 (Wed, 10 Oct 2018) $
; $LastChangedRevision: 25952 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_put_time.pro $
;-

pro spp_fld_cdf_put_time, fileid, time, suffix = suffix, $
  compression = compression
  
  if not keyword_set(compression) then compression = 6

  if not keyword_set(suffix) then suffix = '' else suffix = suffix + '_'

  cdf_leap_second_init

  unix_time_valid = time_double(['2010-01-01/00:00','2049-12-31/23:59'])
  met_time_valid = unix_time_valid - time_double('2010-01-01/00:00:00')
  tt2000_time_valid = long64((add_tt2000_offset(unix_time_valid)-time_double('2000-01-01/12:00:00'))*1.e9)

  get_timespan, ts

  unix_time_scale = ts
  met_time_scale = ts - time_double('2010-01-01/00:00:00')
  tt2000_time_scale = long64((add_tt2000_offset(ts)-time_double('2000-01-01/12:00:00'))*1.e9)

  unix_time = time
  met_time = unix_time - time_double('2010-01-01/00:00:00')
  tt2000_time = long64((add_tt2000_offset(unix_time)-time_double('2000-01-01/12:00:00'))*1.e9)

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

  name_unix = 'time_unix' + suffix
  varid_unix = cdf_varcreate(fileid, name_unix, /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

  if n_elements(compression) GT 0 then begin
    CDF_COMPRESSION, fileid, $
      SET_VAR_GZIP_LEVEL=compression, $
      VARIABLE=varid_unix, $
      /ZVARIABLE
  end

  cdf_attput, fileid, 'FIELDNAM',     varid_unix, name_unix, /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid_unix, 'F15.3', /ZVARIABLE
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

  ; MET Time

  name_met = 'time_met' + suffix
  varid_met = cdf_varcreate(fileid, name_met, /CDF_DOUBLE, /REC_VARY, /ZVARIABLE)

  if n_elements(compression) GT 0 then begin
    CDF_COMPRESSION, fileid, $
      SET_VAR_GZIP_LEVEL=compression, $
      VARIABLE=varid_met, $
      /ZVARIABLE
  end

  cdf_attput, fileid, 'FIELDNAM',     varid_met, name_met, /ZVARIABLE
  cdf_attput, fileid, 'FORMAT',       varid_met, 'F15.3', /ZVARIABLE
  cdf_attput, fileid, 'LABLAXIS',     varid_met, name_met, /ZVARIABLE
  cdf_attput, fileid, 'VAR_TYPE',     varid_met, 'support_data', /ZVARIABLE
  cdf_attput, fileid, 'FILLVAL',      varid_met, -1.0d31, /ZVARIABLE
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

end