;+
;
;NAME:
;iug_load_ionosonde_rish
;
;PURPOSE:
;  Queries the RISH server for the ionogram data taken by the ionosonde 
;  at Shigaraki and loads data into tplot format.
;
;SYNTAX:
; iug_load_ionosonde_rish, site=site, fixed_freq = fixed_freq, $
;                    downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS: 
;  SITE = Ionosonde observation site.  
;         For example, iug_load_ionosonde_rish, site = 'sgk'.
;         The default is 'all', i.e., load all available observation points.
;  /fixed_freq, if set, then tplot variables for every fixed frequency (2-18 MHZ) are created.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
;  
;CODE:
;  A. Shinbori, 24/10/2012.
;  
;MODIFICATIONS:
;  A. Shinbori, 12/11/2012.
;  A. Shinbori, 18/12/2012.
;  A. Shinbori, 09/01/2013.
;  A. Shinbori, 18/02/2013.
;  A. Shinbori, 24/01/2014.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-05-19 11:44:55 -0700 (Fri, 19 May 2017) $
; $LastChangedRevision: 23337 $
; $URL $
;-

pro iug_load_ionosonde_rish, site=site, $
  fixed_freq = fixed_freq, $
  downloadonly=downloadonly, $
  trange=trange, verbose=verbose

;**********************
;Verbose keyword check:
;**********************
if (not keyword_set(verbose)) then verbose=2

;****************
;Site code check:
;****************
;--- all sites (default)
site_code_all = strsplit('sgk',' ', /extract)

;--- check site codes
if (not keyword_set(site)) then site='all'
site_code = strlowcase(ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all))

if n_elements(site_code) eq 1 then begin
   if site_code eq '' then begin
      print, 'This station code is not valid. Please input the allowed keywords, all, and sgk.'
      return
   endif
endif
print, site_code

;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
if ~size(fns,/type) then begin
  ;****************************
  ;Get files for ith component:
  ;****************************
   file_names = file_dailynames_iug( $
                file_format='YYYY/YYYYMM/YYYYMMDD/'+$
                             'YYYYMMDDhhmm',trange=trange,times=times,/unique,/minute_res)+'_ionogram.txt'                       
  
  ;===============================            
  ;Define FILE_RETRIEVE structure:
  ;===============================
   source = file_retrieve(/struct)
   source.verbose=verbose
   source.local_data_dir =  root_data_dir() + 'iugonet/rish/misc/'+site_code+'/ionosonde/text/'
   source.remote_data_dir = 'http://database.rish.kyoto-u.ac.jp/arch/mudb/data/ionosonde/text/'
  
  ;=======================================================  
  ;Get files and local paths, and concatenate local paths:
  ;=======================================================
  local_paths = spd_download(remote_file=file_names, remote_path=source.remote_data_dir, local_path=source.local_data_dir, _extra=source, /last_version)
   local_paths_all = ~(~size(local_paths_all,/type)) ? $
                    [local_paths_all, local_paths] : local_paths
   if ~(~size(local_paths_all,/type)) then local_paths=local_paths_all
endif else file_names=fns

;--- Load data into tplot variables
if (not keyword_set(downloadonly)) then downloadonly=0

if (downloadonly eq 0) then begin
   ;===============
   ;Read the files:
   ;===============
   ;---Definition of parameters and array:
    s=''
    header_data = strarr(9)

   ;==============      
   ;Loop on files: 
   ;==============        
    for j=0L,n_elements(local_paths_all)-1 do begin
       file=local_paths_all[j]
       if file_test(/regular,file) then  dprint,'Loading the ionogram data taken by the ionosonde at Shigaraki:',file $
       else begin
          dprint,'The ionogram data taken by the ionosonde at Shigaraki', file,' not found. Skipping'
          continue
       endelse
       
      ;---Check file line:   
       lines = file_lines(file)
       
      ;---Open the read file:     
       openr,lun,file,/get_lun    
      
      ;================================
      ;Read information of header data:
      ;================================
       for i=0L, n_elements(header_data)-1 do begin
          readf, lun, s
          header_data[i]=s
       endfor      

      ;---Date and hh:mm data and definition of data array:
       date = strmid(header_data[1],12,10)
       hhmm = strmid(header_data[1],23,5)
       time = time_double(string(date)+'/'+string(hhmm))-3600*9
      
      ;---Read the frequency data:
       readf,lun, s
       freq = float(strsplit(s,' ',/extract))
       intensity = fltarr(1,n_elements(freq))
          
      ;Read the data:
       while(not eof(lun)) do begin  
          readf,lun, s
          data = float(strsplit(s,' ',/extract))
          height = data[0]
          intensity [0,*] =data[1:n_elements(data)-1]
         
         ;================================
         ;Append array of height and data:
         ;================================
          append_array, height2, height
          append_array, intensity2,intensity
          height3= height2
       endwhile
       free_lun,lun
            
       intensity3 = transpose(intensity2)
       intensity_all_f = fltarr(1,n_elements(freq),n_elements(height3)) 
       intensity_all_f[0,*,*] = intensity3    

      ;==============================
      ;Append array of time and data:
      ;==============================       
       append_array, site_time, time
       append_array, intensity_all_f2,intensity_all_f

      ;---Clear the buffer:
       height2 = 0
       intensity2 = 0
    endfor
  ;==============================
  ;Store data in TPLOT variables:
  ;==============================
  ;---Acknowlegment string (use for creating tplot vars)
   acknowledgstring = 'If you acquire the ionogram data, ' $
                     + 'we ask that you acknowledge us in your use of the data. This may be done by' $
                     + 'including text such as the ionogram data provided by Research Institute' $
                     + 'for Sustainable Humanosphere of Kyoto University. We would also' $
                     + 'appreciate receiving a copy of the relevant publications. The distribution of ' $
                     + 'ionogram data has been partly supported by the IUGONET (Inter-university Upper ' $
                     + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded ' $
                     + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'    
                         
   dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'M. Yamamoto'))
   if size(intensity_all_f2,/type) eq 4 then begin
     ;==========================================
     ;Create tplot variables for ionogram data: 
     ;========================================== 
      if not keyword_set(fixed_freq) then begin
         store_data,'iug_ionosonde_sgk_ionogram',data={x:site_time,y:intensity_all_f2,v1:freq,v2:height3},dlimit=dlimit
      endif

     ;===========================================================
     ;Create tplot variables for every fixed frequency (2-18 MHz) 
     ;=========================================================== 
      if keyword_set(fixed_freq) then begin
         for i=0L, n_elements(freq)-1 do begin
            power = fltarr(n_elements(site_time),n_elements(height3))
            power[*,*] = intensity_all_f2[*,i,*]
            if (i mod 10) eq 0 then begin
               store_data,'iug_ionosonde_sgk_freq_'+strtrim(string(i/10+2),2)+'MHz',data={x:site_time,y:power,v:height3},dlimit=dlimit
              ;---Add options
               options,'iug_ionosonde_sgk_freq_'+strtrim(string(i/10+2),2)+'MHz',ytitle = 'Height [km]', ztitle = 'Echo power at '+strtrim(string(i/10+2),2)+' [MHz]'
               options, 'iug_ionosonde_sgk_freq_'+strtrim(string(i/10+2),2)+'MHz', spec=1
            endif
         endfor    
      endif
   endif
endif   

;---Clear time and data buffer:
site_time = 0
aintensity_all_f2 = 0
height3 = 0

new_vars=tnames('iug_ionosonde_sgk_*')
if new_vars[0] ne '' then begin    
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

;*************************
;Print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire the ionogram data, we ask that you acknowledge us '
print, 'in your useof the data. This may be done by including text such as '
print, 'the ionogram data provided by Research Institute for Sustainable '
print, 'Humanosphere of Kyoto University. We would also appreciate receiving '
print, 'a copy of the relevant publications. The distribution of ionogram data '
print, 'has been partly supported by the IUGONET (Inter-university Upper '
print, 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) '
print, 'funded by the Ministry of Education, Culture, Sports, Science and ' 
print, 'Technology (MEXT), Japan.'

end


