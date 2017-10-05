;+
; FUNCTION:
;       mms_fpi_quality_bar
;       
; INPUT:
;       probe: probe #
;       data_rate: brst, fast
;       
; OUTPUT:
;       Returns the name of a combined tplot variable with the DIS/DES quality bars
;
;       
;       
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-25 17:59:46 -0800 (Thu, 25 Feb 2016) $
; $LastChangedRevision: 20195 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_quality_bar.pro $
;-

function mms_fpi_quality_bar, probe, data_rate
    probe_in = strcompress(string(probe), /rem)
    
    flag_vars = tnames('mms'+probe_in+'_d?s_errorflags_'+data_rate)
    options, flag_vars, ticklen=0
    options, flag_vars, yticks=1
    options, flag_vars, ystyle=1
    options, flag_vars, colors=[6]
    options, flag_vars, ytitle='Quality'
    options, flag_vars, ysubtitle=''
    quality_bar = 'mms'+probe_in+'_errorflags_'+data_rate
    store_data, quality_bar, data=flag_vars
    
    ylim, quality_bar, 0, 2, 0
    options, quality_bar, panel_size=.2
    return, quality_bar
end