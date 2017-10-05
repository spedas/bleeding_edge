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
; This class is an IDL representation of the SurfaceGeographicCoordinates
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
; Creates an SpdfSurfaceGeographicCoordinates object.
;
; @param latitude {in} {type=double}
;            latitude value.
; @param longitude {in} {type=double}
;            longitude value.
; @returns reference to an SpdfSurfaceGeographicCoordinates object.
;-
function SpdfSurfaceGeographicCoordinates::init, $
    latitude, longitude
    compile_opt idl2

    self.latitude = latitude
    self.longitude = longitude

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSurfaceGeographicCoordinates::cleanup
    compile_opt idl2

; call super->cleanup ???
end


;+
; Gets the latitude value.
;
; @returns latitude value.
;-
function SpdfSurfaceGeographicCoordinates::getLatitude
    compile_opt idl2

    return, self.latitude
end


;+
; Gets the longitude value.
;
; @returns longitude value.
;-
function SpdfSurfaceGeographicCoordinates::getLongitude
    compile_opt idl2

    return, self.longitude
end


;+
; Prints a textual representation of this object.
;-
pro SpdfSurfaceGeographicCoordinates::print
    compile_opt idl2

    print, '  ', self.latitude, ', ', self.longitude
end


;+
; Defines the SpdfSurfaceGeographicCoordinates class.
;
; @field latitude latitude value.
; @field longitude longitude value.
;-
pro SpdfSurfaceGeographicCoordinates__define
    compile_opt idl2
    struct = { SpdfSurfaceGeographicCoordinates, $
        inherits SpdfCoordinates, $
        latitude:0.0d, $
        longitude:0.0d $
    }
end
