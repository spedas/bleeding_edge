;+
; NAME:
;   SPP_FLD_CDF_PUT_DATA
;
; PURPOSE:
;   Stores SPP/FIELDS data in a created CDF file.
;
; CALLING SEQUENCE:
;   spp_fld_cdf_put_data, fileid, data, close = close
;
; INPUTS:
;   FILEID: The file ID of the destination CDF file.
;   DATA: A single IDL hash which contains items to be put into the
;     CDF file.  The items themselves are hashes.  Each data item is itself
;     an IDL hash which contains:
;       - the parsed information from the corresponding XML file definition
;         of the data item
;       - the set of CDF attributes which will be stored as metadata in the
;         CDF file
;       - the data itself, as an IDL list.  The list is converted into an
;         array before being stored in the CDF file.
;     Items which do not have defined CDF attributes are not stored in the
;     CDF file.
;   CLOSE: Set to 1 to close the CDF after putting in the data.
;
; OUTPUTS:
;   No explicit outputs are returned.  After completion, the data in the
;   input IDL hash is stored in the specified CDF file.
;
; EXAMPLE:
;   See call in SPP_FLD_MAKE_CDF_L1.
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2018-10-02 15:53:19 -0700 (Tue, 02 Oct 2018) $
; $LastChangedRevision: 25885 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_cdf_put_data.pro $
;-
pro spp_fld_cdf_put_data, fileid, data, close = close, compression = compression

  if not keyword_set(compression) then compression = 6

  if not keyword_set(fileid) then begin
    print, 'file must be specified'
    return
  endif

  foreach data_item, data, item_name do begin

    data_array = []
    data_array_string = []

    if data_item.HasKey('cdf_att') EQ 0 then begin

      print, 'CDF attributes not defined for ', item_name

    endif else begin

      cdf_var_name = (data_item['cdf_att'])['FIELDNAM']

      null_ind = data_item['data'].Where(!NULL, count = null_count, $
        complement = non_null_ind, ncomplement = non_null_count)

      cdf_atts = data_item['cdf_att']

      ; Check for null records.  If null records exist, then create
      ; a sparse CDF variable.  If no non-null records exist, then
      ; create a non-sparse variable.

      ; TODO: enable selective addition for sparse CDFs

      ; TODO: save raw data in CDF file as well as converted data

      cdf_sparse = (null_count NE 0)

      if non_null_count GT 0 then begin

        if data_item.HasKey('convert_routine') then begin

          ; TODO: Check for presence of convert routine, print error if not found

          raw_data_array = (spp_fld_square_list(data_item['data'])).ToArray()

          if data_item['convert_routine'] NE 'none' then begin

            data_array = call_function(data_item['convert_routine'], raw_data_array)

          endif else begin

            data_array = raw_data_array

          endelse

        endif else begin

          data_array = (data_item['data']).ToArray()

        endelse

        data_dim = size(data_array, /dim)
        data_ndim = n_elements(data_dim) - 1

        dprint, 'Data Type: ', size(data_array, /tname), dlevel = 3
        dprint, 'Data Dimensions: ', data_dim, dlevel = 3
        dprint, 'Number of CDF dimensions: ', data_ndim, dlevel = 3

        data_array_string = (data_item['data_string']).ToArray()

        dprint, 'Number of Strings:', n_elements(data_array_string), dlevel = 3

        data_array_raw = (data_item['data_raw']).ToArray()

        dprint, '# of Raw Data Points:', n_elements(data_array_raw), dlevel = 3

        ;stop

      end

      if cdf_atts.HasKey('DATA_TYPE') then begin

        cdf_data_type = cdf_atts['DATA_TYPE']

      endif else begin

        cdf_data_type = 'CDF_FLOAT'

      endelse

      if non_null_count GT 0 then begin
        if data_ndim GT 0 then begin

          cdf_data_dims = data_dim[1:*]
          cdf_data_vary = intarr(data_ndim) + 1
          varid = cdf_varcreate(fileid, cdf_var_name, cdf_data_vary, $
            dim = cdf_data_dims, /REC_VARY, /ZVARIABLE, $
            _EXTRA = CREATE_STRUCT(cdf_data_type,1))

          ; TODO: this works for simple 2D spectra but for higher dimensions
          ; might need something different
          data_array = transpose(data_array)

        endif else begin

          varid = cdf_varcreate(fileid, cdf_var_name, /REC_VARY, /ZVARIABLE, $
            _EXTRA = CREATE_STRUCT(cdf_data_type,1))

        endelse

      endif else begin

        nelem = spp_fld_tmlib_item_nelem(data_item)

        fillval = spp_fld_tmlib_item_fillval(data_item)

        fill_arr = make_array(nelem, value = fillval)

        cdf_data_dims = [nelem]
        cdf_data_vary = [1]

        n_records = n_elements(data_item['data'])

        varid = cdf_varcreate(fileid, cdf_var_name, cdf_data_vary, $
          dim = cdf_data_dims, /REC_VARY, /ZVARIABLE, $
          _EXTRA = CREATE_STRUCT(cdf_data_type,1))

      endelse

      if n_elements(data_array_string) GT 0 then begin

        varid_str = cdf_varcreate(fileid, cdf_var_name + '_string', $
          numelem = strlen(data_array_string[0]), /rec_vary, /zvariable, $
          /cdf_char)

        if n_elements(compression) GT 0 and n_elements(varid_str) GT 0 then begin
          CDF_COMPRESSION, fileid, $
            SET_VAR_GZIP_LEVEL=compression, $
            VARIABLE=varid_str, $
            /ZVARIABLE
        end

      endif

      if n_elements(data_array_raw) GT 0 then begin

        varid_raw = cdf_varcreate(fileid, cdf_var_name + '_raw', $
          dim = cdf_data_dims, /rec_vary, /zvariable, $
          /cdf_int4)

        if n_elements(compression) GT 0 and n_elements(varid_raw) GT 0 then begin
          CDF_COMPRESSION, fileid, $
            SET_VAR_GZIP_LEVEL=compression, $
            VARIABLE=varid_raw, $
            /ZVARIABLE
        end

      endif

      if n_elements(compression) GT 0 and n_elements(varid) GT 0 then begin
        CDF_COMPRESSION, fileid, $
          SET_VAR_GZIP_LEVEL=compression, $
          VARIABLE=varid, $
          /ZVARIABLE
      end

      dprint, '', dlevel = 3
      dprint, 'Variable ', varid, cdf_var_name, $
        format = '(A, I6, A20)', dlevel = 3
      dprint, 'CDF Attributes: ', dlevel = 3

      foreach cdf_att, cdf_atts, cdf_attname do begin

        ;if cdf_attname NE 'DEPEND_0' then begin

        cdf_attput, fileid, cdf_attname, varid, cdf_att, /zvariable

        dprint, cdf_attname, cdf_att, dlevel = 3, $
          format = '(A20, " ", A40)'

        if cdf_attname EQ 'VAR_SPARSERECORDS' then begin

          if cdf_att EQ 'PAD_MISSING' then begin
            cdf_control, fileid, var = cdf_var_name, $
              SET_SPARSERECORDS = 'PAD_SPARSERECORDS'
          endif

        endif

        if n_elements(data_array_string) GT 0 then begin

          case cdf_attname of
            'FORMAT': ; no FORMAT attribute for string variable
            'FILLVAL': cdf_attput, fileid, cdf_attname, varid_str, $
              ' ', /zvariable
            'SCALEMIN': ; no SCALEMIN attribute for string variable
            'SCALEMAX': ; no SCALEMAX attribute for string variable
            'VALIDMIN': ; no VALIDMIN attribute for string variable
            'VALIDMAX': ; no VALIDMAX attribute for string variable
            'DATA_TYPE': cdf_attput, fileid, cdf_attname, varid_str, $
              'CDF_CHAR', /zvariable
            ELSE: cdf_attput, fileid, cdf_attname, varid_str, $
              cdf_att, /zvar
          end
        end

        if n_elements(data_array_raw) GT 0 then begin

          case cdf_attname of
            'FORMAT': cdf_attput, fileid, cdf_attname, varid_raw, 'I16', /zvariable
            'FILLVAL': cdf_attput, fileid, cdf_attname, varid_raw, '-2147483647', /zvariable
            'SCALEMIN': cdf_attput, fileid, cdf_attname, varid_raw, '-2147483647', /zvariable
            'SCALEMAX': cdf_attput, fileid, cdf_attname, varid_raw, '2147483647', /zvariable
            'VALIDMIN': cdf_attput, fileid, cdf_attname, varid_raw, '-2147483647', /zvariable
            'VALIDMAX': cdf_attput, fileid, cdf_attname, varid_raw, '2147483647', /zvariable
            'DATA_TYPE': cdf_attput, fileid, cdf_attname, varid_raw, 'CDF_INT4', /zvariable
            'UNITS':cdf_attput, fileid, cdf_attname, varid_raw, "Counts", /zvar
            ELSE: cdf_attput, fileid, cdf_attname, varid_raw, $
              cdf_att, /zvar
          end
        end

      endforeach

      if non_null_count GT 0 then begin

        cdf_varput, fileid, cdf_var_name, data_array

        if n_elements(data_array_string) GT 0 then begin

          cdf_varput, fileid, cdf_var_name + '_string', data_array_string

        endif

        if n_elements(data_array_raw) GT 0 then begin

          cdf_varput, fileid, cdf_var_name + '_raw', data_array_raw

        endif

      endif else begin

        print, 'No non-null records for ', cdf_var_name

        ; Get the number of elements in the data item

        ; TODO: fix this kludge

        ;cdf_varput, fileid, cdf_var_name, fill_arr, rec_start = n_records - 1

        ;stop

      endelse


    endelse

  endforeach


  if keyword_set(close) then cdf_close, fileid

end