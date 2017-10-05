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
; This class is an IDL representation of the BTraceData
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
; Creates an SpdfBTraceData object.
;
; @param coordinateSystem {in} {type=string}
;            coordinate system.
; @param hemisphere {in} {type=string}
;            hemisphere.
; @keyword latitude {in} {type=fltarr}
;              latitude values.
; @keyword longitude {in} {type=fltarr}
;              longitude values.
; @keyword arcLength {in} {type=dblarr}
;              arc length values.
; @returns reference to an SpdfBTraceData object.
;-
function SpdfBTraceData::init, $
    coordinateSystem, $
    hemisphere, $
    latitude = latitude, $
    longitude = longitude, $
    arcLength = arcLength
    compile_opt idl2

    self.coordinateSystem = coordinateSystem
    self.hemisphere = hemisphere

    if keyword_set(latitude) then self.latitude = ptr_new(latitude)
    if keyword_set(longitude) then self.longitude = ptr_new(longitude)
    if keyword_set(arcLength) then self.arcLength = ptr_new(arcLength)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfBTraceData::cleanup
    compile_opt idl2

    if ptr_valid(self.latitude) then ptr_free, self.latitude
    if ptr_valid(self.longitude) then ptr_free, self.longitude
    if ptr_valid(self.arcLength) then ptr_free, self.arcLength
end


;+
; Gets the coordinate system value.
;
; @returns coordinate system value.
;-
function SpdfBTraceData::getCoordinateSystem
    compile_opt idl2

    return, self.coordinateSystem
end


;+
; Gets the hemisphere value.
;
; @returns hemisphere value.
;-
function SpdfBTraceData::getHemisphere
    compile_opt idl2

    return, self.hemisphere
end


;+
; Gets the latitude values.
;
; @returns a fltarr contain latitude values or the scalar constant
;     !values.d_NaN if there are no values.
;-
function SpdfBTraceData::getLatitude
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
; @returns a fltarr contain longitude values or the scalar constant
;     !values.d_NaN if there are no values.
;-
function SpdfBTraceData::getLongitude
    compile_opt idl2

    if ptr_valid(self.longitude) then begin

        return, *self.longitude
    endif else begin

        return, !values.f_NaN
    endelse
end


;+
; Gets the ArcLength values.
;
; @returns a dblarr contain ArcLength values or the scalar constant
;     !values.d_NaN if there are no values.
;-
function SpdfBTraceData::getArcLength
    compile_opt idl2

    if ptr_valid(self.arcLength) then begin

        return, *self.arcLength
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Defines the SpdfBTraceData class.
;
; @field coordinateSystem coordinate system.
; @field hemisphere hemisphere.
; @field latitude latitude values.
; @field longitude longitude values.
; @field arcLength arc length values.
;-
pro SpdfBTraceData__define
    compile_opt idl2
    struct = { SpdfBTraceData, $
        coordinateSystem:'', $
        hemisphere:'', $
        latitude:ptr_new(), $
        longitude:ptr_new(), $
        arcLength:ptr_new() $
    }
end
