;+
; PROCEDURE:
;       mvn_ngi_load
; PURPOSE:
;       Loads NGIMS L2 (or L1b) data
;       Each column in csv files will be stored in tplot variables:
;          'mvn_ngi_(filetype)_(focusmode)_(tagname)'
;       Time-series densities for each mass will be storead in
;          'mvn_ngi_(filetype)_(focusmode)_abundance_mass???'
; CALLING SEQUENCE:
;       mvn_ngi_load
; INPUTS:
;       None
; OPTIONAL KEYWORDS:
;       level: 'l2', 'l1b', or 'l3' (Def. 'l2')
;       trange: time range (if not present then timerange() is called)
;       filetype: (Def. ['csn','cso','ion'] for l2, ['osion','osnb'] for l1b, ['res-sht'] for l3)
;       files: paths to local files to read in
;              if set, does not retreive files from server
;              if multiple versions are found, the latest version file will be loaded
;       version: specifies string of two digit version number (e.g., '04')
;       revision: specifies string of two digit revision number (e.g., '03')
;       mass: masses of mass-separated tplot variables (Def. all unique masses)
;       quant_mass: quantities of mass-separated tplot variables
;                   (Def. 'abundance' for l2, 'counts' for 'l1b')
;       mspec: if set, generates mass spectrograms
;       nolatest: skip latest version check (not recommended)
;       cps_dt: (obsolete, but still works)
;       other keywords are passed to 'mvn_pfp_file_retrieve'
; CREATED BY:
;       Yuki Harada on 2015-01-29
; NOTES:
;       Requires IDL 7.1 or later to read in .csv files
;       Use 'mvn_ngi_read_csv' to load ql data
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2024-01-03 16:19:22 -0800 (Wed, 03 Jan 2024) $
; $LastChangedRevision: 32331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/ngi/mvn_ngi_load.pro $
;-

pro mvn_ngi_load, mspec=mspec, trange=trange, filetype=filetype, verbose=verbose, _extra=_extra, files=files, cps_dt=cps_dt, nolatest=nolatest, version=version, revision=revision, level=level, mass=mass_array, quant_mass=quant_mass

  if ~keyword_set(level) then level = 'l2' else level = strlowcase(level)
  if ~keyword_set(filetype) then begin
     if level eq 'l2' then filetype = ['csn','cso','ion']
     if level eq 'l1b' then filetype = ['osion','osnb']
     if level eq 'l3' then filetype = ['res-sht'] ;- FIXME: add 'res-den'
  endif
  if ~keyword_set(quant_mass) then begin
     if level eq 'l2' then quant_mass = ['abundance']
     if level eq 'l1b' then quant_mass = ['counts']
     if level eq 'l3' then quant_mass = ['temperature']
  endif
  if keyword_set(cps_dt) then quant_mass = [quant_mass,'cps_dt']
  latest_flg = 0
  if ~keyword_set(nolatest) and ~keyword_set(version) and ~keyword_set(revision) then latest_flg = 1
  if ~keyword_set(version) then version = '??'   ;- to be overwritten by latest version unless /nolatest is set
  if ~keyword_set(revision) then revision = '??' ;- to be overwritten by latest revision unless /nolatest is set
  if keyword_set(nolatest) then if nolatest eq -1 then latest_flg = 2 ;- experimental mode, latest version for each meas.
  
  for i_filetype=0,n_elements(filetype)-1 do begin ;- loop through filetypes

    ;remove any remote-index.html files so that multiple days in a given month will load jmm, 2019-04-09
     remote_index_file = file_search(root_data_dir()+'maven/data/sci/ngi/'+level+'/????/??/.remote-index.html')
     if(is_string(remote_index_file)) then begin
        for j = 0, n_elements(remote_index_file)-1 do begin
           dprint, dlevel = 2, 'removing: '+remote_index_file[j]
           file_delete, remote_index_file[j]
        endfor
     endif

     ;;; retrieve files
     if ~keyword_set(files) then begin
        urls = ''
        if keyword_set(latest_flg) then urls = mvn_ngi_remote_list(trange=trange,filetype=filetype[i_filetype],latestversion=version,latestrevision=revision,_extra=_extra,verbose=verbose,level=level) ;- check latest version and revision numbers
        if latest_flg eq 2 and total(strlen(urls)) gt 0 then begin ;- experimental mode, latest version for each meas.
           undefine,f
           meas_number = replicate('',n_elements(urls))
           for i=0,n_elements(urls)-1 do meas_number[i] = $
              strmid( file_basename(urls[i]) , strpos(file_basename(urls[i]),'abund-')+6, $
                      strpos(file_basename(urls[i]),'_20')-strpos(file_basename(urls[i]),'abund-')-6 )
           uniq_meas_number = meas_number[uniq(meas_number)]
           for imeas=0,n_elements(uniq_meas_number)-1 do begin
              files_now = file_basename(urls[where(strmatch(urls,'*abund-'+uniq_meas_number[imeas]+'*'))])
              vvv_rrr = replicate('',n_elements(files_now))
              for i=0,n_elements(files_now)-1 do vvv_rrr[i] = strmid( files_now[i] , strpos(files_now[i],'_v') , 8 )
              sort_vvv_rrr = sort(vvv_rrr)
              latest_file = files_now[sort_vvv_rrr[-1]]
              pformat = 'maven/data/sci/ngi/'+level+'/YYYY/MM/'+latest_file
              YYYYMMDD_now = strmid( latest_file , strpos(latest_file,'_20')+1 , 8 )
              trange_now = time_double(YYYYMMDD_now,tf='YYYYMMDD')+[0,86400d]
              append_array, f, mvn_pfp_file_retrieve(pformat,/daily_names,/last_version,/valid_only,trange=trange_now,verbose=verbose, _extra=_extra)
           endfor
           if size(f,/type) eq 0 then f = ''
        endif else if strlen(version) eq 2 then begin
           pformat = 'maven/data/sci/ngi/'+level+'/YYYY/MM/mvn_ngi_'+level+'_'+filetype[i_filetype]+'-*_YYYYMMDDThh????_v'+version+'_r'+revision+'.csv'
           f = mvn_pfp_file_retrieve(pformat,/hourly_names,/last_version,/valid_only,trange=trange,verbose=verbose, _extra=_extra)
        endif else f = ''
     endif else begin           ;- local files
        w = where( strmatch(files,'*'+filetype[i_filetype]+'*',/fold_case) eq 1, nw )
        if nw gt 0 then begin
           ftmp = files[w] ;- input files that possibly have mixed, case-sensitive names
           ftmp = ftmp[sort(strlowcase(ftmp))] ;- case-insensitively sort in alphabetical order
           prefnames = strmid(ftmp,0,strpos(ftmp[0],'_v')) ;- assuming all files have the same case-insensitive format
           lastidx = uniq(strlowcase(prefnames)) ;- case-insensitively select the latest version
           f = ftmp[lastidx]
        endif else f = ''
     endelse
     ;;; check files
     if total(strlen(f)) eq 0 then begin
        dprint,dlevel=2,verbose=verbose,filetype[i_filetype]+' files not found'
        continue
     endif

     ;;; read in files and store data into structures
     for i_file=0,n_elements(f)-1 do begin
        dprint,dlevel=1,verbose=verbose,'reading in '+f[i_file]
        if float(!version.release) lt 8. then begin
           if i_file eq 0 then d = read_csv(f[i_file],header=dh) else begin
              dold = d
              dnew = read_csv(f[i_file],header=dh)
              tagnames = tag_names(d)
              for i_c = 0,n_elements(dh)-1 do str_element, d, tagnames[i_c], [dold.(i_c),dnew.(i_c)],/add
           endelse
        endif else begin
           if i_file eq 0 then begin
              d = read_csv(f[i_file], header=dh)
              d = orderedhash(d)
              keys = d.keys()
              for i_c = 0, n_elements(keys)-1 do d[keys[i_c]] = list(d[keys[i_c]])
           endif else begin
              dnew = read_csv(f[i_file], header=dh)
              dnew = orderedhash(dnew)
              for i_c = 0, n_elements(keys)-1 do d[keys[i_c]].add, dnew[keys[i_c]]
              undefine, dnew
           endelse
        endelse 
     endfor
     if size(d, /type) ne 8 then begin
        for i_c = 0, n_elements(keys)-1 do d[keys[i_c]] = d[keys[i_c]].toarray(/dim)
        d = d.tostruct()
        tagnames = tag_names(d)
     endif 
     
     ;;; check time
     idx = where(strmatch(dh,'t_unix'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique t_unix column in csv files: ',f
        continue
     endif
     t_unix = double(d.(idx))

     ;;; check mode
     if level ne 'l3' then begin ;- no focus mode column in L3 res-sht files
        if level eq 'l1b' then modestr = 'focus_mode' else modestr = 'focusmode'
        idx = where(strmatch(dh,modestr),idx_cnt)
        if idx_cnt ne 1 then begin
           dprint,dlevel=1,verbose=verbose,'No unique focusmode column in csv files: ',f
           continue
        endif
        focusmode = d.(idx)
     endif

     ;;; check mass
     idx = where(strmatch(dh,'*mass'),idx_cnt)
     if idx_cnt ne 1 then begin
        dprint,dlevel=1,verbose=verbose,'No unique mass column in csv files: ',f
        continue
     endif
     mass = double(d.(idx))

     ;;; get species if exists
     undefine, species
     w = where(strmatch(dh,'species'),nw)
     if nw eq 1 then species = d.(w)

     modes = ['csn', 'osnt', 'osnb', 'osion']

     ;;; store tplot variables

     if level eq 'l3' then begin ;- l3, currently "res-sht" only, w/o mode info.
        dh = strlowcase(dh)
        ;;; store all columns (not necessarily monotonic)
        for i_c=0,n_elements(dh)-1 do $
           store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+dh[i_c],data={x:t_unix,y:d.(i_c)}

        ;;; store quantities for each unique mass
        if keyword_set(mass_array) then uniqmass = mass_array else uniqmass = mass[uniq(mass,sort(mass))]
        for i_mass=0,n_elements(uniqmass)-1 do begin
           idx = where( mass eq uniqmass[i_mass],idx_cnt )
           if idx_cnt eq 0 then continue

           if long(uniqmass[i_mass]) eq uniqmass[i_mass] then massstr = string(uniqmass[i_mass],f='(i3.3)') else massstr = string(uniqmass[i_mass],f='(i3.3)')+'_'+string((uniqmass[i_mass]-long(uniqmass[i_mass]))*1000,f='(i3.3)')

           for iq=0,n_elements(quant_mass)-1 do begin
              wq = where(strmatch(dh,quant_mass[iq]),nwq)
              if nwq ne 1 then continue
              quant = double(d.(wq))
              store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+quant_mass[iq]+'_mass'+massstr,data={x:t_unix[idx],y:quant[idx]},dlim={mass:uniqmass[i_mass],filetype:filetype[i_filetype],level:level}
              if size(species,/type) ne 0 then begin
                 spc = species[idx]
                 ws = where( spc eq spc[0] , nws, comp=cws, ncomp=ncws )
                 if ncws gt 0 then begin ;- assuming at most 2 species for 1 mass
                    store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+quant_mass[iq]+'_mass'+massstr+'_'+spc[0],data={x:t_unix[idx[ws]],y:quant[idx[ws]]},dlim={mass:uniqmass[i_mass],filetype:filetype[i_filetype],level:level}
                    store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+quant_mass[iq]+'_mass'+massstr+'_'+spc[cws[0]],data={x:t_unix[idx[cws]],y:quant[idx[cws]]},dlim={mass:uniqmass[i_mass],filetype:filetype[i_filetype],level:level}
                 endif
              endif
           endfor               ;- iq
        endfor                  ;- i_mass
        continue
     endif

     ;;; l2 and l1b
     for i_mode=0,n_elements(modes)-1 do begin
        idx = where(focusmode eq modes[i_mode], idx_cnt)
        if idx_cnt eq 0 then continue

        ;;; store all columns (not necessarily monotonic)
        for i_c=0,n_elements(dh)-1 do $
           store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_'+dh[i_c],data={x:t_unix,y:d.(i_c)}

        ;;; store quantities for each unique mass
        if keyword_set(mass_array) then uniqmass = mass_array else uniqmass = mass[uniq(mass,sort(mass))]
        for i_mass=0,n_elements(uniqmass)-1 do begin
           idx = where( mass eq uniqmass[i_mass] and focusmode eq modes[i_mode],idx_cnt )
           if idx_cnt eq 0 then continue

           if long(uniqmass[i_mass]) eq uniqmass[i_mass] then massstr = string(uniqmass[i_mass],f='(i3.3)') else massstr = string(uniqmass[i_mass],f='(i3.3)')+'_'+string((uniqmass[i_mass]-long(uniqmass[i_mass]))*1000,f='(i3.3)')

           for iq=0,n_elements(quant_mass)-1 do begin
              wq = where(strmatch(dh,quant_mass[iq]),nwq)
              if nwq ne 1 then continue
              quant = double(d.(wq))
              store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_'+quant_mass[iq]+'_mass'+massstr,data={x:t_unix[idx],y:quant[idx]},dlim={mass:uniqmass[i_mass],filetype:filetype[i_filetype],focusmode:modes[i_mode],level:level}
              if size(species,/type) ne 0 then begin
                 spc = species[idx]
                 ws = where( spc eq spc[0] , nws, comp=cws, ncomp=ncws )
                 if ncws gt 0 then begin ;- assuming at most 2 species for 1 mass
                    store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_'+quant_mass[iq]+'_mass'+massstr+'_'+spc[0],data={x:t_unix[idx[ws]],y:quant[idx[ws]]},dlim={mass:uniqmass[i_mass],filetype:filetype[i_filetype],focusmode:modes[i_mode],level:level}
                    store_data,verbose=verbose,'mvn_ngi_'+filetype[i_filetype]+'_'+modes[i_mode]+'_'+quant_mass[iq]+'_mass'+massstr+'_'+spc[cws[0]],data={x:t_unix[idx[cws]],y:quant[idx[cws]]},dlim={mass:uniqmass[i_mass],filetype:filetype[i_filetype],focusmode:modes[i_mode],level:level}
                 endif
              endif
           endfor               ;- iq

        endfor                  ;- i_mass
     endfor                     ;- i_mode

  endfor                        ;- i_filetype

  if keyword_set(mspec) then mvn_ngi_mspec,/del

end
