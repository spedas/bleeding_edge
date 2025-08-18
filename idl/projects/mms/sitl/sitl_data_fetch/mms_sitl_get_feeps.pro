;+
; PROCEDURE:
;         mms_load_feeps
;         
; PURPOSE:
;         Load data from the Fly's Eye Energetic Particle Sensor (FEEPS) onboard MMS
; 
; KEYWORDS: 
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is '1';
;
;$LastChangedBy: rickwilder $
;$LastChangedDate: 2018-04-03 13:31:40 -0700 (Tue, 03 Apr 2018) $
;$LastChangedRevision: 24989 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/sitl_data_fetch/mms_sitl_get_feeps.pro $
;-
pro mms_sitl_get_feeps, trange = trange, probes = probes

    if undefined(probes) then probes_in = ['1'] else probes_in = probes
        
    ; Start with electrons    
    mms_load_data, trange = trange, probes = probes_in, level = 'sitl', instrument = 'feeps', $
        data_rate = 'srvy', datatype = 'electron'
        
    ; Load ions
    mms_load_data, trange = trange, probes = probes_in, level = 'sitl', instrument = 'feeps', $
        data_rate = 'srvy', datatype = 'ion'
   
   
end