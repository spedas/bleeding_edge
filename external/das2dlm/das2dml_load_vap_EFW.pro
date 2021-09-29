;+
; PRO: das2dlm_load_vap_efw,...
;
; Description:
;   Read EFW ElectronPlasmaFrequency
;
;
; Parameters:
;   probe: 'a' or 'b' spacesraft
;   trange: If a time range is set, timespan is executed with it at the end of this program
;   
; CREATED BY:
;   Alexander Drozdov (adrozdov@ucla.edu)
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dml_load_vap_EFW.pro $
;-

pro das2dlm_load_vap_efw, probe=probe, trange=trange
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
   then tr = timerange(trange) $
   else tr = timerange()
     
  if undefined(probe) then probes = 'A' ; default RBSP A
    
  time_format = 'YYYY-MM-DDThh:mm:ss'   
  ; url example 
  ; http://planet.physics.uiowa.edu/das/das2Server?server=dataset&dataset=/uiowa/Van_Allen_Probes/A/EFW/ElectronPlasmaFrequency&start_time=2013-001&end_time=2013-002
  url = 'http://planet.physics.uiowa.edu/das/das2Server?server=dataset'
  dataset = 'dataset=Van_Allen_Probes/' + strupcase(probe) + '/EFW/ElectronPlasmaFrequency'
  time1 = 'start_time=' + time_string( tr[0] , tformat=time_format)
  time2 = 'end_time=' + time_string( tr[1] , tformat=time_format)
  
  requestUrl = url + '&' + dataset + '&' + time1 + '&' + time2
  
  query = das2c_readhttp(requestUrl)
end