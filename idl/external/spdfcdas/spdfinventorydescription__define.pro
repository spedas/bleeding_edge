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
; This class is an IDL representation of the InventoryDescription
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
; Creates an SpdfInventoryDescription object.
;
; @param id {in} {type=string}
;            dataset identifier.
; @param timeIntervals {in} {type=objarr of SpdfTimeIntervals}
;            time intervals when data is available.
; @returns reference to an SpdfInventoryDescription object.
;-
function SpdfInventoryDescription::init, $
    id, timeIntervals
    compile_opt idl2

    self.id = id
    self.timeIntervals = ptr_new(timeIntervals)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfInventoryDescription::cleanup
    compile_opt idl2

;    if obj_valid(*self.timeIntervals) then obj_destroy, *self.timeIntervals
    if ptr_valid(self.timeIntervals) then ptr_free, self.timeIntervals
end


;+
; Gets the dataset identifier.
;
; @returns dataset identifier.
;-
function SpdfInventoryDescription::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the time intervals when data is available.
;
; @returns time intervals when data is available.
;-
function SpdfInventoryDescription::getTimeIntervals
    compile_opt idl2

    return, *self.timeIntervals
end


;+
; Defines the SpdfInventoryDescription class.
;
; @field id dataset identifier.
; @field timeIntervals time intervals when data is available.
;-
pro SpdfInventoryDescription__define
    compile_opt idl2
    struct = { SpdfInventoryDescription, $
        id:'', $
        timeIntervals:ptr_new() $
    }
end
