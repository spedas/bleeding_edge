;pro spp_swp_spanion_sim_crib


tof_max = 2048
TOF = indgen(tof_max)


ilog = round(alog(tof) / alog(tof_max) * 255)
ilog[0] = 0
ilog[1] = 11
plot,ilog

dilog = ilog - shift(ilog,1)
dilog[0] = dilog[1]

plot,dilog

uniq_vlog = uniq(ilog)


plot, 1 > uniq_vlog,/ylog,psym=10

duniq_vlog = uniq_vlog - shift(uniq_vlog,1)

duniq_vlog[0] = duniq_vlog[1]

plot,duniq_vlog


end
