;+
; Name:
;   iug_get_datainfo
;
; PURPOSE:
;   Search granule at the IUGONET metadata database.
;
; Example:
;   iug_get_datainfo, nlat=60, slat=40, elon=15, wlon=0, $
;            ts='2005-1-1', te='2005-1-2', query='Kyoto', data=data 
;
; KEYWORDS:
;   nlat: the northernmost latitude (degree)
;   slat: the southernmost latitude (degree)
;   elon: the easternmost longitude (degree)
;   wlon: the westernmost longitude (degree)
;   ts: start time of observation
;   te: end time of observation
;   rpp: number of records per a query
;   query: free word to search
;   data: information of obtained data files (structure)
;
; Written by Y.-M. Tanaka, Feb. 13, 2010 (ytanaka at nipr.ac.jp)
;-

pro iug_get_datainfo, nlat=nlat, slat=slat, elon=elon, wlon=wlon, $
                    ts=ts, te=te, rpp=rpp, query=query, $
                    xmldir=xmldir, xmlfile=xmlfile, $
                    data=data

data=''

;----- keyword check -----;
if ~keyword_set(rpp) then rpp=300
if ~keyword_set(xmldir) then xmldir=root_data_dir()
if ~keyword_set(xmlfile) then xmlfile='tmp.xml'

;----- Make query -----;
in_query=iug_makequery_mddb(/granule, query=query, nlat=nlat, slat=slat, $
                            elon=elon, wlon=wlon, ts=ts, te=te, rpp=rpp)

;----- download xmlfile -----; 
file_http_copy, xmlfile, serverdir=in_query, localdir=xmldir

;----- Parse XML file -----;
;----- Station name -----;
ResID=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='ResourceID')
if size(ResID, /dimensions) ne 0 then begin
    nstn=n_elements(ResID)
    stname=strarr(nstn)
    for istn=0, nstn-1 do begin
        rem_ResID=ResID[istn]
        for irep=0, 5 do begin
            pos=strpos(rem_ResID, '/')
            rem_ResID=strmid(rem_ResID, pos+1, strlen(rem_ResID)-pos-1)
        endfor
        pos_end=strpos(rem_ResID, '/')
        stname[istn]=strmid(rem_ResID, 0, pos_end)
    endfor

    ;----- Latitude -----;
    sc_nlat=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='NorthernmostLatitude')
    sc_slat=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='SouthernmostLatitude')
    lat=string((float(sc_nlat)+float(sc_slat))*0.5, format='(f6.2)')

    ;----- Longitude -----;
    sc_elon=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='EasternmostLongitude')
    sc_wlon=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='WesternmostLongitude')
    lon=string((float(sc_elon)+float(sc_wlon))*0.5, format='(f7.2)')

    ;----- URL -----;
    url=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='URL')

    data = {name:stname, glat:lat, glon:lon, url:url}

    iug_show_obsinfo, obs=data
endif


end
