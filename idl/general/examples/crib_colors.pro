;+
; Name: crib_colors
;
; Purpose: Crib on how to set colors for line plots and spectrograms
;
; Notes: Run it by typing in IDL command line:
;           .compile crib_colors
;           .go
;           .c
;        or copy and paste.
;
; Colors in SPEDAS:
;
;   To view the currently loaded color table, use: xpalette
;   To retrieve a color index by its name, use the routine: spd_get_color (e.g., blue = spd_get_color('blue'))
;       see the header of spd_get_color for supported colors
;   To load the default color table for SPEDAS, type: init_crib_colors
;   The procedure loadct2 loads a color table and changes 8 colors (the first 7 and the last) to these:
;       [black, magenta, blue, cyan, green, yellow, red, white]
;   The last color in the table is used as the plot background, and it is usually white.
;   The first 7 colors are used in line plots, usually with the following order:
;       [blue, green, red, black, yellow, magenta, cyan]
;   The user can specify these 8 colors, using:
;       loadct2, 65, line_clr=line_clr
;       where line_clr is an array of 8 RGB colors: [[0,0,0],...,[255,255,255]]
;   For tplot, you can pick which colors of the color table to use in line plots, with the command "options", ie:
;       options, 'tplot_name', colors=[1,2,3]
;   Directory general/misc/system contains the default color table 'colors1.tbl',
;       and also 'cbcolors2.tbl' which is a copy of IDL color table 65.
;   For IDL versions before IDL 8.6, the IDL colortable 65 can be loaded using:
;       loadct2, 15, file='cbcolors2.tbl', line_clr=1
;   Users can create their own color tables, and then save them in a file using:
;       TVLCT, red, green, blue, /GET
;       MODIFYCT, 14, 'My Table Name', red, green, blue, FILE='/path/to/file'
;   and then load them using:
;       loadct2, 14, file='/path/to/file', line_clr=1
;
; For a color picker with colorblind choices, see:
;    http://colorbrewer2.org/#type=sequential&scheme=GnBu&n=6
;
;
;Warning: this crib uses some data from the THEMIS branch.  You'll require those routines to run this crib.
;
; $LastChangedBy:$
; $LastChangedDate:$
; $LastChangedRevision:$
; $URL:$
;-

; Load some data
print, 'Start of crib_colors'
device, decomposed = 0
del_data,'*'
timespan,'2007-06-23'
thm_load_state, probe='a'
thm_load_sst, probe='a', level='l1'

; Find how many color tables are supported in this IDL version
loadct, get_names=cn_str
ct = n_elements(cn_str)
msg = 'This IDL version supports ' + string(ct) + ' color tables.'
print, msg

; Create line plot with area under the line filled in
print, 'Example of line plot with area filled in'
tplot, ['tha_psif_tot', 'tha_state_vel', 'tha_psif_en']

; fill in tha_psif_tot 
tplot_fill_color, 'tha_psif_tot', spd_get_color('blue')
stop

; Plot with default colors
init_crib_colors
print, 'Example of line plot and spectrogram using default SPEDAS colors.'
tplot,['tha_state_vel', 'tha_psif_en']
stop

; Older IDL versions may not include color table 65
if ct lt 65 then begin
  msg = 'Skipping examples with color table number 65 because it is not supported in this IDL version.'
  print, msg
endif else begin
  ; Load color table 65, with default line colors
  init_crib_colors
  loadct2, 65
  print, 'Example of line plot using default SPEDAS colors and spectrogram using IDL color table 65.'
  tplot,['tha_state_vel', 'tha_psif_en']
  stop

  ; Load color table 65, with colorblind-appropriate line plot colors
  init_crib_colors
  loadct2, 65, /line_clr ; this is the same as line_clr=1
  print, 'Example of spectrogram using IDL color table 65 and line colors from loadct2 preset 1.'
  tplot,['tha_state_vel', 'tha_psif_en']
  stop

  ; Load color table 65, with second color scheme for line plots
  init_crib_colors
  loadct2, 65, line_clr=2
  print, 'Example of spectrogram using IDL color table 65 and line colors from loadct2 preset 2.'
  tplot,['tha_state_vel', 'tha_psif_en']
  stop

  ; Load color table 65, with user-defined RGB colors for line plots and background
  init_crib_colors
  line_clr=[[0,0,0],[118,42,131],[175,141,195],[231,212,232],[217,240,211],[127,191,123],[27,120,55],[209,229,240]]
  loadct2, 65, line_clr=line_clr
  ; for the line plot, use colors 1,2 and 6 of the palette
  options,'tha_state_vel',colors=[1,2,6]
  print, 'Example of spectrogram using IDL color table 65 and line colors and background provided by user.'
  tplot,['tha_state_vel', 'tha_psif_en']
  stop
end

; For older IDL versions, load the colorblind-appropriate file cbcolors2.tbl:
init_crib_colors
loadct2, 15, file='cbcolors2.tbl', line_clr=1
; for the line plot, use colors 1,2 and 6 of the palette
options,'tha_state_vel',colors=[1,2,6]
print, 'Example of spectrogram using file cbcolors2.tbl and line colors from loadct2 preset 1.'
tplot,['tha_state_vel', 'tha_psif_en']
stop

; Specify line colors by name.  For list of color names supported, see spd_get_color.pro.
; Name matching is case insensitive, but whitespace matters.  Unknown color names will show up
; as black.

init_crib_colors
loadct2,15,file='cbcolors2.tbl',line_color_names=['black','orange','chartreuse','navy blue','dark gray','rosy brown','forest green','white']
options,'tha_state_vel',colors=[1,2,6]
print, 'Example of spectrogram using file cbcolors2.tbl and line colors specified by name'
tplot,['tha_state_vel', 'tha_psif_en']
stop

; Revert to default colors
init_crib_colors

print, 'End of crib_colors'

end