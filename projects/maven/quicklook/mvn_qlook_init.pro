;+
;NAME:
; mvn_qlook_init
;PURPOSE:
; Initialization for MAVEN qlook plotting
;CALLING SEQUENCE:
; mvn_qlook_init, device = device
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
;HISTORY:
; 2013-05-13, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: muser $
; $LastChangedDate: 2015-06-03 12:18:13 -0700 (Wed, 03 Jun 2015) $
; $LastChangedRevision: 17797 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_init.pro $
;-
Pro mvn_qlook_init, no_color_setup = no_color_setup,  device = device, _extra = _extra

common mvn_qlook_init_private, init_done, sw_vsn

setenv, 'ROOT_DATA_DIR='+root_data_dir()

If(keyword_set(device)) Then Begin
   set_plot, strcompress(/remove_all, strupcase(device[0]))
   If(!d.name Eq 'Z') Then Begin
      device, set_resolution = [750, 900] ;changed to be consistent with thm_gen_overplot, 7-jun-2010, jmm
      !p.font = -1                        ; Use default fonts
      !p.charsize = 0.7                   ; Smaller font
      if n_elements(colortable) eq 0 then colortable = 43 ; default color table
      loadct2,colortable
      !p.background = !d.table_size-1     ; White background   (color table 34)
      !p.color=0                          ; Black Pen
   Endif
Endif

If(n_elements(init_done) Eq 0) Then Begin
    init_done = 1
; Set sw_vsn here:
    sw_vsn = 0
;COlor setup
    If(~keyword_set(no_color_setup)) Then Begin
        if n_elements(colortable) eq 0 then colortable = 43 ; default color table
        loadct2,colortable
;Make black on white background
        !p.background = !d.table_size-1 ; White background   (color table 34)
        !p.color=0              ; Black Pen
        if !d.name eq 'WIN' then begin
            device,decompose = 0
        endif
        if !d.name eq 'X' then begin
          ; device,pseudo_color=8  ;fixes color table problem for machines with 24-bit color
            device,decompose = 0
            if !version.os_family eq 'unix' then device,retain=2 ; Unix family does not provide backing store by default
        endif
    Endif
Endif
Return
End
