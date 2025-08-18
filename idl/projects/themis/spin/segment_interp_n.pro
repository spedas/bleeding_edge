pro segment_interp_n,segment,n,t_last,spinper
  if (n LT segment.c1) then begin
    spinper=360.0D/segment.b
    nspins = segment.c1 - n
    t_last = segment.t1 - nspins*spinper
  endif else if (n GT segment.c2) then begin
    bp = segment.b + 2.0D*segment.c*(segment.t2 - segment.t1)
    nspins = n - segment.c2
    spinper = 360.0D/bp
    t_last = segment.t2 + spinper*nspins
  endif else begin
    nspins = n - segment.c1
    phi = 360.0D*nspins
    if (abs(segment.c) LT 1.0D-12) then begin
       dt = phi/segment.b 
    endif else begin
       b = segment.b
       c = segment.c
       dt = (-b + sqrt(b*b - 4.0D*c*(-phi)))/(2.0D*c)
    end
    bp = segment.b + 2.0D*segment.c*dt
    spinper = 360.0D/bp
    t_last = segment.t1 + dt
  end
end
