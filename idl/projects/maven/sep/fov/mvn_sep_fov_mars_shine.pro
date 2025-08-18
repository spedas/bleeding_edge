;20180404 Ali
;calculates the fraction of the sep fov covered by mars surface and mars shine
;rmars: mars radius (km)
;posmar: center of mars position w.r.t maven (km)
;possun: unit vector pointing to the sun from maven (or mars)
;fov: if set, calculations are done for only within the fov of each sep
;resdeg: angular resolution of calculations in degrees. default is 1 degree
;response: if set, plots fov response
;vector: if set, vectorization is used (could be faster, but much higher memory usage). 0:loop over time (default), 1:no loops 2:loop over angles
;
function mvn_sep_fov_mars_shine,rmars,posmar,possun,fov=fov,resdeg=resdeg,response=response,vector=vector

  if n_elements(vector) eq 0 then vector=0
  fnan=!values.f_nan
  srefa=15.5 ;ref (phi) angle
  scrsa=21.0 ;cross (theta) angle

  if ~keyword_set(resdeg) then resdeg=1.
  phid=resdeg*findgen(360./resdeg)-180. ;degrees
  thed=resdeg*findgen(180./resdeg)
  spc=[-45.,+45.,+135.,-135.] ;SEP 1F,2F,1R,2R phi center
  wthe=where(abs(thed-90.) le scrsa,/null,nth2)
  if keyword_set(fov) then begin
    wphi=where((abs(phid-spc[0]) le srefa) or (abs(phid-spc[1]) le srefa) or (abs(phid-spc[2]) le srefa) or (abs(phid-spc[3]) le srefa),/null)
    phid=phid[wphi]
    thed=thed[wthe]
    wthe=where(abs(thed-90.) le scrsa,/null,nth2)
  endif
  nphi=n_elements(phid)
  nthe=n_elements(thed)
  fthe=(cos(!dtor*(thed[wthe]-90.))-cos(!dtor*scrsa))/(1.-cos(!dtor*scrsa)) ;weighting based on detector angular response

  x=cos(!dtor*(phid+45.))#sin(!dtor*thed) ;sep1x
  y=sin(!dtor*(phid+45.))#sin(!dtor*thed) ;sep1z
  z=replicate(1.,nphi)#cos(!dtor*thed) ;sep1y
  dvec=transpose(reform([[x],[z],[y]],[nphi*nthe,3]))

  sizemar=size(posmar,/dim)
  if n_elements(sizemar) eq 1 then nt=1 else nt=sizemar[1]
  mars_surfa=replicate(fnan,[4,nt])
  mars_shine=mars_surfa
  atmo_shine=mars_surfa
  mshine_fov=mars_surfa
  ashine_fov=mars_surfa

  if vector eq 1 then begin ;vectorization: faster, but uses more memory!
    spoint=mvn_sep_fov_mars_incidence(rmars,posmar,dvec)
    cossza=reform(total((spoint-transpose(rebin(posmar,[3,nt,nphi*nthe]),[0,2,1]))*transpose(rebin(possun,[3,nt,nphi*nthe]),[0,2,1]),1),[nphi,nthe,nt])/rmars
    tanalt=cossza ;need to fix these!
    atmosh=cossza
  endif
  
  if vector eq 2 then begin ;loop over angles
    cossza=replicate(fnan,[nphi,nthe,nt])
    tanalt=cossza
    atmosh=cossza
    spoint=replicate(fnan,[3,nphi,nthe,nt])
    radmar=sqrt(total(posmar^2,1)) ;radial distance of MAVEN from Mars (km)
    for ithe=0,nthe-1 do begin
      if nt gt 1 && ~(ithe mod 10) then dprint,ithe,'   out of',nthe,'  theta steps done.'
      for iphi=0,nphi-1 do begin
        dvec=[x[iphi,ithe],z[iphi,ithe],y[iphi,ithe]]
        pdmmar=total(posmar*rebin(dvec,[3,nt]),1)/radmar
        talt=radmar*sqrt(1.d0-pdmmar^2)-rmars ;tangent altitude of dvec (km)
        wtalt0=where(talt lt 0. and pdmmar gt 0.,/null,nws) ;surface
        wtagt0=where(talt gt 0. and talt lt 100. and pdmmar gt 0.,/null,nwt) ;for atmosphere shine
        talt[where(pdmmar lt 0. or talt lt 0.,/null)]=fnan  ;where dvec away from Mars or negative tanalt
        tanalt[iphi,ithe,*]=talt
        if nws gt 0 then begin
          spoint2=mvn_sep_fov_mars_incidence(rmars,posmar[*,wtalt0],dvec)
          spoint[*,iphi,ithe,wtalt0]=reform(spoint2)
          cossza[iphi,ithe,wtalt0]=total((reform(spoint2)-posmar[*,wtalt0])*possun[*,wtalt0],1)/rmars
        endif
        ;        if nwt gt 0 then begin
        postal=dvec#(radmar*pdmmar)-posmar ;tangent altitude vector from Mars center (km)
        cosszatal=total(postal*possun,1)/sqrt(total(postal^2,1)) ;cos(sza of tanalt)
        atmosh[iphi,ithe,*]=(cosszatal gt 0.)*(10.+cosszatal)*exp(-talt/10.)
        ;        endif
      endfor
    endfor
  endif
  if vector eq 0 then begin ;loop over time
    for it=0,nt-1 do begin
      if  nt gt 1 && ~(it mod 1e4) then dprint,it,'   out of',nt,'  time steps done.'
      spoint=mvn_sep_fov_mars_incidence(rmars,posmar[*,it],dvec)
      cossza=reform(total((spoint-rebin(posmar[*,it],[3,nphi*nthe]))*rebin(possun[*,it],[3,nphi*nthe]),1),[nphi,nthe])/rmars
      atmosh=cossza ;need to fix this
      tanalt=cossza ;need to fix this
      for isep=0,3 do begin
        wph2=where(abs(phid-spc[isep]) le srefa,/null,nph2)
        fphi=(cos(!dtor*(phid[wph2]-spc[isep]))-cos(!dtor*srefa))/(1.-cos(!dtor*srefa)) ;weighting based on detector angular response
        wfov=replicate(1.,[nph2,nth2]) ;constant (uniform) weighting for fov elements
        wfo2=fphi#fthe
        cosszafov=cossza[wph2,wthe,*] ;elements within fov
        atmoshfov=atmosh[wph2,wthe,*]
        mars_surfa[isep,it]=total(total(finite(cosszafov)*wfov,1),1)/total(wfov) ;mars surface (disc)
        mars_shine[isep,it]=total(total((cosszafov gt 0.)*cosszafov*wfov,/nan,1),1)/total(wfov) ;mars shine
        atmo_shine[isep,it]=total(total((atmoshfov gt 0.)*atmoshfov*wfov,/nan,1),1)/total(wfov) ;atmo shine
        mshine_fov[isep,it]=total(total((cosszafov gt 0.)*cosszafov*wfo2,/nan,1),1)/total(wfo2) ;mars shine convolved w/ fov response
        ashine_fov[isep,it]=total(total((atmoshfov gt 0.)*atmoshfov*wfo2,/nan,1),1)/total(wfo2) ;mars shine convolved w/ fov response
      endfor
    endfor
  endif

  if vector eq 1 || vector eq 2 then begin
    for isep=0,3 do begin
      wph2=where(abs(phid-spc[isep]) le srefa,/null,nph2)
      fphi=(cos(!dtor*(phid[wph2]-spc[isep]))-cos(!dtor*srefa))/(1.-cos(!dtor*srefa)) ;weighting based on detector angular response
      wfov=replicate(1.,[nph2,nth2]) ;constant (uniform) weighting for fov elements
      wfo2=fphi#fthe
      if keyword_set(response) then p=image(wfo2,phid[wph2],thed[wthe]-90.,rgb=33,/o,min=0.,max=1.)
      cosszafov=cossza[wph2,wthe,*] ;elements within fov
      atmoshfov=atmosh[wph2,wthe,*]
      mars_surfa[isep,*]=total(total(finite(cosszafov)*rebin(wfov,[nph2,nth2,nt]),1),1)/total(wfov) ;mars surface (disc)
      mars_shine[isep,*]=total(total((cosszafov gt 0.)*cosszafov*rebin(wfov,[nph2,nth2,nt]),/nan,1),1)/total(wfov) ;mars shine
      atmo_shine[isep,*]=total(total((atmoshfov gt 0.)*atmoshfov*rebin(wfov,[nph2,nth2,nt]),/nan,1),1)/total(wfov) ;atmo shine
      mshine_fov[isep,*]=total(total((cosszafov gt 0.)*cosszafov*rebin(wfo2,[nph2,nth2,nt]),/nan,1),1)/total(wfo2) ;mars shine convolved w/ fov response
      ashine_fov[isep,*]=total(total((atmoshfov gt 0.)*atmoshfov*rebin(wfo2,[nph2,nth2,nt]),/nan,1),1)/total(wfo2) ;mars shine convolved w/ fov response
    endfor
  endif

  fraction={time:replicate(!values.d_nan,nt),fov:['SEP1F','SEP2F','SEP1R','SEP2R'],mars_surfa:mars_surfa,mars_shine:mars_shine,atmo_shine:atmo_shine,mshine_fov:mshine_fov,ashine_fov:ashine_fov,surfce:spoint,cossza:cossza,tanalt:tanalt,atmosh:atmosh,phid:phid,thed:thed}
  return,fraction

  if 0 then begin ;old method: Mars shine on surface based on cos(sza)
    x=sin(th/2.)#cos(th)
    y=sin(th/2.)#sin(th)
    z=rebin(cos(th/2.),[nth,nth])
    xyz=reform(transpose([[[x]],[[y]],[[z]]]),[3,nth^2])
    cossza=total(xyz*rebin(possun,[3,nth^2]),1)
    xyzmar=rmars*xyz+rebin(posmar,[3,nth^2])
    xyzdir=xyzmar/(ones3#sqrt(total(xyzmar^2,1)))
    dist=sqrt(total(xyzmar^2,1)) ;distance of point on the mars surface from maven
    wdlt=where(dist lt sqrt(mvnrad^2-rmars^2),/null)

    septheta=90.-!radeg*acos(xyzdir[2,wdlt]) ;sep-xy angle (degrees)
    sep1fphi=!radeg*atan(xyzdir[1,wdlt],xyzdir[0,wdlt]) ;sep1f-xz angle (degrees) [-180,180]
    sepphi=sep1fphi-45. ;to align phi=0 with s/c +Z axis
    wlt180=where(sepphi lt -180.,/null)
    if n_elements(wlt180) gt 0 then sepphi[wlt180]+=360.
    fovmars=replicate(0.,[360,180])
    fovshin=fovmars
    ph=floor(sepphi)+180  ;[0,359] ;ref angle
    th=floor(septheta)+90 ;[0,179] ;cross angle
    shine=cossza
    shine[where(shine lt 0.,/null)]=0.
    np=n_elements(cossza) ;number of points
    for ip=0,np-1 do begin
      fovmars[ph[ip],th[ip]]+=1.
      fovshin[ph[ip],th[ip]]+=shine[ip]
    endfor
    marshin=fovshin/fovmars
    p=image(marshin,findgen(360)-180.,findgen(180)-90.,rgb=colortable(64,/reverse),/o,min=0.,max=1.)
    szascaled=bytscl(1.-cossza,min=0.,max=1.)
    p=scatterplot(/o,sepphi,septheta,rgb=64,sym='o',/sym_filled,magnitude=szascaled)
  endif
end