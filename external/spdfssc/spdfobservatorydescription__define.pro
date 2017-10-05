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
; This class is an IDL representation of the ObservatoryDescription
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
; Creates an SpdfObservatoryDescription object.
;
; @param id {in} {type=string}
;            observatory identifier.
; @param name {in} {type=string}
;            observatory name.
; @param resolution {in} {type=int}
;            resolution of trajectory information.
; @param startTime {in} {type=julday}
;            start time of available information.
; @param endTime {in} {type=julday}
;            end time of available information.
; @param geometry {in} {type=string}
;            URL of the file containing the recommended X3D
;            geometry description for rendering the satellite.
; @param trajectoryGeometry {in} {type=string}
;            URL of the file containing the recommended X3D
;            geometry description for rendering the satellite's
;            trajectory.
; @param resourceId {in} {type=string}
;            observatory resource identifier.
; @param groupIds {in} {type=strarr}
;            /Spase/ObservatoryGroupID values.
; @returns reference to an SpdfObservatoryDescription object.
;-
function SpdfObservatoryDescription::init, $
    id, name, resolution, startTime, endTime, geometry, $
    trajectoryGeometry, resourceId, groupIds
    compile_opt idl2

    obj = self->SpdfSatelliteDescription::init( $
        id, name, resolution, startTime, endTime, geometry, $
        trajectoryGeometry)

    self.resourceId = resourceId
    self.groupIds = ptr_new(groupIds)

    return, obj
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfObservatoryDescription::cleanup
    compile_opt idl2

    if ptr_valid(self.groupIds) then begin

        ptr_free, self.groupIds
    endif
end


;+
; Gets the resourceId of this satellite.
;
; @returns resourceId of this satellite.
;-
function SpdfObservatoryDescription::getResourceId
    compile_opt idl2

    return, self.resourceId
end


;+
; Gets the groupIds of this satellite.
;
; @returns groupIds of this satellite.
;-
function SpdfObservatoryDescription::getGroupIds
    compile_opt idl2

    if ptr_valid(self.groupIds) then begin

        return, *self.groupIds
    endif else begin

        return, strarr(1)
    endelse
end


;+
; Prints a textual representation of this object.
;-
pro SpdfObservatoryDescription::print
    compile_opt idl2

    self->SpdfSatelliteDescription::print
    print, '  ', self.resourceId 
end


;+
; Defines the SpdfObservatoryDescription class.
;
; @field resourceId observatory resource identifier.
;-
pro SpdfObservatoryDescription__define
    compile_opt idl2
    struct = { SpdfObservatoryDescription, $
        inherits SpdfSatelliteDescription, $
        resourceId:'', $
        groupIds:ptr_new() $
    }
end
