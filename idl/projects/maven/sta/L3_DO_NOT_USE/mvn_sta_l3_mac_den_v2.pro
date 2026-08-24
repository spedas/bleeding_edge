;+
;PROCEDURE:	mac_den
;PURPOSE:	
;	Calculates Ni from sta c6 and puts it into tplot structures
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  19/06/14
;MOD HISTORY:
;
;NOTES:	  
;CMF edited the original routine to work in the processing pipeline. This routine no longer has options to calculate bkg - the routine is 
;designed to be run on the iv1 level STATIC files, which already have bkg added.
;	
;yesd0, yesd1: equal '1' if these data products exist, and 0 if they don't.
;	
;trange: [a,b] double UNIX time range to look at. Speeds up routine, especially with new background routine.	
;	
;colorindices: a data structure containg the color table indices for IDL for the color/element names:
; black, purple, brown, magenta, blue, cyan, green, yellow, orange, red, white. Use best guesses if the set color table doesn't
; have some of these specifically. Should work for ct 39, 43. For processing routine, this structure is created in mvn_sta_l3_den.pro.
;
;Set /nobkg to run even if there are no bkg data loaded. The default, if not set, is to only proceed if the total(dat.bkg) >0 (i.e., bkg files
;       have been loaded using iv_level > 0 in mvn_sta_l2_load).	
;	
;Use STATIC compiler crib for full set of routines to compile.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Density_routines/mvn_sta_get_kk3.pro
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_mac_den_v2.pro	
;	
;-
pro mvn_sta_l3_mac_den_v2, yesd0, yesd1, skip_get_4dt=skip_get_4dt,energy=energy, trange=trange, success=success, colorindices=colorindices, nobkg=nobkg

proname = 'mvn_sta_l3_mac_den_v2'

common mvn_c6,mvn_c6_ind,mvn_c6_dat
common mvn_sta_kk3_anode,kk3_anode

if not keyword_set(trange) then begin
    times = (mvn_c6_dat.time + mvn_c6_dat.end_time)/2.  ;c6 timestamps
    trange = [min(times), max(times)]
endif

;Check bkg has been loaded: CMF edit: but ignore this step if nobkg=1
;kgh edit: do this for the whole time range, not one time 
;dat=mvn_sta_get_c6(total(trange)/2.)
if not keyword_set(nobkg) then begin
  ;if total(dat.bkg) eq 0 then begin
    if total(mvn_c6_dat.bkg) eq 0 then begin
      print, proname, ": STATIC bkg has not been loaded. Make sure level iv data are available."
      success=0
      return
  endif
endif

cols = colorindices  ;copy variable

c6_avg=3
mvn_sta_make_c6_avg_v2,/verbose,avg=c6_avg

;======================

if not keyword_set(energy) then energy = [0., 1000.]  ;energy=[0,11.]

kk3_anode=1
tt=trange   ;timerange()  ;trange is the variable set above by keyword or default settings
kk3=mvn_sta_get_kk3((tt[0]+tt[1])/2.)

;print,'kk3=',kk3
kk3_string = strmid(string(round(kk3[0]*10.)/10.),6,3)+'-'+strmid(string(round(kk3[1]*10.)/10.),6,3)+'-'+strmid(string(round(kk3[2]*10.)/10.),6,3)+'-'+strmid(string(round(kk3[3]*10.)/10.),6,3)
kk=kk3_string


; Calculate O2+ density and characteristic energy

	mass_o2 = [24,40.]
	m_o2 = 32.
	engy_o2 = energy
	min_o2 = 0.

	get_4dt,t1=trange[0], t2=trange[1], 'ec_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_ec',energy=engy_o2,m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_ec',ytitle='sta!Cc6!C<11eV!CEc!CO2+!CeV',colors=cols.red & ylim,'mvn_sta_o2+_c6_ec',1,30,1

	get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_cnts',energy=engy_o2,m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_cnts',ytitle='sta!Cc6!C<11eV!CO2+!Ccnts',colors=cols.black & ylim,'mvn_sta_o2+_c6_cnts',1,10000,1

	get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_bkg',energy=engy_o2,m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_bkg',ytitle='sta!Cc6!C<11eV!CO2+!Cbkg',colors=cols.black & ylim,'mvn_sta_o2+_c6_bkg',1,10000,1

  get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_all_cnts',energy=[0.,40000.],m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_all_cnts',ytitle='sta!Cc6!Call eV!CO2+!Ccnts',colors=cols.black & ylim,'mvn_sta_o2+_c6_all_cnts',1,10000,1

	get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_all_bkg',energy=[0.,40000.],m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_all_bkg',ytitle='sta!Cc6!Call eV!CO2+!Cbkg',colors=cols.black & ylim,'mvn_sta_o2+_c6_all_bkg',1,10000,1

	get_4dt,t1=trange[0], t2=trange[1], 'nbc_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_density2',energy=engy_o2,m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_density2',ytitle='sta!Cc6!C<11eV!CO2+!C1/cm!U3',colors=cols.red,labels='c6_O2+',labpos=1.e4
		ylim,'mvn_sta_o2+_c6_density2',1000,1.e5,1

	get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_density_all',energy=[0,40000],m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_density_all',ytitle='sta c6 all!C O2+!C!C1/cm!U3',colors=cols.blue,labels='c6_O2+',labpos=1.e4
		ylim,'mvn_sta_o2+_c6_density_all',.1,1.e5,1

	get_4dt,t1=trange[0], t2=trange[1], 'nbc_nolpw_4d','mvn_sta_get_c6',mass=mass_o2,name='mvn_sta_o2+_c6_density2_nolpw',energy=engy_o2,m_int=m_o2,mincnt=min_o2
		options,'mvn_sta_o2+_c6_density2_nolpw',ytitle='sta c6 <11eV!C O2+!C!C1/cm!U3',colors=cols.green,labels='c6_nolpw',labpos=5.e3
		ylim,'mvn_sta_o2+_c6_density2_nolpw',1000,1.e5,1

	store_data,'mvn_sta_o2+_c6_density2_nolpw_compare',data=['mvn_sta_o2+_c6_density2','mvn_sta_o2+_c6_density2_nolpw']
		ylim,'mvn_sta_o2+_c6_density2_nolpw_compare',1000,1.e5,1

	get_4dt,t1=trange[0], t2=trange[1], 'vb_4d','mvn_sta_get_c6_avg',mass=mass_o2,name='mvn_sta_c6_vb_o2_avg',energy=engy_o2,m_int=m_o2
		options,'mvn_sta_c6_vb_o2_avg',ytitle='c6_avg <11eV!C!CO2+!C!Cvb',ylog=0,yrange=[3.4,4.6],color=cols.black,labels='c6_O2+',labpos=4.

	store_data,'mvn_sta_c6_vb_o2_avg_ram',data=['mvn_sta_c6_vb_o2_avg','mvn_v_ram']

	get_4dt,t1=trange[0], t2=trange[1], 'vp_4d','mvn_sta_get_c8',name='mvn_sta_o2+_c8_vperp',energy=engy_o2,m_int=32.
		options,'mvn_sta_o2+_c8_vperp',ytitle='sta c8 <11eV!C O2+!C!Ckm/s'
		ylim,'mvn_sta_o2+_c8_vperp',-1.,1.,0
;	tplot,['mvn_sta_o2+_c8_vperp','mvn_sta_c0_H_E_pot_ec','mvn_sta_c6_M','mvn_sta_c8_D','mvn_sta_c6_att']

;	get_4dt,t1=trange[0], t2=trange[1], 'nbc_4d','mvn_sta_get_c6e',mass=mass_o2,name='mvn_sta_o2+_c6e_density2',energy=engy_o2,m_int=m_o2,mincnt=min_o2
;		options,'mvn_sta_o2+_c6e_density2',ytitle='sta c6e!C O2+!C!C1/cm!U3',colors=cols.cyan
;		ylim,'mvn_sta_o2+_c6e_density2',1000,1.e5,1

	get_data,'mvn_sta_c6_att',data=tmp0
	get_data,'mvn_sta_kk3',data=tmp1
	kk3_full = tmp1.y[0,tmp0.y]
	get_data,'mvn_sta_o2+_c6_ec',data=tmp2
	get_data,'mvn_sta_o2+_c6_cnts',data=tmp3
	get_data,'mvn_sta_o2+_c6_bkg',data=tmp4
	; kk3_full/1.3 is a bit arbitray - should be determined emperically 
	store_data,'mvn_sta_o2+_c6_nbc_den_qf',data={x:tmp3.x,y:(tmp2.y gt kk3_full/1.3) and ((tmp3.y-tmp4.y) ge 10.) and ((tmp3.y-tmp4.y) ge tmp4.y^.5)}
		ylim,'mvn_sta_o2+_c6_nbc_den_qf',-1,2,0


  ;Calculate O2+ using n_4d, d0 and d1 data:
    if yesd0 eq 1 then begin
  		get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d0',mass=mass_o2,name='mvn_sta_o2+_d0_density_n_4d',energy=[0,40000],m_int=m_o2,mincnt=min_o2
  		options,'mvn_sta_o2+_d0_density_n_4d',ytitle='sta d0 n_4d!C O2+!C!C1/cm!U3',colors=cols.black,labels='d0_n4d_O2+',labpos=1.e3
  		ylim,'mvn_sta_o2+_d0_density_n_4d',.1,1000,1
    endif
    if yesd1 eq 1 then begin
      get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d1',mass=mass_o2,name='mvn_sta_o2+_d1_density_n_4d',energy=[0,40000],m_int=m_o2,mincnt=min_o2
      options,'mvn_sta_o2+_d1_density_n_4d',ytitle='sta d1 n_4d!C O2+!C!C1/cm!U3',colors=cols.black,labels='d1_n4d_O2+',labpos=1.e3
      ylim,'mvn_sta_o2+_d1_density_n_4d',.1,1000,1
    endif
    
; Calculate O+ density and characteristic energy

	mass_o = [14,20.]
	m_o = 16.
	engy_o = energy
	min_o = 0.

	get_4dt,t1=trange[0], t2=trange[1], 'ec_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_ec',energy=engy_o,m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_ec',ytitle='sta!Cc6!C<11eV!CEc!CO+!CeV',colors=cols.black & ylim,'mvn_sta_o+_c6_ec',1,30,1

	get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_cnts',energy=engy_o,m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_cnts',ytitle='sta!Cc6!C<11eV!CO+!Ccnts',colors=cols.black & ylim,'mvn_sta_o+_c6_cnts',1,1000,1
  
  ;Original code calculated O+ bkg as density. Calculate as counts below.
	;get_4dt,t1=trange[0], t2=trange[1], 'b_nbc_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_bkg',energy=engy_o,m_int=m_o,mincnt=min_o
	;	options,'mvn_sta_o+_c6_bkg',ytitle='sta!Cc6!C<11eV!CO+!Cbkg',colors=cols.cyan & ylim,'mvn_sta_o+_c6_bkg',1,10000,1
  
  get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_bkg',energy=engy_o,m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_bkg',ytitle='sta!Cc6!C<11eV!CO+!Cbkg',colors=cols.cyan & ylim,'mvn_sta_o+_c6_bkg',1,10000,1
  
	get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_all_cnts',energy=[0.,40000.],m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_all_cnts',ytitle='sta!Cc6!Call eV!CO+!Ccnts',colors=cols.black & ylim,'mvn_sta_o+_c6_all_cnts',1,1000,1

	get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_all_bkg',energy=[0.,40000.],m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_all_bkg',ytitle='sta!Cc6!Call eV!CO+!Cbkg',colors=cols.cyan & ylim,'mvn_sta_o+_c6_all_bkg',1,10000,1

	get_4dt,t1=trange[0], t2=trange[1], 'nbc_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_density2',energy=engy_o,m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_density2',ytitle='sta!Cc6!C<11eV!CO+!C1/cm!U3',colors=cols.black,labels='c6_O+',labpos=1.e3
		ylim,'mvn_sta_o+_c6_density2',100,100000,1

	get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_c6',mass=mass_o,name='mvn_sta_o+_c6_density_all',energy=[0,40000],m_int=m_o,mincnt=min_o
		options,'mvn_sta_o+_c6_density_all',ytitle='sta c6 all!C O+!C!C1/cm!U3',colors=cols.cyan,labels='c6_O+',labpos=1.e3
		ylim,'mvn_sta_o+_c6_density_all',.1,1000,1

  ;Calculate O+ using n_4d, d0 and d1 data:
  if yesd0 eq 1 then begin
      get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d0',mass=mass_o,name='mvn_sta_o+_d0_density_n_4d',energy=[0,40000],m_int=m_o,mincnt=min_o
    		options,'mvn_sta_o+_d0_density_n_4d',ytitle='sta d0 n_4d!C O+!C!C1/cm!U3',colors=cols.cyan,labels='d0_n4d_O+',labpos=1.e3
    		ylim,'mvn_sta_o+_d0_density_n_4d',.1,1000,1
  endif
  if yesd1 eq 1 then begin
      get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d1',mass=mass_o,name='mvn_sta_o+_d1_density_n_4d',energy=[0,40000],m_int=m_o,mincnt=min_o
      options,'mvn_sta_o+_d1_density_n_4d',ytitle='sta d1 n_4d!C O+!C!C1/cm!U3',colors=cols.cyan,labels='d1_n4d_O+',labpos=1.e3
      ylim,'mvn_sta_o+_d1_density_n_4d',.1,1000,1
  endif

;	get_4dt,t1=trange[0], t2=trange[1], 'nc_4d','mvn_sta_get_c6b',mass=mass_o,name='mvn_sta_o+_c6_density3',energy=engy_o,m_int=m_o,mincnt=min_o
;		options,'mvn_sta_o+_c6_density3',ytitle='sta c6 <11eV!C O+!C!C1/cm!U3',colors=cols.green
;		ylim,'mvn_sta_o+_c6_density3',100,100000,1

	get_data,'mvn_sta_o+_c6_density2',data=tmp16
	get_data,'mvn_sta_o2+_c6_density2',data=tmp32

; the following is needed if background has not been added to the c6 structure
	tr=timerange()
	dat=mvn_sta_get_c6(total(tr)/2.) 
	if total(dat.bkg) eq 0 then begin
	  ;This loop should never happen now - but leave in here just in case: -> CMF edit: this can happen if nobkg=1
;		store_data,'mvn_sta_o+_c6_density2_corr',data={x:tmp16.x,y:tmp16.y-tmp32.y/100.}		; works better 20151125
		store_data,'mvn_sta_o+_c6_density2_corr',data={x:tmp16.x,y:tmp16.y-tmp32.y/50.}			; works better 20160529
		store_data,'mvn_sta_o+_c6_bkg',data={x:tmp16.x,y:tmp32.y/50.}
	endif else begin
		store_data,'mvn_sta_o+_c6_density2_corr',data={x:tmp16.x,y:tmp16.y}			; works better 20160529
	endelse
		ylim,'mvn_sta_o+_c6_density2_corr',.1,100000,1
		options,'mvn_sta_o+_c6_density2_corr',ytitle='sta c6 <11eV!CO+!C!C1/cm!U3',colors=cols.cyan,thick=1.5

	get_data,'mvn_sta_c6_att',data=tmp0
	get_data,'mvn_sta_kk3',data=tmp1
	kk3_full = tmp1.y[0,tmp0.y]
	get_data,'mvn_sta_o+_c6_ec',data=tmp2
	get_data,'mvn_sta_o+_c6_cnts',data=tmp3
	get_data,'mvn_sta_o+_c6_bkg',data=tmp4
	get_data,'mvn_sta_c6_scpot',data=tmp5
	; kk3_full/1.3 is a bit arbitray - should be determined emperically 
;	store_data,'mvn_sta_o+_c6_nbc_den_qf',data={x:tmp3.x,y:(tmp2.y gt kk3_full/1.3) and ((tmp3.y-tmp4.y) ge 10.) and ((tmp3.y-tmp4.y) ge tmp4.y^.5)} 
	store_data,'mvn_sta_o+_c6_nbc_den_qf',data={x:tmp3.x,y:(((1.4-tmp5.y) gt kk3_full/1.2) or (tmp2.y gt kk3_full*1.3)) and ((tmp3.y-tmp4.y) ge 40.) and ((tmp3.y-tmp4.y) ge 3.*tmp4.y^.5)} 
	store_data,'mvn_sta_o+_c6_nbc_den_qf',data={x:tmp3.x,y:(((1.4-tmp5.y) gt kk3_full/1.2) or (tmp2.y gt kk3_full*1.3)) and ((tmp3.y-tmp4.y) ge 30.+2.*tmp4.y^.5) } 
		ylim,'mvn_sta_o+_c6_nbc_den_qf',-1,2,0

; Calculate CO2+ density 

	mass_co2 = [40,60.]
	m_co2 = 44.
	engy_co2 = energy
	min_co2 = 10.

	get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6_co2',mass=mass_co2,name='mvn_sta_co2+_c6_cnts',energy=engy_co2,m_int=m_co2
		options,'mvn_sta_co2+_c6_cnts',ytitle='c6 <11eV!C!CCO2+!C!Ccounts',ylog=1,yrange=[10,1.e3],color=cols.black,labels='c6_CO2+',labpos=100.

	get_4dt,t1=trange[0], t2=trange[1], 'nbc_4d','mvn_sta_get_c6_co2',mass=mass_co2,name='mvn_sta_c6_den_co2',energy=engy_co2,m_int=m_co2,mincnt=min_co2
		options,'mvn_sta_c6_den_co2',ytitle='c6 <11eV!C!CCO2+!C!Ccm!U-3',ylog=1,yrange=[1000,2.e4],color=cols.black,labels='c6_CO2+',labpos=3.e3
	
	get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6_co2',mass=mass_co2,name='mvn_sta_co2+_c6_bkg',energy=engy_co2,m_int=m_co2,mincnt=min_co2
		options,'mvn_sta_co2+_c6_bkg',ytitle='sta!Cc6!C<11eV!CCO2+!Cbkg',colors=cols.black & ylim,'mvn_sta_co2+_c6_bkg',1,10000,1

	get_4dt,t1=trange[0], t2=trange[1], 'nbc_4d','mvn_sta_get_c6_co2_avg',mass=mass_co2,name='mvn_sta_c6_den_co2_avg',energy=engy_co2,m_int=m_co2,mincnt=min_co2
		options,'mvn_sta_c6_den_co2_avg',ytitle='c6 <11eV!C!CCO2+!C!Ccm!U-3',ylog=1,yrange=[1000,2.e4],color=cols.black,labels='c6_CO2+',labpos=3.e3

	get_4dt,t1=trange[0], t2=trange[1], 'vb_4d','mvn_sta_get_c6_co2_avg',mass=mass_co2,name='mvn_sta_c6_vb_co2_avg',energy=engy_co2,m_int=m_co2
		options,'mvn_sta_c6_vb_co2_avg',ytitle='c6_avg <11eV!C!CCO2+!C!Cvb',ylog=1,yrange=[3.4,4.6],color=cols.black,labels='c6_CO2+',labpos=4.
    
	get_data,'mvn_sta_c6_den_co2',data=tmp
	store_data,'mvn_sta_c6_den_co2_red',data=tmp
		options,'mvn_sta_c6_den_co2_red',colors=cols.red,ytitle='c6 <11eV!C!CCO2+!C!Ccm!U-3',ylog=1,yrange=[1000,2.e4],labels='c6_CO2+',labpos=3.e3

	get_data,'mvn_sta_c6_den_co2_avg',data=tmp
	store_data,'mvn_sta_c6_den_co2_avg_red',data=tmp
		options,'mvn_sta_c6_den_co2_avg_red',colors=cols.red,ytitle='c6!C!CCO2+!C!Ccm!U-3',ylog=1,yrange=[1000,2.e4],labels='c6_CO2+',labpos=3.e3
  
  ;Calculate using n_4d (for eg pick up ions): this does poorly at periapsis because of the O2+ tail that swamps the CO2+ signal most times.
  if yesd0 eq 1 then begin
    get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d0',mass=mass_co2,name='mvn_sta_co2+_d0_density_n_4d',energy=[0., 40000.],m_int=m_co2
      options,'mvn_sta_co2+_d0_density_n_4d',ytitle='sta d0 n_4d!C CO2+!C!C1/cm!U3',ylog=1,yrange=[10,1.e3],color=cols.black,labels='c6_CO2+_n_4d',labpos=100.
  endif
  if yesd1 eq 1 then begin
    get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d1',mass=mass_co2,name='mvn_sta_co2+_d1_density_n_4d',energy=[0., 40000.],m_int=m_co2
    options,'mvn_sta_co2+_d1_density_n_4d',ytitle='sta d1 n_4d!C CO2+!C!C1/cm!U3',ylog=1,yrange=[10,1.e3],color=cols.black,labels='c6_CO2+_n_4d',labpos=100.
  endif
  
  
  ;Currently, there is no n_4d on c6 data to get STATIC density. Not sure this will ever happen - the removal of O2+ stragglers is
  ;anode dependent and this has not been characterized as of 2021-11-16, and I'm not sure it could be done for c6 data.
  
;***********************************************************************************************
;***********************************************************************************************

; Calculate solar wind proton and alpha density 

	mass_p = [0,1.55]
	m_p = 1.
	engy_p = [0.0,40000]
	min_p = 0.

	get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_c6',mass=mass_p,name='mvn_sta_c6_den_p',energy=engy_p,m_int=m_p,mincnt=min_p
		options,'mvn_sta_c6_den_p',ytitle='c6!C!CH+!C!Ccm!U-3',ylog=1,yrange=[.1,100],color=cols.black,labels='c6_p',labpos=3.e0
  
  get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6',mass=mass_p,name='mvn_sta_h+_c6_all_cnts',energy=[0.,40000.],m_int=m_p,mincnt=min_p
		options,'mvn_sta_h+_c6_all_cnts',ytitle='sta!Cc6!Call eV!CH+!Ccnts',colors=cols.black & ylim,'mvn_sta_h+_c6_all_cnts',1,10000,1

  get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6',mass=mass_p,name='mvn_sta_h+_c6_all_bkg',energy=[0.,40000.],m_int=m_p,mincnt=min_p
		options,'mvn_sta_h+_c6_all_bkg',ytitle='sta!Cc6!Call eV!CH+!Cbkg',colors=cols.black & ylim,'mvn_sta_h+_c6_all_bkg',1,10000,1
		 
  if yesd0 eq 1 then begin
  get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d0',mass=mass_p,name='mvn_sta_d0_den_p',energy=engy_p,m_int=m_p,mincnt=min_p
		options,'mvn_sta_d0_den_p',ytitle='d0!C!CH+!C!Ccm!U-3',ylog=1,yrange=[.1,100],color=cols.black,labels='d0_p',labpos=3.e0
  endif
  if yesd1 eq 1 then begin
    get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d1',mass=mass_p,name='mvn_sta_d1_den_p',energy=engy_p,m_int=m_p,mincnt=min_p
    options,'mvn_sta_d1_den_p',ytitle='d1!C!CH+!C!Ccm!U-3',ylog=1,yrange=[.1,100],color=cols.black,labels='d1_p',labpos=3.e0
  endif
  
	mass_a = [1.55,2.7]
	m_a = 2.
	engy_a = [0.0,40000]
	min_a = 0.

	get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_c6',mass=mass_a,name='mvn_sta_c6_den_a',energy=engy_a,m_int=m_a,mincnt=min_a
		options,'mvn_sta_c6_den_a',ytitle='c6!C!CHe++!C!Ccm!U-3',ylog=1,yrange=[.1,100],color=cols.red,labels='c6_a',labpos=1.e0
  
  get_4dt,t1=trange[0], t2=trange[1], 'c_4d','mvn_sta_get_c6',mass=mass_a,name='mvn_sta_he++_c6_all_cnts',energy=[0.,40000.],m_int=m_a,mincnt=min_a
		options,'mvn_sta_he++_c6_all_cnts',ytitle='sta!Cc6!Call eV!CHe++!Ccnts',colors=cols.black & ylim,'mvn_sta_h++_c6_all_cnts',1,10000,1

	get_4dt,t1=trange[0], t2=trange[1], 'b_4d','mvn_sta_get_c6',mass=mass_a,name='mvn_sta_he++_c6_all_bkg',energy=[0.,40000.],m_int=m_a,mincnt=min_a
		options,'mvn_sta_he++_c6_all_bkg',ytitle='sta!Cc6!Call eV!CHe++!Cbkg',colors=cols.black & ylim,'mvn_sta_h++_c6_all_bkg',1,10000,1

  if yesd0 eq 1 then begin
		  get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d0',mass=mass_a,name='mvn_sta_d0_den_a',energy=engy_a,m_int=m_a,mincnt=min_a
		  options,'mvn_sta_d0_den_a',ytitle='d0!C!CHe++!C!Ccm!U-3',ylog=1,yrange=[.1,100],color=cols.red,labels='d0_a',labpos=1.e0
		endif 
  if yesd1 eq 1 then begin
  	get_4dt,t1=trange[0], t2=trange[1], 'n_4d','mvn_sta_get_d1',mass=mass_a,name='mvn_sta_d1_den_a',energy=engy_a,m_int=m_a,mincnt=min_a
  		options,'mvn_sta_d1_den_a',ytitle='d1!C!CHe++!C!Ccm!U-3',ylog=1,yrange=[.1,100],color=cols.red,labels='d1_a',labpos=1.e0
  endif
  
  ;Multi tplot comparison variables are used for testing, but not needed for processing, so remove here. Note the d0d1_str variable won't work now either.
	if 'y' eq 'n' then begin
    	store_data,'mvn_sta_c6_den_sw',data=['mvn_sta_c6_den_p','mvn_sta_c6_den_a']
        	options,'mvn_sta_c6_den_sw',ytitle='c6!C!Csw!C!Ccm!U-3',ylog=1,yrange=[.01,100]
        	options, 'mvn_sta_c6_den_sw', colors=[cols.black, cols.red]
    
      ;Compare c6 and d1 results:
      options, 'mvn_sta_'+d0d1_str+'_den_p', color=cols.brown
      options, 'mvn_sta_'+d0d1_str+'_den_a', color=cols.purple
      
      ;Add SWIA density moment:
      options, 'mvn_swim_density', color=cols.green
      store_data, 'mvn_sta_c6_'+d0d1_str+'_sw_compare', data=['mvn_sta_c6_den_p', 'mvn_sta_'+d0d1_str+'_den_p', 'mvn_sta_c6_den_a', 'mvn_sta_'+d0d1_str+'_den_a', 'mvn_swim_density']
        ylim, 'mvn_sta_c6_'+d0d1_str+'_sw_compare', 1E-2, 100.
        options, 'mvn_sta_c6_'+d0d1_str+'_sw_compare', colors=[cols.black, cols.brown, cols.red, cols.purple, cols.green]
        options, 'mvn_sta_c6_'+d0d1_str+'_sw_compare', labels=['STA c6 p', 'STA '+d0d1_str+' p', 'STA c6 a', 'STA '+d0d1_str+' a', 'SWI a+p']
        options, 'mvn_sta_c6_'+d0d1_str+'_sw_compare', labflag=1
  endif
  
;	tplot,/add,'mvn_sta_c6_den_sw'
	
;***********************************************************************************************
;***********************************************************************************************
;More multi tplot variables used for testing, but not needed for processing:
if 'y' eq 'n' then begin
    	store_data,'mvn_sta_c6_o_o2_co2_density',data=['mvn_sta_o+_c6_density2', 'mvn_sta_o2+_c6_density2','mvn_sta_c6_den_co2']
    		options,'mvn_sta_c6_o_o2_co2_density',ytitle='sta c6 <11eV!C!CO+ O2+ CO2+!C!C1/cm!U3',panel_size=2
    		ylim,'mvn_sta_c6_o_o2_co2_density',10,1.e5,1
    
    	store_data,'mvn_sta_c6_density_all_compare',data=['mvn_sta_c6_den_p','mvn_sta_c6_den_a','mvn_sta_o+_c6_density_all','mvn_sta_o2+_c6_density_all']
    		options,'mvn_sta_c6_density_all_compare',ytitle='sta c6 all!C!C1/cm!U3',panel_size=2
    		ylim,'mvn_sta_c6_density_all_compare',1,1.e3,1
    
      ;===========
      ;Store STATIC mode and att states into one variable:
      options, 'mvn_sta_c6_att', color=cols.red
      store_data, 'mvn_sta_att_mode', data=['mvn_sta_c6_mode', 'mvn_sta_c6_att']
        options, 'mvn_sta_att_mode', colors=[cols.black, cols.red]
        options, 'mvn_sta_att_mode', labels=['Mode', 'Att']
        options, 'mvn_sta_att_mode', labflag=1
        ylim, 'mvn_sta_att_mode', 0, 8
      
      ;Overplot SWIA moments with STATIC SW:
      options, 'mvn_swim_density', color=cols.green
      store_data, 'mvn_sta_swi_sw', data=['mvn_sta_c6_den_p', 'mvn_sta_c6_den_a', 'mvn_swim_density']
        options, 'mvn_sta_swi_sw', colors=[cols.black, cols.red, cols.green]
        options, 'mvn_sta_swi_sw', labels=['STA p', 'STA a', 'SWI a+p']
        options, 'mvn_sta_swi_sw', labflag=1
        ylim, 'mvn_sta_swi_sw', 1E-2, 50.

endif

;Update line plot colors:
options, 'mvn_sta_o+_c6_density2', color=cols.black
options, 'mvn_sta_o2+_c6_density2', color=cols.blue
options, 'mvn_sta_c6_den_co2', color=cols.green 
options, 'mvn_sta_c6_o_o2_co2_density', colors=[cols.black, cols.blue, cols.green]
options, 'mvn_sta_c6_o_o2_co2_density', labels=['c6_O+', 'c6_O2+', 'c6_CO2+']
options, 'mvn_sta_c6_o_o2_co2_density', labflag=1

success=1

print, proname, ': success.'

end