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
; Copyright (c) 2014 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the FileResult
; element from the
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>
; (SSC) XML schema.
;
; @copyright Copyright (c) 2014 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfSscFileResult object.
;
; @param files {in} {type=SpdfFileDescription objarr}
;            result files.
; @keyword statusCode {in} {type=string}
;              result status code.
; @keyword statusSubCode {in} {type=string}
;              result status sub-code.
; @keyword statusText {in} {type=strarr}
;              result status text.
; @returns reference to an SpdfSscFileResult object.
;-
function SpdfSscFileResult::init, $
    files, $
    statusCode = statusCode, $
    statusSubCode = statusSubCode, $
    statusText = statusText
    compile_opt idl2

    obj = self->SpdfResult::init( $
              statusCode = statusCode, $
              statusSubCode = statusSubCode, $
              statusText = statusText)

    self.files = ptr_new(files)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSscFileResult::cleanup
    compile_opt idl2

    if ptr_valid(self.files) then ptr_free, self.files
end


;+
; Gets the files.
;
; @returns a reference to objarr of FileDescriptions.
;-
function SpdfSscFileResult::getFiles
    compile_opt idl2

    return, *self.files
end


;+
; Defines the SpdfSscFileResult class.
;
; @field files result files.
;-
pro SpdfSscFileResult__define
    compile_opt idl2
    struct = { SpdfSscFileResult, $
        inherits SpdfResult, $
        files:ptr_new() $
    }
end
