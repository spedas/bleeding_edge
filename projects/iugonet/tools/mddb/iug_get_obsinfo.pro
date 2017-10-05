;+
; Name:
;   iug_get_obsinfo
;
; PURPOSE:
;   Search observatories at the IUGONET metadata database.
;
; Example:
;   iug_get_obsinfo, nlat=40, slat=35, elon=140, wlon=130, $
;                    query='Kyoto', obs=obs
;
; KEYWORDS:
;   nlat: the northernmost latitude (degree)
;   slat: the southernmost latitude (degree)
;   elon: the easternmost longitude (degree)
;   wlon: the westernmost longitude (degree)
;   rpp: number of records per a query
;   query: free word to search
;   obs: information of obtained observatories (structure)
;
; Written by Y.-M. Tanaka, Feb. 13, 2010 (ytanaka at nipr.ac.jp)
;-

pro iug_get_obsinfo, nlat=nlat, slat=slat, elon=elon, wlon=wlon, $
                     rpp=rpp, query=query, xmldir=xmldir, xmlfile=xmlfile, $
                     obs=obs 

obs=''

;----- keyword check -----;
if ~keyword_set(rpp) then rpp=300
if ~keyword_set(xmldir) then xmldir=root_data_dir()
if ~keyword_set(xmlfile) then xmlfile='tmp.xml'

;----- Make query -----;
in_query=iug_makequery_mddb(/observatory, query=query, nlat=nlat, slat=slat, $
                            elon=elon, wlon=wlon, rpp=rpp)

;----- download xmlfile -----; 
file_http_copy, xmlfile, serverdir=in_query, localdir=xmldir

;----- Parse XML file -----;
;----- Station name -----;
ResID=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='ResourceID')
if size(ResID, /dimensions) ne 0 then begin
    nstn=n_elements(ResID)
    stname=strarr(nstn)
    for istn=0, nstn-1 do begin
        pos=strpos(ResID[istn], '/', /reverse_search)
        stname[istn]=strmid(ResID[istn], pos+1, strlen(ResID[istn])-pos-1)
    endfor

    ;----- Latitude -----;
    lat=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='Latitude')
    lat=string(float(lat), format='(f6.2)')

    ;----- Longitude -----;
    lon=iug_parsexml_mddb(filename=xmldir+xmlfile, tag='Longitude')
    lon=string(float(lon), format='(f7.2)')

    obs = {name:stname, glat:lat, glon:lon}

    iug_show_obsinfo, obs=obs
endif


end
