;------------------------------------------------------------------------------
;
;  NSSDC/CDF					IDL/CDF Interface, row_to_col.
;
;  Version 1.1, 16-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0   7-Nov-94, J Love	Original version.
;   V1.0a 26-Jun-95, J Love	IDL 4.0.
;   V1.1  16-Aug-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; col_to_row.
;------------------------------------------------------------------------------

;+
; NAME:
;       col_to_row
;
; PURPOSE:
;       `col_to_row' is used to switch the majority of a multi-dimensional
;       array from column-major to row-major.  This function would be used
;       before writing an array of values (created by IDL) to a row-major
;       CDF using `CDFvarHyperPut' (or `CDFlib').
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       status = col_to_row (iBuffer, oBuffer, numDims, dimSizes, numBytes, $
;                            numRecs)
;
; INPUTS:
;       iBuffer:        DATA TYPE DEPENDENT.  The multi-dimensional array
;                       (IDL variable) whose majority is to be reversed.
;       numDims:        LONG.  The number of dimensions (in each record).
;       dimSizes:       LONG array.  The dimension sizes (in each record).
;       numBytes:       LONG.  The number of bytes per value.
;       numRecs:        LONG.  The number of CDF records in the buffer.
;                       Note that the majority is only changed within each
;                       record - the ordering of the records remains the
;                       same (the last dimension of the IDL variable is not
;                       affected).
;
;       All input variables must have been created/initialized before calling
;       `col_to_row'.
;
; OUTPUTS:
;       oBuffer:        DATA TYPE DEPENDENT.  A newly created/recreated IDL
;                       variable (with the same dimensionality as `iBuffer')
;                       with reversed (row-major) majority.
;
;       status:         LONG.  A completion status code.  CDF_OK indicates
;                       success.  The possible status codes are defined by
;                       `cdf0x.pro'.
;
;       All output variables are (re)created/assigned by `col_to_row'.
;
; EXAMPLE:
;       Assume that 5 records are to be written to an rVariable whose
;       dimensionality is 2:[10,30] in a CDF with row-major majority.
;       The records are to be written from an IDL variable named `iBuffer'
;       which was created using `fltarr(10,30,5)' and then loaded with
;       data.  If the data type of the rVariable is CDF_REAL4 (4-byte
;       floating-point), the majority would be reversed as follows...
;
;       IDL> @cdf0x.pro
;       IDL> dimSizes = lonarr(2)
;       IDL> dimSizes(0) = 10
;       IDL> dimSizes(1) = 30
;       IDL> status = col_to_row (iBuffer, oBuffer, 2L, dimSizes, 4L, 5L)
;       IDL> if (status lt CDFx.CDF_WARN) print, 'col_to_row failed.'
;
;       `oBuffer' would also be created/recreated as `fltarr(10,30,5)' by
;       `col_to_row'.
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;        7-Nov-94        Original version.
;       26-Jun-95        IDL 4.0.
;       21-Aug-96        CDF V2.6.
;-

function col_to_row, ibuf,obuf,num_dims,dim_sizes,num_bytes,num_records
on_error, 1
obuf = ibuf
col_2_row, ibuf, obuf, num_dims, dim_sizes, num_bytes, num_records, status
return, status
end
