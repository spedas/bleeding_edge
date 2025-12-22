;------------------------------------------------------------------------------
;
;  NSSDC/CDF					IDL/CDF Interface, row_to_col.
;
;  Version 1.4, 21-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  21-Sep-92, H Leckner	Original version.
;   V1.1  10-Dec-92, H Leckner	Removed print/help debug statements.
;   V1.2  13-May-93, J Love	CDF V2.4 (`idl_cdf.pro' split into separate
;                               files as required for online help in IDL).
;   V1.3   7-Nov-94, J Love	CDF V2.5.
;   V1.3a 26-Jun-95, J Love	IDL 4.0.
;   V1.4  21-Aug-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; row_to_col.
;------------------------------------------------------------------------------

;+
; NAME:
;       row_to_col
;
; PURPOSE:
;       `row_to_col' is used to switch the majority of a multi-dimensional
;       array from row-major to column-major (the majority expected by IDL).
;       This function would be used after reading a buffer of rVariable
;       values with `CDFvarHyperGet' from a column-major CDF.
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       status = row_to_col (iBuffer, oBuffer, numDims, dimSizes, numBytes, $
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
;       `row_to_col'.
;
; OUTPUTS:
;       oBuffer:        DATA TYPE DEPENDENT.  A newly created/recreated IDL
;                       variable (with the same dimensionality as `iBuffer')
;                       with reversed (column-major) majority.
;
;       status:         LONG.  A completion status code.  CDF_OK indicates
;                       success.  The possible status codes are defined by
;                       `cdf0x.pro'.
;
;       All output variables are (re)created/assigned by `row_to_col'.
;
; EXAMPLE:
;       Assume that 5 records from an rVariable each with a dimensionality
;       of 2:[10,30] have been read from a CDF with column-major majority
;       into an IDL variable named `iBuffer' which was created by the
;       `CDFvarHyperGet' as `fltarr(10,30,5)'.  If the data type of the
;       rVariable was CDF_REAL4 (4-byte floating-point), the majority would
;       be reversed as follows...
;
;       IDL> @cdf0x.pro
;       IDL> dimSizes = lonarr(2)
;       IDL> dimSizes(0) = 10
;       IDL> dimSizes(1) = 30
;       IDL> status = row_to_col (iBuffer, oBuffer, 2L, dimSizes, 4L, 5L)
;       IDL> if (status lt CDFx.CDF_WARN) print, 'row_to_col failed.'
;
;       `oBuffer' would also be created/recreated as `fltarr(10,30,5)' by
;       `row_to_col'.
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       13-May-93        Original version.
;        7-Nov-94        Fixed example (`lonarr' to `fltarr').
;       26-Jun-95        IDL 4.0.
;       21-Aug-96        CDF V2.6.
;-

function row_to_col, ibuf,obuf,num_dims,dim_sizes,num_bytes,num_records
on_error, 1
obuf = ibuf
row_2_col, ibuf, obuf, num_dims, dim_sizes, num_bytes, num_records, status
return, status
end
