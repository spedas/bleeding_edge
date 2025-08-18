; the purpose of this function is to take as input a series of bin
; boundaries and return the bin centers

; created by Robert Lillis ((rlillis@ssl.Berkeley.edu)

Function bin_centers,  bin_edges
  nbins =  n_elements (bin_edges) -1
  return,  bin_edges[0: nbins  -1]+ 0.5*(bin_edges[1:*] -$
                                         bin_edges [0: nbins -1])
end
