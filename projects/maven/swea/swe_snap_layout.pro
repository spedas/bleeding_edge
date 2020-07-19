;+
;PROCEDURE:   swe_snap_layout
;PURPOSE:
;  Puts snapshot windows in convenient, non-overlapping locations, 
;  depending on display hardware.  These layouts are only recognized
;  by the SWEA snapshot routines.  This routine has no effect unless
;  a non-zero layout is specified, and you can only do that by calling
;  this routine.  It is perfectly safe to simply ignore the existence 
;  of this routine.  It is admittedly only useful to the author.
;
;  See putwin.pro for details on how the configuration structures are
;  used to create and place windows.
;
;USAGE:
;  swe_snap_layout, layout
;
;INPUTS:
;       layout:        Integer specifying the layout:
;
;                        0 --> Default.  No fixed window positions.
;                        1 --> Macbook 1440x900 (below) with Dell 5120x1440 (above)
;                        2 --> Macbook 1440x900 (below) with twin Dell 2560x1440 (left, right)
;                        3 --> Macbook 1440x900 (below) with Dell 2560x1440 (above)
;
;KEYWORDS:
;
;       HOME:          Equivalent to LAYOUT=3.
;
;       WORK:          Equivalent to LAYOUT=2.
;
;       WORK2:         Equivalent to LAYOUT=1.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-07-18 15:17:05 -0700 (Sat, 18 Jul 2020) $
; $LastChangedRevision: 28910 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_snap_layout.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_snap_layout, layout, home=home, work=work, work2=work2

  @swe_snap_common
  
  if keyword_set(home) then layout = 3
  if keyword_set(work) then layout = 2
  if keyword_set(work2) then layout = 1
  
  if (size(layout,/type) eq 0) then begin
    print,"Hardware-dependent positions for snapshot windows."
    print,"  0 --> Default.  No fixed window positions."
    print,"  1 --> 1440x900 (below) with 5120x1440 (above)"
    print,"  2 --> 1440x900 (below) with 2560x1440 (left), 2560x1440 (right)"
    print,"  3 --> 1440x900 (below) with 2560x1440 (above)"
    print,""
    layout = ''
    read, layout, prompt='Layout > '
  endif

  case layout[0] of

    '1'  : begin  ; Macbook 1440x900 (below) with Dell 5120x1440 (above)
             snap_index = 7

             Dopt = {xsize:800, ysize:600, dx:10, dy:10, monitor:0, corner:0}   ; 3D
             Sopt = {xsize:450, ysize:600, dx:820, dy:10, monitor:0, corner:0}  ; 3D SPEC

             Popt = {xsize:800, ysize:600, dx:10, dy:10, monitor:0, corner:0}   ; PAD
             Nopt = {xsize:600, ysize:450, dx:10, dy:10, monitor:0, corner:2}   ; PAD Energy Cut
             Copt = {xsize:500, ysize:700, dx:10, dy:10, monitor:0, corner:2}   ; PAD 3D View
             Fopt = {xsize:400, ysize:600, dx:820, dy:10, monitor:0, corner:0}  ; PAD SPEC

             Eopt = {xsize:400, ysize:600, dx:10, dy:10, monitor:0, corner:0}   ; SPEC
             Hopt = {xsize:200, ysize:600, dx:420, dy:10, monitor:0, corner:0}  ; HSK

             Oopt  = {xsize:318,  ysize:856, dx:10, dy:0, monitor:0, corner:0}  ; Orbit 1x3
             Oopt1 = {xsize:500,  ysize:473, dx:10, dy:10, monitor:0, corner:0} ; Orbit 1x1
             OCopt = {xsize:600,  ysize:350, dx:10, dy:10, monitor:0, corner:2} ; Orbit cylindrical
             Mopt  = {xsize:757,  ysize:409, dx:10, dy:10, monitor:0, corner:1} ; Mars Small
             MMopt = {xsize:1082, ysize:572, dx:10, dy:10, monitor:0, corner:1} ; Mars Large
             SSopt = {xsize:600,  ysize:280, dx:10, dy:10, monitor:0, corner:2} ; MSO Lat-Lon

             Ropt = {xsize:792, ysize:765, dx:10, dy:10, monitor:0, corner:0}   ; Orrery

             tplot_options,'charsize',1.5  ; larger characters for 5120x1440 display
           end
    
    '2'  : begin  ; Macbook 1440x900 (below) with twin Dell 2560x1440 (left, right)
             snap_index = 6

             Dopt = {xsize:800, ysize:600, dx:10, dy:10, monitor:2, corner:0}   ; 3D
             Sopt = {xsize:450, ysize:600, dx:820, dy:10, monitor:2, corner:0}  ; 3D SPEC

             Popt = {xsize:800, ysize:600, dx:10, dy:10, monitor:2, corner:0}   ; PAD
             Nopt = {xsize:600, ysize:450, dx:10, dy:10, monitor:2, corner:2}   ; PAD Energy Cut
             Copt = {xsize:500, ysize:700, dx:10, dy:10, monitor:2, corner:2}   ; PAD 3D View
             Fopt = {xsize:400, ysize:600, dx:820, dy:10, monitor:2, corner:0}  ; PAD SPEC

             Eopt = {xsize:400, ysize:600, dx:10, dy:10, monitor:2, corner:0}   ; SPEC
             Hopt = {xsize:200, ysize:600, dx:420, dy:10, monitor:2, corner:0}  ; HSK

             Oopt  = {xsize:322,  ysize:868, dx:10, dy:10, monitor:2, corner:0} ; Orbit 1x3
             Oopt1 = {xsize:500,  ysize:473, dx:10, dy:10, monitor:2, corner:0} ; Orbit 1x1
             OCopt = {xsize:600,  ysize:350, dx:10, dy:10, monitor:2, corner:2} ; Orbit cylindrical
             Mopt  = {xsize:757,  ysize:409, dx:10, dy:10, monitor:2, corner:1} ; Mars Small
             MMopt = {xsize:1082, ysize:572, dx:10, dy:10, monitor:2, corner:1} ; Mars Large
             SSopt = {xsize:600,  ysize:280, dx:10, dy:10, monitor:2, corner:2} ; MSO Lat-Lon

             Ropt = {xsize:792, ysize:765, dx:10, dy:10, monitor:2, corner:0}   ; Orrery

             tplot_options,'charsize',1.5  ; larger characters for 2560x1440 display
           end

    '3'  : begin  ; Macbook 1440x900 (below) with Dell 2560x1440 (above)
             snap_index = 4

             Dopt = {xsize:800, ysize:600, dx:10, dy:10, monitor:0, corner:0}   ; 3D
             Sopt = {xsize:450, ysize:600, dx:820, dy:10, monitor:0, corner:0}  ; 3D SPEC

             Popt = {xsize:800, ysize:600, dx:10, dy:10, monitor:0, corner:0}   ; PAD
             Nopt = {xsize:600, ysize:450, dx:10, dy:10, monitor:0, corner:2}   ; PAD Energy Cut
             Copt = {xsize:500, ysize:700, dx:10, dy:10, monitor:0, corner:2}   ; PAD 3D View
             Fopt = {xsize:400, ysize:600, dx:820, dy:10, monitor:0, corner:0}  ; PAD SPEC

             Eopt = {xsize:400, ysize:600, dx:10, dy:10, monitor:0, corner:0}   ; SPEC
             Hopt = {xsize:200, ysize:600, dx:420, dy:10, monitor:0, corner:0}  ; HSK

             Oopt  = {xsize:318,  ysize:856, dx:10, dy:0, monitor:0, corner:0}  ; Orbit 1x3
             Oopt1 = {xsize:500,  ysize:473, dx:10, dy:10, monitor:0, corner:0} ; Orbit 1x1
             OCopt = {xsize:600,  ysize:350, dx:10, dy:10, monitor:0, corner:2} ; Orbit cylindrical
             Mopt  = {xsize:757,  ysize:409, dx:10, dy:10, monitor:0, corner:1} ; Mars Small
             MMopt = {xsize:1082, ysize:572, dx:10, dy:10, monitor:0, corner:1} ; Mars Large
             SSopt = {xsize:600,  ysize:280, dx:10, dy:10, monitor:0, corner:2} ; MSO Lat-Lon

             Ropt = {xsize:792, ysize:765, dx:10, dy:10, monitor:0, corner:0}   ; Orrery
             
             tplot_options,'charsize',1.5
           end

    else : begin  ; Default.  No fixed window positions
             snap_index = 0

             Dopt = {xsize:800, ysize:600}    ; 3D
             Sopt = {xsize:450, ysize:600}    ; 3D SPEC

             Popt = {xsize:800, ysize:600}    ; PAD
             Nopt = {xsize:600, ysize:450}    ; PAD Energy Cut
             Copt = {xsize:500, ysize:700}    ; PAD 3D View
             Fopt = {xsize:400, ysize:600}    ; PAD SPEC

             Eopt = {xsize:400, ysize:600}    ; SPEC
             Hopt = {xsize:200, ysize:545}    ; HSK

             Oopt  = {xsize:318, ysize:856}   ; Orbit 1x3
             Oopt1 = {xsize:600, ysize:538}   ; Orbit 1x1
             OCopt = {xsize:600,  ysize:350}  ; Orbit cylindrical
             Mopt  = {xsize:757,  ysize:409}  ; Mars Small
             MMopt = {xsize:1082, ysize:572}  ; Mars Large
             SSopt = {xsize:600, ysize:280}   ; MSO Lat-Lon

             Ropt  = {xsize:792, ysize:765}   ; Orrery
           end

  endcase

  return

end
