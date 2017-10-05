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
; Portions Copyright [yyyy] [name of copyright owner}
;
; NOSA HEADER END
;
; Copyright (c) 2013 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;


;+
; This class represents the remotely callable interface to 
; <a href="http://www.nasa.gov/">NASA</a>'s
; <a href="http://spdf.gsfc.nasa.gov/">Space Physics Data Facility</a> (SPDF)
; <a href="http://en.wikipedia.org/wiki/Web_service#Representational_state_transfer">
; RESTful Web services</a>.
;
; @copyright Copyright (c) 2013 United States Government as represented
;     by the National Aeronautics and Space Administration. No 
;     copyright is claimed in the United States under Title 17, 
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an object representing the SPDF Web service.
;
; @param endpoint {in} {type=string}
;            URL of SPDF web service.
; @param version {in} {type=string}
;            class version.
; @param currentVersionUrl {in} {type=string}
;            URL to the file identifying the most up to date version
;            of this class.
; @keyword userAgent {in} {optional} {type=string} {default=WsExample}
;              HTTP user-agent value used in communications with SPDF.
; @returns a reference to a SSC object.
;-
function SpdfRest::init, $
    endpoint, $
    version, $
    currentVersionUrl, $
    userAgent = userAgent
    compile_opt idl2

    self.endpoint = endpoint
    self.version = version
    self.currentVersionUrl = currentVersionUrl

    if ~keyword_set(userAgent) then userAgent = 'WsExample'

    self.userAgent = 'User-Agent: ' + userAgent + ' (' + $
        !version.os + ' ' + !version.arch + ') IDL/' + !version.release

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfRest::cleanup
    compile_opt idl2

end


;+
; Gets the current endpoint value.
;
; @returns current endpoint string value.
;-
function SpdfRest::getEndpoint
    compile_opt idl2

    return, self.endpoint
end


;+
; Gets the current userAgent value.
;
; @returns current userAgent string value.
;-
function SpdfRest::getUserAgent
    compile_opt idl2

    return, self.userAgent
end

;+
; Gets the current defaultDataview value.
;
; @returns current defaultDataview string value.
;-
function SpdfSsc::getDefaultDataview
    compile_opt idl2

    return, self.defaultDataview
end


;+
; Gets the version of this class.
;
; @returns version of this class.
;-
function SpdfSsc::getVersion
    compile_opt idl2

    return, self.version
end


;+
; Gets the most up to date version of this class.
;
; @returns most up to date version of this class.
;-
function SpdfSsc::getCurrentVersion
    compile_opt idl2

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        ; Failed to get current version
        return, ''
    endif

    url = obj_new('IDLnetURL')

    return, url->get(/string_array, url=self.currentVersionUrl)
end


;+
; Compares getVersion() and getCurrentVersion() to determine if this
; class is up to date.
;
; @returns true if getVersion() >= getCurrentVersion().  Otherwise
;     false.
;-
function SpdfSsc::isUpToDate
    compile_opt idl2

    version = strsplit(self->getVersion(), '.', /extract)
    versionElements = n_elements(version)
    currentVersion = strsplit(self->getCurrentVersion(), '.', /extract)
    currentVersionElements = n_elements(currentVersion)

    if currentVersionElements eq 0 then begin

        ; Do not know what current version is so return up-to-date
        return, 1
    endif

    if versionElements lt currentVersionElements then begin

        elements = versionElements
    endif else begin

        elements = currentVersionElements
    endelse

    for i = 0, elements - 1 do begin

        if 0 + version[i] lt 0 + currentVersion[i] then return, 0
    endfor

    if versionElements lt currentVersionElements then begin

        return, 0
    endif else begin

        return, 1
    endelse
end


;+
; Gets the node's value of the first child of the first item of the
; specified element of the given DOM document.
;
; @private
;
; @param domElement {in} {required} {type=IDLffXMLDOMElement}
;                DOM element to search.
; @param tagName {in} {required} {type=string}
;                A scalar string containing the tag name of the desired
;                element.
; @returns strarr containing the node's string value(s) of the first 
;     child of the item(s) of the specified element of the given DOM 
;     document. An empty string is returned if the value cannot be 
;     found.
;-
function SpdfRest::getNamedElementsFirstChildValue, $
    domElement, tagName
    compile_opt idl2

    nodeList = domElement->getElementsByTagName(tagName)

    if nodeList->getLength() eq 0 then return, ''

    values = strarr(nodeList->getLength())

    for i = 0, nodeList->getLength() - 1 do begin

        domNode = nodeList->item(i)

        child = domNode->getFirstChild()

        if obj_valid(child) then begin

            values[i] = child->getNodeValue()
        endif else begin

            values[i] = ''
        endelse
    endfor

    if n_elements(values) eq 1 then return, values[0] $
                               else return, values
end


;+
; Gets the node's double value of the first child of the first item of 
; the specified element of the given DOM element.
;
; @private
;
; @param domElement {in} {required} {type=IDLffXMLDOMElement}
;                DOM element to search.
; @param tagName {in} {required} {type=string}
;                A scalar string containing the tag name of the desired
;                element.
; @returns dblarr containing the node's double value(s) of the first 
;     child of the item(s) of the specified element of the given DOM 
;     document. A scalar constant of !values.d_NaN is returned if 
;     the value cannot be found.
;-
function SpdfRest::getNamedElementsFirstChildDoubleValue, $
    domElement, tagName
    compile_opt idl2

    nodeList = domElement->getElementsByTagName(tagName)

    if nodeList->getLength() eq 0 then return, !values.d_NaN

    values = dblarr(nodeList->getLength())

    for i = 0, nodeList->getLength() - 1 do begin

        domNode = nodeList->item(i)

        child = domNode->getFirstChild()

        if obj_valid(child) then begin

            values[i] = double(child->getNodeValue())
        endif else begin

            values[i] = !values.d_NaN
        endelse
    endfor

    if n_elements(values) eq 1 then return, values[0] $
                               else return, values
end


;+
; Gets the node's float value of the first child of the first item of 
; the specified element of the given DOM element.
;
; @private
;
; @param domElement {in} {required} {type=IDLffXMLDOMElement}
;                DOM element to search.
; @param tagName {in} {required} {type=string}
;                A scalar string containing the tag name of the desired
;                element.
; @returns fltarr containing the node's float value(s) of the first 
;     child of the item(s) of the specified element of the given DOM 
;     document. A scalar constant of !values.f_NaN is returned if 
;     the value cannot be found.
;-
function SpdfRest::getNamedElementsFirstChildFloatValue, $
    domElement, tagName
    compile_opt idl2

    nodeList = domElement->getElementsByTagName(tagName)

    if nodeList->getLength() eq 0 then return, !values.f_NaN

    values = fltarr(nodeList->getLength())

    for i = 0, nodeList->getLength() - 1 do begin

        domNode = nodeList->item(i)

        child = domNode->getFirstChild()

        if obj_valid(child) then begin

            values[i] = float(child->getNodeValue())
        endif else begin

            values[i] = !values.f_NaN
        endelse
    endfor

    if n_elements(values) eq 1 then return, values[0] $
                               else return, values
end


;+
; Converts the given Julian Day value to an ISO 8601 string 
; representation.
;
; @private
;
; @param value {in} {type=julDay}
;            Julian day value to convert.
; @returns ISO 8601 string representation of the given value
;-
function SpdfRest::julDay2Iso8601, $
    value
    compile_opt idl2

    caldat, value, month, day, year, hour, minute, second

    return, string(year, month, day, hour, minute, second, $
                   format=self.iso8601Format)
end


;+
; Creates a SpdfTimeInterval object from a child TimeInterval element
; of the given node from a cdas:DataResult XML document.
;
; @private
;
; @param domNode {in} {type=IDLffXMLDOMNode}
;              node from a cdas:DataResult XML document.
; @returns a reference to a SpdfTimeInterval object.
;-
function SpdfRest::getTimeIntervalChild, $
    domNode
    compile_opt idl2

    timeInterval = obj_new()

    timeIntervalElements = domNode->getElementsByTagName('TimeInterval')

    if timeIntervalElements->getLength() gt 0 then begin

        timeInterval = $
            self->getTimeInterval(timeIntervalElements->item(0))
    end

    return, timeInterval
end


;+
; Creates a SpdfTimeInterval object from the given TimeInterval element
; from a cdas:DataResult XML document.
;
; @private
;
; @param timeIntervalElement {in} {type=IDLffXMLDOMNode}
;              element from a cdas:DataResult XML document.
; @returns a reference to a SpdfTimeInterval object.
;-
function SpdfRest::getTimeInterval, $
    timeIntervalElement
    compile_opt idl2

    startDate = $
        self->getJulDate((timeIntervalElement->$
                          getElementsByTagName('Start'))->item(0))

    endDate = $
        self->getJulDate((timeIntervalElement->$
                          getElementsByTagName('End'))->item(0))

    
    return, obj_new('SpdfTimeInterval', startDate, endDate)
end


;+
; Creates a julday object from the given time element from a 
; cdas:DataResult XML document.
;
; @private
;
; @param dateTimeElement {in} {type=IDLffXMLDOMNodeList}
;              list whose first child is to be converted into a julday
; @returns julday representation of first child of given 
;              dateTimeElement.
;-
function SpdfRest::getJulDate, $
    dateTimeElement
    compile_opt idl2

    dateFormat='(I4, 1X, I2, 1X, I2, 1X, I2, 1X, I2, 1X, I2)'

    dateTimeStr = (dateTimeElement->getFirstChild())->getNodeValue()

    reads, dateTimeStr, format=dateFormat, $
            year, month, day, hour, minute, second

    return, julday(month, day, year, hour, minute, second)
end


;+
; Perform an HTTP GET request to the given URL.  This method provides 
; functionality similar to doing    
;     obj_new('IDLffXMLDOMDocument', filename=url)
; except that this method will catch and attempt to deal with errors.
;
; @private
;
; @param url {in} {type=string}
;            URL of GET request to make.
; @keyword errorReporter {in} {optional} {type=string}
;              name of IDL procedure to call if an HTTP error occurs.
; @returns reference to IDLffXMLDOMDocument representation of HTTP
;     response entity.
;-
function SpdfRest::makeGetRequest, $
    url, $
    errorReporter = errorReporter
    compile_opt idl2

    username = ''
    password = ''

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        reply = $
            self->handleHttpError( $
                requestUrl, errorReporter = errorReporter)

        obj_destroy, requestUrl

        if reply eq 0 then return, obj_new()

    endif

    requestUrl = self->getRequestUrl(url, username, password)

    result = string(requestUrl->get(/buffer))

    obj_destroy, requestUrl

    return, obj_new('IDLffXMLDOMDocument', string=result)
end


;+
; Perform an HTTP POST request to the given URL.  
;
; @private
;
; @param url {in} {type=string}
;            URL of GET request to make.
; @param xmlRequest {in} {type=string}
;            XML entity body to be include in the request.
; @keyword errorReporter {in} {optional} {type=string}
;              name of IDL procedure to call if an HTTP error occurs.
; @returns reference to IDLffXMLDOMDocument representation of HTTP
;     response entity.
;-
function SpdfRest::makePostRequest, $
    url, xmlRequest, $
    errorReporter = errorReporter
    compile_opt idl2

    username = ''
    password = ''

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        reply = $
            self->handleHttpError( $
                requestUrl, $
                errorReporter = errorReporter)

        obj_destroy, requestUrl

        if reply eq 0 then return, obj_new()

    endif

    requestUrl = self->getRequestUrl(url, username, password)

    requestUrl->setProperty, header='Content-Type: application/xml'

; print, 'POSTing ', xmlRequest
; print, 'to ', url

    result = requestUrl->put(xmlRequest, /buffer, /post, url=url)

    obj_destroy, requestUrl

    return, obj_new('IDLffXMLDOMDocument', filename=result)
end


;+
; Function to handle HTTP request errors.  
; If an errorReporter has been provided, it is called.
;
; @private
;
; @param request {in} {type=IDLnetURL}
;            HTTP request that caused the error.
; @keyword errorReporter {in} {optional} {type=string}
;              name of IDL procedure to call if an HTTP error occurs.
; @returns a value of 0.
;-
function SpdfRest::handleHttpError, $
    request, $
    errorReporter = errorReporter
    compile_opt idl2

    request->getProperty, $
        response_code=responseCode, $
        response_header=responseHeader, $
        response_filename=responseFilename

    if keyword_set(errorReporter) then begin

        call_method, 'reportError', errorReporter, $
                responseCode, responseHeader, responseFilename
    endif

    return, 0
end


;+
; Create an IDLnetUrl object from the given URL with any supplied
; authentication values set.
;
; @private
;
; @param url {in} {type=string}
;            URL.
; @param username {in} {type=string}
;            username.
; @param password {in} {type=string}
;            password.
; @returns reference to a IDLnetUrl with any supplied authentication
;     values set.
;-
function SpdfRest::getRequestUrl, $
    url, username, password
    compile_opt idl2

    requestUrl = obj_new('IDLnetUrl')

    urlComponents = parse_url(url)

    requestUrl->setProperty, $
        header=self.userAgent, $
        url_scheme=urlComponents.scheme, $
        url_host=urlComponents.host, $
        url_port=urlComponents.port, $
        url_path=urlComponents.path, $
        url_query=urlComponents.query

    if username ne '' then begin

        requestUrl->setProperty, $
            authentication=3, $
            url_username=username, $
            url_password=password
    endif

    return, requestUrl
end


;+
; Defines the SpdfRest class.
;
; @field endpoint URL of SSC web service.
; @field userAgent HTTP 
;            <a href="http://tools.ietf.org/html/rfc2616#section-14.43">
;               user-agent value</a> to use in communications with SSC.
; @field version identifies the version of this class.
; @field currentVersionUrl URL to the file identifying the most up to 
;            date version of this class.
;-
pro SpdfRest__define
    compile_opt idl2
    struct = { SpdfRest, $
        endpoint:'', $
        userAgent:'', $
        version:'', $
        currentVersionUrl:'' $
    }
end
