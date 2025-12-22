;------------------------------------------------------------------------------
;
;  NSSDC/CDF					    MCP (Map CDF Parameters).
;
;  Version 1.2b, 16-Dec-97, Hughes STX.
;                 
;  Modification history:
;
;   V1.0  23-Aug-93, J Love	Original version.
;   V1.0a  4-Feb-94, J Love	DEC Alpha/OpenVMS port.
;   V1.1   1-Nov-94, J Love	CDF V2.5.
;   V1.1a 12-Jun-95, J Love	EPOCH custom format.
;   V1.1b 26-Jun-95, J Love	IDL 4.0.
;   V1.2   9-Sep-96, J Love	CDF V2.6.
;   V1.2a 21-Feb-97, J Love	Removed RICE.
;   V1.2b 16-Dec-97, J Love	Added ALPHAVMSi encoding.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; MCP.
;------------------------------------------------------------------------------

;+
; NAME:
;       MCP
;
; PURPOSE:
;       MCP (Map CDF Parameter) is used to map (look up) the numeric value
;       associated with the (IDL) variables defined in `cdf.pro'.  MCP would
;       be used in those cases where it is not possible to include `cdf.pro'
;       (by executing `@cdf.pro' at the IDL command line) because of the limit
;       on the number of local variable which may exist in a function/procedure
;       (as imposed by IDL).
;
;       This function is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
; CALLING SEQUENCE:
;       value = MCP (name)
;
; INPUTS:
;       name:           STRING.  Symbolic name of the parameter whose value
;                       is desired.
;
; OUTPUTS:
;       value:          LONG.  The associated value.
;
; EXAMPLE:
;       IDL> numDims = 1L
;       IDL> dimSizes = lonarr(1)
;       IDL> dimSizes(0) = 100L
;       IDL> status = CDFcreate ('flux1', numDims, dimSizes, $
;       IDL>                     MCP('HOST_ENCODING'), MCP('ROW_MAJOR'), id)
;       IDL> if (status lt MCP('CDF_WARN')) print, 'CDFcreate failed.'
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       23-Aug-93        Original version.
;       26-Jun-95        IDL 4.0.
;       21-Aug-96        CDF V2.6.
;-

function MCP, symbol
@cdf.pro
;------------------------------------------------------------------------------
; Check for constants...
;------------------------------------------------------------------------------
if (symbol eq 'CDF_OK') then return, CDF_OK
if (symbol eq 'CDF_WARN') then return, CDF_WARN
if (symbol eq 'CDF_MIN_DIMS') then return, CDF_MIN_DIMS
if (symbol eq 'CDF_MAX_DIMS') then return, CDF_MAX_DIMS
if (symbol eq 'CDF_VAR_NAME_LEN  ') then return, CDF_VAR_NAME_LEN  
if (symbol eq 'CDF_ATTR_NAME_LEN ') then return, CDF_ATTR_NAME_LEN 
if (symbol eq 'CDF_COPYRIGHT_LEN ') then return, CDF_COPYRIGHT_LEN 
if (symbol eq 'CDF_STATUSTEXT_LEN ') then return, CDF_STATUSTEXT_LEN 
if (symbol eq 'CDF_PATHNAME_LEN') then return, CDF_PATHNAME_LEN
if (symbol eq 'EPOCH_STRING_LEN') then return, EPOCH_STRING_LEN
if (symbol eq 'EPOCH1_STRING_LEN') then return, EPOCH1_STRING_LEN
if (symbol eq 'EPOCH2_STRING_LEN') then return, EPOCH2_STRING_LEN
if (symbol eq 'EPOCH3_STRING_LEN') then return, EPOCH3_STRING_LEN
if (symbol eq 'EPOCHx_STRING_MAX') then return, EPOCHx_STRING_MAX
if (symbol eq 'EPOCHx_FORMAT_MAX') then return, EPOCHx_FORMAT_MAX
if (symbol eq 'CDF_INT1') then return, CDF_INT1
if (symbol eq 'CDF_INT2') then return, CDF_INT2
if (symbol eq 'CDF_INT4') then return, CDF_INT4
if (symbol eq 'CDF_UINT1') then return, CDF_UINT1
if (symbol eq 'CDF_UINT2') then return, CDF_UINT2
if (symbol eq 'CDF_UINT4') then return, CDF_UINT4
if (symbol eq 'CDF_REAL4') then return, CDF_REAL4
if (symbol eq 'CDF_REAL8') then return, CDF_REAL8
if (symbol eq 'CDF_EPOCH') then return, CDF_EPOCH
if (symbol eq 'CDF_BYTE') then return, CDF_BYTE
if (symbol eq 'CDF_FLOAT') then return, CDF_FLOAT
if (symbol eq 'CDF_DOUBLE') then return, CDF_DOUBLE
if (symbol eq 'CDF_CHAR') then return, CDF_CHAR
if (symbol eq 'CDF_UCHAR') then return, CDF_UCHAR
if (symbol eq 'NETWORK_ENCODING') then return, NETWORK_ENCODING
if (symbol eq 'SUN_ENCODING') then return, SUN_ENCODING
if (symbol eq 'VAX_ENCODING') then return, VAX_ENCODING
if (symbol eq 'DECSTATION_ENCODING') then return, DECSTATION_ENCODING
if (symbol eq 'SGi_ENCODING') then return, SGi_ENCODING
if (symbol eq 'IBMPC_ENCODING') then return, IBMPC_ENCODING
if (symbol eq 'IBMRS_ENCODING') then return, IBMRS_ENCODING
if (symbol eq 'HOST_ENCODING') then return, HOST_ENCODING
if (symbol eq 'MAC_ENCODING') then return, MAC_ENCODING
if (symbol eq 'HP_ENCODING') then return, HP_ENCODING
if (symbol eq 'NeXT_ENCODING') then return, NeXT_ENCODING
if (symbol eq 'ALPHAOSF1_ENCODING') then return, ALPHAOSF1_ENCODING
if (symbol eq 'ALPHAVMSd_ENCODING') then return, ALPHAVMSd_ENCODING
if (symbol eq 'ALPHAVMSg_ENCODING') then return, ALPHAVMSg_ENCODING
if (symbol eq 'ALPHAVMSi_ENCODING') then return, ALPHAVMSi_ENCODING
if (symbol eq 'NETWORK_DECODING') then return, NETWORK_DECODING
if (symbol eq 'SUN_DECODING') then return, SUN_DECODING
if (symbol eq 'VAX_DECODING') then return, VAX_DECODING
if (symbol eq 'DECSTATION_DECODING') then return, DECSTATION_DECODING
if (symbol eq 'SGi_DECODING') then return, SGi_DECODING
if (symbol eq 'IBMPC_DECODING') then return, IBMPC_DECODING
if (symbol eq 'IBMRS_DECODING') then return, IBMRS_DECODING
if (symbol eq 'HOST_DECODING') then return, HOST_DECODING
if (symbol eq 'MAC_DECODING') then return, MAC_DECODING
if (symbol eq 'HP_DECODING') then return, HP_DECODING
if (symbol eq 'NeXT_DECODING') then return, NeXT_DECODING
if (symbol eq 'ALPHAOSF1_DECODING') then return, ALPHAOSF1_DECODING
if (symbol eq 'ALPHAVMSd_DECODING') then return, ALPHAVMSd_DECODING
if (symbol eq 'ALPHAVMSg_DECODING') then return, ALPHAVMSg_DECODING
if (symbol eq 'ALPHAVMSi_DECODING') then return, ALPHAVMSi_DECODING
if (symbol eq 'VARY') then return, VARY
if (symbol eq 'NOVARY') then return, NOVARY
if (symbol eq 'ROW_MAJOR') then return, ROW_MAJOR
if (symbol eq 'COLUMN_MAJOR') then return, COLUMN_MAJOR
if (symbol eq 'COL_MAJOR') then return, COL_MAJOR
if (symbol eq 'SINGLE_FILE') then return, SINGLE_FILE
if (symbol eq 'MULTI_FILE') then return, MULTI_FILE
if (symbol eq 'GLOBAL_SCOPE') then return, GLOBAL_SCOPE
if (symbol eq 'GLOBAL_SCOPE_ASSUMED') then return, GLOBAL_SCOPE_ASSUMED
if (symbol eq 'VARIABLE_SCOPE') then return, VARIABLE_SCOPE
if (symbol eq 'VARIABLE_SCOPE_ASSUMED') then return, VARIABLE_SCOPE_ASSUMED
if (symbol eq 'READONLYon') then return, READONLYon
if (symbol eq 'READONLYoff') then return, READONLYoff
if (symbol eq 'zMODEoff') then return, zMODEoff
if (symbol eq 'zMODEon1') then return, zMODEon1
if (symbol eq 'zMODEon2') then return, zMODEon2
if (symbol eq 'NEGtoPOSfp0on') then return, NEGtoPOSfp0on
if (symbol eq 'NEGtoPOSfp0off') then return, NEGtoPOSfp0off
if (symbol eq 'CDF_MAX_PARMS') then return, CDF_MAX_PARMS
if (symbol eq 'NO_COMPRESSION') then return, NO_COMPRESSION
if (symbol eq 'RLE_COMPRESSION') then return, RLE_COMPRESSION
if (symbol eq 'HUFF_COMPRESSION') then return, HUFF_COMPRESSION
if (symbol eq 'AHUFF_COMPRESSION') then return, AHUFF_COMPRESSION
if (symbol eq 'GZIP_COMPRESSION') then return, GZIP_COMPRESSION
if (symbol eq 'RLE_OF_ZEROs') then return, RLE_OF_ZEROs
if (symbol eq 'OPTIMAL_ENCODING_TREES') then return, OPTIMAL_ENCODING_TREES
if (symbol eq 'NO_SPARSEARRAYS') then return, NO_SPARSEARRAYS
if (symbol eq 'NO_SPARSERECORDS') then return, NO_SPARSERECORDS
if (symbol eq 'PAD_SPARSERECORDS') then return, PAD_SPARSERECORDS
if (symbol eq 'PREV_SPARSERECORDS') then return, PREV_SPARSERECORDS
;------------------------------------------------------------------------------
; Unknown constant.
;------------------------------------------------------------------------------
print, "<<< Unknown/invalid symbol in MCP >>>"
return, 0L
end
