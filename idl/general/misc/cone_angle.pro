function cone_angle, bx, by, bz
  bmag= sqrt (bx*bx + by*by + bz*bz)
  cone_angle = acos(bx/bmag)/!dtor
  return, cone_angle
end
