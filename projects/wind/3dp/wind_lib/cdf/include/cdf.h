/******************************************************************************
*
*  NSSDC/CDF				CDF Header file for C/C++ applications.
*
*  Version 3.5b, 9-Mar-97, Hughes STX.
*
*  Modification history:
*
*   V1.0  22-Jan-91, R Kulkarni	Original version (for CDF V2.0).
*		     J Love
*   V2.0   3-Jun-91, J Love     Modified for CDF V2.1 enhancements,
*				namely the INTERNAL interface and the
*				MULTI/SINGLE file option.  Added
*				macros to replace C i/f functions.
*   V2.1  20-Jun-91, J Love	Added function prototypes.
*   V2.2   8-Aug-91, J Love	Increment for CDF V2.1.2.  Use
*				'CDFlib'.  Renamed a few items.
*   V3.0  19-May-92, J Love	IBM PC & HP-UX port.  CDF V2.2.
*   V3.1  23-Sep-92, J Love	CDF V2.3 (shareable/NeXT/zVar).
*   V3.1a  5-Oct-92, J Love	CDF V2.3.0a (NeXT/encoding).
*   V3.1b  6-Oct-92, J Love	CDF V2.3.0b (CDFcompare).
*   V3.1c 27-Oct-92, J Love	CDF V2.3.0c (pad values).
*   V3.2  12-Jan-94, J Love	CDF V2.4.
*   V3.2a  4-Feb-94, J Love	DEC Alpha/OpenVMS port.
*   V3.2b 22-Feb-94, J Love	Spelling lesson.
*   V3.3   8-Dec-94, J Love	CDF V2.5.
*   V3.3a  3-Mar-95, J Love	Solaris 2.3 IDL i/f.
*   V3.4  28-Mar-95, J Love	POSIX.
*   V3.4a  8-May-95, J Love	ILLEGAL_EPOCH_VALUE.
*   V3.4b  9-Jun-95, J Love	EPOCH custom format.
*   V3.4c 20-Jul-95, J Love	CDFexport-related changes.
*   V3.5  12-Sep-96, J Love	CDF V2.6.
*   V3.5a 21-Feb-97, J Love	Removed RICE.
*   V3.5b  9-Mar-97, J Love	Windows NT for MS Visual C++ 4.0 on an IBM PC.
*
******************************************************************************/

#if !defined(CDFh_INCLUDEd__)
#define CDFh_INCLUDEd__

/******************************************************************************
* CDF defined types
******************************************************************************/

typedef void *CDFid;
typedef long CDFstatus;

/******************************************************************************
* Limits
******************************************************************************/

#define CDF_MIN_DIMS    0               /* Min number of dimensions a CDF
					   variable may have */ 
#define CDF_MAX_DIMS    10              /* Max number of dimensions a CDF
					   variable may have */

/******************************************************************************
* Lengths
******************************************************************************/

#define CDF_VAR_NAME_LEN        64
#define CDF_ATTR_NAME_LEN       64

#define CDF_COPYRIGHT_LEN       256
#define CDF_STATUSTEXT_LEN      80
#define CDF_PATHNAME_LEN        128

#define EPOCH_STRING_LEN	24
#define EPOCH1_STRING_LEN	16
#define EPOCH2_STRING_LEN	14
#define EPOCH3_STRING_LEN	24

#define EPOCHx_STRING_MAX	30
#define EPOCHx_FORMAT_MAX	60

/******************************************************************************
* Data types.
******************************************************************************/

#define CDF_INT1		1L
#define CDF_INT2		2L
#define CDF_INT4		4L
#define CDF_UINT1		11L
#define CDF_UINT2		12L
#define CDF_UINT4		14L
#define CDF_REAL4		21L
#define CDF_REAL8		22L
#define CDF_EPOCH		31L	/* Standard style. */
#define CDF_BYTE		41L     /* same as CDF_INT1 (signed) */
#define CDF_FLOAT		44L     /* same as CDF_REAL4 */
#define CDF_DOUBLE		45L     /* same as CDF_REAL8 */
#define CDF_CHAR		51L     /* a "string" data type */
#define CDF_UCHAR		52L     /* a "string" data type */

/******************************************************************************
* Encoding (for data only, everything else is network encoding).
******************************************************************************/

#define NETWORK_ENCODING        1L
#define SUN_ENCODING            2L
#define VAX_ENCODING            3L
#define DECSTATION_ENCODING     4L
#define SGi_ENCODING            5L
#define IBMPC_ENCODING          6L
#define IBMRS_ENCODING          7L
#define HOST_ENCODING           8L
#define MAC_ENCODING            9L
#define HP_ENCODING             11L
#define NeXT_ENCODING           12L
#define ALPHAOSF1_ENCODING      13L
#define ALPHAVMSd_ENCODING      14L
#define ALPHAVMSg_ENCODING      15L

/******************************************************************************
* Decodings.
******************************************************************************/

#define NETWORK_DECODING        NETWORK_ENCODING
#define SUN_DECODING            SUN_ENCODING
#define VAX_DECODING            VAX_ENCODING
#define DECSTATION_DECODING     DECSTATION_ENCODING
#define SGi_DECODING            SGi_ENCODING
#define IBMPC_DECODING          IBMPC_ENCODING
#define IBMRS_DECODING          IBMRS_ENCODING
#define HOST_DECODING           HOST_ENCODING
#define MAC_DECODING            MAC_ENCODING
#define HP_DECODING             HP_ENCODING
#define NeXT_DECODING           NeXT_ENCODING
#define ALPHAOSF1_DECODING      ALPHAOSF1_ENCODING
#define ALPHAVMSd_DECODING      ALPHAVMSd_ENCODING
#define ALPHAVMSg_DECODING      ALPHAVMSg_ENCODING

/******************************************************************************
* Variance flags
******************************************************************************/

#define VARY   (-1L)        /* TRUE record or dimension variance flag */
#define NOVARY 0L           /* FALSE record or dimension variance flag */

/******************************************************************************
* Majorities
******************************************************************************/

#define ROW_MAJOR       1L
#define COLUMN_MAJOR    2L

/******************************************************************************
* Formats.
******************************************************************************/

#define SINGLE_FILE     1L
#define MULTI_FILE      2L

/******************************************************************************
* Attribute scopes
******************************************************************************/

#define GLOBAL_SCOPE            1L
#define VARIABLE_SCOPE          2L

/******************************************************************************
* Readonly modes.
******************************************************************************/

#define READONLYon              (-1L)
#define READONLYoff             0L

/******************************************************************************
* zModes.
******************************************************************************/

#define zMODEoff                0L
#define zMODEon1                1L
#define zMODEon2                2L

/******************************************************************************
* Negative to positive floating point zero modes.
******************************************************************************/

#define NEGtoPOSfp0on           (-1L)
#define NEGtoPOSfp0off          0L


/******************************************************************************
* Compression/sparseness constants.
******************************************************************************/

#define CDF_MAX_PARMS			5
#define NO_COMPRESSION			0L
#define RLE_COMPRESSION			1L
#define HUFF_COMPRESSION		2L
#define AHUFF_COMPRESSION		3L
/**************************************************
* Compression `4' used to be RICE.  Do not reuse! *
**************************************************/
#define GZIP_COMPRESSION		5L

#define RLE_OF_ZEROs			0L
#define OPTIMAL_ENCODING_TREES		0L
#define NO_SPARSEARRAYS			0L
#define NO_SPARSERECORDS		0L
#define PAD_SPARSERECORDS		1L
#define PREV_SPARSERECORDS		2L

/*****************************************************************************
* Invalid/reserved constants.
*****************************************************************************/

#define RESERVED_CDFID      ((CDFid) NULL)      /* Indicates that a CDF hasn't
						   been selected yet. */
#define RESERVED_CDFSTATUS  ((CDFstatus) (-1))  /* Indicates that a CDFstatus
						   hasn't been selected yet. */

#define ILLEGAL_EPOCH_VALUE	(-1.0)

/******************************************************************************
* Status codes (CDFstatus)
*  - informatory codes are greater than CDF_OK
******************************************************************************/

#define VIRTUAL_RECORD_DATA             ((CDFstatus) 1001)
#define DID_NOT_COMPRESS		((CDFstatus) 1002)
#define VAR_ALREADY_CLOSED              ((CDFstatus) 1003)
#define SINGLE_FILE_FORMAT              ((CDFstatus) 1004)
#define NO_PADVALUE_SPECIFIED           ((CDFstatus) 1005)
#define NO_VARS_IN_CDF                  ((CDFstatus) 1006)
#define MULTI_FILE_FORMAT		((CDFstatus) 1007)
#define SOME_ALREADY_ALLOCATED		((CDFstatus) 1008)
#define PRECEEDING_RECORDS_ALLOCATED	((CDFstatus) 1009)

#define CDF_OK                          ((CDFstatus) 0)

#define ATTR_NAME_TRUNC                 ((CDFstatus) (-1001))
#define CDF_NAME_TRUNC                  ((CDFstatus) (-1002))
#define VAR_NAME_TRUNC                  ((CDFstatus) (-1003))
#define NEGATIVE_FP_ZERO		((CDFstatus) (-1004))
					/* -1005 unused. */
#define FORCED_PARAMETER		((CDFstatus) (-1006))
#define NA_FOR_VARIABLE			((CDFstatus) (-1007))

#define CDF_WARN                        ((CDFstatus) (-2000))

#define ATTR_EXISTS                     ((CDFstatus) (-2001))
#define BAD_CDF_ID                      ((CDFstatus) (-2002))
#define BAD_DATA_TYPE                   ((CDFstatus) (-2003))
#define BAD_DIM_SIZE                    ((CDFstatus) (-2004))
#define BAD_DIM_INDEX                   ((CDFstatus) (-2005))
#define BAD_ENCODING                    ((CDFstatus) (-2006))
#define BAD_MAJORITY                    ((CDFstatus) (-2007))
#define BAD_NUM_DIMS                    ((CDFstatus) (-2008))
#define BAD_REC_NUM                     ((CDFstatus) (-2009))
#define BAD_SCOPE                       ((CDFstatus) (-2010))
#define BAD_NUM_ELEMS                   ((CDFstatus) (-2011))
#define CDF_OPEN_ERROR                  ((CDFstatus) (-2012))
#define CDF_EXISTS                      ((CDFstatus) (-2013))
#define BAD_FORMAT                      ((CDFstatus) (-2014))
#define BAD_ALLOCATE_RECS		((CDFstatus) (-2015))
#define BAD_CDF_EXTENSION		((CDFstatus) (-2016))
#define NO_SUCH_ATTR                    ((CDFstatus) (-2017))
#define NO_SUCH_ENTRY                   ((CDFstatus) (-2018))
#define NO_SUCH_VAR                     ((CDFstatus) (-2019))
#define VAR_READ_ERROR                  ((CDFstatus) (-2020))
#define VAR_WRITE_ERROR                 ((CDFstatus) (-2021))
#define BAD_ARGUMENT                    ((CDFstatus) (-2022))
#define IBM_PC_OVERFLOW                 ((CDFstatus) (-2023))
#define TOO_MANY_VARS                   ((CDFstatus) (-2024))
#define VAR_EXISTS                      ((CDFstatus) (-2025))
#define BAD_MALLOC                      ((CDFstatus) (-2026))
#define NOT_A_CDF                       ((CDFstatus) (-2027))
#define CORRUPTED_V2_CDF                ((CDFstatus) (-2028))
#define VAR_OPEN_ERROR                  ((CDFstatus) (-2029))
#define BAD_INITIAL_RECS                ((CDFstatus) (-2030))
#define BAD_BLOCKING_FACTOR             ((CDFstatus) (-2031))
#define END_OF_VAR                      ((CDFstatus) (-2032))
					/* -2033 unused. */
#define BAD_CDFSTATUS                   ((CDFstatus) (-2034))
#define CDF_INTERNAL_ERROR		((CDFstatus) (-2035))
#define BAD_NUM_VARS			((CDFstatus) (-2036))
#define BAD_REC_COUNT                   ((CDFstatus) (-2037))
#define BAD_REC_INTERVAL                ((CDFstatus) (-2038))
#define BAD_DIM_COUNT                   ((CDFstatus) (-2039))
#define BAD_DIM_INTERVAL                ((CDFstatus) (-2040))
#define BAD_VAR_NUM                     ((CDFstatus) (-2041))
#define BAD_ATTR_NUM                    ((CDFstatus) (-2042))
#define BAD_ENTRY_NUM                   ((CDFstatus) (-2043))
#define BAD_ATTR_NAME                   ((CDFstatus) (-2044))
#define BAD_VAR_NAME                    ((CDFstatus) (-2045))
#define NO_ATTR_SELECTED                ((CDFstatus) (-2046))
#define NO_ENTRY_SELECTED               ((CDFstatus) (-2047))
#define NO_VAR_SELECTED                 ((CDFstatus) (-2048))
#define BAD_CDF_NAME                    ((CDFstatus) (-2049))
					/* -2050 unused. */
#define CANNOT_CHANGE                   ((CDFstatus) (-2051))
#define NO_STATUS_SELECTED              ((CDFstatus) (-2052))
#define NO_CDF_SELECTED                 ((CDFstatus) (-2053))
#define READ_ONLY_DISTRIBUTION          ((CDFstatus) (-2054))
#define CDF_CLOSE_ERROR                 ((CDFstatus) (-2055))
#define VAR_CLOSE_ERROR                 ((CDFstatus) (-2056))
					/* -2057 unused. */
#define BAD_FNC_OR_ITEM                 ((CDFstatus) (-2058))
					/* -2059 unused. */
#define ILLEGAL_ON_V1_CDF               ((CDFstatus) (-2060))
					/* -2061 unused. */
					/* -2062 unused. */
#define BAD_CACHE_SIZE                  ((CDFstatus) (-2063))
					/* -2064 unused. */
					/* -2065 unused. */
#define CDF_CREATE_ERROR                ((CDFstatus) (-2066))
#define NO_SUCH_CDF                     ((CDFstatus) (-2067))
#define VAR_CREATE_ERROR                ((CDFstatus) (-2068))
					/* -2069 unused. */
#define READ_ONLY_MODE                  ((CDFstatus) (-2070))
#define ILLEGAL_IN_zMODE                ((CDFstatus) (-2071))
#define BAD_zMODE                       ((CDFstatus) (-2072))
#define BAD_READONLY_MODE               ((CDFstatus) (-2073))
#define CDF_READ_ERROR                  ((CDFstatus) (-2074))
#define CDF_WRITE_ERROR                 ((CDFstatus) (-2075))
#define ILLEGAL_FOR_SCOPE               ((CDFstatus) (-2076))
#define NO_MORE_ACCESS                  ((CDFstatus) (-2077))
					/* -2078 unused. */
#define BAD_DECODING		        ((CDFstatus) (-2079))
					/* -2080 unused. */
#define BAD_NEGtoPOSfp0_MODE		((CDFstatus) (-2081))
#define UNSUPPORTED_OPERATION		((CDFstatus) (-2082))
					/* -2083 unused. */
					/* -2084 unused. */
					/* -2085 unused. */
#define NO_WRITE_ACCESS                 ((CDFstatus) (-2086))
#define NO_DELETE_ACCESS                ((CDFstatus) (-2087))
#define CDF_DELETE_ERROR		((CDFstatus) (-2088))
#define VAR_DELETE_ERROR		((CDFstatus) (-2089))
#define UNKNOWN_COMPRESSION		((CDFstatus) (-2090))
#define CANNOT_COMPRESS			((CDFstatus) (-2091))
#define DECOMPRESSION_ERROR		((CDFstatus) (-2092))
#define COMPRESSION_ERROR		((CDFstatus) (-2093))
					/* -2094 unused. */
					/* -2095 unused. */
#define EMPTY_COMPRESSED_CDF		((CDFstatus) (-2096))
#define BAD_COMPRESSION_PARM		((CDFstatus) (-2097))
#define UNKNOWN_SPARSENESS		((CDFstatus) (-2098))
#define CANNOT_SPARSERECORDS		((CDFstatus) (-2099))
#define CANNOT_SPARSEARRAYS		((CDFstatus) (-2100))
#define TOO_MANY_PARMS			((CDFstatus) (-2101))
#define NO_SUCH_RECORD			((CDFstatus) (-2102))
#define CANNOT_ALLOCATE_RECORDS		((CDFstatus) (-2103))
					/* -2104 unused. */
					/* -2105 unused. */
#define SCRATCH_DELETE_ERROR		((CDFstatus) (-2106))
#define SCRATCH_CREATE_ERROR		((CDFstatus) (-2107))
#define SCRATCH_READ_ERROR		((CDFstatus) (-2108))
#define SCRATCH_WRITE_ERROR		((CDFstatus) (-2109))
#define BAD_SPARSEARRAYS_PARM		((CDFstatus) (-2110))
#define BAD_SCRATCH_DIR			((CDFstatus) (-2111))

/******************************************************************************
* Functions (for INTERNAL interface).
* NOTE: These values must be different from those of the items.
******************************************************************************/

#define CREATE_			1001L
#define OPEN_			1002L
#define DELETE_			1003L
#define CLOSE_			1004L
#define SELECT_			1005L
#define CONFIRM_		1006L
#define GET_			1007L
#define PUT_			1008L

#define NULL_			1000L

/******************************************************************************
* Items on which functions are performed (for INTERNAL interface).
* NOTE: These values must be different from those of the functions.
******************************************************************************/

#define CDF_                    1L
#define CDF_NAME_               2L
#define CDF_ENCODING_           3L
#define CDF_DECODING_		4L
#define CDF_MAJORITY_           5L
#define CDF_FORMAT_             6L
#define CDF_COPYRIGHT_          7L
#define CDF_NUMrVARS_           8L
#define CDF_NUMzVARS_           9L
#define CDF_NUMATTRS_           10L
#define CDF_NUMgATTRS_          11L
#define CDF_NUMvATTRS_          12L
#define CDF_VERSION_            13L
#define CDF_RELEASE_            14L
#define CDF_INCREMENT_          15L
#define CDF_STATUS_             16L
#define CDF_READONLY_MODE_      17L
#define CDF_zMODE_              18L
#define CDF_NEGtoPOSfp0_MODE_	19L
#define LIB_COPYRIGHT_          20L
#define LIB_VERSION_            21L
#define LIB_RELEASE_            22L
#define LIB_INCREMENT_          23L
#define LIB_subINCREMENT_       24L
#define rVARs_NUMDIMS_          25L
#define rVARs_DIMSIZES_         26L
#define rVARs_MAXREC_           27L
#define rVARs_RECDATA_		28L
#define rVARs_RECNUMBER_        29L
#define rVARs_RECCOUNT_         30L
#define rVARs_RECINTERVAL_      31L
#define rVARs_DIMINDICES_       32L
#define rVARs_DIMCOUNTS_        33L
#define rVARs_DIMINTERVALS_     34L
#define rVAR_                   35L
#define rVAR_NAME_              36L
#define rVAR_DATATYPE_          37L
#define rVAR_NUMELEMS_          38L
#define rVAR_RECVARY_           39L
#define rVAR_DIMVARYS_          40L
#define rVAR_NUMBER_            41L
#define rVAR_DATA_              42L
#define rVAR_HYPERDATA_         43L
#define rVAR_SEQDATA_           44L
#define rVAR_SEQPOS_            45L
#define rVAR_MAXREC_            46L
#define rVAR_MAXallocREC_       47L
#define rVAR_DATASPEC_          48L
#define rVAR_PADVALUE_          49L
#define rVAR_INITIALRECS_       50L
#define rVAR_BLOCKINGFACTOR_    51L
#define rVAR_nINDEXRECORDS_	52L
#define rVAR_nINDEXENTRIES_	53L
#define rVAR_EXISTENCE_		54L
#define zVARs_MAXREC_		55L
#define zVARs_RECDATA_		56L
#define zVAR_                   57L
#define zVAR_NAME_              58L
#define zVAR_DATATYPE_          59L
#define zVAR_NUMELEMS_          60L
#define zVAR_NUMDIMS_           61L
#define zVAR_DIMSIZES_          62L
#define zVAR_RECVARY_           63L
#define zVAR_DIMVARYS_          64L
#define zVAR_NUMBER_            65L
#define zVAR_DATA_              66L
#define zVAR_HYPERDATA_         67L
#define zVAR_SEQDATA_           68L
#define zVAR_SEQPOS_            69L
#define zVAR_MAXREC_            70L
#define zVAR_MAXallocREC_       71L
#define zVAR_DATASPEC_          72L
#define zVAR_PADVALUE_          73L
#define zVAR_INITIALRECS_       74L
#define zVAR_BLOCKINGFACTOR_    75L
#define zVAR_nINDEXRECORDS_	76L
#define zVAR_nINDEXENTRIES_	77L
#define zVAR_EXISTENCE_		78L
#define zVAR_RECNUMBER_         79L
#define zVAR_RECCOUNT_          80L
#define zVAR_RECINTERVAL_       81L
#define zVAR_DIMINDICES_        82L
#define zVAR_DIMCOUNTS_         83L
#define zVAR_DIMINTERVALS_      84L
#define ATTR_                   85L
#define ATTR_SCOPE_             86L
#define ATTR_NAME_              87L
#define ATTR_NUMBER_            88L
#define ATTR_MAXgENTRY_         89L
#define ATTR_NUMgENTRIES_       90L
#define ATTR_MAXrENTRY_         91L
#define ATTR_NUMrENTRIES_       92L
#define ATTR_MAXzENTRY_         93L
#define ATTR_NUMzENTRIES_       94L
#define ATTR_EXISTENCE_		95L
#define gENTRY_                 96L
#define gENTRY_EXISTENCE_       97L
#define gENTRY_DATATYPE_        98L
#define gENTRY_NUMELEMS_        99L
#define gENTRY_DATASPEC_        100L
#define gENTRY_DATA_            101L
#define rENTRY_                 102L
#define rENTRY_NAME_		103L
#define rENTRY_EXISTENCE_       104L
#define rENTRY_DATATYPE_        105L
#define rENTRY_NUMELEMS_        106L
#define rENTRY_DATASPEC_        107L
#define rENTRY_DATA_            108L
#define zENTRY_                 109L
#define zENTRY_NAME_		110L
#define zENTRY_EXISTENCE_       111L
#define zENTRY_DATATYPE_        112L
#define zENTRY_NUMELEMS_        113L
#define zENTRY_DATASPEC_        114L
#define zENTRY_DATA_            115L
#define STATUS_TEXT_            116L
#define CDF_CACHESIZE_		117L
#define rVARs_CACHESIZE_	118L
#define zVARs_CACHESIZE_	119L
#define rVAR_CACHESIZE_		120L
#define zVAR_CACHESIZE_		121L
#define zVARs_RECNUMBER_	122L
#define rVAR_ALLOCATERECS_	123L
#define zVAR_ALLOCATERECS_	124L
#define DATATYPE_SIZE_		125L
#define CURgENTRY_EXISTENCE_	126L
#define CURrENTRY_EXISTENCE_	127L
#define CURzENTRY_EXISTENCE_	128L
#define CDF_INFO_		129L
#define CDF_COMPRESSION_	130L
#define zVAR_COMPRESSION_	131L
#define zVAR_SPARSERECORDS_	132L
#define zVAR_SPARSEARRAYS_	133L
#define zVAR_ALLOCATEBLOCK_	134L
#define zVAR_NUMRECS_		135L
#define zVAR_NUMallocRECS_	136L
#define rVAR_COMPRESSION_	137L
#define rVAR_SPARSERECORDS_	138L
#define rVAR_SPARSEARRAYS_	139L
#define rVAR_ALLOCATEBLOCK_	140L
#define rVAR_NUMRECS_		141L
#define rVAR_NUMallocRECS_	142L
#define rVAR_ALLOCATEDFROM_	143L
#define rVAR_ALLOCATEDTO_	144L
#define zVAR_ALLOCATEDFROM_	145L
#define zVAR_ALLOCATEDTO_	146L
#define zVAR_nINDEXLEVELS_	147L
#define rVAR_nINDEXLEVELS_	148L
#define CDF_SCRATCHDIR_		149L
#define rVAR_RESERVEPERCENT_	150L
#define zVAR_RESERVEPERCENT_	151L
#define rVAR_RECORDS_		152L
#define zVAR_RECORDS_		153L
#define STAGE_CACHESIZE_	154L
#define COMPRESS_CACHESIZE_	155L

#define CDFwithSTATS_		200L	/* For CDF internal use only! */
#define CDF_ACCESS_		201L	/* For CDF internal use only! */

/******************************************************************************
* C interface macros.
******************************************************************************/

#define CDFcreate(CDFname,numDims,dimSizes,encoding,majority,id) \
CDFlib (CREATE_, CDF_, CDFname, numDims, dimSizes, id, \
	PUT_, CDF_ENCODING_, encoding, \
	      CDF_MAJORITY_, majority, \
	NULL_)

#define CDFopen(CDFname,id) \
CDFlib (OPEN_, CDF_, CDFname, id, \
	NULL_)

#define CDFdoc(id,version,release,text) \
CDFlib (SELECT_, CDF_, id, \
	GET_, CDF_VERSION_, version, \
	      CDF_RELEASE_, release, \
	      CDF_COPYRIGHT_, text, \
	NULL_)

#define CDFinquire(id,numDims,dimSizes,encoding,majority,maxRec,nVars,nAttrs) \
CDFlib (SELECT_, CDF_, id, \
	GET_, rVARs_NUMDIMS_, numDims, \
	      rVARs_DIMSIZES_, dimSizes, \
	      CDF_ENCODING_, encoding, \
	      CDF_MAJORITY_, majority, \
	      rVARs_MAXREC_, maxRec, \
	      CDF_NUMrVARS_, nVars, \
	      CDF_NUMATTRS_, nAttrs, \
	NULL_)

#define CDFclose(id) \
CDFlib (SELECT_, CDF_, id, \
	CLOSE_, CDF_, \
	NULL_)

#define CDFdelete(id) \
CDFlib (SELECT_, CDF_, id, \
	DELETE_, CDF_, \
	NULL_)

#define CDFerror(stat, text) \
CDFlib (SELECT_, CDF_STATUS_, stat, \
	GET_, STATUS_TEXT_, text, \
	NULL_)

#define CDFattrCreate(id,attrName,attrScope,attrNum) \
CDFlib (SELECT_, CDF_, id, \
	CREATE_, ATTR_, attrName, attrScope, attrNum, \
	NULL_)

#define CDFattrRename(id,attrNum,attrName) \
CDFlib (SELECT_, CDF_, id, \
		 ATTR_, attrNum, \
	PUT_, ATTR_NAME_, attrName, \
	NULL_)

#define CDFvarCreate(id,varName,dataType,numElements,recVary,dimVarys,varNum) \
CDFlib (SELECT_, CDF_, id, \
	CREATE_, rVAR_, varName, dataType, numElements, \
			recVary, dimVarys, varNum, \
	NULL_)

#define CDFvarRename(id,varNum,varName) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varNum, \
	PUT_, rVAR_NAME_, varName, \
	NULL_)

#define CDFvarInquire(id,varN,varName,dataType,numElements,recVary,dimVarys) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varN, \
	GET_, rVAR_NAME_, varName, \
	      rVAR_DATATYPE_, dataType, \
	      rVAR_NUMELEMS_, numElements, \
	      rVAR_RECVARY_, recVary, \
	      rVAR_DIMVARYS_, dimVarys, \
	NULL_)

#define CDFvarGet(id,varNum,recNum,indices,value) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varNum, \
		 rVARs_RECNUMBER_, recNum, \
		 rVARs_DIMINDICES_, indices, \
	GET_, rVAR_DATA_, value, \
	NULL_)

#define CDFvarPut(id,varNum,recNum,indices,value) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varNum, \
		 rVARs_RECNUMBER_, recNum, \
		 rVARs_DIMINDICES_, indices, \
	PUT_, rVAR_DATA_, value, \
	NULL_)

#define CDFvarHyperGet(id,varN,recS,recC,recI,indices,counts,intervals,buff) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varN, \
		 rVARs_RECNUMBER_, recS, \
		 rVARs_RECCOUNT_, recC, \
		 rVARs_RECINTERVAL_, recI, \
		 rVARs_DIMINDICES_, indices, \
		 rVARs_DIMCOUNTS_, counts, \
		 rVARs_DIMINTERVALS_, intervals, \
	GET_, rVAR_HYPERDATA_, buff, \
	NULL_)

#define CDFvarHyperPut(id,varN,recS,recC,recI,indices,counts,intervals,buff) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varN, \
		 rVARs_RECNUMBER_, recS, \
		 rVARs_RECCOUNT_, recC, \
		 rVARs_RECINTERVAL_, recI, \
		 rVARs_DIMINDICES_, indices, \
		 rVARs_DIMCOUNTS_, counts, \
		 rVARs_DIMINTERVALS_, intervals, \
	PUT_, rVAR_HYPERDATA_, buff, \
	NULL_)

#define CDFvarClose(id,varNum) \
CDFlib (SELECT_, CDF_, id, \
		 rVAR_, varNum, \
	CLOSE_, rVAR_, \
	NULL_)

/******************************************************************************
* Function prototypes.
*     It is assumed that `__cplusplus' is defined for ALL C++ compilers.  If
* ANSI function prototypes are not desired (for whatever reason), define
* noPROTOs on the compile command line.  Otherwise, ANSI function prototypes
* will be used where appropriate.
******************************************************************************/

#if !defined(noPROTOs)
#  if defined(__STDC__)
#    define PROTOs_
#  else
#    if defined(vms)
#      define PROTOs_
#    endif
#    if defined(__MSDOS__) || defined(MSDOS)
#      define PROTOs_
#    endif
#    if defined(macintosh) || defined(THINK_C)
#      define PROTOs_
#    endif
#    if defined(WIN32)
#      define PROTOs_
#    endif
#  endif
#endif

#if defined(PROTOs_)
#  define PROTOARGs(args) args
#else
#  define PROTOARGs(args) ()
#endif

#if defined(BUILDINGforIDL)
#  define STATICforIDL static
#  define VISIBLE_PREFIX static
#else
#  if defined(WIN32) && defined(BUILDINGforDLL)
#    if defined(LIBCDF_SOURCE_)
#      define VISIBLE_PREFIX _declspec(dllexport)
#    else
#      define VISIBLE_PREFIX _declspec(dllimport)
#    endif
#  else
#    define VISIBLE_PREFIX \

#  endif
#  define STATICforIDL \

#endif

#if defined(__cplusplus)
extern "C" {
#endif

#if defined(BUILDINGforIDL)
/* Isn't a prototype needed? */
#else
VISIBLE_PREFIX CDFstatus CDFlib PROTOARGs((long op1, ...));
#endif

VISIBLE_PREFIX CDFstatus CDFattrInquire PROTOARGs((
  CDFid id, long attrNum, char *attrName, long *attrScope, long *maxEntry
));
VISIBLE_PREFIX CDFstatus CDFattrEntryInquire PROTOARGs((
  CDFid id, long attrNum, long entryNum, long *dataType, long *numElems
));
VISIBLE_PREFIX CDFstatus CDFattrPut PROTOARGs((
  CDFid id, long attrNum, long entryNum, long dataType, long numElems,
  void *value
));
VISIBLE_PREFIX CDFstatus CDFattrGet PROTOARGs((
  CDFid id, long attrNum, long entryNum, void *value
));
VISIBLE_PREFIX long CDFattrNum PROTOARGs((CDFid id, char *attrName));
VISIBLE_PREFIX long CDFvarNum PROTOARGs((CDFid id, char *varName));
VISIBLE_PREFIX void EPOCHbreakdown PROTOARGs((
  double epoch, long *year, long *month, long *day, long *hour, long *minute,
  long *second, long *msec
));
VISIBLE_PREFIX double computeEPOCH PROTOARGs((
  long year, long month, long day, long hour, long minute, long second,
  long msec
));
VISIBLE_PREFIX double parseEPOCH PROTOARGs((char *inString));
VISIBLE_PREFIX double parseEPOCH1 PROTOARGs((char *inString));
VISIBLE_PREFIX double parseEPOCH2 PROTOARGs((char *inString));
VISIBLE_PREFIX double parseEPOCH3 PROTOARGs((char *inString));
VISIBLE_PREFIX void encodeEPOCH PROTOARGs((
  double epoch, char epString[EPOCH_STRING_LEN+1]
));
VISIBLE_PREFIX void encodeEPOCH1 PROTOARGs((
  double epoch, char epString[EPOCH1_STRING_LEN+1]
));
VISIBLE_PREFIX void encodeEPOCH2 PROTOARGs((
  double epoch, char epString[EPOCH2_STRING_LEN+1]
));
VISIBLE_PREFIX void encodeEPOCH3 PROTOARGs((
  double epoch, char epString[EPOCH3_STRING_LEN+1]
));
VISIBLE_PREFIX void encodeEPOCHx PROTOARGs((
  double epoch, char format[EPOCHx_FORMAT_MAX], char encoded[EPOCHx_STRING_MAX]
));

#if defined(__cplusplus)
}
#endif

/******************************************************************************
* Synonyms for compatibility with older releases.
******************************************************************************/

#define CDF_DOCUMENT_LEN	        CDF_COPYRIGHT_LEN
#define CDF_ERRTEXT_LEN         	CDF_STATUSTEXT_LEN
#define CDF_NUMDIMS_            	rVARs_NUMDIMS_
#define CDF_DIMSIZES_           	rVARs_DIMSIZES_
#define CDF_MAXREC_             	rVARs_MAXREC_
#define CDF_RECNUMBER_          	rVARs_RECNUMBER_
#define CDF_RECCOUNT_           	rVARs_RECCOUNT_
#define CDF_RECINTERVAL_        	rVARs_RECINTERVAL_
#define CDF_DIMINDICES_         	rVARs_DIMINDICES_
#define CDF_DIMCOUNTS_          	rVARs_DIMCOUNTS_
#define CDF_DIMINTERVALS_       	rVARs_DIMINTERVALS_
#define CDF_NUMVARS_            	CDF_NUMrVARS_
#define VAR_                    	rVAR_
#define VAR_NAME_               	rVAR_NAME_
#define VAR_DATATYPE_           	rVAR_DATATYPE_
#define VAR_NUMELEMS_           	rVAR_NUMELEMS_
#define VAR_RECVARY_            	rVAR_RECVARY_
#define VAR_DIMVARYS_           	rVAR_DIMVARYS_
#define VAR_NUMBER_             	rVAR_NUMBER_
#define VAR_DATA_               	rVAR_DATA_
#define VAR_HYPERDATA_          	rVAR_HYPERDATA_
#define VAR_SEQDATA_            	rVAR_SEQDATA_
#define VAR_SEQPOS_             	rVAR_SEQPOS_
#define VAR_MAXREC_             	rVAR_MAXREC_
#define VAR_DATASPEC_           	rVAR_DATASPEC_
#define VAR_FILLVALUE_          	rVAR_PADVALUE_
#define VAR_INITIALRECS_        	rVAR_INITIALRECS_
#define VAR_EXTENDRECS_         	rVAR_BLOCKINGFACTOR_
#define ATTR_MAXENTRY_          	ATTR_MAXrENTRY_
#define ATTR_NUMENTRIES_        	ATTR_NUMrENTRIES_
#define ENTRY_                  	rENTRY_
#define ENTRY_DATATYPE_         	rENTRY_DATATYPE_
#define ENTRY_NUMELEMS_         	rENTRY_NUMELEMS_
#define ENTRY_DATA_             	rENTRY_DATA_
#define MIPSEL_ENCODING			DECSTATION_ENCODING
#define MIPSEB_ENCODING			SGi_ENCODING
#define rVAR_EXISTANCE_			rVAR_EXISTENCE_
#define zVAR_EXISTANCE_			zVAR_EXISTENCE_
#define ATTR_EXISTANCE_			ATTR_EXISTENCE_
#define gENTRY_EXISTANCE_		gENTRY_EXISTENCE_
#define rENTRY_EXISTANCE_		rENTRY_EXISTENCE_
#define zENTRY_EXISTANCE_		zENTRY_EXISTENCE_
#define GLOBAL_SCOPE_ASSUMED		GLOBAL_SCOPE
#define VARIABLE_SCOPE_ASSUMED		VARIABLE_SCOPE
#define BAD_EXTEND_RECS			BAD_BLOCKING_FACTOR
#define rVAR_EXTENDRECS_		rVAR_BLOCKINGFACTOR_
#define zVAR_EXTENDRECS_		zVAR_BLOCKINGFACTOR_
#define COL_MAJOR			COLUMN_MAJOR

/*****************************************************************************/

#endif
