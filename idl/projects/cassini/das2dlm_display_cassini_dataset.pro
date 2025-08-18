;+
; PRO: das2dlm_display_cassini_dataset, ...
;
; Description:
;    Display informtaion about selected cassini dataset
;
; Keywords:
;    trange: Sets the time tange. Default is ['2013-01-01','2013-01-02']
;    dataset: Cassini dataset, e.g 'RPWS/Derived'. List of datasets is available here: http://planet.physics.uiowa.edu/das/das2Server?server=list
;    nset: Dataset number. Default is 0.
;    postfix: Additional string to the query, e.g. 'interval=60' 
;    
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-07-27 13:04:34 -0700 (Mon, 27 Jul 2020) $
; $Revision: 28941 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cassini/das2dlm_display_cassini_dataset.pro $
;-

pro das2dlm_display_cassini_dataset, trange=trange, dataset=dataset, nset=nset, postfix=postfix 
  
  das2dlm_cassini_init
      
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = ['2013-01-01','2013-01-02']
       
  if undefined(nset) then nset = 0
  
  if ~undefined(postfix) $
    then postfix = '&' + postfix $
    else postfix = ''
  
  time_format = 'YYYY-MM-DDThh:mm:ss'
  
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  datasetstr = 'dataset=Cassini/' + dataset
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)

  requestUrl = url + '&' + datasetstr + '&' + time1 + '&' + time2 + postfix
  print, requestUrl

  query = das2c_readhttp(requestUrl)
  
  print, 'Query:'
  print, query, /IMPLIED_PRINT
  
  ; Get dataset  
  ds = das2c_datasets(query, nset)
  
  print, 'Dataset: '
  print, ds, /IMPLIED_PRINT
  
  ; Physical dimentions
  pdims = das2c_pdims(ds)
  print, 'Pdims: '  
  print, pdims, /IMPLIED_PRINT
  
  ; Cleaning up
  res = das2c_free(query)
   
end