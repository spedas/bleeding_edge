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
;   http://sscweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
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
; Copyright (c) 2013 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the Result
; element from the
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>
; (SSC) XML schema.
;
; @copyright Copyright (c) 2013 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfResult object.
;
; @keyword statusCode {in} {type=string}
;              result status code.
; @keyword statusSubCode {in} {type=string}
;              result status sub-code.
; @keyword statusText {in} {type=strarr}
;              result status text.
; @returns reference to an SpdfResult object.
;-
function SpdfResult::init, $
    statusCode = statusCode, $
    statusSubCode = statusSubCode, $
    statusText = statusText
    compile_opt idl2

    self.statusCode = statusCode
    self.statusSubCode = statusSubCode
    self.statusText = ptr_new(statusText)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfResult::cleanup
    compile_opt idl2

    if ptr_valid(self.statusText) then ptr_free, self.statusText
end


;+
; Gets the status code value.
;
; @returns status code value.
;-
function SpdfResult::getStatusCode
    compile_opt idl2

    return, self.statusCode
end


;+
; Gets the status sub-code value.
;
; @returns status sub-code value.
;-
function SpdfResult::getStatusSubCode
    compile_opt idl2

    return, self.statusSubCode
end


;+
; Gets the status text.
;
; @returns a reference to strarr of status text.
;-
function SpdfResult::getStatusText
    compile_opt idl2

    return, *self.statusText
end


;+
; Prints a textual representation of this object.
;-
pro SpdfResult::print
    compile_opt idl2

    print, '  ', self.statusCode, ': ', self.statusSubCode
end


;+
; Defines the SpdfResult class.
;
; @field statusCode result status code.
; @field statusSubCode result status sub-code.
; @field statusText result status text.
;-
pro SpdfResult__define
    compile_opt idl2
    struct = { SpdfResult, $
        statusCode:'', $
        statusSubCode:'', $
        statusText:ptr_new() $
    }
end
