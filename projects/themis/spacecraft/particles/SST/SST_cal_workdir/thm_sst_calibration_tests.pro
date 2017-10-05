
;+
;NAME:
; thm_sst_calibration_tests
;PURPOSE:
;
;  This routine is for testing new calibrations(will eventually be moved to QA directory) 
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2011-10-10 13:06:53 -0700 (Mon, 10 Oct 2011) $
;$LastChangedRevision: 9100 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_calibration_tests.pro $
;-

pro thm_sst_calibration_tests

  timespan,'2009-11-11/00:00:00'
  
  probe = 'e'
  
  thm_init
  
  !themis.no_update=1
  
  ;this uses the new calibration code
  thm_load_sst2,probe=probe
  
  ;test full distribution
  thm_part_moments,probe=probe,inst='psif',moments='*',/sst_cal,tplotsuffix='_new'
  
  ;this uses the old calibration code
  thm_load_sst,probe=probe
  thm_part_moments,probe=probe,inst='psif',moments='*',tplotsuffix='_old'
  psif_flux_tvars = ['th'+probe+'_psif_en_eflux_old','th'+probe+'_psif_en_eflux_new']

  options,psif_flux_tvars,yrange=[1e4,1e7],zrange=[1e2,1e7]
  
  tplot,psif_flux_tvars
  
  stop
  
  ;test full distribution electrons
  ;By default, this code will combine data from the F & FT distributions of SST data
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new'
  
  ;this uses the old calibration code
  ;thm_load_sst,probe=probe
  thm_part_moments,probe=probe,inst='psef',moments='*',tplotsuffix='_old'
   
  psef_flux_tvars=['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  options,psef_flux_tvars,yrange=[2e4,3e6],zrange=[1e2,1e7],ystyle=1
  tplot,psef_flux_tvars
  
  stop
  
  ;test burst distribution
  thm_part_moments,probe=probe,inst='pseb',moments='*',/sst_cal,tplotsuffix='_new'
  
  ;this uses the old calibration code
  ;thm_load_sst,probe=probe
  thm_part_moments,probe=probe,inst='pseb',moments='*',tplotsuffix='_old'

  tplot,['th'+probe+'_pseb_en_eflux_old','th'+probe+'_pseb_en_eflux_new']
  
  stop
  
  ;test reduced distribution
  thm_part_moments,probe=probe,inst='psir',moments='*',/sst_cal,tplotsuffix='_new'
  
  ;this uses the old calibration code
 ; thm_load_sst,probe=probe
  thm_part_moments,probe=probe,inst='psir',moments='*',tplotsuffix='_old'


  tplot,['th'+probe+'_psir_en_eflux_old','th'+probe+'_psir_en_eflux_new']

  stop
  
  ;test ot channels
  thm_part_moments,probe=probe,inst='psif',moments='*',/sst_cal,tplotsuffix='_new',/ft_ot
  
  tplot,['th'+probe+'_psif_en_eflux_old','th'+probe+'_psif_en_eflux_new']
  
  stop
  
  ;test f channels
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',/f_o
  thm_part_moments,probe=probe,inst='psef',moments='*',tplotsuffix='_old'
  
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
  
   ;test ft channels
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',/ft_ot
  thm_part_moments,probe=probe,inst='psef',moments='*',tplotsuffix='_old'
  
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
  
   ;test fto channel(electrons)
  thm_part_moments,probe=probe,inst='psef',moments='*',/sst_cal,tplotsuffix='_new',/fto
  
  ;note that fto channel won't plot correctly because specplot can't properly draw single channels
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
  
  ;test fto channel(ions)
  thm_part_moments,probe=probe,inst='psif',moments='*',/sst_cal,tplotsuffix='_new',/fto
  
  ;note that fto channel won't plot correctly because specplot can't properly draw single channels
  tplot,['th'+probe+'_psef_en_eflux_old','th'+probe+'_psef_en_eflux_new']
  
  stop
  
  thm_part_getspec, probe=[probe], $
                  theta=[-45,45], phi=[0,450], $
                  data_type=['psif','psef'], angle='phi',suffix='_old'
                  
  thm_part_getspec, probe=[probe], $
                  theta=[-45,45], phi=[0,450],erange=[1,1e7], $
                  data_type=['psif','psef'], angle='phi',suffix='_new',$
                  /sst_cal

  tplot,['th'+probe+'_ps?f_an_eflux_phi_*']

  stop

  ;code to test the cross contamination removal routine directly
 
 
  e_dat = thm_part_dist('th'+probe+'_psef',time_double('2009-11-11/06:00:00'),/sst_cal)
  p_dat = thm_part_dist('th'+probe+'_psif',time_double('2009-11-11/06:00:00'),/sst_cal)
  thm_sst_cross_contamination_remove,p_dat.data,e_dat.data,p_dat.energy[*,0],e_dat.energy[*,0] 

  stop
  
  ;quick test of all probes and species to verify that cal files are correctly formatted
  
  thm_init
  probes=['a','b','c','d','e']
  timespan,'2009-11-11/12:00:00',15,/minute
  
  for i=0,n_elements(probes)-1 do begin
  probe = probes[i]
  
    ;!themis.no_update=1
  
    ;this uses the new calibration code
    thm_load_sst2,probe=probe
  

    thm_part_moments,probe=probe,inst='ps?f',moments='*',/sst_cal,tplotsuffix='_new'
    
  endfor
  
  stop
end