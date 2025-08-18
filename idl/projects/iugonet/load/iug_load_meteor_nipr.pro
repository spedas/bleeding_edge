;+
; PROCEDURE: IUG_LOAD_METEOR_NIPR
;   iug_load_meteor_nipr, site = site, trange = trange, $
;       get_support_data = get_support_data, verbose = verbose, $
;       downloadonly = downloadonly, no_download = no_download
;
; PURPOSE:
;   loads meteor radar data of NIPR
;
; KEYWORDS:
;   site  = Observatory name.  For example, iug_load_meteor_nipr, site = 'tro'.
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_meteor_nipr, site = 'tro', trange = ['2007-01-22/00:00:00','2007-01-24/00:00:00']
;
; NOTE:
;   The meteor radar data obtained by NIPR is now not online.
;
; Written by: Y.-M. Tanaka, July 25, 2011 (ytanaka at nipr.ac.jp)
; Revised by: Y.-M. Tanaka, December 19, 2013 (ytanaka at nipr.ac.jp)
;-

;**************************
;***** Procedure name *****
;**************************
pro iug_load_meteor_nipr, site = site, trange = trange, $
       verbose = verbose, downloadonly = downloadonly, $
       no_download = no_download

;===== Keyword check =====
;----- all site codes -----;
site_code_all = strsplit('tro lyr', /extract)

;----- site -----;
if(not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return
print, 'site_code = ',site_code

;----- verbose -----;
if(not keyword_set(verbose)) then verbose=0

;----- downloadonly -----;
if(not keyword_set(downloadonly)) then downloadonly=0

;----- no_download -----;
if(not keyword_set(no_download)) then no_download=0

;----- get_support_data -----;
if(not keyword_set(get_support_data)) then get_support_data=0

; acknowlegment string (use for creating tplot vars)
acknowledgstring = 'We welcome collaborative research that uses the meteor '+$
	'radar data. Please contact the Principal Investigator, Dr. '+$
	'Masaki Tsutsumi (tutumi [at] nipr.ac.jp), National Institute '+$
	'of Polar Research (NIPR), if you want to use the data. '+$
        'The meteor radar observations are carried out in '+$
        'corporation with Univ. of Tromsoe. The distribution of the meteor '+$
        'radar data from NIPR has been partly supported by the IUGONET '+$
        '(Inter-university Upper atmosphere Global Observation NETwork) '+$
        'project (http://www.iugonet.org/) funded by the Ministry of '+$
        'Education, Culture, Sports, Science and Technology (MEXT), Japan.'

;----- default limit structure -----;
dlimit=create_struct('data_att',create_struct('acknowledgment', $	
       acknowledgstring, 'PI_NAME', 'M. Tsutsumi', 'LINK_TEXT', $
       'http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=108'))


;===== Download files, read data, and create tplot vars at each site =====
ack_flg=0

for i=0, n_elements(site_code)-1 do begin
  site1=site_code(i)
  case site1 of
    'tro' : sitetmp='ntmr'
    'lyr' : sitetmp='nsmr'
  endcase

  ;----- Set parameters for file_retrieve and download data files -----;
  source = file_retrieve(/struct)
  source.verbose = verbose
  source.local_data_dir = root_data_dir() + 'iugonet/nipr/mwr/'
  source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/mwr/'
  if keyword_set(no_download) then source.no_download = 1

  pathformat= strlowcase(sitetmp) + '/YYYY/' + $
              sitetmp+'YYYYMMDD_h2t1.txt'
  relpathnames = file_dailynames(file_format=pathformat, $
                                 trange=trange)
  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

  filestest=file_test(files)

  if(total(filestest) ge 1) then begin
    files=files[where(filestest eq 1)]
  
    ;=========================================
    ;=== Loop on reading meteor radar data ===
    ;=========================================
    ;----- Initialize data buffer -----;
    time_buf = 0
    uwind_buf = 0
    vwind_buf = 0
    uerr_buf = 0
    verr_buf = 0
    nw_buf = 0
    adif1_buf = 0
    adif2_buf = 0
    adif3_buf = 0

    nalt = 30
    ntime = 48
    vdat=findgen(nalt)*2.0+61

    for j=0, n_elements(files)-1 do begin
      file1 = files[j]

      stryear = (strmid(file1,strlen(file1)-17,4))
      strmon = (strmid(file1,strlen(file1)-13,2))
      strday = (strmid(file1,strlen(file1)-11,2))

      ;----- Open file ------;
      openr, lun, file1, /get_lun

      uwind = replicate(!values.f_nan, ntime, nalt)
      vwind = replicate(!values.f_nan, ntime, nalt)
      uerr = replicate(!values.f_nan, ntime, nalt)
      verr = replicate(!values.f_nan, ntime, nalt)
      nw = replicate(-999, ntime, nalt)
      adif1 = replicate(!values.f_nan, ntime, nalt)
      adif2 = replicate(!values.f_nan, ntime, nalt)
      adif3 = replicate(!values.f_nan, ntime, nalt)
      timevec = dblarr(ntime)

      ;----- Read data -----;
      itime=0
      beftime=-1
      data=''
      while (not EOF(lun)) do begin
        readf, lun, data
;        year=fix(strmid(data,0,4))
;        doy=fix(strmid(data,4,3))
        hour=fix(strmid(data,7,2))
        minute=fix(strmid(data,9,2))
        alt=fix(strmid(data,11,4))
        ialt=(alt-fix(vdat[0]))/2
        nowtime=hour+minute*0.5
        
        if (beftime ne -1) and (nowtime ne beftime) then begin
          itime=itime+1
        endif

        uwind(itime, ialt)=float(strmid(data,15,4))
        vwind(itime, ialt)=float(strmid(data,19,4))
        uerr(itime, ialt)=float(strmid(data,23,3))
        verr(itime, ialt)=float(strmid(data,26,3))
        nw(itime, ialt)=fix(strmid(data,29,3))
        adif1(itime, ialt)=float(strmid(data,32,4))
        adif2(itime, ialt)=float(strmid(data,36,4))
        adif3(itime, ialt)=float(strmid(data,40,3))
        timevec(itime)=time_double(stryear+'-'+strmon+'-'+strday+'/'+$
	  	string(hour)+':'+string(minute))
        beftime=nowtime
      endwhile

      uwind=uwind[0:itime-1, *]
      vwind=vwind[0:itime-1, *]
      uerr=uerr[0:itime-1, *]
      verr=verr[0:itime-1, *]
      nw=nw[0:itime-1, *]
      adif1=adif1[0:itime-1, *]
      adif2=adif2[0:itime-1, *]
      adif3=adif3[0:itime-1, *]
      timevec=timevec[0:itime-1]

      ;----- Append data -----;
      append_array, uwind_buf, uwind
      append_array, vwind_buf, vwind
      append_array, uerr_buf, uerr
      append_array, verr_buf, verr
      append_array, nw_buf, nw
      append_array, adif1_buf, adif1
      append_array, adif2_buf, adif2
      append_array, adif3_buf, adif3
      append_array, time_buf, timevec

      ;----- Close file -----;
      free_lun, lun
    endfor

    ;----- Show data policy -----;
    if(ack_flg eq 0) then begin
      ack_flg=1
      print, '**************************************************************************************'
      print, 'Information about NIPR Meteor Radar data'
      print, 'PI: ', dlimit.data_att.PI_name
      print, ''
      print, 'Rules of the Road for NIPR Meteor Radar Data:'
      print, ''
      print_str_maxlet, dlimit.data_att.acknowledgment
      print, ''
      print, 'URL: ',dlimit.data_att.LINK_TEXT
      print, '**************************************************************************************'
    endif

    ;----- Create tplot variables -----;
    if(downloadonly eq 0) then begin
      ;----- tplot variable name -----;
      prefix = 'iug_meteor_'+ strlowcase(site1)

      ;----- store data to tplot variable -----;
      store_data, prefix+'_uwnd', data={x:time_buf, y:uwind_buf, $
	  v:vdat}, dlimit=dlimit
      store_data, prefix+'_vwnd', data={x:time_buf, y:vwind_buf, $
	  v:vdat}, dlimit=dlimit
      store_data, prefix+'_uerr', data={x:time_buf, y:uerr_buf, $
	  v:vdat}, dlimit=dlimit
      store_data, prefix+'_verr', data={x:time_buf, y:verr_buf, $
	  v:vdat}, dlimit=dlimit

      ylim, prefix+'_uwnd', 65, 110, 0
      ylim, prefix+'_vwnd', 65, 110, 0
      ylim, prefix+'_uerr', 65, 110, 0
      ylim, prefix+'_verr', 65, 110, 0
      zlim, prefix+'_uwnd', -100, 100, 0
      zlim, prefix+'_vwnd', -80, 80, 0
      zlim, prefix+'_uerr', 0, 50, 0
      zlim, prefix+'_verr', 0, 50, 0

      options, prefix+'_uwnd', 'spec', 1
      options, prefix+'_vwnd', 'spec', 1
      options, prefix+'_uerr', 'spec', 1
      options, prefix+'_verr', 'spec', 1

      ;----- add options -----;
      options, prefix+'_uwnd', $
        ytitle = 'Meteor radar '+strupcase(site1)+'!CHeight', $
        ysubtitle = '[km]', ztitle='Eastward Wind [m/s]'
      options, prefix+'_vwnd', $
        ytitle = 'Meteor radar '+strupcase(site1)+'!CHeight', $
        ysubtitle = '[km]', ztitle='Northward Wind [m/s]'
      options, prefix+'_uerr', $
        ytitle = 'Meteor radar '+strupcase(site1)+'!CHeight', $
        ysubtitle = '[km]', ztitle='Error of Eastward Wind [m/s]'
      options, prefix+'_verr', $
        ytitle = 'Meteor radar '+strupcase(site1)+'!CHeight', $
        ysubtitle = '[km]', ztitle='Error of Northward Wind [m/s]'

      if(get_support_data eq 1) then begin
        store_data, prefix+'_nw', data={x:time_buf, y:nw_buf, $
          v:vdat}, dlimit=dlimit
        store_data, prefix+'_adif1', data={x:time_buf, y:adif1_buf, $
          v:vdat}, dlimit=dlimit
        store_data, prefix+'_adif2', data={x:time_buf, y:adif2_buf, $
          v:vdat}, dlimit=dlimit
        store_data, prefix+'_adif3', data={x:time_buf, y:adif3_buf, $
          v:vdat}, dlimit=dlimit
      endif
    endif
  endif
endfor

end
