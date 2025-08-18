;+
; NAME:
;   jbt_tplot_pos (function)
;
; PURPOSE:
;   Get the positions of tplot panels. The returned array has the form 
;   [n_panels, 4]. The meanings of the 4 values of each panel are:
;       [*, 0]: left x
;       [*, 1]: bottom y
;       [*, 2]: right x
;       [*, 3]: top y
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   pos = jbt_tplot_pos(npanels = npanels, xpos = xpos, ypos = ypos, $
;   enclose = enclose)
;   
;   xpos and ypos store locations for plots. For example, 
;       plots, xpos[0,*], ypos[0,*], color = 6 ; 6 = red
;   will draw lines along the top panel frame.
;
; ARGUMENTS:
;
; KEYWORDS:
;     npanels: (Output, optional)
;     xpos: (Output, optional)
;     ypos: (Output, optional)
;     /enclose: (Input, optional)
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-24: Created by Jianbao Tao(JBT), SSL, UC Berkeley.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-11-02 16:35:10 -0700 (Fri, 02 Nov 2012) $
; $LastChangedRevision: 11172 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/utils/jbt_tplot_pos.pro $
;-

function jbt_tplot_pos, npanels = npanels, xpos = xpos, ypos = ypos, $
  enclose = enclose


compile_opt idl2

@tplot_com.pro

chsize = !p.charsize
if chsize eq 0. then chsize=1.

def_opts= {ymargin:[4.,2.],xmargin:[12.,12.],position:fltarr(4), $
   title:'',ytitle:'',xtitle:'', $
   xrange:dblarr(2),xstyle:1,    $
   version:3, window:-1, wshow:0,  $
   charsize:chsize,noerase:0,overplot:0,spec:0}

extract_tags,def_opts,tplot_vars.options

varnames = tnames(/tplot)
nd = n_elements(varnames)

npanels = nd

if nd eq 0 then begin
  dprint, 'No vlaid tplot variables in memory. NaN returned.'
  return, !values.f_nan
endif

sizes = fltarr(nd)
for i=0,nd-1 do begin
   dum = 1.
   lim = 0
   get_data,tplot_vars.options.varnames[i],alim=lim
   str_element,lim,'panel_size',value=dum
   sizes[i] = dum
endfor

str_element,def_opts,'ygap',value = ygap
; dprint, 'ygap = ', ygap
; dprint, 'ymargin = ', def_opts.ymargin

nvlabs = [0.,0.,0.,1.,0.]
str_element,tplot_vars,'options.var_label',var_label
if keyword_set(var_label) then if size(/type,var_label) eq 7 then $
    if ndimen(var_label) eq 0 then var_label=tnames(var_label) ;,/extrac)
;ensure the index does not go out of range, other values will use default
if def_opts.version lt 1 or def_opts.version gt 4 then def_opts.version = 3
nvl = n_elements(var_label) + nvlabs[def_opts.version]
def_opts.ymargin = def_opts.ymargin + [nvl,0.]


old_pmulti = !p.multi

!p.multi = 0
pos = plot_positions(ysizes=sizes,options=def_opts,ygap=ygap)
!p.multi = old_pmulti

pos = transpose(pos)

if ~keyword_set(enclose) then begin
  xpos = fltarr(npanels, 4)
  ypos = fltarr(npanels, 4)

  xpos[*, 0] = pos[*, 0]
  xpos[*, 1] = pos[*, 0]
  xpos[*, 2] = pos[*, 2]
  xpos[*, 3] = pos[*, 2]

  ypos[*, 0] = pos[*, 1]
  ypos[*, 1] = pos[*, 3]
  ypos[*, 2] = pos[*, 3]
  ypos[*, 3] = pos[*, 1]
endif else begin
  xpos = fltarr(npanels, 5)
  ypos = fltarr(npanels, 5)

  xpos[*, 0] = pos[*, 0]
  xpos[*, 1] = pos[*, 0]
  xpos[*, 2] = pos[*, 2]
  xpos[*, 3] = pos[*, 2]
  xpos[*, 4] = pos[*, 0]

  ypos[*, 0] = pos[*, 1]
  ypos[*, 1] = pos[*, 3]
  ypos[*, 2] = pos[*, 3]
  ypos[*, 3] = pos[*, 1]
  ypos[*, 4] = pos[*, 1]
endelse

return, pos

end

