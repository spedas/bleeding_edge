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
; Copyright (c) 2010-2017 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;

;+
; This class represents an object that is used to report HTTP errors.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfHttpErrorDialog object.
;
; @returns reference to an SpdfHttpErrorDialog object.
;-
function SpdfHttpErrorDialog::init
    compile_opt idl2

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfHttpErrorDialog::cleanup
    compile_opt idl2

end


;+
; This procedure is called when an HTTP error occurs.  This 
; implementation displays a dialog message with some diagnostic 
; information.
;
; @param responseCode {in} {type=int}
;            the HTTP response code of the request causing the error.
; @param responseHeader {in} {type=string}
;            the HTTP response header of the request causing the error.
; @param responseFilename {in} {type=string}
;            the name of an error response file sent when the error
;            occurred.
;-
pro SpdfHttpErrorDialog::reportError, $
    responseCode, responseHeader, responseFilename
    compile_opt idl2

    case responseCode of
        404:  ; ignore
        else: begin
            reply = dialog_message(!error_state.msg, $
                        title='HTTP Error', /center, /error)

            self->SpdfHttpErrorReporter::reportError, $
                responseCode, responseHeader, reponseFilename
        end
    endcase
end


;+
; Defines the SpdfHttpErrorDialog class.
;
;-
pro SpdfHttpErrorDialog__define
    compile_opt idl2
    struct = { SpdfHttpErrorDialog, $
        inherits SpdfHttpErrorReporter $
    }
end
