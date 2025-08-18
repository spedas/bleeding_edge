;20171115 Ali
;testing the analytical trajectory solver
;
pro mvn_sep_elec_traj_tester
  magit=[0,0,10] ;nT
  v1=[0,1e3,1e6] ;km/s
  x1=[-50,0,0] ;km
  alt=200. ;km
  iteration=0
  dt=1e-4 ;seconds
  plot,[0],xrange=[-10,10],yrange=[-100,10000]

  while (alt gt 100. and alt lt 1000. and iteration lt 2000) do begin ;particle tracing loop
    oplot,[x1[1]],[x1[2]],psym=1
    v0=v1
    mvn_sep_elec_traj_solver,magit,v0,dt,v1,dr
    x1+=dr
;    alt=sqrt(total(x1^2))-rmars ;altitude (km)
    iteration++
  endwhile


end