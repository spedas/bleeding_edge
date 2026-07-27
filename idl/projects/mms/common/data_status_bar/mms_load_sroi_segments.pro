;+
; PROCEDURE:
;         mms_load_sroi_segments
;
; PURPOSE:
;         Loads the SRoI segment intervals into a bar that can be plotted
;
; KEYWORDS:
;         trange:       time range of interest
;         probe:        spacecraft probe # to load the SRoIs for (default: 1)
;         suffix:       suffix to append to the SRoI segments bar tplot variable
;         start_times:  returns an array of unix times (double) containing the start for each SRoI interval
;         end_times:    returns an array of unix times (double) containing the end of each SRoI interval
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-07-22 17:28:56 -0700 (Wed, 22 Jul 2026) $
;$LastChangedRevision: 34663 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_sroi_segments.pro $
;-

pro mms_load_sroi_segments, trange=trange, probe=probe, suffix=suffix, start_times=start_times, end_times=end_times,make_tplot_var=make_tplot_var, no_download=no_download

  if undefined(suffix) then suffix = ''
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(make_tplot_var) then make_tplot_var=1
  if undefined(no_download) then no_download=0
  
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()

  mms_init
  padding = 2*86400
  tr_padded = [tr[0]-padding, tr[1]+padding]
  
  if no_download eq 0 then begin
    result=get_mms_srois(start_time=time_string(tr_padded[0]-2*86400.0, tformat='YYYY-MM-DD'), $
      end_time=time_string(tr_padded[1], tformat='YYYY-MM-DD'), $
      sc_id='mms'+probe, /public)
  endif

  monthly_intervals=spd_month_intervals(tr_padded[0],tr_padded[1])
  month_count = n_elements(monthly_intervals)/2
  sroi_starts = []
  sroi_ends = []
  for i=0,month_count-1 do begin
    month_start=monthly_intervals[0,i]

    month_filename=spd_addslash(!mms.local_data_dir) + 'mms'+probe + time_string(month_start,tformat='/srois/monthly_YYYY_MM.csv')
    print,"Loading "+month_filename
    sroi_seg_template = {  VERSION: 1.0000000,$
        DATASTART: 1,$
        DELIMITER: 44b,$
        MISSINGVALUE: '',$
        COMMENTSYMBOL: "",$
        FIELDCOUNT: 4,$
        FIELDTYPES: [7, 7, 7, 3],$
        FIELDNAMES: [ "UTCSTART", "UTCEND", "PROBE", "ORBIT"],$
        FIELDLOCATIONS: [0, 24, 48, 53],$
        FIELDGROUPS: [0, 1, 2, 3]$
        }
    results = read_ascii(month_filename,template=sroi_seg_template,count=num_items)
    if ~is_struct(results) then begin
      dprint, dlevel=0, 'No SROI intervals found'
      continue
    endif
    
    append_array,sroi_starts,time_double(results.UTCSTART)
    append_array,sroi_ends,time_double(results.UTCEND)

  endfor
  
  idx_in_range = where(sroi_starts le tr[1] and sroi_ends ge tr[0],count)
  if count gt 0 then begin
    start_times = sroi_starts[idx_in_range]
    end_times = sroi_ends[idx_in_range]
    
    for result_idx=0, n_elements(start_times)-1 do begin
        append_array, bar_x, [start_times[i], start_times[i], end_times[i], end_times[i]]
        append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
    endfor

  endif
    
  if undefined(bar_x) then return

  if make_tplot_var then begin
    store_data,'mms'+probe+'_bss_sroi'+suffix,data={x:bar_x, y:bar_y}
    options,'mms'+probe+'_bss_sroi'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
      ticklen=0,panel_size=0.09,colors=4, labels=['SRoI'], charsize=2.
  endif
end