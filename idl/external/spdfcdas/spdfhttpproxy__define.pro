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
; Copyright (c) 2021 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;


;+
; This class represent HTTP proxy settings.
;
; @copyright Copyright (c) 2021 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfHttpProxy object with values suitable for use with the
; IDLnetURL object.  If no parameter values are given, the HTTP_PROXY
; environment variable is examined.  If it has a value, then its value
; is used to initialize this object.  The HTTP_PROXY value should be of 
; the form http://username:password@hostname:port/.  If the HTTP_PROXY
; environment is not set, this object's initial value will indicate to
; IDLnetURL not to use a proxy.  See IDLnetURL documentation for more
; details about the values.
;
; @keyword authentication {in} {type=int} {optional}
;     Type of authentication used when connecting to a proxy server.
; @keyword hostname {in} {type=string} {optional}
;     The proxy server name.
; @keyword port {in} {type=string} {optional}
;     The proxy's TCP/IP port.
; @keyword username {in} {type=string} {optional}
;     Username for authenticating with the proxy server.
; @keyword password {in} {type=string} {optional}
;     Password for authenticating with the proxy server.
;-
function SpdfHttpProxy::init, $
    authentication = authentication, $
    hostname = hostname, $
    port = port, $
    username = username, $
    password = password
    compile_opt idl2

    if ~keyword_set(authentication) and $
       ~keyword_set(hostname) and $
       ~keyword_set(password) and $
       ~keyword_set(port) and $
       ~keyword_set(username) then begin

        http_proxy = getenv('HTTP_PROXY')

        if strlen(http_proxy) gt 0 then begin

            proxyComponents = parse_url(http_proxy)

            self.hostname = proxyComponents.host
            self.password = proxyComponents.password
            self.port = proxyComponents.port
            self.username = proxyComponents.username
            self.authentication = 0

            if strlen(proxyComponents.Username) gt 0 then begin

                self.authentication = 3
            endif 

            return, self
        endif
    endif
    self.authentication = 0
    if keyword_set(authentication) then self.authentication = authentication
    hostname = ''
    if keyword_set(hostname) then self.hostname = hostname
    password = ''
    if keyword_set(password) then self.password = password
    port = '80'
    if keyword_set(port) then self.port = port
    username = ''
    if keyword_set(username) then self.username = username

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfHttpProxy::cleanup
    compile_opt idl2

end


;+
; Gets the authentication value.
;
; @returns authentication value.
;-
function SpdfHttpProxy::getAuthentication
    compile_opt idl2

    return, self.authentication
end


;+
; Sets the authentication value.
;
; @param value {in} {type=int} new value.
;-
pro SpdfHttpProxy::setAuthentication, $
    value
    compile_opt idl2

    self.authentication = value
end


;+
; Gets the hostname value.
;
; @returns hostname value.
;-
function SpdfHttpProxy::getHostname
    compile_opt idl2

    return, self.hostname
end


;+
; Sets the hostname value.
;
; @param value {in} {type=string} new value.
;-
pro SpdfHttpProxy::setHostname, $
    value
    compile_opt idl2

    self.hostname = value
end


;+
; Gets the password value.
;
; @returns password value.
;-
function SpdfHttpProxy::getPassword
    compile_opt idl2

    return, self.password
end


;+
; Sets the password value.
;
; @param value {in} {type=string} new value.
;-
pro SpdfHttpProxy::setPassword, $
    value
    compile_opt idl2

    self.password = value
end


;+
; Gets the port value.
;
; @returns port value.
;-
function SpdfHttpProxy::getPort
    compile_opt idl2

    return, self.port
end


;+
; Sets the port value.
;
; @param value {in} {type=string} new value.
;-
pro SpdfHttpProxy::setPort, $
    value
    compile_opt idl2

    self.port = value
end


;+
; Gets the username value.
;
; @returns username value.
;-
function SpdfHttpProxy::getUsername
    compile_opt idl2

    return, self.username
end


;+
; Sets the username value.
;
; @param value {in} {type=string} new value.
;-
pro SpdfHttpProxy::setUsername, $
    value
    compile_opt idl2

    self.username = value
end


; Defines the SpdfHttpProxy class.  Refer to the IDLnetURL PROXY_* 
; properties documentation for more details about the values.
;
; @field authentication the type of authentication used when connecting to 
;     a proxy server.
; @field hostname the proxy server name.
; @field password authentication password.
; @field port the TCP/IP port that the proxy server monitors for incoming 
;     requests.
; @field username authentiction username.
;-
pro SpdfHttpProxy__define
    compile_opt idl2
    struct = { SpdfHttpProxy, $
        authentication:0, $
        hostname:'', $
        password:'', $
        port:'', $
        username:'' $
    }
end
