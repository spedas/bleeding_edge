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
; This class is an IDL representation of the CoordinateData
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
; Creates an SpdfCoordinateData object.
;
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
; @returns reference to an SpdfCoordinateData object.
;-
function SpdfCoordinateData::init, $
    coordinateSystem, $
    x = x, $
    y = y, $
    z = z, $
    latitude = latitude, $
    longitude = longitude, $
    localTime = localTime
    compile_opt idl2

    self.coordinateSystem = coordinateSystem

    if keyword_set(x) then self.x = ptr_new(x)
    if keyword_set(y) then self.y = ptr_new(y)
    if keyword_set(z) then self.z = ptr_new(z)
    if keyword_set(latitude) then self.latitude = ptr_new(latitude)
    if keyword_set(longitude) then self.longitude = ptr_new(longitude)
    if keyword_set(localTime) then self.localTime = ptr_new(localTime)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCoordinateData::cleanup
    compile_opt idl2

    if ptr_valid(self.x) then ptr_free, self.x
    if ptr_valid(self.y) then ptr_free, self.x
    if ptr_valid(self.z) then ptr_free, self.x
    if ptr_valid(self.latitude) then ptr_free, self.latitude
    if ptr_valid(self.longitude) then ptr_free, self.longitude
    if ptr_valid(self.localTime) then ptr_free, self.localTime
end


;+
; Gets the coordinate system value.
;
; @returns the coordinate system value.
;-
function SpdfCoordinateData::getCoordinateSystem
    compile_opt idl2
 
    return, self.coordinateSystem
end


;+
; Gets the X values.
;
; @returns a dblarr containing X values or the constant scalar
;     !values.d_NaN if there are no values.
;-
function SpdfCoordinateData::getX
    compile_opt idl2
 
    if ptr_valid(self.x) then begin

        return, *self.x
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the Y values.
;
; @returns a dblarr containing Y values or the constant scalar
;     !values.d_NaN if there are no values.
;-
function SpdfCoordinateData::getY
    compile_opt idl2
 
    if ptr_valid(self.y) then begin

        return, *self.y
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the Z values.
;
; @returns a dblarr containing Z values or the constant scalar
;     !values.d_NaN if there are no values.
;-
function SpdfCoordinateData::getZ
    compile_opt idl2
 
    if ptr_valid(self.z) then begin

        return, *self.z
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the latitude values.
;
; @returns a fltarr containing latitude values or the constant scalar
;     !values.f_NaN if there are no values.
;-
function SpdfCoordinateData::getLatitude
    compile_opt idl2
 
    if ptr_valid(self.latitude) then begin

        return, *self.latitude
    endif else begin

        return, !values.f_NaN
    endelse
end


;+
; Gets the longitude values.
;
; @returns a fltarr containing longitude values or the constant scalar
;     !values.f_NaN if there are no values.
;-
function SpdfCoordinateData::getLongitude
    compile_opt idl2
 
    if ptr_valid(self.longitude) then begin

        return, *self.longitude
    endif else begin

        return, !values.f_NaN
    endelse
end


;+
; Gets the local time values.
;
; @returns a fltarr containing local time values or the constant scalar
;     !values.f_NaN if there are no values.
;-
function SpdfCoordinateData::getLocalTime
    compile_opt idl2
 
    if ptr_valid(self.localTime) then begin

        return, *self.localTime
    endif else begin

        return, !values.f_NaN
    endelse
end


;+
; Defines the SpdfCoordinateData class.
;
; @field coordinateSystem coordinate system identifier.
; @field x X coordinate values.
; @field y Y coordinate values.
; @field z Z coordinate values.
; @field latitude latitude values.
; @field longitude longitude values.
; @field localTime localTime values.
;-
pro SpdfCoordinateData__define
    compile_opt idl2
    struct = { SpdfCoordinateData, $
        coordinateSystem:'', $
        x:ptr_new(), $
        y:ptr_new(), $
        z:ptr_new(), $
        latitude:ptr_new(), $
        longitude:ptr_new(), $
        localTime:ptr_new() $
    }
end
