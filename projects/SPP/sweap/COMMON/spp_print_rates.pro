pro print_rates,t

  if ~keyword_set(t) then ctime,t,npoint=2,/silent

  valids=tsample('spp_spanai_rates_VALID_CNTS',t,/average)
  multis=tsample('spp_spanai_rates_MULTI_CNTS',t,/average)
  ostarts=tsample('spp_spanai_rates_START_CNTS',t,/average)
  ostops =tsample('spp_spanai_rates_STOP_CNTS',t,/average)

  print,findgen(16)
  print
  print,valids
  print,multis
  print,ostarts
  print,ostops

  starts = ostarts+valids
  stops = ostops+valids
  print
  print,valids/starts
  print,valids/stops

end
