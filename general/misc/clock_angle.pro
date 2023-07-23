function clock_angle, by, bz
  clock = (by gt 0)*acos(bz/sqrt(by*by + bz*bz))/!dtor + $
              (by le 0)*(360.0 - acos(bz/sqrt(by*by + bz*bz))/!dtor)
  return, clock
end
