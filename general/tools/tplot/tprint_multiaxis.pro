;+
;NAME:
; tprint_multiaxis
;PURPOSE:
; A PostScript wrapper for tplot_multiaxis, opens .ps file, calls
; tplot_multiaxis, closes file and prints or calls "xv". The printer
; or view options are only applied on Unix-based systems, but the file
; will be created for any OS.
;CALLING SEQUENCE:
; tprint_multiaxis, left_names, right_names [,positions], filename=filename, $
;                   printer=printer,times=times,ct=ct,landscape=landscape, $
;                   xsize=xsize,ysize=ysize,_extra=_extra
;INPUT:
;  left_names:  String array or space separated list of tplot variables.
;               Each variable will be plotted in a separate panel with a
;               left-aligned y axis.
;  right_names:  String array or space separate list of tplot variables.
;                Each variable will be added to the appropriate panel
;                with a right-aligned y axis.  If positions are not 
;                specified then this must be the same size as left_names.
;  positions:  Integer array specifying the vertical position [1,N] of 
;              the correspond entry in right_names.  This keyword must
;              be used if left_names has more entries than
;              right_names.
;KEYWORDS:
;  no_zoffset: If set, then the color scale is Not moved off the
;              screen. (See tplot_multiaxis_kludge.pro for details)
;  filename:  An output filename, the default is 'tplot_multiaxis'
;  printer: A printer name (example 'chp360'), If not set, then output
;           is displayed via "xv", if it is a valid command.
;  times: if set, will apply timebars at certain times. Note that
;         tplot_apply_timebar and tplot_apply_databar are also called
;         by default, so if these timbars are aplied for all panels in
;         addition to any variable-specific timebars.
;  ct: Color table; the default is to use whatever is already
;      loaded. Note that the color table is not reset post-plot
;  landscape, xsize, ysize: passed through to popen
;  _extra:  Keywords to tplot can also be used here.
;HISTORY: Hacked from 'tprint.pro', 2022-08-22, jmm,
;         jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-08-22 14:21:36 -0700 (Mon, 22 Aug 2022) $
; $LastChangedRevision: 31031 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/tplot/tprint_multiaxis.pro $
;-
Pro tprint_multiaxis, left_names, right_names, positions, $
                      no_zoffset = no_zoffset, filename = filename, $
                      printer = printer, times = times, ct = ct, $
                      landscape = landscape, xsize = xsize, ysize = ysize, $
                      _extra = _extra
  If(~keyword_set(filename)) Then filename = 'tplot_multiaxis'
  popen, filename, landscape = landscape, xsize = xsize, ysize = ysize
  If(n_elements(ct) Ne 0) Then loadct2, ct
  tplot_multiaxis, left_names, right_names, positions, $
                   no_zoffset = no_zoffset, _extra = _extra
  tplot_apply_timebar & tplot_apply_databar
  If(keyword_set(times)) Then timebar, times
  pclose
;if n_elements(printer) eq 0 then printer='ctek0'
  If(!version.os_family eq 'unix') Then Begin
     If(keyword_set(printer)) Then $
        spawn,'lpr -P'+printer+' '+filename+".ps" $
     Else spawn,'xv '+filename+'.ps &'
  Endif
End
