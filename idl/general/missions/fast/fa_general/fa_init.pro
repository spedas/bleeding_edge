;Set up !FAST in IDL

pro fa_init,reset=reset, $
            local_data_dir=local_data_dir, $
            remote_data_dir=remote_data_dir, $
            no_color_setup=no_color_setup, $
            no_download=no_download

;Check if !fast already exists.
  defsysv,'!fast',exists=exists

;If !fast does not exist, create !fast.
  if NOT keyword_set(exists) then begin
     defsysv,'!fast',file_retrieve(/structure_format)
  endif

  if keyword_set(reset) then !fast.init=0
  if !fast.init NE 0 then return

  !fast=file_retrieve(/structure_format)

;Server list for FAST data and information files.
;ISTP files are in 'http://cdaweb.gsfc.nasa.gov/data/fast/'
  serverlist=['http://themis.ssl.berkeley.edu/data/fast/', $
              'http://sprg.ssl.berkeley.edu/data/fast/']

;File .fast_master must and should only be on server.
;Do not download .fast_master to your local hard disk!
  for url_index=0,n_elements(serverlist)-1 do begin
     file_http_copy,'.fast_master',serverdir=serverlist[url_index], $
                    /no_download,url_info=info_tmp
     if info_tmp.exists EQ 1 then break
  endfor
  if info_tmp.exists NE 1 then begin
     print,'Error: No Valid Servers Found'
     url_index=0
  endif
  !fast.remote_data_dir=serverlist[url_index]
  !fast.local_data_dir=root_data_dir()+'fast/'
  if keyword_set(local_data_dir) then !fast.local_data_dir=local_data_dir
  if keyword_set(remote_data_dir) then !fast.remote_data_dir=remote_data_dir
  if keyword_set(no_download) then !fast.no_download=no_download

;this needs to be done before the .fast_master test
  if getenv('SPEDAS_DATA_DIR') ne '' then $
     !fast.LOCAL_DATA_DIR = spd_addslash(getenv('SPEDAS_DATA_DIR'))+'fast/'
  if getenv('FAST_REMOTE_DATA_DIR') NE '' then $
     !fast.remote_data_dir=getenv('FAST_REMOTE_DATA_DIR')
  if getenv('FAST_LOCAL_DATA_DIR') NE '' then $
     !fast.remote_data_dir=getenv('FAST_LOCAL_DATA_DIR')

  servertestfile='.fast_master'
  if file_test(!fast.local_data_dir+servertestfile) then begin
     !fast.no_server=1 
     !fast.no_download=1
  endif

  !fast.init=1

;Change prompt from IDL> to FAST>
;if !prompt EQ 'IDL> ' then !prompt='FAST> '

  cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
  cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
  printdat,cdf_version

  cdf_version_readmin = '3.1.0'
  cdf_version_writemin = '3.1.1'

  if cdf_version lt cdf_version_readmin then begin
     print,'Your version of the CDF library ('+cdf_version+') is unable to read FAST data files.'
     print,'Please go to the following url to learn how to patch your system:'
     print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
     message,"You can have your data. You just can't read it! Sorry!"
  endif

  if cdf_version lt cdf_version_writemin then begin
     print,ptrace()
     print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write FAST CDF data files.'
     print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
     print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
  endif

;Set up FAST information IDL structure
  common fa_information,info_struct
  filename=fa_pathnames('fasttimes.cdf',directory='information')
  id=cdf_open(filename)
  cdf_varget,id,'FastTimes',timesarray
  cdf_close,id
  fast_setup={test:0b,calibrate:0b,esa:0b,fields:0b,mag:0b,teams:0b}
  info_struct={configuration:fa_config(/all),setup:fast_setup,timesarray:timesarray}

;Set up IDL color scheme.
  idl_color=getenv('IDL_COLOR')
  if idl_color EQ 'NONE' then no_color_setup=1
  if NOT keyword_set(no_color_setup) then begin

     if idl_color NE '' then colortable=idl_color
     if n_elements(colortable) EQ 0 then colortable=43

     old_dev = !d.name
     set_plot,'PS'
     loadct2,colortable
     device,/symbol,font_index=19
     set_plot,old_dev

     loadct2,colortable

     !p.background=!d.table_size-1
     !p.color=0
     !p.font = -1

     if !d.name EQ 'WIN' then begin
        device,decompose=0
     endif
     if !d.name EQ 'X' then begin
        device,decompose=0
        if !version.os_name EQ 'linux' then device,retain=2
     endif
  endif

;TPLOT OPTIONS
  tplot_options,window=0
  tplot_options,'wshow',1
  tplot_options,'ygap',.5
  tplot_options,'lazy_ytitle',1
  tplot_options,'no_interp',1

  printdat,/values,!fast,varname='!fast'

return
end
