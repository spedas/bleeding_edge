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
; This class is an IDL representation of the ObservatoryGroupDescription
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
; Creates an SpdfObservatoryGroupDescription object.
;
; @param name {in} {type=string}
;            name of observatory-group.
; @param observatoryIds {in} {type=strarr}
;            identifiers of the observatories in this group.
; @returns reference to an SpdfObservatoryGroupDescription object.
;-
function SpdfObservatoryGroupDescription::init, $
    name, observatoryIds
    compile_opt idl2

    self.name = name
    self.observatoryIds = ptr_new(observatoryIds)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfObservatoryGroupDescription::cleanup
    compile_opt idl2

    if ptr_valid(self.observatoryIds) then ptr_free, self.observatoryIds
end


;+
; Gets the name of this group.
;
; @returns name of this group.
;-
function SpdfObservatoryGroupDescription::getName
    compile_opt idl2

    return, self.name
end


;+
; Gets the IDs of observatories belonging to this group
;
; @returns strarr containing the IDs of observatories belonging to this
;             group.
;-
function SpdfObservatoryGroupDescription::getObservatoryIds
    compile_opt idl2

    return, *self.observatoryIds
end


;+
; Prints a textual representation of this object.
;-
pro SpdfObservatoryGroupDescription::print
    compile_opt idl2

    print, 'name: ', self.name
    print, 'observatoryIds: ', *self.observatoryIds
end


;+
; Defines the SpdfObservatoryGroupDescription class.
;
; @field name name of group.
; @field observatoryIds IDs of observatories belonging to this group.
;-
pro SpdfObservatoryGroupDescription__define
    compile_opt idl2
    struct = { SpdfObservatoryGroupDescription, $
        name:'', $
        observatoryIds:ptr_new() $
    }
end
