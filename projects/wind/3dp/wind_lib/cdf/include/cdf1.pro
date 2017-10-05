;******************************************************************************
;
;  NSSDC/CDF				CDF/IDL constants (status codes only).
;
;  Version 1.4, 9-Sep-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  21-Sep-92, H Leckner	Original version.
;   V1.1  12-Jan-94, J Love	CDF V2.4.
;   V1.2  24-Oct-94, J Love	CDF V2.5.
;   V1.3  26-Jun-95, J Love	Added online help.
;   V1.4   9-Sep-96, J Love	CDF V2.6.
;
;******************************************************************************

;+
; NAME:
;       cdf1.pro
;
; PURPOSE:
;       `cdf1.pro' is used to create a set of local variables containing the
;       status codes used by the CDF library.  The general CDF constants are
;       defined by `cdf.pro' and the CDF Internal Interface constants are
;       defined by `cdf2.pro'.
;
;       This include file is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       IDL> @cdf1.pro
;
; RESTRICTIONS:
;       The use of `cdf1.pro' may result in too many local variables being
;       created.  If that occurs, consider using `cdf0x.pro' instead.
;
; REVISION HISTORY:
;       26-Jun-95        Original version.
;       21-Aug-96        CDF V2.6.
;-

;******************************************************************************
;  Status codes...
;   - informatory codes are greater than CDF_OK
;******************************************************************************

VIRTUAL_RECORD_DATA		= 1001L
DID_NOT_COMPRESS		= 1002L
VAR_ALREADY_CLOSED		= 1003L
SINGLE_FILE_FORMAT		= 1004L
NO_PADVALUE_SPECIFIED		= 1005L
NO_VARS_IN_CDF			= 1006L
MULTI_FILE_FORMAT		= 1007L
SOME_ALREADY_ALLOCATED		= 1008L
PRECEEDING_RECORDS_ALLOCATED	= 1009L

CDF_OK				= 0L

ATTR_NAME_TRUNC			= -1001L
CDF_NAME_TRUNC			= -1002L
VAR_NAME_TRUNC			= -1003L
NEGATIVE_FP_ZERO		= -1004L
; unused			= -1005L
FORCED_PARAMETER		= -1006L
NA_FOR_VARIABLE			= -1007L

CDF_WARN			= -2000L

ATTR_EXISTS			= -2001L
BAD_CDF_ID			= -2002L
BAD_DATA_TYPE			= -2003L
BAD_DIM_SIZE			= -2004L
BAD_DIM_INDEX			= -2005L
BAD_ENCODING			= -2006L
BAD_MAJORITY			= -2007L
BAD_NUM_DIMS			= -2008L
BAD_REC_NUM			= -2009L
BAD_SCOPE			= -2010L
BAD_NUM_ELEMS			= -2011L
CDF_OPEN_ERROR			= -2012L
CDF_EXISTS			= -2013L
BAD_FORMAT			= -2014L
BAD_ALLOCATE_RECS		= -2015L
BAD_CDF_EXTENSION		= -2016L
NO_SUCH_ATTR			= -2017L
NO_SUCH_ENTRY			= -2018L
NO_SUCH_VAR			= -2019L
VAR_READ_ERROR			= -2020L
VAR_WRITE_ERROR			= -2021L
BAD_ARGUMENT			= -2022L
IBM_PC_OVERFLOW			= -2023L
TOO_MANY_VARS			= -2024L
VAR_EXISTS			= -2025L
BAD_MALLOC              	= -2026L
NOT_A_CDF               	= -2027L
CORRUPTED_V2_CDF		= -2028L
VAR_OPEN_ERROR			= -2029L
BAD_INITIAL_RECS		= -2030L
BAD_BLOCKING_FACTOR		= -2031L
END_OF_VAR			= -2032L
; unused			= -2033L
BAD_CDFSTATUS			= -2034L
CDF_INTERNAL_ERROR		= -2035L
BAD_NUM_VARS			= -2036L
BAD_REC_COUNT			= -2037L
BAD_REC_INTERVAL		= -2038L
BAD_DIM_COUNT			= -2039L
BAD_DIM_INTERVAL		= -2040L
BAD_VAR_NUM			= -2041L
BAD_ATTR_NUM			= -2042L
BAD_ENTRY_NUM			= -2043L
BAD_ATTR_NAME			= -2044L
BAD_VAR_NAME			= -2045L
NO_ATTR_SELECTED		= -2046L
NO_ENTRY_SELECTED		= -2047L
NO_VAR_SELECTED			= -2048L
BAD_CDF_NAME			= -2049L
; unused			= -2050L
CANNOT_CHANGE			= -2051L
NO_STATUS_SELECTED		= -2052L
NO_CDF_SELECTED			= -2053L
READ_ONLY_DISTRIBUTION		= -2054L
CDF_CLOSE_ERROR			= -2055L
VAR_CLOSE_ERROR			= -2056L
; unused			= -2057L
BAD_FNC_OR_ITEM			= -2058L
; unused			= -2059L
ILLEGAL_ON_V1_CDF		= -2060L
; unused			= -2061L
; unused			= -2062L
BAD_CACHE_SIZE			= -2063L
; unused			= -2064L
; unused			= -2065L
CDF_CREATE_ERROR		= -2066L
NO_SUCH_CDF			= -2067L
VAR_CREATE_ERROR		= -2068L
; unused			= -2069L
READ_ONLY_MODE			= -2070L
ILLEGAL_IN_zMODE		= -2071L
BAD_zMODE			= -2072L
BAD_READONLY_MODE		= -2073L
CDF_READ_ERROR			= -2074L
CDF_WRITE_ERROR			= -2075L
ILLEGAL_FOR_SCOPE		= -2076L
NO_MORE_ACCESS			= -2077L
; unused			= -2078L
BAD_DECODING			= -2079L
; unused			= -2080L
BAD_NEGtoPOSfp0_MODE		= -2081L
UNSUPPORTED_OPERATION		= -2082L
; unused			= -2083L
; unused			= -2084L
; unused			= -2085L
NO_WRITE_ACCESS			= -2086L
NO_DELETE_ACCESS		= -2087L
CDF_DELETE_ERROR		= -2088L
VAR_DELETE_ERROR		= -2089L
UNKNOWN_COMPRESSION		= -2090L
CANNOT_COMPRESS			= -2091L
DECOMPRESSION_ERROR		= -2092L
COMPRESSION_ERROR		= -2093L
; unused			= -2094L
; unused			= -2095L
EMPTY_COMPRESSED_CDF		= -2096L
BAD_COMPRESSION_PARM		= -2097L
UNKNOWN_SPARSENESS		= -2098L
CANNOT_SPARSERECORDS		= -2099L
CANNOT_SPARSEARRAYS		= -2100L
TOO_MANY_PARMS			= -2101L
NO_SUCH_RECORD			= -2102L
CANNOT_ALLOCATE_RECORDS		= -2103L
; unused			= -2104L
; unused			= -2105L
SCRATCH_CREATE_ERROR		= -2106L
SCRATCH_CREATE_ERROR		= -2107L
SCRATCH_READ_ERROR		= -2108L
SCRATCH_WRITE_ERROR		= -2109L
BAD_SPARSEARRAYS_PARM		= -2110L
BAD_SCRATCH_DIR			= -2111L

;******************************************************************************
; Synonyms...
;******************************************************************************

BAD_EXTEND_RECS			= BAD_BLOCKING_FACTOR
