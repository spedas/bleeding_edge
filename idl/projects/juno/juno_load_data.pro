;+
; PROCEDURE:
;         juno_load_data
;
; PURPOSE:
;         Load data from the Juno mission
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         datatype:     data types include currently include:
;                     
;                       http://jupiter.physics.uiowa.edu/das/server?server=list
;                       
;
; OUTPUT:
;
; EXAMPLE:
; 
;         Juno> juno_load_data, trange=['2016-08-29', '2016-08-30']
;         Juno> tplot, 'juno_proton_spectra'
;
; NOTES:
;     contact Eric Grimes with bug reports/questions/etc -> egrimes@igpp.ucla.edu
; 
;  **** still being developed, December 2016 ****
; 
; TODO:
;   1. remove hardcoded 2016 in process_packets call (regex should include potential years to avoid grabbing times that match :01:
;   2. allow for exceptions returned by the server:
;       [00]000082<exception type="NoDataInInterval" message='no data found in 2016-214/2016-223'/>
;   3. concatenate all packets in a stream
;   4. add ability to query dataset info
;   5. allow for other XML formats for other datatypes
;   6. add login support for datatypes that require login
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-12-05 12:03:15 -0800 (Mon, 05 Dec 2016) $
;$LastChangedRevision: 22436 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/juno/juno_load_data.pro $
;-

pro juno_load_data, trange = trange, datatype = datatype
    juno_init
    if undefined(datatype) then datatype = 'Juno/JED/ProtonSpectra'
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()
    
    start_time = time_string(tr[0], tformat='YYYY-DOY')
    end_time = time_string(tr[1], tformat='YYYY-DOY')
    start_time_fn = time_string(tr[0], tformat='YYYYMMDDhhmmss')
    end_time_fn = time_string(tr[1], tformat='YYYYMMDDhhmmss')

    remote_file = 'server?server=dataset&dataset='+datatype+'&start_time='+start_time+'&end_time='+end_time+'&ascii=1'
    file_name = strjoin(strsplit(strlowcase(datatype), '/', /extract), '_')+'_'+start_time_fn+'-'+end_time_fn+'.d2s'
    local_data_dir = !juno.local_data_dir
    remote_data_dir = !juno.remote_data_dir
    
    data = spd_download(remote_file=remote_file, $
                        remote_path = remote_data_dir, $
                        local_path = local_data_dir, local_file=file_name, /no_wildcards)

    das2tplot, local_data_dir+file_name
end