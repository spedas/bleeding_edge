pro segment_print,segment
print,FORMAT='(D20.8,D20.8,I10,I10,D12.6,E15.6,I10,D12.6,E15.6,D12.6,D12.6,I10 )',$
   segment.t1,segment.t2,segment.c1,segment.c2,$
   segment.b,segment.c,segment.npts,segment.maxgap,$
   segment.phaserr, segment.initial_delta_phi,segment.idpu_spinper,segment.segflags
end
