;+
;
;NAME:
;iug_load_aws_ktb
;
;PURPOSE:
;  Queries the RISH server for the surface meterology data taken by the automatic weather 
;  station (AWS) at the Kototabang stations and loads data into tplot format.
;
;SYNTAX:
; iug_load_aws_ktb, site=site, downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;  SITE = AWS observation site.  
;         For example, iug_load_aws_ktb, site = 'ktb'.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
; 
;CODE:
;  A. Shinbori, 28/02/2013.
;  
;MODIFICATIONS:
;  A. Shinbori, 24/01/2014.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_aws_ktb, site=site, $
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
site_code_all = strsplit('ktb',' ', /extract)

;--- check site codes
if (not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if n_elements(site_code) eq 1 then begin
   if site_code eq '' then begin
      print, 'This station code is not valid. Please input the allowed keywords, all, and ktb.'
      return
   endif
endif

print, site_code

;***************
;data directory:
;***************
site_data_dir = strsplit('ktb/aws/',' ', /extract)


month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
;******************************************************************
;Loop on downloading files
;******************************************************************
;Get timespan, define FILE_NAMES, and load data:
;===============================================
;
;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
;Definition of parameter and array:
h=0L
jj=0L
kk=0L
kkk=intarr(n_elements(site_data_dir))

;In the case that the parameters are except for all.'
if n_elements(site_code) le n_elements(site_data_dir) then begin
   h_max=n_elements(site_code)
   for i=0L,n_elements(site_code)-1 do begin
      if site_code[i] eq 'ktb' then begin
         kkk[i]=0 
      endif
   endfor
endif

for ii=0L,h_max-1 do begin
   kk=kkk[ii]
   if ~size(fns,/type) then begin
     ;Definition of blr site names:
      if site_code[ii] eq 'ktb' then begin
         site_code2='kototabang'
      endif
  
     ;****************************
     ;Get files for ith component:
     ;****************************
      file_names = file_dailynames(file_format='YYYY/YYYYMM/'+$
                  'YYYYMMDD',trange=trange,times=times,/unique)+'.csv'
                     
     ;===============================
     ;Define FILE_RETRIEVE structure:
     ;===============================
      source = file_retrieve(/struct)
      source.verbose=verbose
      source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/'+site_data_dir[kk]+'csv/'
      source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/radar-group/surface/'+site_code2+'/aws/csv/'
     
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
    
     ;Read the files:
     ;===============
      
     ;Definition of string variable:
      s=''

     ;Initialize data and time buffer
      aws_time = 0
      aws_press = 0
      aws_precipi = 0
      aws_rh = 0
      aws_sr = 0
      aws_temp = 0
      aws_wnddir = 0
      aws_wndspd = 0
    
     ;==============      
     ;Loop on files: 
     ;==============
      for h=jj,n_elements(local_paths)-1 do begin
         file= local_paths[h]
         if file_test(/regular,file) then  dprint,'Loading the observation data of the troposphere taken by the AWS-'+site_code2+' :',file $
         else begin
            dprint,'The observation data of the troposphere taken by the AWS-'+site_code2+' ', file,' not found. Skipping'
            continue
         endelse
            
        openr,lun,file,/get_lun    
       ;
       ;Read information of altitude:
       ;=============================
        readf, lun, s
        readf, lun, s
             
       ;Definition of altitude and data arraies:
        time_zone = 7
            
       ;Read the data:
        while(not eof(lun)) do begin
           readf,lun,s
           ok=1
           if strmid(s,0,1) eq '[' then ok=0
           if ok && keyword_set(s) then begin
              dprint,s ,dlevel=5
              data_arr = strsplit(s,',',/extract)
              date_arr = strsplit(data_arr[0],' ',/extract)
              if n_elements(data_arr) eq 1 then break
              idx=where(month eq date_arr[1])+1

             ;Convert time from LT to UT
              time = time_double(string(date_arr[4])+'-'+string(idx)+'-'+string(date_arr[2])+'/'+string(date_arr[3])) $
                     -time_double(string(1970)+'-'+string(1)+'-'+string(1)+'/'+string(time_zone)+':'+string(0)+':'+string(0))

            ;Substitute each parameter:            
             press = data_arr[2]
             precipi = data_arr[4]
             rh = data_arr[6]
             sr = data_arr[8]
             temp = data_arr[10]
             wnddir = data_arr[12]
             wndspd = data_arr[14]

            ;Enter the missing value:
             a = float(press)
             wbad = where(data_arr[1] ne 'VALID',nbad)
             if nbad gt 0 then a[wbad] = !values.f_nan
             press=a
             b = float(precipi)
             wbad = where(data_arr[3] ne 'VALID',nbad)
             if nbad gt 0 then b[wbad] = !values.f_nan
             precipi=b
             c = float(rh)
             wbad = where(data_arr[5] ne 'VALID',nbad)
             if nbad gt 0 then c[wbad] = !values.f_nan
             rh = c
             d = float(sr)
             wbad = where(data_arr[7] ne 'VALID',nbad)
             if nbad gt 0 then d[wbad] = !values.f_nan
             sr = d
             e = float(temp)
             wbad = where(data_arr[9] ne 'VALID',nbad)
             if nbad gt 0 then e[wbad] = !values.f_nan
             temp = e
             f = float(wnddir)
             wbad = where(data_arr[11] ne 'VALID',nbad)
             if nbad gt 0 then f[wbad] = !values.f_nan
             wnddir=f
             g = float(wndspd)
             wbad = where(data_arr[13] ne 'VALID',nbad)
             if nbad gt 0 then g[wbad] = !values.f_nan
             wndspd=g            

            ;=====================================
            ;Append data of time and observations:
            ;=====================================
             append_array, aws_time, time
             append_array, aws_press,press
             append_array, aws_precipi,precipi
             append_array, aws_rh,   rh
             append_array, aws_sr,   sr
             append_array, aws_temp, temp
             append_array, aws_wnddir, wnddir
             append_array, aws_wndspd, wndspd 
             endif
          endwhile 
          free_lun,lun  
       endfor
         
      ;==============================
      ;Store data in TPLOT variables:
      ;==============================
      ;Acknowlegment string (use for creating tplot vars)
       acknowledgstring = 'If you acquire surface meteorological data, we ask that you acknowledge us in your use of the data.' $
                        + 'This may be done by including text such as surface meteorological data were obtained by the JEPP-HARIMAU ' $
                        + 'and SATREPS-MCCOE projects promoted by JAMSTEC and BPPT under collaboration with RISH of Kyoto University ' $
                        + 'and LAPAN. We would also appreciate receiving a copy of the relevant publications. ' $
                        + 'The distribution of BLR data has been partly supported by the IUGONET (Inter-university Upper ' $
                        + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '$
                        + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.' 
 
      if size(aws_press,/type) eq 4 then begin 
         dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))            
         store_data,'iug_aws_'+site_code[ii]+'_press',data={x:aws_time, y:aws_press},dlimit=dlimit
         store_data,'iug_aws_'+site_code[ii]+'_precipi',data={x:aws_time, y:aws_precipi},dlimit=dlimit
         store_data,'iug_aws_'+site_code[ii]+'_rh',data={x:aws_time, y:aws_rh},dlimit=dlimit
         store_data,'iug_aws_'+site_code[ii]+'_sr',data={x:aws_time, y:aws_sr},dlimit=dlimit
         store_data,'iug_aws_'+site_code[ii]+'_temp',data={x:aws_time, y:aws_temp},dlimit=dlimit
         store_data,'iug_aws_'+site_code[ii]+'_wnddir',data={x:aws_time, y:aws_wnddir},dlimit=dlimit
         store_data,'iug_aws_'+site_code[ii]+'_wndspd',data={x:aws_time, y:aws_wndspd},dlimit=dlimit
         new_vars=tnames('iug_aws_'+site_code[ii]+'_press')
         if new_vars[0] ne '' then begin 
            options,'iug_aws_'+site_code[ii]+'_press',ytitle='AWS-'+site_code[ii]+'!CPress.!C[hPa]'
            options,'iug_aws_'+site_code[ii]+'_precipi',ytitle='AWS-'+site_code[ii]+'!CPrecipi.!C[mm]'
            options,'iug_aws_'+site_code[ii]+'_rh',ytitle='AWS-'+site_code[ii]+'!CRH!C[%]'
            options,'iug_aws_'+site_code[ii]+'_sr',ytitle='AWS-'+site_code[ii]+'!CSolar rad.!C[kW/m2]'
            options,'iug_aws_'+site_code[ii]+'_temp',ytitle='AWS-'+site_code[ii]+'!CTemp.!C[degree C]'
            options,'iug_aws_'+site_code[ii]+'_wnddir',ytitle='AWS-'+site_code[ii]+'!CWind dirction!C[degree]'
            options,'iug_aws_'+site_code[ii]+'_wndspd',ytitle='AWS-'+site_code[ii]+'!CWind speed!C[m/s]'
         endif 
      endif
     ;Clear time and data buffer:
      aws_time = 0
      aws_press = 0
      aws_sr = 0
      aws_rh = 0
      aws_temp = 0
      aws_wnddir = 0
      aws_wndspd = 0
      
      new_vars=tnames('iug_aws_'+site_code[ii]+'_press')
      if new_vars[0] ne '' then begin          
        ;Add tdegap
         tdegap, 'iug_aws_'+site_code[ii]+'_press',/overwrite
         tdegap, 'iug_aws_'+site_code[ii]+'_precipi',/overwrite
         tdegap, 'iug_aws_'+site_code[ii]+'_rh',/overwrite
         tdegap, 'iug_aws_'+site_code[ii]+'_sr',/overwrite
         tdegap, 'iug_aws_'+site_code[ii]+'_temp',/overwrite
         tdegap, 'iug_aws_'+site_code[ii]+'_wnddir',/overwrite
         tdegap, 'iug_aws_'+site_code[ii]+'_wndspd',/overwrite
      endif
   endif
   jj=n_elements(local_paths)
endfor 

new_vars=tnames('iug_aws_*')
if new_vars[0] ne '' then begin    
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

;*************************
;print of acknowledgement:
;*************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire surface meteorological data, we ask that you acknowledge us in your use of the data. '
print, 'This may be done by including text such as surface meteorological data were obtained by the JEPP-HARIMAU ' 
print, 'and SATREPS-MCCOE projects promoted by JAMSTEC and BPPT under collaboration with RISH of Kyoto University ' 
print, 'and LAPAN. We would also appreciate receiving a copy of the relevant publications ' 
print, 'The distribution of BLR data has been partly supported by the IUGONET (Inter-university Upper '
print, 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '
print, 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
end

