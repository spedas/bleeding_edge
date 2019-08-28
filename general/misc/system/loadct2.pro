
;+
;PROCEDURE loadct2, colortable
;   By default LOADCT2 uses the same color table used by LOADCT
;   This can be changed in 3 ways:
;   1) Use the FILE keyword to define a new file
;   2) Define the environment variable IDL_CT_FILE to point to a new file
;   3) Place a new color table file in the same directory as LOADCT2 that matches
;         the name: 'colors*.tbl'.  (The last file found with file_search is used).
;
;KEYWORDS:
;   FILE:  (string) Color table file
;          If FILE is not provided then LOADCT2
;          Uses the environment variable IDL_CT_FILE to determine
;          the color table file if FILE is not set.
;   line_clrs: array of 24 (3x8 RGB colors)
;          To be used as 8 colors (the first 7 and the last) of the color table.
;          If this is set, but no array is provided, then a default set of 8 colors will be used
;          (four different color schemes are provided, appropriate for colorblind vision).
;
;common blocks:
;   colors:      IDL color common block.  Many IDL routines rely on this.
;   colors_com:
;See also:
;   "get_colors","colors_com","bytescale"
;
;Created by Davin Larson;  August 1996
;Version:           1.4
;File:              00/07/05
;Last Modification: loadct2.pro
;-


pro loadct2,ct,invert=invert,reverse=revrse,file=file,previous_ct=previous_ct,graybkg=graybkg, line_clrs=line_clrs
  COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com

  deffile = getenv('IDL_CT_FILE')
  dir = ''
  if not keyword_set(deffile) then begin  ; looks for color table file in same directory
    stack = scope_traceback(/structure)
    filename = stack[scope_level()-1].filename
    dir = file_dirname(filename)
    deffile = file_search(dir+'/'+'colors*.tbl',count=nf)
    if nf gt 0 then deffile=deffile[nf-1]              ; Use last one found
    ;dprint,'Using color table: ',deffile,dlevel=3
  endif
  if not keyword_set(file) and keyword_set(deffile) then file=deffile
  
  if keyword_set(file) && ~file_test(file) then file=dir + path_sep() + file

  black = 0
  magenta=1
  blue = 2
  cyan = 3
  green = 4
  yellow = 5
  red = 6
  bottom_c = 7

  if n_elements(color_table) eq 0 then color_table=ct
  previous_ct =  color_table
  if !d.name eq 'NULL' or !d.name eq 'HP' then begin   ; NULL device and HP device do not support loadct
    dprint,'Device ',!d.name,' does not support color tables. Command Ignored'
    return
  endif
  if (ct le 43 or keyword_set(deffile)) then loadct,ct,bottom=bottom_c,file=file $
  else loadct,ct,bottom=bottom_c ; this line is changed to be able to load color tables > 43
  color_table = ct

  top_c = !d.table_size-2
  white =top_c+1
  cols = [black,magenta,blue,cyan,green,yellow,red,white]
  primary = cols[1:6]


  tvlct,r,g,b,/get

  if keyword_set(revrse) then begin
    r[bottom_c:top_c] = reverse(r[bottom_c:top_c])
    g[bottom_c:top_c] = reverse(g[bottom_c:top_c])
    b[bottom_c:top_c] = reverse(b[bottom_c:top_c])
  endif

  r[cols] = [0,1,0,0,0,1,1,1]*255b
  g[cols] = [0,0,0,1,1,1,0,1]*255b
  b[cols] = [0,1,1,1,0,0,0,1]*255b

  if keyword_set(graybkg) then begin
    r[cols[7]] = 211b
    g[cols[7]] = 211b
    b[cols[7]] = 211b
    if n_elements(graybkg) eq 3 then begin
      r[cols[7]] = graybkg[0]
      g[cols[7]] = graybkg[1]
      b[cols[7]] = graybkg[2]
    endif
  endif

  ; Line and background colors provided by user
  if keyword_set(line_clrs) then begin
    if n_elements(line_clrs) ne 24 then begin
      ; If the user did not provide 8 colors, then use a color scheme appropriate for colorblind vision
      n=fix(line_clrs[0])
      case n of
        1: line_clrs = [[0,0,0],[67, 147, 195],[33, 102, 172],[103, 0, 31],[178,24,43],[254,219,199],[244,165,130],[255,255,255]]
        2: line_clrs = [[0,0,0],[253,224,239],[77,146,33],[161,215,106],[233,163,201],[230,245,208],[197,27,125],[255,255,255]]
        3: line_clrs = [[0,0,0],[216,179,101],[140,81,10],[246,232,195],[1,102,94],[199,234,229],[90,180,172],[255,255,255]]   
        4: line_clrs = [[0,0,0],[84,39,136],[153,142,195],[216,218,235],[241,163,64],[254,224,182],[179,88,6],[255,255,255]]  
        else: line_clrs = [[0,0,0],[67, 147, 195],[33, 102, 172],[103, 0, 31],[178,24,43],[254,219,199],[244,165,130],[255,255,255]]
      endcase      
    endif
    for i=0, 6 do begin
      r[i] = line_clrs[i*3]*1b
      g[i] = line_clrs[i*3+1]*1b
      b[i] = line_clrs[i*3+2]*1b
    endfor
    ncount = n_elements(r)
    r[ncount-1] = line_clrs[21]*1b
    g[ncount-1] = line_clrs[22]*1b
    b[ncount-1] = line_clrs[23]*1b
  endif


  tvlct,r,g,b

  r_curr = r  ;Important!  Update the colors common block.
  g_curr = g
  b_curr = b

  ;force end colors  0 is black max is white
  ;tvlct,r,g,b,/get
  ;n = n_elements(r)
  ;lc = n-1
  ;black = 0
  ;white = 255
  ;if keyword_set(revrse) then begin
  ;  r = reverse(r)
  ;  g = reverse(g)
  ;  b = reverse(b)
  ;endif
  ;if keyword_set(invert) then begin
  ;  black = 255
  ;  white = 0
  ;endif
  ;r(0) = black & g(0)=black  & b(0)=black
  ;r(lc)=white  & g(lc)=white & b(lc)=white
  ;tvlct,r,g,b

end


