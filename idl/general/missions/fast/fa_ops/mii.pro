;------------------------------------------------------------------------------
;
;  NSSDC/CDF					MII (Map Internal Interface).
;
;  Version 1.3a, 21-Feb-97, Hughes STX.
;
;  Modification history:
;
;   V1.0   4-Jan-94, J Love	Original version.
;   V1.1a 22-Feb-94, J Love	Spelling lesson.
;   V1.2   8-Dec-94, J Love	CDF V2.5.
;   V1.2a 26-Jun-95, J Love	IDL 4.0.
;   V1.3  21-Aug-96, J Love	CDF V2.6.
;   V1.3a 21-Feb-97, J Love	Removed RICE.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; MII.
;------------------------------------------------------------------------------

;+
; NAME:
;       MII
;
; PURPOSE:
;       MII (Map Internal Interface) is used to map (look up) the numeric value
;       associated with the (IDL) variables defined in `cdf2.pro'.  MII would
;       be used in those cases where it is not possible to include `cdf2.pro'
;       (by executing `@cdf2.pro' at the IDL command line) because of the
;       limit on the number of local variable which may exist in a function
;       or procedure (as imposed by IDL).
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       value = MII (name)
;
; INPUTS:
;       name:           STRING.  Symbolic name of the Internal Interface
;                       parameter whose value is desired.
;
; OUTPUTS:
;       value:          LONG.  The associated value.
;
; EXAMPLE:
;       IDL> format = MCP('SINGLE_FILE')
;       IDL> status = CDFlib (MII('OPEN_'), MII('CDF_'), 'rain1', id, $
;       IDL>                  MII('GET_'), MII('CDF_FORMAT_'), format, $
;       IDL>                  MII('NULL_'))
;       IDL> if (status lt MCP('CDF_WARN')) print, 'CDFlib failed.'
;
;       Note that `MCP' is used to map the CDF parameters in `cdf.pro'.
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       23-Aug-93        Original version.
;       26-Jun-95        IDL 4.0.
;       21-Aug-96        CDF V2.6.
;-

function MII, symbol
@cdf2.pro
;------------------------------------------------------------------------------
; Check for status codes...
;------------------------------------------------------------------------------
if (symbol eq 'CREATE_') then return, CREATE_
if (symbol eq 'OPEN_') then return, OPEN_
if (symbol eq 'DELETE_') then return, DELETE_
if (symbol eq 'CLOSE_') then return, CLOSE_
if (symbol eq 'SELECT_') then return, SELECT_
if (symbol eq 'CONFIRM_') then return, CONFIRM_
if (symbol eq 'GET_') then return, GET_
if (symbol eq 'PUT_') then return, PUT_
if (symbol eq 'NULL_') then return, NULL_
if (symbol eq 'CDF_') then return, CDF_
if (symbol eq 'CDF_NAME_') then return, CDF_NAME_
if (symbol eq 'CDF_ENCODING_') then return, CDF_ENCODING_
if (symbol eq 'CDF_DECODING_') then return, CDF_DECODING_
if (symbol eq 'CDF_MAJORITY_') then return, CDF_MAJORITY_
if (symbol eq 'CDF_FORMAT_') then return, CDF_FORMAT_
if (symbol eq 'CDF_COPYRIGHT_') then return, CDF_COPYRIGHT_
if (symbol eq 'CDF_NUMrVARS_') then return, CDF_NUMrVARS_
if (symbol eq 'CDF_NUMzVARS_') then return, CDF_NUMzVARS_
if (symbol eq 'CDF_NUMATTRS_') then return, CDF_NUMATTRS_
if (symbol eq 'CDF_NUMgATTRS_') then return, CDF_NUMgATTRS_
if (symbol eq 'CDF_NUMvATTRS_') then return, CDF_NUMvATTRS_
if (symbol eq 'CDF_VERSION_') then return, CDF_VERSION_
if (symbol eq 'CDF_RELEASE_') then return, CDF_RELEASE_
if (symbol eq 'CDF_INCREMENT_') then return, CDF_INCREMENT_
if (symbol eq 'CDF_STATUS_') then return, CDF_STATUS_
if (symbol eq 'CDF_READONLY_MODE_') then return, CDF_READONLY_MODE_
if (symbol eq 'CDF_zMODE_') then return, CDF_zMODE_
if (symbol eq 'CDF_NEGtoPOSfp0_MODE_') then return, CDF_NEGtoPOSfp0_MODE_
if (symbol eq 'LIB_COPYRIGHT_') then return, LIB_COPYRIGHT_
if (symbol eq 'LIB_VERSION_') then return, LIB_VERSION_
if (symbol eq 'LIB_RELEASE_') then return, LIB_RELEASE_
if (symbol eq 'LIB_INCREMENT_') then return, LIB_INCREMENT_
if (symbol eq 'LIB_subINCREMENT_') then return, LIB_subINCREMENT_
if (symbol eq 'rVARs_NUMDIMS_') then return, rVARs_NUMDIMS_
if (symbol eq 'rVARs_DIMSIZES_') then return, rVARs_DIMSIZES_
if (symbol eq 'rVARs_MAXREC_') then return, rVARs_MAXREC_
if (symbol eq 'rVARs_RECDATA_') then return, rVARs_RECDATA_
if (symbol eq 'rVARs_RECNUMBER_') then return, rVARs_RECNUMBER_
if (symbol eq 'rVARs_RECCOUNT_') then return, rVARs_RECCOUNT_
if (symbol eq 'rVARs_RECINTERVAL_') then return, rVARs_RECINTERVAL_
if (symbol eq 'rVARs_DIMINDICES_') then return, rVARs_DIMINDICES_
if (symbol eq 'rVARs_DIMCOUNTS_') then return, rVARs_DIMCOUNTS_
if (symbol eq 'rVARs_DIMINTERVALS_') then return, rVARs_DIMINTERVALS_
if (symbol eq 'rVAR_') then return, rVAR_
if (symbol eq 'rVAR_NAME_') then return, rVAR_NAME_
if (symbol eq 'rVAR_DATATYPE_') then return, rVAR_DATATYPE_
if (symbol eq 'rVAR_NUMELEMS_') then return, rVAR_NUMELEMS_
if (symbol eq 'rVAR_RECVARY_') then return, rVAR_RECVARY_
if (symbol eq 'rVAR_DIMVARYS_') then return, rVAR_DIMVARYS_
if (symbol eq 'rVAR_NUMBER_') then return, rVAR_NUMBER_
if (symbol eq 'rVAR_DATA_') then return, rVAR_DATA_
if (symbol eq 'rVAR_HYPERDATA_') then return, rVAR_HYPERDATA_
if (symbol eq 'rVAR_SEQDATA_') then return, rVAR_SEQDATA_
if (symbol eq 'rVAR_SEQPOS_') then return, rVAR_SEQPOS_
if (symbol eq 'rVAR_MAXREC_') then return, rVAR_MAXREC_
if (symbol eq 'rVAR_MAXallocREC_') then return, rVAR_MAXallocREC_
if (symbol eq 'rVAR_DATASPEC_') then return, rVAR_DATASPEC_
if (symbol eq 'rVAR_PADVALUE_') then return, rVAR_PADVALUE_
if (symbol eq 'rVAR_INITIALRECS_') then return, rVAR_INITIALRECS_
if (symbol eq 'rVAR_BLOCKINGFACTOR_') then return, rVAR_BLOCKINGFACTOR_
if (symbol eq 'rVAR_nINDEXRECORDS_') then return, rVAR_nINDEXRECORDS_
if (symbol eq 'rVAR_nINDEXENTRIES_') then return, rVAR_nINDEXENTRIES_
if (symbol eq 'rVAR_EXISTENCE_') then return, rVAR_EXISTENCE_
if (symbol eq 'zVARs_MAXREC_') then return, zVARs_MAXREC_
if (symbol eq 'zVARs_RECDATA_') then return, zVARs_RECDATA_
if (symbol eq 'zVAR_') then return, zVAR_
if (symbol eq 'zVAR_NAME_') then return, zVAR_NAME_
if (symbol eq 'zVAR_DATATYPE_') then return, zVAR_DATATYPE_
if (symbol eq 'zVAR_NUMELEMS_') then return, zVAR_NUMELEMS_
if (symbol eq 'zVAR_NUMDIMS_') then return, zVAR_NUMDIMS_
if (symbol eq 'zVAR_DIMSIZES_') then return, zVAR_DIMSIZES_
if (symbol eq 'zVAR_RECVARY_') then return, zVAR_RECVARY_
if (symbol eq 'zVAR_DIMVARYS_') then return, zVAR_DIMVARYS_
if (symbol eq 'zVAR_NUMBER_') then return, zVAR_NUMBER_
if (symbol eq 'zVAR_DATA_') then return, zVAR_DATA_
if (symbol eq 'zVAR_HYPERDATA_') then return, zVAR_HYPERDATA_
if (symbol eq 'zVAR_SEQDATA_') then return, zVAR_SEQDATA_
if (symbol eq 'zVAR_SEQPOS_') then return, zVAR_SEQPOS_
if (symbol eq 'zVAR_MAXREC_') then return, zVAR_MAXREC_
if (symbol eq 'zVAR_MAXallocREC_') then return, zVAR_MAXallocREC_
if (symbol eq 'zVAR_DATASPEC_') then return, zVAR_DATASPEC_
if (symbol eq 'zVAR_PADVALUE_') then return, zVAR_PADVALUE_
if (symbol eq 'zVAR_INITIALRECS_') then return, zVAR_INITIALRECS_
if (symbol eq 'zVAR_BLOCKINGFACTOR_') then return, zVAR_BLOCKINGFACTOR_
if (symbol eq 'zVAR_nINDEXRECORDS_') then return, zVAR_nINDEXRECORDS_
if (symbol eq 'zVAR_nINDEXENTRIES_') then return, zVAR_nINDEXENTRIES_
if (symbol eq 'zVAR_EXISTENCE_') then return, zVAR_EXISTENCE_
if (symbol eq 'zVAR_RECNUMBER_') then return, zVAR_RECNUMBER_
if (symbol eq 'zVAR_RECCOUNT_') then return, zVAR_RECCOUNT_
if (symbol eq 'zVAR_RECINTERVAL_') then return, zVAR_RECINTERVAL_
if (symbol eq 'zVAR_DIMINDICES_') then return, zVAR_DIMINDICES_
if (symbol eq 'zVAR_DIMCOUNTS_') then return, zVAR_DIMCOUNTS_
if (symbol eq 'zVAR_DIMINTERVALS_') then return, zVAR_DIMINTERVALS_
if (symbol eq 'ATTR_') then return, ATTR_
if (symbol eq 'ATTR_SCOPE_') then return, ATTR_SCOPE_
if (symbol eq 'ATTR_NAME_') then return, ATTR_NAME_
if (symbol eq 'ATTR_NUMBER_') then return, ATTR_NUMBER_
if (symbol eq 'ATTR_MAXgENTRY_') then return, ATTR_MAXgENTRY_
if (symbol eq 'ATTR_NUMgENTRIES_') then return, ATTR_NUMgENTRIES_
if (symbol eq 'ATTR_MAXrENTRY_') then return, ATTR_MAXrENTRY_
if (symbol eq 'ATTR_NUMrENTRIES_') then return, ATTR_NUMrENTRIES_
if (symbol eq 'ATTR_MAXzENTRY_') then return, ATTR_MAXzENTRY_
if (symbol eq 'ATTR_NUMzENTRIES_') then return, ATTR_NUMzENTRIES_
if (symbol eq 'ATTR_EXISTENCE_') then return, ATTR_EXISTENCE_
if (symbol eq 'gENTRY_') then return, gENTRY_
if (symbol eq 'gENTRY_EXISTENCE_') then return, gENTRY_EXISTENCE_
if (symbol eq 'gENTRY_DATATYPE_') then return, gENTRY_DATATYPE_
if (symbol eq 'gENTRY_NUMELEMS_') then return, gENTRY_NUMELEMS_
if (symbol eq 'gENTRY_DATASPEC_') then return, gENTRY_DATASPEC_
if (symbol eq 'gENTRY_DATA_') then return, gENTRY_DATA_
if (symbol eq 'rENTRY_') then return, rENTRY_
if (symbol eq 'rENTRY_NAME_') then return, rENTRY_NAME_
if (symbol eq 'rENTRY_EXISTENCE_') then return, rENTRY_EXISTENCE_
if (symbol eq 'rENTRY_DATATYPE_') then return, rENTRY_DATATYPE_
if (symbol eq 'rENTRY_NUMELEMS_') then return, rENTRY_NUMELEMS_
if (symbol eq 'rENTRY_DATASPEC_') then return, rENTRY_DATASPEC_
if (symbol eq 'rENTRY_DATA_') then return, rENTRY_DATA_
if (symbol eq 'zENTRY_') then return, zENTRY_
if (symbol eq 'zENTRY_NAME_') then return, zENTRY_NAME_
if (symbol eq 'zENTRY_EXISTENCE_') then return, zENTRY_EXISTENCE_
if (symbol eq 'zENTRY_DATATYPE_') then return, zENTRY_DATATYPE_
if (symbol eq 'zENTRY_NUMELEMS_') then return, zENTRY_NUMELEMS_
if (symbol eq 'zENTRY_DATASPEC_') then return, zENTRY_DATASPEC_
if (symbol eq 'zENTRY_DATA_') then return, zENTRY_DATA_
if (symbol eq 'STATUS_TEXT_') then return, STATUS_TEXT_
if (symbol eq 'CDF_CACHESIZE_') then return, CDF_CACHESIZE_
if (symbol eq 'rVARs_CACHESIZE_') then return, rVARs_CACHESIZE_
if (symbol eq 'zVARs_CACHESIZE_') then return, zVARs_CACHESIZE_
if (symbol eq 'rVAR_CACHESIZE_') then return, rVAR_CACHESIZE_
if (symbol eq 'zVAR_CACHESIZE_') then return, zVAR_CACHESIZE_
if (symbol eq 'zVARs_RECNUMBER_') then return, zVARs_RECNUMBER_
if (symbol eq 'rVAR_ALLOCATERECS_') then return, rVAR_ALLOCATERECS_
if (symbol eq 'zVAR_ALLOCATERECS_') then return, zVAR_ALLOCATERECS_
if (symbol eq 'DATATYPE_SIZE_') then return, DATATYPE_SIZE_
if (symbol eq 'CURgENTRY_EXISTENCE_') then return, CURgENTRY_EXISTENCE_
if (symbol eq 'CURrENTRY_EXISTENCE_') then return, CURrENTRY_EXISTENCE_
if (symbol eq 'CURzENTRY_EXISTENCE_') then return, CURzENTRY_EXISTENCE_
if (symbol eq 'CDF_INFO_') then return, CDF_INFO_
if (symbol eq 'CDF_COMPRESSION_') then return, CDF_COMPRESSION_
if (symbol eq 'zVAR_COMPRESSION_') then return, zVAR_COMPRESSION_
if (symbol eq 'zVAR_SPARSERECORDS_') then return, zVAR_SPARSERECORDS_
if (symbol eq 'zVAR_SPARSEARRAYS_') then return, zVAR_SPARSEARRAYS_
if (symbol eq 'zVAR_ALLOCATEBLOCK_') then return, zVAR_ALLOCATEBLOCK_
if (symbol eq 'zVAR_NUMRECS_') then return, zVAR_NUMRECS_
if (symbol eq 'zVAR_NUMallocRECS_') then return, zVAR_NUMallocRECS_
if (symbol eq 'rVAR_COMPRESSION_') then return, rVAR_COMPRESSION_
if (symbol eq 'rVAR_SPARSERECORDS_') then return, rVAR_SPARSERECORDS_
if (symbol eq 'rVAR_SPARSEARRAYS_') then return, rVAR_SPARSEARRAYS_
if (symbol eq 'rVAR_ALLOCATEBLOCK_') then return, rVAR_ALLOCATEBLOCK_
if (symbol eq 'rVAR_NUMRECS_') then return, rVAR_NUMRECS_
if (symbol eq 'rVAR_NUMallocRECS_') then return, rVAR_NUMallocRECS_
if (symbol eq 'rVAR_ALLOCATEDFROM_') then return, rVAR_ALLOCATEDFROM_
if (symbol eq 'rVAR_ALLOCATEDTO_') then return, rVAR_ALLOCATEDTO_
if (symbol eq 'zVAR_ALLOCATEDFROM_') then return, zVAR_ALLOCATEDFROM_
if (symbol eq 'zVAR_ALLOCATEDTO_') then return, zVAR_ALLOCATEDTO_
if (symbol eq 'zVAR_nINDEXLEVELS_') then return, zVAR_nINDEXLEVELS_
if (symbol eq 'rVAR_nINDEXLEVELS_') then return, rVAR_nINDEXLEVELS_
if (symbol eq 'CDF_SCRATCHDIR_') then return, CDF_SCRATCHDIR_
if (symbol eq 'rVAR_RESERVEPERCENT_') then return, rVAR_RESERVEPERCENT_
if (symbol eq 'zVAR_RESERVEPERCENT_') then return, zVAR_RESERVEPERCENT_
if (symbol eq 'rVAR_RECORDS_') then return, rVAR_RECORDS_
if (symbol eq 'zVAR_RECORDS_') then return, zVAR_RECORDS_
if (symbol eq 'STAGE_CACHESIZE_') then return, STAGE_CACHESIZE_
if (symbol eq 'COMPRESS_CACHESIZE_') then return, COMPRESS_CACHESIZE_
;------------------------------------------------------------------------------
; Check for synonyms...
;------------------------------------------------------------------------------
if (symbol eq 'rVAR_EXTENDRECS_') then return, rVAR_EXTENDRECS_
if (symbol eq 'zVAR_EXTENDRECS_') then return, zVAR_EXTENDRECS_
;------------------------------------------------------------------------------
; Unknown status code.
;------------------------------------------------------------------------------
print, "<<< Unknown/invalid symbol in MII >>>"
return, 0L
end
