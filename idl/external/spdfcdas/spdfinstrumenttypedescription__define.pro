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
; This class is an IDL representation of the InstrumentTypeDescription
; element from the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfInstrumentTypeDescription object.
;
; @param name {in} {type=string}
;            instrument-type name.
; @returns reference to an SpdfInstrumentTypeDescription object.
;-
function SpdfInstrumentTypeDescription::init, $
    name
    compile_opt idl2

    self.name = name

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfInstrumentTypeDescription::cleanup
    compile_opt idl2

end


;+
; Gets the name.
;
; @returns name value.
;-
function SpdfInstrumentTypeDescription::getName
    compile_opt idl2

    return, self.name
end


;+
; Prints a textual representation of this object.
;-
pro SpdfInstrumentTypeDescription::print
    compile_opt idl2

    print, 'name: ', self.name
end


;+
; Defines the SpdfInstrumentTypeDescription class.
;
; @field name instrument-type name.
;-
pro SpdfInstrumentTypeDescription__define
    compile_opt idl2
    struct = { SpdfInstrumentTypeDescription, $
        name:'' $
    }
end
