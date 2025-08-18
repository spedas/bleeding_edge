;+
;NAME:
;  bitplot
;
;INPUT: (optional if DATA keyword is set)
;    x: array of x values
;    y: array of y values
;
;PURPOSE:
;  Plots 'ON' bits for housekeeping type data.
;  Can be used by "tplot".
;  See "_tplot_example" and "_get_example_dat" for an example.
;
;KEYWORDS:
;    PSYMS: array of IDL plot psym values corresponding to each bit.
;          OVERPLOT: create plot without erasing previous plot.
;    DI: value to be given to first bit in plot.  Default is 0.
;    LIMITS: TPLOT limits structure corresponding to the variable plotted.
;    DATA: TPLOT data structure corresponding to the variable plotted.
;    NUMBITS: the number of bits that will be plot
;    SYMSIZE: set the size of the symbol
;
; $LastChangedBy: ali $
; $LastChangedDate: 2025-06-02 12:18:19 -0700 (Mon, 02 Jun 2025) $
; $LastChangedRevision: 33356 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/bitplot.pro $
;-
pro bitplot,x,y,psyms=psyms,overplot=overplot,di=di,limits=lim,data=data,numbits=nb,symsize=symsize
if keyword_set(data) then begin
  x = data.x
  y = data.y
  extract_tags,stuff,data,except=['x','y','dy']
endif
extract_tags,stuff,lim
extract_tags,plotstuff,stuff,/plot
extract_tags,oplotstuff,stuff,/oplot
str_element,lim,'numbits',nb
str_element,stuff,'labels',val=labels
str_element,lim,'psyms',psyms
str_element,lim,'symsize',symsize
str_element,lim,'thick',thick
str_element,lim,'negate',negate    
labsize = 1.
str_element,stuff,'labsize',val=labsize
str_element,stuff,'colors',colors
str_element,stuff,'psym_lim',psym_lim
str_element,stuff,'xrange',xrange
str_element,stuff,'panel_label',panel_label ;jmm, 2025-02-18

chsize = !p.charsize
if not keyword_set(chsize) then chsize = 1.

if size(/type, y) eq 5 then begin
  dprint, dlevel=1, 'Bitplot called on double precision variable. Exiting'
  return
endif


if not keyword_set(nb) then begin
case size(/type,y) of
  1:  nb = 8
  2:  nb = 16
  3:  nb = 32
  12: nb = 16
  13: nb = 32
  14: nb = 64
  15: nb = 64
  else: nb = 0
endcase
; if nb=0 should this routine work at all?
endif

if keyword_set(negate) then y =  y xor negate            ; this could introduce a bug because it will change the value of y if it is a named variable


if n_elements(di) eq 0 then di = 0
if keyword_set(psym_lim) &&  ~keyword_set(psyms) then begin
    w = where(x ge xrange[0] and x le xrange[1],nw)
    if nw le psym_lim then   psyms = 1
endif
if not keyword_set(psyms) then psyms = replicate(3,nb)
npsyms = n_elements(psyms)
if not keyword_set(overplot) then $
   plot,/nodata,[x],[y],yrange=[-1+di,nb+di],/ystyle,_extra=plotstuff

if not keyword_set(symsize) then begin
   symsize = 1.0
endif

if not keyword_set(thick) then begin
  thick = 1.0
endif

if n_elements(colors) ne 0 then col = get_colors(colors)  $
else col = !p.color
ncol = n_elements(col)

if nb gt 32 then bit = 1ll else bit = 1l
prefix = replicate("  ",nb)
for i=0,nb-1 do begin
  ind = where(y and bit,c)
  if keyword_set(negate) && (bit and negate) then prefix[i] = " ~"
  if c ne 0 then $
     oplot,x[ind],replicate(i+di,n_elements(ind)),psym=psyms[i mod npsyms],col=col[i mod ncol],symsize=symsize,thick=thick
  bit = bit * 2
endfor

if keyword_set(labels) then begin
   charsize = !p.charsize
   if charsize eq 0 then charsize = 1.
   nlab = n_elements(labels)
   if nlab ne nb then dprint,'label mismatch:',nlab,nb
   yp = indgen(nlab) + di
   xp = replicate(!x.crange[1],nlab)
   yw = !y.window
   xw = !x.window
   ;prefix = "  "
   if not keyword_set(lbsize) then $
     lbsize = charsize < (yw[1]-yw[0])/(nlab+1) *!d.y_size/!d.y_ch_size $
   else lbsize = lbsize*charsize
   xyouts,xp,yp,prefix+labels,charsize=lbsize,color= col[indgen(nlab) mod ncol]
endif

if is_struct(panel_label) then begin ;jmm, 2025-02-18
   tplot_apply_panel_label, panel_label
endif


end
