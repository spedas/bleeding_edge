function Matfrombas,old1,old2,old3,new1,new2,new3
;+
; Form the matrix for transforming components expressed in OLD system
; to NEW system...all six basis vectors must be expressed in the same
; system, although it doesn't matter what that system is.
;-


mat = [[old1],[old2],[old3]] # transpose([[new1],[new2],[new3]])

return,mat
end
