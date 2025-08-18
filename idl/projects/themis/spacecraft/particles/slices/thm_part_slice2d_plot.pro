
;+
;Procedure:
;  thm_part_slice2d_plot
;
;Purpose:
;  Create plots for 2D particle slices.
;  This routine calls the general spd_slice2d_plot routine.
;  Use thm_part_slice2d_plot_old if calling thm_part_slice2d_old.
;
;Calling Sequence:
;  thm_part_slice2d_plot, slice
;
;Arguments:
;  SLICE: 2D array of values to plot 
;
;Plotting Keywords:
;  LEVELS: Number of color contour levels to plot (default is 60)
;  OLINES: Number of contour lines to plot (default is 0)
;  ZLOG: Boolean indicating logarithmic countour scaling (on by default)
;  ECIRCLE: Boolean to plot circle(s) designating min/max energy 
;           from distribution (on by default)
;  SUNDIR: Boolean to plot the projection of scaled sun direction (black line).
;          Requires GET_SUN_DIRECTION set with thm_part_dist_array. 
;  PLOTAXES: Boolean to plot x=0 and y=0 axes (on by default)
;  PLOTBULK: Boolean to plot projection of bulk velocity vector (red line).
;            (on by default)
;  PLOTBFIELD: Boolean to plot projection of scaled B field (cyan line).
;              Requires B field data to be loaded and specified to
;              thm_part_slice2d with mag_data keyword.
;            
;  CLABELS: Boolean to annotate contour lines.
;  CHARSIZE: Specifies character size of annotations (1 is normal)
;  TITLE: String specifying the title of the plot.
;  [XYZ]RANGE: Two-element array specifying x/y/z axis range.
;  [XYZ]TICKS: Integer(s) specifying the number of ticks for each axis 
;  [XYZ]PRECISION: Integer specifying annotation precision (sig. figs.).
;                  Set to zero to truncate printed values to inegers.
;  [XYZ]STYLE: Integer specifying annotation style:
;             Set to 0 (default) for style to be chosen automatically. 
;             Set to 1 for decimal annotations only ('0.0123') 
;             Set to 2 for scientific notation only ('1.23e-2')
;  [B,V,SUN]_COLOR: Specify the color of the corresponding support vector.
;                   (e.g. "b_color=0", see IDL graphics documentation for options)
;
;  WINDOW:  Index of plotting window to be used.
;  PLOTSIZE: The size of the plot in device units (usually pixels)
;            (Not implemented for postscript).
;
;Exporting keywords:
;  EXPORT: String designating the path and file name of the desired file. 
;          The plot will be exported to a PNG image by default.
;  EPS: Boolean indicating that the plot should be exported to 
;       encapsulated postscript.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-24 16:48:06 -0700 (Thu, 24 Mar 2016) $
;$LastChangedRevision: 20586 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice2d_plot.pro $
;
;-

pro thm_part_slice2d_plot, slice, $
                     ; Dummy vars to conserve backwards compatibility 
                     ; (should allow oldscripts to be run withouth issue)
                       xgrid, ygrid, slice_info, range=range, $
                     ; Range options
                       xrange=xrange, yrange=yrange, zrange=zrange, $
                     ; Basic plotting options
                       title=title, ztitle=ztitle, $ 
                       xtitle=xtitle, ytitle=ytitle, $
                       xticks=x_ticks, yticks=y_ticks, zticks=z_ticks, $
                       xminor=x_minor, yminor=y_minor, $
                       charsize=charsize_in, plotsize=plotsize, $
                       zlog=zlog, $
                       window=window, $
                     ; Annotations 
                       xstyle=xstyle, xprecision=xprecision, $
                       ystyle=ystyle, yprecision=yprecision, $
                       zstyle=zstyle, zprecision=zprecision, $
                     ; Contours
                       olines=olines, levels=levels, nlines=nlines, clabels=clabels, $
                     ; Other plotting options
                       plotaxes=plotaxes, ecircle=ecircle, sundir=sundir, $ 
                       plotbulk=plotbulk, plotbfield=plotbfield, $
                     ; Eport
                       export=export, eps=eps, $
                       _extra=_extra

    compile_opt idl2


;backward compatibility, just in case
if n_elements(range) eq 2 and undefined(zrange) then begin
  zrange = range ;maintain backwards compatability
endif

spd_slice2d_plot, slice, $
               ; Range options
                 xrange=xrange, yrange=yrange, zrange=zrange, $
               ; Basic plotting options
                 title=title, ztitle=ztitle, $ 
                 xtitle=xtitle, ytitle=ytitle, $
                 xticks=x_ticks, yticks=y_ticks, zticks=z_ticks, $
                 xminor=x_minor, yminor=y_minor, $
                 charsize=charsize_in, plotsize=plotsize, $
                 zlog=zlog, $
                 window=window, $
               ; Annotations 
                 xstyle=xstyle, xprecision=xprecision, $
                 ystyle=ystyle, yprecision=yprecision, $
                 zstyle=zstyle, zprecision=zprecision, $
               ; Contours
                 olines=olines, levels=levels, nlines=nlines, clabels=clabels, $
               ; Other plotting options
                 plotaxes=plotaxes, ecircle=ecircle, sundir=sundir, $ 
                 plotbulk=plotbulk, plotbfield=plotbfield, $
               ; Eport
                 export=export, eps=eps, $
                 _extra=_extra


end