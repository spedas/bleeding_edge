;------------------------------------------------------------------------------
;
;  NSSDC/CDF					IDL/CDF startup procedure.
;						SunOS/SOLARIS/Irix5&6/OSF1.
;
;  Version 1.3, 9-Sep-96, Hughes STX.
;
;  Modification history:
;
;   V1.0  14-Sep-92, H Leckner	Original version.
;   V1.1  24-Jan-94, J Love	CDF V2.4.
;   V1.2   7-Nov-94, J Love	CDF V2.5.
;   V1.2a 23-Feb-95, J Love	Added `cdf0'.
;   V1.2b 12-Jun-95, J Love	EPOCH custom format.
;   V1.3   9-Sep-96, J Love	CDF V2.6.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Add directories to IDL search paths.
;------------------------------------------------------------------------------

!path = getenv('CDF_INC') + ':' + !path
!path = getenv('CDF_BIN') + ':' + !path

!help_path = getenv('CDF_HELP') + ':' + !help_path

;------------------------------------------------------------------------------
; Define idl_cdf interface functions.
;------------------------------------------------------------------------------

_shared_if_ = getenv('CDF_LIB') + '/' + 'cdf_idl.so'
linkimage,'idl_cdflib',_shared_if_,min_args=4,max_args=63
linkimage,'idl_cdfcreate',_shared_if_,min_args=9,max_args=9
linkimage,'idl_cdfopen',_shared_if_,min_args=5,max_args=5
linkimage,'idl_cdfinquire',_shared_if_,min_args=11,max_args=11
linkimage,'idl_cdfvarinq',_shared_if_,min_args=10,max_args=10
linkimage,'idl_cdfvarcre',_shared_if_,min_args=10,max_args=10
linkimage,'idl_cdfvarren',_shared_if_,min_args=6,max_args=6
linkimage,'idl_cdfvarnum',_shared_if_,min_args=5,max_args=5
linkimage,'idl_cdfvarget',_shared_if_,min_args=8,max_args=8
linkimage,'idl_cdfvarput',_shared_if_,min_args=8,max_args=8
linkimage,'idl_cdfhypget',_shared_if_,min_args=12,max_args=12
linkimage,'idl_cdfhypput',_shared_if_,min_args=12,max_args=12
linkimage,'idl_cdfattrcre',_shared_if_,min_args=7,max_args=7
linkimage,'idl_cdfattrinq',_shared_if_,min_args=8,max_args=8
linkimage,'idl_cdfattreinq',_shared_if_,min_args=8,max_args=8
linkimage,'idl_cdfattrren',_shared_if_,min_args=6,max_args=6
linkimage,'idl_cdfattrnum',_shared_if_,min_args=5,max_args=5
linkimage,'idl_cdfattrget',_shared_if_,min_args=7,max_args=7
linkimage,'idl_cdfattrput',_shared_if_,min_args=9,max_args=9
linkimage,'idl_cdfdoc',_shared_if_,min_args=7,max_args=7
linkimage,'idl_cdferror',_shared_if_,min_args=5,max_args=5
linkimage,'idl_cdfdelete',_shared_if_,min_args=4,max_args=4
linkimage,'idl_cdfvarclose',_shared_if_,min_args=5,max_args=5
linkimage,'idl_cdfclose',_shared_if_,min_args=4,max_args=4
linkimage,'row_2_col',_shared_if_,min_args=7,max_args=7
linkimage,'col_2_row',_shared_if_,min_args=7,max_args=7
linkimage,'idl_epochbreak',_shared_if_,min_args=8,max_args=8
linkimage,'idl_computepoch',_shared_if_,min_args=8,max_args=8
linkimage,'idl_parsepoch',_shared_if_,min_args=2,max_args=2
linkimage,'idl_parsepoch1',_shared_if_,min_args=2,max_args=2
linkimage,'idl_parsepoch2',_shared_if_,min_args=2,max_args=2
linkimage,'idl_parsepoch3',_shared_if_,min_args=2,max_args=2
linkimage,'idl_encodepoch',_shared_if_,min_args=2,max_args=2
linkimage,'idl_encodepoch1',_shared_if_,min_args=2,max_args=2
linkimage,'idl_encodepoch2',_shared_if_,min_args=2,max_args=2
linkimage,'idl_encodepoch3',_shared_if_,min_args=2,max_args=2
linkimage,'idl_encodepochx',_shared_if_,min_args=3,max_args=3

;------------------------------------------------------------------------------
; Compile idl_cdf interface software.
;------------------------------------------------------------------------------

.run cdfattrcreate.pro
.run cdfattrentryinquire.pro
.run cdfattrget.pro
.run cdfattrinquire.pro
.run cdfattrnum.pro
.run cdfattrput.pro
.run cdfattrrename.pro
.run cdfclose.pro
.run cdfcreate.pro
.run cdfdelete.pro
.run cdfdoc.pro
.run cdferror.pro
.run cdfinquire.pro
.run cdflib.pro
.run cdfopen.pro
.run cdfvarclose.pro
.run cdfvarcreate.pro
.run cdfvarget.pro
.run cdfvarhyperget.pro
.run cdfvarhyperput.pro
.run cdfvarinquire.pro
.run cdfvarnum.pro
.run cdfvarput.pro
.run cdfvarrename.pro
.run epochbreakdown.pro
.run computeepoch.pro
.run parseepoch.pro
.run parseepoch1.pro
.run parseepoch2.pro
.run parseepoch3.pro
.run encodeepoch.pro
.run encodeepoch1.pro
.run encodeepoch2.pro
.run encodeepoch3.pro
.run encodeepochx.pro
.run row_to_col.pro
.run col_to_row.pro
.run cdf0p.pro
.run mcp.pro
.run mii.pro
.run msc.pro

;------------------------------------------------------------------------------
; Create/initialize `current' objects/states.
;------------------------------------------------------------------------------

common cdfcurrent_, cdfid_, cdfstatus_
cdfid_ = 0L				; RESERVED_CDFID (NULL).
cdfstatus_ = -1L			; RESERVED_CDFSTATUS.

;------------------------------------------------------------------------------
; `Include' files.
;    Uncomment zero or more of these.  Previous CDF distributions executed
; `cdf.pro' which created numerous local variables for the CDF constants
; (minus the status codes and Internal Interface functions/items).  In fact
; too many local variables were created which caused problems due to the
; IDL limit on the number of local variables.  `cdf0.pro' solves that problem
; by creating several structures containing the CDF constants (with each
; structure counting as only one local variable).  The purpose of each batch
; file is as follows...
;
;     cdf0x.pro		Creates structures (local variables) containing the
;			CDF constants, status codes, and Internal Interface
;			functions/items.
;     cdf0.pro		Same as `cdf0x.pro' but with longer structure names.
;
;     cdf.pro		Creates local variables for the CDF constants.
;     cdf1.pro		Creates local variables for the status codes.
;     cdf2.pro		Creates local variables for the Internal Interface
;			functions/items.
;
; Leaving all of these lines commented out would probably be preferable.  A
; user could then execute what they want without having unwanted local
; variables automatically created.  If existing applications absolutely rely
; `cdf.pro' being executed, then that line must be uncommented.
;
;------------------------------------------------------------------------------

;@cdf0x.pro
;@cdf0.pro
;@cdf.pro
;@cdf1.pro
;@cdf2.pro
