;+
; Name:
;   iug_makequery_mddb
;
; PURPOSE:
;   Make a query for IUGONET metadata databese.
;
; Written by Y.-M. Tanaka, Feb. 13, 2010 (ytanaka at nipr.ac.jp)
;-

function iug_makequery_mddb, mddb_base_url=mddb_base_url, query=query, $
  granule=granule, numericaldata=numericaldata, $
  displaydata=displaydata, instrument=instrument, observatory=observatory, $
  catalog=catalog, ts=ts, te=te, nlat=nlat, slat=slat, elon=elon, wlon=wlon, $
  search_obj=search_obj, region=region, rpp=rpp, sort_by=sort_by, $
  order=order


out_query=''

if(~keyword_set(mddb_base_url)) then begin
    mddb_base_url = 'http://search.iugonet.org/iugonet/open-search/'
endif

out_query=mddb_base_url+'request?'

if(keyword_set(query)) then begin
    if size(query,/type) ne 7 then begin
        message,'query must be of string type.',/info
        return, out_query
    endif
    out_query=out_query+'query='+query+'&'
endif

if(keyword_set(granule)) then out_query=out_query+'Granule=granule&'
if(keyword_set(numericaldata)) then out_query=out_query+'NumericalData=numericaldata&'
if(keyword_set(displaydata)) then out_query=out_query+'DisplayData=displaydata&'
if(keyword_set(instrument)) then out_query=out_query+'Instrument=instrument&'
if(keyword_set(observatory)) then out_query=out_query+'Observatory=observatory&'
if(keyword_set(catalog)) then out_query=out_query+'Catalog=catalog&'
if(keyword_set(ts)) then begin
    if size(ts,/type) ne 7 then begin
        message,'ts must be of string type.',/info
        return, out_query
    endif
    out_query=out_query+'ts='+ts+'&'
endif
if(keyword_set(te)) then begin
    if size(te,/type) ne 7 then begin
        message,'te must be of string type.',/info
        return, out_query
    endif
    out_query=out_query+'te='+te+'&'
endif
if(size(nlat,/type) ne 0) then out_query=out_query+'nlat='+strcompress(string(nlat),/remove_all)+'&'
if(size(slat,/type) ne 0) then out_query=out_query+'slat='+strcompress(string(slat),/remove_all)+'&'
if(size(elon,/type) ne 0) then out_query=out_query+'elon='+strcompress(string(elon),/remove_all)+'&'
if(size(wlon,/type) ne 0) then out_query=out_query+'wlon='+strcompress(string(wlon),/remove_all)+'&'
if(keyword_set(search_obj)) then begin
    if size(search_obj,/type) ne 7 then begin
        message,'search_obj must be of string type.',/info
        return, out_query
    endif
    out_query=out_query+'search_obj='+search_obj+'&'
endif
if(keyword_set(region)) then begin
    if size(region,/type) ne 7 then begin
        message,'region must be of string type.',/info
        return, out_query
    endif
    out_query=out_query+'region='+region+'&'
endif
if(size(rpp,/type) ne 0) then out_query=out_query+'rpp='+strcompress(string(rpp),/remove_all)+'&'
if(size(sort_by,/type) ne 0) then out_query=out_query+'sort_by='+strcompress(string(sort_by),/remove_all)+'&'
if(keyword_set(order)) then begin
    if size(order,/type) ne 7 then begin
        message,'order must be of string type.',/info
        return, out_query
    endif
    out_query=out_query+'order='+order+'&'
endif

; print, 'out_query = ', out_query

return, out_query

end
