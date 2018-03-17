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
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
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
; Copyright (c) 2010-2018 United States Government as represented by the
; National Aeronautics and Space Administration. No copyright is claimed
; in the United States under Title 17, U.S.Code. All Other Rights 
; Reserved.
;
;


;+
; This class represents the remotely callable interface to 
; <a href="https://www.nasa.gov/">NASA</a>'s
; <a href="https://spdf.gsfc.nasa.gov/">Space Physics Data Facility</a> 
; (SPDF)
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis 
; System</a> (CDAS).
;
; @copyright Copyright (c) 2010-2018 United States Government as 
;     represented by the National Aeronautics and Space Administration.
;     No copyright is claimed in the United States under Title 17, 
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an object representing CDAS.  
; 
; If access to the Internet is through an HTTP proxy, the caller 
; should ensure that the HTTP_PROXY environment is correctly set 
; before this method is called.  The HTTP_PROXY value should be of 
; the form 
; http://username:password@hostname:port/.
;
; @keyword endpoint {in} {optional} {type=string}
;              {default='https://cdaweb.gsfc.nasa.gov/WS/cdasr/1'}
;              URL of CDAS web service.
; @keyword userAgent {in} {optional} {type=string} {default=WsExample}
;              HTTP user-agent value used in communications with CDAS.
; @keyword defaultDataview {in} {optional} {type=string} 
;              {default=sp_phys}
;              default CDAS dataview value to use in subsequent calls
;              when no value is specified.
; @keyword sslVerifyPeer {in} {optional} {type=int} {default=1}
;              Specifies whether the authenticity of the peer's SSL
;              certificate should be verified.  When 0, the connection 
;              succeeds regardless of what the peer SSL certificate 
;              contains.
; @returns a reference to a CDAS object.
;-
function SpdfCdas::init, $
    endpoint = endpoint, $
    userAgent = userAgent, $
    defaultDataview = defaultDataview, $
    sslVerifyPeer = sslVerifyPeer
    compile_opt idl2

    self.endpoint = 'https://cdaweb.gsfc.nasa.gov/WS/cdasr/1'
    self.version = '%VERSION*'
    self.currentVersionUrl = $
        'https://cdaweb.gsfc.nasa.gov/WebServices/REST/spdfCdasVersion.txt'

    if keyword_set(endpoint) then self.endpoint = endpoint

    if ~keyword_set(userAgent) then userAgent = 'WsExample'

    self.userAgent = 'User-Agent: ' + userAgent + '/' + $
        self.version + ' (' + !version.os + ' ' + !version.arch + $
        ') IDL/' + !version.release

    self.defaultDataview = 'sp_phys'

    if keyword_set(defaultDataview) then begin

        self.defaultDataview = defaultDataview
    endif

    self.ssl_verify_peer = SpdfGetDefaultSslVerifyPeer()

    if n_elements(sslVerifyPeer) gt 0 then begin

        self.ssl_verify_peer = sslVerifyPeer
    endif

    http_proxy = getenv('HTTP_PROXY')

    if strlen(http_proxy) gt 0 then begin

        proxyComponents = parse_url(http_proxy)

        self.proxy_hostname = proxyComponents.host
        self.proxy_password = proxyComponents.password
        self.proxy_port = proxyComponents.port
        self.proxy_username = proxyComponents.username

        if strlen(proxy_username) gt 0 then begin

            self.proxy_authentication = 3
        endif
    endif

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCdas::cleanup
    compile_opt idl2

end


;+
; Gets the current endpoint value.
;
; @returns current endpoint string value.
;-
function SpdfCdas::getEndpoint
    compile_opt idl2

    return, self.endpoint
end


;+
; Gets the current userAgent value.
;
; @returns current userAgent string value.
;-
function SpdfCdas::getUserAgent
    compile_opt idl2

    return, self.userAgent
end


;+
; Gets the current defaultDataview value.
;
; @returns current defaultDataview string value.
;-
function SpdfCdas::getDefaultDataview
    compile_opt idl2

    return, self.defaultDataview
end


;+
; Gets the version of this class.
;
; @returns version of this class.
;-
function SpdfCdas::getVersion
    compile_opt idl2

    return, self.version
end


;+
; Gets the most up to date version of this class.
;
; @returns most up to date version of this class.
;-
function SpdfCdas::getCurrentVersion
    compile_opt idl2

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        ; Failed to get current version
        return, ''
    endif

    url = obj_new('IDLnetURL', $
                  proxy_authentication = self.proxy_authentication, $
                  proxy_hostname = self.proxy_hostname, $
                  proxy_port = self.proxy_port, $
                  proxy_username = self.proxy_username, $
                  proxy_password = self.proxy_password)

    return, url->get(/string_array, url=self.currentVersionUrl)
end


;+
; Compares getVersion() and getCurrentVersion() to determine if this
; class is up to date.
;
; @returns true if getVersion() >= getCurrentVersion().  Otherwise 
;     false.
;-
function SpdfCdas::isUpToDate
    compile_opt idl2

    version = strsplit(self->getVersion(), '.', /extract)
    versionElements = n_elements(version)
    currentVersion = strsplit(self->getCurrentVersion(), '.', /extract)
    currentVersionElements = n_elements(currentVersion)

    if versionElements eq 1 or currentVersionElements eq 1 then begin

        ; Do not know what the versions are so return up-to-date
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
; @param domElement {in} {required} {type=IDLffXMLDOMDocument}
;                DOM element to search
; @param tagName {in} {required} {type=string}
;                A scalar string containing the tag name of the desired
;                element.
; @returns node's string value(s) of the first child of the item(s)
;              of the specified element of the given DOM document. An
;              empty string is returned if the value cannot be found.
;-
function SpdfCdas::getNamedElementsFirstChildValue, $
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
; Gets a description of all the dataviews that are available.
;
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfDataviewDescription objects.
;              If there are no dataviews, an array of length 
;              one is returned with the first element being a null 
;              object reference.
;-
function SpdfCdas::getDataviews, $
    httpErrorReporter=errorReporter
    compile_opt idl2

    url = self.endpoint + '/dataviews'

    dvDom = self->makeGetRequest('N/A', url, $
                errorReporter=errorReporter)

    if ~obj_valid(dvDom) then return, objarr(1)

    dataviewElements = $
        dvDom->getElementsByTagName('DataviewDescription')

    dataviews = objarr(dataviewElements->getLength(), /nozero)

    for i = 0, dataviewElements->getLength() - 1 do begin

        dvElement = dataviewElements->item(i)

        id = $
            self->getNamedElementsFirstChildValue(dvElement, 'Id')
        endpointAddress = $
            self->getNamedElementsFirstChildValue(dvElement, $
                'EndpointAddress')
        title = $
            self->getNamedElementsFirstChildValue(dvElement, 'Title')
        subtitle = $
            self->getNamedElementsFirstChildValue(dvElement, 'SubTitle')
        overview = $
            self->getNamedElementsFirstChildValue(dvElement, 'Overview')
        underConstructionStr = $
            self->getNamedElementsFirstChildValue(dvElement, $
                'UnderConstruction')
        if strcmp(underConstructionStr, 'true', /fold_case) eq 1 $
        then begin
            underConstruction = 1b
        endif else begin
            underConstruction = 0b
        endelse
        noticeUrl = $
            self->getNamedElementsFirstChildValue(dvElement, $
                'NoticeUrl')
        publicAccessStr = $
            self->getNamedElementsFirstChildValue(dvElement, $
                'PublicAccess')
        if (strcmp(publicAccessStr, 'true', /fold_case) eq 1) then begin
            publicAccess = 1b
        endif else begin
            publicAccess = 0b
        endelse

        dataviews[i] = $
            obj_new('SpdfDataviewDescription', id, endpointAddress, $
                    title, subtitle, overview, underConstruction, $
                    noticeUrl, publicAccess)
    endfor

    obj_destroy, dvDom

    return, dataviews
end
    

;+
; Gets a description of all the observatory groups.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @keyword instrumentTypes {in} {optional} {type=strarr}
;              names of instrument-types which restrict the returned
;              observatory groups to only those supporting the specified
;              instrument-types.  Valid values are those returned by
;              getInstrumentTypes.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfObservatoryGroupDescription objects.
;              If there are no observatory groups, an array of length 
;              one is returned with the first element being a null 
;              object reference.
;-
function SpdfCdas::getObservatoryGroups, $
    dataview = dataview, $
    instrumentTypes = iTypes, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    url = self.endpoint + '/dataviews/' + dataview + $
              '/observatoryGroups?'

    for i = 0, n_elements(iTypes) - 1 do begin

        url = url + 'instrumentType=' + iTypes[i] + '&'
    endfor

    url = strmid(url, 0, strlen(url) - 1)

    ogDom = self->makeGetRequest(dataview, url, $
                authenticator = authenticator, $
                errorReporter = errorReporter)

    if ~obj_valid(ogDom) then return, objarr(1)

    ogElements = $
        ogDom->getElementsByTagName('ObservatoryGroupDescription')

    observatoryGroups = objarr(ogElements->getLength(), /nozero)

    for i = 0, ogElements->getLength() - 1 do begin

        ogElement = ogElements->item(i)

        name = $
            self->getNamedElementsFirstChildValue(ogElement, 'Name')

        observatoryIds = $
            self->getNamedElementsFirstChildValue(ogElement, $
                'ObservatoryId')

        observatoryGroups[i] = $
            obj_new('SpdfObservatoryGroupDescription', name, $
                observatoryIds)
    endfor

    obj_destroy, ogDom

    return, observatoryGroups
end
    

;+
; Gets a description of all the instrument types.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @keyword observatoryGroups {in} {optional} {type=strarr}
;              names of observatory-groups which restrict the returned
;              instrument types to only those supporting the specified
;              observatory-groups.  Valid values are those returned by
;              getObservatoryGroups.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfInstrumentTypeDescription objects.
;              If there are no intrument types, an array of length one 
;              is returned with the first element being a null object 
;              reference.
;-
function SpdfCdas::getInstrumentTypes, $
    dataview = dataview, $
    observatoryGroups = oGroups, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    url = self.endpoint + '/dataviews/' + dataview + '/instrumentTypes?'

    for i = 0, n_elements(oGroups) - 1 do begin

        url = url + 'observatoryGroup=' + oGroups[i] + '&'
    endfor

    url = strmid(url, 0, strlen(url) - 1)

    itDom = self->makeGetRequest(dataview, url, $
                authenticator = authenticator, $
                errorReporter = errorReporter)

    if ~obj_valid(itDom) then return, objarr(1)

    itElements = $
        itDom->getElementsByTagName('InstrumentTypeDescription')

    instrumentTypes = objarr(itElements->getLength(), /nozero)

    for i = 0, itElements->getLength() - 1 do begin

        itElement = itElements->item(i)

        name = $
            self->getNamedElementsFirstChildValue(itElement, 'Name')

        instrumentTypes[i] = $
            obj_new('SpdfInstrumentTypeDescription', name)
    endfor

    obj_destroy, itDom

    return, instrumentTypes
end
    

;+
; Gets a description of all the datasets.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @keyword observatoryGroups {in} {optional} {type=strarr}
;              names of observatory-groups which restrict the returned
;              datasets to only those supporting the specified
;              observatory-groups.  Valid values are those returned by
;              getObservatoryGroups.
; @keyword instrumentTypes {in} {optional} {type=strarr}
;              names of instrument-types which restrict the returned
;              datasets to only those supporting the specified
;              instrument-types.  Valid values are those returned by
;              getInstrumentTypes.
; @keyword observatories {in} {optional} {type=strarr}
;              names of observatories which restrict the returned
;              datasets to only those supporting the specified
;              observatories.  Valid values are those returned by
;              getObservatories.
; @keyword instruments {in} {optional} {type=strarr}
;              names of instruments which restrict the returned
;              datasets to only those supporting the specified
;              instruments.  Valid values are those returned by
;              getInstruments.
; @keyword startDate {in} {optional} {type=julday}
;              value that restricts the returned dataset to only
;              those that contain data after this date.
; @keyword stopDate {in} {optional} {type=julday}
;              value that restricts the returned dataset to only
;              those that contain data before this date.
; @keyword idPattern {in} {optional} {type=string}
;              a java.util.regex compatible 
;              <a href="https://en.wikipedia.org/wiki/Regex">regular 
;              expression</a> that must match the dataset's identifier 
;              value.  Omitting this parameter is equivalent to ".*".
; @keyword labelPattern {in} {optional} {type=string}
;              a java.util.regex compatible 
;              <a href="https://en.wikipedia.org/wiki/Regex">regular 
;              expression</a> that must match the dataset's label 
;              text.  Omitting this parameter is equivalent to ".*".
;              Embedded matching flag expressions (e.g., (?i) for 
;              case insensitive match mode) are supported and likely 
;              to be useful in this case.
; @keyword notesPattern {in} {optional} {type=string}
;              a java.util.regex compatible 
;              <a href="https://en.wikipedia.org/wiki/Regex">regular 
;              expression</a> that must match the dataset's notes 
;              text.  Omitting this parameter is equivalent to ".*".
;              Embedded matching flag expressions (e.g., (?i) for 
;              case insensitive match mode) are supported and likely 
;              to be useful in this case.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfDatasetDescription objects.  If there are no
;              datasets, an array of length one is returned with the
;              first element being a null object reference.
;-
function SpdfCdas::getDatasets, $
    dataview = dataview, $
    observatoryGroups = observatoryGroups, $
    instrumentTypes = instrumentTypes, $
    observatories = observatories, $
    instruments = instruments, $
    startDate = startDate, $
    stopDate = stopDate, $
    idPattern = idPattern, $
    labelPattern = labelPattern, $
    notesPattern = notesPattern, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    url = self.endpoint + '/dataviews/' + dataview + '/datasets?'

    for i = 0, n_elements(observatoryGroups) - 1 do begin

        url = url + 'observatoryGroup=' + observatoryGroups[i] + '&'
    endfor

    for i = 0, n_elements(instrumentTypes) - 1 do begin

        url = url + 'instrumentType=' + instrumentTypes[i] + '&'
    endfor

    for i = 0, n_elements(observatories) - 1 do begin

        url = url + 'observatory=' + observatories[i] + '&'
    endfor

    for i = 0, n_elements(instruments) - 1 do begin

        url = url + 'instrument=' + instruments[i] + '&'
    endfor

    if keyword_set(startDate) then begin

        url = url + 'startDate=' + self->julDay2Iso8601(startDate) + '&'
    endif

    if keyword_set(stopDate) then begin

        url = url + 'stopDate=' + self->julDay2Iso8601(stopDate) + '&'
    endif

    if keyword_set(idPattern) then begin

         url = url + 'idPattern=' + idPattern + '&'
    endif

    if keyword_set(labelPattern) then begin

         url = url + 'labelPattern=' + labelPattern + '&'
    endif

    if keyword_set(notesPattern) then begin

         url = url + 'notesPattern=' + notesPattern + '&'
    endif

    url = strmid(url, 0, strlen(url) - 1)

    dsDom = self->makeGetRequest(dataview, url, $
                authenticator = authenticator, $
                errorReporter = errorReporter)

    if ~obj_valid(dsDom) then begin

        return, objarr(1)
    endif

    dsElements = $
        dsDom->getElementsByTagName('DatasetDescription')

    datasets = objarr(dsElements->getLength(), /nozero)

    for i = 0, dsElements->getLength() - 1 do begin

        dsElement = dsElements->item(i)

        id = $
            self->getNamedElementsFirstChildValue(dsElement, 'Id')

        observatories = $
            self->getNamedElementsFirstChildValue(dsElement, $
                'Observatory')

        instruments = $
            self->getNamedElementsFirstChildValue(dsElement, $
                'Instrument')

        observatoryGroups = $
            self->getNamedElementsFirstChildValue(dsElement, $
                'ObservatoryGroup')

        instrumentTypes = $
            self->getNamedElementsFirstChildValue(dsElement, $
                'InstrumentTypes')

        label = $
            self->getNamedElementsFirstChildValue(dsElement, 'Label')

        timeInterval = self->getTimeIntervalChild(dsElement)

        piName = $
            self->getNamedElementsFirstChildValue(dsElement, 'PiName')

        piAffiliation = self->getNamedElementsFirstChildValue($
                            dsElement, 'PiAffiliation')

        notes = $
            self->getNamedElementsFirstChildValue(dsElement, 'Notes')

        linkElements = dsElement->getElementsByTagName('DatasetLink')

        if linkElements->getLength() gt 0 then begin

            datasetLinks = objarr(linkElements->getLength(), /nozero)

            for j = 0, linkElements->getLength() - 1 do begin

                linkElement = linkElements->item(j)

                title = $
                    self->getNamedElementsFirstChildValue(linkElement, $
                        'Title')
                text = $
                    self->getNamedElementsFirstChildValue(linkElement, $
                        'Text')
                url = $
                    self->getNamedElementsFirstChildValue(linkElement, $
                        'Url')

                datasetLinks[j] = $
                    obj_new('SpdfDatasetLink', title, text, url)
            endfor
        endif else begin

            datasetLinks = obj_new()
        endelse

        datasets[i] = $
            obj_new('SpdfDatasetDescription', id, observatories, $
                instruments, observatoryGroups, instrumentTypes, $
                label, timeInterval, piName, piAffiliation, notes, $
                datasetLinks)

        obj_destroy, datasetLinks
    endfor

    obj_destroy, dsDom

    return, datasets
end
    

;+
; Gets a description of a dataset's data inventory.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @param dataset {in} {type=string}
;              identifies the dataset.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns an SpdfInventoryDescription or a null reference if no
;              inventory is available.
;-
function SpdfCdas::getInventory, $
    dataview = dataview, dataset, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    url = self.endpoint + '/dataviews/' + dataview + '/datasets/' + $
          dataset + '/inventory'

    inventoryDom = self->makeGetRequest(dataview, url, $
                       authenticator = authenticator, $
                       errorReporter = errorReporter)

    inventoryElements = $
        inventoryDom->getElementsByTagName('InventoryDescription')

    if inventoryElements->getLength() eq 0 then begin

        obj_destroy, inventoryDom

        return, obj_new()
    endif

    inventoryElement = inventoryElements->item(0)

    id = self->getNamedElementsFirstChildValue(inventoryElement, 'Id')

    timeIntervalElements = $
        inventoryElement->getElementsByTagName('TimeInterval')

    if timeIntervalElements->getLength() gt 0 then begin

        timeIntervals = $
            objarr(timeIntervalElements->getLength(), /nozero)

        for i = 0, timeIntervalElements->getLength() - 1 do begin

            timeIntervals[i] = $
                self->getTimeInterval(timeIntervalElements->item(i))
        endfor
    endif else begin

        timeIntervals = obj_new()
    endelse

    obj_destroy, inventoryDom

    return, obj_new('SpdfInventoryDescription', id, timeIntervals)
end
    

;+
; Gets a description of a dataset's variables.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @param dataset {in} {type=string}
;              identifies the dataset.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns array of SpdfVariableDescription objects.  If the dataset
;              has no variables, an array of one null object is 
;              returned.
;-
function SpdfCdas::getVariables, $
    dataview = dataview, dataset, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    url = self.endpoint + '/dataviews/' + dataview + '/datasets/' + $
          dataset + '/variables'

    varDom = self->makeGetRequest(dataview, url, $
                authenticator = authenticator, $
                errorReporter = errorReporter)

    if ~obj_valid(varDom) then return, objarr(1)

    varElements = $
        varDom->getElementsByTagName('VariableDescription')

    if varElements->getLength() eq 0 then begin

        obj_destroy, varDom

        return, objarr(1)
    endif

    varDescriptions = objarr(varElements->getLength(), /nozero)

    for i = 0, varElements->getLength() - 1 do begin

        varElement = varElements->item(i)

        name = $
            self->getNamedElementsFirstChildValue(varElement, 'Name')

        shortDescription = $
            self->getNamedElementsFirstChildValue(varElement, $
                'ShortDescription')

        longDescription = $
            self->getNamedElementsFirstChildValue(varElement, $
                'LongDescription')

        parent = $
            self->getNamedElementsFirstChildValue(varElement, 'Parent')

        children = $
            self->getNamedElementsFirstChildValue(varElement, $
                'Children')
 
        varDescriptions[i] = $
            obj_new('SpdfVariableDescription', name, shortDescription, $
                longDescription, parent = parent, children = children)
    endfor

    obj_destroy, varDom

    return, varDescriptions
end
    

;+
; Gets <a href="https://cdf.gsfc.nasa.gov/">Common Data Format</a>
; data from the specified dataset.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @param timeIntervals {in} {type=objarr of SpdfTimeIntervals}
;              time intervals of data to get.
; @param dataset {in} {type=string}
;              identifies the dataset from which data is being
;              requested.
; @param variables {in} {type=strarr}
;              names of variable's whose data is being requested.
;              If the first (only) name is "ALL-VARIABLES", then the 
;              resulting CDF will contain all variables.
; @keyword cdfVersion {in} {optional} {type=int}
;              is the CDF file version that any created CDF files 
;              should be (2 or 3). 
; @keyword cdfFormat {in} {optional} {type=string}
;              CDF format of returned data.  Valid values are:
;              Binary, CDFML, GzipCDFML, ZipCDFML.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns SpdfCdasDataResult object.
;-
function SpdfCdas::getCdfData, $
    dataview = dataview, $
    timeIntervals, $
    dataset, $
    variables, $
    cdfVersion = cdfVersion, $
    cdfFormat = cdfFormat, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    sizeTimeIntervals = size(timeIntervals)

    if sizeTimeIntervals[0] eq 0 then begin

        timeIntervals = [timeIntervals]
    endif

    datasetRequest = $
        obj_new('SpdfDatasetRequest', dataset, variables)

    cdfRequest = $
        obj_new('SpdfCdfRequest', timeIntervals, datasetRequest, $
            cdfVersion = cdfVersion, cdfFormat = cdfFormat)

    dataRequest = $
        obj_new('SpdfCdasDataRequest', cdfRequest)

    result = self->getData(dataview = dataview, dataRequest, $
                 authenticator = authenticator, $
                 httpErrorReporter = errorReporter)

    obj_destroy, datasetRequest
    obj_destroy, cdfRequest
    obj_destroy, dataRequest

    return, result
end


;+
; Gets a textual representation of data from the specified dataset.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @param timeInterval {in} {type=SpdfTimeInterval}
;              time range of data to get.
; @param dataset {in} {type=string}
;              identifies the dataset from which data is being
;              requested.
; @param variables {in} {type=strarr}
;              names of variable's whose data is being requested.
;              If no names are specified, the data of all variables
;              is returned.
; @keyword compression {in} {optional} {type=int}
;              the type of compression to use on the result file.
;              Valid values are: Uncompressed, Gzip, Bzip2, Zip.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns SpdfCdasDataResult object.
;-
function SpdfCdas::getTextData, $
    dataview = dataview, timeInterval, dataset, variables, $
    compression = compression, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    datasetRequest = $
        obj_new('SpdfDatasetRequest', dataset, variables)

    textRequest = $
        obj_new('SpdfTextRequest', timeInterval, datasetRequest, $
            compression = compression)

    dataRequest = $
        obj_new('SpdfCdasDataRequest', textRequest)

    result = self->getData(dataview = dataview, dataRequest, $
                 authenticator = authenticator, $
                 httpErrorReporter = errorReporter)

    obj_destroy, datasetRequest
    obj_destroy, textRequest
    obj_destroy, dataRequest

    return, result
end


;+
; Gets a graphical representation of data from the specified dataset.
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @param timeInterval {in} {type=SpdfTimeInterval}
;              time range of data to get.
; @param datasetRequests {in} {type=objarr of SpdfDatasetRequest}
;              identifies the datasets and variables from which data 
;              is being requested.
; @keyword graphOptions {in} {optional} {type=int}
;              graphing options.  Valid values are:
;              CoarseNoiseFilter, DoubleHeightYAxis, CombineGraphs.
; @keyword imageFormat {in} {optional} {type=strarr}
;              Format options for graph.  Valid values are:
;              GIF, PNG, PS, PDF.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns SpdfCdasDataResult object.
;-
function SpdfCdas::getGraphData, $
    dataview = dataview, timeInterval, datasetRequests, $
    graphOptions = graphOptions, imageFormat = imageFormat, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    graphRequest = $
        obj_new('SpdfGraphRequest', $
            timeInterval, datasetRequests, $
            graphOptions = graphOptions, imageFormats = imageFormats)

    dataRequest = $
        obj_new('SpdfCdasDataRequest', graphRequest)

    result = self->getData(dataview = dataview, dataRequest, $
                 authenticator = authenticator, $
                 httpErrorReporter = errorReporter)

    obj_destroy, graphRequest
    obj_destroy, dataRequest

    return, result
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
function SpdfCdas::julDay2Iso8601, $
    value
    compile_opt idl2

    caldat, value, month, day, year, hour, minute, second

    return, string(year, month, day, hour, minute, second, $
                   format=self.iso8601Format)
end


;+
; Make a request to CDAS for the specified data.
;
; @private
;
; @keyword dataview {in} {optional} {type=string}
;              name of dataview to access.
; @param dataRequest {in} {type=SpdfCdasDataRequest}
;              specifies the data to get.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword httpErrorReporter {in} {optional} 
;              {type=SpdfHttpErrorReporter}
;              used to report an HTTP error.
; @returns SpdfCdasDataResult object.
;-
function SpdfCdas::getData, $
    dataview = dataview, $
    dataRequest, $
    authenticator = authenticator, $
    httpErrorReporter = errorReporter
    compile_opt idl2

    if ~keyword_set(dataview) then dataview = self.defaultDataview

    url = self.endpoint + '/dataviews/' + dataview + '/datasets'

    requestDoc = obj_new('IDLffXMLDOMDocument')

    requestDom = $
        requestDoc->appendChild( $
            dataRequest->createDomElement(requestDoc))

    requestDoc->save, string=xmlRequest

    obj_destroy, requestDoc

    dataDoc = self->makePostRequest(dataview, url, xmlRequest, $
                  authenticator = authenticator, $
                  errorReporter = errorReporter)

    if ~obj_valid(dataDoc) then return, obj_new()

    dataResult = self->getDataResult(dataDoc)

    obj_destroy, dataDoc

    return, dataResult
end


;+
; Creates an SpdfCdasDataResult object from the given cdas:DataResult
; XML document.
;
; @private
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;              cdas:DataResult XML document.
; @returns SpdfCdasDataResult object.
;-
function SpdfCdas::getDataResult, $
    doc
    compile_opt idl2

    fileDescriptions = self->getFileDescriptions(doc)

    messages = self->getDataResultText(doc, 'Message')

    warnings = self->getDataResultText(doc, 'Warning')

    statuses = self->getDataResultText(doc, 'Status')

    errors = self->getDataResultText(doc, 'Error')

    dataResult = obj_new('SpdfCdasDataResult', $
        fileDescriptions, $
        messages = messages, warnings = warnings, $
        statuses = statuses, errors = errors)

    return, dataResult
end
    

;+
; Creates SpdfFileDescription object(s) from the FileDescription
; elements in the given cdas:DataResult XML document.
;
; @private
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;              cdas:DataResult XML document.
; @returns objarr of SpdfFileDescription objects.
;-
function SpdfCdas::getFileDescriptions, $
    doc
    compile_opt idl2

    fileDescriptions = obj_new()

    fileElements = doc->getElementsByTagName('FileDescription')

    if fileElements->getLength() gt 0 then begin

        fileDescriptions = objarr(fileElements->getLength(), /nozero)

        for i = 0, fileElements->getLength() - 1 do begin

            fileElement = fileElements->item(i)

            name = $
                self->getNamedElementsFirstChildValue(fileElement, $
                    'Name')

            mimeType = $
                self->getNamedElementsFirstChildValue(fileElement, $
                    'MimeType')

            startTime = $
                self->getJulDate((fileElement->$
                    getElementsByTagName('StartTime'))->item(0))

            endTime = $
                self->getJulDate((fileElement->$
                     getElementsByTagName('EndTime'))->item(0))

            timeInterval = $
                obj_new('SpdfTimeInterval', startTime, endTime)

            length = $
                self->getNamedElementsFirstChildValue(fileElement, $
                    'Length')

            lastModified = $
                self->getNamedElementsFirstChildValue(fileElement, $
                    'LastModified')

            thumbnailDescription = $
                self->getThumbnailDescription(fileElement)

            thumbnailId = self->getThumbnailId(fileElement)

            fileDescriptions[i] = obj_new('SpdfFileDescription', $
                name, mimeType, timeInterval, length, lastModified, $
                thumbnailDescription = thumbnailDescription, $
                thumbnailId = thumbnailId)

            obj_destroy, timeInterval
            obj_destroy, thumbnailDescription
        endfor
    end

    return, fileDescriptions
end


;+
; Creates an SpdfThumbnailDescription object from the FileDescription
; element in the given cdas:DataResult XML document.
;
; @private
;
; @param fileElement {in} {type=IDLffXMLDOMDocument}
;              cdas:FileDescription element from a cdas:DataResult XML 
;              document.
; @returns SpdfThumbnailDescription object.
;-
function SpdfCdas::getThumbnailDescription, $
    fileElement
    compile_opt idl2

    thumbnailDescription = obj_new()

    thumbnailDescriptionElements = $
        fileElement->getElementsByTagName('ThumbnailDescription')

    if thumbnailDescriptionElements->getLength() gt 0 then begin

        thumbnailDescriptionElement = $
            thumbnailDescriptionElements->item(0)

        type = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'Type')

        name = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'Name')

        dataset = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'Dataset')

        timeInterval = self->getTimeIntervalChild(thumbnailElement)

        varName = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'VarName')

        options = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'Options')

        numFrames = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'NumFrames')

        numRows = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'NumRows')

        numCols = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'NumCols')

        titleHeight = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'TitleHeight')

        thumbnailHeight = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'ThumbnailHeight')

        thumbnailWidth = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'ThumbnailWidth')

        startRecord = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'StartRecord')

        myScale = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'MyScale')

        xyStep = $
            self->getNamedElementsFirstChildValue(thumbnailElement, $
                'XyStep')

        thumbnailDescription = obj_new('SpdfThumbnailDescription', $
            type, name, dataset, timeInterval, varName, options, $
            numFrames, numRows, numCols, titleHeight, thumbnailHeight, $
            thumbnailWidth, startRecord, myScale, xyStep)

        obj_destroy, timeInterval
    end

    return, thumbnailDescription
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
function SpdfCdas::getTimeIntervalChild, $
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
function SpdfCdas::getTimeInterval, $
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
function SpdfCdas::getJulDate, $
    dateTimeElement
    compile_opt idl2

    dateFormat='(I4, 1X, I2, 1X, I2, 1X, I2, 1X, I2, 1X, I2)'

    dateTimeStr = (dateTimeElement->getFirstChild())->getNodeValue()

    reads, dateTimeStr, format=dateFormat, $
            year, month, day, hour, minute, second

    return, julday(month, day, year, hour, minute, second)
end


;+
; Gets the ThumbnailId value from the given cdas:FileDescription 
; element.
;
; @private
;
; @param fileElement {in} {type=IDLffXMLDOMNode}
;              cdas:FileDescription node.
; @returns ThumbnailId string value.
;-
function SpdfCdas::getThumbnailId, $
    fileElement
    compile_opt idl2

    return, self->getNamedElementsFirstChildValue(fileElement, $
                'ThumbnailId')
end


;+
; Gets the specified node values from the given cdas:DataResult XML 
; document.
;
; @private
;
; @param resultDoc {in} {type=IDLffXMLDOMDocument}
;            cdas:DataResult XML document.
; @param type {in} {type=string}
;            name of elements whose value is to be gotten.  This is
;            expected to be one of Message, Warning, Status, or Error.
; @returns strarr of the specified node values from the given document.
;-
function SpdfCdas::getDataResultText, $
    resultDoc, type

    return, self->getNamedElementsFirstChildValue(resultDoc, type)
end


;+
; Perform an HTTP GET request to the given URL.  This method provides 
; functionality similar to doing    
;     obj_new('IDLffXMLDOMDocument', filename=url)
; except that this method will catch an authorization error (401),
; call the supplied authenticator function, and then retry the
; request with the authentication credentials obtained from the
; call to the callers authentication function.
;
; @private
;
; @param dataview {in} {type=string}
;            name of dataview to access.
; @param url {in} {type=string}
;            URL of GET request to make.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword errorReporter {in} {optional} {type=string}
;              name of IDL procedure to call if an HTTP error occurs.
; @returns reference to IDLffXMLDOMDocument representation of HTTP
;     response entity.
;-
function SpdfCdas::makeGetRequest, $
    dataview, url, $
    authenticator = authenticator, $
    errorReporter = errorReporter
    compile_opt idl2

    username = ''
    password = ''

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        reply = $
            self->handleHttpError( $
                requestUrl, dataview, username, password, $
                authenticator = authenticator, $
                errorReporter = errorReporter)

        obj_destroy, requestUrl

        if reply eq 0 then return, obj_new()

    endif

    requestUrl = self->getRequestUrl(url, username, password)

    result = string(requestUrl->get(/buffer))

    obj_destroy, requestUrl

    return, obj_new('IDLffXMLDOMDocument', string=result)
end


;+
; Perform an HTTP POST request to the given URL.  If an authorization
; error (401) occurs, the supplied authenticator function is called, 
; and then the request is retried with the authentication credentials 
; obtained from the call to the callers authentication function.
;
; @private
;
; @param dataview {in} {type=string}
;            name of dataview to access.
; @param url {in} {type=string}
;            URL of GET request to make.
; @param xmlRequest {in} {type=string}
;            XML entity body to be include in the request.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword errorReporter {in} {optional} {type=string}
;              name of IDL procedure to call if an HTTP error occurs.
; @returns reference to IDLffXMLDOMDocument representation of HTTP
;     response entity.
;-
function SpdfCdas::makePostRequest, $
    dataview, url, xmlRequest, $
    authenticator = authenticator, $
    errorReporter = errorReporter
    compile_opt idl2

    username = ''
    password = ''

    catch, errorStatus
    if (errorStatus ne 0) then begin

        catch, /cancel

        reply = $
            self->handleHttpError( $
                requestUrl, dataview, username, password, $
                authenticator = authenticator, $
                errorReporter = errorReporter)

        obj_destroy, requestUrl

        if reply eq 0 then return, obj_new()

    endif

    requestUrl = self->getRequestUrl(url, username, password)

    requestUrl->setProperty, header='Content-Type: application/xml'

; print, 'POSTing ', xmlRequest
; print, 'to ', url
; requestUrl.GetProperty, ssl_verify_peer=sslVerifyPeer
; print, 'ssl_verify_peer =', sslVerifyPeer
; requestUrl.SetProperty, ssl_verify_host=0
; requestUrl.GetProperty, ssl_verify_host=sslVerifyHost
; print, 'ssl_verify_host =', sslVerifyHost

    result = requestUrl->put(xmlRequest, /buffer, /post, url=url)

    obj_destroy, requestUrl

    return, obj_new('IDLffXMLDOMDocument', filename=result)
end


;+
; Function to handle HTTP request errors.  If an authorization error
; (401) has occurred and an authenticator is provided, the given
; authenticator is called to obtain authentication credentials.
; For any other error, if an errorReporter has been provided, it is
; called.
;
; @private
;
; @param request {in} {type=IDLnetURL}
;            HTTP request that caused the error.
; @param dataview {in} {type=string}
;            name of dataview to access.
; @param username {out} {type=string}
;            username value obtained by calling the given authenticator.
; @param password {out} {type=string}
;            password value obtained by calling the given authenticator.
; @keyword authenticator {in} {optional} {type=SpdfAuthenticator}
;              authenticator that is used when a dataview requiring
;              authentication is specified.
; @keyword errorReporter {in} {optional} {type=string}
;              name of IDL procedure to call if an HTTP error occurs.
; @returns a value of 1 if username and password has been set and a 
;     value of 0 if not. 
;-
function SpdfCdas::handleHttpError, $
    request, dataview, username, password, $
    authenticator = authenticator, $
    errorReporter = errorReporter
    compile_opt idl2

    request->getProperty, $
        response_code=responseCode, $
        response_header=responseHeader, $
        response_filename=responseFilename

    if responseCode eq 401 && $
       keyword_set(authenticator) then begin

        reply = $
            call_method('getCredentials', authenticator, $
                dataview, username, password)

        if reply eq 0 then begin

            return, 0
        endif
    endif else begin

        if keyword_set(errorReporter) then begin

            call_method, 'reportError', errorReporter, $
                    responseCode, responseHeader, responseFilename
        endif

        return, 0
    endelse

    return, 1
end


;+
; Create an IDLnetURL object from the given URL with any supplied
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
; @returns reference to a IDLnetURL with any supplied authentication
;     values set.
;-
function SpdfCdas::getRequestUrl, $
    url, username, password
    compile_opt idl2

    requestUrl = $
        obj_new('IDLnetURL', $
                proxy_authentication = self.proxy_authentication, $
                proxy_hostname = self.proxy_hostname, $
                proxy_port = self.proxy_port, $
                proxy_username = self.proxy_username, $
                proxy_password = self.proxy_password, $
                ssl_verify_peer = self.ssl_verify_peer)

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
; Defines the SpdfCdas class.
;
; @field endpoint URL of CDAS web service.
; @field defaultDataview CDAS dataview to access when the dataview is
;               not specified.
; @field userAgent HTTP 
;            <a href="https://tools.ietf.org/html/rfc2616#section-14.43">
;               user-agent value</a> to use in communications with CDAS.
; @field version identifies the version of this class.
; @field currentVersionUrl URL to the file identifying the most up to 
;            date version of this class.
; @field proxy_authentication IDLnetURL PROXY_AUTHENTICATION property
;            value.
; @field proxy_hostname IDLnetURL PROXY_HOSTNAME property value.
; @field proxy_password IDLnetURL PROXY_PASSWORD property value.
; @field proxy_port IDLnetURL PROXY_PORT property value.
; @field proxy_username IDLnetURL PROXY_USERNAME property value.
; @field ssl_verify_peer IDLnetURL SSL_VERIFY_PEER property value.
;-
pro SpdfCdas__define
    compile_opt idl2
    struct = { SpdfCdas, $
        endpoint:'', $
        userAgent:'', $
        defaultDataview:'', $
        version:'', $
        currentVersionUrl:'', $
        proxy_authentication:0, $
        proxy_hostname:'', $
        proxy_password:'', $
        proxy_port:'', $
        proxy_username:'', $
        ssl_verify_peer:1 $
    }
end
