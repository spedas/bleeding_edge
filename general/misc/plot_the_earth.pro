;+
; :PURPOSE:
;    Create an Earth graphic.
;
; :INPUT:
;    X - position x
;    Y - position y
;    R - radius
;    Direction - direction of the sun in RAD 
;    LineColor - color of the line 
;    FillColor - color of the background
;    RenderNum - number of defined vertex in earth half view
;   
;    Example: default plot the earth
;      PLOT_THE_EARTH, 0, 0, 1, 0, 'k', 'black', 16
;      
; AUTHOR:
;   Alexander Drozdov
;
; VERSION:
;  $LastChangedBy: adrozdov $
;  $LastChangedDate: 2017-10-25 12:57:57 -0700 (Wed, 25 Oct 2017) $
;  $LastChangedRevision: 24214 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/plot_the_earth.pro $

;-
PRO PLOT_THE_EARTH, X, Y, R, Direction, LineColor, FillColor, RenderNum, MPAUSE=MPAUSE
; create nodes
al = [0:!pi:!pi/RenderNum] + Direction
ex = R*sin(al)
ey = R*cos(al)

; plot
E = ELLIPSE(X,Y, '-'+LineColor, /DATA, MAJOR=R, MINOR=R, FILL_BACKGROUND=0)
P = POLYGON(X + ex,Y + ey, '-'+LineColor, /DATA, FILL_BACKGROUND=1, FILL_COLOR=FillColor)

IF KEYWORD_SET(MPAUSE) THEN BEGIN
  spd_mpause,xmp,ymp
  M = PLOT(xmp,ymp,/OVERPLOT)
ENDIF

END