;+
;NAME:
;tplot_fill_time_intv
;PURPOSE:
;Allow different background color, or other polyfill options for time
;intervals for a tplot variable. Called only from tplot.pro, Do not
;use this in any other environment
;CALLING SEQUENCE:
;tplot_fill_time_intv, routine, data, newlim
;INPUT:
;routine - thie is the plot routine for a given tplot variable,
;          typically 'mplot' or 'specplot' or 'bitplot'
;data - the data structure for the input variable
;newlim - the limits structure, this must contain a tag
;         'fill_time_intv' = {time:interval_times, color:color values}
;         The time intervals can be an array of 2, or 2Xntimes, color
;         values can be scalar, or an array of ntimes. Other polyfill
;         options, such as line_fill, orientation, thick, can be input
;         in the fill_time_intv structure,
;time_offset - the plot start time needed for the correct position 
;EXAMPLES:
; (see also crib_fill_time_intv.pro in spdsw/general/examples)
;
;a solid background color, using options, for the variable 'sta_SWEA_mom_flux'
;options, 'sta_SWEA_mom_flux', 'fill_time_intv', $
;         {time:['2008-03-23/02:00','2008-03-23/04:00'], color:2}
;
;different intervals with different colors, using options, for the flux variable
;2Xn_times intervals
;t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
;c1 = 'rgb' ;you can use string color values in addition to absolute numbers 

;options, 'sta_SWEA_mom_flux', 'fill_time_intv', {time:t1, color:c1}
;
;set line_fill:1,orientation:45 to use angled 
;parallel lines and not solid colors
;2Xn_times intervals
;t1 = '2008-03-23/'+[['02:00','04:00'],['07:00','09:00'],['16:24','22:00']]
;c1 = [4,6,2]
;
;options, 'sta_SWEA_mom_flux', 'fill_time_intv', 
;          {time:t1, color:c1, line_fill:1, orientation:45.0}
;See crib sheet for more options
;
;HISTORY:
; 2019-11-04, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-03-23 13:23:01 -0700 (Thu, 23 Mar 2023) $
; $LastChangedRevision: 31653 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_fill_time_intv.pro $
;-
Pro tplot_fill_time_intv, routine, data, newlim, time_offset

  If(~is_struct(newlim)) Then Begin
     dprint, 'No limits structure'
     Return
  Endif

;two times and a color value, or two X n times and n colors also
;line_fill, orientation, and thick options,
  If(tag_exist(newlim,'fill_time_intv')) Then Begin
     t_rct = time_double(newlim.fill_time_intv.time)-time_offset
     n_intv = n_elements(t_rct[0, *])
     If(tag_exist(newlim.fill_time_intv, 'color')) Then Begin
        c_intv0 = get_colors(newlim.fill_time_intv.color)
        nc = n_elements(c_intv0)
        If(nc Ne n_intv) Then Begin
           c_intv = replicate(c_intv0[0], n_intv)
        Endif Else c_intv = c_intv0
     Endif Else c_intv = lonarr(n_intv)
     If(tag_exist(newlim.fill_time_intv, 'line_fill')) Then Begin
        lf_intv0 = get_colors(newlim.fill_time_intv.line_fill)
        nlf = n_elements(lf_intv0)
        If(nlf Ne n_intv) Then Begin
           lf_intv = replicate(lf_intv0[0], n_intv)
        Endif Else lf_intv = lf_intv0
     Endif Else lf_intv = lonarr(n_intv)
     If(tag_exist(newlim.fill_time_intv, 'linestyle')) Then Begin
        ls_intv0 = get_colors(newlim.fill_time_intv.linestyle)
        nls = n_elements(ls_intv0)
        If(nls Ne n_intv) Then Begin
           ls_intv = replicate(ls_intv0[0], n_intv)
        Endif Else ls_intv = ls_intv0
     Endif Else ls_intv = lonarr(n_intv)
     If(tag_exist(newlim.fill_time_intv, 'thick')) Then Begin
        lt_intv0 = get_colors(newlim.fill_time_intv.thick)
        nlt = n_elements(lt_intv0)
        If(nlt Ne n_intv) Then Begin
           lt_intv = replicate(lt_intv0[0], n_intv)
        Endif Else lt_intv = lt_intv0
     Endif Else lt_intv = lonarr(n_intv)
     If(tag_exist(newlim.fill_time_intv, 'orientation')) Then Begin
        lo_intv0 = get_colors(newlim.fill_time_intv.orientation)
        nlo = n_elements(lo_intv0)
        If(nlo Ne n_intv) Then Begin
           lo_intv = replicate(lo_intv0[0], n_intv)
        Endif Else lo_intv = lo_intv0
     Endif Else lo_intv = lonarr(n_intv)
     For j = 0, n_intv-1 Do Begin
        x_rct = [t_rct[0,j], t_rct[1,j], $
                 t_rct[1,j], t_rct[0,j]]
        x_rct = x_rct > !cxmin ;assure that limits are within plot limits, jmm, 2023-03-23
        x_rct = x_rct < !cxmax
        If(tag_exist(newlim, 'ylog') && newlim.ylog Eq 1) Then Begin
           y_rct = 10.0^[!cymin, !cymin, !cymax, !cymax]
        Endif Else y_rct = [!cymin, !cymin, !cymax, !cymax]
        If(lf_intv[j] Eq 0) Then Begin
           polyfill, x_rct, y_rct, color = c_intv[j]
        Endif Else Begin
           polyfill, x_rct, y_rct, color = c_intv[j], line_fill = lf_intv[j], $
                     linestyle = ls_intv[j], thick = lt_intv[j], orientation = lo_intv[j]
        Endelse 
     Endfor
;replot after polyfill, if not specplot
     If(routine Ne 'specplot') Then call_procedure,routine,data=data,limits=newlim
  Endif

End
