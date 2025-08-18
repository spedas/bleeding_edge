;+
;NAME:
; mvn_qlook_static_d1_bar
;PURPOSE:
; creates static_d1 data bar for overview plots, checks for STATIC D1 data
; in L0 files
;CALLING SEQUENCE:
; p = mvn_qlook_static_d1_bar(date,duration)
;INPUT:
; date =  the date for the start of the timespan, 
; duration = the duration of your bar in days
;KEYWORDS:
; outline: set this to 1 to generate a sample rate panel with
;          a black outline rather than no outline
;OUTPUT:
; p = the variable name of the qlook_static_d1_bar, set to '' if not
;     sccessful
;HISTORY:
; 2025-05-14, jmm, jimm@ssl.berkeley.edu, hacked from mvn_qlook_burst_bar.pro
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Function mvn_qlook_static_d1_bar, date, duration, outline=outline, from_l2 = from_l2, _extra = _extra

  p = ''
  timespan, date, duration

; make tplot variable tracking the presence of archive data
;------------------------------------------------------------------
;Look for STATIC D1 data
;Call mvn_sta_load_l0 first
  common mvn_d1,mvn_d1_ind,mvn_d1_dat 
  If(is_struct(mvn_d1_dat)) Then Begin
     store_data, 'mvn_d1_arcflag', data = {x:mvn_d1_dat.time, y:0.5+fltarr(n_elements(mvn_d1_dat.time))}
     tdegap, 'mvn_d1_arcflag', /overwrite, dt = 600.0
  Endif Else Begin
     mvn_sta_l0_load
     If(is_struct(mvn_d1_dat)) Then Begin
        store_data, 'mvn_d1_arcflag', data = {x:mvn_d1_dat.time, y:0.5+fltarr(n_elements(mvn_d1_dat.time))}
        tdegap, 'mvn_d1_arcflag', /overwrite, dt = 600.0
     Endif Else Begin
        message, /info, 'No STATIC D1 data available'
        Return, p
     Endelse
  Endelse

  options, 'mvn_d1_arcflag', 'thick', 5
  options, 'mvn_d1_arcflag', 'psym', 1
  If(keyword_set(outline)) Then Begin
     options,'mvn_d1_arcflag',color=0,ticklen=0,yticks=1,ytickname=[' ',' ']
  Endif

  ylim, 'mvn_d1_arcflag', 0.0, 1.0, 0
  options, 'mvn_d1_arcflag', 'panel_size', 0.1
  options,'mvn_d1_arcflag', ytitle='D1'

;end mode bar code block
;--------------->
  p = 'mvn_d1_arcflag'
  Return, p
End

