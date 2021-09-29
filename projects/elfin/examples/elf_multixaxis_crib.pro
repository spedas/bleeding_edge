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
  aacgmidl
  elf_init
  tplot_options, 'xmargin', [20,9]
  cwdirname=!elf.local_data_dir ; your directory here, if other than default IDL dir
  cwd,cwdirname
  pival=!PI
  Re=6378.1 ; Earth equatorial radius in km
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
;;trace to equator to get L, MLAT in IGRF
ttrace2equator,'el'+sclet+'_pos_gsm',external_model='none',internal_model='igrf',/km,in_coord='gsm',out_coord='gsm',rlim=100.*Re
get_data,'el'+sclet+'_pos_gsm_foot',data=elx_pos_eq
L1=sqrt(total(elx_pos_eq.y^2.0,2,/nan))/Re
store_data,'el'+sclet+'_L_igrf',data={x:elx_pos_eq.x,y:L1}
get_data,'elx_pos_sm',data=elx_pos_sm
req=sqrt(total(elx_pos_eq.y^2.0,2,/nan))
rloc=sqrt(total(elx_pos_sm.y^2.0,2,/nan))
rratio=rloc/req
ibad=where(rratio gt 1.)
if ibad[0] ne -1. then rratio[ibad]=1.00
lat2=acos(sqrt(rratio))/!dtor
tdotp,'elx_bt89_gsm','el'+sclet+'_pos_gsm',newname='elx_br_tmp'
get_data,'elx_br_tmp',data=Br_tmp
ineg=where(Br_tmp.y gt 0.)
if ineg[0] ne -1. then lat2[ineg]=-1.*abs(lat2[ineg])
store_data,'el'+sclet+'_MLAT_igrf',data={x:elx_pos_eq.x,y:lat2}
;;trace to ionosphere (100km) and calculate MLT using AACGM
ttrace2iono,'el'+sclet+'_pos_gsm',newname='el'+sclet+'_ifootn_gsm',external_model='none' $
  ,internal_model='igrf',/km,in_coord='gsm',out_coord='gsm',rlim=100.*Re,/geopack_2008,dsmax=0.01,/standard_mapping
thm_cotrans, 'el'+sclet+'_ifootn_gsm', 'el'+sclet+'_ifootn_mag', out_coord='mag',in_coord='gsm'
get_data,'el'+sclet+'_ifootn_mag',data=elx_nf_mag
cart_to_sphere,elx_nf_mag.y[*,0],elx_nf_mag.y[*,1],elx_nf_mag.y[*,2],r_mag,theta_mag,phi_mag
mlt_igrf = aacgmmlt(time_string(elx_nf_mag.x,precision=-5), elx_nf_mag.x, phi_mag)
store_data,'el'+sclet+'_MLT_igrf',data={x:elx_nf_mag.x,y:mlt_igrf};;projected to 100km and use aacgm
;
print,'*****************************************************************************'
print,'This shows how to estimate MLAT, MLT, L in IGRF field, instead of a dipole
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