;+
;Procedure: iug_load_iprt,
;  iug_load_iprt, datatype = datatype, $
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
;  26-MAR.-2020, revised by F. Tsuchiya (swap definition of databufR for databufL)
;
;Acknowledgment:
;
;
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/load/iug_load_iprt.pro $
;-



;**************************
;***** Main Procedure *****
;**************************
pro iug_load_iprt, datatype = datatype, $
             trange = trange, verbose = verbose, $
             downloadonly = downloadonly


;*************************
;***** Keyword check *****
;*************************
; verbose
if ~keyword_set(verbose) then verbose=0

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

; define file names
relpathnames = file_dailynames(file_format='/YYYY/YYYYMMDD_IPRT', $
                               trange=trange, addmaster=addmaster)+'.fits'

; define remote and local path information
source = file_retrieve(/struct)
source.verbose = verbose
source.local_data_dir = root_data_dir() + 'iugonet/tohokuU/iit/'
source.remote_data_dir = 'http://radio.gp.tohoku.ac.jp/db/IPRT-SUN/DATA2/'

; download data
local_files = spd_download(remote_file=relpathnames, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)

; if downloadonly set, go to the top of this loop
if keyword_set(downloadonly) then return

;===================================
;=== Loop on reading MAGDAS data ===
;===================================
print,(local_files)

for j=0,n_elements(local_files)-1 do begin
  file = local_files[j]

  if file_test(/regular,file) then begin
    dprint,'Loading IPRT SOLAR RADIO DATA file: ', file
    fexist = 1
  endif else begin
    dprint,'Loading IPRT SOLAR RADIO DATA file ',file,' not found. Skipping'
    continue
  endelse

  ; create base time
  year = (strmid(relpathnames[j],strlen(relpathnames[j])-18,4))
  month = (strmid(relpathnames[j],strlen(relpathnames[j])-14,2))
  ;day = (strmid(relpathnames[j],27,2))
  ;basetime = time_double(year+'-'+month+'-'+day)


  ;===================================
  fits_read,file,data,hd
  date_start = time_double(sxpar(hd,'DATE-OBS')+'/'+sxpar(hd,'TIME-OBS'))
  timearr = date_start $
       + sxpar(hd,'CRVAL1') + (dindgen(sxpar(hd,'NAXIS1'))-sxpar(hd,'CRPIX1')) * sxpar(hd,'CDELT1')
  freq = sxpar(hd,'CRVAL2') + (dindgen(sxpar(hd,'NAXIS2'))-sxpar(hd,'CRPIX2')) * sxpar(hd,'CDELT2')
  ;dindgen(sxpar(hd,'NAXIS2'))

;print,time_string(date_start)
;stop
;    buf = fltarr(6)
;    line=''
;    yy=0L & mm=0L & dd=0L & doy=0L & pc3i=0. & pc3p=0.
;    openr,lun,file, /get_lun
;    readf,lun,line ; file header
;    readf,lun,line ; file header
;    readf,lun,line ; file header
    ;readf,lun,yy,mm,dd,doy,pc3i,pc3p
;    while not eof(lun) do begin
;      readf,lun,buf
      ;yy=[yy,buf[0]]
;      mm=[mm,buf[1]]
      ;dd=[dd,buf[2]]
      ;doy=[doy,buf[3]]
;      pc3i=[pc3i,buf[4]]
     ; pc3p=[pc3p,buf[5]]
    ;endwhile
;    free_lun,lun
  append_array,databufR,data[*,*,0]
  append_array,databufL,data[*,*,1]
  append_array,timebuf,timearr
  ;===================================
;stop
;    ; open file
;    openr, lun, file, /get_lun
;
;    ; seek delimiter
;    buf = bytarr(1, 1)
;    while (buf ne 26) do begin
;      readu, lun, buf
;    end
;    readu, lun, buf
;
;    ; read data
;    rdata = fltarr(7, 1440)
;    readu, lun, rdata
;    rdata = transpose(rdata)
;
;    ; close file
;    free_lun, lun
;
;    ; append data and time index
;    append_array, databuf, rdata
;    append_array, timebuf, basetime + dindgen(1440)*60d

endfor

;=======================================
;=== Loop on creating tplot variable ===
;=======================================
if size(databufL,/type) eq 1 then begin
  ; tplot variable name
  ;tplot_name = 'onw_pc3_' + strlowcase(strmid(magdas_sites[i],0,3)) + '_pc3'
  tplot_nameL = 'iprt_sun_L'
  tplot_nameR = 'iprt_sun_R'

  ; for bad data
  wbad = where(finite(databufL) gt 99999, nbad)
  if nbad gt 0 then databufL[wbad] = !values.f_nan

  wbad = where(databufL lt 0, nbad)
  if nbad gt 0 then databuL[wbad] = !values.f_nan

  ; default limit structure
  dlimit=create_struct('data_att',create_struct('acknowledgment', acknowledgstring, $
                                                'PI_NAME', 'H. Misawa') $
                      ,'SPEC',1)

  ; store data to tplot variable
  databufL /= 10.0  ; unit convertion [dB from background] 
  databufR /= 10.0  ; unit convertion [dB from background]
  store_data, tplot_nameL, data={x:timebuf, y:databufL, v:freq}, dlimit=dlimit
  store_data, tplot_nameR, data={x:timebuf, y:databufR, v:freq}, dlimit=dlimit

  ; add options
  options, tplot_nameL, labels=['IPRT_SUN_LCP'] , $
                       ytitle = sxpar(hd,'CTYPE2'), $
                       ysubtitle = 'LCP', $
                       ztitle = 'dB from background', $
                       datagap = 10
;                       title = 'IPRT Solar radio data'
  options, tplot_nameR, labels=['IPRT_SUN_RCP'] , $
                       ytitle = sxpar(hd,'CTYPE2'), $
                       ysubtitle = 'RCP', $
                       ztitle = 'dB from background', $
                       datagap = 10
;                     title = 'IPRT Solar radio data', $
endif

; clear data and time buffer
databufL = 0
databufR = 0
timebuf = 0

; go to next site
;;endfor

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
