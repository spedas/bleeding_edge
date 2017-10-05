;+
;Procedure:
;  thm_crib_maccs_gmag
;
;Purpose:
;  This crib sheet gives examples of how to plot magnetometer data from
;  the Magnetometer Array for Cusp and Cleft Studies (MACCS), an array of
;  magnetometers in Arctic Canada run by Augsburg College and Boston
;  University. Further details of the MACCS array can be found in:
;  "W. J. Hughes and M. J. Engebretson, MACCS: Magnetometer Array for Cusp
;  and Cleft Studies, in Satellite-Ground Based Coordination Sourcebook,
;  (eds. M. Lockwood, M.N. Wild H. J. Opgenoorth), ESA-SP-1198, pp. 119-130, 1997."
;
;Notes:
;  If these data are used in a publication, you must acknowledge the source:
;  "Acknowledgement: MACCS magnetometer data were provided by Mark Engebretson,
;  Augsburg College"
;
;See also:
;  thm_crib_gmag
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
;$LastChangedRevision: 17598 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_maccs_gmag.pro $
;-


; To load only MACCS stations with thm_load_gmag, use the keyword /maccs_sites
;--------------------------------------------------------------------

;This will load all the MACCS stations that have data available on 1-dec-2010
thm_load_gmag, trange = ['2010-12-01', '2010-12-02'], /maccs_sites

tplot, 'thg_mag_*'

stop

; To get data for individual sites, use the site keyword.
; The MACCS sites are handled in the same way as the other GMAG sites.
; The valid site names for the MACCS data are:
;
;        ['cdrt','crvr','gjoa','rbay','pang','nain','iglo']
;
; corresponding to:
;
;        ['Cape Dorset', 'Clyde River', 'Gjoa Haven', 'Repulse Bay',$
;         'Pangnirtung', 'Nain', 'Igloolik']
;--------------------------------------------------------------------

;load specified sites for 2009-1-1
thm_load_gmag, trange = ['2009-01-01', '2009-01-02'], site = ['cdrt','gjoa']

;split components into speparate tplot variables
split_vec, 'thg_mag_cdrt'
split_vec, 'thg_mag_gjoa'

tplot,'thg_mag_cdrt* thg_mag_gjoa*'



End


