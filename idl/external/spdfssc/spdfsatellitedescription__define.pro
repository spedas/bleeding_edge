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
; This class is an IDL representation of the SatelliteDescription
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
; Creates an SpdfSatelliteDescription object.
;
; @param id {in} {type=string}
;            satellite identifier.
; @param name {in} {type=string}
;            satellite name.
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
; @returns reference to an SpdfSatelliteDescription object.
;-
function SpdfSatelliteDescription::init, $
    id, name, resolution, startTime, endTime, geometry, $
    trajectoryGeometry
    compile_opt idl2

    self.id = id
    self.name = name
    self.resolution = resolution
    self.startTime = startTime
    self.endTime = endTime
    self.geometry = geometry
    self.trajectoryGeometry = trajectoryGeometry

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSatelliteDescription::cleanup
    compile_opt idl2

end


;+
; Gets the id of this satellite.
;
; @returns id of this satellite.
;-
function SpdfSatelliteDescription::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the name of this satellite.
;
; @returns name of this satellite.
;-
function SpdfSatelliteDescription::getName
    compile_opt idl2

    return, self.name
end


;+
; Gets the resolution of this satellite.
;
; @returns resolution of this satellite.
;-
function SpdfSatelliteDescription::getResolution
    compile_opt idl2

    return, self.resolution
end


;+
; Gets the start time of this satellite.
;
; @returns start time of this satellite.
;-
function SpdfSatelliteDescription::getStartTime
    compile_opt idl2

    return, self.startTime
end


;+
; Gets the end time of this satellite.
;
; @returns end time of this satellite.
;-
function SpdfSatelliteDescription::getEndTime
    compile_opt idl2

    return, self.endTime
end


;+
; Gets the geometry of this satellite.
;
; @returns geometry of this satellite.
;-
function SpdfSatelliteDescription::getGeometry
    compile_opt idl2

    return, self.geometry
end


;+
; Gets the trajectory geometry of this satellite.
;
; @returns trajectory geometry of this satellite.
;-
function SpdfSatelliteDescription::getTrajectoryGeometry
    compile_opt idl2

    return, self.trajectoryGeometry
end


;+
; Prints a textual representation of this object.
;-
pro SpdfSatelliteDescription::print
    compile_opt idl2

    print, '  ', self.id, ': ', self.name
end


;+
; Defines the SpdfSatelliteDescription class.
;
; @field id ground station identifier.
; @field name ground station's name.
; @field resolution trajectory resolution.
; @field startTime julday start time value.
; @field endTime julday end time value.
; @field geometry satellite geometry.
; @field trajectoryGeometry trajectory geometry.
;-
pro SpdfSatelliteDescription__define
    compile_opt idl2
    struct = { SpdfSatelliteDescription, $
        id:'', $
        name:'', $
        resolution:0, $
        startTime:0d, $
        endTime:0d, $
        geometry:'', $
        trajectoryGeometry:'' $
    }
end
