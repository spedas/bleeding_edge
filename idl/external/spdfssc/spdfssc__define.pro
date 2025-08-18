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
;   https://sscweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
;
; See the Agreement for the specific language governing permissions
; and limitations under the Agreement.
;
; When distributing Covered Code, include this NOSA HEADER in each
; file and include the Agreement file at 
; docs/NASA_Open_Source_Agreement_1.3.txt.  If applicable, add the 
; following below this NOSA HEADER, with the fields enclosed by 
; brackets "[]" replaced with your own identifying information: 
; Portions Copyright [yyyy] [name of copyright owner}
;
; NOSA HEADER END
;
; Copyright (c) 2013-2017 United States Government as represented by 
; the National Aeronautics and Space Administration. No copyright is 
; claimed in the United States under Title 17, U.S.Code. All Other 
; Rights Reserved.
;
;


;+
; This class represents the remotely callable interface to 
; <a href="https://www.nasa.gov/">NASA</a>'s
; <a href="https://spdf.gsfc.nasa.gov/">Space Physics Data Facility</a> 
; (SPDF)
; <a href="https://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>
; (SSC).  The current implementation only support the 
; <a href="https://sscweb.gsfc.nasa.gov/WebServices/REST/#Get_Locations_POST">
; "data locations" functionality</a>.  Supporting the "text (listing)
; locations", "conjunctions" and/or "graphs" functionality is a 
; future possibility if there were sufficient interest.
;
; @copyright Copyright (c) 2013-2017 United States Government as 
;     represented by the National Aeronautics and Space Administration.
;     No copyright is claimed in the United States under Title 17, 
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an object representing SSC.
;
; @keyword endpoint {in} {optional} {type=string}
;              {default=self->getDefaultEndpoint()}
;              URL of SSC web service .
; @keyword userAgent {in} {optional} {type=string} {default=WsExample}
;              HTTP user-agent value used in communications with SSC.
; @keyword sslVerifyPeer {in} {optional} {type=int} {default=1}
;              Specifies whether the authenticity of the peer's SSL
;              certificate should be verified.  When 0, the connection
;              succeeds regardless of what the peer SSL certificate
;              contains.
; @returns a reference to a SSC object.
;-
function SpdfSsc::init, $
    endpoint = endpoint, $
    userAgent = userAgent, $
    sslVerifyPeer = sslVerifyPeer
    compile_opt idl2

    version = '%VERSION*'
    currentVersionUrl = $
        'https://sscweb.gsfc.nasa.gov/WebServices/REST/spdfSscVersion.txt'

    if ~keyword_set(endpoint) then begin

        endpoint = self->getDefaultEndpoint()
    endif

    obj = self->SpdfRest::init( $
              endpoint, version, currentVersionUrl, $
              userAgent = userAgent + '/' + version, $
              sslVerifyPeer = sslVerifyPeer)

    return, obj
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSsc::cleanup
    compile_opt idl2

    self->SpdfRest::cleanup
end


;+
; Gets the default endpoint value.
;
; @returns default endpoint string value.
;-
function SpdfSsc::getDefaultEndpoint
    compile_opt idl2

    endpoint = 'http'

    releaseComponents = strsplit(!version.release, '.', /extract)

    if releaseComponents[0] ge '8' and $
       releaseComponents[1] ge '4' then begin

        ; Even though earlier versions of IDL are suppose to support
        ; https, they do not (at least they do not support https to
        ; cdaweb).

        endpoint = endpoint + 's'
    endif

    return, endpoint + '://sscweb.gsfc.nasa.gov/WS/sscr/2'
end


;+
; Gets a description of all the observatories that are available.
;
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfObservatoryDescription objects.
;-
function SpdfSsc::getObservatories, $
    httpErrorReporter=errorReporter
    compile_opt idl2

    url = self.endpoint + '/observatories'

    observatoryDom = $
        self->makeGetRequest(url, errorReporter=errorReporter)

    if ~obj_valid(observatoryDom) then return, objarr(1)

    observatoryElements = $
        observatoryDom->getElementsByTagName('Observatory')

    observatories = objarr(observatoryElements->getLength(), /nozero)

    for i = 0, observatoryElements->getLength() - 1 do begin

        observatoryElement = observatoryElements->item(i)

        id = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'Id')
        name = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'Name')
        resolution = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'Resolution')
        startTime = $
            self->getJulDate((observatoryElement->$
                getElementsByTagName('StartTime'))->item(0))
        endTime = $
            self->getJulDate((observatoryElement->$
                getElementsByTagName('EndTime'))->item(0))
        geometry = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'Geometry')
        trajectoryGeometry = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'TrajectoryGeometry')
        resourceId = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'ResourceId')
        groupIds = $
            self->getNamedElementsFirstChildValue( $
                observatoryElement, 'GroupId')

        observatories[i] = $
            obj_new('SpdfObservatoryDescription', id, name, $
                resolution, startTime, endTime, geometry, $
                trajectoryGeometry, resourceId, groupIds)
    endfor

    obj_destroy, observatoryDom

    return, observatories
end
    

;+
; Gets a description of all the ground stations that are available.
;
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfGroundStation objects.
;-
function SpdfSsc::getGroundStations, $
    httpErrorReporter=errorReporter
    compile_opt idl2

    url = self.endpoint + '/groundStations'

    gsDom = self->makeGetRequest(url, errorReporter=errorReporter)

    if ~obj_valid(gsDom) then return, objarr(1)

    gsElements = gsDom->getElementsByTagName('GroundStation')

    groundStations = objarr(gsElements->getLength(), /nozero)

    for i = 0, gsElements->getLength() - 1 do begin

        gsElement = gsElements->item(i)

        id = $
            self->getNamedElementsFirstChildValue(gsElement, 'Id')
        name = $
            self->getNamedElementsFirstChildValue(gsElement, 'Name')
        latitude = $
            self->getNamedElementsFirstChildValue( $
                gsElement, 'Latitude')
        longitude = $
            self->getNamedElementsFirstChildValue( $
                gsElement, 'Longitude')

        location = obj_new('SpdfSurfaceGeographicCoordinates', $
                       latitude, longitude)

        groundStations[i] = $
            obj_new('SpdfGroundStation', id, name, location)
    endfor

    obj_destroy, gsDom

    return, groundStations
end


;+
; Request the specified satellite location information from SSC.
;
; @private
;
; @param locationRequest {in} {type=SpdfLocationRequest}
;            specifies the information to get.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns an SpdfSscDataResult or SpdfSscFileResult object.
;-
function SpdfSsc::getLocations, $
    locationRequest, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    url = self.endpoint + '/locations'

    requestDoc = obj_new('IDLffXMLDOMDocument')

    requestDom = $
        requestDoc->appendChild( $
            locationRequest->createDomElement(requestDoc))

    requestDoc->save, string=xmlRequest

    obj_destroy, requestDoc

    resultDoc = self->makePostRequest(url, xmlRequest, $
                    errorReporter = errorReporter)

    if ~obj_valid(resultDoc) then return, obj_new()

    fileNodeList= resultDoc->getElementsByTagName('Files')

    if fileNodeList->getLength() eq 0 then begin

        dataResult = self->getDataResult(resultDoc)
    endif else begin

        dataResult = self->getFileResult(resultDoc)
    endelse

    obj_destroy, resultDoc

    return, dataResult
end


;+
; Gets the node's time values from the given DOM element.
;
; @private
;
; @param domElement {in} {required} {type=IDLffXMLDOMElement}
;                DOM element to search.
; @keyword name {in} {optional} {type=string} {default='Time'}
;              name of time tag.
; @returns node's julday time value(s) from the given DOM element.
;     A scalar value of !values.d_NaN is returned if no value is found.
;-
function SpdfSsc::getTime, $
    domElement, $
    name = name
    compile_opt idl2

    if keyword_set(name) then name = name else name = 'Time'

    nodeList = domElement->getElementsByTagName(name)

    if nodeList->getLength() eq 0 then return, !values.d_NaN

    values = dblarr(nodeList->getLength())

    for i = 0, nodeList->getLength() - 1 do begin

        domNode = nodeList->item(i)

        values[i] = self->getJulDate(domNode)
    endfor

    if n_elements(values) eq 1 then return, values[0] $
                               else return, values
end


;+
; Gets the specified node values from the given ssc:DataResult XML
; document.
;
; @private
;
; @param resultDoc {in} {type=IDLffXMLDOMDocument}
;            SpdfSscDataResult XML document.
; @param type {in} {type=string}
;            name of elements whose value is to be gotten.
; @returns strarr of the specified node values from the given document.
;-
function SpdfSsc::getDataResultText, $
    resultDoc, type
    compile_opt idl2

    return, self->getNamedElementsFirstChildValue(resultDoc, type)
end


;+
; Creates an SpdfSscFileResult object from the given ssc:DataResult
; XML document.
;
; @private
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;              SpdfSscDataResult XML document.
; @returns SpdfSscFileResult object.
;-
function SpdfSsc::getFileResult, $
    doc
    compile_opt idl2

; doc->save, filename='getFileResult.xml', /pretty_print

    statusCode = self->getDataResultText(doc, 'StatusCode')

    statusSubCode = self->getDataResultText(doc, 'StatusSubCode')

    statusText = self->getDataResultText(doc, 'StatusText')

    if statusCode eq '' then begin

        ; This will not be necessary when the server is fixed to
        ; include it in a FileResult (fix is in R2.2.7).
        statusCode = 'Success'
    endif
    if statusCode ne 'Success' then begin

        print, 'StatusCode: ', statusCode
        print, 'StatusSubCode: ', statusSubCode
        print, 'StatusText: ', statusText

        return, obj_new()
    endif

    files = self->getFiles(doc)

    fileResult = obj_new('SpdfSscFileResult', $
        files, $
        statusCode = statusCode, $
        statusSubCode = statusSubCode, $
        statusText = statusText)

    return, fileResult
end


;+
; Creates an array of SpdfFileDescription objects from the given 
; ssc:Files XML document.
;
; @private
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;              SpdfFileResult XML document.
; @returns objarr containing SpdfFileDescriptions or an objarr(1) whose
;     first element is ~obj_valid().
;-
function SpdfSsc::getFiles, $
    doc
    compile_opt idl2

; doc->save, filename='files.xml', /pretty_print

    filesElements = $
        doc->getElementsByTagName('Files')

    if filesElements->getLength() eq 0 then begin

        return, objarr(1)
    endif

    files = objarr(filesElements->getLength())

    for i = 0, filesElements->getLength() - 1 do begin

        filesElement = filesElements->item(i)

        name = self->getNamedElementsFirstChildValue( $
                   filesElement, 'Name')

        mimeType = self->getNamedElementsFirstChildValue( $
                       filesElement, 'MimeType')

        length = self->getNamedElementsFirstChildValue( $
                   filesElement, 'Length')

        lastModified = self->getTime(filesElement, name='LastModified')

        files[i] = obj_new('SpdfFileDescription', $
            name, $
            mimeType, $
            length, $
            lastModified)
    endfor

    return, files
end


;+
; Creates an SpdfSscDataResult object from the given ssc:DataResult
; XML document.
;
; @private
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;              SpdfSscDataResult XML document.
; @returns SpdfSscDataResult object.
;-
function SpdfSsc::getDataResult, $
    doc
    compile_opt idl2

doc->save, filename='getDataResult.xml', /pretty_print

    statusCode = self->getDataResultText(doc, 'StatusCode')

    statusSubCode = self->getDataResultText(doc, 'StatusSubCode')

    statusText = self->getDataResultText(doc, 'StatusText')

    if statusCode ne 'Success' then begin

        print, 'StatusCode: ', statusCode
        print, 'StatusSubCode: ', statusSubCode
        print, 'StatusText: ', statusText

        return, obj_new()
    endif

    data = self->getSatelliteData(doc)

    dataResult = obj_new('SpdfSscDataResult', $
        data, $
        statusCode = statusCode, $
        statusSubCode = statusSubCode, $
        statusText = statusText)

    return, dataResult
end


;+
; Creates an SpdfSatelliteData object from the given ssc:SatelliteData
; XML document.
;
; @private
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;              SpdfSatelliteData XML document.
; @returns objarr containing SpdfSatelliteData or an objarr(1) whose
;     first element is ~obj_valid().
;-
function SpdfSsc::getSatelliteData, $
    doc
    compile_opt idl2

; doc->save, filename='satData.xml', /pretty_print

    satDataElements = $
        doc->getElementsByTagName('Data')

    if satDataElements->getLength() eq 0 then begin

        return, objarr(1)
    endif

    satData = objarr(satDataElements->getLength())

    for i = 0, satDataElements->getLength() - 1 do begin

        satDataElement = satDataElements->item(i)

        id = $
            self->getNamedElementsFirstChildValue( $
                satDataElement, 'Id')

        coordinateData = $
            self->getCoordinateData(satDataElement)

        time = self->getTime(satDataElement)

        bTraceData = self->getBTraceData(satDataElement)

        radialLength = $
            self->getDoubleSatelliteData( $
                satDataElement, 'RadialLength')

        magneticStrength = $
            self->getDoubleSatelliteData( $
                satDataElement, 'MagneticStrength')

        neutralSheetDistance = $
            self->getDoubleSatelliteData( $
                satDataElement, 'NeutralSheetDistance')

        bowShockDistance = $
            self->getDoubleSatelliteData( $
                satDataElement, 'BowShockDistance')

        magnetoPauseDistance = $
            self->getDoubleSatelliteData( $
                satDataElement, 'MagnetoPauseDistance')

        dipoleLValue = $
            self->getDoubleSatelliteData( $
                satDataElement, 'DipoleLValue')

        dipoleInvariantLatitude = $
            self->getFloatSatelliteData( $
                satDataElement, 'DipoleInvariantLatitude')

        spacecraftRegion = $
            self->getSatelliteRegionData( $
                satDataElement, 'SpacecraftRegion')

        radialTracedFootpointRegions = $
            self->getSatelliteRegionData( $
                satDataElement, 'RadialTracedFootpointRegions')

        bGseX = $
            self->getDoubleSatelliteData(satDataElement, 'BGseX')

        bGseY = $
            self->getDoubleSatelliteData(satDataElement, 'BGseY')

        bGseZ = $
            self->getDoubleSatelliteData(satDataElement, 'BGseZ')

        northBTracedFootpointRegions = $
            self->getSatelliteRegionData( $
                satDataElement, 'NorthBTracedFootpointRegions')

        southBTracedFootpointRegions = $
            self->getSatelliteRegionData( $
                satDataElement, 'SouthBTracedFootpointRegions')

        satData[i] = obj_new('SpdfSatelliteData', $
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
            radialTracedFootpointRegions = $
                radialTracedFootpointRegions, $
            bGseX = bGseX, $
            bGseY = bGseY, $
            bGseZ = bGseZ, $
            northBTracedFootpointRegions = $
                northBTracedFootpointRegions, $
            southBTracedFootpointRegions = $
                southBTracedFootpointRegions)
    endfor

    return, satData
end


;+
; Creates an SpdfCoordinateData object from the given ssc:SatelliteData
; XML element.
;
; @private
;
; @param satDataElement {in} {type=IDLffXMLDOMElement}
;              SpdfSatelliteData XML element.
; @returns SpdfCoordinateData object.
;-
function SpdfSsc::getCoordinateData, $
    satDataElement
    compile_opt idl2

    nodeList = satDataElement->getElementsByTagName('Coordinates')

    if nodeList->getLength() eq 0 then return, obj_new()

    coordinatesElement = nodeList->item(0)

    coordinateSystem = $
        self->getNamedElementsFirstChildValue( $
            coordinatesElement, 'CoordinateSystem')

    x = self->getNamedElementsFirstChildDoubleValue( $
            coordinatesElement, 'X')

    y = self->getNamedElementsFirstChildDoubleValue( $
            coordinatesElement, 'Y')

    z = self->getNamedElementsFirstChildDoubleValue( $
            coordinatesElement, 'Z')

    latitude = self->getNamedElementsFirstChildFloatValue( $
            coordinatesElement, 'Latitude')

    longitude = self->getNamedElementsFirstChildFloatValue( $
            coordinatesElement, 'Longitude')

    localTime = self->getNamedElementsFirstChildDoubleValue( $
            coordinatesElement, 'LocalTime')

    coordinateData = $
        obj_new('SpdfCoordinateData', $
            coordinateSystem, $
            x = x, $
            y = y, $
            z = z, $
            latitude = latitude, $
            longitude = longitude, $
            localTime = localTime)

    return, coordinateData
end


;+
; Creates an SpdfBTraceData object from the given ssc:BTraceData
; XML element.
;
; @private
;
; @param satDataElement {in} {type=IDLffXMLDOMElement}
;              SpdfSatelliteData XML element.
; @returns SpdfCoordinateData object.
;-
function SpdfSsc::getBTraceData, $
    satDataElement
    compile_opt idl2

    bTraceDataElements = $
        satDataElement->getElementsByTagName('BTraceData')

    if bTraceDataElements->getLength() eq 0 then begin

        return, objarr(1)
    endif

    bTraceData = objarr(bTraceDataElements->getLength())

    for i = 0, bTraceDataElements->getLength() - 1 do begin

        bTraceDataElement = bTraceDataElements->item(i)

        coordinateSystem = $
            self->getNamedElementsFirstChildValue( $
                bTraceDataElement, 'CoordinateSystem')

        hemisphere = $
            self->getNamedElementsFirstChildValue( $
                bTraceDataElement, 'Hemisphere')

        latitude = self->getNamedElementsFirstChildFloatValue( $
                bTraceDataElement, 'Latitude')

        longitude = self->getNamedElementsFirstChildFloatValue( $
                bTraceDataElement, 'Longitude')

        arcLength = self->getNamedElementsFirstChildDoubleValue( $
                bTraceDataElement, 'ArcLength')

        bTraceData[i] = $
            obj_new('SpdfBTraceData', $
                coordinateSystem, $
                hemisphere, $
                latitude = latitude, $
                longitude = longitude, $
                arcLength = arcLength)
    endfor

    return, bTraceData
end


;+
; Gets the specified double data values from the given satellite data.
;
; @private
;
; @param satDataElement {in} {type=IDLffXMLDOMElement}
;              Satellite XML element.
; @param name {in} {type=string}
;            name of satellite data to get.
; @returns array of double values.
;-
function SpdfSsc::getDoubleSatelliteData, $
    satDataElement, $
    name
    compile_opt idl2

    values = self->getNamedElementsFirstChildDoubleValue( $
            satDataElement, name)

    return, values
end


;+
; Gets the specified float data values from the given satellite data.
;
; @private
;
; @param satDataElement {in} {type=IDLffXMLDOMElement}
;              Satellite XML element.
; @param name {in} {type=string}
;            name of satellite data to get.
; @returns array of float values.
;-
function SpdfSsc::getFloatSatelliteData, $
    satDataElement, $
    name
    compile_opt idl2

    values = self->getNamedElementsFirstChildFloatValue( $
            satDataElement, name)

    return, values
end


;+
; Gets the specified region data values from the given satellite data.
;
; @private
;
; @param satDataElement {in} {type=IDLffXMLDOMElement}
;              Satellite XML element.
; @param name {in} {type=string}
;            name of region data to get.
; @returns strarr of region values.  An empty string is returned 
;     if the value cannot be found.
;-
function SpdfSsc::getSatelliteRegionData, $
    satDataElement, $
    name
    compile_opt idl2

    values = self->getNamedElementsFirstChildValue( $
                satDataElement, name)

    return, values
end


;+
; Defines the SpdfSsc class.
;
;-
pro SpdfSsc__define
    compile_opt idl2
    struct = { SpdfSsc, $
        inherits SpdfRest $
    }
end
