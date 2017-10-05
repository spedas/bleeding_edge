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
;   http://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
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
; This file contains a procedure-oriented wrapper to a subset of
; functionality from the SpdfSsc class (IDL client interface to
; <a href="http://sscweb.gsfc.nasa.gov/WebServices">
; Satellite Situation Center Web Services</a> (SSC WSs)) library.
;
; @copyright Copyright (c) 2013 United States Government as 
;     represented by the National Aeronautics and Space 
;     Administration. No copyright is claimed in the United States 
;     under Title 17, U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Corrects the case of the given value.
;
; @private
;
; @param coordinateSystem {in} {type=string}
;            a coordinate system identifier.
; @returns a coordinate system identifier with the correct (camel)
;     case.  If the input value cannot be mapped to a valid coordinate
;     system value, then an empty string ('') is returned.
;-
function spdfFixCoordinateSystemCase, $
    coordinateSystem
    compile_opt idl2

    case strlowcase(coordinateSystem) of

    'geo'     : return, 'Geo'
    'gm'      : return, 'Gm'
    'gse'     : return, 'Gse'
    'gsm'     : return, 'Gsm'
    'sm'      : return, 'Sm'
    'geitod'  : return, 'GeiTod'
    'geij2000': return, 'GeiJ2000'
    else      : return, ''
    endcase

end

;+
; This function gets basic location information for a single satellite
; from <a href="http://www.nasa.gov/">NASA</a>'s
; <a href="http://spdf.gsfc.nasa.gov/">Space Physics Data Facility</a>
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>.
; More comprehensive information if available by using 
; <code>SpdfSsc::getLocations()</code>.
;
; @param satellite {in} {type=string}
;            identifies the satellite whose location is to be gotten.
; @param timeSpan {in} {type=strarr(2)}
;            ISO 8601 format strings of the start and stop times of the
;            data to get.
; @keyword coordinateSystem {in} {optional} {type=string} 
;            {default='Gse'}
;            specifies the coordinate system.  Must be one of the 
;            following values: Geo, Gm, Gsm, Sm, GeiTod, or GeiJ2000.
; @keyword quiet {in} {optional} {type=boolean} {default=false}
;            SpdfGetLocations normally prints an error message if no 
;            data is found.  If QUIET is set, no error messages is 
;            printed.
; @keyword httpErrorReporter {in} {optional}
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns SpdfLocations object containing requested data.
; @examples
;   <pre>
;     l = spdfGetLocations('ace', 
;           ['2013-01-01T00:00:00.000Z', '2013-01-03T00:00:00.000Z'])
;     p = plot3d(l->getX(), l->getY(), l->getZ(), window_title='Orbit')
;   </pre>
;-
function SpdfGetLocations, $
    satellite, $
    timeSpan, $
    coordinateSystem = coordinateSystem, $
    quiet = quiet, $
    httpErrorReporter = httpErrorReporter
    compile_opt idl2

    if keyword_set(coordinateSystem) then begin

        coordinateSystem = $
            spdfFixCoordinateSystemCase(coordinateSystem)

        if coordinateSystem eq '' then begin

            if ~keyword_set(quiet) then begin

                print, 'Invalid coordinateSystem value'
            endif

            return, obj_new()
        endif

    endif else begin

        coordinateSystem = 'Gse'
    endelse

    ssc = $
        obj_new('SpdfSsc', $
            endpoint = 'http://sscweb.gsfc.nasa.gov/WS/sscr/2', $
            userAgent = 'SpdfGetLocations/1.0')

    timeInterval = $
        obj_new('SpdfTimeInterval', timeSpan[0], timeSpan[1])

    if ~keyword_set(httpErrorReporter) then begin

        httpErrorReporter = obj_new('SpdfHttpErrorReporter')
    endif

    sats = objarr(1)

    sats[0] = obj_new('SpdfSatelliteSpecification', satellite, 2)

    coordinateOptions = objarr(5)
    coordinateOptions[0] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = coordinateSystem, component = 'X')
    coordinateOptions[1] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = coordinateSystem, component = 'Y')
    coordinateOptions[2] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = coordinateSystem, component = 'Z')
    coordinateOptions[3] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = coordinateSystem, component = 'Lat')
    coordinateOptions[4] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = coordinateSystem, component = 'Lon')

    outputOptions = $
        obj_new('SpdfOutputOptions', coordinateOptions)

    locationRequest = $
        obj_new('SpdfSscDataRequest', $
            timeInterval, $
            sats, $
            outputOptions, $
            description  = 'Locator request.')

    locations = $
        ssc->getLocations( $
            locationRequest, $
            httpErrorReporter = httpErrorReporter)

    statusCode = locations->getStatusCode()

    if statusCode eq 'Error' then begin

        if ~keyword_set(quiet) then begin

            print, 'status: ', statusCode
            subCode = locations->getStatusSubCode()
            print, 'statusSubCode: ', subCode
            statusText = locations->getStatusText()
            print, 'statusText: ', statusText
        endif

        return, obj_new()
    endif

    data = locations->getData()

    if ~obj_valid(data[0]) then begin

        if ~keyword_set(quiet) then begin

            print, 'No data returned'
            print, 'status: ', statusCode
            subCode = locations->getStatusSubCode()
            print, 'statusSubCode: ', subCode
            statusText = locations->getStatusText()
            print, 'statusText: ', statusText
        endif

        return, obj_new()
    endif

    id = data[0]->getId()
    time = data[0]->getTime()
    coordData = data[0]->getCoordinateData()
    coordinateSystem = coordData->getCoordinateSystem()
    x = coordData->getX()
    y = coordData->getY()
    z = coordData->getZ()
    lat = coordData->getLatitude()
    lon = coordData->getLongitude()
    localTime = coordData->getLocalTime()

    return, obj_new('SpdfLocations', $
        id, time, coordinateSystem, $
        x = x, y = y, z = z, $
        latitude = lat, longitude = lon, localTime = localTime)
end


