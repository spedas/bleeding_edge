;+
; PROCEDURE: iug_load_avon_vlfb
;
; PURPOSE:
;   To load AVON/VLF-B data 
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_avon, site='TNN',
;           This can be an array of strings, e.g., ['tnn', 'srb']
;           or a single string delimited by spaces, e.g., 'tnn srb'.
;           Sites:  tnn srb ptk lbs
;   parameter = Parameter name. 'ch1' and 'ch2' are available.
;               ch1 for north-south component, and ch2 for east-west component.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_download: use only files which are online locally.
;   /verbose : set to output some useful info
;   trange = (Optional) Time range of interest  (2 element array).
;
; EXAMPLE:
;   iug_load_avon_vlfb, site='tnn', $
;            trange=['2007-12-28/10:20:00','2007-12-28/10:40:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://iugonet02.gp.tohoku.ac.jp/avon/rules.txt
;
; NAMING CONVENTIONS:
;       avon_[site]_vlfb_[parameter]
;       ex. avon_tnn_vlfb_ch1
;
; Written by: M.Yagi, May 14, 2014
;             PPARC, Tohoku Univ.
;
;   $LastChangedBy: nikos $
;   $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
;   $URL:
;-
pro iug_load_avon_vlfb, site=site, parameter=parameter, $
         downloadonly=downloadonly, no_download=no_download, verbose=verbose, trange=trange, force=force

;--- site
site_code_all = strsplit('tnn srb ptk lbs hni', /extract)
if(n_elements(site) eq 0) then site='all'
site_code=ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)
if site_code[0] eq '' then return

;--- parameter
param_all = strsplit('ch1 ch2', /extract)
if(n_elements(parameter) eq 0) then parameter='all'
parameter=strjoin(parameter, ' ')
parameter=strsplit(strlowcase(parameter), ' ', /extract)
parameter = ssl_check_valid_name(parameter, param_all, /include_all)

;--- other options
if (not keyword_set(verbose)) then verbose=0
if (not keyword_set(downloadonly)) then downloadonly=0
if (not keyword_set(no_download)) then no_download=0

;--- data file structure
source = file_retrieve(/struct)
source.verbose = verbose
filedate = file_dailynames(file_format='YYYYMMDDhhmmss', trange=trange, res=600)
fileyear = strmid(filedate,0,4)
fileday  = strmid(filedate,2,6)

if keyword_set(no_download) then source.no_download = 1

if n_elements(filedate) gt 6 then begin
  print, '############################################'
  print, '!!! timespan too long (>1 hour) !!!'
  if keyword_set(force) then begin 
    print, '"force" option is used'
    print, 'loading data ... (it will take a long time)'
    print, '############################################'
  endif else begin
    print, 'please set timespan shorter than 1 hour'
    print, 'if you want to load longer data, use "force" option'
    print, 'ex. iug_load_avon_vlfb,/force'
    print, '############################################'
    return
  endelse
endif

show_text=0
for i=0,n_elements(site_code)-1 do begin
  ;--- Set the file path
  source.local_data_dir = root_data_dir() + 'iugonet/TohokuU/radio_obs/'+strupcase(site_code[i])+'/avon/'
  source.remote_data_dir = 'http://iugonet02.gp.tohoku.ac.jp/avon/cdf/'+strupcase(site_code[i])+'/'

  ;--- Download file
  relfnames = fileyear+'/'+fileday+'/'+'vlf_waveform_'+strlowcase(site_code[i])+'_'+filedate+'_v01.cdf'
  datfiles = spd_download(remote_file=relfnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

  print, source.remote_data_dir+relfnames

  ;--- Skip load where no data
  filenum=n_elements(datfiles)
  file_exist=intarr(filenum)
  for it=0,filenum-1 do begin
    file_exist[it] = file_test(datfiles[it])
  endfor

  ;--- Load data into tplot variables
  if(downloadonly eq 0 and (where(file_exist eq 1))[0] ne -1) then begin
    datfiles  = datfiles[where(file_exist eq 1)]
    show_text = 1

    for j=0,n_elements(parameter)-1 do begin
      cdf2tplot, file=source.local_data_dir+relfnames,varformat='vlf_wave_'+parameter[j]

      ;--- change tplot variable name
      newname = 'avon_vlfb_'+site_code[i]+'_'+parameter[j]
      copy_data,  'vlf_wave_'+parameter[j], newname
      store_data, 'vlf_wave_'+parameter[j], /delete
      ;--- modify ytitle
      options, newname, ytitle='AVON/VLF-B'
      options, newname, ysubtitle=site_code[i]+'_'+parameter[j]+' [V]'
    endfor
  endif

endfor

;--- Acknowledgement
if (show_text eq 1) then begin
  dprint, '**********************************************************************'
  dprint, 'Project: Asia VLF Observation Network(AVON) VLF-B'
  dprint, ''
  dprint, 'PI and Host PI(s): Hiroyo Ohya'
  dprint, 'Affiliations: Graduate School of Engineering, Chiba University'
  dprint, ''
  dprint, 'Rules of the Road for AVON VLF-B Use:'
  dprint, ' When you use the raw data, you have to participate our consortium.'
  dprint, 'Please contact us. When the data is used in or contributes to a'
  dprint, 'presentation or publication, you should make acknowledgement.'
  dprint, ''
  dprint, '-Acknowledgement:Presentation'
  dprint, 'The authors wish to thank the Asia VLF Observation Network(AVON),'
  dprint, 'a collaboration among universities and institutions in Asia,for'
  dprint, 'providing observation data used in this presentation.'
  dprint, ''
  dprint, '-Acknowledgement: Paper'
  dprint, 'The authors wish to thank the Asia VLF Observation Network(AVON),'
  dprint, 'a collaboration among universities and institutions in Asia,for'
  dprint, 'providing observation data used in this paper.'
  dprint, 'This work was supported by JSPS KAKENHI Grant Numbers 19002002,'
  dprint, '24253002,and 25302005.'
  dprint, ''
  dprint, '-Reference'
  dprint, 'Please refer the following paper, if needed.'
  dprint, 'Adachi, Toru, Takahashi, Yukihiro, Ohya, Hiroyo, Tsuchiya, Fuminori'
  dprint, 'Yamashita, Kozo, Yamamoto, Mamoru, Hashiguchi, Hiroyuki(2008) Monitoring'
  dprint, 'of Lightning Activity in Southeast Asia: Scientific Objectives and'
  dprint, 'Strategies,Kyoto Working Papers on Area Studies: G-COE'
  dprint, 'Series(11),page.1-20.'
  dprint, ''
  dprint, 'For more information, see http://iugonet02.gp.tohoku.ac.jp/avon/'
  dprint, '**********************************************************************'
endif else begin
  dprint, 'No data is loaded'
  dprint, ''
endelse

return
end
