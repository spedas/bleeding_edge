;+
;PROCEDURE: gopen, filename
;PURPOSE: 
;  Prepare to put out a GIF file.
;INPUT:    optional;  if:
;  string   :  string used as filename,  '.gif' extension is added automatically
;  integer X:  filename set to 'plotX.gif'.  value of x is incremented by 1.
;  none:       filename set to 'plot.gif'
;KEYWORDS: See print_options for info.
;  COPY:    pass COPY keyword to set_plot
;  INTERP:  pass INTERP keyword to set_plot  (default is to have interp on)
;
;SEE ALSO:	"gclose",
;		"print_options",
;		"gopen_com"
;
;CREATED BY:	Davin Larson (as popen.pro)
;SWIPED BY: Bill Peria
;
;-

pro gopen,n,          $
          color=color,        $
          bw=bw,              $
          directory=printdir, $
          xsize = xsize,      $
          ysize = ysize,      $
          interp = interp,    $
          ctable = ctable,    $
          set_character_size = set_character_size, $
          copy = copy
@gopen_com

if (keyword_set(port) or  $
    keyword_set(land) or  $
    keyword_set(color) or  $
    keyword_set(printer) or  $
    keyword_set(font) or  $
    keyword_set(bw) or  $
    keyword_set(aspect) or  $
    keyword_set(encapsulated)) then begin
    message,' ignoring PostScript-only keywords...',/continue
endif

zres = [680,480]
if keyword_set(xsize) then zres(0) = xsize
if keyword_set(ysize) then zres(1) = ysize


if n_params() ne 0 then begin
    if data_type(n) eq 0 then n = 1
    if data_type(n) eq 2 then begin
        gif_name = strcompress('plot'+string(n)+'.gif',/REMOVE_ALL)
        n = n+1
    endif
    if data_type(n) eq 7 then begin
        if strmid(n,strlen(n)-4,4) ne '.gif' then begin
            gif_name=n+'.gif'
        endif else begin
            gif_name = n
        endelse
    endif
endif
if (data_type(gif_name) ne 7) or not defined(n) then gif_name = 'plot.gif'
if data_type(print_dir) eq 7 then gif_name = print_dir+'/'+gif_name

g_old_device = !d.name
                                ;g_old_color  = !p.color
                                ;g_old_bckgrnd= !p.background

if n_elements(interp) eq 0 then interp = 0
if n_elements(copy) eq 0 then copy =0

tvlct,g_old_r,g_old_g,g_old_b,/get

set_plot,'Z',interp=interp,copy=copy
device,set_resolution=zres
if defined (set_character_size) then begin
    device,set_character_size = set_character_size
endif


if n_elements(ctable) ne 0 then begin
    loadct2,ctable(0)
endif

return
end




