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
; This class is an IDL representation of the VariableDescription
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
; Creates an SpdfVariableDescription object.
;
; @param name {in} {type=string}
;            name of variable.
; @param shortDescription {in} {type=string}
;            short description of varaible.
; @param longDescription {in} {type=string}
;            long description of varaible.
; @keyword parent {in} {type=string} {optional}
;            name of parent variable.
; @keyword children {in} {type=strarr} {optional}
;            names of child variables
; @returns reference to an SpdfVariableDescription object.
;-
function SpdfVariableDescription::init, $
    name, shortDescription, longDescription, $
    parent = parent, children = children
    compile_opt idl2

    self.name = name
    self.shortDescription = shortDescription
    self.longDescription = longDescription
    if keyword_set(parent) then self.parent = parent
    if keyword_set(children) then self.children = ptr_new(children)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfVariableDescription::cleanup
    compile_opt idl2

    if ptr_valid(self.children) then ptr_free, self.children
end


;+
; Gets the name of this variable.
;
; @returns name of this variable.
;-
function SpdfVariableDescription::getName
    compile_opt idl2

    return, self.name
end


;+
; Gets the short description of this variable.
;
; @returns short description of this variable.
;-
function SpdfVariableDescription::getShortDescription
    compile_opt idl2

    return, self.shortDescription
end


;+
; Gets the long description of this variable.
;
; @returns long description of this variable.
;-
function SpdfVariableDescription::getLongDescription
    compile_opt idl2

    return, self.longDescription
end


;+
; Prints a textual representation of this object.
;-
pro SpdfVariableDescription::print
    compile_opt idl2

    print, '  ', self.name, ' - ', self.shortDescription
end


;+
; Defines the SpdfVariableDescription class.
;
; @field name varable's name.
; @field shortDescription short description of variable.
; @field longDescription long description of variable.
; @field parent name of parent variable.
; @field children names of child variables.
;-
pro SpdfVariableDescription__define
    compile_opt idl2
    struct = { SpdfVariableDescription, $
        name:'', $
        shortDescription:'', $
        longDescription:'', $
        parent:'', $
        children:ptr_new() $
    }
end
