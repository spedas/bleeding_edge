;+
; PRO erg_load_pwe_ofa
;
; The read program for Level-2 PWE/OFA data 
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. Currently only 'spec' is
;   acceptable. (For futrue, 'matrix' and 'complex' are prepared.)
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   get_suuport_data: Set to load support data in CDF data files.
;   trange: Set a time range to load data explicitly for the specified
;           time range.
;   downloadonly: If set, data files are downloaded and the program
;                exits without generating tplot variables.
;   no_download: Set to prevent the program from searching in the
;                remote server for data files.
;   verbose:  Set to make some commands in this program verbose.
;   uname: user ID to be passed to the remote server for
;          authentication.
;   passwd: password to be passed to the remote server for
;           authentication.
;   band_width: return a hash variable for band width of each mode.
;               ex: band_width[132], band_width[256] return band width
;               with datapoints of 132, 256, respectively.
;   ror: If set a string, rules of the road (RoR) for data products
;        are displayed at your terminal.
;        
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_pwe_ofa
;   IDL> erg_load_pwe_ofa, datatype='spec'
;
; :Authors:
;   Masafumi Shoji, ERG Science Center (E-mail: masafumi.shoji at nagoya-u.jp)
;
; $LastChangedDate: 2021-03-25 13:25:21 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29822 $
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/pwe/erg_load_pwe_ofa.pro $
;-

pro erg_load_pwe_ofa, $
   level=level, $
   datatype=datatype, $
   trange=trange, $
   downloadonly=downloadonly, $
   no_download=no_download, $
   get_support_data = get_support_data, $
   verbose=verbose, $
   uname=uname, $
   passwd=passwd, $
   band_width=band_width, $
   ror=ror, $
   coord=coord, $
   _extra=_extra

erg_init

if ~keyword_set(level) then level='l2' ;; level='l1_prime'
if ~keyword_set(datatype) then datatype='spec'
if ~keyword_set(coord) then coord='sgi'
if ~keyword_set(downloadonly) then downloadonly = 0
if ~keyword_set(no_download) then begin
   no_download = 0
   ;     if ~keyword_set(uname) then begin
   ;        uname=''
   ;        read, uname, prompt='Enter username: '
   ;     endif
   ;     
   ;     if ~keyword_set(passwd) then begin
   ;        passwd=''
   ;        read, passwd, prompt='Enter passwd: '
   ;     endif
endif

if ~strcmp(datatype, 'spec') and ~strcmp(datatype, 'matrix') and ~strcmp(datatype, 'complex') and ~strcmp(datatype, 'property') then begin
   print, 'Keyword datatype accepts only "spec", "matrix" and "complex" for L2, and "property" for L3.'
   return
endif

if strcmp(level,'l3') then begin
   datatype = 'property'
   coord = 'dsi'
endif

coord_fix = ''
if ~strcmp(datatype,'spec') then begin
   coord_fix = coord+'_'
endif

relfpathfmt = 'YYYY/MM/erg_pwe_ofa_' + level+'_'+datatype+'_'+ coord_fix + 'YYYYMMDD_v??_??.cdf' ;;real
remotedir=!erg.remote_data_dir+'satellite/erg/pwe/ofa/'+level+'/'+datatype+'/'
localdir = !erg.local_data_dir + 'satellite/erg/pwe/ofa/'+level+'/'+datatype+'/'
prefix = 'erg_pwe_ofa_'+datatype+'_'+level+'_'

relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
files=spd_download(remote_file=relfpaths,remote_path = remotedir,local_path=localdir,no_download=no_download,$
   _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)
filestest=file_test(files)

if (total(filestest) ge 1) then begin
   datfiles=files[where(filestest eq 1)]
endif else return

if ~downloadonly then begin
   cdf2tplot, file = datfiles, prefix = prefix, get_support_data = get_support_data, $
      verbose = verbose

   cdfi = cdf_load_vars(datfiles,varformat=varformat,var_type='support_data',/spdf_depend, $
            varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2, all=all)

   idx_bw=where(strmatch(cdfi.vars.name, 'band_width_*') eq 1)
   n=n_elements(idx_bw)
   band_width=hash()
   for i=0, n-1 do begin
      x=fix(strmid(cdfi.vars[idx_bw[i]].name, 12, 5))
      band_width[x]=*cdfi.vars[idx_bw[i]].dataptr
   endfor
endif

if strcmp(level,'l2') and strcmp(datatype, 'spec') then begin

   zlim, prefix+['E_spectra_*'], 1e-9, 1e-2, 1
   zlim, prefix+['B_spectra_*'], 1e-4, 1e2, 1
   options, prefix+['E_spectra_*'], 'datagap', 8.
   options, prefix+['B_spectra_*'], 'datagap', 8.


   if strcmp(tnames(prefix+['E_spectra_66']),'') and strcmp(tnames(prefix+['E_spectra_132']),'') and $
      strcmp(tnames(prefix+['E_spectra_264']),'') and strcmp(tnames(prefix+['E_spectra_528']),'') then begin

      print, 'No varid OFA spectra data is loaded.'
      goto, gt1

   endif else begin    
      store_data, prefix+'E_spectra_merged', data=[tnames(prefix+['E_spectra_66','E_spectra_132','E_spectra_264','E_spectra_528'])]
      store_data, prefix+'B_spectra_merged', data=[tnames(prefix+['B_spectra_66','B_spectra_132','B_spectra_264','B_spectra_528'])]
   endelse

   ylim, prefix+'E_spectra_*', 32e-3, 20., 1
   ylim, prefix+'B_spectra_*', 32e-3, 20., 1
   options, prefix+['E_spectra_*'], 'ytitle', 'ERG PWE/OFA-SPEC (E)'
   options, prefix+['B_spectra_*'], 'ytitle', 'ERG PWE/OFA-SPEC (B)'
   options, ['*_spectra_*'], 'ysubtitle', 'frequency [kHz]'
   options, prefix+'E_spectra_*', 'ztitle', 'mV^2/m^2/Hz'
   options, prefix+'B_spectra_*', 'ztitle', 'pT^2/Hz'

   endif

   if strcmp(level,'l3') then begin

      ylim, prefix+['?_spectra_*', 'kvec_*', 'polarization_*', 'planarity_*', 'Pvec_angle_*'], 32e-3, 20., 1
      zlim, prefix+['kvec_polar_*'], 0, 90, 0
      zlim, prefix+['kvec_azimuth_*'], -180., 180., 0
      zlim, prefix+['polarization_*'], -1., 1., 0
      zlim, prefix+['planarity_*'], 0., 1., 0
      zlim, prefix+['Pvec_angle_*'], 0., 180., 0
 
      options, prefix+['E_spectra_*'], 'ytitle', 'E field spectra'
      options, prefix+['B_spectra_*'], 'ytitle', 'B field spectra'
      options, ['*_spectra_*'], 'ysubtitle', 'frequency [kHz]'
      options, prefix+'E_spectra_*', 'ztitle', 'mV^2/m^2/Hz'
      options, prefix+'B_spectra_*', 'ztitle', 'pT^2/Hz'
      options, prefix+['kvec_*', 'Pvec_angle_*'], 'ztitle', '[!Eo!N]'

   endif

gatt=cdf_var_atts(datfiles[0])

; storing data information
erg_export_filever, datfiles

print_str_maxlet, ' '
print, '**********************************************************************'
print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 80
print, ''
print, 'Information about ERG PWE OFA'
print, ''
print, 'PI: ', gatt.PI_NAME
print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 80
print, ''

if keyword_set(ror) then begin
print, 'Rules of the Road for ERG PWE OFA Data Use:'
for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 80
print, ''
print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
endif else begin
print, 'RoR of ERG project common: https://ergsc.isee.nagoya-u.ac.jp/data_info/rules_of_the_road.shtml.en'
print, 'RoR of PWE/OFA: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Pwe/Ofa'
print, 'To show the RoR, set "ror" keyword'
print, 'Contact: erg_pwe_info at isee.nagoya-u.ac.jp'
endelse

print, '**********************************************************************'

gt1:

END
