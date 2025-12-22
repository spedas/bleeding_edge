;------------------------------------------------------------------------------
;
;  NSSDC/CDF						MSC (Map Status Code).
;
;  Version 1.2, 9-Sep-96, Hughes STX
;
;  Modification history:
;
;   V1.0  12-Jan-94, J Love	Original version.
;   V1.0a  4-Feb-94, J Love	DEC Alpha/OpenVMS port.
;   V1.1   1-Nov-94, J Love	CDF V2.5.
;   V1.1a 26-Jun-95, J Love	IDL 4.0.
;   V1.2   9-Sep-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; MSC.
;------------------------------------------------------------------------------

;+
; NAME:
;       MSC
;
; PURPOSE:
;       MSC (Map Status Code) is used to map (look up) the numeric value
;       associated with the (IDL) variables defined in `cdf1.pro'.  MSC would
;       be used in those cases where it is not possible to include `cdf1.pro'
;       (by executing `@cdf1.pro' at the IDL command line) because of the
;       limit on the number of local variable which may exist in a function
;       or procedure (as imposed by IDL).
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       value = MSC (name)
;
; INPUTS:
;       name:           STRING.  Symbolic name of the status code whose value
;                       is desired.
;
; OUTPUTS:
;       value:          LONG.  The associated value.
;
; EXAMPLE:
;       IDL> status = CDFopen ('flux1', id)
;       IDL> if (status lt MCP('CDF_WARN')) print, 'CDFopen failed.'
;       IDL> if (status eq MSC('NO_SUCH_CDF')) print, 'No such CDF.'
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       23-Aug-93        Original version.
;       26-Jun-95        IDL 4.0.
;       21-Aug-96        CDF V2.6.
;-

function MSC, symbol
@cdf1.pro
;------------------------------------------------------------------------------
; Check for status codes...
;------------------------------------------------------------------------------
if (symbol eq 'VIRTUAL_RECORD_DATA') then return, VIRTUAL_RECORD_DATA
if (symbol eq 'CDF_OK') then return, CDF_OK
if (symbol eq 'ATTR_NAME_TRUNC') then return, ATTR_NAME_TRUNC
if (symbol eq 'CDF_NAME_TRUNC') then return, CDF_NAME_TRUNC
if (symbol eq 'VAR_NAME_TRUNC') then return, VAR_NAME_TRUNC
if (symbol eq 'NEGATIVE_FP_ZERO') then return, NEGATIVE_FP_ZERO
if (symbol eq 'VAR_ALREADY_CLOSED') then return, VAR_ALREADY_CLOSED
if (symbol eq 'SINGLE_FILE_FORMAT') then return, SINGLE_FILE_FORMAT
if (symbol eq 'NO_FILLVALUE_SPECIFIED') then return, NO_FILLVALUE_SPECIFIED
if (symbol eq 'NO_VARS_IN_CDF') then return, NO_VARS_IN_CDF
if (symbol eq 'CDF_WARN') then return, CDF_WARN
if (symbol eq 'ATTR_EXISTS') then return, ATTR_EXISTS
if (symbol eq 'BAD_CDF_ID') then return, BAD_CDF_ID
if (symbol eq 'BAD_DATA_TYPE') then return, BAD_DATA_TYPE
if (symbol eq 'BAD_DIM_SIZE') then return, BAD_DIM_SIZE
if (symbol eq 'BAD_DIM_INDEX') then return, BAD_DIM_INDEX
if (symbol eq 'BAD_ENCODING') then return, BAD_ENCODING
if (symbol eq 'BAD_MAJORITY') then return, BAD_MAJORITY
if (symbol eq 'BAD_NUM_DIMS') then return, BAD_NUM_DIMS
if (symbol eq 'BAD_REC_NUM') then return, BAD_REC_NUM
if (symbol eq 'BAD_SCOPE') then return, BAD_SCOPE
if (symbol eq 'BAD_NUM_ELEMS') then return, BAD_NUM_ELEMS
if (symbol eq 'CDF_OPEN_ERROR') then return, CDF_OPEN_ERROR
if (symbol eq 'CDF_EXISTS') then return, CDF_EXISTS
if (symbol eq 'BAD_FORMAT') then return, BAD_FORMAT
if (symbol eq 'NO_SUCH_ATTR') then return, NO_SUCH_ATTR
if (symbol eq 'NO_SUCH_ENTRY') then return, NO_SUCH_ENTRY
if (symbol eq 'NO_SUCH_VAR') then return, NO_SUCH_VAR
if (symbol eq 'VAR_READ_ERROR') then return, VAR_READ_ERROR
if (symbol eq 'VAR_WRITE_ERROR') then return, VAR_WRITE_ERROR
if (symbol eq 'BAD_ARGUMENT') then return, BAD_ARGUMENT
if (symbol eq 'IBM_PC_OVERFLOW') then return, IBM_PC_OVERFLOW
if (symbol eq 'TOO_MANY_VARS') then return, TOO_MANY_VARS
if (symbol eq 'VAR_EXISTS') then return, VAR_EXISTS
if (symbol eq 'BAD_MALLOC') then return, BAD_MALLOC
if (symbol eq 'NOT_A_CDF') then return, NOT_A_CDF
if (symbol eq 'CORRUPTED_V2_CDF') then return, CORRUPTED_V2_CDF
if (symbol eq 'VAR_OPEN_ERROR') then return, VAR_OPEN_ERROR
if (symbol eq 'BAD_INITIAL_RECS') then return, BAD_INITIAL_RECS
if (symbol eq 'BAD_BLOCKING_FACTOR') then return, BAD_BLOCKING_FACTOR
if (symbol eq 'END_OF_VAR') then return, END_OF_VAR
if (symbol eq 'BAD_CDFSTATUS') then return, BAD_CDFSTATUS
if (symbol eq 'BAD_REC_COUNT') then return, BAD_REC_COUNT
if (symbol eq 'BAD_REC_INTERVAL') then return, BAD_REC_INTERVAL
if (symbol eq 'BAD_DIM_COUNT') then return, BAD_DIM_COUNT
if (symbol eq 'BAD_DIM_INTERVAL') then return, BAD_DIM_INTERVAL
if (symbol eq 'BAD_VAR_NUM') then return, BAD_VAR_NUM
if (symbol eq 'BAD_ATTR_NUM') then return, BAD_ATTR_NUM
if (symbol eq 'BAD_ENTRY_NUM') then return, BAD_ENTRY_NUM
if (symbol eq 'BAD_ATTR_NAME') then return, BAD_ATTR_NAME
if (symbol eq 'BAD_VAR_NAME') then return, BAD_VAR_NAME
if (symbol eq 'NO_ATTR_SELECTED') then return, NO_ATTR_SELECTED
if (symbol eq 'NO_ENTRY_SELECTED') then return, NO_ENTRY_SELECTED
if (symbol eq 'NO_VAR_SELECTED') then return, NO_VAR_SELECTED
if (symbol eq 'BAD_CDF_NAME') then return, BAD_CDF_NAME
if (symbol eq 'CANNOT_CHANGE') then return, CANNOT_CHANGE
if (symbol eq 'NO_STATUS_SELECTED') then return, NO_STATUS_SELECTED
if (symbol eq 'NO_CDF_SELECTED') then return, NO_CDF_SELECTED
if (symbol eq 'READ_ONLY_DISTRIBUTION') then return, READ_ONLY_DISTRIBUTION
if (symbol eq 'CDF_CLOSE_ERROR') then return, CDF_CLOSE_ERROR
if (symbol eq 'VAR_CLOSE_ERROR') then return, VAR_CLOSE_ERROR
if (symbol eq 'BAD_FNC_OR_ITEM') then return, BAD_FNC_OR_ITEM
if (symbol eq 'ILLEGAL_ON_V1_CDF') then return, ILLEGAL_ON_V1_CDF
if (symbol eq 'CDF_CREATE_ERROR') then return, CDF_CREATE_ERROR
if (symbol eq 'NO_SUCH_CDF') then return, NO_SUCH_CDF
if (symbol eq 'VAR_CREATE_ERROR') then return, VAR_CREATE_ERROR
if (symbol eq 'READ_ONLY_MODE') then return, READ_ONLY_MODE
if (symbol eq 'ILLEGAL_IN_zMODE') then return, ILLEGAL_IN_zMODE
if (symbol eq 'BAD_zMODE') then return, BAD_zMODE
if (symbol eq 'BAD_READONLY_MODE') then return, BAD_READONLY_MODE
if (symbol eq 'CDF_READ_ERROR') then return, CDF_READ_ERROR
if (symbol eq 'CDF_WRITE_ERROR') then return, CDF_WRITE_ERROR
if (symbol eq 'ILLEGAL_FOR_SCOPE') then return, ILLEGAL_FOR_SCOPE
if (symbol eq 'NO_MORE_ACCESS') then return, NO_MORE_ACCESS
if (symbol eq 'BAD_DECODING') then return, BAD_DECODING
if (symbol eq 'MULTI_FILE_FORMAT') then return, MULTI_FILE_FORMAT
if (symbol eq 'BAD_NEGtoPOSfp0_MODE') then return, BAD_NEGtoPOSfp0_MODE
if (symbol eq 'UNSUPPORTED_OPERATION') then return, UNSUPPORTED_OPERATION
if (symbol eq 'BAD_CACHE_SIZE') then return, BAD_CACHE_SIZE
if (symbol eq 'CDF_INTERNAL_ERROR') then return, CDF_INTERNAL_ERROR
if (symbol eq 'BAD_NUM_VARS') then return, BAD_NUM_VARS
if (symbol eq 'NO_WRITE_ACCESS') then return, NO_WRITE_ACCESS
if (symbol eq 'NO_DELETE_ACCESS') then return, NO_DELETE_ACCESS
if (symbol eq 'BAD_ALLOCATE_RECS') then return, BAD_ALLOCATE_RECS
if (symbol eq 'BAD_CDF_EXTENSION') then return, BAD_CDF_EXTENSION
if (symbol eq 'SOME_ALREADY_ALLOCATED') then return, SOME_ALREADY_ALLOCATED
if (symbol eq 'PRECEEDING_RECORDS_ALLOCATED') then $
  return, PRECEEDING_RECORDS_ALLOCATED
if (symbol eq 'FORCED_PARAMETER') then return, FORCED_PARAMETER
if (symbol eq 'NA_FOR_VARIABLE') then return, NA_FOR_VARIABLE
if (symbol eq 'CDF_DELETE_ERROR') then return, CDF_DELETE_ERROR
if (symbol eq 'VAR_DELETE_ERROR') then return, VAR_DELETE_ERROR
if (symbol eq 'UNKNOWN_COMPRESSION') then return, UNKNOWN_COMPRESSION
if (symbol eq 'CANNOT_COMPRESS') then return, CANNOT_COMPRESS
if (symbol eq 'DECOMPRESSION_ERROR') then return, DECOMPRESSION_ERROR
if (symbol eq 'COMPRESSION_ERROR') then return, COMPRESSION_ERROR
if (symbol eq 'TOO_MANY_PARMS') then return, TOO_MANY_PARMS
if (symbol eq 'EMPTY_COMPRESSED_CDF') then return, EMPTY_COMPRESSED_CDF
if (symbol eq 'BAD_COMPRESSION_PARM') then return, BAD_COMPRESSION_PARM
if (symbol eq 'UNKNOWN_SPARSENESS') then return, UNKNOWN_SPARSENESS
if (symbol eq 'CANNOT_SPARSERECORDS') then return, CANNOT_SPARSERECORDS
if (symbol eq 'CANNOT_SPARSEARRAYS') then return, CANNOT_SPARSEARRAYS
if (symbol eq 'NO_SUCH_RECORD') then return, NO_SUCH_RECORD
if (symbol eq 'CANNOT_ALLOCATE_RECORDS') then return, CANNOT_ALLOCATE_RECORDS
if (symbol eq 'SCRATCH_DELETE_ERROR') then return, SCRATCH_DELETE_ERROR
if (symbol eq 'SCRATCH_CREATE_ERROR') then return, SCRATCH_CREATE_ERROR
if (symbol eq 'SCRATCH_READ_ERROR') then return, SCRATCH_READ_ERROR
if (symbol eq 'SCRATCH_WRITE_ERROR') then return, SCRATCH_WRITE_ERROR
if (symbol eq 'BAD_SPARSEARRAYS_PARM') then return, BAD_SPARSEARRAYS_PARM
if (symbol eq 'BAD_SCRATCH_DIR') then return, BAD_SCRATCH_DIR
if (symbol eq 'DID_NOT_COMPRESS') then return, DID_NOT_COMPRESS
;------------------------------------------------------------------------------
; Check for synonyms...
;------------------------------------------------------------------------------
if (symbol eq 'BAD_EXTEND_RECS') then return, BAD_EXTEND_RECS
;------------------------------------------------------------------------------
; Unknown status code.
;------------------------------------------------------------------------------
print, "<<< Unknown/invalid symbol in MSC >>>"
return, 0L
end
