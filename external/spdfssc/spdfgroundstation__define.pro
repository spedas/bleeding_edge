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
; This class is an IDL representation of the GroundStation
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
; Creates an SpdfGroundStation object.
;
; @param id {in} {type=string}
;            ground station identifier.
; @param name {in} {type=string}
;            ground station name.
; @param location {in} {type=SpdfSurfaceGeographicCoordinates}
;            ground station location.
; @returns reference to an SpdfGroundStation object.
;-
function SpdfGroundStation::init, $
    id, name, location
    compile_opt idl2

    self.id = id
    self.name = name
    self.location = location

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfGroundStation::cleanup
    compile_opt idl2

end


;+
; Gets the id of this ground station.
;
; @returns id of this ground station.
;-
function SpdfGroundStation::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the name of this ground station.
;
; @returns name of this ground station.
;-
function SpdfGroundStation::getName
    compile_opt idl2

    return, self.name
end


;+
; Gets the location of this ground station.
;
; @returns a reference to the location of this ground station.
;-
function SpdfGroundStation::getLocation
    compile_opt idl2

    return, self.location
end


;+
; Prints a textual representation of this object.
;-
pro SpdfGroundStation::print
    compile_opt idl2

    print, '  ', self.id, ': ', self.name
end


;+
; Defines the SpdfGroundStation class.
;
; @field id ground station identifier.
; @field name ground station's name.
; @field location ground station's location.
;-
pro SpdfGroundStation__define
    compile_opt idl2
    struct = { SpdfGroundStation, $
        id:'', $
        name:'', $
        location:obj_new() $
    }
end
