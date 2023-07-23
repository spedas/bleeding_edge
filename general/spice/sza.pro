;Calculates solar Zenith angle from Sunstate coordinates (GSE at earth, MSO at Mars etc.)
function sza, x, y, z
  return, acos(x/sqrt(x^2+y^2+z^2))/!dtor
end
