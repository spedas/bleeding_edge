;******************************************************************************
;
;  NSSDC/CDF				CDF `include file' for IDL interface.
;
;  Version 1.2, 21-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  22-Feb-95, J Love	Original version.
;   V1.1  26-Jun-95, J Love	Added online help.
;   V1.2  21-Aug-96, J Love	CDF V2.6.
;
;******************************************************************************

;+
; NAME:
;       cdf0.pro
;
; PURPOSE:
;       `cdf0.pro' is used to create a set of structure variables containing
;       the constants used by the CDF library.  The structures created and
;       their contents are as follows...
;
;               CDFconst     - General CDF constants.
;               CDFdataType  - Data type codes.
;               CDFencoding  - Encoding codes.
;               CDFdecoding  - Decoding codes.
;               CDFiCode     - Informational status codes.
;               CDFwCode     - Warning status codes.
;               CDFeCode     - Error status codes.
;               CDFiiFnc     - Internal Interface functions.
;               CDFiiItem    - General Internal Interface items.
;               CDFiiItemA   - Internal Interface attribute items.
;               CDFiiItemE   - Internal Interface entry items.
;               CDFiiItemR   - Internal Interface rVariable items.
;               CDFiiItemZ   - Internal Interface zVariable items.
;
;       These structures contain the same values defined using the `cdf.pro',
;       `cdf1.pro', and `cdf2.pro' batch files.  To see the contents of each
;       structure, use the command...
;
;               IDL> help, /structure, <structure-name>
;
;       The use of these structures eliminates the problem of too many local
;       variables caused by the use of `cdf.pro', `cdf1.pro', and `cdf2.pro'.
;
;       This include file is part of the CDF interface provided with the CDF
;       distribution.  IDL also provides its own built-in interface to CDFs.
;
;       If the lengths of these structure names are longer than desired,
;       consider using `cdf0x.pro' instead.
;
; CALLING SEQUENCE:
;       IDL> @cdf0.pro
;
; EXAMPLE:
;       IDL> @cdf0.pro
;       IDL> status = CDFlib (CDFiiFnc.OPEN_, CDFiiItem.CDF_, 'rain2x', id, $
;       IDL>                  CDFiiFnc.NULL_)
;       IDL> if (status lt CDFconst.CDF_WARN) print, 'CDF not opened...'
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       26-Jun-95       Original version.
;       21-Aug-96       CDF V2.6.
;-

CDFconstantCodes, CDFconst
CDFdataTypeCodes, CDFdataType
CDFencodingCodes, CDFencoding
CDFdecodingCodes, CDFdecoding
CDFinfoCodes, CDFiCode
CDFwarnCodes, CDFwCode
CDFerrorCodes, CDFeCode
CDFiiFunctionCodes, CDFiiFnc
CDFiiItemCodes, CDFiiItem
CDFii_attrItemCodes, CDFiiItemA
CDFii_entryItemCodes, CDFiiItemE
CDFii_rVarItemCodes, CDFiiItemR
CDFii_zVarItemCodes, CDFiiItemZ
