;+
; psp_fld_popen
;
; :Purpose:
;   Wrapper for the SPEDAS 'popen' function, used to set default
;   parameters used by PSP/FIELDS plot routines for encapsulated
;   PostScript output.
;
;   See the corresponding 'psp_fld_pclose' function for closing the plot
;   and converting to PDF/PNG format.
;
; :Arguments:
;   n: in, required, string
;     The name of the PostScript file to open. Do not include
;     the extension.
;
; :Keywords:
;   _extra: in, optional, any
;     Parameters to pass to the 'popen' function.
;   thick: in, optional, any
;     Line thickness for the plot. Line, axis, and text thickness are
;     set to the same value.
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-07-24 13:40:33 -0700 (Thu, 24 Jul 2025) $
; $LastChangedRevision: 33495 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_popen.pro $
;
;-

pro psp_fld_popen, n, _extra = extra, $
  thick = thick
  compile_opt idl2

  if n_elements(thick) eq 0 then thick = 3
  if n_elements(font) eq 0 then font = -1
  if n_elements(xsize) eq 0 then xsize = 10
  if n_elements(ysize) eq 0 then ysize = 7.5

  popen, n, font = font, encapsulated = 1, $
    xsize = xsize, ysize = ysize, _extra = extra

  !p.charthick = thick
  !p.thick = thick
  !x.thick = thick
  !y.thick = thick
  !z.thick = thick
end
