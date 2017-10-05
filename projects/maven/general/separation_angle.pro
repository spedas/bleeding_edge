; Calculates the separation angle, in radians, between two vectors.
; 
; Inputs: a, b are the vectors in question.
; 
; IMPORTANT: The first dimension of both factors must be 3!

function separation_angle, a, b
  cosphi = ((total(a*b,1)/(sqrt(total(a^2,1))*sqrt(total(b^2,1)))) > (-1.)) < 1.
  return, acos(cosphi)
end
