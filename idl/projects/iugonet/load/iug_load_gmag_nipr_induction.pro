
;+
; PROCEDURE: iug_load_gmag_nipr_induction
;   to load NIPR induction magnetometer data 
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_gmag_nipr_induction, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['syo', 'hus']
;           or a single string delimited by spaces, e.g., 'syo hus'.
;           Available sites: syo hus tjo aed isa
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   frequency_dependent = get frequecy-dependent sensitivity
;            (frequency [Hz] and sensitivity (H,D,Z) [Vp-p])
;
; EXAMPLE:
;   iug_load_gmag_nipr_induction, site='syo', $
;         trange=['2008-02-28/00:00:00','2008-02-28/02:00:00']
;
; Written by: Y. Miyashita, Jan 23, 2011
;             ERG-Science Center, STEL, Nagoya Univ.
;             erg-sc-core at st4a.stelab.nagoya-u.ac.jp
; Revised for NIPR data by Y. Sato, August 6, 2012 (sato.yuka at nipr.ac.jp)
;-

pro iug_load_gmag_nipr_induction, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, frequency_dependent=frequency_dependent

;*** site codes ***
;--- aliases
if(n_elements(site) ne 0) then begin
  site=strjoin(site, ' ')
  site=strsplit(strlowcase(site), ' ', /extract)
endif

;--- all sites (default)
site_code_all = strsplit( $
  'syo hus tjo aed isa', $
  ' ', /extract)

;--- check site codes
if(n_elements(site) eq 0) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

print, site_code


;*** keyword set ***
if(not keyword_set(downloadonly)) then downloadonly=0
if(not keyword_set(no_server)) then no_server=0
if(not keyword_set(no_download)) then no_download=0

;*** other variables ***
if(arg_present(frequency_dependent)) then $
  frequency_dependent=replicate({site_code:' ', nfreq:0, $
      frequency:fltarr(15), sensitivity:dblarr(15,3)}, n_elements(site_code))

instr='imag'

;*** load CDF ***
;--- Create (and initialize) a data file structure 
source = file_retrieve(/struct)

;--- Set parameters for the data file class 
source.local_data_dir  = root_data_dir() + 'iugonet/nipr/'
source.remote_data_dir = 'http://iugonet0.nipr.ac.jp/data/'
if keyword_set(no_download) then source.no_download = 1

relpathnames1 = file_dailynames(file_format='YYYY', trange=trange)
relpathnames2 = file_dailynames(file_format='YYYYMMDD', trange=trange)

for i=0,n_elements(site_code)-1 do begin

  ;----- Set sampling time correspoding to input date -----;
  tr=timerange(trange)
  tr0=tr[0]
  if site_code[i] eq 'syo' then begin
    crttime=time_double('1998-1-1')
    if tr0 lt crttime then tres='2sec' else tres='20hz'
  endif
  if site_code[i] eq 'hus' then begin
    crttime=time_double('2001-09-08')
    if tr0 lt crttime then tres='2sec' else tres='02hz'
  endif
  if site_code[i] eq 'tjo' then begin
    crttime=time_double('2001-9-12')
    if tr0 lt crttime then tres='2sec' else tres='02hz'
  endif
  if site_code[i] eq 'aed' then begin
    crttime=time_double('2001-9-27')
    if tr0 lt crttime then tres='2sec' else tres='02hz'
  endif
  if site_code[i] eq 'isa' then begin
    tres='2sec'
  endif

  relpathnames  = instr+'/'+site_code[i]+'/'+tres+'/'+$
    relpathnames1 + '/nipr_'+tres+'_'+instr+'_'+site_code[i]+'_'+$
    relpathnames2 + '_v??.cdf'


  ;--- Download the designated data files from the remote data server
  ;    if the local data files are older or do not exist. 
  files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, no_server=no_server, no_download=no_download, _extra=source, /last_version)
  filestest=file_test(files)

  if(total(filestest) ge 1) then begin
    files=files(where(filestest eq 1))

    ;--- print PI info and rules of the road
    gatt = cdf_var_atts(files[0])

    print, '**************************************************************************************'
    ;print, gatt.project
    print, gatt.Logical_source_description
    print, ''
    ;print, 'Information about ', gatt.Station_code
    print, 'PI: ', gatt.PI_name
    print, 'Affiliation: ', gatt.PI_affiliation
    print, ''
    print, 'Rules of the Road for NIPR Induction Magnetometer Data Use:'
    print_str_maxlet, gatt.Rules_of_use
    print, ''
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
    print, '**************************************************************************************'

    ;--- Load data into tplot variables
    if(downloadonly eq 0) then begin
      cdf2tplot, file=files, verbose=source.verbose, $
                 prefix='nipr_imag_', suffix='_'+site_code[i]

      ;--- Calculate epoch since 1970/01/01 00:00:00 UT and get frequency-dependent sensitivity and phase difference
      get_data, 'nipr_imag_db_dt_'+site_code[i], data=dtmp

      for j=0,n_elements(files)-1 do begin      
        cdfid=cdf_open(files[j])

        ;--- CDF_EPOCH16
        cdf_control, cdfid, get_var_info=cdfcont, variable='epoch_db_dt', /zvariable
        eepoch=dcomplexarr(cdfcont.maxrec+1)
        cdf_varget, cdfid, 'epoch_db_dt', eepoch, rec_count=cdfcont.maxrec+1

        ;--- get frequency-dependent sensitivity and phase difference
        if((j eq 0) and (arg_present(frequency_dependent))) then begin
          print, 'Getting frequency-dependent sensitivity and phase difference'
          cdf_control, cdfid, get_var_info=cdfcont, variable='frequency', /zvariable

          ffreq=fltarr(cdfcont.maxrec+1) & ssensi=dblarr(3,cdfcont.maxrec+1)
          cdf_varget, cdfid, 'frequency',        ffreq,  rec_count=cdfcont.maxrec+1
          cdf_varget, cdfid, 'sensitivity',      ssensi, rec_count=cdfcont.maxrec+1

          frequency_dependent[i].site_code=site_code[i]
          frequency_dependent[i].nfreq=cdfcont.maxrec+1
          frequency_dependent[i].frequency[0:cdfcont.maxrec]=ffreq[0:cdfcont.maxrec]
          frequency_dependent[i].sensitivity[0:cdfcont.maxrec,0:2]=transpose(ssensi[0:2,0:cdfcont.maxrec])
        endif

        ;---
        cdf_close, cdfid
      endfor

      ;--- Rename
      copy_data,  'nipr_imag_db_dt_'+site_code[i], 'nipr_imag_'+site_code[i]+'_'+tres
      store_data, 'nipr_imag_db_dt_'+site_code[i], /delete

      ;--- Delete invalid data
      store_data, 'nipr_imag_gps_1pps_time_pulse_'+site_code[i], /delete

      ;--- Missing data -1.e+31 --> NaN
      tclip, 'nipr_imag_'+site_code[i]+'_'+tres, -1e+5, 1e+5, /overwrite

      ;--- Labels
      options, 'nipr_imag_'+site_code[i]+'_'+tres, labels=['dH/dt','dD/dt','dZ/dt'], labflag=1

    endif

  endif
endfor   ; end of for loop of i

;---
return
end

