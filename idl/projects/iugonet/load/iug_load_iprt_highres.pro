;+
;Procedure: iug_load_iprt_highres,
;  iug_load_iprt_highres, datatype = datatype, numbit=numbit, version=version, $
;           trange = trange, verbose = verbose, $
;           downloadonly = downloadonly
;Purpose:
;  This procedure allows you to download and plot TOHOKUU_RADIO OBSERVATION data on TDAS.
;  This is a sample code for IUGONET analysis software.
;
;Keywords:
;  datatype = The type of data to be loaded.  In this sample
;             procedure, there is only one option, the default value of 'Sun'.
;  trange = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /verbose, if set, then output some useful info
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;
; PROCEDURES USED:
;  fits_read, sxpar, fits_open, fits_close, gettok, sxdelpar, sxaddpar, valid_num
;  For the use of this procedure, get FITS I/O procedures from
;  the IDL Astronomy Library (http://idlastro.gsfc.nasa.gov/fitsio.html).
;  You can download these procedures by running get_fitslib.
;
;
;Example:
; timespan,'2010-11-03',1,/hours
;  iug_load_iprt
;  tplot_names
;  zlim,'iprt_sun_L',20,120
;  zlim,'iprt_sun_R',20,120
;  tplot,['iprt_sun_L','iprt_sun_R']
;
;
;Code:
;  Shuji Abe, revised by M. Kagitani
;
;ChangeLog:
;  7-April-2010, abeshu, test release.
;  8-April-2010, abeshu, minor update.
;  27-JUL.-2010, revised for this procedure by M. Kagitani
;  12-NOV.-2010, revised by M. Kagitani
;  25-NOV.-2010, renamed to 'iug_load_iprt.pro' by M. Kagitani
;  22-JAN.-2014, revised by M. Yagi
;  22-NOV.-2017, revised by F. Tsuchiya
;
;Acknowledgment:
;
;
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/tags/spedas_2_00/projects/iugonet/load/iug_load_iprt.pro $
;-



;**************************
;***** Main Procedure *****
;**************************
pro iug_load_iprt_highres, datatype = datatype, numbit = numbit, subtract_bg=subtract_bg, $
             version = version, trange = trange, verbose = verbose, $
             downloadonly = downloadonly, no_download = no_download


;*************************
;***** Keyword check *****
;*************************
; verbose
if ~keyword_set(verbose) then verbose=0
if ~keyword_set(downloadonly) then downloadonly=0
if ~keyword_set(no_download) then no_download=0

; dafault data type
if ~keyword_set(datatype) then datatype='Sun'

; validate datatype
vns=['Sun'];vns=['Sun','Jupiter']
if size(datatype,/type) eq 7 then begin
  datatype=ssl_check_valid_name(datatype,vns, $
                                /ignore_case, /include_all);, /no_warning)

if datatype[0] eq '' then begin
  dprint,'IPRT file ',file,' not found. Skipping'
    ;continue
  endif
endif else begin
  dprint,'DATATYPE must be of string type.'
;  continue
endelse

; dafault bit
if ~keyword_set(numbit) then begin
    numbit=8
	res=60
endif else begin
	case numbit of
	    8: res=60
	    16: res=60
		else: dprint,'The numbit must be 8 or 16.'
    endcase
endelse
strbit=string(numbit, format='(i02)')

; dafault version
if ~keyword_set(version) then version=1
strver=string(version, format='(i02)')

; subtract_bg
if ~keyword_set(subtract_bg) then subtract_bg=0

; acknowlegment string (use for creating tplot vars)
acknowledgstring = '"We would like to present the following two guidelines.' $
+ 'The 1st one concerns what we would like you to do when you use the data.' $
+ '1. Tell us what you are working on.' $
+ 'This is partly because to protect potential Ph.D. thesis projects.' $
+ 'Also, if your project coincides with one that team members are working on,' $
+ 'that can lead to a fruitful collaboration. The 2nd one concerns what you do '$
+ 'when you make any presentations and publications using the data.' $
+ '2. Co-authorship:' $
+ 'When the data forms an important part of your work, we would like you to '$
+ 'offer us co-authorship.' $
+ '3. Acknowledgements:' $
+ 'All presentations and publications should carry the following sentence:' $
+ ' "IPRT(Iitate Planetary Radio Telescope) is a Japanese radio telescope '$
+ 'developed and operated by Tohoku University."' $
+ '4. Entry to publication list:'$
+ 'When your publication is accepted, or when you make a presentation at a '$
+ 'conference on your result, please let us know by sending email to PI.'$
+ 'Contact person & PI: Dr. Hiroaki Misawa (misawa@pparc.gp.tohoku.ac.jp)'


;************************************************************
;***** Download files, read data, and create tplot vars *****
;************************************************************
;=================================
;=== Loop on downloading files ===
;=================================
; make remote path, local path, and download files

relpathnames = file_dailynames(file_format='high'+strbit+$
                        '/YYYY/YYYYMMDD/iprt_amt_l1_high_'+strbit+$
                        'bit_YYYYMMDD-hhmm_v'+strver, $
                         trange=trange, res=res, addmaster=addmaster)+'.fits'

; define file names
;relpathnames = file_dailynames(file_format='/YYYY/YYYYMMDD_IPRT', $
;                               trange=trange, addmaster=addmaster)+'.fits'

; define remote and local path information
source = file_retrieve(/struct)
source.verbose = verbose
source.local_data_dir = root_data_dir() + 'iugonet/tohokuU/iit/'
; source.remote_data_dir = 'http://radio.gp.tohoku.ac.jp/db/IPRT-SUN/DATA2/'
source.remote_data_dir = 'http://radio.gp.tohoku.ac.jp/db/IPRT-SUN/l1/'

print, relpathnames

; download data
files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, no_download=no_download, /last_version)

; if downloadonly set, go to the top of this loop
if keyword_set(downloadonly) then return

filestest=file_test(files)
if total(filestest) ge 1 then begin
    files=files(where(filestest eq 1))

    print, files

    ;===================================
    ;=== Loop on reading IPRT data ===
    ;===================================
	xvec_r='' & yvec_r=''
	xvec_l='' & yvec_l=''
    for ifile=0, n_elements(files)-1 do begin
	    print, files[ifile]
        iug_ant_fits2tplot, files[ifile], subtract_bg=subtract_bg

        get_data, 'iprt_r', data=d, dlim=dlim_r, lim=lim_r
        append_array, xvec_r, d.x
		append_array, yvec_r, d.y
		vvec_r=d.v
        get_data, 'iprt_l', data=d, dlim=dlim_l, lim=lim_l
        append_array, xvec_l, d.x
		append_array, yvec_l, d.y
		vvec_l=d.v
    endfor
	store_data, 'iprt_r', data={x:xvec_r, y:yvec_r, v:vvec_r}, dlim=dlim_r, lim=lim_r
	store_data, 'iprt_l', data={x:xvec_l, y:yvec_l, v:vvec_l}, dlim=dlim_l, lim=lim_l
endif

;******************************
;print of acknowledgement:
;******************************
print, 'We would like to present the following two guidelines.' 
print, 'The 1st one concerns what we would like you to do when you use the data.' 
print, '1. Tell us what you are working on.' 
print, 'This is partly because to protect potential Ph.D. thesis projects.' 
print, 'Also, if your project coincides with one that team members are working on,' 
print, 'that can lead to a fruitful collaboration. The 2nd one concerns what you do '
print, 'when you make any presentations and publications using the data.' 
print, '2. Co-authorship:' 
print, 'When the data forms an important part of your work, we would like you to '
print, 'offer us co-authorship.' 
print, '3. Acknowledgements:' 
print, 'All presentations and publications should carry the following sentence:' 
print, ' "IPRT(Iitate Planetary Radio Telescope) is a Japanese radio telescope '
print, 'developed and operated by Tohoku University."' 
print, '4. Entry to publication list:'
print, 'When your publication is accepted, or when you make a presentation at a '
print, 'conference on your result, please let us know by sending email to PI.'
print, 'Contact person & PI: Dr. Hiroaki Misawa (misawa@pparc.gp.tohoku.ac.jp)'

end
