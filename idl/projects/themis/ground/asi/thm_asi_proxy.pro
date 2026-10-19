;+
;FUNCTION:
;  thm_asi_proxy
;
;PURPOSE:
;  Resolve the HTTP proxy configuration to use for THEMIS ASI / REGO
;  archive traffic, returned with IDLnetURL property names so the result
;  can be applied directly with IDLnetURL::SetProperty or handed to
;  spd_download through _extra.
;
;  This exists so that the API listing call (thm_asi_get_urls,
;  which drives its own IDLnetURL object) obeys the same proxy settings as
;  the file downloads, which go through spd_download and therefore already
;  pick up http_proxy inside spd_download_file.
;
;  Resolution order:
;    1. AURORAX_PROXY_HOSTNAME and AURORAX_PROXY_PORT (with optional
;       AURORAX_PROXY_USERNAME / AURORAX_PROXY_PASSWORD). This is the
;       idl-aurorax convention, kept so existing setups keep working, and
;       treated as an override because it is the more specific setting.
;    2. http_proxy, the standard SPEDAS convention, parsed by spd_get_proxy
;       -- the exact call spd_download_file makes -- so a proxy configured
;       the usual SPEDAS way needs no extra setup here:
;         setenv, 'http_proxy=http://user:pass@proxy.example.org:3128'
;
;KEYWORDS:
;  verbose: dprint verbosity passthrough
;
;OUTPUT:
;  Structure with proxy_hostname, proxy_port, proxy_username and
;  proxy_password tags, or !null when no proxy is configured. Passing an
;  undefined/!null value through _extra is a no-op in IDL, so callers can
;  forward the result unconditionally.
;
;NOTES:
;  spd_get_proxy leaves its argument undefined when http_proxy is unset or
;  unparseable, which is what makes the !null return work.
;-
function thm_asi_proxy, verbose = verbose

  compile_opt idl2

  ; 1. explicit idl-aurorax variables override the general http_proxy
  hostname = getenv('AURORAX_PROXY_HOSTNAME')
  port = getenv('AURORAX_PROXY_PORT')
  if (hostname ne '' && port ne '') then begin
    dprint, dlevel = 4, verbose = verbose, 'thm_asi_proxy: using ' + $
      'AURORAX_PROXY_* proxy ' + hostname + ':' + port
    return, {proxy_hostname: hostname, $
      proxy_port: port, $
      proxy_username: getenv('AURORAX_PROXY_USERNAME'), $
      proxy_password: getenv('AURORAX_PROXY_PASSWORD')}
  endif

  ; 2. standard SPEDAS http_proxy, parsed exactly as spd_download_file does
  props = !null
  spd_get_proxy, props
  if ~is_struct(props) then return, !null

  dprint, dlevel = 4, verbose = verbose, 'thm_asi_proxy: using ' + $
    'http_proxy proxy ' + props.proxy_hostname + ':' + strtrim(props.proxy_port, 2)

  return, props
end
