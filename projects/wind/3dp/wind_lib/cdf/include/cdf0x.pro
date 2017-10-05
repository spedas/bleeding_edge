;******************************************************************************
;
;  NSSDC/CDF				CDF `include file' for IDL interface.
;
;  Version 1.0, 21-Aug-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  21-Aug-96, J Love	Original version.
;
;******************************************************************************

;+
; NAME:
;       cdf0x.pro
;
; PURPOSE:
;       `cdf0x.pro' is used to create a set of structure variables containing
;       the constants used by the CDF library.  The structures created and
;       their contents are as follows...
;
;               CDFx     - General CDF constants.
;               CDFdt    - Data type codes.
;               CDFen    - Encoding codes.
;               CDFde    - Decoding codes.
;               CDFic    - Informational status codes.
;               CDFwc    - Warning status codes.
;               CDFec    - Error status codes.
;               CDFiif   - Internal Interface functions.
;               CDFiix   - General Internal Interface items.
;               CDFiia   - Internal Interface attribute items.
;               CDFiie   - Internal Interface entry items.
;               CDFiir   - Internal Interface rVariable items.
;               CDFiiz   - Internal Interface zVariable items.
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
; CALLING SEQUENCE:
;       IDL> @cdf0x.pro
;
; EXAMPLE:
;       IDL> @cdf0x.pro
;       IDL> status = CDFlib (CDFiif.OPEN_, CDFiii.CDF_, 'rain2x', id, $
;       IDL>                  CDFiif.NULL_)
;       IDL> if (status lt CDFx.CDF_WARN) print, 'CDF not opened...'
;
; RESTRICTIONS:
;       None.
;
; REVISION HISTORY:
;       21-Aug-96        Original version.
;-

CDFconstantCodes, CDFx
CDFdataTypeCodes, CDFdt
CDFencodingCodes, CDFen
CDFdecodingCodes, CDFde
CDFinfoCodes, CDFic
CDFwarnCodes, CDFwc
CDFerrorCodes, CDFec
CDFiiFunctionCodes, CDFiif
CDFiiItemCodes, CDFiix
CDFii_attrItemCodes, CDFiia
CDFii_entryItemCodes, CDFiie
CDFii_rVarItemCodes, CDFiir
CDFii_zVarItemCodes, CDFiiz
