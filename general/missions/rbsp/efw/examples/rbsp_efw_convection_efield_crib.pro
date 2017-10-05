;+
; NAME: rbsp_efw_convection_efield_crib
; SYNTAX:
; PURPOSE: Calculate RBSP convection electric field and velocity
; INPUT:
; OUTPUT:
; KEYWORDS:
; HISTORY:
; VERSION: Written by Aaron W Breneman, July 2016. Based on Scott Thaller's crib
;-



date = '2014-02-23'
;date = '2013-02-23'
probe = 'b'
sc = probe
bp = '12'
;frame = 'corotation'
frame = 'inertial'



;-------------------------------------------------------------------------------
;Load EFW electric field
;-------------------------------------------------------------------------------

rbsp_efw_edotb_to_zero_crib,date,probe,/noplot,boom_pair=bp

if frame eq 'inertial'   then evar = 'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_spinfit'
if frame eq 'corotation' then evar = 'rbsp'+sc+'_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'
get_data,evar,etimes,EMGSE

;Create Ex=0 MGSE variable
Ex0 = EMGSE[*,0]
Ex0[*] = 0.


;-------------------------------------------------------------------------------
;Load ephemeris data
;-------------------------------------------------------------------------------

rbsp_efw_position_velocity_crib
tinterpol_mxn,'rbsp'+sc+'_spinaxis_direction_gse',evar,newname='rbsp'+sc+'_spinaxis_direction_gse'
get_data,'rbsp'+sc+'_spinaxis_direction_gse',ttmp,wgse
get_data,'rbsp'+sc+'_state_pos_gse',data=pos
get_data,'rbsp'+sc+'_state_radius',ttmp,r
get_data,'rbsp'+sc+'_state_lshell',ttmp,lshell



;-------------------------------------------------------------------------------
;Load EMFISIS L3 magnetic field GSE
;-------------------------------------------------------------------------------

rbsp_load_emfisis,probe=probe,cadence='1sec',coord='gse',level='l3'
tinterpol_mxn,'rbsp'+sc+'_emfisis_l3_1sec_gse_Mag',etimes,$
newname='rbsp'+sc+'_emfisis_l3_1sec_gse_Mag'

;get_data,'rbsp'+sc+'_emfisis_l3_1sec_gse_Mag',data=Bmag_l3

;transform to MGSE
rbsp_gse2mgse,'rbsp'+sc+'_emfisis_l3_1sec_gse_Mag',wgse,newname='Mag_mgse'
copy_data,'rbsp'+sc+'_emfisis_l3_1sec_gse_Mag','Mag_gse'
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




;------------------------------------
;Define RAF (radial, azimuthal, field-aligned) coordinate system
;------------------------------------

tinterpol_mxn,'rbsp'+sc+'_state_pos_gse',etimes,newname='rbsp'+sc+'_state_pos_gse'
rbsp_gse2mgse,'rbsp'+sc+'_state_pos_gse',wgse,newname='rbsp'+sc+'_state_pos_mgse'

get_data,'rbsp'+sc+'_state_pos_mgse',data=mgse_pos
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


store_data,'perp1_dir!CMGSE!Cazimuthal!Ceastward!Cunit-vec',$
data={x:etimes,y:perp1_dirMGSE},dlim={colors:[2,4,6],labels:['x','y','z']}
store_data,'perp2_dir!CMGSE!Cradial!Coutward!Cunit-vec',$
data={x:etimes,y:perp2_dirMGSE},dlim={colors:[2,4,6],labels:['x','y','z']}


;------------------------------------------------------------------------------
;Project Efield onto perpendicular RAF unit vectors
;------------------------------------------------------------------------------

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




edb_stat='E-dot-B'
store_data,'RBSP'+sc+'_E-field!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_1},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'_E-field!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_2},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'_E-field!CFAC!CE-dot-B!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:[[E_perp_1],[E_perp_2]]},$
dlim={constant:[0],colors:[2,6],labels:['Azimuthal!C  East','!C!C  Radial!C  Outward']}



edb_stat='Ex=0'
store_data,'RBSP'+sc+'_E-field!CAzimuthal(East)!CEx=0!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_10},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'_E-field!CRadial(Outward)!CEx=0!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:E_perp_20},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'_E-field!CFAC!CEx=0!C'+frame+'-frame!CmV/m',$
data = {x:etimes,y:[[E_perp_10],[E_perp_20]]},$
dlim={constant:[0],colors:[2,6],labels:['Azimuthal!C  East','!C!C  Radial!C  Outward']}



;-------------------------------------------------------------------------------
;Calculate ExB velocity in MGSE coord
;-------------------------------------------------------------------------------

exbMGSE = 1000.*[[(EMGSE[*,1]*BMGSE[*,2] - EMGSE[*,2]*BMGSE[*,1])/B_mag^2],$
[(EMGSE[*,2]*BMGSE[*,0] - EMGSE[*,0]*BMGSE[*,2])/B_mag^2],$
[(EMGSE[*,0]*BMGSE[*,1] - EMGSE[*,1]*BMGSE[*,0])/B_mag^2]]

exbMGSE0 = 1000.*[[(EMGSE[*,1]*BMGSE[*,2] - EMGSE[*,2]*BMGSE[*,1])/B_mag^2],$
[(EMGSE[*,2]*BMGSE[*,0] - Ex0*BMGSE[*,2])/B_mag^2],$
[(Ex0*BMGSE[*,1] - EMGSE[*,1]*BMGSE[*,0])/B_mag^2]]

store_data,'RBSP'+sc+'!CExB!CMGSE!CE-dot-B!Ckm/s',data={x:etimes,y:exbMGSE}
store_data,'RBSP'+sc+'!CExB!CMGSE!CEx=0!Ckm/s',data={x:etimes,y:exbMGSE0}



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

edb_stat='E-dot-B'

store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_1},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_2},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C33-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_1,n_smooth33sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C55-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_1,n_smooth55sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C5-min.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_1,n_smooth5min,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C33-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_2,n_smooth33sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C55-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_2,n_smooth55sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C5-min.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_2,n_smooth5min,/nan,/edge_truncate)}


edb_stat='Ex=0'

store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_10},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:exb_perp_20},dlim={constant:[0],colors:[0],labels:['']}
store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C33-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_10,n_smooth33sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C55-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_10,n_smooth55sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CAzimuthal(East)!C5-min.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_10,n_smooth5min,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C33-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_20,n_smooth33sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C55-sec.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_20,n_smooth55sec,/nan,/edge_truncate)}
store_data,'RBSP'+sc+'!CExB!CRadial(Outward)!C5-min.-ave.!C'+edb_stat+'!C'+frame+'-frame!Ckm/s',data = {x:etimes,y:smooth(exb_perp_20,n_smooth5min,/nan,/edge_truncate)}



;-------------------------------------------------------------------------------
; Calculate ExB velocity in GSE coordinates
;-------------------------------------------------------------------------------

rbsp_mgse2gse,'RBSP'+sc+'!CExB!CMGSE!CE-dot-B!Ckm/s',wgse,newname='RBSP'+sc+'!CExB!CGSE!CE-dot-B!Ckm/s'
rbsp_mgse2gse,'RBSP'+sc+'!CExB!CMGSE!CEx=0!Ckm/s',wgse,newname='RBSP'+sc+'!CExB!CGSE!CEx=0!Ckm/s'



;-------------------------------------------------------------------------------
;Plot quantities
;-------------------------------------------------------------------------------

options,['*'],constant=0

;unit vectors
tplot,['perp1_dir!CMGSE!Cazimuthal!Ceastward!Cunit-vec',$
'perp2_dir!CMGSE!Cradial!Coutward!Cunit-vec']

;-----------
;Plot quantities using E*B=0 assumption

;Electric fields
tplot,['RBSP'+sc+'_E-field!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!CmV/m',$
'RBSP'+sc+'_E-field!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!CmV/m',$
'RBSP'+sc+'_E-field!CFAC!CE-dot-B!C'+frame+'-frame!CmV/m']
;ExB velocities (E*B=0, no time averaging)
;...MGSE ExB velocities
tplot,['RBSP'+sc+'!CExB!CMGSE!CE-dot-B!Ckm/s',$
'RBSP'+sc+'!CExB!CGSE!CE-dot-B!Ckm/s']
tplot,['RBSP'+sc+'!CExB!CAzimuthal(East)!CE-dot-B!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CRadial(Outward)!CE-dot-B!C'+frame+'-frame!Ckm/s']
;ExB velocities (E*B=0, 33 sec time averaging)
tplot,['RBSP'+sc+'!CExB!CRadial(Outward)!C33-sec.-ave.!CE-dot-B!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CRadial(Outward)!C33-sec.-ave.!CE-dot-B!C'+frame+'-frame!Ckm/s']
;ExB velocities (E*B=0, 55 sec time averaging)
tplot,['RBSP'+sc+'!CExB!CAzimuthal(East)!C55-sec.-ave.!CE-dot-B!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CRadial(Outward)!C55-sec.-ave.!CE-dot-B!C'+frame+'-frame!Ckm/s']
;ExB velocities (E*B=0, 5 min time averaging)
tplot,['RBSP'+sc+'!CExB!CRadial(Outward)!C5-min.-ave.!CE-dot-B!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CAzimuthal(East)!C5-min.-ave.!CE-dot-B!C'+frame+'-frame!Ckm/s']


;-------------------------------------
;Plot quantities using Ex=0 assumption

;Electric fields
tplot,['RBSP'+sc+'_E-field!CAzimuthal(East)!CEx=0!C'+frame+'-frame!CmV/m',$
'RBSP'+sc+'_E-field!CRadial(Outward)!CEx=0!C'+frame+'-frame!CmV/m',$
'RBSP'+sc+'_E-field!CFAC!CEx=0!C'+frame+'-frame!CmV/m']
;ExB velocities (E*B=0, no time averaging)
;...MGSE ExB velocities
tplot,['RBSP'+sc+'!CExB!CMGSE!CEx=0!Ckm/s',$
'RBSP'+sc+'!CExB!CGSE!CEx=0!Ckm/s']
tplot,['RBSP'+sc+'!CExB!CAzimuthal(East)!CEx=0!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CRadial(Outward)!CEx=0!C'+frame+'-frame!Ckm/s']
;ExB velocities (E*B=0, 33 sec time averaging)
tplot,['RBSP'+sc+'!CExB!CRadial(Outward)!C33-sec.-ave.!CEx=0!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CRadial(Outward)!C33-sec.-ave.!CEx=0!C'+frame+'-frame!Ckm/s']
;ExB velocities (E*B=0, 55 sec time averaging)
tplot,['RBSP'+sc+'!CExB!CAzimuthal(East)!C55-sec.-ave.!CEx=0!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CRadial(Outward)!C55-sec.-ave.!CEx=0!C'+frame+'-frame!Ckm/s']
;ExB velocities (E*B=0, 5 min time averaging)
tplot,['RBSP'+sc+'!CExB!CRadial(Outward)!C5-min.-ave.!CEx=0!C'+frame+'-frame!Ckm/s',$
'RBSP'+sc+'!CExB!CAzimuthal(East)!C5-min.-ave.!CEx=0!C'+frame+'-frame!Ckm/s']





end
