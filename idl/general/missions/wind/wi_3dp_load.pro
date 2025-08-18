;+
;Procedure: WI_3DP_LOAD
;
;Purpose:  Loads WIND 3DP data
;
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   VERBOSE : To change verbosity
;Examples:
;   wi_3dp_load,'k0'
;   wi_3dp_load,'pm'
;   wi_3dp_load,'elpd'
;   wi_3dp_load,'elm2'
;   wi_3dp_load,'sfpd'
;   wi_3dp_load,'sfsp'
;   wi_3dp_load,'phsp'
;   wi_3dp_load,'sosp'
;   wi_3dp_load,'sopd'
;
;Notes:
; Author: Davin Larson
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-02-03 15:08:57 -0800 (Mon, 03 Feb 2020) $
; $LastChangedRevision: 28271 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wi_3dp_load.pro $
;-
pro wi_3dp_load,type,files=files,trange=trange,verbose=verbose,$
                downloadonly=downloadonly, no_download=no_download, $
                no_update=no_update, $
                varformat=varformat,datatype=datatype, $
                version=version, $
                addmaster=addmaster,tplotnames=tn,source=source,suffix=suffix

if keyword_set(type) then datatype=type
if not keyword_set(datatype) then datatype = 'k0'
if not keyword_set(suffix) then suffix = ''

;All 3dp data, except for 'k0' is at SSL, but the path is different,
;so make the distinction, to avoid trying to download to the
;unwriteable local_data_dir
wind_init
if file_test(!wind.local_data_dir+'wind/.master') && datatype Ne 'k0' then begin
  ; Local directory IS the master directory
   at_ssl = 1b
endif else at_ssl = 0b

;Use istp_init for most 3dp data
istp_init

if at_ssl then begin
   if not keyword_set(source) then source = !wind
endif else begin
   if not keyword_set(source) then source = !istp
endelse
   
masterfile=''
; versions might change in the future 
if not keyword_set(version) then version ='v??'

case datatype of
  'k0':  begin
    pathformat = 'wind/3dp/3dp_k0/YYYY/wi_k0_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then  varformat = 'ion_density ion_vel ion_temp'
    if not keyword_set(prefix) then prefix = 'wi_3dp_k0_'
  end

  'pm': begin
    if(at_ssl) then pathformat = 'wind/3dp/pm/YYYY/wi_pm_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_pm/YYYY/wi_pm_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '?_* TIME Epoch'
    if not keyword_set(prefix) then prefix = 'wi_3dp_pm_'
    addmaster=1
  end

  'elpd_old': begin
    if(at_ssl) then pathformat = 'wind/3dp/elpd/YYYY/wi_elpd_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_elpd/YYYY/wi_elpd_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elpd_'
    addmaster=1
  end

  'elpd': begin ;note that SPDF does not have 'new' files, jmm, 2017-03-06
    if(at_ssl) then pathformat = 'wind/3dp/elpd2/YYYY/wi_3dp_elpd_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_elpd/YYYY/wi_elpd_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elpd_'
    fix_elpd_flux = 1
;    addmaster=1
  end

  'elsp': begin
    if(at_ssl) then pathformat = 'wind/3dp/elsp/YYYY/wi_elsp_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_elsp/YYYY/wi_elsp_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elsp_'
;    fix_elpd_flux = 1
;    addmaster=1
  end

  'elm2': begin
    if(at_ssl) then pathformat = 'wind/3dp/elm2/YYYY/wi_elm2_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_elm2/YYYY/wi_elm2_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_elm2_'
;    fix_elpd_flux = 1
;    addmaster=1
  end

  'sfpd': begin
    if(at_ssl) then pathformat = 'wind/3dp/sfpd/YYYY/wi_sfpd_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_sfpd/YYYY/wi_sfpd_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sfpd_'
;    addmaster=0
  end

  'sfsp': begin
    if(at_ssl) then pathformat = 'wind/3dp/sfsp/YYYY/wi_sfsp_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_sfsp/YYYY/wi_sfsp_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sfsp_'
;    addmaster=0
  end

  'plsp': begin
    if(at_ssl) then pathformat = 'wind/3dp/plsp/YYYY/wi_plsp_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_plsp/YYYY/wi_plsp_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'
    if not keyword_set(prefix) then prefix = 'wi_3dp_plsp_'
    fix_sosp_flux =1
;  addmaster=0
  end

  'phsp': begin
    if(at_ssl) then pathformat = 'wind/3dp/phsp/YYYY/wi_phsp_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_phsp/YYYY/wi_phsp_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'
    if not keyword_set(prefix) then prefix = 'wi_3dp_phsp_'
   ; fix_sosp_flux =1
;  addmaster=0
  end

  'sosp': begin
    if(at_ssl) then pathformat = 'wind/3dp/sosp/YYYY/wi_sosp_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_sosp/YYYY/wi_sosp_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sosp_'
    fix_sosp_flux =1
;  addmaster=0
  end

  'sosp2': begin ;Note that these files are not online at SSL or SPDF, jmm, 2017-03-06
    if(at_ssl) then pathformat = 'wind/3dp/sosp/YYYY/wi_3dp_sosp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_sosp/YYYY/wi_3dp_sosp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sosp2_'
    fix_sosp_flux =1
;    addmaster=0
  end

  'sopd': begin
    if(at_ssl) then pathformat = 'wind/3dp/sopd/YYYY/wi_sopd_3dp_YYYYMMDD_'+version+'.cdf' $
    else pathformat = 'wind/3dp/3dp_sopd/YYYY/wi_sopd_3dp_YYYYMMDD_'+version+'.cdf'
    if not keyword_set(varformat) then varformat = '*'  ; 'FLUX EDENS TEMP QP QM QT MAGF TIME'
    if not keyword_set(prefix) then prefix = 'wi_3dp_sopd_'
    fix_sopd_flux =1
;    addmaster=0
  end
  else : begin
     dprint, 'No datatype: '+datatype
     return
  end
endcase

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

relpathnames = file_dailynames(file_format=pathformat,trange=trange,addmaster=addmaster)

;if data is loaded from cdaweb, then the mastercdf is not in a 0000
;directory, but at
;https://cdaweb.gsfc.nasa.gov/pub/software/cdawlib/0MASTERS
spdf_test = strpos(source.remote_data_dir, 'spdf')
If(~at_ssl && keyword_set(addmaster) && spdf_test[0] Ne -1) Then Begin
   ;the mastercdf is the first in the file list, but check for 8 zeros
   test_master = strpos(relpathnames, '00000000')
   ss_master = where(test_master Ne -1)
   If(ss_master[0] Ne -1) Then Begin
      cdaweb_masterdir = 'https://cdaweb.gsfc.nasa.gov/pub/software/cdawlib/0MASTERS/'
      masterfile0 = cdaweb_masterdir+file_basename(relpathnames[ss_master])
      master_local_path = source.local_data_dir+file_dirname(relpathnames[ss_master], /mark_directory)
   Endif
   masterfile = spd_download(remote_file=masterfile0, local_path = master_local_path, $
                             no_download = source.no_download, no_update = source.no_update, $
                             /last_version, $
                             file_mode = '666'o, dir_mode = '777'o)
   ss_not_master = where(test_master Eq -1)
   files = spd_download(remote_file=relpathnames[ss_not_master], $
                        remote_path=source.remote_data_dir, $
                        local_path = source.local_data_dir, $
                        no_download = source.no_download, $
                        no_update = source.no_update, /last_version, $
                        file_mode = '666'o, dir_mode = '777'o)
   files = [masterfile, files]
Endif Else Begin
   files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, $
                        local_path = source.local_data_dir, $
                        no_download = source.no_download, no_update = source.no_update, $
                        /last_version, file_mode = '666'o, dir_mode = '777'o)
Endelse

if keyword_set(downloadonly) then return

;test for ok files here
nfiles = n_elements(files)
ok_files = bytarr(nfiles)
for j = 0, nfiles-1 do begin ;files may be null string, or have ?? in returned filename
   if(files[j] Ne '' And is_string(file_search(files[j]))) then ok_files[j] = 1b
endfor
keep_files = where(ok_files eq 1, nkeep)
if(nkeep eq 0) then begin
   dprint, 'No data files found for:'+datatype
   return
endif else files = files[keep_files]

cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn,suffix=suffix    ; load data into tplot variables

; Set options for specific variables

if keyword_set(fix_elpd_flux) or keyword_set(fix_sopd_flux) then begin   ;  perform cluge because CDF file attributes are not set for these files
   get_data,prefix+'FLUX'+suffix,ptr=p_flux
   get_data,prefix+'PANGLE'+suffix,ptr=p_pangles
   get_data,prefix+'ENERGY'+suffix,ptr=p_energy
   If(is_struct(p_energy) && ptr_valid(p_energy.y)) Then $
      str_element,/add,p_flux,'V1',p_energy.y  
   If(is_struct(p_pangles) && ptr_valid(p_pangles.y)) Then $
      str_element,/add,p_flux,'V2',p_pangles.y
   store_data,prefix+'FLUX'+suffix,data = p_flux
endif


if keyword_set(fix_sosp_flux) then begin
  ;  printdat,tn
   get_data,prefix+'FLUX'+suffix,ptr=p_flux
   get_data,prefix+'ENERGY'+suffix,ptr=p_energy
   If(is_struct(p_energy) && ptr_valid(p_energy.y)) Then $
      str_element,/add,p_flux,'V',p_energy.y
   store_data,prefix+'FLUX'+suffix,data = p_flux

endif

if datatype eq 'elpd' then begin
   reduce_pads,'wi_3dp_elpd_FLUX'+suffix,1,4,4
   reduce_pads,'wi_3dp_elpd_FLUX'+suffix,2,0,0
;data does not always have enough angular bins, jmm, 2019-10-15
   get_data,'wi_3dp_elpd_PANGLE'+suffix,ptr=p_pangles
   If(is_struct(p_pangles) && ptr_valid(p_pangles.y)) Then Begin
      szp = size(*p_pangles.y)
      If(szp[0] Eq 2 && szp[2] Ge 12) Then $
         reduce_pads,'wi_3dp_elpd_FLUX'+suffix,2,12,12
   Endif
endif

options,/def,strfilter(tn,'wi_3dp_ion_vel',delim=' ') , colors='bgr', labels=['Vx','Vy','Vz']   ; set colors for the vector quantities
;options,/def,strfilter(tn,'wi_mfi_BGSEc') , ytitle = 'WIND!CB (nT)'

dprint,dlevel=3,'tplotnames: ',tn


end
