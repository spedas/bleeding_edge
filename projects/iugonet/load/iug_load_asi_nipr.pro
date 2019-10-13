;+
; PROCEDURE: IUG_LOAD_ASI_NIPR
;   iug_load_asi_nipr, site = site, $
;                     wavelength=wavelength, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly, $
;                     no_download=no_download
;
; PURPOSE:
;   Loads the all-sky imager data obtained by NIPR.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_asi_nipr, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['syo', 'hus']
;           or a single string delimited by spaces, e.g., 'syo hus'.
;           Available sites as of April, 2013 : syo
;   wavelength = Wavelength in Angstrom, i.e., 4278, 5577, 6300, etc.
;           The 0000 means white light images taken without filter.
;           Only 0000 is available as of October, 2014.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_asi_nipr, site='hus', wavelength=0000, $
;                 trange=['2012-01-22/20:30','2012-01-22/21:00']
;
; Written by Y.-M. Tanaka, July, 2014 (ytanaka at nipr.ac.jp)
;-

;************************************************
;*** Load procedure for imaging riometer data ***
;***             obtained by NIPR             ***
;************************************************
pro iug_load_asi_nipr, site=site, wavelength=wavelength, $
        trange=trange, verbose=verbose, downloadonly=downloadonly, $
	no_download=no_download

;===== Keyword check =====
;----- default -----;
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

;----- site -----;
site_code_all = strsplit('hus tjo tro lyr spa syo mcm', /extract)
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

print, site_code

;----- wavelength -----;
if(not keyword_set(wavelength)) then wavelength=[0000]
wlenstr=string(wavelength, format='(i4.4)')

wlenstr_all=strsplit('0000 4278 4300 5577 5580 6300', /extract)
wlenstr=ssl_check_valid_name(wlenstr,wlenstr_all, $
                             /ignore_case, /include_all)
if wlenstr[0] eq '' then begin
    print, 'The wavelength:'+wlenstr+' is not supported!'
    return
endif

;----- Set parameters for file_retrieve and download data files -----;
source = file_retrieve(/struct)
source.verbose = verbose
source.local_data_dir  = root_data_dir() + 'iugonet/nipr/'
source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
; source.remote_data_dir = 'http://polaris.nipr.ac.jp/~ytanaka/data/'
if keyword_set(no_download) then source.no_download = 1
if keyword_set(downloadonly) then source.downloadonly = 1
relpathnames1 = file_dailynames(file_format='YYYY/MM/DD', trange=trange, /hour_res)
relpathnames2 = file_dailynames(file_format='YYYYMMDDhh', trange=trange, /hour_res)

instr='asi'

;===== Download files, read data, and create tplot vars at each site =====
;----- Loop -----
for i=0,n_elements(site_code)-1 do begin
  for j=0,n_elements(wavelength)-1 do begin
    relpathnames  = instr+'/'+site_code[i]+'/'+$
      relpathnames1 + '/nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_'+$
      relpathnames2 + '_v??.cdf'

print, relpathnames

    files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

    filestest=file_test(files)
    if total(filestest) ge 1 then begin
      files=files(where(filestest eq 1))
    endif

    ;----- Print PI info and rules of the road -----;
    if(file_test(files[0])) then begin
      gatt = cdf_var_atts(files[0])
      print, '**************************************************************************************'
      print, gatt.Logical_source_description
      print, ''
      print, 'Information about ', gatt.Station_code
      print, ''
      print, 'PI: ', gatt.PI_name
      print, ''
      print, 'Affiliations: ', gatt.PI_affiliation
      print, ''
      print, 'Rules of the Road for NIPR All-Sky Imager Data:'
      print_str_maxlet, gatt.TEXT
      print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
      print, '**************************************************************************************'
    endif

    ;----- Load data into tplot variables -----;
    if(downloadonly eq 0) then begin
      ;----- Rename tplot variables of hdz_tres -----;
      prefix_tmp='niprtmp_'
      cdf2tplot, file=files, verbose=source.verbose, prefix=prefix_tmp

      tplot_name_tmp=tnames(prefix_tmp+'*')
      len=strlen(tplot_name_tmp[0])

      if len eq 0 then begin
        ;----- Quit if no data have been loaded -----;
        print, 'No tplot var loaded for '+site_code[i]+'.'
      endif else begin
        ;----- Loop for params -----;
		for k=0, n_elements(tplot_name_tmp)-1 do begin
          ;----- Find param -----;
          len=strlen(tplot_name_tmp[k])
          pos=strpos(tplot_name_tmp[k],'_')
          param=strmid(tplot_name_tmp[k],pos+1,len-pos-1)

          if param eq 'image_raw' then begin
            tplot_name_new='nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]
          endif else begin
            tplot_name_new='nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_'+param
          endelse

          ;----- Rename tplot variables -----;
          copy_data, tplot_name_tmp[k], tplot_name_new
          store_data, tplot_name_tmp[k], /delete

        endfor

        ;----- Load positions -----;
        cdfi = cdf_load_vars(files[0], varformat='*')
        tm_vn = (strfilter(cdfi.vars.name, 'epoch_image'))[0]
        az_vn = (strfilter(cdfi.vars.name, 'azimuth_angle'))[0]
        el_vn = (strfilter(cdfi.vars.name, 'elevation_angle'))[0]
        glatcen_vn = (strfilter(cdfi.vars.name, 'glat_center'))[0]
        gloncen_vn = (strfilter(cdfi.vars.name, 'glon_center'))[0]
        glatcor_vn = (strfilter(cdfi.vars.name, 'glat_corner'))[0]
        gloncor_vn = (strfilter(cdfi.vars.name, 'glon_corner'))[0]
        alt_vn = (strfilter(cdfi.vars.name, 'altitude'))[0]

        tm_idx = (where(strcmp(cdfi.vars.name, tm_vn) , cnt))[0]
        az_idx = (where(strcmp(cdfi.vars.name, az_vn) , cnt))[0]
        el_idx = (where(strcmp(cdfi.vars.name, el_vn) , cnt))[0]
        glatcen_idx = (where(strcmp(cdfi.vars.name, glatcen_vn) , cnt))[0]
        gloncen_idx = (where(strcmp(cdfi.vars.name, gloncen_vn) , cnt))[0]
        glatcor_idx = (where(strcmp(cdfi.vars.name, glatcor_vn) , cnt))[0]
        gloncor_idx = (where(strcmp(cdfi.vars.name, gloncor_vn) , cnt))[0]
        alt_idx = (where(strcmp(cdfi.vars.name, alt_vn) , cnt))[0]

        tm_dat = *cdfi.vars[tm_idx].dataptr
        az_dat = *cdfi.vars[az_idx].dataptr
        el_dat = *cdfi.vars[el_idx].dataptr
        glatcen_dat = *cdfi.vars[glatcen_idx].dataptr
        gloncen_dat = *cdfi.vars[gloncen_idx].dataptr
        glatcor_dat = *cdfi.vars[glatcor_idx].dataptr
        gloncor_dat = *cdfi.vars[gloncor_idx].dataptr
        alt_dat = *cdfi.vars[alt_idx].dataptr

        time=[tm_dat[0], tm_dat[n_elements(tm_dat)-1]]
        dim=size(glatcen_dat, /dim)
		nalt=dim[0] & nx=dim[1] & ny=dim[2]

        v1=[0,1]
		vx=indgen(nx) & vy=indgen(ny)
        azel=fltarr(2, nx, ny, 2)
        azel[0, *, *, 0]=az_dat & azel[0, *, *, 1]=az_dat
        azel[1, *, *, 0]=el_dat & azel[1, *, *, 1]=el_dat
        store_data, 'nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_azel', $
                    data={x:time_double(time,/epoch), y:azel, v1:v1, v2:vx, v3:vy}

        pos_cen=fltarr(2, nalt, nx, ny, 2)
        pos_cen[0, *, *, *, 0]=glatcen_dat & pos_cen[0, *, *, *, 1]=glatcen_dat
        pos_cen[1, *, *, *, 0]=gloncen_dat & pos_cen[1, *, *, *, 1]=gloncen_dat
        store_data, 'nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_pos_cen', $
                    data={x:time_double(time,/epoch), y:pos_cen, v1:v1, v2:alt_dat, v3:vx, v4:vy}

		vx2=indgen(nx+1) & vy2=indgen(ny+1)
        pos_cor=fltarr(2, nalt, nx+1, ny+1, 2)
        pos_cor[0, *, *, *, 0]=glatcor_dat & pos_cor[0, *, *, *, 1]=glatcor_dat
        pos_cor[1, *, *, *, 0]=gloncor_dat & pos_cor[1, *, *, *, 1]=gloncor_dat
        store_data, 'nipr_'+instr+'_'+site_code[i]+'_'+wlenstr[j]+'_pos_cor', $
                    data={x:time_double(time,/epoch), y:pos_cor, v1:v1, v2:alt_dat, v3:vx2, v4:vy2}


      endelse
    endif
  endfor
endfor

;---
return
end
