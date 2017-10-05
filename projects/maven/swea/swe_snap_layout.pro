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
;USAGE:
;  swe_snap_layout, layout
;
;INPUTS:
;       layout:        Integer specifying the layout:
;
;                        0 --> Default.  No fixed window positions.
;                        1 --> Macbook 1440x900 with Dell 1920x1200 (above)
;                        2 --> Twin Dell 1920x1200 (left, right)
;                        3 --> Macbook 1440x900 with ViewSonic 1680x1050 (above)
;                        4 --> Macbook 1440x900 with Dell 2560x1440 (above)
;                        5 --> Macbook 1440x900 (below) with twin Dell 1920x1200 (left, right)
;                        6 --> Macbook 1440x900 (below) with twin Dell 2560x1440 (left, right)
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-05-08 17:32:11 -0700 (Mon, 08 May 2017) $
; $LastChangedRevision: 23287 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_snap_layout.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_snap_layout, layout, home=home, work=work

  @swe_snap_common
  
  if keyword_set(home) then layout = 4
  if keyword_set(work) then layout = 6
  
  if (size(layout,/type) eq 0) then begin
    print,"Hardware-dependent positions for snapshot windows (optional)."
    print,"  0 --> Default.  No fixed window positions."
    print,"  1 --> 1440x900 (below) with 1920x1200 (above)"
    print,"  2 --> 1920x1200 (left) with 1920x1200 (right)"
    print,"  3 --> 1440x900 (below) with 1680x1050 (above)"
    print,"  4 --> 1440x900 (right) with 2560x1440 (above)"
    print,"  5 --> 1440x900 (below) with 1920x1200 (left), 1920x1200 (right)"
    print,"  6 --> 1440x900 (below) with 2560x1440 (left), 2560x1440 (right)"
    print,""
    layout = ''
    read, layout, prompt='Layout > '
  endif

  case layout[0] of

    '1'  : begin  ; Macbook 1440x900 with Dell 1920x1200 (above)
             snap_index = 1

             Dopt = {xsize:800, ysize:600, xpos:300,  ypos:-600}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:1130, ypos:-600}

             Popt = {xsize:800, ysize:600, xpos:300,  ypos:-600}  ; PAD
             Nopt = {xsize:450, ysize:600, xpos:1130, ypos:-600}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}
             Fopt = {xsize:400, ysize:600, xpos:1130,  ypos:-600}

             Eopt = {xsize:400, ysize:600, xpos:720,  ypos:-600}  ; SPEC
             Hopt = {xsize:225, ysize:545, xpos:480, ypos:-600}
           end
    
    '2'   : begin  ; Twin Dell 1920x1200 (left, right)
             snap_index = 2

             Dopt = {xsize:800, ysize:600, xpos:1120, ypos:640}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:880,  ypos:500}

             Popt = {xsize:800, ysize:600, xpos:1120, ypos:640}  ; PAD
             Nopt = {xsize:450, ysize:600, xpos:880,  ypos:500}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}
             Fopt = {xsize:400, ysize:600, xpos:880, ypos:640}

             Eopt = {xsize:400, ysize:600, xpos:1120, ypos:640}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:880,  ypos:500}
           end
    
    '3'  : begin  ; Macbook 1440x900 with ViewSonic 1680x1050 (above)
             snap_index = 3

             Dopt = {xsize:800, ysize:600, xpos:240,  ypos:-600}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:1100, ypos:-600}

             Popt = {xsize:800, ysize:600, xpos:240,  ypos:-600}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:1050, ypos:-600}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}
             Fopt = {xsize:400, ysize:600, xpos:1050,  ypos:-600}

             Eopt = {xsize:400, ysize:600, xpos:240,  ypos:-600}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:700,  ypos:-540}
           end
    
    '4'  : begin  ; Macbook 1440x900 with Dell 2560x1440 (above)
             snap_index = 4
             x0 = 570
             y0 = -622

             Dopt = {xsize:800, ysize:600, xpos:x0,     ypos:y0}     ; 3D
             Sopt = {xsize:450, ysize:600, xpos:x0+810, ypos:y0}

             Popt = {xsize:800, ysize:600, xpos:x0,     ypos:y0}     ; PAD
             Nopt = {xsize:600, ysize:450, xpos:x0,     ypos:y0-200}
             Copt = {xsize:500, ysize:700, xpos:1000,   ypos:-700}
             Fopt = {xsize:400, ysize:600, xpos:x0+810, ypos:y0}

             Eopt = {xsize:400, ysize:600, xpos:x0,     ypos:y0}     ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:x0+410, ypos:y0+55}

             Oopt  = {xsize:322,  ysize:868, xpos:594,  ypos:-890}   ; MVN_ORB_TPLT
             OCopt = {xsize:600,  ysize:350, xpos:928, ypos:-878}
             Mopt  = {xsize:757,  ysize:409, xpos:940, ypos:-430}
             MMopt = {xsize:1082, ysize:572, xpos:925,  ypos:-594}
             
             tplot_options,'charsize',1.5  ; larger characters for 2560x1440 display
           end
    
    '5'  : begin  ; Macbook 1440x900 with Twin Dell 1920x1200 (left, right)
             snap_index = 5
             xsize = 1920
             ysize = 1200

             Dopt = {xsize:800, ysize:600, xpos:xsize+100, ypos:640}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:xsize+1000, ypos:640}

             Popt = {xsize:800, ysize:600, xpos:xsize+100, ypos:640}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:xsize+1000, ypos:640}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}
             Fopt = {xsize:400, ysize:600, xpos:xsize+1000, ypos:640}

             Eopt = {xsize:400, ysize:600, xpos:xsize+100, ypos:640}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:xsize+600, ypos:640}
           end
    
    '6'  : begin  ; Macbook 1440x900 with twin Dell 2560x1440 (left, right)
             snap_index = 6
             xsize = 2560
             ysize = 1440

             Dopt = {xsize:800, ysize:600, xpos:xsize+100, ypos:640}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:xsize+1000, ypos:640}

             Popt = {xsize:800, ysize:600, xpos:xsize+100, ypos:640}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:xsize+170, ypos:150}
             Copt = {xsize:500, ysize:700, xpos:1000, ypos:-700}
             Fopt = {xsize:400, ysize:600, xpos:xsize+1000, ypos:640}

             Eopt = {xsize:400, ysize:600, xpos:xsize+100, ypos:640}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:xsize+600, ypos:640}

             Oopt  = {xsize:322,  ysize:868, xpos:xsize+12, ypos:560}   ; MVN_ORB_TPLT
             OCopt = {xsize:600,  ysize:350, xpos:xsize+12, ypos:100}
             Mopt  = {xsize:757,  ysize:409, xpos:xsize+350, ypos:1020}
             MMopt = {xsize:1082, ysize:572, xpos:xsize+350, ypos:856}
             
             tplot_options,'charsize',1.5  ; larger characters for 2560x1440 display
           end
    
    else : begin  ; Default.  No fixed window positions
             snap_index = 0

             Dopt = {xsize:800, ysize:600, xpos:0, ypos:0}  ; 3D
             Sopt = {xsize:450, ysize:600, xpos:0, ypos:0}

             Popt = {xsize:800, ysize:600, xpos:0, ypos:0}  ; PAD
             Nopt = {xsize:600, ysize:450, xpos:0, ypos:0}
             Copt = {xsize:500, ysize:700, xpos:0, ypos:0}
             Fopt = {xsize:400, ysize:600, xpos:0, ypos:0}

             Eopt = {xsize:400, ysize:600, xpos:0, ypos:0}  ; SPEC
             Hopt = {xsize:200, ysize:545, xpos:0, ypos:0}
           end

  endcase

  return

end
