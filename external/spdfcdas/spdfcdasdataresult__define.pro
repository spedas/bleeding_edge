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
; Copyright (c) 2010-2017 United States Government as represented by 
; the National Aeronautics and Space Administration. No copyright is 
; claimed in the United States under Title 17, U.S.Code. All Other 
; Rights Reserved.
;
;


;+
; This class is an IDL representation of the DataResult element from the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis 
; System</a> (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2017 United States Government as 
;     represented by the National Aeronautics and Space Administration.
;     No copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfCdasDataResult object.
;
; @param fileDescriptions {in} {type=objarr of SpdfFileDescription}
;            descriptions of the files comprising this result.
; @keyword messages {in} {optional} {type=strarr} 
;            messages related to this result.
; @keyword warnings {in} {optional} {type=strarr} 
;            warnings related to this result.
; @keyword statuses {in} {optional} {type=strarr} 
;            statuses related to this result.
; @keyword errors {in} {optional} {type=strarr} 
;            errors related to this result.
; @returns reference to an SpdfCdasDataResult object.
;-
function SpdfCdasDataResult::init, $
    fileDescriptions, $
    messages = messages, warnings = warnings, $
    statuses = statuses, errors = errors
    compile_opt idl2

    self.fileDescriptions = ptr_new(/allocate_heap)
    *self.fileDescriptions = fileDescriptions

    if keyword_set(messages) then begin
        self.messages = ptr_new(/allocate_heap)
        *self.messages = messages
    end

    if keyword_set(warnings) then begin
        self.warnings = ptr_new(/allocate_heap)
        *self.warnings = warnings
    end

    if keyword_set(statuses) then begin
        self.statuses = ptr_new(/allocate_heap)
        *self.statuses = statuses
    end

    if keyword_set(errors) then begin
        self.errors = ptr_new(/allocate_heap)
        *self.errors = errors
    end

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCdasDataResult::cleanup
    compile_opt idl2

    if ptr_valid(self.fileDescriptions) then ptr_free, self.fileDescriptions
    if ptr_valid(self.messages) then ptr_free, self.messages
    if ptr_valid(self.warnings) then ptr_free, self.warnings
    if ptr_valid(self.statuses) then ptr_free, self.statuses
    if ptr_valid(self.errors) then ptr_free, self.errors
end


;+
; Gets the SpdfFileDescriptions.
;
; @returns a reference to objarr of SpdfFileDescriptions.
;-
function SpdfCdasDataResult::getFileDescriptions
    compile_opt idl2

    return, *(self.fileDescriptions)
end


;+
; Gets the messages.
;
; @returns a reference to strarr of messages.
;-
function SpdfCdasDataResult::getMessages
    compile_opt idl2

    if ptr_valid(self.messages) then begin

        return, *(self.messages)
    endif else begin

        return, ['']
    endelse
end


;+
; Gets the warnings.
;
; @returns a reference to strarr of warnings.
;-
function SpdfCdasDataResult::getWarnings
    compile_opt idl2

    if ptr_valid(self.warnings) then begin

        return, *(self.warnings)
    endif else begin

        return, ['']
    endelse
end


;+
; Gets the statuses.
;
; @returns a reference to strarr of statuses.
;-
function SpdfCdasDataResult::getStatuses
    compile_opt idl2

    if ptr_valid(self.statuses) then begin

        return, *(self.statuses)
    endif else begin

        return, ['']
    endelse
end


;+
; Gets the errors.
;
; @returns a reference to strarr of errors.
;-
function SpdfCdasDataResult::getErrors
    compile_opt idl2

    if ptr_valid(self.errors) then begin

        return, *(self.errors)
    endif else begin

        return, ['']
    endelse
end


;+
; Prints a textual representation of this object.
;-
pro SpdfCdasDataResult::print
    compile_opt idl2

    if ptr_valid(self.fileDescriptions) then begin

        print, 'File Descriptions:'

        for i = 0, n_elements(*self.fileDescriptions) - 1 do begin

            if obj_valid((*self.fileDescriptions)[i]) then begin

                (*self.fileDescriptions)[i]->print
            endif else begin

                print, 'fileDescriptions[', i, '] is not valid'
            endelse
        endfor
    end

    if ptr_valid(self.messages) then begin

        print, 'Messages:'

        for i = 0, n_elements(*self.messages) - 1 do begin

            print, '  ', (*self.messages)[i]
        endfor
    end

    if ptr_valid(self.warnings) then begin

        print, 'Warnings:'

        for i = 0, n_elements(*self.warnings) - 1 do begin

            print, '  ', (*self.warnings)[i]
        endfor
    end

    if ptr_valid(self.statuses) then begin

        print, 'Statuses:'

        for i = 0, n_elements(*self.statuses) - 1 do begin

            print, '  ', (*self.statuses)[i]
        endfor
    end

    if ptr_valid(self.errors) then begin

        print, 'Errors:'

        for i = 0, n_elements(*self.errors) - 1 do begin

            print, '  ', (*self.errors)[i]
        endfor
    end

end


;+
; Defines the SpdfCdasDataResult class.
;
; @field fileDescriptions descriptions of the files comprising this
;            result.
; @field messages messages related to this result.
; @field warnings warnings related to this result.
; @field statuses statuses related to this result.
; @field errors errors related to this result.
;-
pro SpdfCdasDataResult__define
    compile_opt idl2
    struct = { SpdfCdasDataResult, $
        fileDescriptions:ptr_new(), $
        messages:ptr_new(), $
        warnings:ptr_new(), $
        statuses:ptr_new(), $
        errors:ptr_new() $
    }
end
