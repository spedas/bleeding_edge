;+
; :Description:
;    Create an Earth graphic.
;
; :Params:
;    X - position x
;    Y - position y
;    R - radius
;    Direction - direction of the sun in RAD 
;    LineColor - color of the line 
;    FillColor - color of the background
;    RenderNum - number of defined vertex in earth half view
;
; :Keywords:
;    ELLIPSE
;    POLYGON
;    
;    Example: default plot the earth
;      PLOT_THE_EARTH, 0, 0, 1, 0, 'k', 'black', 16
;-
PRO PLOT_THE_EARTH, X, Y, R, Direction, LineColor, FillColor, RenderNum
; create nodes
al = [0:!pi:!pi/RenderNum] + Direction
ex = R*sin(al)
ey = R*cos(al)

; plot
E = ELLIPSE(X,Y, '-'+LineColor, /DATA, MAJOR=R, MINOR=R, FILL_BACKGROUND=0)
P = POLYGON(X + ex,Y + ey, '-'+LineColor, /DATA, FILL_BACKGROUND=1, FILL_COLOR=FillColor)


END