;+
;PROCEDURE:	load_fa_k0_dcf
;PURPOSE:	
;	Load summary data from the FAST DC fields instrument into TPLOT
;	structures. Up to eight TPLOT quantities are stored, namely
;	EX, EZ, DENSITY, BX, BY, BZ, S/C POTENTIAL, SPIN ANGLE, and MODEBAR. 
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
;				Default = indexfiledir+'/fa_k0_dcf_file'
;				indexfiledir = '$FAST_CDF_MAST_DIR' 
;	orbit		int, orbit for file load
;	var		strarr(n) of cdf variable names
;             default is ['EX','EZ','DENSITY','BX','BY','BZ','S/C POTENTIAL','SPIN ANGLE']
;
;	dvar		strarr(n) of cdf dependent variable names
;			set dvar(n)='' if no dependent variable for variable
;			dvar must be same dimension as var
;			default=['','','','','','']
;
;CREATED BY:	J. McFadden 96-9-8
; modified for fields  B. Peria 96-10-7
;
;-

pro load_fa_k0_dcf, $
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
    endif else dir=dir+'/dcf/'
    if not keyword_set(orbit) and not keyword_set(trange) then begin
        print,'Must enter filenames, trange, or orbit keyword!!'
        return
    endif
    if keyword_set(orbit) then begin
        sorb = STRMID( STRCOMPRESS( orbit + 1000000, /RE), 2, 5)
        filenames = findfile(dir+'fa_k0_dcf_'+sorb+'*.cdf')
    endif else begin
        if keyword_set(trange) then begin
            if not keyword_set(indexfile) then begin
                indexfiledir = getenv('FAST_CDF_MAST_DIR')	
                mfile = indexfiledir+'/fa_k0_dcf_files'
            endif else mfile = indexfile
            get_file_names,filenames,TIME_RANGE=trange,MASTERFILE=mfile
        endif 
    endelse
endif else begin
    if keyword_set(dir) then filenames=dir+filenames
endelse

if not keyword_set(var) then begin
    var=['EX','EZ','BX','BY','BZ','S/C POTENTIAL','SPIN ANGLE']
endif

nvar=dimen1(var)
if not keyword_set(dvar) then dvar=strarr(nvar)
if dimen1(dvar) ne nvar then begin 
    message,' dvar and var must be same dimension',/continue
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
    if d eq 0 then time=tmp else time=[time,tmp]
endfor


not_there = lonarr(nvar)
for n=0,nvar-1 do begin
    for d=0,nfiles-1 do begin
        loadcdf,filenames(d),var(n),tmp
        if dvar(n) ne '' then begin
            loadcdf,filenames(d),dvar(n),tmpv
        endif
        if d eq 0 then begin
            tmp_tot  = tmp
            if dvar(n) ne '' then tmpv_tot = tmpv
        endif else begin
            tmp_tot  = [tmp_tot,tmp]
            if dvar(n) ne '' then tmpv_tot = [tmpv_tot,tmpv]
        endelse
    endfor

    if dvar(n) ne '' then begin
        store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot,v:tmpv_tot}
        options,var(n),'spec',1	
        options,var(n),'x_no_interp',1
        options,var(n),'y_no_interp',1
    endif else begin
        store_data,var(n),data={ytitle:var(n),x:time,y:tmp_tot}
    endelse
    oops:
endfor

;
; Get the modebar from the latest ACF CDF...
;
ftyp = 'dcf'
acfilenames = filenames
maxver = 20
for d=0,nfiles-1 do begin
    while strpos(acfilenames(d),ftyp) ge 0 do begin
        ftmp = acfilenames(d)
        acfilenames(d) = strmid(ftmp,0,strpos(ftmp,ftyp)) + $
          'acf' + strmid(ftmp, strpos(ftmp,ftyp)+3,strlen(ftmp))
    endwhile 
    ftmp = acfilenames(d)
    ver = maxver
    repeat begin
        verpos = strpos(ftmp,'_v')+2
        newver = strcompress(string(ver-1),/remove)
        if ver lt 9 then newver = '0'+newver
        ftmp = strmid(ftmp,0,verpos) +  newver + '.cdf'
        err_stat=0
        acfilenames(d) = ftmp
        ver = fix(strmid(ftmp,verpos,2))
    endrep until (((files_exist(acfilenames(d)))(0) ne '') $
                  or (ver lt 1))
    no_bar = 0
    if ver lt 1 then no_bar = 1
endfor

if not no_bar then begin
    for d=0,nfiles-1 do begin
        loadcdf,acfilenames(d),'TIME',tmpactime
        loadcdf,acfilenames(d),'MODEBAR',tmp
        loadcdf,acfilenames(d),'VMBAR',tmpv
        
        if d eq 0 then begin
            actime = tmpactime
            tmp_tot  = tmp
            tmpv_tot = tmpv
        endif else begin
            actime = [tmpactime,actime]
            tmp_tot  = [tmp_tot,tmp]
            tmpv_tot = [tmpv_tot,tmpv]
        endelse
    endfor
    store_data,'MODEBAR',data={x:actime,y:tmp_tot,v:tmpv_tot}
endif else begin
    message,'No Valid ACF CDF...no modebar will be produced...',/continue
endelse
;
; end of ACF CDF modebar grab....
;

; Get the orbit data

tmin=min(time,/nan)
tmax=max(time,/nan)

if not keyword_set(no_orbit) then get_fa_orbit,time,/time_array,/all

; Zero the time range

tplot_options,trange=[0,0]

default_dc_limits

return
end



