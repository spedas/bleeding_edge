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
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2010-2017 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;


;+
; This program is an example to demonstrate calling the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis
; System</a>'s 
; <a href="https://cdaweb.gsfc.nasa.gov/WebServices/REST/">
; REST Web Services</a> from an 
; <a href="http://www.harrisgeospatial.com/">Exelis Visual Information 
; Solutions</a>
; (VIS) Interactive Data Language (IDL) program.  It demonstrates the 
; following:
;   <ul>
;     <li>Getting the available dataviews.</li>
;     <li>Getting the available mission groups.</li>
;     <li>Getting the available instrument types.</li>
;     <li>Getting the available datasets for ACE.</li>
;     <li>Getting the variables for the AC_H0_MFI dataset.</li>
;     <li>Getting and displaying a portion of an ASCII listing of 
;         AC_H0_MFI data.</li>
;     <li>Getting a CDF file of AC_H0_MFI data and displaying some of 
;         the file's attributes.</li>
;     <li>Getting and displaying a graph of AC_H0_MFI data.</li>
;     <li>Some basic HTTP error handling.</li>
;   </ul>
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-



;+
; This procedure demonstrates how to obtain a local copy of a remote 
; CDF file and display some CDF information about the file's contents.
;
; @param fileDescription {in} {type=SpdfFileDescription}
;            description of a remote CDF file.
;-
pro getCdfFile, $
    fileDescription
    compile_opt idl2

    filename = fileDescription->getFile()

    cdfId = cdf_open(filename)

    cdfInfo = cdf_inquire(cdfId)

    help, cdfInfo, /structure

    cdf_delete, cdfId
end


;+
; This procedure demonstrates how to obtain a local copy of a remote 
; text file and display a portion of its contents.
;
; @param fileDescription {in} {type=SpdfFileDescription}
;            description of a remote CDF file.
;-
pro getTextFile, $
    fileDescription
    compile_opt idl2

    text = fileDescription->getFile(/string_array)

    print, '    Contents:'

    for i = 0, min ([69, n_elements(text) - 1]) do begin

        print, '    ', text[i]
    endfor
end


;+
; This procedure demonstrates how to check the MIME-type of an 
; SpdfFileDescription and, if it is of type "image/png", to get a local
; copy and display the image.
;
; @param fileDescription {in} {type=SpdfFileDescription}
;            description of a remote file
;-
pro getFile, $
    fileDescription
    compile_opt idl2

    mimeType = fileDescription->getMimeType()

    print, '    MIME-type:', mimeType

    if mimeType eq 'image/png' then begin

        filename = fileDescription->getFile()

        image = read_png(filename)
;        tv, image
;        iimage, image
        iimage, filename
    end
end


;+
; This procedure demonstrates how to examine an SpdfFileDescription 
; and then display it based upon it MIME-type.
;
; @param fileDescription {in} {type=SpdfFileDescription}
;            description of a remote file.
;-
pro getResultFile, $
    fileDescription
    compile_opt idl2

    print, '    File name: ', fileDescription->getName()
    print, '    File length: ', fileDescription->getLength()

    mimeType = fileDescription->getMimeType()

    case mimeType of
        'application/vnd.nasa.cdf': getCdfFile, fileDescription
        'text/plain': getTextFile, fileDescription
        else: getFile, fileDescription
    endcase
end


;+
; This procedure demonstrates how to examine the result of a data 
; request.
;
; @param results {in} {type=SpdfCdasDataResult}
;            results of a data request.
;-
pro getDataResults, $
    results
    compile_opt idl2

    print, 'Data Results:'

    fileDescriptions = results->getFileDescriptions()

    for i = 0, n_elements(fileDescriptions) - 1 do begin

        getResultFile, fileDescriptions[i]
    endfor

    obj_destroy, fileDescriptions
end


;+
; This procedure is an example to demonstrate calling the CDAS REST
; Web Services from an IDL program.  It demonstrates the following:
;   <ul>
;     <li>Getting the available dataviews.</li>
;     <li>Getting the available mission groups.</li>
;     <li>Getting the available instrument types.</li>
;     <li>Getting the available datasets for ACE.</li>
;     <li>Getting the variables for the AC_H0_MFI dataset.</li>
;     <li>Getting and displaying a portion of an ASCII listing of 
;         AC_H0_MFI data.</li>
;     <li>Getting a CDF file of AC_H0_MFI data and displaying some of 
;         the file's attributes.</li>
;     <li>Getting and displaying a graph of AC_H0_MFI data.</li>
;     <li>Some basic HTTP error handling.</li>
;   </ul>
;-
pro SpdfCdasWsExample
    compile_opt idl2
    print, "Calling CDAS REST Web Services to get the Dataviews'

    cdas = $
        obj_new('SpdfCdas', $
            userAgent = 'WsExample', $
            defaultDataview = 'sp_phys')

    errReporter = obj_new('SpdfHttpErrorReporter');

    dataviews = cdas->getDataviews(httpErrorReporter = errReporter)

    print, 'Dataviews:'
    for i = 0, n_elements(dataviews) - 1 do begin

        print, '  ', (dataviews[i])->getId(), '  ', $
            (dataviews[i])->getTitle()
    endfor
    print

    obj_destroy, dataviews


    observatoryGroups = $
        cdas->getObservatoryGroups(httpErrorReporter = errReporter)

    print, 'ObservatoryGroups:'
    for i = 0, n_elements(observatoryGroups) - 1 do begin
 
        observatoryGroups[i]->print
        print
    endfor

    obj_destroy, observatoryGroups


    instrumentTypes = $
        cdas->getInstrumentTypes(httpErrorReporter = errReporter)

    print, 'InstrumentTypes:'
    for i = 0, n_elements(instrumentTypes) - 1 do begin

        instrumentTypes[i]->print
    endfor

    obj_destroy, instrumentTypes


    datasets = $
        cdas->getDatasets( $
            observatoryGroups = ['ACE'], $
            httpErrorReporter = errReporter)

    print, 'Datasets:'

    for i = 0, n_elements(datasets) - 1 do begin

        datasets[i]->print
    endfor

    print, ' got ', n_elements(datasets), ' datasets'

    obj_destroy, datasets


    dataset = 'AC_H0_MFI'

    vars = $
        cdas->getVariables(dataset, httpErrorReporter = errReporter)

    varNames = strarr(n_elements(vars))

    print, 'Variables:'

    for i = 0, n_elements(vars) - 1 do begin

        varNames[i] = vars[i]->getName()
        
        vars[i]->print
    endfor

    obj_destroy, vars

    dataset = 'spase://VHO/NumericalData/ACE/MAG/L2_PT16S'

    timeInterval = $
        obj_new('SpdfTimeInterval', $
            julday(1, 1, 2006, 0, 0, 0), $
            julday(1, 1, 2006, 0, 30, 0))

    dataResults = $
        cdas->getTextData( $
            timeInterval, dataset, varNames, $
            httpErrorReporter = errReporter)

    obj_destroy, timeInterval

    getDataResults, dataResults

    obj_destroy, dataResults


    timeInterval = $
        obj_new('SpdfTimeInterval', $
            julday(1, 1, 2006, 0, 0, 0), $
            julday(1, 2, 2006, 0, 0, 0))

    dataResults = $
        cdas->getCdfData( $
            timeInterval, dataset, varNames, $
            httpErrorReporter = errReporter)

    getDataResults, dataResults

    obj_destroy, dataResults


    datasetRequest = $
        obj_new('SpdfDatasetRequest', dataset, varNames)

    datasetRequests = [datasetRequest]

    dataResults = $
        cdas->getGraphData( $
            timeInterval, datasetRequests, $
            httpErrorReporter = errReporter)

    obj_destroy, timeInterval
    obj_destroy, datasetRequests

    getDataResults, dataResults

    obj_destroy, dataResults


    obj_destroy, cdas
end

