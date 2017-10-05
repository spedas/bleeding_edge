;$Id: cube__define.pro 19798 2016-01-23 00:10:28Z jwl $
;+
; Definition of geometry of a cube.
;
; @abstract
; @keyword x {out}{optional}{type=numeric vector} x coordinates of vertices
; @keyword y {out}{optional}{type=numeric vector} y coordinates of vertices
; @keyword z {out}{optional}{type=numeric vector} z coordinates of vertices
; @keyword polygon_conn {out}{optional}{type=numeric vector} connectivity
;          array for the polygon
;-
pro cube::getdefinition, x=x, y=y, z=z, polygon_conn=polygon_conn
    compile_opt idl2

    x = [-1, -1, +1, +1, -1, -1, +1, +1] / 2.0
    y = [-1, -1, -1, -1, +1, +1, +1, +1] / 2.0
    z = [-1, +1, +1, -1, -1, +1, +1, -1] / 2.0
    polygon_conn = $
        [5, 0, 1, 2, 3, 0, $
         5, 4, 5, 6, 7, 4, $
         5, 1, 5, 6, 2, 1, $
         5, 2, 6, 7, 3, 2, $
         5, 3, 7, 4, 0, 3, $
         5, 0, 4, 5, 1, 0]
end


;+
; Define instance variables.
;
; @file_comments Class representing a cube.
; @author Michael Galloy
; @history
; <ul>
; <li>Created August 1, 2003
; <li>2006-06, MP: Removed POLYLINE_CONN keyword from getDefinition
;     method.
; </ul>
;-
pro cube__define
    compile_opt idl2

    define = { cube, inherits polyhedron }
end
