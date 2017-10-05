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
; This class is an IDL representation of the Locations
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
; Creates an SpdfLocations object.
;
; @param id {in} {type=string}
;            satellite identifier.
; @param time {in} {type=array}
;            juldate time of location.
; @param coordinateSystem {in} {type=string}
;            coordinate system (valid values: "Geo", "Gm", "Gse",
;            "Gsm", "Sm", "GeiTod", "GeiJ2000").
; @keyword x {in} {type=dblarr}
;              X values.
; @keyword y {in} {type=dblarr}
;              Y values.
; @keyword z {in} {type=dblarr}
;              Z values.
; @keyword latitude {in} {type=fltarr}
;              latitude values.
; @keyword longitude {in} {type=fltarr}
;              longitude values.
; @keyword localTime {in} {type=dblarr}
;              local time values.
; @returns reference to an SpdfLocations object.
;-
function SpdfLocations::init, $
    id, $
    time, $
    coordinateSystem, $
    x = x, $
    y = y, $
    z = z, $
    latitude = latitude, $
    longitude = longitude, $
    localTime = localTime
    compile_opt idl2

    if ~(self->SpdfCoordinateData::init( $
            coordinateSystem, $
            x = x, $
            y = y, $
            z = z, $
            latitude = latitude, $
            longitude = longitude, $
            localTime = localTime)) then begin

       return, 0
    endif

    self.id = id
    self.time = ptr_new(time)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfLocations::cleanup
    compile_opt idl2

    if ptr_valid(self.time) then ptr_free, self.time

;    self->SpdfCoordinateData::cleanup
end


;+
; Gets the id value.
;
; @returns the id value.
;-
function SpdfLocations::getId
    compile_opt idl2
 
    return, self.id
end


;+
; Gets the time values.
;
; @returns a dblarr containing time values or the constant scalar
;     !values.d_NaN if there are no values.
;-
function SpdfLocations::getTime
    compile_opt idl2
 
    if ptr_valid(self.time) then begin

        return, *self.time
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Defines the SpdfLocations class.
;
; @field id satellite identifier.
; @field time juldate of locations.
;-
pro SpdfLocations__define
    compile_opt idl2
    struct = { SpdfLocations, $

        inherits SpdfCoordinateData, $
        id:'', $
        time:ptr_new() $
    }
end
