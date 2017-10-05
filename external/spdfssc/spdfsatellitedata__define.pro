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
; This class is an IDL representation of the SatelliteData
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
; Creates an SpdfSatelliteData object.
;
; @param id {in} {type=string}
;            satellite identifier.
; @param coordinateData {in} {type=SpdfCoordinateData}
;              satellite coordinate data.
; @param time {in} {type=dblarr}
;              julday time associated with each data point.
; @keyword bTraceData {in} {optional} {type=SpdfBTraceData}
;              magnetic field trace data.
; @keyword radialLength {in} {optional} {type=dblarr}
;              distance from center of Earth.
; @keyword magneticStrength {in} {optional} {type=dblarr}
;              magnetic field strength.
; @keyword neutralSheetDistance {in} {optional} {type=dblarr}
;              distance from neutral sheet.
; @keyword bowShockDistance {in} {optional} {type=dblarr}
;              distance from bow shock.
; @keyword magnetoPauseDistance {in} {optional} {type=dblarr}
;              distance from magneto pause.
; @keyword dipoleLValue {in} {optional} {type=dblarr}
;              dipole L values.
; @keyword dipoleInvariantLatitude {in} {optional} {type=dblarr}
;              dipole invariant latitude values.
; @keyword spacecraftRegion {in} {optional} {type=strarr}
;              spacecraft region.
; @keyword radialTracedFootpointRegions {in} {optional} {type=strarr}
;              radial traced footpoint region.
; @keyword bGseX {in} {optional} {type=dblarr}
;              B GSE X values.
; @keyword bGseY {in} {optional} {type=dblarr}
;              B GSE Y values.
; @keyword bGseZ {in} {optional} {type=dblarr}
;              B GSE Z values.
; @keyword northBTracedFootpointRegions {in} {optional} {type=strarr}
;              north B traced regions.
; @keyword southBTracedFootpointRegions {in} {optional} {type=strarr}
;              south B traced regions.
; @returns reference to an SpdfSatelliteData object.
;-
function SpdfSatelliteData::init, $
    id, $
    coordinateData, $
    time, $
    bTraceData = bTraceData, $
    radialLength = radialLength, $
    magneticStrength = magneticStrength, $
    neutralSheetDistance = neutralSheetDistance, $
    bowShockDistance = bowShockDistance, $
    magnetoPauseDistance = magnetoPauseDistance, $
    dipoleLValue = dipoleLValue, $
    dipoleInvariantLatitude = dipoleInvariantLatitude, $
    spacecraftRegion = spacecraftRegion, $
    radialTracedFootpointRegions = radialTracedFootpointRegions, $
    bGseX = bGseX, $
    bGseY = bGseY, $
    bGseZ = bGseZ, $
    northBTracedFootpointRegions = northBTracedFootpointRegions, $
    southBTracedFootpointRegions = southBTracedFootpointRegions
    compile_opt idl2

    self.id = id
    self.coordinateData = ptr_new(coordinateData)
    self.time = ptr_new(time)

    if keyword_set(bTraceData) then $
        self.bTraceData = ptr_new(bTraceData)
    if keyword_set(radialLength) then $
        self.radialLength = ptr_new(radialLength)
    if keyword_set(magneticStrength) then $
        self.magneticStrength = ptr_new(magneticStrength)
    if keyword_set(neutralSheetDistance) then $
        self.neutralSheetDistance = ptr_new(neutralSheetDistance)
    if keyword_set(bowShockDistance) then $
        self.bowShockDistance = ptr_new(bowShockDistance)
    if keyword_set(magnetoPauseDistance) then $
        self.magnetoPauseDistance = ptr_new(magnetoPauseDistance)
    if keyword_set(dipoleLValue) then $
        self.dipoleLValue = ptr_new(dipoleLValue)
    if keyword_set(dipoleInvariantLatitude) then $
        self.dipoleInvariantLatitude = ptr_new(dipoleInvariantLatitude)
    if keyword_set(spacecraftRegion) then $
        self.spacecraftRegion = ptr_new(spacecraftRegion)
    if keyword_set(radialTracedFootpointRegions) then begin

        self.radialTracedFootpointRegions = $
            ptr_new(radialTracedFootpointRegions)
    endif
    if keyword_set(bGseX) then self.bGseX = ptr_new(bGseX)
    if keyword_set(bGseY) then self.bGseY = ptr_new(bGseY)
    if keyword_set(bGseZ) then self.bGseZ = ptr_new(bGseZ)
    if keyword_set(northBTracedFootpointRegions) then $
        self.northBTracedFootpointRegions = ptr_new(northBTracedFootpointRegions)
    if keyword_set(southBTracedFootpointRegions) then $
        self.southBTracedFootpointRegions = ptr_new(southBTracedFootpointRegions)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSatelliteData::cleanup
    compile_opt idl2

    if ptr_valid(self.coordinateData) then $
        ptr_free, self.coordinateData
    if ptr_valid(self.time) then ptr_free, self.time
    if ptr_valid(self.bTraceData) then $
        ptr_free, self.bTraceData
    if ptr_valid(self.radialLength) then $
        ptr_free, self.radialLength
    if ptr_valid(self.magneticStrength) then $
        ptr_free, self.magneticStrength
    if ptr_valid(self.neutralSheetDistance) then $
        ptr_free, self.neutralSheetDistance
    if ptr_valid(self.bowShockDistance) then $
        ptr_free, self.bowShockDistance
    if ptr_valid(self.magnetoPauseDistance) then $
        ptr_free, self.magnetoPauseDistance
    if ptr_valid(self.dipoleLValue) then $
        ptr_free, self.dipoleLValue
    if ptr_valid(self.dipoleInvariantLatitude) then $
        ptr_free, self.dipoleInvariantLatitude
    if ptr_valid(self.spacecraftRegion) then $
        ptr_free, self.spacecraftRegion
    if ptr_valid(self.radialTracedFootpointRegions) then $
        ptr_free, self.radialTracedFootpointRegions
    if ptr_valid(self.bGseX) then ptr_free, self.bGseX
    if ptr_valid(self.bGseY) then ptr_free, self.bGseY
    if ptr_valid(self.bGseZ) then ptr_free, self.bGseZ
    if ptr_valid(self.northBTracedFootpointRegions) then $
        ptr_free, self.northBTracedFootpointRegions
    if ptr_valid(self.southBTracedFootpointRegions) then $
        ptr_free, self.southBTracedFootpointRegions

end


;+
; Gets the id value.
;
; @returns id value.
;-
function SpdfSatelliteData::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the coordinate data.
;
; @returns a reference to coordinate data.
;-
function SpdfSatelliteData::getCoordinateData
    compile_opt idl2

    if ptr_valid(self.coordinateData) then begin

        return, *self.coordinateData
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the time values.
;
; @returns the time values.
;-
function SpdfSatelliteData::getTime
    compile_opt idl2

    if ptr_valid(self.time) then begin

        return, *self.time
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the B field trace data.
;
; @returns a reference to SpdfBTraceData.
;-
function SpdfSatelliteData::getBTraceData
    compile_opt idl2

    if ptr_valid(self.bTraceData) then begin

        return, *self.bTraceData
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the radial length values.
;
; @returns a dblarr containing radial length values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getRadialLength
    compile_opt idl2

    if ptr_valid(self.radialLength) then begin

        return, *self.radialLength
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the magnetic strength values.
;
; @returns a dblarr containing magnetic strength values or the 
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getMagneticStrength
    compile_opt idl2

    if ptr_valid(self.magneticStrength) then begin

        return, *self.magneticStrength
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the neutral sheet distance values.
;
; @returns a dblarr containing neutral sheet distance values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getNeutralSheetDistance
    compile_opt idl2

    if ptr_valid(self.neutralSheetDistance) then begin

        return, *self.neutralSheetDistance
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the bow shock distance values.
;
; @returns a dblarr containing bow shock distance values or the
;     constant scaler !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getBowShockDistance
    compile_opt idl2

    if ptr_valid(self.bowShockDistance) then begin

        return, *self.bowShockDistance
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the magneto pause distance values.
;
; @returns a dblarr containing magneto pause distance values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getMagnetoPauseDistance
    compile_opt idl2

    if ptr_valid(self.magnetoPauseDistance) then begin

        return, *self.magnetoPauseDistance
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the dipole L values.
;
; @returns a dblarr containing dipole L values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getDipoleLValue
    compile_opt idl2

    if ptr_valid(self.dipoleLValue) then begin

        return, *self.dipoleLValue
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the dipole invariant latitude values.
;
; @returns a dblarr containing dipole invariant latitude values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getDipoleInvariantLatitude
    compile_opt idl2

    if ptr_valid(self.dipoleInvariantLatitude) then begin

        return, *self.dipoleInvariantLatitude
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the spacecraft region values.
;
; @returns a strarr containing spacecraft region values or the
;     constant scalar '' if there are no values.
;-
function SpdfSatelliteData::getSpacecraftRegion
    compile_opt idl2

    if ptr_valid(self.spacecraftRegion) then begin

        return, *self.spacecraftRegion
    endif else begin

        return, ''
    endelse
end


;+
; Gets the radial trace footpoint region values.
;
; @returns a strarr containing radial trace footpoint region values or
;     the constant scalar '' if there are no values.
;-
function SpdfSatelliteData::getRadialTracedFootpointRegions
    compile_opt idl2

    if ptr_valid(self.radialTracedFootpointRegions) then begin

        return, *self.radialTracedFootpointRegions
    endif else begin

        return, ''
    endelse
end


;+
; Gets the B GSE X values.
;
; @returns a dblarr containing B GSE X values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getBGseX
    compile_opt idl2

    if ptr_valid(self.bGseX) then begin

        return, *self.bGseX
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the B GSE Y values.
;
; @returns a dblarr containing B GSE Y values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getBGseY
    compile_opt idl2

    if ptr_valid(self.bGseY) then begin

        return, *self.bGseY
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the B GSE Z values.
;
; @returns a dblarr containing B GSE Z values or the
;     constant scalar !values.d_NaN if there are no values.
;-
function SpdfSatelliteData::getBGseZ
    compile_opt idl2

    if ptr_valid(self.bGseZ) then begin

        return, *self.bGseZ
    endif else begin

        return, !values.d_NaN
    endelse
end


;+
; Gets the north B traced regions values.
;
; @returns a strarr containing north B traced regions values or the
;     constant scalar '' if there are no values.
;-
function SpdfSatelliteData::getNorthBTracedFootpointRegions
    compile_opt idl2

    if ptr_valid(self.northBTracedFootpointRegions) then begin

        return, *self.northBTracedFootpointRegions
    endif else begin

        return, ''
    endelse
end


;+
; Gets the south B traced regions values.
;
; @returns a strarr containing south B traced regions values or the
;     constant scalar '' if there are no values.
;-
function SpdfSatelliteData::getSouthBTracedFootpointRegions
    compile_opt idl2

    if ptr_valid(self.southBTracedFootpointRegions) then begin

        return, *self.southBTracedFootpointRegions
    endif else begin

        return, ''
    endelse
end


;+
; Defines the SpdfSatelliteData class.
;
; @field id satellite identifier.
; @field coordinateData satellite coordinate data.
; @field time time associated with each data point.
; @field bTraceData magnetic field trace data.
; @field radialLength distance from center of Earth.
; @field magneticStrength magnetic field strength.
; @field neutralSheetDistance distance from neutral sheet.
; @field bowShockDistance distance from bow shock.
; @field magnetoPauseDistance distance from magneto pause.
; @field dipoleLValue dipole L values.
; @field dipoleInvariantLatitude dipole invariant latitude values.
; @field spacecraftRegion spacecraft region.
; @field radialTracedFootpointRegions radial trace footpoint region.
; @field bGseX B GSE X values.
; @field bGseY B GSE Y values.
; @field bGseZ B GSE Z values.
; @field northBTracedFootpointRegions north B traced regions.
; @field southBTracedFootpointRegions south B traced regions.
;-
pro SpdfSatelliteData__define
    compile_opt idl2
    struct = { SpdfSatelliteData, $
        id:'', $
        coordinateData:ptr_new(), $
        time:ptr_new(), $
        bTraceData:ptr_new(), $
        radialLength:ptr_new(), $
        magneticStrength:ptr_new(), $
        neutralSheetDistance:ptr_new(), $
        bowShockDistance:ptr_new(), $
        magnetoPauseDistance:ptr_new(), $
        dipoleLValue:ptr_new(), $
        dipoleInvariantLatitude:ptr_new(), $
        spacecraftRegion:ptr_new(), $
        radialTracedFootpointRegions:ptr_new(), $
        bGseX:ptr_new(), $
        bGseY:ptr_new(), $
        bGseZ:ptr_new(), $
        northBTracedFootpointRegions:ptr_new(), $
        southBTracedFootpointRegions:ptr_new() $
    }
end
