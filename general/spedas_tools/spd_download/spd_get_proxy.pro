;+
;Procedure:
;  spd_get_proxy
;
;Purpose:
;  Gets "http_proxy" environment variable and adds parsed proxy
;  properties to an input structure for use with idlneturl.
;
;Calling Sequence:
;  spd_get_proxy, structure
;
;Arguments:
;  structure: Structure to which the idlneturl proxy properties will be appended.
;             Existing properties will not be overwritten.  If undefined or not 
;             valid then a structure with said properties will be returned.
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-08-28 14:36:40 -0700 (Fri, 28 Aug 2015) $
;$LastChangedRevision: 18666 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_download/spd_get_proxy.pro $
;-

pro spd_get_proxy, s

    compile_opt idl2, hidden


proxy = getenv('http_proxy')
if proxy eq '' then return

;parse
proxy_elements = parse_url(proxy)

;no need to proceed if cannot parse a host
if proxy_elements.host eq '' then return

;place in structure corresponding to idlneturl properties
property_struct = { proxy_hostname: proxy_elements.host, $
                    proxy_port: proxy_elements.port, $
                    proxy_username: proxy_elements.username, $
                    proxy_password: proxy_elements.password } 

;pass out via input structure
;do not replace any existing tags
if is_struct(s) then begin

  input_tags = tag_names(s)
  properties = tag_names(property_struct)

  for i=0, n_elements(properties)-1 do begin
    if in_set(properties[i],input_tags) then continue
    s = create_struct(s,properties[i],property_struct.(i))
  endfor

endif else begin
  s = property_struct
endelse


end