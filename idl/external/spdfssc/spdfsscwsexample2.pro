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
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2017 United States Government as represented by 
; the National Aeronautics and Space Administration. No copyright is 
; claimed in the United States under Title 17, U.S.Code. All Other 
; Rights Reserved.
;
;


;+
; This program is an example to demonstrate calling the
; <a href="https://sscweb.gsfc.nasa.gov/">Satellite Situation Center's</a>
; <a href="https://sscweb.gsfc.nasa.gov/WebServices/REST/">
; REST Web Services</a> from an 
; <a href="http://www.harrisgeospatial.com/">Exelis Visual Information 
; Solutions</a>
; (VIS) Interactive Data Language (IDL) program.  It demonstrates the 
; following:
;   <ul>
;     <li>Using a JSON representation for the request and response 
;         entity body.</li>
;     <li>Requesting the magnetic conjunction of a set of satellites.</li>
;   </ul>
;
; @copyright Copyright (c) 2017 United States Government as 
;     represented by the National Aeronautics and Space Administration.
;     No copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-




;+
; This procedure is an example to demonstrate calling the SSC REST
; Web Services from an IDL program.  It demonstrates the following:
;   <ul>
;     <li>Using a JSON representation for the request and response 
;         entity body.</li>
;     <li>Requesting the magnetic conjunction of a set of satellites.</li>
;   </ul>
; @requires 8.2
;-
pro SpdfSscWsExample2
    compile_opt idl2

    conjunctionReq = '{' + $
        '"Request": {' + $
            '"BfieldModel": {' + $
                '"ExternalBFieldModel": {' + $
                    '"@class": "gov.nasa.gsfc.sscweb.schema.Tsyganenko89CBFieldModel",' + $
                    '"KeyParameterValues": "KP_3_3_3"' + $
                '},' + $
                '"InternalBFieldModel": "IGRF",' + $
                '"TraceStopAltitude": 1' + $
            '},' + $
            '"ConditionOperator": "ALL",' + $
            '"Conditions": [' + $
                '"java.util.ArrayList",' + $
                '[' + $
                    '{' + $
                        '"@class": "gov.nasa.gsfc.sscweb.schema.SatelliteCondition",' + $
                        '"Satellite": [' + $
                            '"java.util.ArrayList",' + $
                            '[' + $
                                '{' + $
                                    '"BfieldTraceDirection": "SOUTH_HEMISPHERE",' + $
                                    '"Id": "barrel1a"' + $
                                '},' + $
                                '{' + $
                                    '"BfieldTraceDirection": "SOUTH_HEMISPHERE",' + $
                                    '"Id": "rbspa"' + $
                                '},' + $
                                '{' + $
                                    '"BfieldTraceDirection": "SOUTH_HEMISPHERE",' + $
                                    '"Id": "rbspb"' + $
                                '}' + $
                            ']' + $
                        '],' + $
                        '"SatelliteCombination": 1' + $
                    '},' + $
                    '{' + $
                        '"@class": "gov.nasa.gsfc.sscweb.schema.LeadSatelliteCondition",' + $
                        '"ConjunctionArea": {' + $
                            '"@class": "gov.nasa.gsfc.sscweb.schema.BoxConjunctionArea",' + $
                            '"CoordinateSystem": "GEO",' + $
                            '"DeltaLatitude": 3.0,' + $
                            '"DeltaLongitude": 10.0' + $
                        '},' + $
                        '"Satellite": [' + $
                            '"java.util.ArrayList",' + $
                            '[' + $
                                '{' + $
                                    '"BfieldTraceDirection": "SOUTH_HEMISPHERE",' + $
                                    '"Id": "barrel1a"' + $
                                '}' + $
                            ']' + $
                        '],' + $
                        '"TraceType": "B_FIELD"' + $
                    '}' + $
                ']' + $
            '],' + $
            '"Description": "Magnetic conjunction of at least 1 RBSP satellites with BARREL 1A (lead satellite).",' + $
            '"ExecuteOptions": {' + $
                '"ResultEmailAddress": null,' + $
                '"WaitForResult": true' + $
            '},' + $
            '"ResultOptions": {' + $
                '"FormatOptions": {' + $
                    '"Cdf": null,' + $
                    '"DateFormat": "YYYY_DDD",' + $
                    '"DegreeDigits": 2,' + $
                    '"DegreeFormat": "DECIMAL",' + $
                    '"DistanceDigits": 1,' + $
                    '"DistanceFormat": "INTEGER_KM",' + $
                    '"LatLonFormat": "LAT_90_LON_360",' + $
                    '"LinesPerPage": 55,' + $
                    '"TimeFormat": "HH_HHHH"' + $
                '},' + $
                '"IncludeQueryInResult": true,' + $
                '"QueryResultType": "XML",' + $
                '"SubSatelliteCoordinateSystem": "GEO",' + $
                '"SubSatelliteCoordinateSystemType": "SPHERICAL",' + $
                '"TraceCoordinateSystem": "GEO"' + $
            '},' + $
            '"TimeInterval": {' + $
                '"End": [' + $
                    '"javax.xml.datatype.XMLGregorianCalendar",' + $
                    '"2013-02-14T00:00:00.000+0000"' + $
                '],' + $
                '"Start": [' + $
                    '"javax.xml.datatype.XMLGregorianCalendar",' + $
                    '"2013-01-29T00:00:00.000+0000"' + $
                ']' + $
            '}' + $
        '}' + $
    '}'

;    openw, 3, 'conjunction.json'
;    printf, 3, conjunctionReq
;    close, 3
;    json = json_parse(conjunctionReq)
;    help, json

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        requestUrl->GetProperty, RESPONSE_CODE=rspCode, $
             RESPONSE_HEADER=rspHdr, RESPONSE_FILENAME=rspFn

        PRINT, 'rspCode = ', rspCode
        PRINT, 'rspHdr= ', rspHdr
        PRINT, 'rspFn= ', rspFn

        obj_destroy, requestUrl

    endif


    userAgent = 'User-Agent: SpdfSscWsExample2 (' + $
        !version.os + ' ' + !version.arch + ') IDL/' + !version.release

    sscUrl = 'http://sscweb-dev.sci.gsfc.nasa.gov/WS/sscr/2/conjunctions'
    urlComponents = parse_url(sscUrl)

    headers = [userAgent, $
               'Content-Type: application/json', $
               'Accept: application/json']
;    headers = 'Content-Type: application/json'

    requestUrl = obj_new('IDLnetURL')
    requestUrl->setProperty, $
        headers=headers, $
        url_scheme=urlComponents.scheme, $
        url_host=urlComponents.host, $
        url_port=urlComponents.port, $
        url_path=urlComponents.path
    
    result = requestUrl->put(conjunctionReq, /buffer, /post, url=sscUrl)

;    print, result
;    result = '/home/btharris/Projects/Spdf/sscWebServices/src/idl/PutRsp.dat'

;    spawn, 'python -mjson.tool ' + result, prettyResult
;    print, prettyResult

    conjunctionRes = json_parse(result)

    queryResult = conjunctionRes['QueryResult']
;    print, queryResult

    status = queryResult['StatusCode']
    print, status
    queryRequest = queryResult['QueryRequest']
    queryDescription = queryRequest['Description']
    print, queryDescription

    conjunctions = (queryResult['Conjunction'])[1]
;    print,  conjunctions
    print, 'Conjunctions:'
    for i = 0, n_elements(conjunctions) - 1 do begin

        print, format='(%"%d")',i
        conjunction = conjunctions[i]
;        print, conjunction
        timeInterval = conjunction['TimeInterval']
        startTime = (timeInterval['Start'])[1]
        endTime = (timeInterval['End'])[1]
        print, '    ', startTime, ' - ', endTime

        satDescriptions = conjunction['SatelliteDescription']
        for j = 0, n_elements(satDescriptions) - 1 do begin

        satDescription = (conjunction['SatelliteDescription'])[1,j]
;        print, satDescription
        sat = (satDescription['Satellite'])
        print, '    ', sat, '     Latitude        Longitude        Radius'
        description = (satDescription['Description'])[1,0]
        location = description['Location']
        lat = location['Latitude']
        lon = location['Longitude']
        radius = location['Radius']
        print, '        ', lat, lon, radius
        traceDescription = description['TraceDescription']
        arcLength = traceDescription['ArcLength']
        traceLoc = traceDescription['Location']
        traceLat = traceLoc['Latitude']
        traceLon = traceLoc['Longitude']
        traceTarget = traceDescription['Target']
        targetDistance = traceTarget['Distance']
        targetLeadSatellite = traceTarget['LeadSatellite']
        print, '        Trace: ArcLength      Latitude        Longitude'
        print, '        ', arcLength, traceLat, traceLon
        print, '        Target: Distance  LeadSatellite'
        print, '        ', targetDistance, '  ', targetLeadSatellite
        endfor
    endfor

    obj_destroy, requestUrl
end

