;+
; Name: thm_crib_sst_load_calibrate
;
; Purpose:  Demonstrate usage of thm_sst_load_calibrate
;
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-02-25 13:10:28 -0800 (Wed, 25 Feb 2015) $
; $LastChangedRevision: 17040 $
; $URL $
;-


;--------------------------------------------------------------------------------------------------------------------------------------
;basic call
;--------------------------------------------------------------------------------------------------------------------------------------
;
trange=['2011-07-29/13:00:00','2011-07-29/14:00:00']
timespan,trange
;thm_sst_load_calibrate loads the data automatically.  Calling thm_load_esa_pkt, thm_load_sst, is not necessary
;sun contamination is automatically removed by default using the manual method with a default bin selection based on analysis by Jim Mctiernan
thm_sst_load_calibrate,probe='d',datatype='psif',trange=trange,dist_data=dist_psif
thm_part_moments,inst='psif',probe='d',dist_array=dist_psif
thm_part_getspec,data_type='psif',probe='d',dist_array=dist_psif,angle='phi'
  
;Note the gaps/discolorations at the left & right edges of the time series
;  these are regions where ESA data is missing because of time clipping and 
;  low time resolution can be mitigated by using the esa_datatype keyword to
;  select higher time resolution data(psir, example below),using longer time
;  periods, or time clipping after processing
tplot,['thd_psif_an_eflux_phi','thd_psif_en_eflux']
stop
  
;--------------------------------------------------------------------------------------------------------------------------------------
;manually select contamination bins
;--------------------------------------------------------------------------------------------------------------------------------------

trange=['2011-07-29/13:00:00','2011-07-29/14:00:00']
timespan,trange
;sun_bins = [0,8,16,24,32,33,40,47,48,55,56,57]  ;this is the default 
;sun_bins = -1 ; use this to disable sun decontamination 

sun_bins = [0,8,16,24,32,33,40,47,48,49,54,55,56,57] ;mask some extra bins(49,54)

thm_sst_load_calibrate,probe='d',datatype='psif',trange=trange,dist_data=dist_psif,sun_bins=sun_bins
thm_part_moments,inst='psif',probe='d',dist_array=dist_psif
thm_part_getspec,data_type='psif',probe='d',dist_array=dist_psif,angle='phi'

tplot,['thd_psif_an_eflux_phi','thd_psif_en_eflux']
stop

;---------------------------------------------------------------------------------------------------------------------------------------
;manually select output energies for SST
;---------------------------------------------------------------------------------------------------------------------------------------
;
trange=['2011-07-29/13:00:00','2011-07-29/14:00:00']
timespan,trange

;Since SST must be interpolated across energy to match detector dead layers, it is possible to select different target energies from
;default binning output by the spacecraft. This can also be used to adjust the number of energies interpolated into the energy gap
;between ESA and SST
;
;
;energies = [25000.,26000.,28000.,34000.0,41000.0,53000.0,67400.0,95400.0,142600.,207400.,297000.,421800.,654600.,1.13460e+06,2.32980e+06,4.00500e+06] ;the default values in eV for ions
;energies = [27000,28000.,29000.,30000.0, 31000.0,41000.0,52000.0,65500.0,93000.0,139000.,203500.,293000.,408000.,561500.,719500.] ;the default value iin eV for electrons

energies =  [25000.,26000.,27000.,28000.,29000.,34000.0,41000.0,53000.0,67400.0,95400.0,142600.,207400.,297000.,421800.,654600.,1.13460e+06,2.32980e+06,4.00500e+06] ;add some extra energies in the gap(27,29 keV)
thm_sst_load_calibrate,probe='d',datatype='psif',trange=trange,dist_data=dist_psif,energies=energies
thm_part_moments,inst='psif',probe='d',dist_array=dist_psif
thm_part_getspec,data_type='psif',probe='d',dist_array=dist_psif,angle='phi'

tplot,['thd_psif_an_eflux_phi','thd_psif_en_eflux']
stop

;---------------------------------------------------------------------------------------------------------------------------------------
;select esa_datatype and get ESA data used to calibrate SST
;---------------------------------------------------------------------------------------------------------------------------------------

;first we cleanup, not necessary, but good practice
del_data,'*'
heap_gc

;Can return a copy of the ESA data that was used to calibrate SST.
;This can be helpful for generating combined ESA/SST moments and energy spectra since the data are already interpolated onto the same time grid

probe='d'
species = 'i'
sst_datatype = 'ps'+species+'f'
esa_datatype = 'pe'+species+'r'
comb_datatype = 'pc'+species+'x'
trange=['2012-07-29/12:00:00','2012-07-29/13:00:00']
timespan,trange

thm_sst_load_calibrate,probe=probe,datatype=sst_datatype,esa_datatype=esa_datatype,trange=trange,dist_data=dist_sst,dist_esa=dist_esa
thm_part_moments,inst=sst_datatype,probe=probe,dist_array=dist_sst
thm_part_moments,inst=esa_datatype,probe=probe,dist_array=dist_esa


;generate combined eflux
;coming soon: this process automated

;get spectral data
get_data,'th'+probe+'_'+sst_datatype+'_en_eflux',data=sst_en_eflux
get_data,'th'+probe+'_'+esa_datatype+'_en_eflux',data=esa_en_eflux

;concatenate into new variable, reverse order of esa energy channels to match SST, remove ESA retrace bin
store_data,'th'+probe+'_'+comb_datatype+'_en_eflux',data={x:sst_en_eflux.x,y:[[reverse(esa_en_eflux.y[*,1:*],2)],[sst_en_eflux.y]],v:[[reverse(esa_en_eflux.v[*,1:*],2)],[sst_en_eflux.v]]}

;set plotting options, ystyle=1 forces the displayed range to match requested, instead of drawing to nearest even tick
options,'th'+probe+'_'+comb_datatype+'_en_eflux',yrange=[7,4e6],zrange=[1e2,1e8],ystyle=1,spec=1,ylog=1,zlog=1
options,'th'+probe+'_'+comb_datatype+'_en_eflux',ytitle='eV',ztitle='eV/(sec*cm2*sr*eV)'

;set some global potting options
tplot_options,'xmargin',[13,8]
tplot_options,'charsize',1.2
tplot_options,'title','Combined Eflux '+ strupcase(species)

tplot,'th'+probe+'_'+comb_datatype+'_en_eflux'
stop

; and generate combined moments
;total density
calc," 'th?_pc?x_density' = 'th?_ps?f_density' + 'th?_pe?r_density' "
;Quick tip: If the data are not time interpolated, just pass /interp keyword to calc and it will interpolate automatically
ident=[1,1,1]
;total velocity
calc,"'th?_pc?x_velocity'= ('th?_ps?f_velocity'*('th?_ps?f_density'#ident)+'th?_pe?r_velocity'*('th?_pe?r_density'#ident))/('th?_pc?x_density'#ident)"

options,'th?_pc?x_velocity',yrange=[-100,100]
options, 'th?_pc?x_velocity', labels = ['Vx', 'Vy', 'Vz']
options, 'th?_pc?x_velocity', labflag = 1

thm_load_state,probe=probe,trange=trange,/get_support
thm_cotrans, 'th?_pc?x_velocity', out_suffix='_gsm', out_coord='gsm'

;total pressure (ESA)
calc,"'th?_pe?r_press'= total('th?_pe?r_t3'*('th?_pe?r_density'#ident),2)/3."

;total pressure (SST)
calc,"'th?_ps?f_press'= total('th?_ps?f_t3'*('th?_ps?f_density'#ident),2)/3."

eVpercc_to_nPa=0.1602/1000.    ; multiply

;total pressure(for species)
calc," 'th?_pc?x_press' = eVpercc_to_nPa * ('th?_ps?f_press' + 'th?_pe?r_press') " ; in nPa

tplot_options,'title','Combined Moments '+ strupcase(species)

tplot,'th?_pc?x_press th?_pc?x_velocity_gsm th?_pc?x_density'

stop


end