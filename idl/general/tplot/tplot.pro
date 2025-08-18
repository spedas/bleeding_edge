;+
;PROCEDURE:   tplot  [,datanames]
;PURPOSE:
;   Creates a time series plot of user defined quantities.
;INPUT:
;   datanames: A string of space separated datanames.
;             wildcard expansion is supported.
;             if datanames is not supplied then the last values are used.
;             Each name should be associated with a data quantity.
;             (see the "STORE_DATA" and "GET_DATA" routines.)
;             Alternatively datanames can be an array of integers or strings.
;             run "TPLOT_NAMES" to show the current numbering.
;
;KEYWORDS:
;   TITLE:    A string to be used for the title. Remembered for future plots.
;   ADD_VAR:  Set this variable to add datanames to the previous plot.  If set
;         to 1, the new panels will appear at the top (position 1) of the
;         plot.  If set to 2, they will be inserted directly after the
;         first panel and so on.  Set this to a value greater than the
;         existing number of panels in your tplot window to add panels to
;             the bottom of the plot.
;         Set this variable to a negative integer to count up from the last
;         panel.  If set to -1, the new panels will be placed above the last
;         panel.  If set to -2, they will be placed above the second to last
;         panel, and so on.
;   SUB_VAR:  Set this variable to remove datanames from the plot.
;   LASTVAR:  Set this variable to plot the previous variables plotted in a
;         TPLOT window.
;   PICK:     Set this keyword to choose new order of plot panels
;             using the mouse.
;   TOSS:     Set this keyword to remove panels using the mouse.
;   WINDOW:   Window to be used for all time plots.  If set to -1, then the
;             current window is used.
;   VAR_LABEL:  String [array]; Variable(s) used for putting labels along
;     the bottom. This allows quantities such as altitude to be labeled.
;   VERSION:  Must be 1,2,3,4,5 or 6 (3 is default)  Uses a different labeling
;   scheme.  Version 4 is for rocket-type time scales.
;     valid inputs for "version" (date annotation | tick annotations)
;     1: UTC date boundaries | # of hours or days
;     2: month:day | UTC time (fewer ticks)
;     3: year(left margin) month:day | UTC time (default)
;     4: seconds after launch
;     5: supress time labels
;     6: time displayed directly below last panel
;     7: time displayed directly below last panel (1 line date text only)
;     this option can also be set when calling tplot_options (
;     e.g. tplot, [variable], version=2 )
;   NO_VTITLE_SHIFT: If the var_label keyword is set, then if the full
;     time range is less than 10 minutes, then the titles for the
;     var_labels are shifted downwards a small amount. (Added on
;     2022-02-07). Set /no_vtitle_shift via keyword in the tplot
;     call, or via "tplot_options,'no_vtitle_shift',1" to turn this off.
;   OVERPLOT: Will not erase the previous screen if set.
;   NAMES:    The names of the tplot variables that are plotted.
;   NOCOLOR:  Set this to produce plot without color.
;   TRANGE:   Time range for tplot.
;   NEW_TVARS:  Returns the tplot_vars structure for the plot created. Set
;         aside the structure so that it may be restored using the
;             OLD_TVARS keyword later. This structure includes information
;             about various TPLOT options and settings and can be used to
;             recreates a plot.
;   OLD_TVARS:  Use this to pass an existing tplot_vars structure to
;     override the one in the tplot_com common block.
;   GET_PLOT_POSITION: Returns an array containing the corners of each panel in the plot, to make it easier to overplot and annotate plots
;   HELP:     Set this to print the contents of the tplot_vars.options
;         (user-defined options) structure.
;
;RESTRICTIONS:
;   Some data must be loaded prior to trying to plot it.  Try running
;   "_GET_EXAMPLE_DAT" for a test.
;
;EXAMPLES:  (assumes "_GET_EXAMPLE_DAT" has been run)
;   tplot,'amp slp flx2' ;Plots the named quantities
;   tplot,'flx1',/ADD          ;Add the quantity 'flx1'.
;   tplot                      ;Re-plot the last variables.
;   tplot,var_label=['alt']   ;Put Distance labels at the bottom.
;       For a long list of examples see "_TPLOT_EXAMPLE"
;
;OTHER RELATED ROUTINES:
;   Examples of most usages of TPLOT and related routines are in
;      the crib sheet: "_TPLOT_EXAMPLE"
;   Use "TNAMES" function to return an array of current names.
;   Use "TPLOT_NAMES" to print a list of acceptable names to plot.
;   Use "TPLOT_OPTIONS" for setting various global options.
;   Plot limits can be set with the "YLIM" procedure.
;   Spectrogram limits can be set with the "ZLIM" procedure.
;   Time limits can be set with the "TLIMIT" procedure.
;   The "OPTIONS" procedure can be used to set all IDL
;      plotting keyword parameters (i.e. psym, color, linestyle, etc) as well
;      as some keywords that are specific to tplot (i.e. panel_size, labels,
;      etc.)  For example, to change the relative panel width for the quantity
;      'slp', run the following:
;            OPTIONS,'slp','panel_size',1.5
;   TPLOT calls the routine "SPECPLOT" to make spectrograms and
;      calls "MPLOT" to make the line plots. See these routines to determine
;      what other options are available.
;   Use "GET_DATA" to retrieve the data structure (or
;      limit structure) associated with a TPLOT quantity.
;   Use "STORE_DATA" to create new TPLOT quantities to plot.
;   The routine "DATA_CUT" can be used to extract interpolated data.
;   The routine "TSAMPLE" can also be used to extract data.
;   Time stamping is performed with the routine "TIME_STAMP".
;   Use "CTIME" or "GETTIME" to obtain time values.
;   tplot variables can be stored in files using "TPLOT_SAVE" and loaded
;      again using "TPLOT_RESTORE"
;
;CREATED BY:    Davin Larson  June 1995
;
;QUESTIONS?
;   See the archives at:  http://lists.ssl.berkeley.edu/mailman/listinfo/tplot
;Still have questions:
;   Send e-mail to:  tplot@ssl.berkeley.edu    someone might answer!
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-12-31 18:33:10 -0800 (Tue, 31 Dec 2024) $
; $LastChangedRevision: 33025 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot.pro $
;-

pro tplot,datanames,      $
   WINDOW = wind,         $
   reverse = reverse, $
   NOCOLOR = nocolor,     $
   VERBOSE = verbose,     $
   wshow = wshow,         $
   OPLOT = oplot,         $
   OVERPLOT = overplot,   $
   VERSION = version , $
   TITLE = title,         $
   LASTVAR = lastvar,     $
   ADD_VAR = add_var,     $
   SUB_VAR = sub_var,     $
   LOCAL_TIME= local_time,$
   REFDATE = refdate,     $
   VAR_LABEL = var_label, $
   OPTIONS = opts,        $
   T_OFFSET = t_offset,   $
   TRANGE = trng,         $
   NAMES = names,         $
   PICK = pick,           $
   TOSS = toss,           $
   new_tvars = new_tvars, $
   old_tvars = old_tvars, $
   datagap = datagap,     $  ;It looks like this keyword isn't actually used.  pcruce 10/4/2012
   get_plot_position=pos, $
   no_vtitle_shift = no_vtitle_shift, $       
   help = help

compile_opt idl2

@tplot_com.pro


if 1 then begin   ; check for embedded calls
    stack = scope_traceback(/structure)
    stack = stack[0:n_elements(stack)-2]
    nocallsfrom = ['CTIME','TPLOT']
    incommon = array_union(nocallsfrom,stack.routine)
    w = where(incommon ne -1,nw)
    if nw gt 0 then begin
        dprint,dlevel=2,'Calls to TPLOT are not allowed from within '+strupcase(nocallsfrom[w])
        return
    endif
endif


if keyword_set(names) and (arg_present(names)) eq 0 then begin
  tplot_names,datanames
  return  
endif

if size(verbose,/type) eq 0 then  str_element,tplot_vars,'options.verbose',verbose ; get default verbose value if it exists
if size(wshow,/type) eq 0 then str_element,tplot_vars,'options.wshow',wshow


if keyword_set(old_tvars) then tplot_vars = old_tvars

if keyword_set(help) then begin
    printdat,tplot_vars.options,varname='tplot_vars.options'
    new_tvars = tplot_vars
    return
endif

; setup tplot_vars....
tplot_options,title=title,var_label=var_label,refdate=refdate, wind=wind, options = opts


if keyword_set(overplot) then oplot=overplot
if n_elements(trng) eq 2 then trange = time_double(trng)

chsize = !p.charsize
if chsize eq 0. then chsize=1.

def_opts= {ymargin:[4.,2.],xmargin:[12.,12.],position:fltarr(4), $
   title:'',ytitle:'',xtitle:'', $
   xrange:dblarr(2),xstyle:1,    $
   version:3, window:-1, wshow:0,  $
   charsize:chsize,noerase:0,overplot:0,spec:0}

extract_tags,def_opts,tplot_vars.options

; Define the variables to be plotted:

;str_element,tplot_vars,'options.varnames',tplot_var
; if n_elements(tplot_var) eq 0 then $
;    str_element,tplot_vars,'options.varnames',['NULL'],/add_replace

if keyword_set(pick) then begin
   ctime,prompt='Click on desired panels. (button 3 to quit)',panel=mix,/silent
   if n_elements(mix) ne 0 then datanames = tplot_vars.settings.varnames[mix]
endif

if keyword_set(toss) then begin
   ctime,prompt='Click on panels to remove. (button 3 to quit)',panel=nix,/silent
   mix = indgen(n_elements(tplot_vars.settings.varnames))
   for i=0,(n_elements(nix)-1) do mix[nix[i]] = -1
   i = where(mix ne -1, count)
   if (count gt 0) then datanames = tplot_vars.options.varnames[mix[i]]
endif

if keyword_set(add_var)  then begin
   names = tnames(datanames,/all)
   if keyword_set(reverse) then names = reverse(names)
   if (add_var lt 0) then add_var = (n_elements(tplot_vars.options.varnames)+add_var+1) > 1
   if add_var eq 1 then datanames = [names,tplot_vars.options.varnames] else $
    if (add_var gt n_elements(tplot_vars.options.varnames)) then $
        datanames = [tplot_vars.options.varnames,names] else $
        datanames = [tplot_vars.options.varnames[0:add_var-2],names,$
           tplot_vars.options.varnames[add_var-1:*]]
endif


dt = size(/type,datanames)
ndim = size(/n_dimen,datanames)

if dt ne 0 then begin
   if dt ne 7 or ndim ge 1 then dnames = strjoin(tnames(datanames,/all),' ') $
   else dnames=datanames
endif else begin
	tpv_opt_tags = tag_names( tplot_vars.options)
	idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
	if icnt gt 0 then begin
		dnames=tplot_vars.options.datanames
	endif else begin
		return
	endelse
endelse

;if dt ne 0 then names= tnames(datanames,/all)

if keyword_set(lastvar) then str_element,tplot_vars,'settings.last_varnames',names

;if keyword_set(names) then begin
;   str_element,tplot_vars,'settings.last_varnames',tplot_vars.options.varnames,$
;       /add_replace
;   str_element,tplot_vars,'options.varnames',names,/add_replace ;  array of names
;   str_element,tplot_vars,'settings.varnames',names,/add_replace
;endif else names = tplot_vars.options.varnames

str_element,tplot_vars,'options.lazy_ytitle',lazy_ytitle

varnames = tnames(dnames,nd,ind=ind,/all)

str_element,tplot_vars,'options.datanames',dnames,/add_replace
str_element,tplot_vars,'options.varnames',varnames,/add_replace

if nd eq 0 then begin
   dprint,dlevel=0,verbose=verbose,'No valid variable names found to tplot! (use TPLOT_NAMES to display)'
   return
endif

;ind = array_union(tplot_vars.options.varnames,data_quants.name)

sizes = fltarr(nd)
for i=0,nd-1 do begin
   dum = 1.
   lim = 0
   get_data,tplot_vars.options.varnames[i],alim=lim
   str_element,lim,'panel_size',value=dum
   sizes[i] = dum
endfor

plt = {x:!x,y:!y,z:!z,p:!p}

if (!d.flags and 256) ne 0  then begin    ; windowing devices
   current_window= !d.window > 0
   if def_opts.window ge 0 then w = def_opts.window $
   else w = current_window
;test to see if this window exists before wset, jmm, 7-may-2008:
;removed upper limit on window number, jmm, 19-mar-2009
   device, window_state = wins
   if(w Eq 0 Or wins[w]) then wset,w else begin
     dprint,verbose=verbose, 'Window is closed and Unavailable, Returning'
     w = current_window
     def_opts.window = w
     tplot_options, window = w
     return
   endelse
   if def_opts.wshow ne 0 || keyword_set(wshow) then wshow ;,icon=0   ; The icon=0 option doesn't work with windows
   str_element,def_opts,'wsize',value = wsize
   wi,w,wsize=wsize
endif

str_element,tplot_vars,'settings.y',replicate(!y,nd),/add_replace
str_element,tplot_vars,'settings.clip',lonarr(6,nd),/add_replace
str_element,def_opts,'ygap',value = ygap
str_element,def_opts,'charsize',value = chsize
str_element,def_opts,'local_time',local_time

if keyword_set(nocolor) then str_element,def_opts,'nocolor',nocolor,/add_replace

nvlabs = [0.,0.,0.,1.,0.,0.,0.,0.]
str_element,tplot_vars,'options.var_label',var_label
if keyword_set(var_label) then if size(/type,var_label) eq 7 then $
    if ndimen(var_label) eq 0 then var_label=tnames(var_label) ;,/extrac)
;ensure the index does not go out of range, other values will use default
if def_opts.version lt 1 or def_opts.version gt 7 then def_opts.version = 3
nvl = n_elements(var_label) + nvlabs[def_opts.version]
def_opts.ymargin = def_opts.ymargin + [nvl,0.]

!p.multi = 0
pos = plot_positions(ysizes=sizes,options=def_opts,ygap=ygap)

if  keyword_set(trange) then str_element,tplot_vars,'options.trange',trange,/add_replace $
else  str_element,tplot_vars,'options.trange',trange
if trange[0] eq trange[1] then $
    trg=minmax(reform(data_quants[ind].trange),min_value=0.1) $
else trg = trange

tplot_var_labels,def_opts,trg,var_label,local_time,pos,chsize,vtitle=vtitle,vlab=vlab,time_offset=time_offset,time_scale=time_scale

;return time_offset in the t_offset keyword, if requested
if undefined(time_offset) then begin
  dprint,'Illegal time interval.',dlevel=1  
  return
endif

t_offset = time_offset

def_opts.xrange = (trg-time_offset)/time_scale

if keyword_set(oplot) then def_opts.noerase = 1

;for i=0,nd-1 do begin
;  polyfill,(pos[*,i])([[0,1],[2,1],[2,3],[0,3]]),color=5,/norm
;endfor

;stop

init_opts = def_opts
init_opts.xstyle = 5
;if init_opts.noerase eq 0 then erase_region,_extra=init_opts
if  init_opts.noerase eq 0 then erase
init_opts.noerase = 1
str_element,init_opts,'ystyle',5,/add
box,init_opts

def_opts.noerase = 1
str_element,tplot_vars,'options.timebar',tbnames
if keyword_set(tbnames) then begin
   tbnames = tnames(tbnames)
   ntb = n_elements(tbnames)
   for i=0,ntb-1 do begin
      t = 0
      get_data,tbnames[i],data=d
      str_element,d,'x',t
      str_element,d,'time',t
      for j=0,n_elements(t)-1 do $
         oplot,(t[j]-time_offset)/time_scale*[1,1],[0,1],linestyle=1
   endfor
endif

str_element,/add,tplot_vars,'settings.y', replicate(!y,nd)
str_element,/add,tplot_vars,'settings.clip',lonarr(6,nd)

for i=0,nd-1 do begin
   name = tplot_vars.options.varnames[i]
   def_opts.position = pos[*,i]         ;  get the correct plot position
   get_data,name,alimits=limits,ptr=pdata,data=data,index=index,dtype=dtype

   if not keyword_set(pdata) and dtype ne 3 then  dprint,verbose=verbose,'Undefined or empty variable data: ',name $
   else dprint,verbose=verbose,dlevel=1,index,name,format='(i4," ",a)'
   if keyword_set(pdata) then  nd2 = n_elements(pdata) else nd2 = 1
   if dtype eq 3 then begin
    datastr = data
    yrange = [0.,0.]
    str_element,limits,'yrange',yrange
    if ndimen(datastr) eq 0 then datastr = tnames(datastr,/all);  strsplit(datastr,/extract)
    nd2 = n_elements(datastr)
    if yrange[0] eq yrange[1] then get_ylimits,datastr,limits,trg
   endif else datastr=0

   ;allow label placing for pseudo variables
   all_labels = ''
   labflag = 0b 
   label_placement = 0 ;array to determine label positions
   labidx = 0 ;offset for indexing position array
   str_element, limits,'labflag',labflag

   if nd2 gt 1 && keyword_set(labflag) && keyword_set(datastr) then begin
     ;check for labels set on the pseudo variable, use defaults if not set
     str_element, limits,'labels',all_labels
     if ~keyword_set(all_labels) then begin
       for c=0, nd2-1 do begin
         templab = ''
         get_data, datastr[c], alimits=templim
         str_element, templim, 'labels', templab
         if keyword_set(templab) then begin
           all_labels = keyword_set(all_labels) ? [all_labels,templab]:templab
           label_placement = [label_placement,replicate(c,n_elements(templab))]
         endif
       endfor
     endif
     if n_elements(label_placement) gt 1 then begin
       label_placement = label_placement[1:n_elements(label_placement)-1]
     endif
   endif
   
   ;allow colors to be set on pseudo variables
   colors_set = 0b
   color_offset = 0
   str_element, limits, 'colors', colors_set
   for d=0,nd2-1 do begin
     newlim = def_opts
     newlim.ytitle = keyword_set(lazy_ytitle) ? strjoin(strsplit(name,'_',/extract),'!c')  : name
     if keyword_set(datastr) then begin
        name = datastr[d]
        get_data,name,index=index,data=data,alimits=limits2,dtype=dtype ;,ptr=pdata
;help,limits2,/st
;stop
        if not keyword_set(data)  then  dprint,verbose=verbose,'Unknown variable: ',name $
        else dprint,verbose=verbose,dlevel=1,index,name,format='(i3,"   ",a)'
     endif else limits2 = 0

     if size(/type,data) eq 8 then begin
        tshift = 0.d
        str_element,data,'tshift',value = tshift
        tshift=tshift[0]
;  printdat,name,tshift,limits2,dtype
        data.x = (data.x - (time_offset-tshift))/time_scale
;data.x is no longer unix time here, but is measured from the
;time_offset value
     endif  else data={x:dindgen(2),y:findgen(2)}
     extract_tags,newlim,data,      except = ['x','y','dy','v']
     extract_tags,newlim,limits2
     extract_tags,newlim,ylimits
     extract_tags,newlim,limits
;     extract_tags,newlim,def_opts
     newlim.overplot = d ne 0
     if keyword_set(overplot) then newlim.overplot = 1   ;<- *** LINE ADDED **
     if i ne (nd-1) then newlim.xtitle=''
     if i ne (nd-1) then newlim.xtickname = ' '
     
     ;add labels if set on pseudo var
     if keyword_set(all_labels) then begin
       ;labels not set on pseudo var, placement determined earlier
       if keyword_set(label_placement) then begin
         label_index = where(label_placement eq d, nl)
         if nl lt 1 then label_index = -1
       ;labels explicitly set on pseudo var, add labels in order
       endif else begin
         label_index = indgen(dimen2(data.y)) + labidx
         labidx = max(label_index) + 1
       endelse
       ;add aggregated labels/indexes for current variable
       str_element, newlim, 'label_index', label_index, /add
       str_element, newlim, 'all_labels', all_labels, /add
     endif 

     ;set offset into color array, if plotting pseudo vars this should
     ;allow the next variable's trace to start at the proper color
     if keyword_set(colors_set) then begin
       str_element, newlim, 'color_offset', color_offset, /add
     endif
     
     ysubtitle = struct_value(newlim,'ysubtitle',def='')
     if keyword_set(ysubtitle) then newlim.ytitle += '!c'+ysubtitle
     if newlim.spec ne 0 then routine='specplot' else routine='mplot'
;     if size(/type,data.y
     str_element,newlim,'tplot_routine',value=routine
     color_table= struct_value(newlim,'color_table',default=-1) & pct=-1
     rev_color_table= struct_value(newlim,'reverse_color_table',default=0) & prev=0
     lcolors= struct_value(newlim,'line_colors',default=-1) & pline=-1
;modified by dmitchell include CSV color tables (indices >= 1000) and to remember reversed tables
     if (color_table ge 0) then initct,color_table,previous_ct=pct,reverse=rev_color_table,previous_rev=prev
     if (lcolors[0] ne -1) then line_colors,lcolors,previous_lines=pline
;if debug() then stop
     call_procedure,routine,data=data,limits=newlim
;Allow fill of time interval with different background color, or other
;polyfill options, given by fill_time_intv structure, jmm, 2019-11-04
     str_element, newlim, 'fill_time_intv', success = fill_intv
     if fill_intv eq 1 then tplot_fill_time_intv, routine, data, newlim, time_offset

     if (color_table ne pct || rev_color_table ne prev) then initct,pct,rev=prev
     if (max(abs(lcolors - pline)) gt 0) then line_colors,pline

     ;get offset into color array (for pseudo vars)
     if keyword_set(colors_set) then begin
       str_element, newlim, 'color_offset', value=color_offset
     endif

   endfor
   def_opts.noerase = 1
   def_opts.title  = ''
   tplot_vars.settings.y[i]=!y
   tplot_vars.settings.clip[*,i] = !p.clip
endfor

str_element,tplot_vars,'settings.varnames',varnames,/add_replace
str_element,tplot_vars,'settings.d',!d,/add_replace
str_element,tplot_vars,'settings.p',!p,/add_replace
str_element,tplot_vars,'settings.x',!x,/add_replace
str_element,tplot_vars,'settings.trange_cur',(!x.range * time_scale) + time_offset

;option to control left-hand labels for x-axis
str_element, def_opts, 'vtitle', vtitle
if keyword_set(vtitle) then begin                 ; finish var_labels
  str_element,def_opts,'charthick',value=charthick
  xspace = chsize * !d.x_ch_size / !d.x_size
  yspace = chsize * !d.y_ch_size / !d.y_size
  xpos = pos[0,nd-1] - (def_opts.xmargin[0]-1) * xspace
; bugfix on 11/7/2018 by egrimes; increased the yposition slightly for
; time ranges < 5 seconds to prevent overlaps
; updated on 2/7/2022 to 10 minutes (the issue occurs for small time
; ranges, including many above 5 seconds)
  str_element,def_opts,'no_vtitle_shift',opt_no_vtitle_shift
  if(~keyword_set(no_vtitle_shift) and ~keyword_set(opt_no_vtitle_shift)) then begin
     if trg[1]-trg[0] le 60.*10 then ypos = pos[1,nd-1] - 2.5 * yspace else ypos = pos[1,nd-1] - 1.5 * yspace
  endif else ypos = pos[1,nd-1] - 1.5 * yspace
  xyouts,xpos,ypos,vtitle,/norm,charsize=chsize,charthick=charthick
endif


time_stamp,charsize = chsize*.5

if (!d.flags and 256) ne 0  then begin    ; windowing devices
  str_element,tplot_vars,'settings.window',!d.window,/add_replace
  if def_opts.window ge 0 then wset,current_window
endif

!x = plt.x
!y = plt.y
!z = plt.z
!p = plt.p


str_element,tplot_vars,'settings.time_scale',time_scale,/add_replace
str_element,tplot_vars,'settings.time_offset',time_offset,/add_replace
new_tvars = tplot_vars
return
end

