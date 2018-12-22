;+
; NAME: rbsp_efw_convection_efield_crib
; SYNTAX:
; PURPOSE: Calculate RBSP convection electric field and velocity
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY: Written by Aaron W Breneman, July 2016. Based on Scott Thaller's crib
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2018-12-21 07:13:50 -0800 (Fri, 21 Dec 2018) $
;   $LastChangedRevision: 26380 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_efw_convection_efield_crib.pro $
;-

;Input variables
date = '2014-02-23'
sc = 'b'
bp = '12'  ;boom pair
;frame = 'corotation'
frame = 'inertial'


rbx = 'rbsp'+sc

;-------------------------------------------------------------------------------
;Load EFW electric field
;-------------------------------------------------------------------------------

rbsp_efw_edotb_to_zero_crib,date,sc,/noplot,boom_pair=bp

if frame eq 'inertial'   then evar = rbx+'_efw_esvy_mgse_vxb_removed_spinfit'
if frame eq 'corotation' then evar = rbx+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'
get_data,evar,etimes,EMGSE

;Create Ex=0 MGSE variable
Ex0 = EMGSE[*,0]
Ex0[*] = 0.


;-------------------------------------------------------------------------------
;Load ephemeris data
;-------------------------------------------------------------------------------

rbsp_efw_position_velocity_crib
tinterpol_mxn,rbx+'_spinaxis_direction_gse',evar,$
  newname=rbx+'_spinaxis_direction_gse'
get_data,rbx+'_spinaxis_direction_gse',ttmp,wgse
get_data,rbx+'_state_pos_gse',data=pos
get_data,rbx+'_state_radius',ttmp,r
get_data,rbx+'_state_lshell',ttmp,lshell



;-------------------------------------------------------------------------------
;Load EMFISIS L3 magnetic field GSE
;-------------------------------------------------------------------------------

rbsp_load_emfisis,probe=sc,cadence='1sec',coord='gse',level='l3'
tinterpol_mxn,rbx+'_emfisis_l3_1sec_gse_Mag',etimes,$
newname=rbx+'_emfisis_l3_1sec_gse_Mag'


;transform to MGSE
rbsp_gse2mgse,rbx+'_emfisis_l3_1sec_gse_Mag',wgse,newname='Mag_mgse'
copy_data,rbx+'_emfisis_l3_1sec_gse_Mag','Mag_gse'
get_data,'Mag_mgse',ttmp,BMGSE
B_mag = SQRT(BMGSE[*,0]^2+BMGSE[*,1]^2+BMGSE[*,2]^2)


;-------------------------------------------------------------------------------
;number of data points to smooth over
;-------------------------------------------------------------------------------


rate =  find_datarate(etimes[0:100])
ttt = rbsp_sample_rate(etimes,out_med_avg=rate)
rate = 1/rate[1]

n_smooth5min = 5.*60./rate
n_smooth33sec = 33./rate
n_smooth55sec = 55./rate


;-------------------------------------------------------------------------------
;Define background magnetic field unit vector
;-------------------------------------------------------------------------------

bg_fieldMGSE = fltarr(n_elements(etimes),3)
Bkgrd_field_mag = smooth(B_mag,n_smooth5min,/nan,/edge_truncate)
bg_fieldMGSE[*,0]  = smooth(BMGSE[*,0],n_smooth5min,/nan,/edge_truncate)/Bkgrd_field_mag
bg_fieldMGSE[*,1]  = smooth(BMGSE[*,1],n_smooth5min,/nan,/edge_truncate)/Bkgrd_field_mag
bg_fieldMGSE[*,2]  = smooth(BMGSE[*,2],n_smooth5min,/nan,/edge_truncate)/Bkgrd_field_mag



;-----------------------------------------------------------------------------
;Define RAF (radial, azimuthal, field-aligned) coordinate system
;-----------------------------------------------------------------------------

tinterpol_mxn,rbx+'_state_pos_gse',etimes,newname=rbx+'_state_pos_gse'
rbsp_gse2mgse,rbx+'_state_pos_gse',wgse,newname=rbx+'_state_pos_mgse'

get_data,rbx+'_state_pos_mgse',data=mgse_pos
mptimes = mgse_pos.x
xmgse = mgse_pos.y[*,0]
ymgse = mgse_pos.y[*,1]
zmgse = mgse_pos.y[*,2]
radial_pos = SQRT(xmgse^2+ymgse^2+zmgse^2)


r_dir_vecMGSE = fltarr(n_elements(etimes),3) ;the vectors along the spin axis
r_dir_vecMGSE[*,0] = xmgse/radial_pos   ;REPLACE WITH RADIAL VECTOR MGSE
r_dir_vecMGSE[*,1] = ymgse/radial_pos
r_dir_vecMGSE[*,2] = zmgse/radial_pos


perp1_dirMGSE = fltarr(n_elements(etimes),3)
for xx=0L,n_elements(etimes)-1 do perp1_dirMGSE[xx,*] = crossp(bg_fieldMGSE[xx,*],r_dir_vecMGSE[xx,*])  ;azimuthal, east
perp2_dirMGSE = fltarr(n_elements(etimes),3)
for xx=0L,n_elements(etimes)-1 do perp2_dirMGSE[xx,*] = crossp(perp1_dirMGSE[xx,*],bg_fieldMGSE[xx,*]) ;radial, outward


;need to normalize perp 1 and perp2 direction
bdotr = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do bdotr[xx] = bg_fieldMGSE[xx,0]*r_dir_vecMGSE[xx,0] + $
bg_fieldMGSE[xx,1]*r_dir_vecMGSE[xx,1] + $
bg_fieldMGSE[xx,2]*r_dir_vecMGSE[xx,2]


;Normalize unit vectors
one_array = replicate(1.0,n_elements(etimes))
perp_norm_fac1 = SQRT(one_array - (bdotr*bdotr))
perp_norm_fac = fltarr(n_elements(etimes),3)
perp_norm_fac[*,0] = perp_norm_fac1
perp_norm_fac[*,1] = perp_norm_fac1
perp_norm_fac[*,2] = perp_norm_fac1

;Radial and azimuthal directions in MGSE coord
perp1_dirMGSE = perp1_dirMGSE/(perp_norm_fac)
perp2_dirMGSE = perp2_dirMGSE/(perp_norm_fac)
par_dirMGSE = bg_fieldMGSE


store_data,'perp1_dir!CMGSE!Cazimuthal!Ceastward!Cunit-vec',$
data={x:etimes,y:perp1_dirMGSE},dlim={colors:[2,4,6],labels:['x','y','z']}
store_data,'perp2_dir!CMGSE!Cradial!Coutward!Cunit-vec',$
data={x:etimes,y:perp2_dirMGSE},dlim={colors:[2,4,6],labels:['x','y','z']}
store_data,'par_dir!CMGSE!Cparallel-to-Bo!Cunit-vec',$
data={x:etimes,y:par_dirMGSE},dlim={colors:[2,4,6],labels:['x','y','z']}



;------------------------------------------------------------------------------
;Project spacecraft velocity onto perpendicular RAF unit vectors
;------------------------------------------------------------------------------

tinterpol_mxn,rbx+'_state_vel_mgse',etimes,newname=rbx+'_state_vel_mgse'
get_data,rbx+'_state_vel_mgse',ttmp,VscMGSE

vsc_perp_1  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
vsc_perp_1[xx] = VscMGSE[xx,0]*perp1_dirMGSE[xx,0] + $
VscMGSE[xx,1]*perp1_dirMGSE[xx,1] + $
VscMGSE[xx,2]*perp1_dirMGSE[xx,2]

vsc_perp_2  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
vsc_perp_2[xx] = VscMGSE[xx,0]*perp2_dirMGSE[xx,0] + $
VscMGSE[xx,1]*perp2_dirMGSE[xx,1] + $
VscMGSE[xx,2]*perp2_dirMGSE[xx,2]

vsc_par = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
vsc_par[xx] = VscMGSE[xx,0]*par_dirMGSE[xx,0] + $
VscMGSE[xx,1]*par_dirMGSE[xx,1] + $
VscMGSE[xx,2]*par_dirMGSE[xx,2]

;spacecraft velocity in RAF coord
store_data,rbx+'_state_vel_raf',etimes,[[vsc_perp_1],[vsc_perp_2],[vsc_par]]
options,rbx+'_state_vel_raf','ytitle',rbx+'!Cvelocity!Cradial!Cazimuthal!Cfieldaligned!C[km/s]'


;------------------------------------------------------------------------------
;Project Efield onto perpendicular RAF unit vectors
;------------------------------------------------------------------------------
;				b) Two vec - input "vec" and "vec2"
;					z-hat is direction of "vec"
;					y-hat = (vec x vec2)/|vec2 x vec|
;					x-hat = (y-hat x vec)/|vec x y-hat|  (vec2 is in x-z plane)
;					Uses this if "vec2" is set



E_perp_1  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
E_perp_1[xx] = EMGSE[xx,0]*perp1_dirMGSE[xx,0] + $
EMGSE[xx,1]*perp1_dirMGSE[xx,1] + $
EMGSE[xx,2]*perp1_dirMGSE[xx,2]

E_perp_2  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
E_perp_2[xx] = EMGSE[xx,0]*perp2_dirMGSE[xx,0] + $
EMGSE[xx,1]*perp2_dirMGSE[xx,1] + $
EMGSE[xx,2]*perp2_dirMGSE[xx,2]

E_par  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
E_par[xx] = EMGSE[xx,0]*par_dirMGSE[xx,0] + $
EMGSE[xx,1]*par_dirMGSE[xx,1] + $
EMGSE[xx,2]*par_dirMGSE[xx,2]


E_perp_10  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
E_perp_10[xx] = Ex0[xx]*perp1_dirMGSE[xx,0] + $
EMGSE[xx,1]*perp1_dirMGSE[xx,1] + $
EMGSE[xx,2]*perp1_dirMGSE[xx,2]

E_perp_20  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
E_perp_20[xx] = Ex0[xx]*perp2_dirMGSE[xx,0] + $
EMGSE[xx,1]*perp2_dirMGSE[xx,1] + $
EMGSE[xx,2]*perp2_dirMGSE[xx,2]

E_par0  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
E_par0[xx] = Ex0[xx]*par_dirMGSE[xx,0] + $
EMGSE[xx,1]*par_dirMGSE[xx,1] + $
EMGSE[xx,2]*par_dirMGSE[xx,2]



edb_stat='E-dot-B'
store_data,rbx+'_E-field!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_1},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'_E-field!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_2},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'_E-field!CFAC!CE-dot-B!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:[[E_perp_1],[E_perp_2]]},$
dlim={constant:[0],colors:[2,6],labels:['Azimuthal!C  East','!C!C  Radial!C  Outward']}



edb_stat='Ex=0'
store_data,rbx+'_E-field!CAzimuthal(East)!CEx=0!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_10},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'_E-field!CRadial(Outward)!CEx=0!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_20},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'_E-field!CFAC!CEx=0!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:[[E_perp_10],[E_perp_20],[E_par0]]},$
dlim={constant:[0],colors:[2,6],labels:['Azimuthal!C  East','!C!C  Radial!C  Outward','!C!C field aligned']}



;-------------------------------------------------------------------------------
;Calculate ExB velocity in MGSE coord
;-------------------------------------------------------------------------------

exbMGSE = 1000.*[[(EMGSE[*,1]*BMGSE[*,2] - EMGSE[*,2]*BMGSE[*,1])/B_mag^2],$
[(EMGSE[*,2]*BMGSE[*,0] - EMGSE[*,0]*BMGSE[*,2])/B_mag^2],$
[(EMGSE[*,0]*BMGSE[*,1] - EMGSE[*,1]*BMGSE[*,0])/B_mag^2]]
store_data,rbx+'!CExB!CMGSE!CE-dot-B!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE}

exbMGSE0 = 1000.*[[(EMGSE[*,1]*BMGSE[*,2] - EMGSE[*,2]*BMGSE[*,1])/B_mag^2],$
[(EMGSE[*,2]*BMGSE[*,0] - Ex0*BMGSE[*,2])/B_mag^2],$
[(Ex0*BMGSE[*,1] - EMGSE[*,1]*BMGSE[*,0])/B_mag^2]]
store_data,rbx+'!CExB!CMGSE!CEx=0!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE0}

exbMGSEx_tmp = smooth(exbMGSE[*,0],n_smooth5min,/nan,/edge_truncate)
exbMGSEy_tmp = smooth(exbMGSE[*,1],n_smooth5min,/nan,/edge_truncate)
exbMGSEz_tmp = smooth(exbMGSE[*,2],n_smooth5min,/nan,/edge_truncate)
exbMGSE_tmp = [[exbMGSEx_tmp],[exbMGSEy_tmp],[exbMGSEz_tmp]]
store_data,rbx+'!CExB!CMGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE_tmp}

exbMGSEx_tmp = smooth(exbMGSE[*,0],n_smooth33sec,/nan,/edge_truncate)
exbMGSEy_tmp = smooth(exbMGSE[*,1],n_smooth33sec,/nan,/edge_truncate)
exbMGSEz_tmp = smooth(exbMGSE[*,2],n_smooth33sec,/nan,/edge_truncate)
exbMGSE_tmp = [[exbMGSEx_tmp],[exbMGSEy_tmp],[exbMGSEz_tmp]]
store_data,rbx+'!CExB!CMGSE!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE_tmp}

exbMGSEx_tmp = smooth(exbMGSE[*,0],n_smooth55sec,/nan,/edge_truncate)
exbMGSEy_tmp = smooth(exbMGSE[*,1],n_smooth55sec,/nan,/edge_truncate)
exbMGSEz_tmp = smooth(exbMGSE[*,2],n_smooth55sec,/nan,/edge_truncate)
exbMGSE_tmp = [[exbMGSEx_tmp],[exbMGSEy_tmp],[exbMGSEz_tmp]]
store_data,rbx+'!CExB!CMGSE!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE_tmp}

exbMGSEx_tmp = smooth(exbMGSE0[*,0],n_smooth5min,/nan,/edge_truncate)
exbMGSEy_tmp = smooth(exbMGSE0[*,1],n_smooth5min,/nan,/edge_truncate)
exbMGSEz_tmp = smooth(exbMGSE0[*,2],n_smooth5min,/nan,/edge_truncate)
exbMGSE_tmp = [[exbMGSEx_tmp],[exbMGSEy_tmp],[exbMGSEz_tmp]]
store_data,rbx+'!CExB!CMGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE_tmp}

exbMGSEx_tmp = smooth(exbMGSE0[*,0],n_smooth33sec,/nan,/edge_truncate)
exbMGSEy_tmp = smooth(exbMGSE0[*,1],n_smooth33sec,/nan,/edge_truncate)
exbMGSEz_tmp = smooth(exbMGSE0[*,2],n_smooth33sec,/nan,/edge_truncate)
exbMGSE_tmp = [[exbMGSEx_tmp],[exbMGSEy_tmp],[exbMGSEz_tmp]]
store_data,rbx+'!CExB!CMGSE!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE_tmp}

exbMGSEx_tmp = smooth(exbMGSE0[*,0],n_smooth55sec,/nan,/edge_truncate)
exbMGSEy_tmp = smooth(exbMGSE0[*,1],n_smooth55sec,/nan,/edge_truncate)
exbMGSEz_tmp = smooth(exbMGSE0[*,2],n_smooth55sec,/nan,/edge_truncate)
exbMGSE_tmp = [[exbMGSEx_tmp],[exbMGSEy_tmp],[exbMGSEz_tmp]]
store_data,rbx+'!CExB!CMGSE!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',data={x:etimes,y:exbMGSE_tmp}



;------------------------------------------------------------------------------
; now project ExB velocity into RAF coordinates
;------------------------------------------------------------------------------

exb_perp_1  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
exb_perp_1[xx] = exbMGSE[xx,0]*perp1_dirMGSE[xx,0] + $
exbMGSE[xx,1]*perp1_dirMGSE[xx,1] + $
exbMGSE[xx,2]*perp1_dirMGSE[xx,2]

exb_perp_2  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
exb_perp_2[xx] = exbMGSE[xx,0]*perp2_dirMGSE[xx,0] + $
exbMGSE[xx,1]*perp2_dirMGSE[xx,1] + $
exbMGSE[xx,2]*perp2_dirMGSE[xx,2]

exb_par = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
exb_par[xx] = exbMGSE[xx,0]*par_dirMGSE[xx,0] + $
exbMGSE[xx,1]*par_dirMGSE[xx,1] + $
exbMGSE[xx,2]*par_dirMGSE[xx,2]

exb_perp_10  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
exb_perp_10[xx] = exbMGSE0[xx,0]*perp1_dirMGSE[xx,0] + $
exbMGSE0[xx,1]*perp1_dirMGSE[xx,1] + $
exbMGSE0[xx,2]*perp1_dirMGSE[xx,2]

exb_perp_20  = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
exb_perp_20[xx] = exbMGSE0[xx,0]*perp2_dirMGSE[xx,0] + $
exbMGSE0[xx,1]*perp2_dirMGSE[xx,1] + $
exbMGSE0[xx,2]*perp2_dirMGSE[xx,2]

exb_par0 = fltarr(n_elements(etimes))
for xx=0L,n_elements(etimes)-1 do $
exb_par0[xx] = exbMGSE0[xx,0]*par_dirMGSE[xx,0] + $
exbMGSE0[xx,1]*par_dirMGSE[xx,1] + $
exbMGSE0[xx,2]*par_dirMGSE[xx,2]


edb_stat='E-dot-B'

store_data,rbx+'!CExB!CAzimuthal(East)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_1},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'!CExB!CRadial(Outward)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_2},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'!CExB!CFieldaligned!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_par},dlim={constant:[0],colors:[0],labels:['']}

store_data,rbx+'!CExB!CAzimuthal(East)!C33sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_1,n_smooth33sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CRadial(Outward)!C33sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_2,n_smooth33sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CFieldaligned!C33sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_par,n_smooth33sec,/nan,/edge_truncate)}

store_data,rbx+'!CExB!CAzimuthal(East)!C55sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_1,n_smooth55sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CRadial(Outward)!C55sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_2,n_smooth55sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CFieldaligned!C55sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_par,n_smooth55sec,/nan,/edge_truncate)}

store_data,rbx+'!CExB!CAzimuthal(East)!C5min_avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_1,n_smooth5min,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CRadial(Outward)!C5min_avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_2,n_smooth5min,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CFieldaligned!C5min_avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_par,n_smooth5min,/nan,/edge_truncate)}


edb_stat='Ex=0'

store_data,rbx+'!CExB!CAzimuthal(East)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_10},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'!CExB!CRadial(Outward)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_20},dlim={constant:[0],colors:[0],labels:['']}
store_data,rbx+'!CExB!CFieldaligned!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_par0},dlim={constant:[0],colors:[0],labels:['']}

store_data,rbx+'!CExB!CAzimuthal(East)!C33sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_10,n_smooth33sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CRadial(Outward)!C33sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_20,n_smooth33sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CFieldaligned!C33sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_par0,n_smooth33sec,/nan,/edge_truncate)}

store_data,rbx+'!CExB!CAzimuthal(East)!C55sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_10,n_smooth55sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CRadial(Outward)!C55sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_20,n_smooth55sec,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CFieldaligned!C55sec-avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_par0,n_smooth55sec,/nan,/edge_truncate)}

store_data,rbx+'!CExB!CAzimuthal(East)!C5min_avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_10,n_smooth5min,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CRadial(Outward)!C5min_avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_20,n_smooth5min,/nan,/edge_truncate)}
store_data,rbx+'!CExB!CFieldaligned!C5min_avg!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_par0,n_smooth5min,/nan,/edge_truncate)}



;-------------------------------------------------------------------------------
; Calculate ExB velocity in GSE coordinates
;-------------------------------------------------------------------------------


rbsp_mgse2gse,rbx+'!CExB!CMGSE!CE-dot-B!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!CE-dot-B!C'+frame+'-frame!Ckm/s'
rbsp_mgse2gse,rbx+'!CExB!CMGSE!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s'
rbsp_mgse2gse,rbx+'!CExB!CMGSE!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s'
rbsp_mgse2gse,rbx+'!CExB!CMGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s'

rbsp_mgse2gse,rbx+'!CExB!CMGSE!CEx=0!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!CEx=0!C'+frame+'-frame!Ckm/s'
rbsp_mgse2gse,rbx+'!CExB!CMGSE!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s'
rbsp_mgse2gse,rbx+'!CExB!CMGSE!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s'
rbsp_mgse2gse,rbx+'!CExB!CMGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',wgse,newname=rbx+'!CExB!CGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s'


;-------------------------------------------------------------------------------
;Plot difference b/t convection velocity and sc velocity (used for Doppler shift)
;-------------------------------------------------------------------------------

;MGSE coord
dif_data,rbx+'!CExB!CMGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',rbx+'_state_vel_mgse',newname=rbx+'!Cvconvection-vsc_MGSE!C5min_avg!CE-dot-B'
options,rbx+'!Cvconvection-vsc_MGSE!C5min_avg!CE-dot-B','ytitle',rbx+'!Cvconvection-vsc!CMGSE!C5min_avg!CE-dot-B!C[km/s]'


;GSE coord
dif_data,rbx+'!CExB!CGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_gse',$
newname=rbx+'!Cvconvection-vsc_GSE!C5min_avg!CE-dot-B'
options,rbx+'!Cvconvection-vsc_GSE!C5min_avg!CE-dot-B','ytitle',rbx+'!Cvconvection-vsc!CGSE!C5min_avg!CE-dot-B!C[km/s]'



;RAF coord
get_data,rbx+'!CExB!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!Ckm/s',ttmp,vr
get_data,rbx+'!CExB!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!Ckm/s',ttmp,va
get_data,rbx+'!CExB!CFieldaligned!CE-dot-B!C'+frame+'-frame!Ckm/s',ttmp,vz
store_data,rbx+'!CExB!CRAF!CE-dot-B!C'+frame+'-frame!Ckm/s',etimes,[[vr],[va],[vz]]
dif_data,rbx+'!CExB!CRAF!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_raf',$
newname=rbx+'!Cvconvection-vsc_RAF!CE-dot-B'
options,rbx+'!Cvconvection-vsc_RAF!CE-dot-B','ytitle',rbx+'!Cvconvection-vsc!CRAF!CE-dot-B!C[km/s]'


get_data,rbx+'!CExB!CRadial(Outward)!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',ttmp,vr
get_data,rbx+'!CExB!CAzimuthal(East)!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',ttmp,va
get_data,rbx+'!CExB!CFieldaligned!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',ttmp,vz
store_data,rbx+'!CExB!CRAF!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',etimes,[[vr],[va],[vz]]
dif_data,rbx+'!CExB!CRAF!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_raf',$
newname=rbx+'!Cvconvection-vsc_RAF!C5min_avg!CE-dot-B'
options,rbx+'!Cvconvection-vsc_RAF!C5min_avg!CE-dot-B','ytitle',rbx+'!Cvconvection-vsc!CRAF!C5min_avg!CE-dot-B!C[km/s]'


;MGSE coord
dif_data,rbx+'!CExB!CMGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_mgse',$
newname=rbx+'!Cvconvection-vsc_MGSE!C5min_avg!CEx=0'
options,rbx+'!Cvconvection-vsc_MGSE!C5min_avg!CEx=0','ytitle',rbx+'!Cvconvection-vsc!CMGSE!C5min_avg!CEx=0!C[km/s]'

;GSE coord
dif_data,rbx+'!CExB!CGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_gse',$
newname=rbx+'!Cvconvection-vsc_GSE!C5min_avg!CEx=0'
options,rbx+'!Cvconvection-vsc_GSE!C5min_avg!CEx=0','ytitle',rbx+'!Cvconvection-vsc!CGSE!C5min_avg!CEx=0!C[km/s]'

;RAF coord
get_data,rbx+'!CExB!CRadial(Outward)!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',ttmp,vr
get_data,rbx+'!CExB!CAzimuthal(East)!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',ttmp,va
get_data,rbx+'!CExB!CFieldaligned!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',ttmp,vz
store_data,rbx+'!CExB!CRAF!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',etimes,[[vr],[va],[vz]]
dif_data,rbx+'!CExB!CRAF!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_raf',$
newname=rbx+'!Cvconvection-vsc_RAF!C5min_avg!CEx=0'
options,rbx+'!Cvconvection-vsc_RAF!C5min_avg!CEx=0','ytitle',rbx+'!Cvconvection-vsc!CRAF!C5min_avg!CEx=0!C[km/s]'




;-------------------------------------------------------------------------------
;Plot quantities
;-------------------------------------------------------------------------------



options,'*',constant=0


stop

;unit vectors
tplot,['perp1_dir!CMGSE!Cazimuthal!Ceastward!Cunit-vec',$
'perp2_dir!CMGSE!Cradial!Coutward!Cunit-vec']

;-----------
;Plot quantities using E*B=0 assumption

;Electric fields
tplot,[evar,$
rbx+'_E-field!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!CmV/m',$
rbx+'_E-field!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!CmV/m',$
rbx+'_E-field!CFAC!CE-dot-B!C'+frame+'-frame!CmV/m']

;ExB velocities (E*B=0, no time averaging)
tplot,[rbx+'!CExB!CMGSE!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!Ckm/s']

;ExB velocities (E*B=0, 33 sec time averaging)
tplot,[rbx+'!CExB!CMGSE!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C33sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s']

;ExB velocities (E*B=0, 55 sec time averaging)
tplot,[rbx+'!CExB!CMGSE!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CAzimuthal(East)!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C55sec-avg!CE-dot-B!C'+frame+'-frame!Ckm/s']

;ExB velocities (E*B=0, 5 min time averaging)
tplot,[rbx+'!CExB!CMGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CAzimuthal(East)!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s']

;Convection velocity - spacecraft velocity for Doppler shift
tplot,[rbx+'!CExB!CMGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_mgse',$
rbx+'!Cvconvection-vsc_MGSE!C5min_avg!CE-dot-B']

tplot,[rbx+'!CExB!CGSE!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_gse',$
rbx+'!Cvconvection-vsc_GSE!C5min_avg!CE-dot-B']

tplot,[rbx+'!CExB!CRAF!C5min_avg!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_raf',$
rbx+'!Cvconvection-vsc_RAF!C5min_avg!CE-dot-B']

tplot,[rbx+'!CExB!CRAF!CE-dot-B!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_raf',$
rbx+'!Cvconvection-vsc_RAF!CE-dot-B',$
'rbspb_emfisis_l3_1sec_gse_Mag','rbspb_emfisis_l3_1sec_gse_Magnitude']






;-------------------------------------
;Plot quantities using Ex=0 assumption

;Electric fields
tplot,[evar,$
rbx+'_E-field!CAzimuthal(East)!CEx=0!C'+frame+'-frame!CmV/m',$
rbx+'_E-field!CRadial(Outward)!CEx=0!C'+frame+'-frame!CmV/m',$
rbx+'_E-field!CFAC!CEx=0!C'+frame+'-frame!CmV/m']

;ExB velocities (E*B=0, no time averaging)
tplot,[rbx+'!CExB!CMGSE!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CAzimuthal(East)!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!CEx=0!C'+frame+'-frame!Ckm/s']

;ExB velocities (E*B=0, 33 sec time averaging)
tplot,[rbx+'!CExB!CMGSE!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C33sec-avg!CEx=0!C'+frame+'-frame!Ckm/s']

;ExB velocities (E*B=0, 55 sec time averaging)
tplot,[rbx+'!CExB!CMGSE!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CAzimuthal(East)!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C55sec-avg!CEx=0!C'+frame+'-frame!Ckm/s']

;ExB velocities (E*B=0, 5 min time averaging)
tplot,[rbx+'!CExB!CMGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CRadial(Outward)!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'!CExB!CAzimuthal(East)!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s']


;Convection velocity - spacecraft velocity for Doppler shift
tplot,[rbx+'!CExB!CMGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_mgse',$
rbx+'!Cvconvection-vsc_MGSE!C5min_avg!CEx=0']

tplot,[rbx+'!CExB!CGSE!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_gse',$
rbx+'!Cvconvection-vsc_GSE!C5min_avg!CEx=0']

tplot,[rbx+'!CExB!CRAF!C5min_avg!CEx=0!C'+frame+'-frame!Ckm/s',$
rbx+'_state_vel_raf',$
rbx+'!Cvconvection-vsc_RAF!C5min_avg!CEx=0']


stop

end
