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
; This program is an example to demonstrate calling the
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center's</a>
; <a href="http://sscweb.gsfc.nasa.gov/WebServices/REST/">
; REST Web Services</a> from an 
; <a href="http://www.exelisvis.com/">Exelis Visual Information 
; Solutions</a>
; (VIS) Interactive Data Language (IDL) program.  It demonstrates the 
; following:
;   <ul>
;     <li>Getting the available observatories.</li>
;     <li>Getting the available ground stations.</li>
;     <li>Getting and displaying satellite location data.</li>
;     <li>Some basic HTTP error handling.</li>
;   </ul>
;
; @copyright Copyright (c) 2013 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-



;+
; This procedure is an example to demonstrate calling the SSC REST
; Web Services from an IDL program.  It demonstrates the following:
;   <ul>
;     <li>Getting the available observatories.</li>
;     <li>Getting the available ground stations.</li>
;     <li>Getting and displaying satellite location data.</li>
;     <li>Some basic HTTP error handling.</li>
;   </ul>
;-
pro SpdfSscWsExample
    compile_opt idl2

    ssc = $
        obj_new('SpdfSsc', $
            endpoint = 'http://sscweb.gsfc.nasa.gov/WS/sscr/2', $
;            endpoint = 'http://localhost:8084/WS/sscr/2', $
            userAgent = 'WsExample/1.0')

    errReporter = obj_new('SpdfHttpErrorReporter');

    observatories = $
        ssc->getObservatories(httpErrorReporter = errReporter)

    print, 'Observatories:'
    for i = 0, n_elements(observatories) - 1 do begin

        id = (observatories[i])->getId()
        name = (observatories[i])->getName()
        spaseId = (observatories[i])->getResourceId()

        print, '  ', id, '  ', name, '  ', spaseId

        spaseGroupIds = (observatories[i])->getGroupIds()

        for j = 0, n_elements(spaseGroupIds) - 1 do begin

            if strlen(spaseGroupIds[j]) gt 0 then begin

                print, '    ', spaseGroupIds[j]
            endif
        endfor
    endfor
    print

    obj_destroy, observatories

    groundStations = $
        ssc->getGroundStations(httpErrorReporter = errReporter)

    print, 'Ground Stations:'
    for i = 0, n_elements(groundStations) - 1 do begin

        location = (groundStations[i])->getLocation()
        latitude = location->getLatitude()
        longitude = location->getLongitude()

        print, '  ', (groundStations[i])->getId(), '  ', $
            (groundStations[i])->getName(), '  ', latitude, $
            '  ', longitude
    endfor
    print

    obj_destroy, groundStations

    timeInterval = $
        obj_new('SpdfTimeInterval', $
            julday(1, 2, 2008, 11, 0, 0), $
            julday(1, 2, 2008, 11, 30, 0))

    sats = objarr(2)

    sats[0] = obj_new('SpdfSatelliteSpecification', 'themisa', 2)
    sats[1] = obj_new('SpdfSatelliteSpecification', 'themisb', 2)

    coordinateOptions = objarr(6)
    coordinateOptions[0] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = 'Gse', component = 'X')
    coordinateOptions[1] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = 'Gse', component = 'Y')
    coordinateOptions[2] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = 'Gse', component = 'Z')
    coordinateOptions[3] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = 'Gse', component = 'Lat')
    coordinateOptions[4] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = 'Gse', component = 'Lon')
    coordinateOptions[5] = $
        obj_new('SpdfCoordinateOptions', $
            coordinateSystem = 'Gse', component = 'Local_Time')


    regionOptions = $
        obj_new('SpdfRegionOptions', $
            /spacecraft, /radialTracedFootpoint, $
            /northBTracedFootpoint, /southBTracedFootpoint)

    valueOptions = $
        obj_new('SpdfValueOptions', $
            /radialDistance, /bFieldStrength, $
            /dipoleLValue, /dipoleInvLat)

    distanceFromOptions = $
        obj_new('SpdfDistanceFromOptions', $
            /neutralSheet, /bowShock, /mPause, /bGseXYZ)

    bFieldTraceOptions = objarr(2)

    bFieldTraceOptions[0] = $
        obj_new('SpdfBFieldTraceOptions', $
            coordinateSystem = 'Geo', $
            hemisphere = 'North', $
            /footpointLatitude, /footpointLongitude, /fieldLineLength)

    bFieldTraceOptions[1] = $
        obj_new('SpdfBFieldTraceOptions', $
            coordinateSystem = 'Geo', $
            hemisphere = 'South', $
            /footpointLatitude, /footpointLongitude, /fieldLineLength)

    outputOptions = $
        obj_new('SpdfOutputOptions', $
            coordinateOptions, $
            /allLocationFilters, $
            regionOptions = regionOptions, $
            valueOptions = valueOptions, $
            distanceFromOptions = distanceFromOptions, $
            minMaxPoints = 2, $
            bFieldTraceOptions = bFieldTraceOptions)

    bFieldModel = obj_new('SpdfTsyganenko96BFieldModel')

    locationRequest = $
        obj_new('SpdfSscDataRequest', $
            timeInterval, $
            sats, $
            outputOptions, $
            description  = 'Simple locator request.', $
            bFieldModel = bFieldModel)

    locations = $
        ssc->getLocations( $
            locationRequest, $
            httpErrorReporter = errReporter)

    statusCode = locations->getStatusCode()

    if statusCode eq 'Error' then begin

        print, 'status: ', statusCode
        subCode = locations->getStatusSubCode()
        print, 'statusSubCode: ', subCode
        statusText = locations->getStatusText()
        print, 'statusText: ', statusText
    endif

    data = locations->getData()

    if ~obj_valid(data[0]) then begin

        print, 'No data returned'
        print, 'status: ', statusCode
        subCode = locations->getStatusSubCode()
        print, 'statusSubCode: ', subCode
        statusText = locations->getStatusText()
        print, 'statusText: ', statusText

        return
    endif

    for i = 0, n_elements(data) - 1 do begin
    
        id = data[i]->getId()
        print, "Satellite: ", id

        time = data[i]->getTime()
        coordData = data[i]->getCoordinateData()
        coordinateSystem = coordData->getCoordinateSystem()
        x = coordData->getX()
        y = coordData->getY()
        z = coordData->getZ()
        lat = coordData->getLatitude()
        lon = coordData->getLongitude()
        localTime = coordData->getLocalTime()

        bTraceData = data[i]->getBTraceData()
        radialLength = data[i]->getRadialLength()
        magneticStrength = data[i]->getMagneticStrength()
        bGseX = data[i]->getBGseX()
        bGseY = data[i]->getBGseY()
        bGseZ = data[i]->getBGseZ()
        neutralSheetDistance = data[i]->getNeutralSheetDistance()
        bowshockDistance = data[i]->getBowShockDistance()
        magnetoPauseDistance = data[i]->getMagnetoPauseDistance()
        dipoleLValue = data[i]->getDipoleLValue()
        dipoleInvariantLatitude = data[i]->getDipoleInvariantLatitude()
        spacecraftRegions = data[i]->getSpacecraftRegion()
        radialTracedFootpointRegions = $
            data[i]->getRadialTracedFootpointRegions()
        northBTracedFootpointRegions = $
            data[i]->getNorthBTracedFootpointRegions()
        southBTracedFootpointRegions = $
            data[i]->getSouthBTracedFootpointRegions()

        print, ''
        print, 'Coordinate System: ', strupcase(coordinateSystem)
        print, 'Time                 X               Y              Z'
        for j = 0, n_elements(time) - 1 do begin
 
            caldat, time[j], month, day, year, hour, min, sec

            print, $
                format='(%"%d-%02d-%02dT%02d:%02d:%02dZ %f, %f, %f")', $
                year, month, day, hour, min, sec, x[j], y[j], z[j]
        endfor

        print, ''
        print, 'Coordinate System: ', strupcase(coordinateSystem)
        print, 'Time                 Latitude    Longitude  Local Time'
        for j = 0, n_elements(time) - 1 do begin
 
            caldat, time[j], month, day, year, hour, min, sec

            print, $
                format='(%"%d-%02d-%02dT%02d:%02d:%02dZ %f, %f, %f")', $
                year, month, day, hour, min, sec, lat[j], lon[j], $
                localTime[j]
        endfor

        for k = 0, n_elements(bTraceData) - 1 do begin

            print, ''
            print, 'Magnetic Field Trace Information'
            print, 'Coordinate System: ', $
                       strupcase(bTraceData[k]->getCoordinateSystem())
            print, 'Hemisphere: ', bTraceData[k]->getHemisphere()
            lat = bTraceData[k]->getLatitude()
            lon = bTraceData[k]->getLongitude()
            arcLen = bTraceData[k]->getArcLength()
            print, 'Time                 Latitude    Longitude   Arc Length'
            for j = 0, n_elements(lat) - 1 do begin
 
                caldat, time[j], month, day, year, hour, min, sec

                print, format='(%"%d-%02d-%02dT%02d:%02d:%02dZ  %f  %f  %f")', $
                    year, month, day, hour, min, sec, $
                    lat[j], lon[j], arcLen[j]
            endfor
        endfor

        print, ''
        print, '                                         Footpoint Regions'
        print, '                     Space                       Magnetic Field'
        print, 'Time                 Region         Radial     North       South'
        for j = 0, n_elements(time) - 1 do begin
 
            caldat, time[j], month, day, year, hour, min, sec

            print, format='(%"%d-%02d-%02dT%02d:%02d:%02dZ  %s  %s  %s  %s")', $
                year, month, day, hour, min, sec, $
                spacecraftRegions[j], radialTracedFootpointRegions[j], $
                northBTracedFootpointRegions[j], $
                southBTracedFootpointRegions[j]
        endfor


        print, ''
        print, '                      Radial        Dipole      Invariant '
        print, 'Time                  Length        L Value     Latitude'
        for j = 0, n_elements(time) - 1 do begin
 
            caldat, time[j], month, day, year, hour, min, sec

            print, format='(%"%d-%02d-%02dT%02d:%02d:%02dZ  %e  %e  %e")', $
                year, month, day, hour, min, sec, $
                radialLength[j], $
                dipoleLValue[j], dipoleInvariantLatitude[j]
        endfor


        print, ''
        print, '                            Magnetic Field '
        print, '                                            GSE'
        print, 'Time                  Strength   X           Y          Z
        for j = 0, n_elements(time) - 1 do begin
 
            caldat, time[j], month, day, year, hour, min, sec

            print, format='(%"%d-%02d-%02dT%02d:%02d:%02dZ  %f  %f  %f  %f")', $
                year, month, day, hour, min, sec, $
                magneticStrength[j], bGseX[j], bGseY[j], bGseZ[j]
        endfor

        print, ''
        print, '                               Distances to    '
        print, '                      Neutral                       Magneto'
        print, 'Time                  Sheet          Bowshock       Pause'
        for j = 0, n_elements(time) - 1 do begin
 
            caldat, time[j], month, day, year, hour, min, sec

            print, format='(%"%d-%02d-%02dT%02d:%02d:%02dZ  %e  %e  %e  %e  %e  %e  %e")', $
                year, month, day, hour, min, sec, $
                neutralSheetDistance[j], bowshockDistance[j], $
                magnetoPauseDistance[j]
        endfor

;        p = plot3d(x, y, z, /overplot, window_title='Orbit')

    endfor


    obj_destroy, ssc
end

