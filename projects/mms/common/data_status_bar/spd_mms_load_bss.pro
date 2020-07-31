;+
; NAME: spd_mms_load_bss
;
; PURPOSE: To display horizontal color bars indicating burst data availability
;
; KEYWORDS: 
; 
;   trange:          time frame for bss
;   datatype:        type of BSS data ['fast','burst','status','fom']. default includes 'fast' and 'burst'
;   include_labels:  set this flag to have the horizontal bars labeled
;   probe:           probe # for SRoI bars (used as fast survey segments after 6Nov15; default: 1)
; 
; NOTES: 
;   "bss" stands for Burst Segment Status (a term used in the MMS-SDC2SITL-ICD document). 
;   By default, it produces the following tplot-variables.
;   
;   1. mms_bss_fast  (red bar) 
;      the time periods of fast-survey mode (more precisely, the time periods of ROIs)
;      
;   2. mms_bss_burst (blue bar) 
;      the time periods (segments) selected by SITLs for burst data
;      
;   3. mms_bss_status (green bar) 
;      Represents segment statuses. 
;
;   4. mms_bss_fom (histogram, black) 
;      The height represents the FOM values (i.e., priority level defined by SITLs)
;
;   5. To labels bss bars set the include_labels flag, /include_labels
;   
;   See examples/basic/spd_mms_load_bss_crib.pro for examples. 
;   
; CREATED BY: Mitsuo Oka   Oct 2015
; 
; Updated by egrimes, June 2016
; Updated by egrimes, July 2020 - to get the fast segment bars using the new SRoI code instead of 
;      the older fast segment routine for dates on and after 6Nov15 (this is because the older fast segment
;      bars routine returns incorrect segments for later in the mission, but the SRoI routine doesn't work 
;      for dates before 6Nov15)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-07-30 12:28:00 -0700 (Thu, 30 Jul 2020) $
;$LastChangedRevision: 28956 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/spd_mms_load_bss.pro $
;-

PRO spd_mms_load_bss, trange=trange, datatype=datatype, include_labels=include_labels, probe=probe
  compile_opt idl2

  if undefined(trange) then trange = timerange() else trange = timerange(trange)
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = ['fast','burst']
  datatype = strlowcase(datatype)
  
  nmax = n_elements(datatype)
  
  ; check if team login is required first
  if array_contains(datatype, 'status') || array_contains(datatype, 'fom') then begin
      status = mms_login_lasp(username=username)
      
      ; valid non-public user?
      if username eq '' || username eq 'public' then begin
          dprint, dlevel = 0, 'Error, need to login as an MMS team member for "status" and/or "fom" segment bars' 
      endif
  endif
  
  burst_label = keyword_set(include_labels) ? 'Burst' : ''
  fast_label = keyword_set(include_labels) ? 'Fast' : ''
  status_label = keyword_set(include_labels) ? 'Status' : ''
  fom_label = keyword_set(include_labels) ? 'FoM' : ''

  panel_size = keyword_set(include_labels) ? 0.09 : 0.01
  
  for n=0,nmax-1 do begin
    case datatype[n] of
      'fast': begin
         ; use the old fast segments code for dates before 6Nov15
         if time_double(trange[0]) le time_double('2015-11-06') then begin
           mms_load_fast_segments, trange=trange
           options,'mms_bss_fast',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
            ticklen=0,panel_size=panel_size,colors=6, labels=[fast_label], labsize=1, charsize=1.
          endif else begin
            ; use SRoI code for dates on and after 6Nov15
            mms_load_sroi_segments, trange=trange, probe=probe
            copy_data, 'mms' + probe + '_bss_sroi', 'mms_bss_fast'
            options,'mms_bss_fast',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
              ticklen=0,panel_size=panel_size,colors=6, labels=[fast_label], labsize=1, charsize=1.
          endelse
       end
      'burst': begin
         mms_load_brst_segments, trange=trange
         options,'mms_bss_burst',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
          ticklen=0,panel_size=panel_size,colors=2, labels=[burst_label], labsize=1, charsize=1.
       end
      'status': begin
         mms_load_bss_status, trange=trange, include_labels=include_labels
         options,'mms_bss_status',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
          ticklen=0,panel_size=panel_size,labels=[status_label], labsize=1, charsize=1.
       end
      'fom': begin
         mms_load_bss_fom, trange=trange
       end
      else: message,'datatype: '+datatype[n]+' is not allowed.'
    endcase
  endfor

END
