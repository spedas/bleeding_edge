;20180405 Ali
;computes the mars surface intercept of a ray, given mars position and a direction vector defining a ray
;r: mars mean radius (km) [1]
;m: mars position (km) [3,nt]
;v: vector direction (unit vector) [3,nv]
;s: surface intercept point (km) [3,nv,nt]
function mvn_sep_fov_mars_incidence,r,m,v

  sizem=size(m,/dim)
  sizev=size(v,/dim)
  if n_elements(sizem) eq 1 then nt=1 else nt=sizem[1]
  if n_elements(sizev) eq 1 then nv=1 else nv=sizev[1]
  onesnt=replicate(1.,nt)
  onesnv=replicate(1.,nv)

  v0=reform(v[0,*]) ;[nv]
  wv0=where(v0 eq 0.,/null,nv0)
  if nv0 gt 0 then v0[wv0]=1e-10 ;to circumvent div by 0. (kluge)
  v0nt=v0#onesnt ;[nv,nt]
  v1nt=reform(v[1,*])#onesnt ;[nv,nt]
  v2nt=reform(v[2,*])#onesnt ;[nv,nt]

  m2=total(m^2,1) ;[nt]
  mv=transpose(v)#m ;[nv,nt]

  b=-2.*v0nt*mv ;[nv,nt]
  c=(v0^2)#(m2-r^2) ;[nv,nt]
  d=b^2-(4.*c) ;delta [nv,nt]

  wf=where((mv gt 0.) and (d gt 0.),/null,nf) ;where there is an intercept found
  if nf gt 0 then begin
    x1=(-b[wf]-sqrt(d[wf]))/2. ;[nf]
    x2=(-b[wf]+sqrt(d[wf]))/2. ;x2 > x1
    wv0lt0=where(v0nt[wf] lt 0.,/null,nv0lt0)
    x0=x1 ;[nf]
    if nv0lt0 gt 0 then x0[wv0lt0]=x2[wv0lt0] ;[nf]
    x=replicate(!values.f_nan,[1,nv,nt]) ;[1,nv,nt]
    x[wf]=x0 ;[1,nv,nt]
    y=x*v1nt/v0nt ;[1,nv,nt]
    z=x*v2nt/v0nt ;[1,nv,nt]
    s=[x,y,z] ;[3,nv,nt]
  endif else s=!values.f_nan

  return,s

  if 0 then begin ;older method, only works for nt=nv=1
    if v[0] eq 0. then v[0]=1e-10 ;to circumvent div by 0. (kluge)

    mv=total(m*v)
    m2=total(m^2)

    a=1.
    b=-2.*v[0]*mv
    c=(v[0]^2)*(m2-r^2)
    d=b^2-(4.*a*c) ;delta

    if (mv lt 0.) or (d lt 0.) then s=0 else begin
      x1=(-b-sqrt(d))/2./a
      x2=(-b+sqrt(d))/2./a ;x2 > x1
      x=(v[0] gt 0.) ? x1:x2
      y=x*v[1]/v[0]
      z=x*v[2]/v[0]
      s=[x,y,z]
    endelse

  endif

end

;method='Ellipsoid'
;target='mars'
;et=time_ephemeris(times[tminsub])
;time_valid=spice_valid_times(et,objects=[observer,target],/force_objects)
;if ~time_valid then continue
;fixref='IAU_MARS'
;abcorr='NONE'
;obsrvr=observer
;dref=to_frame
;dvec=v
;                      cspice_sincpt, method, target, et, fixref, abcorr, obsrvr, dref, dvec, spoint, trgepc, srfvec, found
;        if found then cspice_ilumin, method, target, et, fixref, abcorr, obsrvr,             spoint, trgepc, srfvec, phase, solar, emissn
;        if found then cossza[iphi,ithe]=cos(solar)
