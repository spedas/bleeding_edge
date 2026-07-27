;
;+
;
;Procedure get_fgm_range_transition_times
;
;Purpose:
;  Analyze a set of packet headers from spin fit (apid 410), FGE (apid 405), FGL (apid 460), or FGH (apid 461) L1 support data (the *_hed outputs)
;  Detect where the FGM range settings change, and return the packet header times which bracket the change.
;
;Syntax:
;  get_fgm_range_transitions_times, tvar, start_times=start_times, end_times=end_times
;
;  where
;
;  tvar: A tplot variable containing packet headers, obtained by loading L1 data with /get_support_data.  It will have a suffix '_hed'.
;  start_times: Returned array of start times bracketing the range transitions
;  end_times: Returned array of end times bracketing the range transitions
; 
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-07-24 11:51:21 -0700 (Fri, 24 Jul 2026) $
; $LastChangedRevision: 34673 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/get_fgm_range_transition_times.pro $
;-


pro get_fgm_range_transition_times,tvar,start_times=start_times,end_times=end_times

    get_data,tvar,data=d
    dy_uint = uint(d.y)
    first_hdr = dy_uint[0,*]
    us16 = ishft(first_hdr[0],8) + first_hdr[1]
    apid = us16 and 0x7ff
    if apid eq 0x405 then begin
      ; Range info for apid 0x405 FGE packets is in header bytes 12 and 13
      b12 = dy_uint[*,12]
      b13 = dy_uint[*,13]
      r0 = ishft(b12,-4) and 0x0f
      r1 = b12 and 0x0f
      r2 = ishft(b13,-4) and 0x0f
    endif else begin
      ; Range info for FGL, FGH, and FIT packets is in header bytes 14 and 15
      b14 = dy_uint[*,14]
      b15 = dy_uint[*,15]
      r0 = ishft(b14,-4) and 0x0f
      r1 = b14 and 0x0f
      r2 = ishft(b15,-4) and 0x0f
    endelse
    ; The X, Y, and Z ranges are represented separately.  We want to detect a change in any of them, so combine them into one quantity
    r_all = ishft(r0,8) + ishft(r1,4) + r2
    
    n = n_elements(r_all)
    r_diff = r_all[1:n-1] - r_all[0:n-2]
    idx_changed = where(r_diff ne 0, diff_count)
    start_times = []
    end_times = []
    if diff_count gt 0 then begin
      start_times = d.x[idx_changed]
      end_times = d.x[idx_changed+1]
    endif
 end
    