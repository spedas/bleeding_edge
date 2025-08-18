;+
; PROCEDURE:
;         cl_load_peace
;         
; PURPOSE:
;         Load data from the Plasma Electron and Current Experiment (PEACE)
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for Cluster probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
; OUTPUT:
; 
; 
; EXAMPLE:
; 
; 
; NOTES:
; 
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;-

pro cl_load_peace, probes = probes, datatype = datatype, trange = trange, source = source, $
                 remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                 no_download = no_download, no_server = no_server, tplotnames = tplotnames, $
                 get_support_data = get_support_data, varformat = varformat, $
                 cdf_filenames = cdf_filenames, cdf_records = cdf_records, min_version = min_version, $
                 cdf_version = cdf_version, latest_version = latest_version, $
                 time_clip = time_clip, suffix = suffix, versions = versions
                  
    if undefined(probes) then probes = ['1'] ; default to Cluster 1
    if undefined(datatype) then datatype = 'pp'

    cl_load_data,probes = probes, datatype = datatype, trange = trange, source = source, $
                 remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
                 no_download = no_download, no_server = no_server, tplotnames = tplotnames, $
                 get_support_data = get_support_data, varformat = varformat, $
                 cdf_filenames = cdf_filenames, cdf_records = cdf_records, min_version = min_version, $
                 cdf_version = cdf_version, latest_version = latest_version, $
                 time_clip = time_clip, suffix = suffix, versions = versions, instrument='pea'

end