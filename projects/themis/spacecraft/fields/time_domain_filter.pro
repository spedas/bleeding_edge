;+
;function time_domain_filter
;
;purpose: filter data in a tplot structure, assuming constant dt between points,
;         returns filtered data in a new tplot structure.
;
;usage
; new_data = time_domain_filter(data, freq_low, freq_high)
;
;Parameters
; data : a structure with elements x and y for time and data, respectively, with
;        time in seconds.
; freq_low: low cutoff freqency in Hz
; freq_high: high cutoff frequency in Hz
;
;HISTORY
; Chris Chaston 9-May-2007 ?
;
;$LastChangedBy: kenb-mac $
;$LastChangedDate: 2007-10-02 09:24:50 -0700 (Tue, 02 Oct 2007) $
;$LastChangedRevision: 1645 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/time_domain_filter.pro $
;-

function time_domain_filter,data,freq_low,freq_high

;get sample period
dt=data.x(1)-data.x(0)
;print,'sample_period',dt
nyquist=1.0/(2.*dt)
;print,'nyquist',nyquist
flow=freq_low/nyquist
fhigh=freq_high/nyquist
A=120.;from Ergun's fa_fields_filter
if flow EQ 0.0 then f=fhigh else f=flow
nterms=long(5.0/f) > 1
;nterms=n_elements(data.x)/10.0;
if nterms GT 5000. then nterms=5000.
out=digital_filter(flow,fhigh,A,nterms)

new_series=convol(data.y,out)
new_series={x:data.x,y:new_series}
return,new_series

end
