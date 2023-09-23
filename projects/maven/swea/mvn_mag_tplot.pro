;+
;PROCEDURE:   mvn_mag_tplot
;PURPOSE:
;  Makes fancy MAG tplot panels: amplitude on a log scale, and phi/theta
;  in a single panel.  This routine is not intended for general use, but
;  you're welcome to use it.  Much of this code was borrowed from Takuya
;  Hara.
;
;USAGE:
;  mvn_mag_tplot
;INPUTS:
;       bvec:      Tplot variable name containing the magnetic field vectors.
;                  Default = 'mvn_B_1sec_maven_mso'.
;
;KEYWORDS:
;       SANG:      Archmedian spiral angle at Mars.  Default = 54 deg (for
;                  a nominal 400-km/s solar wind velocity).  The phi/theta
;                  panel will contain horizontal lines at the angles for
;                  toward and away sectors.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-09-05 08:53:38 -0700 (Tue, 05 Sep 2023) $
; $LastChangedRevision: 32078 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_mag_tplot.pro $
;
;CREATED BY:	David L. Mitchell  2015-04-02
;-

pro mvn_mag_tplot, bvec, model=model, sang=sang

  nan = !values.f_nan
  blab = ['Bx','By','Bz']
  bcol = [2,4,6]
  tplot_options, get=topt
  names = tnames()

  if not keyword_set(bvec) then bvec = 'mvn_B_1sec_maven_mso'
  if not keyword_set(sang) then sang = 54.

  get_data, bvec, alim=alim, data=b, index=i
  if (i eq 0) then begin
    print,"MAG data not found: ", bvec
    return
  endif
  bvec = names[i-1]

  str_element, alim, 'level', lvl, success=ok
  if (not ok) then lvl = 'L?'
  
  str_element, alim, 'spice_frame', frame, success=ok
  if (not ok) then frame = '??'
  if (strmatch(frame, '*spacecraft*', /fold)) then frame = 'S/C'
  if (strmatch(frame, '*mso*', /fold)) then frame = 'MSO'
  if (strmatch(frame, '*iau*', /fold)) then frame = 'GEO'
  
  if (frame eq 'MSO') then acon = [(180.-sang), 180., (360.-sang)] $
                      else acon = [180.]

  btot = sqrt(total(b.y*b.y, 2))

  options, bvec, labels=blab, colors=bcol, labflag=1, constant=0, $
                 ytitle='MAG ' + lvl, /def

  get_data, bvec, dl=bl
  bmax = max(btot, /nan)
  if (bmax gt 100.) then blog = 1 else blog = 0     

  bp = b.y ; positive sign
  bm = b.y ; negative sign
  lbp = blab
  lbm = blab
  for il=0,2 do if (b.y[n_elements(b.x)-1, il] gt 0.) then lbm[il] = '' else lbp[il] = '' 
  undefine, il

  idx = where(bp lt 0., nidx)
  if (nidx gt 0) then bp[idx] = nan
  idx = where(bm gt 0., nidx)
  if (nidx gt 0) then bm[idx] = nan

  store_data, bvec + '_plus', data={x: b.x, y: bp}, dl=bl
  store_data, bvec + '_minus', data={x: b.x, y: abs(bm)}, dl=bl

  options, bvec + '_plus', panel_size=0.5, labels=lbp, $
           ytitle='MAG ' + lvl, ysubtitle='+B' + strlowcase(frame) + ' [nT]', /def
  options, bvec + '_minus', panel_size=0.5, labels=lbm, $
           ytitle='MAG ' + lvl, ysubtitle='-B' + strlowcase(frame) + ' [nT]', /def
  options, bvec +  ['_plus', '_minus'], labflag=1

  store_data, 'mvn_mag_' + strlowcase(lvl) + '_bamp_1sec', $
              data={x: b.x, y: btot}, $
              dlimits={ytitle: 'MAG ' + lvl, ysubtitle: '|B| [nT]'}

  if keyword_set(model) then mvn_model_bcrust_load, /nocalc
  get_data, 'mvn_mod_bcrust_amp', index=i
  if (i eq 0) then store_data, 'mvn_mod_bcrust_amp', data={x:minmax(b.x), y:[nan,nan]}
  options,'mvn_mod_bcrust_amp','linestyle',2
  
  store_data, 'mvn_mag_bamp', data=['mvn_mag_' + strlowcase(lvl) + '_bamp_1sec', 'mvn_mod_bcrust_amp'], $
              dlimits={labels: ['obs', 'model'], colors:[4,6], labflag: -1, ytitle: 'MAG ' + lvl, $
              ysubtitle: '|B| [nT]'} 

  if (blog) then begin
    ylim, 'mvn_mag_bamp', 0.5, bmax*1.1, 1
    options, 'mvn_mag_bamp', ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log'
  endif

  ylim, bvec + '_plus', 0.5, bmax*1.1, 1
  ylim, bvec + '_minus', bmax*1.1, 0.5, 1
  options, bvec + '_plus', ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log'
  options, bvec + '_minus', ytickformat='mvn_ql_pfp_tplot_ytickname_minus_log'

  undefine, bmax, blog, status
     
  bphi = atan(b.y[*, 1], b.y[*, 0])
  bthe = asin(b.y[*, 2] / btot)
  idx = where(bphi lt 0., nidx)
  if (nidx gt 0) then bphi[idx] += 2.*!pi
  undefine, idx, nidx

  aopt = {yaxis:1, ystyle:1, yrange:[-90.,90.], ytitle:'', color:4, yticks:2, yminor:3}
  if tag_exist(topt,'charsize') then str_element, aopt, 'charsize', topt.charsize, /add_replace

  vname = 'mvn_mag_bang'
  store_data, vname, data={x: b.x, y: [[bthe*!RADEG*2.+180.], [bphi*!RADEG]]}
  options, vname, 'psym', 3
  options, vname, 'colors', [4,6]
  options, vname, 'ytitle', 'MAG ' + lvl
  options, vname, 'ysubtitle', frame + ' Angles'
  options, vname, 'yticks', 4
  options, vname, 'yminor', 3
  options, vname, 'ystyle', 9
  options, vname, 'labels', ['  theta','  phi']
  options, vname, 'labflag', 1
  options, vname, 'constant', acon
  options, vname, 'axis', aopt
  ylim, vname, 0., 360., 0., /def
  undefine, bphi, bthe, b

  vname = 'mvn_mag_azel'
  get_data, 'mvn_B_1sec_iau_mars', data=Bgeo
  str_element, Bgeo, 'azim', success=ok
  str_element, Bgeo, 'elev', success=ok
  if (ok) then begin
    aopt.ytitle = ''
    store_data, vname, data={x:Bgeo.x, y:[[Bgeo.elev*2.+180.], [Bgeo.azim]]}
    options, vname, 'psym', 3
    options, vname, 'colors', [4,6]
    options, vname, 'ytitle', 'MAG ' + lvl
    options, vname, 'ysubtitle', 'Local Angles'
    options, vname, 'yticks', 4
    options, vname, 'yminor', 3
    options, vname, 'ystyle', 9
    options, vname, 'labels', ['  elev','  azim']
    options, vname, 'labflag', 1
    options, vname, 'constant', 180.
    options, vname, 'axis', aopt
    ylim, vname, 0., 360., 0., /def
  endif

  return

end
