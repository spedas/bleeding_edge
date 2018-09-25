;+
; NAME:
;   SPP_FLD_MAKE_CDF_L1
;
; PURPOSE:
;   Produce a Level 1 CDF file for PSP/FIELDS data.  Level 1 files for FIELDS
;   contain data from a single APID.  This top level program retrieves the
;   APID-specific data from the packets stored in the FIELDS TMlib database,
;   reads CDF metadata from an  APID-specific XML file, and stores the data in
;   a L1 CDF file.
;
; CALLING SEQUENCE:
;   spp_fld_make_cdf_l1, apid_name
;
; INPUTS:
;   APID_NAME: The name of the APID for the L1 CDF.  Uses the abbreviated
;     APID packet identifier rather than the hex code (e.g. 'rfs_lfr' instead of
;     '0x2b2').
;   VARFORMAT: Optional parameter that allows creation of a file with only a
;     subset of data items from the packet.  For more information, see comments
;     in SPP_FLD_LOAD_TMLIB_DATA.  If this keyword is not set, all items from
;     the packet are loaded and stored in the L1 CDF file.
;   TRANGE: If set, this time range is passed to SPP_FLD_CDF_TIMESPAN and
;     used to define the time range for selection of data from the TMlib
;     database.  If not set, the current TPLOT time span is used.
;   LOAD: If set, loads the created CDF file into TPLOT variables after the
;     file is saved.
;
; OUTPUTS:
;   FILENAME: The full path of the created CDF file.
;   FILEID: The CDF file ID assigned to the created CDF file by the
;     SPP_FLD_CDF_CREATE.
;
; EXAMPLE:
;   spp_fld_make_cdf_l1, 'rfs_lfr_auto', /load
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupa $
; $LastChangedDate: 2018-09-24 11:18:10 -0700 (Mon, 24 Sep 2018) $
; $LastChangedRevision: 25856 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_make_cdf_l1.pro $
;-
pro spp_fld_make_cdf_l1, apid_name, $
  fileid = fileid, $
  varformat = varformat, $
  trange = trange, $
  filename = filename, $
  load = load, $
  daily = daily

  if not keyword_set(apid_name) then return ; TODO: Better checking and error reporting

  spp_fld_cdf_timespan, trange = trange, success = ts_success, $
    filename_timestring = filename_timestring, daily = daily

  if ts_success NE 1 then return ; TODO: error reporting here

  data = spp_fld_load_tmlib_data(apid_name, $
    varformat = varformat, success = dat_success, $
    cdf_att = cdf_att, times = times, packets = packets, idl_att = idl_att)

  if dat_success NE 1 then begin

    if dat_success EQ -1 then dprint, 'No data found for ' + apid_name, dlevel = 2

    filename = ''

    return ; TODO: error reporting here

  endif

  ;
  ; Create the CDF file
  ;

  spp_fld_cdf_create, 1, 0, cdf_att, filename_timestring, $
    filename = filename, fileid = fileid

  ;
  ; Write the packets file
  ;

  packet_filename = strmid(filename,0,strlen(filename)-3) + 'dat'

  if n_elements(daily) EQ 0 then begin

    spp_fld_write_packet_file, packet_filename, packets

  endif else begin

    ; TODO: Check for presence of environment variables

    packet_filename = packet_filename.Replace(getenv('SPP_FLD_CDF_DAILY_DIR'), $
      getenv('SPP_FLD_DAT_DAILY_DIR'))
      
    file_mkdir, file_dirname(packet_filename)

    spp_fld_write_packet_file, packet_filename, packets

  endelse


  ;
  ; Put data into the CDF file
  ;

  spp_fld_cdf_put_metadata, fileid, filename, cdf_att

  spp_fld_cdf_put_time, fileid, times.ToArray()

  spp_fld_cdf_put_depend, fileid, idl_att = idl_att

  spp_fld_cdf_put_data, fileid, data, /close


  ;
  ; If load keyword set, load file into tplot variables
  ;

  if keyword_set(load) then begin

    if file_test(filename) then begin

      spp_fld_load_l1, filename

      if !spp_fld_tmlib.test_cdf_dir NE '' then begin

        file_mkdir, !spp_fld_tmlib.test_cdf_dir

        file_copy, filename, !spp_fld_tmlib.test_cdf_dir, /over

      end

    end

    if file_test(packet_filename) then begin

      if !spp_fld_tmlib.test_cdf_dir NE '' then begin

        file_copy, packet_filename, !spp_fld_tmlib.test_cdf_dir, /over

      end

    end

  endif

end