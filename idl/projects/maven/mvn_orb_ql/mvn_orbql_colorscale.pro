function mvn_orbql_colorscale, data,            $
                     MINCOL = mincol, $
                     MAXCOL = maxcol, $
                     MINDAT = mindat, $
                     MAXDAT = maxdat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_colorscale.pro                                                        ;
;                                                                       ;
; Routine takes input data set and transforms it to output image for    ;
;  color display.                                                       ;
;                                                                       ;
; Notes:                                                                ;
;       Different from BYTSCL() in MINCOL keyword, and result is not    ;
;        expressed in bytes                                             ;
;       Defaults to linear color scaling from 0 to 255                  ;
;       Defaults to color scale stretches over all data.                ;
;       Keywords can change used color indeces, and bounds for data     ;
;       Data outside of bounds is set equal to maxdat or mindat         ;
;       To "reverse" color table set MAXCOL < MINCOL                    ;
;                                                                       ;
; Passed Variables                                                      ;
;       data            -   Input matrix of data                        ;
;       MINCOL          -   keyword: Index of lowest color to use       ;
;                                     Assumed to be 0                   ;
;       MAXCOL          -   keyword: Index of highest color to use      ;
;                                     Assumed to be 255                 ;
;       MINDAT          -   keyword: Lowest data value to consider      ;
;                                     when applying color transform     ;
;       MAXDAT          -   keyword: Highest data value to consider     ;
;                                     when applying color transform     ;
;                                                                       ;
; Written by:      David Brain                                          ;
; Last Modified:   July 11, 2000   (Dave Brain)                         ;
;                     Thesis Research Version (Now a function)          ;
;                  Mar 05, 1999    (Dave Brain)                         ;
;                     Initial Revision (formerly colortransform.pro)    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF n_elements(mincol) EQ 0 THEN mincol = 0
IF n_elements(maxcol) EQ 0 THEN maxcol = 255
IF n_elements(mindat) EQ 0 THEN mindat = min(data,/nan)
IF n_elements(maxdat) EQ 0 THEN maxdat = max(data,/nan)

colrange = maxcol - mincol
datrange = maxdat - mindat

lodata = where(data LT mindat, locount)
hidata = where(data GT maxdat, hicount)

dat = data                                      ; Copy data

IF locount NE 0 THEN dat[lodata] = mindat
IF hicount NE 0 THEN dat[hidata] = maxdat

RETURN, (dat - mindat) * colrange/float(datrange) + mincol

end
