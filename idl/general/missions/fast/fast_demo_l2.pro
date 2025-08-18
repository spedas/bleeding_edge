; FAST crib for loading and plotting FAST esa data using level 2 CDFs
; Just copy this file and paste it into IDL for a quick demo of FAST software
; For loading EES, IES, EEB, IEB, use		fa_load_esa_l2.pro
;***********************************************************************************************************
; select an orbit number or orbit range or time range

fa_orbitrange,2371
;fa_orbitrange,1801
;fa_orbitrange,2301
;fa_orbitrange,2001
;fa_orbitrange,[1801,1802]
;fa_orbitrange,[1801,1804]
;trange=timerange(['97-02-21/3:00','97-02-21/7:00']) & dt=trange[1]-trange[0] & timespan,trange[0],dt,/seconds
;***********************************************************************************************************
; I find the following helpful, but not necessary

!y.margin=[4,4]		; default is [4,2]
!x.margin=[10,5]	; default is [10,3]

;***********************************************************************************************************
; initialize software

fa_init
loadct2,43
cols=get_colors()
window,0,xsize=1000,ysize=1000

;***********************************************************************************************************
; initialize the time range and orbit numbers if not already set

trange=timerange()
print,time_string(trange)
orbits=fa_time_to_orbit(trange)
print,orbits
if orbits[0] eq orbits[1] then orbit = string(orbits[0]) else orbit=string(orbits[0])+'-'+string(orbits[1])
fa_k0_load,'orb'

;***********************************************************************************************************
; load eesa and iesa survey data

fa_esa_load_l2,datatype=['ees','ies'],/tplot

; helpful options for plotting
options,'fa_ees_l2_en_quick',datagap=5.
options,'fa_ies_l2_en_quick',datagap=5.

; plot the eflux data
tplot,['fa_ees_l2_en_quick','fa_ies_l2_en_quick'],title='FAST Orbit= '+orbit,var_label=['alt','ilat','mlt']
wait,5
wait,5
;*************************************************************************************
; load eesa and iesa burst data

fa_esa_load_l2,datatype=['eeb','ieb'],/tplot

; helpful options for plotting
options,'fa_eeb_l2_en_quick',datagap=0.1
options,'fa_ieb_l2_en_quick',datagap=0.1

tplot,['fa_ees_l2_en_quick','fa_ies_l2_en_quick','fa_eeb_l2_en_quick','fa_ieb_l2_en_quick'],title='FAST Orbit= '+orbit,var_label=['alt','ilat','mlt']

wait,5
;*************************************************************************************
; plot eesa survey data (select a time with the cursor)

dat=get_fa2_ees()
window,1 & spec2d,dat,/label
window,2 & pitch2d,dat,/label
window,4 & contour2d,dat

wait,5
;*************************************************************************************
; plot iesa survey data (select a time with the cursor)

dat=get_fa2_ies()
window,1 & spec2d,dat,/label
window,2 & pitch2d,dat,/label
window,4 & contour2d,dat

wait,5
;*************************************************************************************
; generate some calibrated energy flux versus time spectrograms of eesa and iesa survey data

  bkg=0
  gap_time=5.

  get_dat='get_fa2_ees'
  name1='fa_ees_en_spec'
  get_en_spec,get_dat,units='eflux',name=name1,gap_time=gap_time,bkg=bkg
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  name1='fa_ees_en_spec'
         zlim,name1,1.e5,1.e9,1
         ylim,name1,5.,30000.,1
         options,name1,'ztitle','Eflux !C!C eV/cm!U2!N-s-sr-eV'
         options,name1,'ytitle','e-!C!C Energy (eV)'
         options,name1,'spec',1
         options,name1,'x_no_interp',1
         options,name1,'y_no_interp',1
tplot,'fa_ees_en_spec'

  name1='fa_ees_pa_spec'
  get_dat='fa2_ees'
  get_pa_spec,get_dat,units='eflux',name=name1,energy=[100,30000]
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  name1='fa_ees_pa_spec'
         zlim,name1,1.e5,1.e9,1
         ylim,name1,-10.,370.,0
         options,name1,'ztitle','Eflux !C!C eV/cm!U2!N-s-sr-eV'
         options,name1,'ytitle','e- '+'!C!C pitch angle'
         options,name1,'spec',1
         options,name1,'x_no_interp',1
         options,name1,'y_no_interp',1
tplot,['fa_ees_en_spec','fa_ees_pa_spec']

  name1='fa_ies_en_spec'
  get_dat='fa2_ies'
  get_en_spec,get_dat,units='eflux',name=name1,gap_time=gap_time,bkg=bkg
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  name1='fa_ies_en_spec'
         zlim,name1,1.e4,1.e8,1
         ylim,name1,5.,30000.,1
         options,name1,'ztitle','Eflux !C!C eV/cm!U2!N-s-sr-eV'
         options,name1,'ytitle','i+!C!C Energy (eV)'
         options,name1,'spec',1
         options,name1,'x_no_interp',1
         options,name1,'y_no_interp',1
tplot,['fa_ees_en_spec','fa_ees_pa_spec','fa_ies_en_spec']

  name1='fa_ies_pa_spec'
  get_dat='fa2_ies'
  get_pa_spec,get_dat,units='eflux',name=name1,energy=[50,30000]
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  name1='fa_ies_pa_spec'
         zlim,name1,1.e4,1.e8,1
         ylim,name1,-10.,370.,0
         options,name1,'ztitle','Eflux !C!C eV/cm!U2!N-s-sr-eV'
         options,name1,'ytitle','i+ '+'!C!C pitch angle'
         options,name1,'spec',1
         options,name1,'x_no_interp',1
         options,name1,'y_no_interp',1
tplot,['fa_ees_en_spec','fa_ees_pa_spec','fa_ies_en_spec','fa_ies_pa_spec']

wait,5
;*************************************************************************************
; generate some line plots of electron flux and energy flux

name1='Je_s'
get_dat='fa2_ees'
get_2dt,'j_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Je_s'
	ylim,name1,1.e6,1.e10,1
	options,name1,'ytitle','Je !C!C1/cm!U2!N-s'
	options,name1,'tplot_routine','pmplot'



name1='JEe_s'
get_dat='fa2_ees'
get_2dt,'je_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='JEe_s'
	ylim,name1,.001,10.,1
	options,name1,'ytitle','JEe !C!Cergs/cm!U2!N-s'
	options,name1,'tplot_routine','pmplot'


name1='Ji_s'
get_dat='fa2_ies'
get_2dt,'j_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='Ji_s'
	ylim,name1,1.e4,1.e8,1
	options,name1,'ytitle','Ji !C!C1/cm!U2!N-s'
	options,name1,'tplot_routine','pmplot'


name1='JEi_s'
get_dat='fa2_ies'
get_2dt,'je_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
name1='JEi_s'
	ylim,name1,.001,1,1
	options,name1,'ytitle','JEi !C!Cergs/cm!U2!N-s'
	options,name1,'tplot_routine','pmplot'

tplot,['fa_ees_en_spec','fa_ees_pa_spec','fa_ies_en_spec','fa_ies_pa_spec','JEe_s','Je_s','JEi_s','Ji_s']

wait,5
;*************************************************************************************
; Other useful functions to understand

;tlimit
;ctime
;get_data
;store_data
;makepng
;plot_fa_crossing,orbit=1800



End
