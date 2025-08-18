;+
;NAME:
; mvn_spd_init
;PURPOSE:
; Initialization for MAVEN 
;CALLING SEQUENCE:
; mvn_spd_init, device = device
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; def_file_source = A default structure for the file_source; tags:
;   LOCAL_DATA_DIR  STRING    '/disks/data/'
;   REMOTE_DATA_DIR STRING    ''
;   NO_SERVER       INT              1
;   VERBOSE         INT              2
;   LAST_VERSION    INT              1
;HISTORY:
; 2013-05-13, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-01-11 11:54:21 -0800 (Mon, 11 Jan 2016) $
; $LastChangedRevision: 19709 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_spd_init.pro $
;-
Pro mvn_spd_init, reset = reset, def_file_source = def_file_source, $
                  no_color_setup = no_color_setup, _extra = _extra

  common mvn_spd_init_private, init_done
  common mvn_file_source_com, psource

  setenv, 'ROOT_DATA_DIR='+root_data_dir()

  If((n_elements(init_done) Eq 0) or keyword_set(reset)) Then Begin
     undefine, psource ;need this to handle mvn_file_source (which I will not touch)
     init_done = 1
;Color setup
     If(~keyword_set(no_color_setup)) Then Begin
        If(n_elements(colortable) Eq 0) Then colortable = 43 ; default color table
        loadct2, colortable
;Make black on white background
        !p.background = !d.table_size-1 ; White background   (color table 34)
        !p.color = 0                      ; Black Pen
        If(!d.name Eq 'WIN') Then Begin
           device, decompose = 0
        Endif
        If(!d.name eq 'X') Then Begin
           device, decompose = 0
;Unix family does not provide backing store by default
           If(!version.os_family Eq 'unix') Then device, retain = 2 
        Endif
     Endif

;Call mvn_file_source for the file setup, carefully
     If(is_struct(def_file_source)) Then Begin
        yyy = mvn_file_source(def_file_source)
     Endif Else Begin
;Use local config, unless reset is set. It looks like for
;other instruments, reset ignores the local config file
        yyy = mvn_spd_read_config()
        If(~is_struct(yyy) || keyword_set(reset)) Then Begin
           yyy = mvn_file_source(_extra=_extra)
;Point to SDC
           yyy.remote_data_dir = 'https://lasp.colorado.edu/maven/sdc/public/data/'
        Endif
     Endelse
;Don;t define psource if none of this worked.
     If(is_struct(yyy)) Then psource = yyy
  Endif

  Return
End
