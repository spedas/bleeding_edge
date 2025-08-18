
;+
;
;Crib sheet for KYOTO_LOAD_AE.PRO.
;
;Modifications:
;  Changed name from KYOTO_CRIB_AE2TPLOT to KYOTO_CRIB_LOAD_AE, WMF, 6/4/2008.
;
;WMFeuerstein, 5/20/2008.
;
;-

print,'Enter ".c" to set the timespan to a date known to contain Kyoto AE data'
print,'(2007-03-23) (if this step is skipped, the user will be queried for the date).
print, 'Note that AE data is classed as realtime or provisional. Only provisional data is available,'
print, 'so you may be unable to load data from recent months.' 
stop
timespan,'7-3-23',2

print,'Enter ".c" to call KYOTO_LOAD_AE with no parameters (defaults to AE data).
stop
kyoto_load_ae

print,'Enter ".c" to plot AE data.'
stop
tplot,'kyoto_ae'

print,'Enter ".c" to call KYOTO_LOAD_AE with DATATYPE = '+"'ao' and plot all results."
stop
kyoto_load_ae,datatype='ao'
tplot,['kyoto_ae','kyoto_ao']

print,'Enter ".c" to call KYOTO_LOAD_AE with DATATYPE = '+"'all' and plot all results."
stop
kyoto_load_ae,datatype='all'
tplot,['kyoto_ae','kyoto_ao','kyoto_al','kyoto_au','kyoto_ax']


end

