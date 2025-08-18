;+
;Procedure:
;     mms_feeps_smooth
;
;Purpose:
;     Creates tplot variables of the smoothed spectra, with smoothing
;     specified by num_smooth
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-07-26 09:16:24 -0700 (Tue, 26 Jul 2016) $
;$LastChangedRevision: 21526 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_smooth.pro $
;-

pro mms_feeps_smooth, probe=probe, datatype=datatype, suffix=suffix, data_units=data_units, $
    data_rate=data_rate, level=level, num_smooth = num_smooth
    
    ; smoothing time in seconds
    if undefined(num_smooth) then num_smooth = 1.0
    if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
    if undefined(datatype) then datatype = 'electron'
    if undefined(data_units) then data_units = 'intensity'
    if undefined(suffix) then suffix=''
    if undefined(level) then level = 'l2'

    lower_en = datatype eq 'electron' ? 71 : 78 ; keV
    
    prefix = 'mms'+probe+'_epd_feeps_'
    
    ;var_name = prefix+datatype+'_'+data_units+'_omni'+suffix
    var_name = strcompress('mms'+probe+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_'+data_units+'_omni'+suffix, /rem)
    
    tsmooth_in_time, var_name, newname=var_name+'_smth'+suffix, num_smooth, /double

    ylim, var_name+'_smth'+suffix, lower_en, 600., 1
    zlim, var_name+'_smth'+suffix, 0, 0, 1

end