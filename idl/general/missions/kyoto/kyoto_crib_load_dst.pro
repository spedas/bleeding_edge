
;+
;
;Crib sheet for KYOTO_LOAD_DST.PRO.  Modified from KYOTO_CRIB_LOAD_AE.PRO.
;Copy and paste lines to command line, or type .run kyoto_crib_load_dst
;
;Modifications:
;
;WMFeuerstein, 8/21/2008.
;
;-

print,'Enter ".c" to set the timespan to a date known to contain Kyoto DST data'
print,'(2007-03-23) (if this step is skipped, the user will be queried for the date).
print, 'Kyoto DST data is classed as realtime, provisional, or final. All three categories will be queried.'
stop
timespan,'7-3-23',2

print,'Enter ".c" to call KYOTO_LOAD_DST 
stop
kyoto_load_dst

print,'Enter ".c" to plot DST data.'
stop
tplot,'kyoto_dst'
print, 'The y axis label indicates whether data loaded is realtime, provisional, or final (or some combination thereof).'

stop
print, 'Data can also be returned in array form from kyoto_load_dst when a file is loaded, using the keywords dstdata and dsttime'
print,'Enter ".c" to call KYOTO_LOAD_DST with keywords dstdata and dsttime'
stop
kyoto_load_dst, dstdata=dstdata, dsttime=dsttime
plot, dsttime, dstdata
print, 'Note that DST data files contain a full month of data, so the arrays may return a longer time period than the tplot variable.'

end

