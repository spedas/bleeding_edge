;+
;pro thm_sst_crib
; This is an example crib sheet that will load Solid State Telescope data.
; Open this file in a text editor and then use copy and paste to copy
; selected lines into an idl window. Or alternatively compile and run
; using the command:
; .RUN THM_SST_CRIB
;Author: Davin Larson
;
; $Id:$
;-

date = '2007-03-23'

if 0 then setbp,/thisfile

dprint,getdebug=db,setdebug=3,print_trace=3,print_dtime=1,/print_dlevel

if keyword_set(date) then timespan,date,ndays else timespan,systime(1)-2*3600d*24
prb = ['a','b','c','d','e']
prb = 'c'
thx = 'th'+prb

loaded = 0
if not keyword_set(loaded) then begin

thm_load_sst,probe=prb       ;bpif keyword_set(dbg)
mtypes = ['psif','psef']   ; SST
thm_part_spec_calc,probe=prb,moments=['density','flux','mftens','velocity','T3'],instruments=mtypes
thm_part_spec_calc,probe=prb,instruments=mtypes

stop

;;thm_load_mom,probe=prb
;thm_load_hsk,probe=prb,varformat='th?_*sst* th?_imon_?5va th?_imon_?5va'
;thm_load_hsk,probe=prb,varformat='th?_*esa*'
;thm_load_fit, /get_support_data
;thm_cal_fit, /verbose
;thm_load_state2,probe=prb,/get_support,/polar
;tplot_options,var_label = 'th'+prb+'_state_pos_Re'
 ; mtypes = ['sif','sef']
;thm_part_mom_calc,probe=prb,comps=['density','flux','mftens','velocity','T3'],types=mtypes



; ESA data:

if 0 then begin  ; ESA portion not working yet
thm_load_esa_pkt,probe=prb
mtypes = ['peif','peef']   ; ESA
thm_part_spec_calc,probe=prb,moments=['density','flux','mftens','velocity','T3'],instruments=mtypes
endif
stop

; mom=moments_3d()

;store_data,'Tha_pexf_density',data=tnames('tha_pe?f_density')
;store_data,'Tha_pexf_velocity',data=tnames('tha_pe?f_velocity')
;
;store_data,'Tha_peix_density',data=tnames('tha_pei?_density')
;store_data,'Tha_peex_density',data=tnames('tha_pee?_density')
;store_data,'Tha_peix_flux',data=tnames('tha_pei?_flux')
;store_data,'Tha_peex_flux',data=tnames('tha_pee?_flux')
;store_data,'Tha_peix_mftens',data=tnames('tha_pei?_mftens')
;store_data,'Tha_peex_mftens',data=tnames('tha_pee?_mftens')

ylim,'*_density',.01,100,1
ylim,'*_flux',-5e7,5e7,0
ylim,'*_mftens',-1000,5000
ylim,'*_eflux',-2e7,2e7

loaded = keyword_set(tnames())
endif

;tplot,'T*'

tplot,'th?_ps?f_en'


if 0 then begin

;tplot,'tha_pei[fm]*'    ;bp

;tplot,/add,'T*

;tplot,'thb_pei[fm]*'    ;bp
;tplot,'thc_pei[fm]*'    ;bp
;tplot,'thd_pei[fm]*'    ;bp
;tplot,'the_pei[fm]*'    ;bp

tplot,'tha_pee[fm]*'    ;bp
;tplot,'thb_pee[fm]*'    ;bp
;tplot,'thc_pee[fm]*'    ;bp
;tplot,'thd_pee[fm]*'    ;bp
;tplot,'the_pee[fm]*'    ;bp


;mom= moments_3d()


dtype = 'tha_peef'
spec3d,thm_part_dist(dtype,gettime(/c))
plot3d_new,thm_part_dist(dtype,gettime(/c))



;thm_load_mom_del,probe=prb
;thm_load_esa,probe=prb

;; for s=12,16 do for w=20,44,8 do print, (2 * 64 + ((s+16) mod 32) * 2)*256 + w,s,w, form='("1B",Z4,"     ;  start=",i,"  length=",i)'

endif


dprint,setdebug=db
dprint,'Done'

end
