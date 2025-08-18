;+
; NAME:
; SYNTAX:
; PURPOSE:
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY:
; VERSION:
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2024-12-13 09:03:48 -0800 (Fri, 13 Dec 2024) $
;   $LastChangedRevision: 32990 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/asi_mosaic/thm_map_add.pro $
;-

;---------------------------------------------------------------------------------
;(c) Eric Donovan and Brian Jackel - 2007
;thm_map_add
;this is to be called after thm_map_set (or your own map_set) and a polyfill that oplotted the mosaic
;the general idea is to overplot some useful contextual information on top of mosaics
;this can and should be called multiple times to accomplish what is desired
;this is called with keywords only and each keyword has a default
;please contact Eric Donovan if this program crashes for any reason
;this program is not meant to be comprehensive - it just does some things that can quickly
;help assess a situation given some ASI data and some ground mag data
;--------------------------------------------------------------------------------------
;keyword list of default defaults ----
   ;invariant_color       default is 0
   ;invariant_thick       default is 1
   ;invariant_lats        default is none plotted
   ;invariant_lons        default is none plotted
   ;invariant_linestyle   default is 0
   ;geographic_lats       default is none plotted
   ;geographic_lons       default is none plotted
   ;geographic_color      default is none plotted
   ;geographic_thick      default is 1
   ;geographic_linestyle  default is 1
   ;asi_fovs              default is none plotted
   ;asi_fov_color         default is 0
   ;asi_fov_thick         default is 1
   ;asi_fov_elevation     default is 10 corresponding to 160 field of view (ie cropping at 10 degrees above horizon)
   ;asi_emission_height   default is 110 km
   ;tgb_sites             defaukt is none plotted
   ;tgb_site_color        default is 0 (color of symbol)
   ;tgb_site_sym_size     default is 1
   ;tgb_site_name         default is site name not output to figure
   ;tgb_site_abbrev       default is site abbreviation not outputted to figure

;--------------------------------------------------------------------------------------

;EXAMPLE VALID CALLS
;note this is just for quick reference
;also see "thm_map_examples.pro" which accompanies this package

;invariants (note restrictions on invariant lats at 5 degree intervals
;invariants calculated using Rob Barnes' PACE 2000 IDL code
;in future we should include Rob's code in the THEMIS distribution
;thm_map_add,invariant_lats=[65,70]
;thm_map_add,invariant_lats=[70]
;thm_map_add,invariant_lats=[50,60,85]    ;has contours ONLY for 50 through 85 degrees north in 5 degree steps
                                             ;takes ONLY arrays of invariant latitude values
;thm_map_add,invariant_lats=[65,70],/invariant_lons
                                             ;invariant longitudes at one hour MLT spacing starting from Churchill meridian
                                             ;only has an effect if invariant_lats is set and n_elements(invariant_lons)>1
;thm_map_add,invariant_lats=[65,70],/invariant_lons,invariant_color=250,invariant_thick=10


;geographic contours  (East longitude)
;thm_map_add,geographic_lats=50+6*indgen(5),geographic_lons=235+indgen(4)*20,geographic_linestyle=2,geographic_thick=3
;thm_map_add,geographic_lats=50+6*indgen(5)
;thm_map_add,geographic_lons=245+indgen(20)*2

;--------------------------------------------------------------------------------------

;overplotting ASI fields of view
;thm_map_set & thm_map_add,asi_fovs=1
;thm_map_set & thm_map_add,asi_fovs=['atha']  & thm_map_add,asi_fovs=['pina'] & thm_map_add,asi_fovs=['kapu']
;thm_map_set & thm_map_add,asi_fovs=[1,4,6,9,12],asi_fov_thick=2,asi_fov_color=150
;thm_map_set & thm_map_add,asi_fovs=['inuv','rank','snkq','gbay'],asi_fov_thick=2,asi_fov_color=150
;thm_map_set & thm_map_add,asi_fovs=['gill'],asi_emission_height=110 & thm_map_add,asi_fovs=['gill'],asi_emission_height=230
;to find out what the site numbers, names, and abbreviations are run the following....
;   start by.... restore,'thm_map_add.sav' & w=where(gb_sites.themis_asi eq 1)
;   then run ... for i=0,n_elements(w)-1 do print,string(w(i),format='(i3.2)')+'  '+gb_sites(w(i)).name+' ('+gb_sites(w(i)).abbreviation+')'

;--------------------------------------------------------------------------------------

;overplotting some site info
;try the following in order
;   thm_map_set,xsize=600,ysize=600 & thm_map_add,invariant_lats=50+indgen(6)*5 &restore,'thm_map_add.sav'
;   w=where(gb_sites.themis_fluxgate eq 1) & thm_map_add,tgb_sites=w,tgb_site_color=0,tgb_site_sym_size=2
;   w=where(gb_sites.themis_epo_fluxgate eq 1 and gb_sites.themis_asi eq 0)
;   thm_map_add,tgb_sites=w,tgb_site_color=30,tgb_site_sym_size=2
;   w=where(gb_sites.gima_fluxgate eq 1) & thm_map_add,tgb_sites=w,tgb_site_color=100,tgb_site_sym_size=2
;   w=where(gb_sites.augo_fluxgate eq 1) & thm_map_add,tgb_sites=w,tgb_site_color=150,tgb_site_sym_size=2
;   w=where(gb_sites.carisma_fluxgate eq 1) & thm_map_add,tgb_sites=w,tgb_site_color=250,tgb_site_sym_size=2
;   w=where(gb_sites.nrcan_fluxgate eq 1) & thm_map_add,tgb_sites=w,tgb_site_color=250,tgb_site_sym_size=3
;                                           thm_map_add,tgb_sites=w,tgb_site_color=0,tgb_site_sym_size=1
;what has this done? THis shows all the fluxgates that feed into THEMIS. UCLA fluxgates at themis GBO sites are shown in black,
;EPO mags not at GBO sites are in purple, GIMA mags in blue, Athabasca University mag in green, CARISMA in red, and CANMOS
;(or NRCan) mags in red with a black center.

;--------------------------------------------------------------------------------------

;future frills
;better continent outlines
;better lakes etc
;overplot terminator
;include Barnes AACGM 2000 idl code (MUST talk to Rob Barnes)
;link to data base of sites and instrument types
;overplot labels (best done by user now)
;other?
;--------------------------------------------------------------------------------------

pro thm_map_add,      invariant_color                   =invariant_color              ,$
                      invariant_thick                   =invariant_thick              ,$
                      invariant_lats                    =invariant_lats               ,$
                      invariant_lons                    =invariant_lons               ,$
                      invariant_linestyle               =invariant_linestyle          ,$
                      geographic_lats                   =geographic_lats              ,$
                      geographic_lons                   =geographic_lons              ,$
                      geographic_color                  =geographic_color             ,$
                      geographic_thick                  =geographic_thick             ,$
                      geographic_linestyle              =geographic_linestyle         ,$
                      asi_fovs                          =asi_fovs                     ,$
                      asi_fov_color                     =asi_fov_color                ,$
                      asi_fov_thick                     =asi_fov_thick                ,$
                      asi_fov_elevation                 =asi_fov_elevation            ,$
                      asi_emission_height               =asi_emission_height          ,$
                      tgb_sites                         =tgb_sites                    ,$
                      tgb_site_color                    =tgb_site_color               ,$
                      tgb_site_sym_size                 =tgb_site_sym_size            ,$
                      tgb_site_name                     =tgb_site_name                ,$
                      tgb_site_abbrev                   =tgb_site_abbrev              ,$
                      return_lons                       =return_lons                  ,$
                      return_lats                       =return_lats                  ,$
                      no_grid                           =no_grid

  ; hfrey
   rt_info = routine_info('thm_map_add',/source)
   path = file_dirname(rt_info.path) 
   restore,filename=path+path_sep()+'thm_map_add.sav' ;restores a saved ascii_template variable named "templ"
;   restore,file='!themis.local_data_dir+'thg/l2/asi/cal/thm_map_add.sav'
;   restore,'thm_map_add.sav'  ;does this EVERY call - inefficient and I will rewrite later to make a structure to pass
   aacgm_lon_contour=thg_map_aacgm_lon_contour
   aacgm_lat_contour=thg_map_aacgm_lat_contour
   gb_sites=thg_map_gb_sites
   if keyword_set(return_lons) then return_lons=thg_map_aacgm_lon_contour
   if keyword_set(return_lats) then return_lats=thg_map_aacgm_lat_contour

   if keyword_set(asi_fovs) then thm_map_add_asi_fovs,gb_sites,asi_fovs=asi_fovs,$
                                                                  asi_fov_color=asi_fov_color,$
                                                                  asi_fov_thick=asi_fov_thick,$
                                                                  asi_fov_elevation=asi_fov_elevation,$
                                                                  asi_emission_height=asi_emission_height

   if keyword_set(tgb_sites) then thm_map_add_gb_sites,gb_sites,tgb_sites=tgb_sites,$
                                                                   tgb_site_color=tgb_site_color,$
                                                                   tgb_site_sym_size=tgb_site_sym_size,$
                                                                   tgb_site_name=tgb_site_name,$
                                                                   tgb_site_abbrev=tgb_site_abbrev

   if keyword_set(no_grid) then return

   if keyword_set(invariant_lats) or keyword_set(invariant_lons) then $
     thm_map_oplot_aacgm_2000_invariants,aacgm_lon_contour,aacgm_lat_contour,$
                                        invariant_lats=invariant_lats,$
                                        invariant_lons=invariant_lons,$
                                        invariant_color=invariant_color,$
                                        invariant_thick=invariant_thick,$
                                        invariant_linestyle=invariant_linestyle

   if keyword_set(geographic_lats) or keyword_set(geographic_lons) then $
     thm_map_oplot_geographic_grid,geographic_lons=geographic_lons,$
                                  geographic_lats=geographic_lats,$
                                  geographic_color=geographic_color,$
                                  geographic_thick=geographic_thick,$
                                  geographic_linestyle=geographic_linestyle

return
end
;------------------------------------------------------------------------------