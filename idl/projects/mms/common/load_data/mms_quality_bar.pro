;+
; Function:
;       mms_quality_bar
;       
; Input:
;       data_in: tplot variable containing bit flags for quality of data
;       
; Output:
;       Creates a tplot variable with the name data_in + _bar, containing
;       quality bars. Returns the name of the tplot variable it created.
;       
;       
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-12-10 14:33:38 -0800 (Thu, 10 Dec 2015) $
; $LastChangedRevision: 19596 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_quality_bar.pro $
;-


function mms_quality_bar, data_in

    get_data,data_in,data=d,dlimits=dl
    
    str_element,dl,'ysubtitle',/delete
    store_data, data_in+'_bar', data=d, dlimits=dl

    options,data_in+'_bar',colors='r'
    options,data_in+'_bar',tplot_routine='bitplot'
    options,data_in+'_bar',numbits=32
    options,data_in+'_bar',ytitle='Quality'
    options,data_in+'_bar',panel_size=.2
    options,data_in+'_bar',psym=6
    options,data_in+'_bar',symsize=.0125
    ;kill the ticks
    options,data_in+'_bar',ticklen=0
    options,data_in+'_bar',yticks=1
    options,data_in+'_bar',ystyle=1
    return, data_in+'_bar'
end