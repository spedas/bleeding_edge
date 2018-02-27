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
; in the United States under Title 17, U.S.Code. All Other Rights 
; Reserved.
;
;



;+
; This class is an IDL representation of the FileDescription element 
; from the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis 
; System</a> (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2017 United States Government as 
;     represented by the National Aeronautics and Space 
;     Administration. No copyright is claimed in the United States 
;     under Title 17, U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfFileDescription object.
;
; If access to the Internet is through an HTTP proxy, the caller 
; should ensure that the HTTP_PROXY environment is correctly set 
; before this method is called.  The HTTP_PROXY value should be of 
; the form 
; http://username:password@hostname:port/.
;
; @param name {in} {type=string}
;            name of file.
; @param mimeType {in} {type=string}
;            (Multipurpose Internet Mail Extensions) MIME-type of file.
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time interval of the data in this file.
; @param length {in} {type=long64}
;            length (in bytes) of file.
; @param lastModified {in} {type=double}
;            date file was last modified (julday value).
; @keyword thumbnailDescription {in} {optional}
;            {type=SpdfThumbnailDescription}
;            if file contains thumbnail images, then this describes
;            them.
; @keyword thumbnailId {in} {optional} {type=SpdfThumbnailId}
;            if file contains thumbnail images, then this contains
;            an opaque value that the server needs to provide 
;            full-sized versions of the images.
; @returns reference to an SpdfFileDescription object.
;-
function SpdfFileDescription::init, $
    name, mimeType, timeInterval, length, lastModified, $
    thumbnailDescription = thumbnailDescription, $
    thumbnailId = thumbnailId
    compile_opt idl2

    self.name = name
    self.mimeType = mimeType
    self.timeInterval = timeInterval
    self.length = length
    self.lastModified = lastModified

    if keyword_set(thumbnailDescription) then begin

        self.thumbnailDescription = thumbnailDescription
    end

    if keyword_set(thumbnailId) then begin

        self.thumbnailId = thumbnailId
    end

    http_proxy = getenv('HTTP_PROXY')

    if strlen(http_proxy) gt 0 then begin

        proxyComponents = parse_url(http_proxy)

        self.proxy_hostname = proxyComponents.host
        self.proxy_password = proxyComponents.password
        self.proxy_port = proxyComponents.port
        self.proxy_username = proxyComponents.username

        if strlen(self.proxy_username) gt 0 then begin

            self.proxy_authentication = 3
        endif
    endif

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfFileDescription::cleanup
    compile_opt idl2

    if obj_valid(self.timeInterval) then obj_destroy, self.timeInterval
    if obj_valid(self.thumbnailDescription) then $
        obj_destroy, self.thumbnailDescription
end


;+
; Gets the file's name.
;
; @returns filename value.
;-
function SpdfFileDescription::getName
    compile_opt idl2

    return, self.name
end


;+
; Gets the MIME-type of file.
;
; @returns MIME-type value.
;-
function SpdfFileDescription::getMimeType
    compile_opt idl2

    return, self.mimeType
end


;+
; Gets time interval of data in file.
;
; @returns time interval of data.
;-
function SpdfFileDescription::getTimeInterval
    compile_opt idl2

    return, self.timeInterval
end


;+
; Gets the file's length (in bytes).
;
; @returns file's length (bytes).
;-
function SpdfFileDescription::getLength
    compile_opt idl2

    return, self.length
end


;+
; Gets date the file was last modified.
;
; @returns date of last modification (julday value).
;-
function SpdfFileDescription::getLastModified
    compile_opt idl2

    return, self.lastModified
end


;+
; Gets thumbnail description.
;
; @returns thumbnail description or NULL object reference if this file
;     is not thumbnail images.
;-
function SpdfFileDescription::getThumbnailDescription
    compile_opt idl2

    return, self.thumbnailDescription
end


;+
; Gets thumbnail identifier.
;
; @returns thumbnail identifier or an empty string if this file
;     is not thumbnail images.
;-
function SpdfFileDescription::getThumbnailId
    compile_opt idl2

    return, self.thumbnailId
end


;+
; Prints a textual representation of this object.
;-
pro SpdfFileDescription::print
    compile_opt idl2

    print, 'Name: ', self.name
;    print, 'MimeType: ', self.mimeType
;    if ptr_valid(self.timeInterval) then begin
;    end
;    print, 'Length: ', self.length
;    print, 'LastModified: ', self.lastModified
;    if ptr_valid(self.thumbnailDescription) then begin
;    end
end


;+
; Retrieves this file from a remote HTTP or FTP server and writes 
; it to disk, a memory buffer, or an array of strings. The returned 
; data is written to disk in the location specified by the FILENAME 
; keyword. If the filename is not specified, the local name will be
; the same as this file's name in the current working directory.
; 
; @keyword buffer {in} {optional} {type=boolean} {default=false}
;            if this keyword is set, the return value is a buffer 
;            and the FILENAME keyword is ignored.
; @keyword filename {in} {optional} {type=string} 
;            set this keyword equal to a string that holds the file 
;            name and path where the retrieved file is locally stored.
;            If FILENAME specifies a full path, the file is stored in 
;            the specified path.  If FILENAME specifies a relative 
;            path, the path is relative to IDL's current working 
;            directory.  If FILENAME is not present the file is
;            stored in the current working directory under the name 
;            the basename of filename.  If FILENAME is the same 
;            between calls, the last file received is overwritten.
; @keyword string_array {in} {optional} {type=boolean} {default=false}
;            set this keyword to treat the return value as an array 
;            of strings. If this keyword is set, the FILENAME and 
;            BUFFER keywords are ignored.
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
; @returns one of the following: A string containing the full path 
;            of the file retrieved from the remote HTTP or FTP server,
;            A byte vector, if the BUFFER keyword is set, An array of 
;            strings, if the STRING_ARRAY keyword is set, A null 
;            string, if no data were returned by the method.
;-
function SpdfFileDescription::getFile, $
    buffer = buffer, filename = filename, $
    string_array = string_array, $ 
    callback_function = callback_function, $
    callback_data = callback_data, $
    sslVerifyPeer = sslVerifyPeer
    compile_opt idl2

    if n_elements(filename) eq 0 then begin

        urlComponents = parse_url(self.name)
        filename = file_basename(urlComponents.path)
    endif

    if n_elements(sslVerifyPeer) eq 0 then begin

        sslVerifyPeer = 1
    endif

    fileUrl = $
        obj_new('IDLnetUrl', $
                proxy_authentication = self.proxy_authentication, $
                proxy_hostname = self.proxy_hostname, $
                proxy_port = self.proxy_port, $
                proxy_username = self.proxy_username, $
                proxy_password = self.proxy_password, $
                ssl_verify_peer = sslVerifyPeer)

    if keyword_set(callback_function) then begin

        fileUrl -> setProperty, callback_function = callback_function
    endif

    if keyword_set(callback_data) then begin

        fileUrl -> setProperty, callback_data = callback_data
    endif

    result = fileUrl->get(buffer = buffer, filename = filename, $
                 string_array = string_array, url = self.name)

    obj_destroy, fileUrl

    return, result
end


;+
; Defines the SpdfFileDescription class.
;
; @field name name of file.
; @field mimeType MIME-type of file.
; @field timeInterval time interval of data in file.
; @field length file's length (in bytes).
; @field lastModified data of last modification (julday).
; @field thumbnailDescription description of thumbnail images when
;            this file contains thumbnail images.  Otherwise, NULL.
; @field thumbnailId thumbnail description identifier when this file
;            contains thumbnail images.  Otherwise, ''.
; @field proxy_authentication IDLnetURL PROXY_AUTHENTICATION property
;            value.
; @field proxy_hostname IDLnetURL PROXY_HOSTNAME property value.
; @field proxy_password IDLnetURL PROXY_PASSWORD property value.
; @field proxy_port IDLnetURL PROXY_PORT property value.
; @field proxy_username IDLnetURL PROXY_USERNAME property value.
;-
pro SpdfFileDescription__define
    compile_opt idl2
    struct = { SpdfFileDescription, $
        name:'', $
        mimeType:'', $
        timeInterval:obj_new(), $
        length:0LL, $
        lastModified:0.0D, $
        thumbnailDescription:obj_new(), $
        thumbnailId:'', $
        proxy_authentication:0, $
        proxy_hostname:'', $
        proxy_password:'', $
        proxy_port:'', $
        proxy_username:'' $
    }
end
