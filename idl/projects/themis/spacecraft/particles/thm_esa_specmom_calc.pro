;Name: thm_esa_specmom_calc.pro
;Purpose: This is a wrapper routine for getting some ESA L2 data quanitities.
;Inputs:  DATE: The date (ie, '2007-07-01')
;         DUR: The duration in days.
;         SC: The spacecraft  (ie, 'a b c d e')
;         MTYPE: Moments type (ie, 'spectrogram density velocity temperature')
;         SPECIES: Ions or electrons
;         DISTRIBUTION_TYPE: Full, reduced or burst
;Output:  Tplot variables are created in the IDL environment.
;Caveats: Reduced moment calculations don't work very well yet.        


pro thm_esa_specmom_calc,date=date,dur=dur,probes=probes,mtypes=mtypes,species=species,distribution_types=distribution_types,_extra=_extra

;--------------------------------------------------------------------------------
;check inputs

if keyword_set(probes) then sc=probes  ; quick switch of variable name
vsc = ['a','b','c','d','e']
if not keyword_set(sc) then sc=vsc
sc=ssl_check_valid_name(strtrim(strlowcase(sc),2),vsc,/include_all)
if sc(0) eq 'all' then sc=vsc
if sc(0) eq '' then return

vmtyp=['spe','den','vel','tem']
if not keyword_set(mtypes) then mtyp=vmtyp $
   else begin
        if size(mtypes,/dimen) eq 0 then mtypes=strsplit(mtypes,' ',/extract)
        mtyp=ssl_check_valid_name(strmid(strtrim(strlowcase(mtypes),2),0,3),vmtyp,/include_all)
        end
if mtyp(0) eq 'all' then mtyp=vmtyp
if mtyp(0) eq '' then return

vdtyp=['f','r','b']
if not keyword_set(distribution_types) then typ='f' $
   else begin
        if size(distribution_types,/dimen) eq 0 then distribution_types=strsplit(distribution_types,' ',/extract)
        if total(strmatch(strtrim(strlowcase(distribution_types),2),'all')) gt 0 then typ='all' $
           else typ=strmid(strtrim(strlowcase(distribution_types),2),0,1)
        typ=ssl_check_valid_name(typ,vdtyp,/include_all)
        endelse
if typ(0) eq '' then return

vspe=['i','e']
if not keyword_set(species) then spe=vspe $
   else begin
        if size(species,/dimen) eq 0 then species=strsplit(species,' ',/extract)
        if total(strmatch(strtrim(strlowcase(species),2),'all')) gt 0 then spe='all' $
           else spe=strmid(strtrim(strlowcase(species),2),0,1)
        spe=ssl_check_valid_name(spe,vspe,/include_all)
        endelse
if spe(0) eq '' then return

if not keyword_set(date) then begin
  dprint, "Keyword DATE must be set.  Example: date='2007-03-23'"
  return
endif

if not keyword_set(dur) then dur=1




;--------------------------------------------------------------------------------

timespan,date,dur
thm_load_state,probe=sc
thm_load_esa_pkt,probe=sc

;--------------------------------------------------------------------------------

for i=0,n_elements(sc)-1 do begin
 for j=0,n_elements(spe)-1 do begin
  for k=0,n_elements(typ)-1 do begin
  
  if typ(k) eq 'f' then gap_time=1000. else gap_time=10.

;--------------------------------------------------------------------------------

;calc spectrogram


    if total(strmatch(mtyp,'spe')) gt 0 then begin
	get_dat=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k))
	name1=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k)+'_en_eflux')
	thm_get_en_spec,get_dat,units='eflux',retrace=1,name=name1,gap_time=gap_time,t1=t1,t2=t2,_extra=_extra

	options,name1,'ztitle','Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
	options,name1,'ytitle','ESA '+spe(j)+'+ th'+sc(i)+'!C!C eV'
	options,name1,'spec',1
	options,name1,'x_no_interp',1
	options,name1,'y_no_interp',1
	options,name1,'zlog',1
	options,name1,'ylog',1
    endif
    
;--------------------------------------------------------------------------------

;calc density moment

    if total(strmatch(mtyp,'den')) gt 0 then begin
        get_dat=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k))
	name1=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k)+'_density')
	thm_get_2dt,'n_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[20.,21000.],_extra=_extra
;delete ytitle in the data structure, from get_2dt.pro
        get_data, name1, data = d & options, d, 'ytitle' & store_data, name1, data = d
	options,name1,'ytitle','N'+spe(j)+' th'+sc(i)+'!C!C1/cm!U3'
	options,name1,'ylog',1
    endif
    
;--------------------------------------------------------------------------------

;calc velocity moment

    if total(strmatch(mtyp,'vel')) gt 0 then begin
        get_dat=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k))
	name1=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k)+'_velocity_dsl')
	thm_get_2dt,'v_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[20.,21000.],_extra=_extra

	get_data,name1,data=d,dlimits=a
	cotrans_set_coord,a,'dsl'
;delete ytitle in the data structure, from get_2dt.pro
        options, d, 'ytitle'
	store_data,name1,data=d,dlimits=a

	options,name1,'ytitle','V'+spe(j)+' th'+sc(i)+'!C!Ckm/s'
	options,name1,labels=['V'+spe(j)+'!dx!n', 'V'+spe(j)+'!dy!n', 'V'+spe(j)+'!dz!n'],constant=0.
    endif

;--------------------------------------------------------------------------------

;calc temperature moment

    if total(strmatch(mtyp,'tem')) gt 0 then begin
        get_dat=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k))
 	name1=strjoin('th'+sc(i)+'_pe'+spe(j)+typ(k)+'_T_dsl')
	thm_get_2dt,'t_3d_new',get_dat,name=name1,gap_time=gap_time,t1=t1,t2=t2,energy=[20.,21000.],_extra=_extra

	get_data,name1,data=d,dlimits=a
	cotrans_set_coord,a,'dsl'
;delete ytitle in the data structure, from get_2dt.pro
        options, d, 'ytitle'
	store_data,name1,data=d,dlimits=a

	options,name1,'ytitle','T'+spe(j)+' th'+sc(i)+'!C!CeV'
	options,name1,'ylog',1
    endif
    
;--------------------------------------------------------------------------------

  endfor ; k
 endfor ; j
endfor ; i

;--------------------------------------------------------------------------------




end
