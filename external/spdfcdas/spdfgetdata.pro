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
; This file contains a procedure-oriented wrapper that integrates
; functionality from the SpdfCdas class (IDL client interface to
; <a href="https://cdaweb.gsfc.nasa.gov/WebServices">
; Coordinated Data Analysis System Web Services</a> (CDAS WSs))
; and the 
; <a href="https://spdf.gsfc.nasa.gov/CDAWlib.html">CDAWlib</a>
; library.
;
; @copyright Copyright (c) 2010-2017 United States Government as 
;     represented by the National Aeronautics and Space 
;     Administration. No copyright is claimed in the United States 
;     under Title 17, U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; This function is an example of a callback_function for the
; spdfGetData function.
;
; @param statusInfo {in} {type=strarr}
; @param progressInfo {in} {type=lon64arr}
; @param callbackData {in} {type=reference}
; @returns a continue flag.  A return value of zero indicates that
;     the operation should be cancelled.  A return value of one 
;     indicates that the operation should continue.
;-
function SpdfGetDataCallback, $
    statusInfo, progressInfo, callbackData
    compile_opt idl2

    print, 'spdfGetDataCallback: statusInfo:', statusInfo

    if progressInfo[0] eq 1 then begin

        percentComplete = $
            double(progressInfo[2]) / progressInfo[1] * 100.0

        print, progressinfo[2], progressInfo[1], percentComplete, $
            format='(%"spdfGetDataCallback: (%d) bytes of (%d) complete (%f%%)")'
    endif

    return, 1
end


;+
; This function gets data from <a href="https://www.nasa.gov/">NASA</a>'s
; <a href="https://spdf.gsfc.nasa.gov/">Space Physics Data Facility</a>
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis 
; System</a>.
;
; @param dataset {in} {type=string}
;            name of dataset to get data from.
; @param variables {in} {out} {type=strarr}
;            On entry, names of variables whose values are to be gotten.
;            If the first (only) name is "ALL-VARIABLES", then the 
;            resulting CDF will contain all variables.
;            On exit, names of variables actually read (may be more 
;            than requested).
; @param timeSpans {in} {type=strarr(n, 2)}
;            ISO 8601 format strings of the start and stop times of the
;            data to get.
; @keyword dataview {in} {optional} {type=string} {default='sp_phys'}
;            name of dataview containing the dataset.
; @keyword endpoint {in} {optional} {type=string}
;              {default='https://cdaweb.gsfc.nasa.gov/WS/cdasr/1'}
;              URL of CDAS web service.
; @keyword keepfiles {in} {optional} {type=boolean} {default=false}
;            The KEEPFILES keyword causes SpdfGetData to retain the
;            downloaded data files.  Normally these files are deleted
;            after the data is read into the IDL environment.
; @keyword quiet {in} {optional} {type=boolean} {default=false}
;            SpdfGetData normally prints an error message if no data is
;            found.  If QUIET is set, no error messages is printed.
; @keyword verbose {in} {optional} {type=boolean} {default=false}
;            The VERBOSE keyword causes SpdfGetData to print additional
;            status, debugging, and usage information.
; @keyword callback_function {in} {optional} {type=string}
;            this keyword value is the name of the IDL function that
;            is to be called during this retrieval operation.  The 
;            callbacks provide feedback to the user about the ongoing 
;            operation, as well as provide a method to cancel an 
;            ongoing operation. If this keyword is not set, no
;            callback to the caller is made.  For information on 
;            creating a callback function, see "Using Callbacks with 
;            the IDLnetURL Object" in the IDL documentation.
; @keyword callback_data {in} {optional} {type=reference}
;            this keyword value contains data that is passed to the 
;            caller when a callback is made. The data contained in 
;            this variable is defined and set by the caller. The 
;            variable is passed, unmodified, directly to the caller 
;            as a parameter in the callback function. If this keyword
;            is not set, the corresponding callback parameter's value
;            is undefined.
; @keyword sslVerifyPeer {in} {optional} {type=int} {default=1}
;            Specifies whether the authenticity of the peer's SSL
;            certificate should be verified.  When 0, the connection 
;            succeeds regardless of what the peer SSL certificate 
;            contains.
; @returns structure containing requested data.  Note that a few 
;     datasets in CDAS contain variables with names that cannot
;     be used as tag names an IDL structure.  In those cases, the
;     tag name in this structure will be a modification of the
;     actual CDF variable name.  For example, if you requested the
;     'H+' variable from the 'FA_K0_TMS' dataset, the 'H+' values
;     will be returned in a structure under the tag name 'H$'.
; @examples
;   <pre>
;     d = spdfgetdata('AC_K2_MFI', ['Magnitude', 'BGSEc'], $
;           ['2013-01-01T00:00:00.000Z', '2013-01-03T00:00:00.000Z'], $
;           /VERBOSE)
;
;     The Epoch values are returned in d.epoch.dat
;     The Magnitude values are in d.magnitude.dat
;     The BGSEc values are in d.bgsec.dat
; 
;    To see further info. about each variable type 
;        help, /struct, d."variablename"
;    To make a plot with the CDAWlib s/w type 
;        s = plotmaster(d, /AUTO, /CDAWEB, /GIF, /SMOOTH, /SLOW)
;   </pre>
;-
function SpdfGetData, $
    dataset, $
    variables, $
    timeSpans, $
    dataview = dataview, $
    endpoint = endpoint, $
    keepfiles = keepfiles, $
    quiet = quiet, $
    verbose = verbose, $
    callback_function = callback_function, $
    callback_data = callback_data, $
    sslVerifyPeer = sslVerifyPeer
    compile_opt idl2

    spd_cdawlib_virtual_funcs ; compile required functions
    
    if ~keyword_set(dataview) then begin

        dataview = 'sp_phys'
    end

    cdas = $
        obj_new('SpdfCdas', $
            endpoint = endpoint, $
            userAgent = 'SpdfGetData', $
            defaultDataview = dataview, $
            sslVerifyPeer = sslVerifyPeer)

    sizeTimeSpans = size(timeSpans)

    if sizeTimeSpans[0] eq 1 then begin

        timeIntervals = $
            [obj_new('SpdfTimeInterval', timeSpans[0], timeSpans[1])]

    endif else begin
        if sizeTimeSpans[0] eq 2 then begin

            timeIntervals = objarr(sizeTimeSpans[1])

            for i = 0, sizeTimeSpans[1] - 1 do begin

                timeIntervals[i] = $
                    obj_new('SpdfTimeInterval', $
                        timeSpans[0, i], timeSpans[1, i])
            endfor
        endif else begin

            if ~keyword_set(quiet) then begin

                print, 'Error: size(timeSpans) = ', sizeTimeSpans
            endif
            obj_destroy, cdas

            return, obj_new()
        endelse
    endelse

    httpErrorReporter = obj_new('SpdfHttpErrorReporter')

    dataResults = $
        cdas->getCdfData( $
            timeIntervals, dataset, variables, $
            httpErrorReporter = httpErrorReporter)

    if ~obj_valid(dataResults) then begin

        obj_destroy, timeIntervals
        obj_destroy, cdas

        return, obj_new()
    endif
    fileDescriptions = dataResults->getFileDescriptions()

    if n_elements(fileDescriptions) gt 0 then begin

        cd, current=cwd

        if ~file_test(cwd, /write) then begin

            tmpDir = getenv('IDL_TMPDIR')
            pushd, tmpDir

            if ~keyword_set(quiet) then begin

                print, 'Warning: The current working directory (', $
                       cwd, ') is not writable.'
                print, 'Temporarily changing working directory to ', $
                       tmpDir
                if keyword_set(keepfiles) then begin

                    print, 'Downloaded files will be saved to ', tmpDir
                endif
            endif
        endif

        localCdfNames = strarr(n_elements(fileDescriptions))

        for i = 0, n_elements(fileDescriptions) - 1 do begin

            if obj_valid(fileDescriptions[i]) then begin

                if keyword_set(callback_function) then begin

                    statusInfo = strarr(1)
                    statusInfo[0] = $
                        string(i + 1, n_elements(fileDescriptions), $
                               fileDescriptions[i]->getName(), $
                               format='(%"Beginning file retrieval (%d) of (%d) (%s)")')

                    progressInfo = lon64arr(5)
                    progressInfo[0] = 0

                    continue = call_function(callback_function, $
                                             statusInfo, $
                                             progressInfo, $
                                             callback_data)
                    if ~continue then begin

                        obj_destroy, fileDescriptions
                        obj_destroy, dataResults
                        obj_destroy, timeIntervals
                        obj_destroy, cdas

                        if n_elements(tmpDir) ne 0 then popd
                        return, 1
                    endif
                endif
                localCdfNames[i] = $
                    fileDescriptions[i]->getFile($
                        callback_function=callback_function, $
                        callback_data=callback_data, $
                        sslVerifyPeer=sslVerifyPeer)
            endif else begin

                if keyword_set(verbose) then dataResults->print

                obj_destroy, fileDescriptions
                obj_destroy, dataResults
                obj_destroy, timeIntervals
                obj_destroy, cdas

                if n_elements(tmpDir) ne 0 then popd
                return, 1
            endelse
        endfor

        localCdfNames2 = localCdfNames
        allVars = ''
        ; reads data into handles (memory) should be fastest
        data = spd_cdawlib_read_mycdf(allVars, localCdfNames2, all = 1, $
                          /nodata) 

        ; reads data into .dat structure tags
        ; data = read_mycdf(variables, localCdfNames) 

        if n_tags(data) eq 3 && $
           array_equal (tag_names(data), $
               ['DATASET', 'ERROR', 'STATUS']) then begin
 
            if keyword_set(verbose) then begin

                print, 'Error in read_mycdf()'
                print, '  ERROR: ', data.error
                print, '  STATUS: ', data.status
            endif

            obj_destroy, fileDescriptions
            obj_destroy, dataResults
            obj_destroy, timeIntervals
            obj_destroy, cdas

            return, 1
        endif

        newbuf = spd_cdawlib_hsave_struct(data, /nosave) 
        ; don't use the /nosave if you want it saved
        ; to a save file, need to specify a file name though.

        if ~keyword_set(keepfiles) then begin

            file_delete, localCdfNames
        endif
        if keyword_set(verbose) then begin

            if keyword_set(keepfiles) then begin

                print, 'Data sub/superset returned in local CDF file: ', $
                       localCdfNames
            endif
            print, '   '
            print, 'Data variables returned are:'
            print, '   '
            help, /struct, newbuf
            print, '   '

        endif

    endif else begin

        if ~keyword_set(quiet) then begin

            print, 'No data found'
        endif
    endelse

    obj_destroy, fileDescriptions
    obj_destroy, dataResults
    obj_destroy, timeIntervals
    obj_destroy, cdas

    if keyword_set(verbose) then begin

        print, 'Data values are returned in the data structure in each variables .dat tag member. '
        print, '   '
        print, "For example - for the call d = spdfgetdata('AC_K2_MFI', ['Magnitude', 'BGSEc'], ['2013-01-01T00:00:00.000Z', '2013-01-03T00:00:00.000Z'])"
        print, '   '
        print, 'The Epoch values are returned in d.epoch.dat'
        print, 'the Magnitude values are in d.magnitude.dat'
        print, 'and the BGSEc values are in d.bgsec.dat'
        print, '   '
        print, 'To see further info. about each variable type help, /struct, d."variablename"'
        print, 'To make a plot with the CDAWlib s/w type s = plotmaster(d, /AUTO, /CDAWEB, /GIF, /SMOOTH, /SLOW)

    endif

    if n_elements(tmpDir) ne 0 then popd

    return, newbuf  ; data
end
