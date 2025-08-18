;+
; PROCEDURE: IUG_CRIB_MDDB
;    A sample crib sheet that explains how to search data from IUGONET 
;    metadata database (MDDB). You can run this crib sheet by copying 
;    & pasting each command below (except for stop and end) into the 
;    IDL command line. Or alternatively compile and run using the command:
;        .run iug_crib_mddb
;
; NOTE: For more information of the IUGONET project, see:
;       http://www.iugonet.org/en
;    &  http://search.iugonet.org/iugonet/.
; Written by: Y.-M. Tanaka, May 2, 2011
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Make query
mddb_url = 'http://search.iugonet.org/iugonet/open-search/'
query_part = 'request?query=nipr+AND+fluxgate+AND+syo&ts=2010-1-1&te=2010-1-1&Granule=granule&'
query = mddb_url+query_part

; Get URL for data file
url=get_source_url_list(query)
print, 'url = ', url

; Download data file
file_http_copy, url

; Stop
print,'Enter ".c" to continue.'
stop

; Search observatories located in glat=[30, 45] and glon=[120, 145]
iug_get_obsinfo, nlat=45, slat=30, elon=145, wlon=120, query='kyoto', $
                     obs=obs

; Stop
print,'Enter ".c" to continue.'
stop

; Search WDC observatories in glat=[55, 75] and glon=[0, 40] and 
;   Plot them on the world map.
iug_plotmap_obs, glatlim=[55, 75], glonlim=[0, 40], $
    query='wdc', charsize=1.2, psym=6, symsize=1.3, $
    symcolor=254

end
