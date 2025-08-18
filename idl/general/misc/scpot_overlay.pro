;+
;NAME:
; scpot_overlay
;PURPOSE:
; Overlays a spacecraft potential (or similar line function) over a
; spectrogram
;CALLING SEQUENCE:
;  cvar = scpot_overlay(pvar, svar)
;INPUT:
; pvar = a tplot variable containing the spacecraft potential
; svar = a tplot variable containing a spectrogram
;OUTPUT:
; cvar = a compound tplot variable name containing the combined spectrum
;        variable with the SC pot overlaid.
;KEYWORDS:
; sc_line_color = if set, use this color for SCPOT
; sc_line_thick = if set, use this line thickness for SCPOT
; sc_line_style = if set, use this line_style for SCPOT
; scale_scpot = if set, then scale the scpot to the max and min of the
;              spectrogram y-range
; use_yrange = if set, scale using the yrange range for the
;              spectrogram, if not set, use min and max of data.v.
; zero_line = if set, add a line for zero potential
; suffix = suffix for output variable
;HISTORY:
; 3-sep-2013, jmm, jimm@ssl.berkeley.edu
; 29-jan-2016, jmm, must have lost the suffix keyword, replaced it.
;$LastChangedBy: jimm $
;$LastChangedDate: 2016-01-29 11:44:34 -0800 (Fri, 29 Jan 2016) $
;$LastChangedRevision: 19841 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/scpot_overlay.pro $
;-
Function scpot_overlay, pvar, svar, $
                        sc_line_color = sc_line_color, $
                        sc_line_thick = sc_line_thick, $
                        sc_line_style = sc_line_style, $
                        scale_scpot = scale_scpot, $
                        use_yrange = use_yrange, $
                        zero_line = zero_line, $
                        suffix = suffix, $
                        _extra=_extra


otp = ''
pv0 = tnames(pvar)
If(is_string(pv0) Eq 0) Then Begin
    dprint, 'No Variable: '+pvar
    Return, otp
Endif

sv0 = tnames(svar)
If(is_string(sv0) Eq 0) Then Begin
    dprint, 'No Variable: '+svar
    Return, otp
Endif

;CLone the variables
get_data, pv0, data = pd, dlimits = pdl
If(Keyword_set(suffix)) Then sfx = suffix Else sfx = ''
pv1 = 'SCPOT4_'+sv0+sfx

get_data, sv0, data = d, dlimits = dl, limits = al

;The pv data needs scaling, and also another component with a line for
;zero, since it can be negative.
If(tag_exist(d, 'v') Eq 0) Then Begin
    dprint, 'No V variable in data structure for: '+sv0
    Return, otp
Endif

;scaling will depend on whether the spec variable is scales linearly or
;log, YLOG seems to be in the limits structure
If(tag_exist(al, 'ylog', /quiet) && al.ylog Eq 1) Then slog = 1 Else slog = 0
If(keyword_set(use_yrange)) Then Begin
    If(tag_exist(al, 'yrange', /quiet)) Then v0 = min(al.yrange, max = v1)
Endif Else Begin                ;careful for log purposes
    If(slog Eq 0) Then v0 = min(d.v, max = v1) $
    Else v0 = min(d.v[where(d.v Ne 0)], max = v1)
Endelse

If(keyword_set(scale_scpot)) Then Begin
    y = pd.y
    y0 = min(y, max = y1)
    If(slog Eq 0) Then Begin
        a = (v1-v0)/(y1-y0)
        b = v1-a*y1
        yy = a*y+b
    Endif Else Begin
        v1x = alog10(v1) & v0x = alog10(v0)
        a = (v1x-v0x)/(y1-y0)
        b = v1x-a*y1
        yy = 10^(a*y+b)
    Endelse
    If(keyword_set(zero_line)) Then Begin
        zero_l = yy
        If(slog Eq 0) Then zero_l[*] = b $
        Else zero_l[*] = 10.0^b
        yy = transpose([transpose(yy), transpose(zero_l)])
    Endif
    store_data, pv1, data = {x:pd.x, y:yy}
;Set the yrange explicitly here
    ok_yy = where(yy Ne 0, nok_yy)
    If(nok_yy Gt 0) Then Begin
        yr0 = min([v0,v1,yy[ok_yy]], max = yr1)
    Endif Else Begin
        yr0 = min([v0,v1], max = yr1)
    Endelse
Endif Else Begin
    store_data, pv1, data = {x:pd.x, y:pd.y}
    yr0 = min([v0,v1], max = yr1)
Endelse


;Set some options
If(keyword_set(sc_line_color)) Then options, pv1, 'color', sc_line_color
If(keyword_set(sc_line_thick)) Then options, pv1, 'thick', sc_line_thick
If(keyword_set(sc_line_style)) Then options, pv1, 'linestyle', sc_line_style

;Create the compound variable
otp = sv0+'_SCPOT'+sfx
store_data, otp, data = [sv0, pv1]
options, otp, 'yrange', [yr0, yr1]

Return, otp

End







