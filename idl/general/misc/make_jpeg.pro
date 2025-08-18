pro make_jpeg, filename
  tvlct, r, g, b, /get
  image = tvrd(/true)
  write_jpeg, filename, image, quality = 100, true = 1
end
