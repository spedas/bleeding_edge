Pro fa_esa_l1l2comp, orbit, burst = burst

  If(keyword_set(burst)) Then Begin
     types = ['eeb', 'ieb']
     ext = 'eb'
  Endif Else Begin
     types = ['ees', 'ies']
     ext = 'es'
  Endelse

;first test counts-counts comparison
  fa_orbitrange, orbit
  fa_load_esa_l1, datatype=types, /tplot
  fa_esa_load_l2, orbit = orbit, datatype=types
  fa_esa_l2_tplot, /counts

  get_data,'fa_e'+ext+'_l2_ct_quick', data = el2c
  get_data,'fa_e'+ext+'_l1_en_quick', data = el1c
  get_data,'fa_i'+ext+'_l2_ct_quick', data = dl2c
  get_data,'fa_i'+ext+'_l1_en_quick', data = dl1c

;energy spectra and pitch angle spectra?
;L1 from fast_demo.crib
  bkg=0
  gap_time=5.

  get_dat='get_fa1_e'+ext
  name1='fa_e'+ext+'_en_spec'
  get_en_spec,get_dat,units='eflux',name=name1,gap_time=gap_time,bkg=bkg
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e5,1.e9,1
  ylim,name1,5.,30000.,1
  options,name1,'ztitle','L1 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','e-!C!C Energy (eV)'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

  get_dat='get_fa1_i'+ext
  name1='fa_i'+ext+'_en_spec'
  get_en_spec,get_dat,units='eflux',name=name1,gap_time=gap_time,bkg=bkg
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e4,1.e8,1
  ylim,name1,5.,30000.,1
  options,name1,'ztitle','L1 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','i+!C!C Energy (eV)'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

;pitch angles
  name1='fa_e'+ext+'_pa_spec'
  get_dat='get_fa1_e'+ext
  get_pa_spec,get_dat,units='eflux',name=name1,energy=[100,30000]
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e5,1.e9,1
  ylim,name1,-10.,370.,0
  options,name1,'ztitle','L1 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','e- '+'!C!C pitch angle'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

  name1='fa_i'+ext+'_pa_spec'
  get_dat='get_fa1_i'+ext
  get_pa_spec,get_dat,units='eflux',name=name1,energy=[100,30000]
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e4,1.e8,1
  ylim,name1,-10.,370.,0
  options,name1,'ztitle','L1 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','i+ '+'!C!C pitch angle'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

;do using L2
  get_dat='get_fa2_e'+ext
  name1='fa_e'+ext+'_en_spec_l2'
  get_en_spec,get_dat,units='eflux',name=name1,gap_time=gap_time,bkg=bkg
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e5,1.e9,1
  ylim,name1,5.,30000.,1
  options,name1,'ztitle','L2 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','e-!C!C Energy (eV)'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

  get_dat='get_fa2_i'+ext
  name1='fa_i'+ext+'_en_spec_l2'
  get_en_spec,get_dat,units='eflux',name=name1,gap_time=gap_time,bkg=bkg
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e4,1.e8,1
  ylim,name1,5.,30000.,1
  options,name1,'ztitle','L2 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','i+!C!C Energy (eV)'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

;pitch angles
  name1='fa_e'+ext+'_pa_spec_l2'
  get_dat='get_fa2_e'+ext
  get_pa_spec,get_dat,units='eflux',name=name1,energy=[100,30000]
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e5,1.e9,1
  ylim,name1,-10.,370.,0
  options,name1,'ztitle','L2 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','e- '+'!C!C pitch angle'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

  name1='fa_i'+ext+'_pa_spec_l2'
  get_dat='get_fa2_i'+ext
  get_pa_spec,get_dat,units='eflux',name=name1,energy=[100,30000]
  get_data,name1,data=tmp
  tmp.y=tmp.y>1.e-10
  store_data,name1,data=tmp
  zlim,name1,1.e4,1.e8,1
  ylim,name1,-10.,370.,0
  options,name1,'ztitle','L2 Eflux !C!C eV/cm!U2!N-s-sr-eV'
  options,name1,'ytitle','i+ '+'!C!C pitch angle'
  options,name1,'spec',1
  options,name1,'x_no_interp',1
  options,name1,'y_no_interp',1

;*************************************************************************************
; generate some line plots of electron flux and energy flux
  name1='Je_s'
  get_dat='fa1_e'+ext
  get_2dt,'j_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  name1='Je_s'
  ylim,name1,1.e6,1.e10,1
  options,name1,'ytitle','L1 Je !C!C1/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='JEe_s'
  get_dat='fa1_e'+ext
  get_2dt,'je_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  name1='JEe_s'
  ylim,name1,.001,10.,1
  options,name1,'ytitle','L1 JEe !C!Cergs/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='Ji_s'
  get_dat='fa1_i'+ext
  get_2dt,'j_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  name1='Ji_s'
  ylim,name1,1.e4,1.e8,1
  options,name1,'ytitle','L1 Ji !C!C1/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='JEi_s'
  get_dat='fa1_i'+ext
  get_2dt,'je_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  name1='JEi_s'
  ylim,name1,.001,1,1
  options,name1,'ytitle','L1 JEi !C!Cergs/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='Je_s_l2'
  get_dat='fa2_e'+ext
  get_2dt,'j_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  ylim,name1,1.e6,1.e10,1
  options,name1,'ytitle','L2 Je !C!C1/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='JEe_s_l2'
  get_dat='fa2_e'+ext
  get_2dt,'je_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  ylim,name1,.001,10.,1
  options,name1,'ytitle','L2 JEe !C!Cergs/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='Ji_s_l2'
  get_dat='fa2_i'+ext
  get_2dt,'j_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  ylim,name1,1.e4,1.e8,1
  options,name1,'ytitle','L2 Ji !C!C1/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  name1='JEi_s_l2'
  get_dat='fa2_i'+ext
  get_2dt,'je_2d_new',get_dat,name=name1,gap_time=gap_time,energy=[25.,33000.]
  ylim,name1,.001,1,1
  options,name1,'ytitle','L2 JEi !C!Cergs/cm!U2!N-s'
  options,name1,'tplot_routine','pmplot'

  print, 'Min and max differences for Electrons counts'
  print, minmax(el2c.y-el1c.y)
  print, 'Min and max differences for ions counts'
  print, minmax(dl2c.y-dl1c.y)

  get_data, 'fa_e'+ext+'_en_spec', data = el1
  get_data, 'fa_e'+ext+'_en_spec_l2', data = el2
  print, 'Min and max differences for Electron Energy Spec'
  print, minmax(el2.y-el1.y)

  get_data, 'fa_i'+ext+'_en_spec', data = el1
  get_data, 'fa_i'+ext+'_en_spec_l2', data = el2
  print, 'Min and max differences for ions Energy Spec'
  print, minmax(el2.y-el1.y)

  get_data, 'fa_e'+ext+'_pa_spec', data = el1
  get_data, 'fa_e'+ext+'_pa_spec_l2', data = el2
  print, 'Min and max differences for Electron PA Spec'
  print, minmax(el2.y-el1.y)

  get_data, 'fa_i'+ext+'_pa_spec', data = el1
  get_data, 'fa_i'+ext+'_pa_spec_l2', data = el2
  print, 'Min and max differences for ions PA Spec'
  print, minmax(el2.y-el1.y)

  get_data, 'Je_s', data = jl1
  get_data, 'Je_s_l2', data = jl2
  print, 'Min and max differences for electron flux'
  print, minmax(jl2.y-jl1.y)
  print, 'Fractional Min and max differences for electron flux'
  print, minmax(abs(jl2.y-jl1.y)/abs(jl1.y))

  get_data, 'Ji_s', data = jl1
  get_data, 'Ji_s_l2', data = jl2
  print, 'Min and max differences for ion flux'
  print, minmax(jl2.y-jl1.y)
  print, 'Fractional Min and max differences for ion flux'
  print, minmax(abs(jl2.y-jl1.y)/abs(jl1.y))

  get_data, 'JEe_s', data = jl1
  get_data, 'JEe_s_l2', data = jl2
  print, 'Min and max differences for electron energy flux'
  print, minmax(jl2.y-jl1.y)
  print, 'Fractional Min and max differences for electron energy flux'
  print, minmax(abs(jl2.y-jl1.y)/abs(jl1.y))

  get_data, 'JEi_s', data = jl1
  get_data, 'JEi_s_l2', data = jl2
  print, 'Min and max differences for ion energy flux'
  print, minmax(jl2.y-jl1.y)
  print, 'Fractional Min and max differences for ion energy flux'
  print, minmax(abs(jl2.y-jl1.y)/abs(jl1.y))

End


