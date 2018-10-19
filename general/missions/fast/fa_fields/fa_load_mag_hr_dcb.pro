;+
;
;NAME:
;  fa_load_mag_hr_dcb
;
;PURPOSE:
;  Loads FAST high rate dc magnetic field(DCB) data using SPDF web services.
;  Imports into tplot
;
;Keywords:
;  trange: specify data time range different from the one provided by timespan/timerange()
;  tplotnames: get a list of the loaded variables
;
;NOTES:
;  #1 Data available(sporadically) for dates 1996-09-28 to 1998-10-09
;    good test date: timespan,'1998-10-01',3,/hour
;  #2 Dataset and import advice courtesy of Bob Strangeway (strange@igpp.ucla.edu)
;  
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2018-10-18 11:12:23 -0700 (Thu, 18 Oct 2018) $
;$LastChangedRevision: 25996 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_fields/fa_load_mag_hr_dcb.pro $
;
;-

;helper function, replace flags with NANs
pro fa_load_mag_hr_dcb_deflag,varname
  compile_opt idl2,hidden

  flag = 2.0e8

  get_data,varname,data=d
  
  idx = where(d.y eq flag,c)
  
  if c gt 0 then begin
    d.y[idx] = !VALUES.D_NAN
  endif

  store_data,varname,data=d

end

;helper function, replace flags with NANs
pro fa_load_mag_hr_dcb_metadata,varname
  compile_opt idl2,hidden
  
  get_data,varname,data=d,dlimit=dl
  
  dim = dimen(d.y)
  
  if n_elements(dim) eq 2 && dim[1] eq 3 then begin
    str_element,dl,'colors',[2,4,6],/add
  endif
  
  data_att = {units:'none',coord_sys:'',st_type:'none'}
  
  if strmatch(varname,'*_gei',/fold_case) then begin
    data_att.coord_sys='gei'
  endif
  
  ;does units field exit
  str_element,dl.cdf.vatt,'units',success=s
  if s then begin
    data_att.units=dl.cdf.vatt.units
  endif
  
  if strmatch(varname,'fa_hr_dcb_pos_gei') then begin
    data_att.st_type = 'pos'
  endif else if strmatch(varname,'fa_hr_dcb_vel_gei') then begin
    data_att.st_type = 'vel'
  endif
  
  str_element,dl,'data_att',data_att,/add
  
  store_data,varname,dlimit=dl
  
end

pro fa_load_mag_hr_dcb,trange=trange,tplotnames=tplotnames, $
                       no_download = no_download, no_update = no_update, $
                       downloadonly = downloadonly

  compile_opt idl2

  istp_init
  cdf_leap_second_init ;needed to import hr data since it uses tt2000 times
   
  version='v0?'
  source =!istp
  if(keyword_set(no_download)) then source.no_download = no_download
  if(keyword_set(no_update)) then source.no_update = no_update
  if(keyword_set(downloadonly)) then source.downloadonly = downloadonly
  downloadonly = source.downloadonly
  verbose = source.verbose
   
  tr = timerange(trange)
  
  ;http://cdaweb.gsfc.nasa.gov/istp_public/data/fast/dcb/dcb_hr/1998/09/fast_hr_dcb_19980901002656_v01.cdf
  ;https://cdaweb.gsfc.nasa.gov/istp_public/data/fast/dcf/l2/dcb/1996/10/fast_hr_dcb_19961001052936_00441_v02.cdf
  file_format = 'YYYY/MM/fast_hr_dcb_YYYYMMDDhh????_*_'+version+'.cdf'

  relpathnames = file_dailynames(file_format=file_format,trange=tr,/hour_res)
  remote_path = source.remote_data_dir+'fast/dcf/l2/dcb/'
;Local path for SSL is different
  If(file_test('/disks/data/fast/.fast_master')) Then Begin
     local_path = '/disks/data/fast/l2/DCB/'
  Endif Else local_path = source.local_data_dir+'fast/dcb/dcb_hr/'
  files = spd_download(remote_file=relpathnames, remote_path=remote_path, $
                       local_path = local_path, no_download = source.no_download, $
                       no_update = source.no_update, $
                       file_mode = '666'o, dir_mode = '777'o)
   
  if downloadonly then return
  
  cdf2tplot,file=files,verbose=verbose ,prefix = 'fa_hr_dcb_',tplotnames=tplotnames,/load_labels
  
  if keyword_set(tplotnames) then begin ;output is '' for no variables loaded
    for i = 0,n_elements(tplotnames)-1 do begin
      fa_load_mag_hr_dcb_deflag,tplotnames[i]
      fa_load_mag_hr_dcb_metadata,tplotnames[i]
    endfor
  endif
 
 end
 
 ;orphaned test code, uses SPDF web services.  Nice in some ways, but file management(redownload, local path etc...) isn't really there, so I'd I have to do this manually. 
; ;create web chooser object
; cdas = $
;   obj_new('SpdfCdas', $
;   endpoint = 'http://cdaweb.gsfc.nasa.gov/WS/cdasr/1', $
;   userAgent = 'WsExample/1.0', $
;   defaultDataview = 'sp_phys')
;   
; ;create error reporter object(not really sure how this works)
; errReporter = obj_new('SpdfHttpErrorReporter');
; 
;; server->interrogative, for testing
;; use print,result[n]->getId() to view the returned output
; 
; dataviews = cdas->getDataviews(httpErrorReporter = errReporter)
;
; instrumentTypes = cdas->getInstrumentTypes(httpErrorReporter = errReporter)
; 
; observatoryGroups = cdas->getObservatoryGroups(httpErrorReporter = errReporter)
; 
; datasets = cdas->getDatasets(observatoryGroups = ['FAST'], httpErrorReporter = errReporter)
; 
;  dataset = 'FAST_HR_DCB'
;  
;  vars = cdas->getVariables(dataset, httpErrorReporter = errReporter)
; 
;  for i = 0,n_elements(vars)-1 do valid_datatypes = array_concat(vars[i]->getName(),valid_datatypes)

;  
;  obj_destroy,vars
; 
;  if keyword_set(valid_names) then begin
;  
;    undefine,trange
;    datasets = cdas->getDatasets(observatoryGroups = ['FAST'], httpErrorReporter = errReporter)
;   
;    for i = 0,n_elements(datasets)-1 do begin
;      if datasets[i]->getId() eq dataset then begin
;        timeobj = datasets[i]->getTimeInterval()
;        trange = time_string(time_double([timeObj->getCdaWebStart(),timeObj->getCdaWebStop()]))
;        obj_destroy,timeobj
;      endif
;    endfor
;    obj_destroy,datasets
;    
;    datatype = valid_datatypes
;      
;    return
;  endif
; 
;  if ~keyword_set(trange) then begin
;    trange=timerange()
;  endif
;  
;  ts=time_struct(trange)
;  julrange = julday(ts.month,ts.date,ts.year,ts.hour,ts.min,ts.sec)
;
;  timeobj = obj_new('SpdfTimeInterval', julrange[0],julrange[1])
 
 ;stop

