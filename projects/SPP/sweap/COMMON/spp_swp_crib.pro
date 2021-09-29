; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-04-02 12:45:19 -0700 (Fri, 02 Apr 2021) $
; $LastChangedRevision: 29850 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_crib.pro $
;spp_swp_crib
;

; change the default root data directory. This will affect all SPEDAS load files. I don't recomment changing from the default
;setenv,'ROOT_DATA_DIR=/cache/'       ; Can be put in personal startup file.  If you've been using SPEDAS you won't need this and I don't recomment changing it.

; define the FIELDS username:password combination
;setenv,'FIELDS_USER_PASS=username:password'    ; A line like this can be put in each user's personal startup file.  I recommend: "idl_startup_$user$"  Where $user$ is your username.


; Define a time range
timespan,'2018-11-3',5   ; 5 days starting on venus encounter
timespan,'2019-3-20',26   ; 5 days starting on venus encounter
timespan, '2018 11 1', 14   ; encounter 1
timespan, '2019 3 29', 14   ; encounter 2
timespan, '2019 8 30',14   ; encounter 3
timespan ,'2020 1 18',22   ; encounter 4
timespan ,'2020 5 25',25   ; encounter 5
timespan ,'2020 9 13',33   ; encounter 6
timespan,['2021-01-09/00:00:00', '2021-01-29/00:00:00'] ; encounter 7

stop


spp_fld_load  ;   type =mag_SC_4_Sa_per_Cyc'  ;   default is spacecraft frame 4 NYHz

spp_fld_load, type = 'mag_RTN_4_Sa_per_Cyc'  ;   Get RTN frame mag data at 4 NYHz


; Subsequent load routines will use this timespan for the default time range

; Load some L2 highest resolution mag data:
centertime = average( timerange() )
spp_fld_load,type='mag_RTN',trange=centertime   ; Get a single day of high res mag data

; plot it:
tplot,'psp_fld_l2_mag_RTN'


spp_swp_spice,/quaternion,/position

spp_swp_spe_load

spp_swp_spi_load,/rtn_frame


; Load L3 SPC data
spp_swp_spc_load ,type='l3i'


; See what has been loaded:
tplot_names


;  See only the SPC variables:
tplot_names,'*_spc_*


; Get extensize information about a tplot variable:
tplot_names,'psp_swp_spc_l3i_vp_moment_SC',/verbose


;  Plot some selected things:
tplot,'*vp_moment_SC *np_moment'   ; plot all "matching" quantities

; Change limits
ylim,'*np_moment',10,1000,1     ; change range

; replot
tplot


; Load SPAN-Ion data
spp_swp_spi_load, type = 'sf00'

tplot_names,'*spi_*

tplot,/add,'*spi_sf00*'


spp_swp_spe_load



; Load L3 SPC data
spp_swp_spc_load ,type='l2i'

spp_swp_spice

; Extracting data






end


