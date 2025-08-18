
;function get_color_indx,color --> this is now a stand-alone function

;if data_type(color) eq 7 then begin
;  case strmid(color,1,0) of
;  'r': vecs = [255,0,0]
;endif


;tvlct,r,g,b,/get
;vecs = replicate(1.,n_elements(r)) # reform(color)
;tbl = [[r],[g],[b]]
;d = sqrt( total((vecs-tbl)^2,2) )
;m = min(d,bin)
;return,byte(bin)
;end


;+
;FUNCTION:    get_colors
;PURPOSE:   returns a structure containing color pixel values
;INPUT:    none
;KEYWORDS:
;   NOCOLOR:  forces all colors to !d.table_size-1.
;
;Written by: Davin Larson    96-01-31
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-02-03 13:32:18 -0800 (Mon, 03 Feb 2025) $
; $LastChangedRevision: 33109 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/get_colors.pro $
;-
function  get_colors,colors=cols,array=array,input
@colors_com

dt = size(/type,input)

if dt ge 1 and dt le 5 then return,round(input)

magenta  = get_color_indx([1,0,1]*255)
red      = get_color_indx([1,0,0]*255)
yellow   = get_color_indx([1,1,0]*255)
green    = get_color_indx([0,1,0]*255)
cyan     = get_color_indx([0,1,1]*255)
blue     = get_color_indx([0,0,1]*255)
white    = get_color_indx([1,1,1]*255)
black    = get_color_indx([0,0,0]*255)

colors = [black,magenta,blue,cyan,green,yellow,red,white]
cols = colors

; Include color table info, if present (dmitchell, July 2022)

ctab = n_elements(color_table) ? color_table : -1
crev = n_elements(color_reverse) ? color_reverse : 0
cbot = n_elements(bottom_c) ? bottom_c : -1
ctop = n_elements(top_c) ? top_c : -1
lndx = n_elements(line_colors_index) ? line_colors_index : -1
ctfl = n_elements(ct_file) ? ct_file : ''
ctmx = n_elements(ct_max) ? ct_max : -1

col = {black:black,magenta:magenta,blue:blue,cyan:cyan,green:green, $
  yellow:yellow,red:red,white:white,color_table:ctab,bottom_c:cbot, $
  top_c:ctop,color_reverse:crev,line_colors_index:lndx, ct_file:ctfl, $
  ct_max:ctmx}

if dt eq 7 then begin
  map = bytarr(256)+!p.color
  map[byte('xmbcgyrw')] = colors
  map[byte('XMBCGYRW')] = colors
  map[byte('0123456789')] = bindgen(10)
  map[byte('Dd')] = !p.color
  map[byte('Zz')] = !p.background
  cb = reform(byte(input))
  return,map[cb]
endif

if keyword_set(array) then return,colors else return,col

end




