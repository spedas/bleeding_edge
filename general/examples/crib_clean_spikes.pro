
;+
;PROCEDURE:
;  crib_clean_spikes.pro
;
;PURPOSE: 
;  demonstrates some aspects of the clean_spikes procedure
;
;USAGE:
; .run crib_clean_spikes
;
;
;WARNING: this crib uses some data from the THEMIS branch.  You'll require those routines to run this crib
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-03-16 12:05:08 -0700 (Mon, 16 Mar 2020) $
; $LastChangedRevision: 28416 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_clean_spikes.pro $
;
;-


print, 'Test with GMAG'

;Load GMAG data from ccnv site:
timespan, '2017-03-23', 1
thm_load_gmag, site = 'ccnv'
var = tnames('thg_mag_ccnv')
var = var[0]
;plot for verification
tplot, var
print, 'Original data, has spikes, we add larger spikes early in the day.'
stop

;Create a dataset with spikes:
get_data, var, data = d
d.y[1400, 0] = 1.0e5            ;should work
d.y[1600, 1] = -1.0e5
store_data, var+'-test', data = d
tplot, var+'-test'              ;will show spikes
print, 'Note the Spikes, two large ones added arbitrarily, multiple smaller ones, in the data'
stop
;run the following command:
clean_spikes, var+'-test', new_name = var+'_despiked'
tplot, [var+'-test', var+'_despiked'] ;oops still spikes
print, 'Test default clean_spikes:'
print, 'The top panel is the original, the bottom -- despiked'
print, 'On verification, spikes persist, making the default clean_spikes not very useful'
print, 'Try subtract_average keyword, which uses the tsub_average procedure to subtract'
print, 'the average value from each component. Despiking is performed, and the averages'
print, 'are restored. *Note that this is not recommended for data that is defined to be'
print, 'greater than zero, such as a density or particle count rate'
stop
clean_spikes, var+'-test', new_name = var+'_despiked1', /subtract_average
tplot, [var+'-test', var+'_despiked1'] ;oops, still some spikes
print, 'Test clean_spikes: /subtract_average'
print, 'The large spikes are gone, but the smaller ones persist. THe clean spikes procedure'
print, 'has other keywords, a threshold value, and a smoothing parameter.'
print, 'The default of the thresh keyword is 10, and the default of the keyword nsmooth'
print, 'is 3. If the data value at any point is greater than thresh*nsmooth/(nsmooth-1+thresh)'
print, 'times the smoothed data point, then the data is flagged as a spike.'
print, 'Reduce the threshold to 2.0, so that a spike has to be only 1.5 times the value of it''s'
print, 'smoothed value.'
stop
clean_spikes, var+'-test', new_name = var+'_despiked2', thresh = 2.0, /subtract_average
tplot, [var+'-test', var+'_despiked2'] ;oops, not quite, but close
print, 'Test clean_spikes: /subtract_average, thresh = 2.0'
print, 'Still not such a great idea, the problem here is that the spikes are longer than one'
print, 'data point. Try increased smoothing'
stop
clean_spikes, var+'-test', new_name = var+'_despiked3', thresh = 2.0, /subtract_average, ns = 11
tplot, [var+'-test', var+'_despiked3'] ;oops, not quite, but close
print, 'Test clean_spikes: /subtract_average, thresh = 2.0, nsmooth  = 11'
print, 'Better, but not ideal. An issue with the default procedure is that it compares'
print, 'possible spikes with smoothed versions of themselves. We might rather compare the'
print, 'spikes with the surrounding values. Use the use_nn_median keyword to force the'
print, 'program to compare possible spikes with the median value of the plus/minus nsmooth'
print, 'values of the data. Note that this takes longer, so try other options first.'
stop
clean_spikes, var+'-test', new_name = var+'_despiked4', thresh = 2.0, /use_nn_median
tplot, [var+'-test', var+'_despiked4'] ;oops, not quite, but close
print, 'Test clean_spikes: /use_nn_median, thresh = 2.0'
print, 'Better, but not still not ideal. Try increasing the number of smoothing'
print, 'from the default value of 3 to 11.'
stop
clean_spikes, var+'-test', new_name = var+'_despiked5', thresh = 2.0, /use_nn_median, nsmooth = 11
tplot, [var+'-test', var+'_despiked5']
print, 'Test clean_spikes: /use_nn_median, thresh = 2.0, nsmooth = 11'
print, 'Still not so great, try the same with the /subtract_average keyword set'
stop
clean_spikes, var+'-test', new_name = var+'_despiked6', thresh = 2.0, /use_nn_median, nsmooth = 11, /subtract_average
tplot, [var+'-test', var+'_despiked6']
print, 'Test clean_spikes: /use_nn_median, thresh = 2.0, nsmooth = 11, /subtract_average'
print, 'SUCCESS. Note that you may be required to mix/match non-default options, Finally, '
print, 'plot the average-subtracted version of the field, to see the small variations.'
stop
tsub_average, 'thg_mag_ccnv_despiked6'
options, 'thg_mag_ccnv_despiked6-d', 'yrange', [-50.0, 50.0]
tplot, [var+'-test', 'thg_mag_ccnv_despiked6-d']
print, 'Here is despiked, average-subtracted data.'
End
