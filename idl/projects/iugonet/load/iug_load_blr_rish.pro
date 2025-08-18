;+
;
;NAME:
;iug_load_blr_rish
;
;PURPOSE:
;  Queries the Kyoto_RISH server for the CSV data (uwnd, vwnd, wwnd, pwr1-5, wdt1-5) 
;  of the troposphere taken by the boundary layer radar (BLR) at Kototabang, Shigaraki and Serpong
;  and loads data into tplot format.
;
;SYNTAX:
; iug_load_blr_rish, site=site, parameter=parameter, $
;                    downloadonly=downloadonly, trange=trange, verbose=verbose
;
;KEYWOARDS:
;   SITE = BLR observation site.  
;          For example, iug_load_blr_rish, site = 'ktb'.
;          The default is 'all', i.e., load all available observation points.
;  PARAMETER = parameter name of BLR obervation data.  
;          For example, iug_load_blr_rish, parameter = 'uwnd'.
;          The default is 'all', i.e., load all available parameters.
;  TRANGE = (Optional) Time range of interest  (2 element array), if
;          this is not set, the default is to prompt the user. Note
;          that if the input time range is not a full day, a full
;          day's data is loaded.
;  /downloadonly, if set, then only download the data, do not load it
;                 into variables.
;  VERBOSE: [1,...,5], Get more detailed (higher number) command line output.
; 
;CODE:
;  A. Shinbori, 09/09/2010.
;  
;MODIFICATIONS:
;  A. Shinbori, 03/23/2011.
;  A. Shinbori, 12/26/2011.
;  A. Shinbori, 31/01/2012.
;  A. Shinbori, 10/02/2012.
;  A. Shinbori, 17/12/2012.
;  A. Shinbori, 27/02/2013.
;  A. Shinbori, 24/01/2014.
;  A. Shinbori, 08/08/2017.
;  A. Shinbori, 30/11/2017.
;   
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_load_blr_rish, site=site, $
  parameter=parameter, $
  downloadonly=downloadonly, $
  trange=trange, $
  verbose=verbose

;**************
;keyword check:
;**************
if (not keyword_set(verbose)) then verbose=2

;**************
;keyword check:
;**************
if not keyword_set(trange) then begin
  get_timespan, time_org
endif else begin
  time_org = time_double(trange)
endelse

;***********
;site codes:
;***********
;--- all sites (default)
site_code_all = strsplit('ktb sgk srp',' ', /extract)

;--- check site codes
if (not keyword_set(site)) then site='all'
site_code = ssl_check_valid_name(site, site_code_all, /ignore_case, /include_all)

if n_elements(site_code) eq 1 then begin
   if site_code eq '' then begin
      print, 'This station code is not valid. Please input the allowed keywords, all, ktb, sgk, and srp.'
      return
   endif
endif
print, site_code
 
;***********
;parameters:
;***********
;--- all parameters (default)
parameter_all = strsplit('uwnd vwnd wwnd pwr1 pwr2 pwr3 pwr4 pwr5 wdt1 wdt2 wdt3 wdt4 wdt5',' ', /extract)

;--- check parameters
if(not keyword_set(parameter)) then parameter='all'
parameters = ssl_check_valid_name(parameter, parameter_all, /ignore_case, /include_all)

print, parameters

;***************
;Data directory:
;***************
site_data_dir = strsplit('ktb/blr/ sgk/blr/ srp/blr/ ',' ', /extract)

;*****************
;Defition of unit:
;*****************
;--- all units (default)
unit_all = strsplit('m/s dB',' ', /extract)

;**************************
;Loop on downloading files:
;**************************

;===================================================================
;Download files, read data, and create tplot vars at each component:
;===================================================================
;Definition of parameter and array:
h=0L
jj=0L
k=0L
n_site=intarr(n_elements(site_data_dir))
time_shift =dblarr(n_elements(site_data_dir))

start_time=time_double('1992-04-13')
end_time=time_double('1992-08-29')


;---In the case that the parameters are except for all.'
if n_elements(site_code) le n_elements(site_data_dir) then begin
   h_max=n_elements(site_code)
   for i=0L,n_elements(site_code)-1 do begin
      case site_code[i] of
         'ktb':n_site[i]=0
         'sgk':n_site[i]=1 
         'srp':n_site[i]=2 
      endcase
      case site_code[i] of
        'ktb':time_shift[i] = 7.0d
        'sgk':time_shift[i] = 9.0d
        'srp':time_shift[i] = 7.0d
      endcase
   endfor
endif

for ii=0L,h_max-1 do begin
   
   k=n_site[ii]
   for iii=0L,n_elements(parameters)-1 do begin
  
     ;==============================================================
     ;Change time window associated with a time shift from UT to LT:
     ;==============================================================
      day_org = (time_org[1] - time_org[0])/86400.d
      day_mod = day_org + 1.0
      timespan, time_org[0] - time_shift[ii] * 3600.0d, day_mod
      if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) + time_shift[ii] * 3600.d0); for GUI

      if ~size(fns,/type) then begin
        ;---Definition of blr site names:
         case site_code[ii] of
            'ktb':site_code2='kototabang'
            'sgk':site_code2='shigaraki'
            'srp':site_code2='serpong' 
         endcase
                          
        ;****************************  
        ;Get files for ith component:
        ;****************************
         file_names = file_dailynames( $
         file_format='YYYYMM/YYYYMMDD/'+$
                     'YYYYMMDD',trange=trange,times=times,/unique)+'.'+parameters[iii]+'.csv'
                     
        ;---Set up the start time of the BLR data period at Shigaraki:
         in_time =  file_dailynames(file_format='YYYYMMDD',trange=trange,times=times,/unique)
         data_time = time_double(strmid(in_time,0,4)+'-'+strmid(in_time,4,2)+'-'+strmid(in_time,6,2)) 
         if site_code[ii] eq 'sgk' then begin  
            if (data_time[0] lt start_time) or (data_time[0] gt end_time) then break
         endif
                     
        ;===============================
        ;Define FILE_RETRIEVE structure:
        ;===============================
         source = file_retrieve(/struct)
         source.verbose=verbose
         source.local_data_dir = root_data_dir() + 'iugonet/rish/misc/'+site_data_dir[k]+'csv/'
         source.remote_data_dir = 'http://www.rish.kyoto-u.ac.jp/radar-group/blr/'+site_code2+'/data/data/ver02.0212/'

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
      
        ;---Definition of string parameter:
         s=''
         
        ;==============
        ;Loop on files: 
        ;==============
         for h=jj,n_elements(local_paths)-1 do begin
            file= local_paths[h]
            if file_test(/regular,file) then  dprint,'Loading the observation data of the troposphere taken by the BLR-'+site_code2+' :',file $
            else begin
               dprint,'The observation data of the troposphere taken by the BLR-'+site_code2+' ', file,' not found. Skipping'
               continue
            endelse
           
           ;---Open the read file: 
            openr,lun,file,/get_lun    
            
           ;=============================
           ;Read information of altitude:
           ;=============================
            readf, lun, s
            height = strsplit(s,',',/extract)
             
           ;---Definition of altitude and data arraies:
            altitude = fltarr(n_elements(height)-1)
            data = strarr(n_elements(height)-1)
            data2 = fltarr(1,n_elements(height)-1)
             
           ;---Enter the altitude information:
            for j=0L,n_elements(height)-2 do begin
               altitude[j] = float(height[j+1])
            endfor
             
           ;---Enter the missing value:
            for j=0L, n_elements(altitude)-1 do begin
               b = float(altitude[j])
               wbad = where(b eq 0,nbad)
               if nbad gt 0 then b[wbad] = !values.f_nan
               data[j] = !values.f_nan
               data2[0,j] = !values.f_nan
               altitude[j]=b
            endfor

           ;=================
           ;Loop on readdata:
           ;=================
            while(not eof(lun)) do begin
               readf,lun,s
               ok=1
               if strmid(s,0,1) eq '[' then ok=0
               if ok && keyword_set(s) then begin
                  dprint,s ,dlevel=5
                  data = strsplit(s,',',/extract)
                    
                 ;---Definition of parameters for time convert from LT to UT:
                  year = strmid(data[0],0,4)
                  month = strmid(data[0],5,2)
                  day = strmid(data[0],8,2)
                  hour = strmid(data[0],11,2)
                  minute = strmid(data[0],14,2) 
                   
                 ;---Convert time from LT to UT    
                  blr_data_time = time_double(string(year)+'-'+string(month)+'-'+string(day)+'/'+string(hour)+':'+string(minute)) - time_shift[ii] * 3600.0d
                  if (site_code[ii] eq 'sgk') and (blr_data_time gt time_double(string(1992)+'-'+string(9)+'-'+string(1)+'/'+string(0)+':'+string(0)+':'+string(0))) then break
                            
                 ;---Enter the missing value:
                  for j=0,n_elements(height)-2 do begin
                     a = float(data[j+1])
                     wbad = where(a eq 999,nbad)
                     if nbad gt 0 then a[wbad] = !values.f_nan
                     data2[0,j]=a
                  endfor
                 
                 ;=============================
                 ;Append data of time and data:
                 ;=============================
                  append_array, blr_data_time_app, blr_data_time
                  append_array, blr_data_app, data2 

               endif
            endwhile 
            free_lun,lun  
         endfor

        ;==============================================================
        ;Change time window associated with a time shift from UT to LT:
        ;==============================================================
         timespan, time_org
         get_timespan, init_time2
         if keyword_set(trange) then trange[1] = time_string(time_double(trange[1]) - 9.0d * 3600.0d); for GUI
         
        ;==============================
        ;Store data in TPLOT variables:
        ;==============================
        ;---Acknowlegment string (use for creating tplot vars)
         acknowledgstring = 'If you acquire the boundary layer radar (BLR) data, ' $
                          + 'we ask that you acknowledge us in your use of the data. This may be done by' $
                          + 'including text such as the BLR data provided by Research Institute' $
                          + 'for Sustainable Humanosphere of Kyoto University. We would also' $
                          + 'appreciate receiving a copy of the relevant publications. The distribution of '$
                          + 'BLR data has been partly supported by the IUGONET (Inter-university Upper '$
                          + 'atmosphere Global Observation NETwork) project (http://www.iugonet.org/) funded '$
                          + 'by the Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'
          
         if size(blr_data_app,/type) eq 4 then begin 
            o=0 
            if parameters[iii] eq 'pwr1' then o=1  
            if parameters[iii] eq 'pwr2' then o=1
            if parameters[iii] eq 'pwr3' then o=1
            if parameters[iii] eq 'pwr4' then o=1
            if parameters[iii] eq 'pwr5' then o=1
           
           ;---Create the tplot variables:
            dlimit=create_struct('data_att',create_struct('acknowledgment',acknowledgstring,'PI_NAME', 'H. Hashiguchi'))            
            store_data,'iug_blr_'+site_code[ii]+'_'+parameters[iii],data={x:blr_data_time_app, y:blr_data_app, v:altitude},dlimit=dlimit

           ;----Edge data cut:
            time_clip, 'iug_blr_'+site_code[ii]+'_'+parameters[iii], init_time2[0], init_time2[1], newname = 'iug_blr_'+site_code[ii]+'_'+parameters[iii]
           
           ;---Options of each tplot variable
            new_vars=tnames('iug_blr_'+site_code[ii]+'_'+parameters[iii])
            if new_vars[0] ne '' then begin 
               options,'iug_blr_'+site_code[ii]+'_'+parameters[iii],ytitle='BLR-'+site_code[ii]+'!CHeight!C[km]',$
                        ztitle=parameters[iii]+'!C['+unit_all[o]+']'
               options, 'iug_blr_'+site_code[ii]+'_'+parameters[iii], 'spec', 1   
            endif 
         endif

        ;---Clear time and data buffer:
         blr_data_time_app = 0
         blr_data_app = 0

        ;---Add tdegap
         new_vars=tnames('iug_blr_'+site_code[ii]+'_'+parameters[iii])
         if new_vars[0] ne '' then begin          
            tdegap, 'iug_blr_'+site_code[ii]+'_'+parameters[iii],/overwrite
         endif
      endif
      jj=n_elements(local_paths)
     ;---Initialization of timespan for parameters 
      timespan, time_org
   endfor
   jj=n_elements(local_paths)
  ;---Initialization of timespan for sites
   timespan, time_org
endfor 

new_vars=tnames('iug_blr_*')
if new_vars[0] ne '' then begin    
   print,'*****************************
   print,'Data loading is successful!!'
   print,'*****************************
endif

;**************************
;Print of acknowledgement:
;**************************
print, '****************************************************************
print, 'Acknowledgement'
print, '****************************************************************
print, 'If you acquire BLR data, we ask that you acknowledge us in your use'
print, 'of the data. This may be done by including text such as BLR data' 
print, 'provided by Research Institute for Sustainable Humanosphere of' 
print, 'Kyoto University. We would also appreciate receiving a copy of the' 
print, 'relevant publications. The distribution of BLR data has been partly'
print, 'supported by the IUGONET (Inter-university Upper atmosphere Global'
print, 'Observation NETwork) project (http://www.iugonet.org/) funded by the'
print, 'Ministry of Education, Culture, Sports, Science and Technology (MEXT), Japan.'

end

