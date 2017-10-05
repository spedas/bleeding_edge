;+
;Procedure:
;  thm_crib_greenland_gmag
;
;Purpose:
;  Crib sheet demonstrating loading GMAG data from Greenland stations
;
;Notes:
;  In addition to the NRSQ site included in the standard THEMIS GMAG
;  data distribution, Jurgen Matzka(jrgm@space.dtu.dk) from the Technical
;  University of Denmark has made data gmag data available from the DTU(previously DMI) and
;  the TGO gmag networks.  Availability is 2007 through to the present.
;  Although not all gmags are available at all times.
;  To access these data, simply use the program thm_load_gmag
;  More DMI data can be added upon request.  Otherwise, THEMIS archives will be updated 
;  approximately every 3 months. 
; 
;  WARNING:  As with all GMAG data, users should be careful to verify data units
;            and coordinate systems, as calibrations can drift from true values 
;            over time.  Users should be particularly careful with the older data
;            from the DMI/DTU network. In particular, DMI/DTU data from the first 
;            part of 2009 and earlier is uncalibrated.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_greenland_gmag.pro $
;-


print, "--- Start of crib sheet ---"


;To get data for individual sites, use the site keyword with one of the following values:
;
;  amk and atu bfe bjn dmh dnb dob don fhb gdh ghb hop jck kar kuv lyr
;  nal naq nor nrd roe rvk sco skt sol sor stf svs tdc thl tro umq upn
;
;  These names correspond to gmags at these locations:
;    Ammassalik(Tasiilaq) Andenes Attu Brorfelde Bjornoya Danmarkshavn Dombas Donna Paamiut(Frederickshap) Qeqertarsuaq(Godhavn) Nuuk(Godthap) Hopen Jackvik Karmoy
;    Kullorsuaq Longyearbyen NyAlesund Naqsarsuaq Nordkapp Nord Roemoe Rorvik Ittoqqortoormiit Maniitsoq(SukkerToppen) Solund Soroya
;    Kangerlussuaq(SondreStromFjord)Savissivik TristanDaCunha Qaanaaq(Thule) Tromso Umanaq Upernavik

; Detailed info on DTU/TGO sites is here:
; http://flux.phys.uit.no/geomag.html 
;  

thm_load_gmag, trange = ['2009-01-01', '2009-01-02'], site = ['amk', 'gdh']

;or

thm_load_gmag, trange = ['2009-01-01', '2009-01-02'],  site = ['amk gdh']

;etc... 
; To load all sites from the TGO network use the keyword /tgo_sites
; The sites in the tgo network are: 
;  and bjn dob don hop jck kar lyr nal nor rvk sol sor tro

thm_load_gmag, trange = ['2009-01-01','2009-01-02'], /tgo_sites

; To load all sites from the DTU network use the keyword /dtu_sites
; The sites in the dtu network are:
;  amk atu bfe dmh fhb gdh ghb kuv naq nrd roe sco skt stf svs tdc thl umq upn 
; The sites atu, dmh, dnb (not operational), nrd, svs are not currently loaded with the /dtu_sites keyword
; because only uncalibrated data exists, thus the command below will load 
; amk, bfe, fhb, gdh, ghb, kuv, naq, roe, sco, skt, stf, tdc, thl, umq, upn if available for the chosen date range.
; Warning: Data from 2009 or earlier from these sites may also be uncalibrated.

thm_load_gmag, trange = ['2009-12-01', '2009-12-02'], /dtu_sites

; The keywords /tgo_sites, /dtu_sites can be used together to load both TGO and DTU network sites.
;The other keyword inputs for thm_load_gmag,
;(/subtract_average, /subtract_median, /valid_names, etc...) still
;work. See THM_CRIB_GMAG in this directory for examples.

;If this data is used in a publication, please acknowledge the source: 
;"Tromsø Geophysical Observatory, University of Tromsø, Norway for use of the Greenland & Norway magnetometer data"
;
;
print, "--- End of crib sheet ---"

End


