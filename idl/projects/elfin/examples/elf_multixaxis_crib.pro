;
; Shows how to create multiple x-axes to add to UT: MLT, Lsheel, MLat, MLon etc
; Procedure reads STATE data, computes other axes data, reads EPDE data and plots
; Use the crib to learn how to do this, cut-and-paste relevant pieces.
; This it is not intended to be a subroutine but a crib-sheet
;
; First release: 2020/11/10, Vassilis
;
pro elf_multixaxis_crib
;
  elf_init
  tplot_options, 'xmargin', [20,9]
  cwdirname=!elf.local_data_dir ; your directory here, if other than default IDL dir
  cwd,cwdirname
  pival=!dpi
  Re=6378.1 ; Earth equatorial radius in km
  Rem=6371.0 ; Earth mean radius in km
;
; pick an event; here from 2019-09-27 storm on EL-A
; 
 tstart='2019-09-28/16:19:00' ; <- this is the ELFIN mission paper event, Fig. 21
 tend='2019-09-28/16:22:00'   ; <- this is the ELFIN mission paper event, Fig. 21
 ; tstart='2020-04-22/05:43:50' ; <--- uncommend this to plot a different event
 ; tend='2020-04-22/05:48:30'   ; <--- uncommend this to plot a different event
 time2plot=[tstart,tend]
 timeduration=time_double(tend)-time_double(tstart)
 timespan,tstart,timeduration,/seconds ; set the analysis time interval
;
 sclet='a'
;
; first you need to load the state data (position and attitude)\
;
; This shows the simplest form of the call sequence which takes advantage of default settings
;
elf_load_state,probe=sclet ; load ELFIN's position and attitude data (probe='a' which is also the default)
;
cotrans,'el'+sclet+'_pos_gei','el'+sclet+'_pos_gse',/GEI2GSE
cotrans,'el'+sclet+'_pos_gse','el'+sclet+'_pos_gsm',/GSE2GSM
cotrans,'el'+sclet+'_pos_gsm','el'+sclet+'_pos_sm',/GSM2SM ; now in SM
split_vec,'el'+sclet+'_pos_sm'
copy_data,'el'+sclet+'_pos_sm_x','SMX'
copy_data,'el'+sclet+'_pos_sm_y','SMY'
copy_data,'el'+sclet+'_pos_sm_z','SMZ'
;
tplot,'el'+sclet+'_'+['pos_gei','att_gei','spin_orbnorm_angle','spin_sun_angle'], $
  title='el'+sclet,var_label='SM'+['X','Y','Z']
;
print,'*****************************************************************************'
print,'This shows how to plot XYZ position in SM coordinates, in a standard fashion '
print,'*****************************************************************************'
stop
;
;
tplot_options, version=6
;
tplot
;
print,'*****************************************************************************'
print,'This replots XYZ pos in SM, but now has time on top (tplot_options, version=6)'
print,'*****************************************************************************'
stop
;
tt89,'el'+sclet+'_pos_gsm',/igrf_only,newname='elx_bt89_gsm',period=1. ; gets IGRF field at ELF location
cotrans,'elx_bt89_gsm','elx_bt89_sm',/GSM2SM ; cast Bfield into SM coords
copy_data,'el'+sclet+'_pos_sm','elx_pos_sm' ; avoid satellite name for simplicity, just use elx from now on for pos too!
xyz_to_polar,'elx_pos_sm',/co_latitude ; get position in rthphi (polar) coords
calc," 'elx_pos_sm_mlat' = 90.-'elx_pos_sm_th' "
calc," 'elx_pos_sm_mlt' = ('elx_pos_sm_phi' + 180. mod 360. ) / 15. "
;
calc," 'L'=('elx_pos_sm_mag'/Re)/(sin('elx_pos_sm_th'*pival/180.))^2 " ; this projects to ground (to 1Re NOT 1Re+100km!)
copy_data,'elx_pos_sm_mlat','MLA' ; magnetic latitude of satellite, same as that of ground track
copy_data,'elx_pos_sm_mlt','MLT' ; magnetic local time of satellite, same as that of ground track
;
tplot,'el'+sclet+'_'+['pos_gei','att_gei','spin_orbnorm_angle','spin_sun_angle'], $
  title='el'+sclet,var_label=['MLA','MLT','L']
;
print,'*****************************************************************************'
print,'This replots the same as before, but has MLAT, MLT, L as supplementary Xaxes
print,'*****************************************************************************'
stop
r_ift_dip = (1.+100./Rem) ;;100km altitude
;;trace to equator to get L, MLAT in IGRF, following Vassilis' algorithm on 08/22/2021
ttrace2equator,'el'+sclet+'_pos_gsm',external_model='none',internal_model='igrf',/km,in_coord='gsm',out_coord='gsm',rlim=100.*Rem
cotrans,'el'+sclet+'_pos_gsm_foot','elx_pos_sm_foot',/GSM2SM ; now in SM
get_data,'elx_pos_sm_foot',data=elx_pos_sm_foot
xyz_to_polar,'elx_pos_sm_foot',/co_latitude ; get position in rthphi (polar) coords
calc," 'Ligrf'=('elx_pos_sm_foot_mag'/Rem)/(sin('elx_pos_sm_foot_th'*pival/180.))^2 " ; uses 1Rem (mean E-radius, the units of L) NOT 1Rem+100km!
tdotp,'elx_bt89_gsm','el'+sclet+'_pos_gsm',newname='elx_br_tmp'
get_data,'elx_br_tmp',data=Br_tmp
hemisphere=sign(-Br_tmp.y)
calc," 'MLATigrf' = (180./pival)*arccos(sqrt(Rem*r_ift_dip/'elx_pos_sm_foot_mag')*sin('elx_pos_sm_foot_th'*pival/180.))*hemisphere " ; at footpoint
calc," 'MLTigrf' = ('elx_pos_sm_foot_phi' + 180. mod 360. ) / 15. " ; done with MLT
copy_data, 'MLTigrf','el'+sclet+'_MLT_igrf'
copy_data, 'MLATigrf','el'+sclet+'_MLAT_igrf'
copy_data, 'Ligrf','el'+sclet+'_L_igrf'
options,'el'+sclet+'_L_igrf',ytitle='L (IGRF)'
options,'el'+sclet+'_MLT_igrf',ytitle='MLT (IGRF)'
options,'el'+sclet+'_MLAT_igrf',ytitle='MLAT (IGRF)'
tplot,'el'+sclet+'_'+['pos_gei','att_gei','spin_orbnorm_angle','spin_sun_angle'], $
  title='el'+sclet,var_label=['MLA','MLT','L','el'+sclet+['_MLAT_igrf','_MLT_igrf','_L_igrf']]
;
print,'*****************************************************************************'
print,'This shows how to estimate MLAT, MLT, L in IGRF field, instead of a dipole
print,'*****************************************************************************'
stop
; find satellite's and its ionospheric projection's AACGM (Altitude Adjusted Corrected Geomagnetic) coordinates Laacgm, MLTaacgm, MLATaacgm
; Note that Laacgm is assumed here to be same as Ligrf, the true magnetic equatorial distance in Rem, not the dipole equator distance in Rem
; Note that AACGM defines mlt and mlat as the dipole coord's of the point where the upwards mapped field line meets the DIPOLE equator.
; AACGM coord's are not same as IGRF MLT and MLAT which take the true equator to determine mlt/mlat. Using AACGM-V2 here
; Note that AACGM_v2 here is done as the result of a GEO-CGM mapping using spherical harmonic expansion, but confirmed to be close by tracing
aacgmidl_v2 ; initializes AACGM routines
aacgm_v2 ; initializes aacgm v2 routines
cotrans,'el'+sclet+'_pos_gei','elx_pos_geo',/GEI2GEO
get_data,'elx_pos_geo',data=elx_pos_geo ; local
cart_to_sphere,elx_pos_geo.y[*,0],elx_pos_geo.y[*,1],elx_pos_geo.y[*,2],rgeo,theta_geo,phi_geo; by default phi is -180 to 180.; theta is -90 to 90.
height=rgeo-Rem ; geocentric but NEEDS TO BE CHANGED TO GEODETIC (OR KEYWORD? TO SWICH cnvcoord_v2 BEHAVIOR? to expect GEOCENTRIC NEEDS TO BE PROVIDED)
aacgm_year=long(time_string(elx_pos_geo.x[0],precision=-5))
aacgm_month=long(strmid(time_string(elx_pos_geo.x[0]),5,2))
aacgm_day=long(strmid(time_string(elx_pos_geo.x[0]),8,2))
ret = AACGM_v2_SetDateTime(aacgm_year,aacgm_month,aacgm_day)
aacgm_geo = transpose([[theta_geo],[phi_geo],[height]])
aacgm_fix = cnvcoord_v2(aacgm_geo) ; lat/lon/geocentric_radii (latter needs to be changed to geodetic, but for now close enough)
MLATaacgm = reform(aacgm_fix[0,*]) ; 1D array now
MLONaacgm = reform(aacgm_fix[1,*]) ; 1D array now, containing fixed Earth magnetic longitude of point
MLTaacgm = MLTConvertYrsec_v2(long(time_string(elx_pos_geo.x,precision=-5)), $ ; this is year
  elx_pos_geo.x-time_double(time_string(elx_pos_geo.x[0],precision=-5)), $ ; this is seconds of year
  MLONaacgm) ;
store_data,'el'+sclet+'_MLAT_aacgm',data={x:elx_pos_geo.x,y:MLATaacgm}
store_data,'el'+sclet+'_MLT_aacgm',data={x:elx_pos_geo.x,y:MLTaacgm}
copy_data, 'Ligrf','el'+sclet+'_L_aacgm'
options,'el'+sclet+'_MLAT_aacgm',ytitle='MLAT (aacgm)'
options,'el'+sclet+'_MLT_aacgm',ytitle='MLT (aacgm)'
tplot,'el'+sclet+'_'+['pos_gei','att_gei','spin_orbnorm_angle','spin_sun_angle'], $
  title='el'+sclet,var_label=['MLA','MLT','L','el'+sclet+['_MLAT_igrf','_MLT_igrf','_L_igrf'],'el'+sclet+['_MLAT_aacgm','_MLT_aacgm']]
print,'*****************************************************************************'
print,'This shows how to estimate MLAT, MLT, L in AACGM (Altitude Adjusted Corrected Geomagnetic) coordinates, instead of a dipole
print,'*****************************************************************************'
stop
;
; Now you can also plot the IGRF B-field data at the location of the satellite
;
get_data,'elx_pos_sm_th',data=elx_pos_sm_th,dlim=myposdlim,lim=myposlim ; get data to establish rotation matrix
get_data,'elx_pos_sm_phi',data=elx_pos_sm_phi
csth=cos(!PI*elx_pos_sm_th.y/180.)
csph=cos(!PI*elx_pos_sm_phi.y/180.)
snth=sin(!PI*elx_pos_sm_th.y/180.)
snph=sin(!PI*elx_pos_sm_phi.y/180.)
rot2rthph=[[[snth*csph],[csth*csph],[-snph]],[[snth*snph],[csth*snph],[csph]],[[csth],[-snth],[0.*csth]]]
store_data,'rot2rthph',data={x:elx_pos_sm_th.x,y:rot2rthph},dlim=myposdlim,lim=myposlim ; get rotmat in tplot variable form
tvector_rotate,'rot2rthph','elx_bt89_sm',newname='elx_bt89_sm_sph' ; rotate field using above rotmat
rotSMSPH2NED=[[[snth*0.],[snth*0.],[snth*0.-1.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.+1.],[snth*0.]]] ; rotmat to North, East, Down
store_data,'rotSMSPH2NED',data={x:elx_pos_sm_th.x,y:rotSMSPH2NED},dlim=myposdlim,lim=myposlim
tvector_rotate,'rotSMSPH2NED','elx_bt89_sm_sph',newname='elx_bt89_sm_NED' ; North (-Spherical_theta), East (Spherical_phi), Down (-Spherical_r)
tvectot,'elx_bt89_sm_NED',newname='elx_bt89_sm_NEDT' ; adds total field for plotting purposes
options,'elx_bt89_sm_N*','ysubtitle','nT'
options,'elx_bt89_sm_NEDT','labels',['N','E','D','T']
options,'elx_bt89_sm_N*','databar',0.
;
copy_data,'elx_bt89_sm_NEDT','el'+sclet+'_'+'bt89_sm_NEDT'
;
tplot,'el'+sclet+'_'+['pos_gei','att_gei','spin_orbnorm_angle','spin_sun_angle','bt89_sm_NEDT'], $
  title='el'+sclet,var_label=['MLA','MLT','L']
tplot_apply_databar ; shows the databar
;
print,'*********************************************************************************'
print,'Plots also the IGRF field at the satellite location, at the bottom panel
print,'*********************************************************************************'
;
stop
;
elf_load_epd,probe=sclet,datatype='pef' ; you must first load the EPD data, here, for further use (default is ELFIN-A 'a', 'e', and 'nflux'
elf_getspec,probe=sclet,datatype='pef' ; get some spectra (default is 'a',species='e' (or datatype='pef'),type='nflux'  <- note these MUST match the previous call
;
tplot,'el'+sclet+'_'+['pos_gei','att_gei','spin_orbnorm_angle','spin_sun_angle','pef_en_spec2plot_omni','pef_pa_spec2plot_ch0','bt89_sm_NEDT'], $
  title='el'+sclet,var_label=['MLA','MLT','L']
tplot_apply_databar ; shows the databar
;
print,'*********************************************************************************'
print,'Plots also some EPDE data, for reference, to ease combining this crib with others
print,'*********************************************************************************'
;
stop
;
end