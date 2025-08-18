;based on thm_load_esa_pot.pro
;th?_pxxm_pot is converted to th?_pxxm_scpot without vaf.

pro thm_pxxm_pot_to_scpot,probe=probe,pot_scale=pot_scale,offset=offset,min_pot=min_pot,datatype_efi=datatype_efi,merge=merge,trange=trange

; booms are not fully deployed before the following dates, set pot to zero
;	TH-C	07-05-15
;	TH-D	07-06-06
;	TH-E	07-06-06
;	TH-B	07-11-21
;	TH-A	08-01-13
;
; moment packet potential must be time shifted, onboard timing changed at mom_tim_adjust
; 1.6028 = 1 + 217/360 times spin_period is the spin offset time between s/c pot in moments packet and actual time s/c potential calculated
; after mom_tim_adjust[], 0.625 times spin_period is the spin offset time between s/c pot in moments packet and actual time s/c potential calculated
; after mom_tim_adjust[], the measured moment potential should be increased by 1.03 to account for differences in V1234 and the snapshot of V3
; changes to timing for s/c potential in moments packets occurred at
; 	THEMIS A: 07-333-20:51:26
; 	THEMIS B: 07-337-18:43:24
; 	THEMIS C: 07-337-18:23:03
; 	THEMIS D: 07-331-18:34:23
; 	THEMIS E: 07-333-17:49:10
;
; moment packet potential must be rescaled after below dates (mom_pot_adjust) to compensate for onboard scaling
; ICCR_MML28 - Adjust spacecraft potential scale & offset for pot in moments packets
;	THEMIS A 07-321-19:03:49
;	THEMIS B 07-322-03:12:17
;	THEMIS C 07-322-07:12:01
;	THEMIS D 07-322-00:02:15
;	THEMIS E 07-322-01:55:32
;

boom_deploy_time=time_double(['08-01-13','07-11-21','07-05-15','07-06-06','07-06-06'])

mom_pot_adjust=dblarr(5,3)
mom_pot_adjust[*,0]=time_double(['07-11-17/19:03:49','07-11-18/03:12:17','07-11-18/07:12:01','07-11-18/00:02:15','07-11-18/01:55:32'])
mom_pot_adjust[*,1]=time_double(['08-09-10/16:00:00','08-10-10/23:00:00','08-02-05/06:00:00','08-09-06/17:00:00','08-04-04/23:00:00'])
mom_pot_adjust[*,2]=time_double(['09-06-04/20:17:45','09-06-08/21:51:00','09-06-09/22:48:00','09-06-08/21:25:00','09-06-08/22:57:00'])

mom_tim_adjust=time_double(['07-11-29/20:51:26','07-12-03/18:43:24','07-12-03/18:23:03','07-11-27/18:34:23','07-11-29/17:49:10'])
tshft_mom=[1.6028,0.625]
probe_order=['a','b','c','d','e','f']

; sc default
	if keyword_set(probe) then sc=probe
	if not keyword_set(sc) then begin
		print,'S/C number not set, default = all probes'
		sc=['a','b','c','d','e']
	endif

	if not keyword_set(themishome) then themishome=!themis.local_data_dir

nsc = n_elements(sc)
probes=strarr(1)
if nsc eq 1 then probes[0]=sc
if nsc ne 1 then probes=sc
isc = intarr(nsc)
for i=0,nsc-1 do isc[i]=where(probes(i) eq probe_order)

;***********************************************************************************
; Set scale, offset, and min_pot if not set by keywords
; TBD - In the future these scale and offset values will have to be determined on the fly

def_scale = 1.15
def_offset = 1.0
def_min_pot = 0.0

if not keyword_set(min_pot) then min_pot=def_min_pot
if not keyword_set(pot_scale) then scale=def_scale else scale=pot_scale
if not keyword_set(offset) then offset=def_offset

;***********************************************************************************
  for i=0,nsc-1 do begin
		thm_load_mom,probe=probes[i],trange=trange,datatype='pxxm'
		get_data,'th'+probes[i]+'_pxxm_pot',data=tmp,index=index
		if index ne 0 then begin
			npts=n_elements(tmp.x)
; the following uncorrects onboard mom packet sc_pot after the date where corrections were implemented
; note that the onboard offset was set to 311, where 311/256=1.215 V

			if tmp.x[npts-1] lt mom_pot_adjust[isc[i],0] then begin
					; do nothing
			endif else if tmp.x[npts-1] lt mom_pot_adjust[isc[i],1] then begin 
				ind=where(tmp.x gt mom_pot_adjust[isc[i],0],count)
				if count gt 0 then tmp.y[ind]=(tmp.y[ind]-1.215)/1.15
			endif else if tmp.x[npts-1] lt mom_pot_adjust[isc[i],2] then begin 
				ind=where(tmp.x lt mom_pot_adjust[isc[i],1],count)
				if count gt 0 then tmp.y[ind]=(tmp.y[ind]-1.215)/1.15
				ind=where(tmp.x gt mom_pot_adjust[isc[i],1],count)
				if count gt 0 then tmp.y[ind]=(tmp.y[ind]-1.215)
			endif else begin
				ind=where(tmp.x lt mom_pot_adjust[isc[i],2],count)
				if count gt 0 then tmp.y[ind]=(tmp.y[ind]-1.215)
				ind=where(tmp.x gt mom_pot_adjust[isc[i],2],count)
				if count gt 0 then tmp.y[ind]=(tmp.y[ind]-1.215)/1.15
			endelse

; the following gets the spin period so that proper corrections to the mom packet sc_pot timing can be implemented 
; mom packet sc_pot measurement time, or average time, depends on the onboard alogrithm used 

		get_data,'th'+probes[i]+'_state_spinper',data=spinper
		if not keyword_set(spinper) then begin
			thm_load_state,/get_support_data,probe=probes[i],trange=trange
			get_data,'th'+probes[i]+'_state_spinper',data=spinper
			if not keyword_set(spinper) then begin
				print,'No state data available for probe ',probes[i]
				print,'Using default 3 sec spin period'
				spin_period=replicate(3.,n_elements(tmp.x))
			endif else spin_period = interp(spinper.y,spinper.x,tmp.x)
		endif else spin_period = interp(spinper.y,spinper.x,tmp.x)

		if tmp.x[0] ge mom_tim_adjust[isc[i]] then time=tmp.x-tshft_mom[1]*spin_period else $
		if tmp.x[npts-1] le mom_tim_adjust[isc[i]] then time=tmp.x-tshft_mom[0]*spin_period else begin
			min_tim=min(abs(tmp.x-mom_tim_adjust[isc[i]]),ind)
			if tmp.x[ind] gt mom_tim_adjust[isc[i]] then ind=ind-1
			time=tmp.x
			time[0:ind]=time[0:ind]-tshft_mom[0]*spin_period[0:ind]
			time[ind+1:npts-1]=time[ind+1:npts-1]-tshft_mom[1]*spin_period[ind+1:npts-1]
		endelse	
		scpot=tmp.y
		endif else begin
			print,'No moment data available for probe ',probes[i]
		endelse

;***********************************************************************************
		if not keyword_set(scpot) then return
		scpot=(scale*(scpot+offset)) > min_pot
		store_data,'th'+probes[i]+'_pxxm_scpot',data={x:tmp.x,y:scpot}


;***********************************************************************************
; if no mom data (index=0) we still need to get the average spin period
if keyword_set(datatype_efi) then begin
		if index eq 0 then begin
			get_data,'th'+probes[i]+'_state_spinper',data=spinper
			if not keyword_set(spinper) then begin
				thm_load_state,/get_support_data,probe=probes[i],trange=trange
				get_data,'th'+probes[i]+'_state_spinper',data=spinper
				if not keyword_set(spinper) then begin
					print,'No state data available for probe ',probes[i]
					print,'Using default 3 sec spin period'
					spin_period=3.
					npts=1
				endif else begin
					spin_period = spinper.y 
					npts=n_elements(spinper.x)
				endelse
			endif else begin
				spin_period = spinper.y 
				npts=n_elements(spinper.x)
			endelse
		endif

		avg_spin_period=total(spin_period)/npts

; Calculate sc_pot based on efi vaf data if available

		thm_load_efi,probe=probes[i],datatype=datatype_efi,level=1,trange=trange
		get_data,'th'+probes[i]+'_'+datatype_efi,data=tmp1,index=index2

		if index2 ne 0 then begin
;			get rid of bad points
			bad_frac=1.05 
			vaf1 = -1.*reform(tmp1.y[*,0])
			vaf2 = -1.*reform(tmp1.y[*,1])
			vaf3 = -1.*reform(tmp1.y[*,2])
			vaf4 = -1.*reform(tmp1.y[*,3])
			ind1 = where(bad_frac lt 3.*vaf1/(vaf2+vaf3+vaf4),cnt1)
			ind2 = where(bad_frac lt 3.*vaf2/(vaf1+vaf3+vaf4),cnt2)
			ind3 = where(bad_frac lt 3.*vaf3/(vaf4+vaf1+vaf2),cnt3)
			ind4 = where(bad_frac lt 3.*vaf4/(vaf3+vaf1+vaf2),cnt4)
			if cnt1 gt 0 then vaf1[ind1]=vaf2[ind1]
			if cnt2 gt 0 then vaf2[ind2]=vaf1[ind2]
			if cnt3 gt 0 then vaf3[ind3]=vaf4[ind3]
			if cnt4 gt 0 then vaf4[ind4]=vaf3[ind4]
			vaf12 = (vaf1+vaf2)/2.
			vaf34 = (vaf3+vaf4)/2.
			ind5 = where(vaf12/vaf34 gt bad_frac and vaf34 gt 1.,cnt5) 
			if cnt5 gt 0 then vaf12[ind5]=vaf34[ind5]		
			ind6 = where(vaf34/vaf12 gt bad_frac and vaf12 gt 1.,cnt6) 
			if cnt6 gt 0 then vaf34[ind6]=vaf12[ind6]		
			vaf1234 = (vaf12+vaf34)/2.
			print,'Bad point counts=',cnt1,cnt2,cnt3,cnt4,cnt5,cnt6

;			vaf1234_3a=time_average(tmp1.x,vaf1234,resolution=avg_spin_period,newtime=newtime)
;			ind = where(finite(vaf1234_3a))
;			newtime=newtime(ind)
;			vaf1234_3a=vaf1234_3a(ind)
;			if keyword_set(make_plot) then store_data,'th'+sc+'_vaf1234_3a_pot',data={x:newtime,y:vaf1234_3a}


			vaf1234_3s=smooth_in_time(vaf1234,tmp1.x,avg_spin_period)
			if keyword_set(make_plot) then store_data,'th'+sc+'_vaf1234_3s_pot',data={x:tmp1.x,y:vaf1234_3s}

			if keyword_set(make_plot) then store_data,'th'+sc+'_mom_pot',data={x:time,y:scpot}

;			if index ne 0 then begin
;;				t3 = [time,newtime]
;;				d3 = [scpot,vaf1234_3a]
;				t3 = [time,tmp1.x]
;				d3 = [scpot,vaf1234_3s]
;				s = sort(t3)
;				time=t3[s]
;				scpot=d3[s]
;			endif else begin
;; bug, newtime no longer defined
;;				time=newtime
;**				time = tmp1.x  		; bug fix by Jim McTiernan, failed when no mom data existed
;				scpot=vaf1234_3s

;**				scpot=vaf1234
;			endelse

		vaf1234=(scale*(vaf1234+offset)) > min_pot

			if keyword_set(merge) then begin
			;if index ne 0 then begin
				t3 = [time,tmp1.x]
				d3 = [scpot,vaf1234]
				s = sort(t3)
				time=t3[s]
				scpot=d3[s]
			endif else begin
;; bug, newtime no longer defined
;;				time=newtime
				time = tmp1.x  		; bug fix by Jim McTiernan, failed when no mom data existed
;				scpot=vaf1234_3s
				scpot=vaf1234
			endelse

		endif

;**		scpot=(scale*(scpot+offset)) > min_pot
		store_data,'th'+probes[i]+'_esa_pot',data={x:time,y:scpot}


    ;spin phase
    model=spinmodel_get_ptr(probes[i])
    spinmodel_interp_t,model=model,time=time, spinphase=phase,spinper=spinper,use_spinphase_correction=1       ;a la J. L.
    phase*=!dtor
    phase-=45*!dtor
    newname='th'+probes[i]+'_'+datatype_efi+'_phase'
    store_data,newname,data={x:time,y:phase*180/!pi},dlim={colors:0,labels:'PH',ysubtitle:'[deg]',constant:[0,90,180,270]}
    ylim,newname,-90,360
    options,newname,yticks=5

endif

endfor
end