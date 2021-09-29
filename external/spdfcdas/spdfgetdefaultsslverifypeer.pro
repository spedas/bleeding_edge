;
; NOSA HEADER START
;
; The contents of this file are subject to the terms of the NASA Open 
; Source Agreement (NOSA), Version 1.3 only (the "Agreement").  You may 
; not use this file except in compliance with the Agreement.
;
; You can obtain a copy of the agreement at
;   docs/NASA_Open_Source_Agreement_1.3.txt
; or 
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
;
; See the Agreement for the specific language governing permissions
; and limitations under the Agreement.
;
; When distributing Covered Code, include this NOSA HEADER in each
; file and include the Agreement file at 
; docs/NASA_Open_Source_Agreement_1.3.txt.  If applicable, add the 
; following below this NOSA HEADER, with the fields enclosed by 
; brackets "[]" replaced with your own identifying information: 
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2018 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;


;+
; Gets the default value for the IDLnetURL SSL_VERIFY_PEER property
; based upon the current version of IDL.
;
; @returns 0 if current version of IDL cannot verify new SSL certificates.
;     Otherwise, 1.
;-
function SpdfGetDefaultSslVerifyPeer
    compile_opt idl2

    releaseComponents = strsplit(!version.release, '.', /extract)

    if (releaseComponents[0] lt '8') or $
       (releaseComponents[0] eq '8' and $
        releaseComponents[1] lt '4') then begin

        ; Earlier versions of IDL cannot verify new SSL certificates.

        return, 0
    endif

    return, 1
end
