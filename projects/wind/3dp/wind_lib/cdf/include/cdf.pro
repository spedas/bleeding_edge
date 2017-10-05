;******************************************************************************
;
;  NSSDC/CDF				CDF/IDL constants (excluding status
;					codes and Internal interface).
;
;  Version 1.5a, 21-Feb-97, Hughes STX.
;
;  Modification history:
;
;   V1.0  23-Sep-92, H Leckner	Original version.
;   V1.0b  6-Oct-92, J Love	CDF V2.3.0b (CDFcompare).
;   V1.1  27-Oct-92, J Love	Removed version/release/increment.
;   V1.2  23-Aug-93, J Love	CDF V2.4.
;   V1.2a  4-Feb-94, J Love	DEC Alpha/OpenVMS port.
;   V1.3  31-Oct-94, J Love	CDF V2.5.
;   V1.3a 12-Jun-95, J Love	EPOCH custom format.
;   V1.4  26-Jun-95, J Love	Added online help.
;   V1.5   9-Sep-96, J Love	CDF V2.6.
;   V1.5a 21-Feb-97, J Love	Removed RICE.
;
;******************************************************************************

;+
; NAME:
;       cdf.pro
;
; PURPOSE:
;       `cdf.pro' is used to create a set of local variables containing the
;       general constants used by the CDF library.  The CDF status codes are
;       defined by `cdf1.pro' and the CDF Internal Interface constants are
;       defined by `cdf2.pro'.
;
;       This include file is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       IDL> @cdf.pro
;
; RESTRICTIONS:
;       The use of `cdf.pro' may result in too many local variables being
;       created.  If that occurs, consider using `cdf0x.pro' instead.
;
; REVISION HISTORY:
;       26-Jun-95        Original version.
;       21-Aug-96        CDF V2.6.
;-

;******************************************************************************
; Status codes/thresholds.  These are commonly used so they appear here as well
; as with the other status codes [to save available IDL variables].
;******************************************************************************

CDF_OK			= 0L
CDF_WARN		= -2000L

;******************************************************************************
; Limits
;******************************************************************************

CDF_MIN_DIMS		= 0L
CDF_MAX_DIMS		= 10L

;******************************************************************************
; Lengths
;******************************************************************************

CDF_VAR_NAME_LEN  	= 64L
CDF_ATTR_NAME_LEN 	= 64L
CDF_COPYRIGHT_LEN 	= 256L
CDF_STATUSTEXT_LEN 	= 80L
CDF_PATHNAME_LEN	= 128L

EPOCH_STRING_LEN	= 24L
EPOCH1_STRING_LEN	= 16L
EPOCH2_STRING_LEN	= 14L
EPOCH3_STRING_LEN	= 24L

EPOCHx_STRING_MAX	= 30L
EPOCHx_FORMAT_MAX	= 60L

;******************************************************************************
; Data types.
;******************************************************************************

CDF_INT1		=  1L
CDF_INT2		=  2L
CDF_INT4		=  4L
CDF_UINT1		= 11L
CDF_UINT2		= 12L
CDF_UINT4		= 14L
CDF_REAL4		= 21L
CDF_REAL8		= 22L
CDF_EPOCH		= 31L
CDF_BYTE		= 41L
CDF_FLOAT		= 44L			
CDF_DOUBLE		= 45L			
CDF_CHAR		= 51L
CDF_UCHAR		= 52L	

;******************************************************************************
; Encodings (for data only, everything else is network encoding).
;*****************************************************************************/

NETWORK_ENCODING	=  1L
SUN_ENCODING		=  2L
VAX_ENCODING		=  3L
DECSTATION_ENCODING	=  4L
SGi_ENCODING		=  5L
IBMPC_ENCODING		=  6L
IBMRS_ENCODING		=  7L
HOST_ENCODING		=  8L
MAC_ENCODING		=  9L
HP_ENCODING		= 11L
NeXT_ENCODING		= 12L
ALPHAOSF1_ENCODING	= 13L
ALPHAVMSd_ENCODING	= 14L
ALPHAVMSg_ENCODING	= 15L

;******************************************************************************
; Decodings.
;*****************************************************************************/

NETWORK_DECODING	= NETWORK_ENCODING
SUN_DECODING		= SUN_ENCODING
VAX_DECODING		= VAX_ENCODING
DECSTATION_DECODING	= DECSTATION_ENCODING
SGi_DECODING		= SGi_ENCODING
IBMPC_DECODING		= IBMPC_ENCODING
IBMRS_DECODING		= IBMRS_ENCODING
HOST_DECODING		= HOST_ENCODING
MAC_DECODING		= MAC_ENCODING
HP_DECODING		= HP_ENCODING
NeXT_DECODING		= NeXT_ENCODING
ALPHAOSF1_DECODING	= ALPHAOSF1_ENCODING
ALPHAVMSd_DECODING	= ALPHAVMSd_ENCODING
ALPHAVMSg_DECODING	= ALPHAVMSg_ENCODING

;******************************************************************************
; Variance flags
;******************************************************************************

VARY			= -1L
NOVARY			=  0L

;******************************************************************************
; Majorities
;******************************************************************************

ROW_MAJOR		= 1L
COLUMN_MAJOR		= 2L

;******************************************************************************
; Formats.
;******************************************************************************

SINGLE_FILE		= 1L
MULTI_FILE		= 2L

;******************************************************************************
; Attribute scopes
;******************************************************************************

GLOBAL_SCOPE		= 1L
VARIABLE_SCOPE		= 2L

;******************************************************************************
; Readonly modes.
;******************************************************************************

READONLYon		= -1L
READONLYoff		=  0L

;******************************************************************************
; zModes.
;******************************************************************************

zMODEoff		= 0L
zMODEon1		= 1L
zMODEon2		= 2L

;******************************************************************************
; Negative to positive floating point zero modes.
;******************************************************************************

NEGtoPOSfp0on		= -1L
NEGtoPOSfp0off		=  0L

;******************************************************************************
; Compression/sparseness constants.
;******************************************************************************

CDF_MAX_PARMS		= 5
NO_COMPRESSION		= 0L
RLE_COMPRESSION		= 1L
HUFF_COMPRESSION	= 2L
AHUFF_COMPRESSION	= 3L
GZIP_COMPRESSION	= 5L
RLE_OF_ZEROs		= 0L
OPTIMAL_ENCODING_TREES	= 0L
NO_SPARSEARRAYS		= 0L
NO_SPARSERECORDS	= 0L
PAD_SPARSERECORDS	= 1L
PREV_SPARSERECORDS	= 2L

;******************************************************************************
; Synonyms.
;******************************************************************************

MIPSEB_ENCODING		= SGi_ENCODING
GLOBAL_SCOPE_ASSUMED	= GLOBAL_SCOPE
VARIABLE_SCOPE_ASSUMED	= VARIABLE_SCOPE
COL_MAJOR		= COLUMN_MAJOR
