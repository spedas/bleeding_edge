;+
; PROCEDURE:
;         mms_load_brst_segments_sdc
;
; PURPOSE:
;         Loads the burst segment intervals into a bar that can be plotted
;
; NOTE:
;         This is the old version of this file, use: 
;         
;         mms_load_brst_segments
;            
;         instead.
; 
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-07-01 07:52:56 -0700 (Fri, 01 Jul 2016) $
;$LastChangedRevision: 21414 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_brst_segments_sdc.pro $
;-

pro mms_load_brst_segments_sdc, trange=trange, suffix=suffix
  if undefined(suffix) then suffix = ''
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  
  mms_init

  brst_file = spd_download(remote_file='https://lasp.colorado.edu/mms/sdc/public/service/latis/mms_burst_data_segment.csv', $
    local_file=!mms.local_data_dir+'mms_burst_data_segment.csv', $
    SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

  brst_seg_temp = { VERSION: 1.0000000, $
                    DATASTART: 1, $
                    DELIMITER: 44b, $
                    MISSINGVALUE: "", $
                    COMMENTSYMBOL: "", $
                    FIELDCOUNT: 13, $
                    FIELDTYPES: [0, 3, 3, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0], $
                    FIELDNAMES: [ "FIELD01", "TAISTARTTIME", $
                    "TAIENDTIME", "FIELD04", "FIELD05", "FIELD06", $
                    "FIELD07", "STATUS", "FIELD09", "FIELD10", $
                    "FIELD11", "FIELD12", "FIELD13"], $
                    FIELDLOCATIONS: [0, 4, 16, 28, 44, 50, 53, 56, 75, 78, 93, 114, 135], $
                    FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]  $
                   }
  brst_data = read_ascii(brst_file, template=brst_seg_temp, count=num_items)
  
  complete_idxs = where(brst_data.status eq 'COMPLETE+FINISHED', c_count)
  if c_count ne 0 then begin
    tai_start = brst_data.TAISTARTTIME[complete_idxs]
    tai_end = brst_data.TAIENDTIME[complete_idxs]
    
    unix_start = mms_tai2unix(tai_start)
    unix_end = mms_tai2unix(tai_end)
    
    times_in_range = where(unix_start ge tr[0]-180. and unix_end le tr[1]+180., t_count)

    if t_count ne 0 then begin
      unix_start = unix_start[times_in_range]
      unix_end = unix_end[times_in_range]
      
      for idx = 0, n_elements(unix_start)-1 do begin
        append_array, bar_x, [unix_start[idx], unix_start[idx], unix_end[idx], unix_end[idx]]
        append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
      endfor
      
      store_data,'mms_bss_burst'+suffix,data={x:bar_x, y:bar_y}
      options,'mms_bss_burst'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
        ticklen=0,panel_size=0.09,colors=4, labels=['Burst'], charsize=2.
    endif else begin
      dprint, dlevel = 0, 'Error, no brst segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
    endelse
  endif else begin
    dprint, dlevel = 0, 'Error, couldn''t find any COMPLETE+FINISHED segments in mms_burst_data_segment.csv'
  endelse
end