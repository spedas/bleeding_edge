;+
; NAME:
;     crib_tplot_greek_letters
;
; PURPOSE:
;     Demonstrates how to use IDL text-formatting escape sequences for
;     Greek letters in tplot component labels (legends) and axis titles.
;
; NOTES:
;     The !X escape returns text to the default font.  Existing SPEDAS
;     loaders use these same escapes in ytitles, for example !4h!X for
;     theta, !4u!X for phi, and !4l!X for micro-style labels.
;
;     These are IDL direct-graphics text/font escapes used by existing
;     SPEDAS labels.  Exact glyph appearance can depend on the active
;     graphics device/font and IDL runtime.
;
;     To run from IDL:
;       .compile crib_tplot_greek_letters
;       crib_tplot_greek_letters
;
;     Type ".c" at each stop to continue through the examples.
;
; SEE ALSO:
;     crib_tplot, crib_tplot_annotation, crib_tplot_panel_labels
;
; $LastChangedBy$
; $LastChangedDate$
; $LastChangedRevision$
; $URL$
;-

pro crib_tplot_greek_letters

  ; Make this crib self-contained.
  store_data, '*', /delete

  npts = 64L
  times = time_double('2020-01-01/00:00') + dindgen(npts)*60D
  phase = findgen(npts)/10.0

  y = fltarr(npts, 3)
  y[*, 0] = sin(phase)
  y[*, 1] = cos(phase)
  y[*, 2] = 0.5*sin(phase + 0.8)

  store_data, 'greek_label_demo', data={x: times, y: y}

  ;---------------------------------------------------------------------
  ; Greek letters in tplot component labels
  ;---------------------------------------------------------------------
  print, 'Example 1: use the labels option to put Greek letters in tplot labels.'
  print, '           labflag controls where the labels are drawn.'

  options, 'greek_label_demo', labels=['!4h!X component', '!4u!X component', '!4l!X component']
  options, 'greek_label_demo', colors='bgr', labflag=-1
  options, 'greek_label_demo', ytitle='Greek labels'
  options, 'greek_label_demo', ysubtitle='demo'

  tplot, 'greek_label_demo'

  print, 'Type ''.c'' to continue to the title/subtitle example.'
  stop

  ;---------------------------------------------------------------------
  ; Greek letters in titles and subtitles
  ;---------------------------------------------------------------------
  print, 'Example 2: the same IDL text escapes can be used in tplot titles.'
  print, '           !4h!X renders theta, !4u!X renders phi, and !4l!X renders micro.'

  options, 'greek_label_demo', ytitle='Angles !4h!X and !4u!X'
  options, 'greek_label_demo', ysubtitle='!4l!XV example'
  options, 'greek_label_demo', labflag=-1

  tplot, 'greek_label_demo'

  print, 'Type ''.c'' to continue to the reference table.'
  stop

  ;---------------------------------------------------------------------
  ; Compact reference table for common SPEDAS/IDL text escapes
  ;---------------------------------------------------------------------
  print, 'Common IDL direct-graphics escapes useful in tplot text:'
  print, '  These escapes are used by existing SPEDAS labels; exact glyphs can'
  print, '  depend on the active graphics device/font and IDL runtime.'
  print, '  !4h!X    theta, as used by existing SPEDAS Wind theta labels'
  print, '  !4u!X    phi, as used by existing SPEDAS Wind phi labels'
  print, '  !9Q!X    theta-like symbol font label used by Wind plasma moments'
  print, '  !9F!X    phi-like symbol font label used by Wind plasma moments'
  print, '  !4l!X    micro/mu-style escape used by SPEDAS time tick labels'
  print, '  !U...!N  superscript, for example cm!U-3!N'
  print, '  !D...!N  subscript'
  print, '  !C       line break in tplot titles/subtitles'

  print, 'Done with crib_tplot_greek_letters.'

end
