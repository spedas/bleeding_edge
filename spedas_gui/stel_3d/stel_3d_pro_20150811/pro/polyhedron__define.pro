;$Id: polyhedron__define.pro 19798 2016-01-23 00:10:28Z jwl $
;+
; Implement this method in a concrete subclass.
;
; @abstract
; @keyword x {out}{optional}{type=numeric vector} x coordinates of vertices
; @keyword y {out}{optional}{type=numeric vector} y coordinates of vertices
; @keyword z {out}{optional}{type=numeric vector} z coordinates of vertices
; @keyword polygon_conn {out}{optional}{type=numeric vector} Connectivity
;  array for the polygon
;-
pro polyhedron::getdefinition, x=x, y=y, z=z, polygon_conn=polygon_conn
    compile_opt idl2

end

;+
; Set properties of the polyhedron.
;
; @keyword outline {in}{optional}{type=boolean} Whether the polyhedron is
;  filled or an outline
; @keyword _extra {in}{optional}{type=keywords} Keywords of IDLgrPolygon
;-
pro polyhedron::setproperty, outline=outline, _extra=e
    compile_opt idl2

    self->idlgrpolygon::setproperty, _extra=e

    ;; IDLgrPolygon style=1 - outline, style=2 - filled
    if (n_elements(outline) ne 0) then begin
        self.outline = keyword_set(outline)
        self->idlgrpolygon::setproperty, style=(2-self.outline)
    endif
end

;+
; Get properties of the polyhedron.
;
; @keyword outline {out}{optional}{type=boolean} Whether the polyhedron is
;  filled or an outline
; @keyword _ref_extra {out}{optional}{type=keywords} Keywords of IDLgrPolygon.
;-
pro polyhedron::getproperty, outline=outline, _ref_extra=e
    compile_opt idl2

    self->idlgrpolygon::getproperty, _extra=e
    outline = self.outline
end


;+
; Build the polyhedron's vertices and connectivity array.
;-
pro polyhedron::buildpolygons, pos=pos, scale=scale, _extra=e
    compile_opt idl2

    self->getdefinition, x=x, y=y, z=z, polygon_conn=polygon_conn

    x *= scale
    y *= scale
    z *= scale

    x += pos[0]
    y += pos[1]
    z += pos[2]

    self->idlgrpolygon::setproperty, $
       data=transpose([[x], [y], [z]]), $
       polygons=polygon_conn, _extra=e
end

;+
; Free resources.
;-
pro polyhedron::cleanup
    compile_opt idl2

    self->idlgrpolygon::cleanup
end

;+
; @keyword pos {in}{optional}{type=3-element numeric}{default=[0.0, 0.0, 0.0]}
;  The position of the center of the cube.
; @keyword scale {in}{optional}{type=numeric}{default=1.0} Scale the
;  size of the polygon.
; @keyword outline {in}{optional}{type=boolean} Set to create an outline of a
;  polygon. Default is filled.
; @keyword _extra {in}{optional}{type=keywords} Keywords to IDLgrPolygon.
;-
function polyhedron::init, pos=pos, scale=scale, outline=outline, _extra=e
    compile_opt idl2

    if self->idlgrpolygon::init(_extra=e) eq 0 then return, 0

    self.outline = keyword_set(outline)
    if self.outline then self->setproperty, style=1

    self->buildpolygons, $
        pos=n_elements(pos) eq 0 ? [0.0, 0.0, 0.0] : pos, $
        scale=n_elements(scale) eq 0 ? 1.0 : scale, $
        _extra=e

    return, 1
end

;+
; Define instance variables.
;
; @file_comments Class representing a polyhedron.
; @field outline Switch to display outline/filled polyhedron.
; @requires IDL 6.0
; @author Michael Galloy, RSI, 2003
; @history
; <ul>
; <li>2006-06, Mark Piper: Refactored class, inheriting from
;     IDLgrPolygon instead of IDLgrModel. Removed IDLgrPolyline
;     reference. Renamed buildPolygons and getDefinition methods.
; </ul>
;-
pro polyhedron__define
    compile_opt idl2

    define = { polyhedron, inherits idlgrpolygon, $
               outline : 0B }
end
