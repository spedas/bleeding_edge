;+
;PROCEDURE:
; thm_load_esa_bkg
;
;PURPOSE:	
;	Adds background count rates to the ESA data structures which can be used 
; by thm_pei_bkg_sub and thm_pee_bkg_sub for background removal.
;
;INPUT:		
;	probe:  strarr		themis spacecraft - "a", "b", "c", "d", "e"
;         if not set defaults to all		
;	sc:		strarr		themis spacecraft - "a", "b", "c", "d", "e"
;       if not set defaults to all		
;	datatype:  string array specifying datatypes from which background is calculated
;            valid inputs: "peir", "peer", "pser"
;            if not set defaults to all
;            peer data is also used for calculating pser background
; trange:  two element time range
;          if not specified or set with timespan user will be prompted
;	user_select:  0/1	keyword not working -- code under construction
;               if set, will run thm_pse_bkg_set.pro to let the user select the interval for calculating pser sunlight background 
;               if not set, will run thm_pse_bkg_auto.pro for automated pser sunlight background subtraction
;
;CREATED BY:	J. McFadden	08/12/31
;VERSION:	1
;LAST MODIFICATION:  08/12/31
;MOD HISTORY:
;				08/12/31	
;				10/03/18	added peer background from scattered electrons	
;				10/04/06	background array for electrons now filled using ion calculated background
;     2016/06/30  minor changes to integrate with spedas
;     2016/07/12  autoload all data, some code cleaning
;
;NOTES:	 
;		Autoloads pser, peir, peer, and state data if not present
;		If both iesa and sst data sets are used, will use the lower background estimate 
;		Uses iesa data for background in the inner magnetosphere
;		Will only work properly if data includes a perigee pass 
;	
;-

pro thm_load_esa_bkg,sc=sc, probes=probes_in, datatype=datatype_in, trange=trange, _extra=_extra

  compile_opt strictarr

;	Time how long the routine takes
ex_start = systime(1)

cols=get_colors()

; get spacecraft/probe input
if undefined(probes_in) then begin
  if undefined(sc) then begin
    probes = ['a','b','c','d','e','f']
  endif else begin
    probes = sc
  endelse
endif else begin
  probes = probes_in
endelse

; get datatype input
if undefined(datatype) then begin
  datatype = ['peir','peer','pser']
endif else begin
  datatype = datatype_in
endelse

dprint, 'Loading ESA background for probes: '+strjoin(probes,', '), dlevel=2
dprint, 'Loading ESA background from datatypes: '+strjoin(datatype,', '), dlevel=2

; matrix to transform pser count spectra to psir background counts -- needs to be calculated
; we may need different arrays for different spacecraft

;aa = 1.e-3*[0.32,0.425,.537,.672,.935,1.378,1.985,2.825,3.995]^2.
;aa = [1.50000,0.000113094, 0.000113094,0.000132572,0.000312597,0.00131105,0.00480372,0.0229715 ,0.0229715]	; 20080213
aa = [1.50000,6.27452e-005,0.000120554,0.000222392,0.000539607,0.00150673,0.00392665,0.00984036,0.0241520]
; the 0.7 in aa[0] sets the minimum background determined from pser
aa = [0.70,6.27452e-005,0.000120554,0.000222392,0.000539607,0.00150673,0.00392665,0.00984036,0.0241520]
;***********************************************************************************

;=======================================================
; get background data
;=======================================================

for i=0, n_elements(probes)-1 do begin

	dprint,'Calculating background for th'+probes[i], dlevel=2

;=======================================================
; pser determined background
;=======================================================

	if in_set(datatype,'pser') then begin
		dprint,'Calculating background from pser data', dlevel=2
;		wait,.1

;	'th'+probes[i]+'_pser_minus_bkg' contains pser counts after sunlight background subtraction

;		tmp = thm_sst_pser(probe=probes[i],index=10)
;		if not keyword_set(tmp) then thm_load_sst,probe=probes[i]
;		thm_load_sst,probe=probes[i]

    thm_part_load, probe=probes[i], datatype='pser', trange=trange, _extra=_extra
    thm_part_load, probe=probes[i], datatype='peer', trange=trange, _extra=_extra

		if keyword_set(user_select) then begin
;    this user_select section doesn't work, bkg keyword disabled for pse data
			name1='th'+probes[i]+'_pser_minus_bkg'
			get_dat='thm_sst_pser'
			thm_get_en_spec,get_dat,units='counts',name=name1,probe=probes[i],bkg=1
				ylim,name1,100.,100000.,1
				options,name1,'ytitle','e- th'+probes[i]+'!C!CCounts'
				options,name1,'spec',0
			name2='th'+probes[i]+'_pser_atten'
			thm_get_2dt,'sst_atten',get_dat,name=name2,probe=probes[i]
				ylim,name2,0.,11,0
				options,name2,'ytitle','e- sst th'+probes[i]+'!C!C Atten'
		endif else begin
      thm_pse_bkg_auto,sc=probes[i]
    endelse

		get_data,'th'+probes[i]+'_pser_minus_bkg',data=tmp1
    ;warn if data is not present and proceed as though no pser was used -af
    if ~is_struct(tmp1) then begin
      dprint, 'WARNING: No pser data available for background determination!',dlevel=1
      att_on = [1.,1.]
      bkg1 = [0.,0.]
      time1 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
    endif else begin

  ;		get_data,'th'+probes[i]+'_pser_atten',data=tmp2
  		sst = transpose(tmp1.y[*,0:8]) & sst[0,*]=1.
  ;		att = interp(tmp2.y,tmp2.x,tmp1.x)
  		npt = n_elements(tmp1.x) 
  ;		att_on=fltarr(npt) & att_on(where(att eq 5))=1.
  		att_on=replicate(1.,npt)
  		bkg1 = total((aa#att_on)*sst,1)
  		time1=tmp1.x
 
  		thm_get_2dt,'jo_3d_new','th'+sc+'_peer',name='Jeo_10_30keV',gap_time=6.,energy=[10000,27000.]
  		get_data,'Jeo_10_30keV',data=tmp8
  		bkg_pee = 5.e-9*interp(tmp8.y,tmp8.x,tmp1.x)
  		store_data,'th'+probes[i]+'_peer_pei_bkg',data={x:tmp1.x,y:bkg_pee}
  			ylim,'th'+probes[i]+'_peer_pei_bkg',1,100,1
  		bkg1=bkg1+bkg_pee
  
  		store_data,'th'+probes[i]+'_pser_pei_bkg',data={x:tmp1.x,y:bkg1}
  			ylim,'th'+probes[i]+'_pser_pei_bkg',1.,10000.,1
  			options,'th'+probes[i]+'_pser_pei_bkg','ytitle','Bkg pse th'+probes[i]+'!C!CCounts'

    endelse

	endif else begin
		att_on = [1.,1.]
		bkg1 = [0.,0.]
		time1 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
	endelse

;=======================================================
; peir determined background
;=======================================================

	if in_set(datatype,'peir') then begin
		dprint,'Calculating background from peir data', dlevel=2
;		wait,.1

    thm_part_load, probe=probes[i], datatype='peir', trange=trange, _extra=_extra

		get_dat='th'+probes[i]+'_peir'
		name1='th'+probes[i]+'_pei_pei_bkg'
;TODO here it stops now		
		thm_get_2dt,'thm_pei_bkg',get_dat,name=name1
			ylim,name1,1.,10000.,1
			options,name1,'ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
; the following screwed up in shadow and was replaced with tsmooth2
;		get_data,name1,data=tmp2
;		pei_bkg_3s=smooth_in_time(tmp2.y,tmp2.x,1.05*(tmp2.x[50]-tmp2.x[47]))	; smooth over 3 spins
;		store_data,'thm_pei_bkg_smooth',data={x:tmp2.x,y:pei_bkg_3s}
;		bkg2=pei_bkg_3s
		tsmooth2,name1,3,newname='thm_pei_bkg_smooth'				; smooth over 3 spins
		get_data,'thm_pei_bkg_smooth',data=tmp2
		bkg2=tmp2.y
		time2=tmp2.x

	endif else begin
		bkg2 = [0.,0.]
		time2 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
	endelse

;=======================================================
; peer determined background
;=======================================================

	if in_set(datatype,'peer') then begin
		dprint,'Calculating background from peer data', dlevel=2
;		wait,.1

    thm_part_load, probe=probes[i], datatype='peer', trange=trange, _extra=_extra

		get_dat='th'+probes[i]+'_peer'
		name1='th'+probes[i]+'_peer_pee_bkg'
		thm_get_2dt,'thm_pee_bkg',get_dat,name=name1
			ylim,name1,1.,10000.,1
			options,name1,'ytitle','Bkg pee th'+probes[i]+'!C!C Counts'
		tsmooth2,name1,3,newname='thm_pee_bkg_smooth'				; smooth over 3 spins
		get_data,'thm_pee_bkg_smooth',data=tmp2
		bkg4=tmp2.y
		time4=tmp2.x

	endif else begin
		bkg4 = [0.,0.]
		time4 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
	endelse

;=======================================================
; optimize with sc pos
;=======================================================

; if both peir and pser background used, then optimize pser background, state data must be loaded
; scale pser bkg to optimize agreement with peir bkg for distance>5.3Re
; dis3 and time3 are used to force pei bkg use for distance<5.3Re

	get_data,'th'+probes[i]+'_state_pos',data=tmp3,index=index
	if index eq 0 then begin
		thm_load_state,probe=probes[i],version=2, trange=trange
		get_data,'th'+probes[i]+'_state_pos',data=tmp3,index=index
	endif
	if index gt 0 then begin
		dis3=(total(tmp3.y^2,2))^.5/6370.
		time3=tmp3.x
		if total(bkg1)*total(bkg2) ne 0. then begin
			ind = where(bkg1 gt 20. and bkg1 lt 500.,count)
			if count gt 1000 then begin 
				bkg8=interp(bkg2,time2,time1[ind])
				dist=interp(dis3,time3,time1[ind])
				bkg7=bkg1[ind]
				ind2 = where(finite(bkg8) and finite(bkg7) and dist gt 5.3,count2)
				if count2 gt 1000 then scale = total(bkg7[ind2]*bkg8[ind2])/total(bkg7[ind2]*bkg7[ind2]) else scale=1.
				if scale gt 2. or scale lt .5 then begin
					dprint,'Error - thm_load_esa_bkg scale correction is too large',dlevel=1
					dprint,'Probable error in pser optimization code',dlevel=1
					dprint,'pser background set to zero',dlevel=1
					att_on = [1.,1.]
					bkg1 = [0.,0.]
					time1 = [time_double('07-02-01/0'),time_double('27-02-01/0')]
				endif else begin
					dprint,'pser background scaled from default values by: ',strtrim(scale,2), dlevel=2
					bkg1 = bkg1 * scale
					store_data,'th'+probes[i]+'_pser_pei_bkg',data={x:time1,y:bkg1}
				endelse
			endif
		endif
	endif else begin
    ;af - it's not clear what the correct treatment should be if state data is missing
    ;     but it *should* be present at all times
    dprint,'ERROR: State data not present for th'+probes[i]+'; no background loaded',dlevel=0
    continue
	endelse

;=======================================================
; add to esa common block structures
;=======================================================

; diagnostics
; print,minmax(bkg1)
; print,minmax(bkg2)
; print,n_elements(where(att eq 5))
; print,n_elements(where(att_on eq 1))
; print,n_elements(where(att_on ne 1))

	if probes[i] eq 'a' then begin
		common tha_454,tha_454_ind,tha_454_dat 
		if n_elements(tha_454_dat) ne 0 then begin
		  if tha_454_ind ne -1 then begin
			time=(tha_454_dat.time+tha_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_454_dat.bkg_pse=bkg_pse
			tha_454_dat.bkg_pei=bkg_pei
			tha_454_dat.bkg=bkg3
		  endif
		endif
		common tha_455,tha_455_ind,tha_455_dat 
		if n_elements(tha_455_dat) ne 0 then begin
		  if tha_455_ind ne -1 then begin
			time=(tha_455_dat.time+tha_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_455_dat.bkg_pse=bkg_pse
			tha_455_dat.bkg_pei=bkg_pei
			tha_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common tha_456,tha_456_ind,tha_456_dat 
		if n_elements(tha_456_dat) ne 0 then begin
		  if tha_456_ind ne -1 then begin
			time=(tha_456_dat.time+tha_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_456_dat.bkg_pse=bkg_pse
			tha_456_dat.bkg_pei=bkg_pei
			tha_456_dat.bkg=bkg3
		  endif
		endif
		common tha_457,tha_457_ind,tha_457_dat 
		if n_elements(tha_457_dat) ne 0 then begin
		  if tha_457_ind ne -1 then begin
			time=(tha_457_dat.time+tha_457_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_457_dat.bkg_pse=bkg_pse
			tha_457_dat.bkg_pei=bkg_pei
			tha_457_dat.bkg_pee=bkg_pee
			tha_457_dat.bkg=bkg3
		  endif
		endif
		common tha_458,tha_458_ind,tha_458_dat 
		if n_elements(tha_458_dat) ne 0 then begin
		  if tha_458_ind ne -1 then begin
			time=(tha_458_dat.time+tha_458_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_458_dat.bkg_pse=bkg_pse
			tha_458_dat.bkg_pei=bkg_pei
			tha_458_dat.bkg_pee=bkg_pee
			tha_458_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pee_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg_pee],[bkg3]]}
				ylim,'th'+probes[i]+'_pee_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pee_bkg','ytitle','Bkg pee th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pee_bkg','colors',[cols.red,cols.green,cols.magenta,cols.black]
				options,'th'+probes[i]+'_pee_bkg','labels',['pei', 'pse', 'pee', 'bkg']
				options,'th'+probes[i]+'_pee_bkg','labflag', 1
		  endif
		endif
		common tha_459,tha_459_ind,tha_459_dat 
		if n_elements(tha_459_dat) ne 0 then begin
		  if tha_459_ind ne -1 then begin
			time=(tha_459_dat.time+tha_459_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			tha_459_dat.bkg_pse=bkg_pse
			tha_459_dat.bkg_pei=bkg_pei
			tha_459_dat.bkg_pee=bkg_pee
			tha_459_dat.bkg=bkg3
		  endif
		endif
	endif else if probes[i] eq 'b' then begin
		common thb_454,thb_454_ind,thb_454_dat 
		if n_elements(thb_454_dat) ne 0 then begin
		  if thb_454_ind ne -1 then begin
			time=(thb_454_dat.time+thb_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_454_dat.bkg_pse=bkg_pse
			thb_454_dat.bkg_pei=bkg_pei
			thb_454_dat.bkg=bkg3
		  endif
		endif
		common thb_455,thb_455_ind,thb_455_dat 
		if n_elements(thb_455_dat) ne 0 then begin
		  if thb_455_ind ne -1 then begin
			time=(thb_455_dat.time+thb_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_455_dat.bkg_pse=bkg_pse
			thb_455_dat.bkg_pei=bkg_pei
			thb_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common thb_456,thb_456_ind,thb_456_dat 
		if n_elements(thb_456_dat) ne 0 then begin
		  if thb_456_ind ne -1 then begin
			time=(thb_456_dat.time+thb_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_456_dat.bkg_pse=bkg_pse
			thb_456_dat.bkg_pei=bkg_pei
			thb_456_dat.bkg=bkg3
		  endif
		endif
		common thb_457,thb_457_ind,thb_457_dat 
		if n_elements(thb_457_dat) ne 0 then begin
		  if thb_457_ind ne -1 then begin
			time=(thb_457_dat.time+thb_457_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_457_dat.bkg_pse=bkg_pse
			thb_457_dat.bkg_pei=bkg_pei
			thb_457_dat.bkg_pee=bkg_pee
			thb_457_dat.bkg=bkg3
		  endif
		endif
		common thb_458,thb_458_ind,thb_458_dat 
		if n_elements(thb_458_dat) ne 0 then begin
		  if thb_458_ind ne -1 then begin
			time=(thb_458_dat.time+thb_458_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_458_dat.bkg_pse=bkg_pse
			thb_458_dat.bkg_pei=bkg_pei
			thb_458_dat.bkg_pee=bkg_pee
			thb_458_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pee_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg_pee],[bkg3]]}
				ylim,'th'+probes[i]+'_pee_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pee_bkg','ytitle','Bkg pee th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pee_bkg','colors',[cols.red,cols.green,cols.magenta,cols.black]
				options,'th'+probes[i]+'_pee_bkg','labels',['pei', 'pse', 'pee', 'bkg']
				options,'th'+probes[i]+'_pee_bkg','labflag', 1
		  endif
		endif
		common thb_459,thb_459_ind,thb_459_dat 
		if n_elements(thb_459_dat) ne 0 then begin
		  if thb_459_ind ne -1 then begin
			time=(thb_459_dat.time+thb_459_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thb_459_dat.bkg_pse=bkg_pse
			thb_459_dat.bkg_pei=bkg_pei
			thb_459_dat.bkg_pee=bkg_pee
			thb_459_dat.bkg=bkg3
		  endif
		endif
	endif else if probes[i] eq 'c' then begin
		common thc_454,thc_454_ind,thc_454_dat 
		if n_elements(thc_454_dat) ne 0 then begin
		  if thc_454_ind ne -1 then begin
			time=(thc_454_dat.time+thc_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_454_dat.bkg_pse=bkg_pse
			thc_454_dat.bkg_pei=bkg_pei
			thc_454_dat.bkg=bkg3
		  endif
		endif
		common thc_455,thc_455_ind,thc_455_dat 
		if n_elements(thc_455_dat) ne 0 then begin
		  if thc_455_ind ne -1 then begin
			time=(thc_455_dat.time+thc_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_455_dat.bkg_pse=bkg_pse
			thc_455_dat.bkg_pei=bkg_pei
			thc_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common thc_456,thc_456_ind,thc_456_dat 
		if n_elements(thc_456_dat) ne 0 then begin
		  if thc_456_ind ne -1 then begin
			time=(thc_456_dat.time+thc_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_456_dat.bkg_pse=bkg_pse
			thc_456_dat.bkg_pei=bkg_pei
			thc_456_dat.bkg=bkg3
		  endif
		endif
		common thc_457,thc_457_ind,thc_457_dat 
		if n_elements(thc_457_dat) ne 0 then begin
		  if thc_457_ind ne -1 then begin
			time=(thc_457_dat.time+thc_457_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_457_dat.bkg_pse=bkg_pse
			thc_457_dat.bkg_pei=bkg_pei
			thc_457_dat.bkg_pee=bkg_pee
			thc_457_dat.bkg=bkg3
		  endif
		endif
		common thc_458,thc_458_ind,thc_458_dat 
		if n_elements(thc_458_dat) ne 0 then begin
		  if thc_458_ind ne -1 then begin
			time=(thc_458_dat.time+thc_458_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_458_dat.bkg_pse=bkg_pse
			thc_458_dat.bkg_pei=bkg_pei
			thc_458_dat.bkg_pee=bkg_pee
			thc_458_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pee_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg_pee],[bkg3]]}
				ylim,'th'+probes[i]+'_pee_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pee_bkg','ytitle','Bkg pee th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pee_bkg','colors',[cols.red,cols.green,cols.magenta,cols.black]
				options,'th'+probes[i]+'_pee_bkg','labels',['pei', 'pse', 'pee', 'bkg']
				options,'th'+probes[i]+'_pee_bkg','labflag', 1
		  endif
		endif
		common thc_459,thc_459_ind,thc_459_dat 
		if n_elements(thc_459_dat) ne 0 then begin
		  if thc_459_ind ne -1 then begin
			time=(thc_459_dat.time+thc_459_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thc_459_dat.bkg_pse=bkg_pse
			thc_459_dat.bkg_pei=bkg_pei
			thc_459_dat.bkg_pee=bkg_pee
			thc_459_dat.bkg=bkg3
		  endif
		endif
	endif else if probes[i] eq 'd' then begin
		common thd_454,thd_454_ind,thd_454_dat 
		if n_elements(thd_454_dat) ne 0 then begin
		  if thd_454_ind ne -1 then begin
			time=(thd_454_dat.time+thd_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_454_dat.bkg_pse=bkg_pse
			thd_454_dat.bkg_pei=bkg_pei
			thd_454_dat.bkg=bkg3
		  endif
		endif
		common thd_455,thd_455_ind,thd_455_dat 
		if n_elements(thd_455_dat) ne 0 then begin
		  if thd_455_ind ne -1 then begin
			time=(thd_455_dat.time+thd_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_455_dat.bkg_pse=bkg_pse
			thd_455_dat.bkg_pei=bkg_pei
			thd_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common thd_456,thd_456_ind,thd_456_dat 
		if n_elements(thd_456_dat) ne 0 then begin
		  if thd_456_ind ne -1 then begin
			time=(thd_456_dat.time+thd_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_456_dat.bkg_pse=bkg_pse
			thd_456_dat.bkg_pei=bkg_pei
			thd_456_dat.bkg=bkg3
		  endif
		endif
		common thd_457,thd_457_ind,thd_457_dat 
		if n_elements(thd_457_dat) ne 0 then begin
		  if thd_457_ind ne -1 then begin
			time=(thd_457_dat.time+thd_457_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_457_dat.bkg_pse=bkg_pse
			thd_457_dat.bkg_pei=bkg_pei
			thd_457_dat.bkg_pee=bkg_pee
			thd_457_dat.bkg=bkg3
		  endif
		endif
		common thd_458,thd_458_ind,thd_458_dat 
		if n_elements(thd_458_dat) ne 0 then begin
		  if thd_458_ind ne -1 then begin
			time=(thd_458_dat.time+thd_458_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_458_dat.bkg_pse=bkg_pse
			thd_458_dat.bkg_pei=bkg_pei
			thd_458_dat.bkg_pee=bkg_pee
			thd_458_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pee_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg_pee],[bkg3]]}
				ylim,'th'+probes[i]+'_pee_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pee_bkg','ytitle','Bkg pee th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pee_bkg','colors',[cols.red,cols.green,cols.magenta,cols.black]
				options,'th'+probes[i]+'_pee_bkg','labels',['pei', 'pse', 'pee', 'bkg']
				options,'th'+probes[i]+'_pee_bkg','labflag', 1
		  endif
		endif
		common thd_459,thd_459_ind,thd_459_dat 
		if n_elements(thd_459_dat) ne 0 then begin
		  if thd_459_ind ne -1 then begin
			time=(thd_459_dat.time+thd_459_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			thd_459_dat.bkg_pse=bkg_pse
			thd_459_dat.bkg_pei=bkg_pei
			thd_459_dat.bkg_pee=bkg_pee
			thd_459_dat.bkg=bkg3
		  endif
		endif
	endif else if probes[i] eq 'e' then begin
		common the_454,the_454_ind,the_454_dat 
		if n_elements(the_454_dat) ne 0 then begin
		  if the_454_ind ne -1 then begin
			time=(the_454_dat.time+the_454_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_454_dat.bkg_pse=bkg_pse
			the_454_dat.bkg_pei=bkg_pei
			the_454_dat.bkg=bkg3
		  endif
		endif
		common the_455,the_455_ind,the_455_dat 
		if n_elements(the_455_dat) ne 0 then begin
		  if the_455_ind ne -1 then begin
			time=(the_455_dat.time+the_455_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_455_dat.bkg_pse=bkg_pse
			the_455_dat.bkg_pei=bkg_pei
			the_455_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pei_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg3]]}
				ylim,'th'+probes[i]+'_pei_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pei_bkg','ytitle','Bkg pei th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pei_bkg','colors',[cols.red,cols.green,cols.black]
				options,'th'+probes[i]+'_pei_bkg','labels',['pei', 'pse', 'bkg']
				options,'th'+probes[i]+'_pei_bkg','labflag', 1
		  endif
		endif
		common the_456,the_456_ind,the_456_dat 
		if n_elements(the_456_dat) ne 0 then begin
		  if the_456_ind ne -1 then begin
			time=(the_456_dat.time+the_456_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_456_dat.bkg_pse=bkg_pse
			the_456_dat.bkg_pei=bkg_pei
			the_456_dat.bkg=bkg3
		  endif
		endif
		common the_457,the_457_ind,the_457_dat 
		if n_elements(the_457_dat) ne 0 then begin
		  if the_457_ind ne -1 then begin
			time=(the_457_dat.time+the_457_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_457_dat.bkg_pse=bkg_pse
			the_457_dat.bkg_pei=bkg_pei
			the_457_dat.bkg_pee=bkg_pee
			the_457_dat.bkg=bkg3
		  endif
		endif
		common the_458,the_458_ind,the_458_dat 
		if n_elements(the_458_dat) ne 0 then begin
		  if the_458_ind ne -1 then begin
			time=(the_458_dat.time+the_458_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_458_dat.bkg_pse=bkg_pse
			the_458_dat.bkg_pei=bkg_pei
			the_458_dat.bkg_pee=bkg_pee
			the_458_dat.bkg=bkg3
			store_data,'th'+probes[i]+'_pee_bkg',data={x:time,y:[[bkg_pei],[bkg_pse],[bkg_pee],[bkg3]]}
				ylim,'th'+probes[i]+'_pee_bkg',1.,10000.,1
				options,'th'+probes[i]+'_pee_bkg','ytitle','Bkg pee th'+probes[i]+'!C!C Counts'
				options,'th'+probes[i]+'_pee_bkg','colors',[cols.red,cols.green,cols.magenta,cols.black]
				options,'th'+probes[i]+'_pee_bkg','labels',['pei', 'pse', 'pee', 'bkg']
				options,'th'+probes[i]+'_pee_bkg','labflag', 1
		  endif
		endif
		common the_459,the_459_ind,the_459_dat 
		if n_elements(the_459_dat) ne 0 then begin
		  if the_459_ind ne -1 then begin
			time=(the_459_dat.time+the_459_dat.end_time)/2.
			bkg_pse = interp(/no_extrapolate,interp_threshold=5.1,bkg1,time1,time)
			ind9 = where(0 eq finite(bkg_pse),count) & if count gt 1 then bkg_pse[ind9]=0.
;			att_pse = interp(/no_extrapolate,interp_threshold=5.1,att_on,time1,time)
			att_pse = interp((dis3 gt 5.3),time3,time)
			bkg_pei = interp(/no_extrapolate,interp_threshold=5.1,bkg2,time2,time)
			bkg_pee = interp(/no_extrapolate,interp_threshold=5.1,bkg4,time4,time)
			indtmp = where(bkg_pei gt 300.,count) & tmp_pse=bkg_pse
			if count gt 1 then tmp_pse[indtmp] = bkg_pei[indtmp] > bkg_pse[indtmp] 
			if (max(bkg1) eq 0.) then bkg3=bkg_pei else if (max(bkg2) eq 0.) then bkg3=bkg_pse else $
				bkg3=att_pse*(tmp_pse<bkg_pei)+(1.-att_pse)*bkg_pei
			the_459_dat.bkg_pse=bkg_pse
			the_459_dat.bkg_pei=bkg_pei
			the_459_dat.bkg_pee=bkg_pee
			the_459_dat.bkg=bkg3
		  endif
		endif
	endif

	ex_time = systime(1) - ex_start
	dprint,'Loading ESA background complete:  '+strtrim(ex_time,2)+' seconds execution time.', dlevel=2
	tplot,['th'+probes[i]+'_pei_bkg'],title='THEMIS '+strupcase(probes[i])+'  PEI Background'

endfor
end
