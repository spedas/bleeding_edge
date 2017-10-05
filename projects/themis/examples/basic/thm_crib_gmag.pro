;+
;Procedure:
;  thm_crib_gmag
;
;Purpose:
;  Demonstrate basic examples of loading ground magnetometer data.
;
;Acknowledgements:
;  MACCS:
;    If these data are used in a publication, you must acknowledge the source:
;    "Acknowledgement: MACCS magnetometer data were provided by Mark Engebretson,
;    Augsburg College"
;
;See also:
;  thm_crib_greenland_gmag
;  thm_crib_maccs_gmag
;  thm_crib_gmag_wavelet
;  thm_crib_gmag_locations
;
;More info:
;  http://themis.ssl.berkeley.edu/instrument_gmags.shtml
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/basic/thm_crib_gmag.pro $
;-


;------------------------------------------------------------------------------
; Load ground mag data
;------------------------------------------------------------------------------

;set time range
trange = ['2006-10-02', '2006-10-04' ]

;load data from multiple sites
;  -use "site" keyword to load data from specfic site
;  -if no sites are specified all sites will be loaded (this might take a while)
thm_load_gmag, site='bmls ccnv fykn', trange=trange

;plot
tplot, 'thg_mag_'+['bmls','ccnv','fykn']

stop


;------------------------------------------------------------------------------
; Loading entire networks
;------------------------------------------------------------------------------

;  To include all sites from a specific network use the following keywords.
;  Manually specified sites from other networks will also be loaded.
;  Consult network websites for terms of use.
;       /thm_sites      (THEMIS GBO network)
;       /epo_sites      (THEMIS EPO network)
;       /tgo_sites      (TGO network)
;       /dtu_sites      (DTU network)
;       /maccs_sites    (MACCS network)
;       /usgs_sites     (USGS network)
;       /ua_sites       (University of Alaska sites)
;       /atha_sites     (University of Athabasca/AUTUMN network)
;       /carisma_sites  (CARISMA network)
;       /mcmac_sites    (MCMAC network)
;       /nrcan_sites    (NRCAN network)

;set time range
trange = ['2006-10-02', '2006-10-04' ]

;load all THEMIS GBO sites
thm_load_gmag, /thm_sites, /subtract_average, trange=trange

;plot all variables
tplot, 'thg_mag_????'

stop


;------------------------------------------------------------------------------
; Subract average/median when loading data
;------------------------------------------------------------------------------

;set time range
trange = ['2006-10-02', '2006-10-04' ]

;load data
thm_load_gmag, site='bmls', trange=trange, /subtract_average, suffix='_ave'
thm_load_gmag, site='bmls', trange=trange, /subtract_median, suffix='_med'
thm_load_gmag, site='bmls', trange=trange

;plot all three versions
tplot, 'thg_mag_bmls*'

stop


;------------------------------------------------------------------------------
; Splitting data components
;------------------------------------------------------------------------------

;set time range
trange = ['2006-10-02', '2006-10-04' ]

;load data
thm_load_gmag, site='ccnv', trange=trange, /subtract_average

;split into separate tplot variables for each trace
split_vec, 'thg_mag_ccnv'

;plot
tplot, 'thg_mag_ccnv_?'

stop




end

