;+
; NAME:
;   SPP_FLD_CDF_CREATE
;
; PURPOSE:
;   Creates a FIELDS CDF file using the CDF_CREATE function.
;
; CALLING SEQUENCE:
;   spp_fld_cdf_create, 1, 0, cdf_att, filename_timestring, $
;     filename = filename, fileid = fileid
;
; INPUTS:
;   LEVEL: The level (L1, L2, ...) of the created CDF file
;   VERS_NUM: The version number of the file
;   CDF_ATT: An IDL dictionary containing the global attributes of the CDF file,
;     read (for L1 files) from the XML definition of the APID or (for higher
;     level files) from the lower level CDF files.
;   FILENAME_TIMESTRING: A string specifying the time string included in the
;     CDF filename.  For a daily file, the format is YYYYMMDD.  For a specific
;     non-daily interval, the format is YYYYMMDDHHMMSS_YYYYMMDDHHMMSS, with the
;     two times specifying the start and end of the interval.
;
; OUTPUTS:
;   FILENAME: The full path of the created CDF file.
;   FILEID: The CDF file ID assigned to the created CDF file by CDF_CREATE.
;
; EXAMPLE:
;   See call in SPP_FLD_MAKE_CDF_L1.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2018-05-08 14:59:32 -0700 (Tue, 08 May 2018) $
; $LastChangedRevision: 25181 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_create.pro $
;-
pro spp_fld_cdf_create, level, vers_num, cdf_att, filename_timestring, $
  filename = filename, fileid = fileid

  level_str = 'l' + string(level, format = '(I1)')

  ; TODO: Decide if we need to keep version number

  vers_num_str = '_v' + string(vers_num, format = '(I02)')

  if cdf_att['Logical_source'].StartsWith('SPP_FLD_',/FOLD_CASE) OR $
    cdf_att['Logical_source'].StartsWith('PSP_FLD_',/FOLD_CASE) then begin

    cdf_subdir = (cdf_att['Logical_source'].ToLower()).SubString(8)

  end

  year_str = filename_timestring.SubString(0,3)
  month_str = filename_timestring.SubString(4,5)

  filename_hdr = $
    (cdf_att['Logical_source'].ToLower()).Insert('_' + level_str,7) + '_'

  cdf_dir = !spp_fld_tmlib.cdf_dir

  if not keyword_set(file) then $
    filename = cdf_dir + $
    '/fields/' + $
    cdf_subdir + '/' + $
    level_str + '/' + $
    year_str + '/' + $
    month_str + '/' + $
    filename_hdr + filename_timestring + vers_num_str + '.cdf'

  if file_search(file_dirname(filename)) EQ '' then $
    file_mkdir, file_dirname(filename)

  if file_search(filename) NE '' then file_delete, filename

  fileid = cdf_create(filename, $
    /single_file, /network_encoding, /row_major,/clobber)

end
