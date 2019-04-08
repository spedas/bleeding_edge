;+
; PROCEDURE loadct_sd
;
; :DESCRIPTION:
; This procedure is basically the same as loadct2.pro except for
; yellow (color=5) replaced with grey. Some additional colormaps 
; were also implemented for indices 44-47 as follows: 
;    44 : the Cutlass color table often used for SuperDARN data
;    45 : a color table similar to the one that was used in the JHU/APL SuperDARN website
;    46 : the "jet" colormap used by matplotlib of python
;    47 : the "viridis" colormap also used by matplotlib of python
;
; Some original functions to modify a colarmap were also added as keywords: 
;  center_hatched: if set, colors arount the center of a colormap are hatched with white (default)
;  hatched_color: set a color index used for the hatching turned on by center_hatched keyword
;  hatched_width: number of indices over which the hatching is applied. Default is 21.
;
; :AUTHOR:
;   Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
; :HISTORY:
;   2017/09/27: jet and viridis implemented
;   2010/11/20: created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-

PRO set_col_tab_from_rgb_txt, rgb_txt, bottom_c

  if n_params() lt 1 then return
  if ~file_test(rgb_txt) then begin
     print, 'Cannot read the RGB text file! The color table does not change.'
     dprint, 'rdb_txt = ', rgb_txt
     return
  endif
  if n_params() ne 2 then bottom_c = 7 ;default

  dat = read_ascii( rgb_txt ) 
  rgb = byte( dat.field1 )
  red = reform( rgb[0,*] )
  green = reform( rgb[1,*] )
  blue = reform( rgb[2,*] )
  
  if !d.name ne 'null' and !d.name ne 'HP' then begin
     tvlct, red, green, blue
  endif
  
end

;To define the cutlass color table. The RGB values are loaded
;from cut_col_tab.dat which should be placed in the same directory.
PRO cut_col_tab

                                ; Number of colours for current device
  ncol=(!D.N_COLORS<256)-1
  
  red  =INTARR(ncol)
  green=INTARR(ncol)
  blue =INTARR(ncol)
  
  colour_table=INTARR(4,256)
  
  stack = SCOPE_TRACEBACK(/structure)
  filename = stack[SCOPE_LEVEL()-1].filename
  dir = FILE_DIRNAME(filename)
  fname_cut_coltbl = dir+'/col_tbl/cut_col_tab.dat'
  OPENR,colorfile,fname_cut_coltbl,/GET_LUN
  READF,colorfile,colour_table
  FREE_LUN,colorfile
  
                                ; Stretch this colour scale coz it's no good at the ends
  colour_stretch=INTARR(4,256)
  scale_start=65
  scale_end=240
  skip=(scale_end-scale_start)/256.0
  FOR col=0,255 DO BEGIN
     colour_stretch(*,col)=colour_table(*,FIX(scale_start+skip*col))
  ENDFOR
  colour_table=colour_stretch
  
  indx=1.0
  skip=255.0/(ncol-1)
  FOR col=1,ncol-1 DO BEGIN
     red(col)  =colour_table(1,FIX(indx))
     green(col)=colour_table(3,FIX(indx))
     blue(col) =colour_table(2,FIX(indx))
     indx=indx+skip
  ENDFOR
  
                                ; Swap colour bar so that color goes red -> yellow -> green -> blue
  red_swap  =red
  blue_swap =blue
  green_swap=green
  FOR col=1,ncol-1 DO BEGIN
     red(ncol-col)  =red_swap(col)
     blue(ncol-col) =blue_swap(col)
     green(ncol-col)=green_swap(col)
  ENDFOR
  
  IF !D.NAME NE 'NULL' AND !d.name NE 'HP'THEN BEGIN
     
     TVLCT,red,green,blue
     
  ENDIF
  
END

;-----------------------------------------------------------------------
PRO cut_col_tab2, bottom_c

  if n_params() ne 1 then bottom_c = 7 ;default
  
                                ;Load the Cutlass table first
  cut_col_tab
  
                                ;Obtain RGB values for the color table
  tvlct, r, g, b, /get
  top_c = !d.table_size-2       ; color=!d.table_size-1 is assigned to white in TDAS
  
  negative_top = bottom_c + fix(ceil((top_c - bottom_c)/2.)) -1
  positive_bottom = negative_top + 1
  
                                ;For debugging
                                ;  print, 'bottom_c=',bottom_c
                                ;  print, 'negative_top=', negative_top
                                ;  print, 'positive_bottom=', positive_bottom
                                ;  print, 'top_c=', top_c
                                ;  print, '# of negative colors=', negative_top - bottom_c +1
                                ;  print, '# of positive colors=', top_c - positive_bottom +1
  
                                ;Initialize
  red  =INTARR(top_c+2)
  green=INTARR(top_c+2)
  blue =INTARR(top_c+2)
  
                                ;Stretch the negative part of the Cutlass color scale to fit in that of the new one
  bot = 1 & top = 110
  neg_r = reverse(r[bot:top])
  neg_g = reverse(g[bot:top])
  neg_b = reverse(b[bot:top])
  for i=0, negative_top-bottom_c do begin
     idx = fix( float(top-bot) * i / (negative_top-bottom_c)    )
     red[i+bottom_c] = neg_r[idx]
     green[i+bottom_c]=neg_g[idx]
     blue[i+bottom_c] =neg_b[idx]
  endfor
                                ;Stretch the positive part of the Cutlass color scale to fit in that of the new one
  bot = 160 & top = 225
  pos_r = reverse(r[bot:top])
  pos_g = reverse(g[bot:top])
  pos_b = reverse(b[bot:top])
  for i=0, top_c-positive_bottom do begin
     idx = fix( float(top-bot) * i / (top_c-positive_bottom)    )
     red[i+positive_bottom] = pos_r[idx]
     green[i+positive_bottom]=pos_g[idx]
     blue[i+positive_bottom] =pos_b[idx]
  endfor
  
  
  
  IF !D.NAME NE 'NULL' AND !d.name NE 'HP'THEN BEGIN
     
     TVLCT,red,green,blue
     
  ENDIF
  
END

;-----------------------------------------------------------------------

PRO loadct_sd,ct,invert=invert,reverse=revrse,file=file,previous_ct=previous_ct, $
              center_hatched=center_hatched, hatched_width=hatched_width, hatched_color=hatched_color
  COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com
  
  deffile = GETENV('IDL_CT_FILE')
  IF NOT KEYWORD_SET(deffile) THEN BEGIN ; looks for color table file in same directory
     stack = SCOPE_TRACEBACK(/structure)
     filename = stack[SCOPE_LEVEL()-1].filename
     dir = FILE_DIRNAME(filename)
     deffile = FILE_SEARCH(dir+'/col_tbl/'+'colors*.tbl',count=nf)
     IF nf GT 0 THEN deffile=deffile[nf-1] ; Use last one found
                                ;dprint,'Using color table: ',deffile,dlevel=3
  ENDIF
  IF NOT KEYWORD_SET(file) AND KEYWORD_SET(deffile) THEN file=deffile
  
  black = 0
  magenta=1
  blue = 2
  cyan = 3
  green = 4
  grey = 5
  red = 6
  bottom_c = 7
  
  IF ~KEYWORD_SET(ct) THEN ct = 43 ;FAST-Special
  
                                ;Error check for ct
  if ct lt 0 or ct gt 47 then begin
     print, 'The number of currently available color tables are 0-47.'
     print, 'Please specify a table number of the above range.'
     return
  endif
  
  IF N_ELEMENTS(color_table) EQ 0 THEN color_table=ct
  previous_ct =  color_table
  IF !d.name EQ 'NULL' OR !d.name EQ 'HP' THEN BEGIN ; NULL device and HP device do not support loadct
     dprint,'Device ',!d.name,' does not support color tables. Command Ignored'
     RETURN
  ENDIF
  
  IF ct LT 43 THEN BEGIN
     loadct,ct,bottom=bottom_c,file=file
  ENDIF ELSE IF ct EQ 43 THEN BEGIN
     loadct,ct,bottom=bottom_c,file=file,/silent
     PRINT, '% Loading table SD-Special'
  ENDIF ELSE IF ct EQ 44 THEN BEGIN
     cut_col_tab
     print, '% Loading table Cutlass color bar for SD'
  ENDIF ELSE IF ct EQ 45 THEN BEGIN
     cut_col_tab2, bottom_c
     print, '% Loading the color bar similar to the default in JHU/APL SD site'
  endif else if ct eq 46 then begin
     set_col_tab_from_rgb_txt, file_source_dirname()+'/col_tbl/rgb_jet.txt', bottom_c
     print, '% Loading the JET color table'
  endif else if ct eq 47 then begin
     set_col_tab_from_rgb_txt, file_source_dirname()+'/col_tbl/rgb_viridis.txt', bottom_c
     print, '% Loading the Viridis color table'
  endif
  
  
  color_table = ct
  
  top_c = !d.table_size-2
  white =top_c+1
  cols = [black,magenta,blue,cyan,green,grey,red,white]
  primary = cols[1:6]
  
  
  TVLCT,r,g,b,/get
  
  IF KEYWORD_SET(revrse) THEN BEGIN
     r[bottom_c:top_c] = reverse(r[bottom_c:top_c])
     g[bottom_c:top_c] = reverse(g[bottom_c:top_c])
     b[bottom_c:top_c] = reverse(b[bottom_c:top_c])
  ENDIF
  
  r[cols] = BYTE([0,1,0,0,0,0.553,1,1]*255)
  g[cols] = BYTE([0,0,0,1,1,0.553,0,1]*255)
  b[cols] = BYTE([0,1,1,1,0,0.553,0,1]*255)
  
                                ;Hatch the colors around the center of the table
  if keyword_set(center_hatched) then begin
     if ~keyword_set(hatched_width) then begin
        hwidth = fix(21)        ; elements in a color table. This should be an odd number.
     endif else hwidth = fix(hatched_width)
     if (hwidth mod 2) eq 0 then hwidth++
     if ~keyword_set(hatched_color) then begin
        r_h = 255 & g_h = 255 & b_h = 255 ;White
     endif else begin
        if n_elements(hatched_color) eq 3 then begin ;given as [r,g,b] 
           r_h = hatched_color[0] & g_h = hatched_color[1] & b_h = hatched_color[2]
        endif else begin        ;given as a scalar
           if hatched_color lt 0 or hatched_color ge n_elements(r) then begin
              r_h = 255 & g_h = 255 & b_h = 255 ;White
           endif else begin
              r_h = r[hatched_color] & g_h = g[hatched_color] & b_h = b[hatched_color]
           endelse
        endelse
     endelse
     
     halfwidth = (hwidth-1)/2
     cnt_c = round( (top_c + bottom_c)/2. )
     cols = indgen(hwidth) + cnt_c - halfwidth
     mincols = min(cols) & maxcols = max(cols)
     dis = ( cols - cnt_c ) / float(halfwidth)
     basecol = cols
     basecol[where(cols lt cnt_c)] = mincols
     basecol[where(cols ge cnt_c)] = maxcols
     
     r_hatched = byte(  r[basecol] + (fix(r_h)-r[basecol])*(1.-abs(dis)^2)  )
     r[cols] = r_hatched
     g_hatched = byte(  g[basecol] + (fix(g_h)-g[basecol])*(1.-abs(dis)^2)  )
     g[cols] = g_hatched
     b_hatched = byte(  b[basecol] + (fix(b_h)-b[basecol])*(1.-abs(dis)^2)  )
     b[cols] = b_hatched
     
  endif
  
                                ;Redefine the color table using the newly contructed RGB values
  TVLCT,r,g,b
  
  r_curr = r                    ;Important!  Update the colors common block.
  g_curr = g
  b_curr = b
  
  
END


