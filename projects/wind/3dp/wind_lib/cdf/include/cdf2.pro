;******************************************************************************
;
;  NSSDC/CDF			CDF/IDL constants (Internal interface only).
;
;  Version 1.4a, 21-Feb-97, Hughes STX.
;
;  Modification history:
;
;   V1.0   3-Sep-92, H Leckner	Original version.
;   V1.1   4-Jan-94, J Love	CDF V2.4.
;   V1.1a 22-Feb-94, J Love	Spelling lesson.
;   V1.2   8-Dec-94, J Love	CDF V2.5.
;   V1.3  26-Jun-95, J Love	Added online help.
;   V1.4  21-Aug-96, J Love	CDF V2.6.
;   V1.4a 21-Feb-97, J Love	Removed RICE.
;
;******************************************************************************

;+
; NAME:
;       cdf2.pro
;
; PURPOSE:
;       `cdf2.pro' is used to create a set of local variables containing the
;       Internal Interface constants used by the CDF library.  The general CDF
;       constants are defined by `cdf.pro' and the CDF status codes are defined
;       by `cdf1.pro'.
;
;       This include file is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       IDL> @cdf2.pro
;
; RESTRICTIONS:
;       The use of `cdf2.pro' may result in too many local variables being
;       created.  If that occurs, consider using `cdf0x.pro' instead.
;
; REVISION HISTORY:
;       26-Jun-95        Original version.
;       21-Aug-96        CDF V2.6.
;-

;******************************************************************************
;  Functions (for INTERNAL interface).
;  NOTE: These values must be different from those of the items.
;******************************************************************************

CREATE_		= 1001L
OPEN_		= 1002L
DELETE_		= 1003L
CLOSE_		= 1004L
SELECT_		= 1005L
CONFIRM_	= 1006L
GET_		= 1007L
PUT_		= 1008L
NULL_		= 1000L

;******************************************************************************
;  Items on which functions are performed (for INTERNAL interface).
;  NOTE: These values must be different from those of the functions.
;******************************************************************************

CDF_			= 1L
CDF_NAME_		= 2L
CDF_ENCODING_		= 3L
CDF_DECODING_		= 4L
CDF_MAJORITY_		= 5L
CDF_FORMAT_		= 6L
CDF_COPYRIGHT_		= 7L
CDF_NUMrVARS_		= 8L
CDF_NUMzVARS_		= 9L
CDF_NUMATTRS_		= 10L
CDF_NUMgATTRS_		= 11L
CDF_NUMvATTRS_		= 12L
CDF_VERSION_		= 13L
CDF_RELEASE_		= 14L
CDF_INCREMENT_		= 15L
CDF_STATUS_		= 16L
CDF_READONLY_MODE_	= 17L
CDF_zMODE_		= 18L
CDF_NEGtoPOSfp0_MODE_	= 19L
LIB_COPYRIGHT_		= 20L
LIB_VERSION_		= 21L
LIB_RELEASE_		= 22L
LIB_INCREMENT_		= 23L
LIB_subINCREMENT_	= 24L
rVARs_NUMDIMS_		= 25L
rVARs_DIMSIZES_		= 26L
rVARs_MAXREC_		= 27L
rVARs_RECDATA_		= 28L
rVARs_RECNUMBER_	= 29L
rVARs_RECCOUNT_		= 30L
rVARs_RECINTERVAL_	= 31L
rVARs_DIMINDICES_	= 32L
rVARs_DIMCOUNTS_	= 33L
rVARs_DIMINTERVALS_	= 34L
rVAR_			= 35L
rVAR_NAME_		= 36L
rVAR_DATATYPE_		= 37L
rVAR_NUMELEMS_		= 38L
rVAR_RECVARY_		= 39L
rVAR_DIMVARYS_		= 40L
rVAR_NUMBER_		= 41L
rVAR_DATA_		= 42L
rVAR_HYPERDATA_		= 43L
rVAR_SEQDATA_		= 44L
rVAR_SEQPOS_		= 45L
rVAR_MAXREC_		= 46L
rVAR_MAXallocREC_	= 47L
rVAR_DATASPEC_		= 48L
rVAR_PADVALUE_		= 49L
rVAR_INITIALRECS_	= 50L
rVAR_BLOCKINGFACTOR_	= 51L
rVAR_nINDEXRECORDS_	= 52L
rVAR_nINDEXENTRIES_	= 53L
rVAR_EXISTENCE_		= 54L
zVARs_MAXREC_		= 55L
zVARs_RECDATA_		= 56L
zVAR_			= 57L
zVAR_NAME_		= 58L
zVAR_DATATYPE_		= 59L
zVAR_NUMELEMS_		= 60L
zVAR_NUMDIMS_		= 61L
zVAR_DIMSIZES_		= 62L
zVAR_RECVARY_		= 63L
zVAR_DIMVARYS_		= 64L
zVAR_NUMBER_		= 65L
zVAR_DATA_		= 66L
zVAR_HYPERDATA_		= 67L
zVAR_SEQDATA_		= 68L
zVAR_SEQPOS_		= 69L
zVAR_MAXREC_		= 70L
zVAR_MAXallocREC_	= 71L
zVAR_DATASPEC_		= 72L
zVAR_PADVALUE_		= 73L
zVAR_INITIALRECS_	= 74L
zVAR_BLOCKINGFACTOR_	= 75L
zVAR_nINDEXRECORDS_	= 76L
zVAR_nINDEXENTRIES_	= 77L
zVAR_EXISTENCE_		= 78L
zVAR_RECNUMBER_		= 79L
zVAR_RECCOUNT_		= 80L
zVAR_RECINTERVAL_	= 81L
zVAR_DIMINDICES_	= 82L
zVAR_DIMCOUNTS_		= 83L
zVAR_DIMINTERVALS_	= 84L
ATTR_			= 85L
ATTR_SCOPE_		= 86L
ATTR_NAME_		= 87L
ATTR_NUMBER_		= 88L
ATTR_MAXgENTRY_		= 89L
ATTR_NUMgENTRIES_	= 90L
ATTR_MAXrENTRY_		= 91L
ATTR_NUMrENTRIES_	= 92L
ATTR_MAXzENTRY_		= 93L
ATTR_NUMzENTRIES_	= 94L
ATTR_EXISTENCE_		= 95L
gENTRY_			= 96L
gENTRY_EXISTENCE_	= 97L
gENTRY_DATATYPE_	= 98L
gENTRY_NUMELEMS_	= 99L
gENTRY_DATASPEC_	= 100L
gENTRY_DATA_		= 101L
rENTRY_			= 102L
rENTRY_NAME_		= 103L
rENTRY_EXISTENCE_	= 104L
rENTRY_DATATYPE_	= 105L
rENTRY_NUMELEMS_	= 106L
rENTRY_DATASPEC_	= 107L
rENTRY_DATA_		= 108L
zENTRY_			= 109L
zENTRY_NAME_		= 110L
zENTRY_EXISTENCE_	= 111L
zENTRY_DATATYPE_	= 112L
zENTRY_NUMELEMS_	= 113L
zENTRY_DATASPEC_	= 114L
zENTRY_DATA_		= 115L
STATUS_TEXT_		= 116L
CDF_CACHESIZE_		= 117L
rVARs_CACHESIZE_	= 118L
zVARs_CACHESIZE_	= 119L
rVAR_CACHESIZE_		= 120L
zVAR_CACHESIZE_		= 121L
zVARs_RECNUMBER_	= 122L
rVAR_ALLOCATERECS_	= 123L
zVAR_ALLOCATERECS_	= 124L
DATATYPE_SIZE_		= 125L
CURgENTRY_EXISTENCE_	= 126L
CURrENTRY_EXISTENCE_	= 127L
CURzENTRY_EXISTENCE_	= 128L
CDF_INFO_		= 129L
CDF_COMPRESSION_	= 130L
zVAR_COMPRESSION_	= 131L
zVAR_SPARSERECORDS_	= 132L
zVAR_SPARSEARRAYS_	= 133L
zVAR_ALLOCATEBLOCK_	= 134L
zVAR_NUMRECS_		= 135L
zVAR_NUMallocRECS_	= 136L
rVAR_COMPRESSION_	= 137L
rVAR_SPARSERECORDS_	= 138L
rVAR_SPARSEARRAYS_	= 139L
rVAR_ALLOCATEBLOCK_	= 140L
rVAR_NUMRECS_		= 141L
rVAR_NUMallocRECS_	= 142L
rVAR_ALLOCATEDFROM_	= 143L
rVAR_ALLOCATEDTO_	= 144L
zVAR_ALLOCATEDFROM_	= 145L
zVAR_ALLOCATEDTO_	= 146L
zVAR_nINDEXLEVELS_	= 147L
rVAR_nINDEXLEVELS_	= 148L
CDF_SCRATCHDIR_		= 149L
rVAR_RESERVEPERCENT_	= 150L
zVAR_RESERVEPERCENT_	= 151L
rVAR_RECORDS_		= 152L
zVAR_RECORDS_		= 153L
STAGE_CACHESIZE_	= 154L
COMPRESS_CACHESIZE_	= 155L

;******************************************************************************
; Synonyms...
;******************************************************************************

rVAR_EXTENDRECS_	= rVAR_BLOCKINGFACTOR_
zVAR_EXTENDRECS_	= zVAR_BLOCKINGFACTOR_
