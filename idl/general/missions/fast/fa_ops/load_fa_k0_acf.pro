;+
;PROCEDURE:	load_fa_k0_acf
;PURPOSE:	
;	Load summary data from the FAST AC fields instrument into TPLOT
;	structures. Up to eight TPLOT quantities are stored, namely VLF
;	E, VLF E POWER, VLF B POWER, VLF B, HF E, HF B, HF E POWER, HF
;	B POWER. 
;
;	
;INPUT:	
;	none 
;KEYWORDS:
;	filenames	strarr(m), string array of filenames of cdf files to be entered
;				Files are obtained from "dir" if dir is set, 
;					otherwise files obtained from local dir.
;				If filenames not set, then orbit or trange keyword must
;					be set.
;	dir		string, directory where filenames can be found
;				If dir not set, default is "environvar" or local directory
;	environvar	string, name of environment variable to set "dir"
;				Used if filenames not set
;				Default environvar = '$FAST_CDF_HOME'
;	trange		trange[2], time range used to get files from index list
;	indexfile	string, complete path name for indexfile of times and filenames
;				Used if trange is set.
;				Default = indexfiledir+'/fa_k0_acf_file'
;				indexfiledir = '$FAST_CDF_MAST_DIR' 
;	orbit		int, orbit for file load
;	var		strarr(n) of cdf variable names
;
;	default=['VLF_E_SPEC','VLF_PWR','VLF_B_SPEC','HF_E_SPEC','HF_PWR', $
;         'HF_B_SPEC','ELF_E_SPEC','ELF_B_SPEC','ELF_PWR','MODEBAR']
;
;
;	dvar		strarr(n) of cdf dependent variable names
;			set dvar(n)='' if no dependent variable for variable
;			dvar must be same dimension as var
;                       default = ['VLF_E_FREQ','','VLF_B_FREQ','HF_E_FREQ','','HF_B_FREQ',
;                       'ELF_E_FREQ','ELF_B_FREQ','','VMBAR']
;
;
;CREATED BY:	J. McFadden 96-9-8
; modified for fields  B. Peria 96-10-7
;
;-

pro load_fa_k0_acf, $
                    filenames=filenames, $
                    dir = dir, $
                    environvar = environvar, $
                    trange = trange, $
                    indexfile = indexfile, $
                    orbit = orbit, $
                    var=var, $
                    dvar=dvar, $
                    no_orbit = no_orbit

if not keyword_set(filenames) then begin
    if not keyword_set(environvar) then environvar = 'FAST_CDF_HOME'
    if not keyword_set(dir) then dir = getenv(environvar)
    if not keyword_set(dir) then begin
        print, ' Using local directory'
        dir=''
    endif else dir=dir+'/acf/'
    if not keyword_set(orbit) and not keyword_set(trange) then begin
        print,'Must enter filenames, trange, or orbit keyword!!'
        return
    endif
    if keyword_set(orbit) then begin
        sorb = STRMID( STRCOMPRESS( orbit + 1000000, /RE), 2, 5)
        filenames = findfile(dir+'fa_k0_acf_'+sorb+'*.cdf')
    endif else begin
        if keyword_set(trange) then begin
            if not keyword_set(indexfile) then begin
                indexfiledir = getenv('FAST_CDF_MAST_DIR')	
                mfile = indexfiledir+'/fa_k0_acf_files'
            endif else mfile = indexfile
            get_file_names,filenames,TIME_RANGE=trange,MASTERFILE=mfile
        endif 
    endelse
endif else begin
    if keyword_set(dir) then filenames=dir+filenames
endelse

if not keyword_set(var) then begin
    var=['VLF_E_SPEC','VLF_PWR','VLF_B_SPEC','HF_E_SPEC','HF_PWR', $
         'HF_B_SPEC','ELF_E_SPEC','ELF_B_SPEC','ELF_PWR','MODEBAR']
    dvar=['VLF_E_FREQ','','VLF_B_FREQ','HF_E_FREQ','','HF_B_FREQ', $
          'ELF_E_FREQ','ELF_B_FREQ','','VMBAR']
endif 
nvar=dimen1(var)
if not keyword_set(dvar) then dvar=strarr(nvar)
if dimen1(dvar) ne nvar then begin 
    print,' dvar and var must be same dimension'
    for i=0,10 do begin
        print,dvar(i),' ',var(i)
    endfor
    
    return
endif
catch,err_stat
if (err_stat ne 0) then begin
    case err_stat of
        -473:begin
            warn = 'Variable '+var(n)+' was not found in '+filenames(d)
            message,warn,/continue
        end
        else:begin
            message,!err_string,/continue
            catch,/cancel
            return
        end
    endcase
    err_stat=0
    goto,oops
endif

nfiles = dimen1(filenames)
for d=0,nfiles-1 do begin
    print,'Loading file: ',filenames(d),'...'
    loadcdf,filenames(d),'TIME',tmp
    if d eq 0 then begin
        time=tmp 
    endif else begin
        ntime=dimen1(time)
        gaptime1=2.*time(ntime-1) - time(ntime-2)
        gaptime2=2*tmp(0) - tmp(1)
        time=[time,gaptime1,gaptime2,tmp]
    endelse
endfor

for n=0,nvar-1 do begin
    for d=0,nfiles-1 do begin
        loadcdf,filenames(d),var(n),tmp
        if dvar(n) ne '' then begin
            loadcdf,filenames(d),dvar(n),tmpv
            if (size(tmpv))(0) gt 1 then begin
                tmpv = reform(tmpv(0,*)) ; deal with awkward
                                ; old_makecdf output
            endif
        endif
        if d eq 0 then begin
            tmp_tot  = tmp
            if dvar(n) ne '' then tmpv_tot = tmpv
        endif else begin
            totdim = n_elements(tmp_tot[0,*])
            tmpdim = n_elements(tmp[0,*])
            if tmpdim ne totdim then begin
                if tmpdim lt totdim then begin
                    tmp_tot = tmp_tot[*,0:tmpdim-1l]
                endif else begin
                    tmp = tmp[*,0:totdim-1l]
                endelse
            endif 
            gapdata=tmp_tot[0:1,*]
            gapdata[*,*]=!values.f_nan
            tmp_tot  = [tmp_tot,gapdata,tmp]

            if dvar(n) ne '' then tmpv_tot = tmpv ; no concatentation!
        endelse
    endfor

    if dvar(n) ne '' then begin $
      store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot,v:tmpv_tot}
        if strpos(var(n),'SPEC') ge 0 then begin
            options,var(n),'ystyle',1
            options,var(n),'ylog',1
        endif
        options,var(n),'spec',1	
        options,var(n),'x_no_interp',1
        options,var(n),'y_no_interp',1
    endif else begin
        store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
    endelse
    oops:
endfor

; Get the orbit data, and store cyclotron freq also

if not keyword_set(no_orbit) then begin
    tmin=min(time)
    tmax=max(time)
    get_fa_orbit,time,/all,/time_array

    twopi = 2.d*!dpi
    jev = 1.6022d-19
    em = jev/9.11d-31
    mi_me = 1836.1d

    bcolor = byte(float(!d.n_colors) *0.9) ; green for ct 39
    get_data,'B_model',data=b_model
    bmag = sqrt(total(b_model.y^2,2))*1.d-09 ; Tesla
    wce = (em*bmag/twopi)/1000. ; electron cyclotron, kHz
    store_data,'w_ce',data={x:b_model.x,y:wce}, $
      dlimit={colors:[bcolor],thick:1}
    wcp = ((em/mi_me)*bmag/twopi)/1000. ; proton cyclotron, kHz
    store_data,'w_cp',data={x:b_model.x,y:wcp}, $
      dlimit={colors:[bcolor],thick:1}
endif

default_ac_limits

; Zero the time range

tplot_options,trange=[0,0]

return
end



