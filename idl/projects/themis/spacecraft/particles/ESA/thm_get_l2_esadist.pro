;+
;NAME:
; thm_get_l2esadist
;PURPOSE:
; Returns a single 3D distribution for THEMIS ESA
; Equivalent to the GET_TH?_PE?? routines.
;CALLING SEQUENCE:
; dat = thm_get_l2_esadist(time, probe, datatype, $
;       START=st,EN=en,ADVANCE=adv,RETREAT=ret,index=ind,times=times)
;INPUT:
; time = time of the data to be returned, the closest in the full 3D
;        structure to the input time
; probe = 'a', 'b', 'c', 'd', or 'e'
; dataype = 'peif', 'peir', 'peeb', 'peef', 'peer', or 'peeb'
;KEYWORDS: (Same as one of the GET_TH?_PE?? functions)
;KEYWORDS:
;	start:		0,1		if set, gets first time in common block
;	en:		0,1		if set, gets last time in common block
;	advance		0,1		if set, gets next time in common block
;	retreat		0,1		if set, gets previous time in common block
;	index		long		gets data at the index value "ind" in common block
;	times		0,1		returns an array of times for
;all the data, returns 0 if no data
; Note that if the closest data point is invalid, then the next valid
;data point is returned
;OUTPUT:
; A single ESA 3D data structure, with tags:
;   PROJECT_NAME    STRING    'THEMIS'
;   SPACECRAFT      STRING    'a'
;   DATA_NAME       STRING    'IESA 3D Full'
;   APID            INT           1108
;   UNITS_NAME      STRING    'eflux'
;   UNITS_PROCEDURE STRING    'thm_convert_esa_units'
;   VALID           BYTE         1
;   TIME            DOUBLE       1.5572738e+09
;   END_TIME        DOUBLE       1.5572738e+09
;   DELTA_T         DOUBLE           2.7417169
;   INTEG_T         DOUBLE        0.0026774579
;   DT_ARR          FLOAT     Array[32, 88]
;   CONFIG1         BYTE         1
;   CONFIG2         BYTE         1
;   AN_IND          INT              1
;   EN_IND          INT              1
;   MODE            INT              1
;   NENERGY         INT             32
;   ENERGY          FLOAT     Array[32, 88]
;   DENERGY         FLOAT     Array[32, 88]
;   EFF             DOUBLE    Array[32, 88]
;   BINS            INT       Array[32, 88]
;   NBINS           INT             88
;   THETA           FLOAT     Array[32, 88]
;   DTHETA          FLOAT     Array[32, 88]
;   PHI             FLOAT     Array[32, 88]
;   DPHI            FLOAT     Array[32, 88]
;   DOMEGA          FLOAT     Array[32, 88]
;   GF              FLOAT     Array[32, 88]
;   GEOM_FACTOR     FLOAT        0.00153000
;   DEAD            FLOAT       1.70000e-07
;   MASS            FLOAT         0.0104389
;   CHARGE          FLOAT           1.00000
;   SC_POT          FLOAT           0.00000
;   ECLIPSE_DPHI    DOUBLE           0.0000000
;   MAGF            FLOAT     Array[3]
;   BKG             FLOAT     Array[32, 88]
;   DATA            FLOAT     Array[32, 88]
;HISTORY:
; 2022-11-14, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-10-30 16:00:06 -0700 (Mon, 30 Oct 2023) $
; $LastChangedRevision: 32212 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_get_l2_esadist.pro $
Function thm_get_l2_esadist, time, probe0, datatype0, $
                             START=st,EN=en,ADVANCE=adv,$
                             RETREAT=ret,index=ind,times=times

;Access the appropriate common block
  probe = strcompress(strlowcase(probe0[0]), /remove_all)
  datatype = strcompress(strlowcase(datatype0[0]), /remove_all)
  If(probe Eq 'a') Then Begin
     Case datatype of
        'peif': Begin
           common tha_peif_l2, tha_peif_ind, tha_peif_dat, tha_peif_vatt
           If(is_struct(tha_peif_dat)) Then Begin
              all_dat = tha_peif_dat & get_ind = tha_peif_ind
           Endif Else all_dat = -1
        End
        'peir': Begin
           common tha_peir_l2, tha_peir_ind, tha_peir_dat, tha_peir_vatt
           If(is_struct(tha_peir_dat)) Then Begin
              all_dat = tha_peir_dat & get_ind = tha_peir_ind
           Endif Else all_dat = -1
        End
        'peib': Begin
           common tha_peib_l2, tha_peib_ind, tha_peib_dat, tha_peib_vatt
           If(is_struct(tha_peib_dat)) Then Begin
              all_dat = tha_peib_dat & get_ind = tha_peib_ind
           Endif Else all_dat = -1
        End
        'peef': Begin
           common tha_peef_l2, tha_peef_ind, tha_peef_dat, tha_peef_vatt
           If(is_struct(tha_peef_dat)) Then Begin
              all_dat = tha_peef_dat & get_ind = tha_peef_ind
           Endif Else all_dat = -1
        End
        'peer': Begin
           common tha_peer_l2, tha_peer_ind, tha_peer_dat, tha_peer_vatt
           If(is_struct(tha_peer_dat)) Then Begin
              all_dat = tha_peer_dat & get_ind = tha_peer_ind
           Endif Else all_dat = -1
        End
        'peeb': Begin
           common tha_peeb_l2, tha_peeb_ind, tha_peeb_dat, tha_peeb_vatt
           If(is_struct(tha_peeb_dat)) Then Begin
              all_dat = tha_peeb_dat & get_ind = tha_peeb_ind
           Endif Else all_dat = -1
        End
        Else: all_dat = -1
     Endcase
  Endif Else If(probe Eq 'b') Then Begin
     Case datatype of
        'peif': Begin
           common thb_peif_l2, thb_peif_ind, thb_peif_dat, thb_peif_vatt
           If(is_struct(thb_peif_dat)) Then Begin
              all_dat = thb_peif_dat & get_ind = thb_peif_ind
           Endif Else all_dat = -1
        End
        'peir': Begin
           common thb_peir_l2, thb_peir_ind, thb_peir_dat, thb_peir_vatt
           If(is_struct(thb_peir_dat)) Then Begin
              all_dat = thb_peir_dat & get_ind = thb_peir_ind
           Endif Else all_dat = -1
        End
        'peib': Begin
           common thb_peib_l2, thb_peib_ind, thb_peib_dat, thb_peib_vatt
           If(is_struct(thb_peib_dat)) Then Begin
              all_dat = thb_peib_dat & get_ind = thb_peib_ind
           Endif Else all_dat = -1
        End
        'peef': Begin
           common thb_peef_l2, thb_peef_ind, thb_peef_dat, thb_peef_vatt
           If(is_struct(thb_peef_dat)) Then Begin
              all_dat = thb_peef_dat & get_ind = thb_peef_ind
           Endif Else all_dat = -1
        End
        'peer': Begin
           common thb_peer_l2, thb_peer_ind, thb_peer_dat, thb_peer_vatt
           If(is_struct(thb_peer_dat)) Then Begin
              all_dat = thb_peer_dat & get_ind = thb_peer_ind
           Endif Else all_dat = -1
        End
        'peeb': Begin
           common thb_peeb_l2, thb_peeb_ind, thb_peeb_dat, thb_peeb_vatt
           If(is_struct(thb_peeb_dat)) Then Begin
              all_dat = thb_peeb_dat & get_ind = thb_peeb_ind
           Endif Else all_dat = -1
        End
        Else: all_dat = -1
     Endcase
  Endif Else If(probe Eq 'c') Then Begin
     Case datatype of
        'peif': Begin
           common thc_peif_l2, thc_peif_ind, thc_peif_dat, thc_peif_vatt
           If(is_struct(thc_peif_dat)) Then Begin
              all_dat = thc_peif_dat & get_ind = thc_peif_ind
           Endif Else all_dat = -1
        End
        'peir': Begin
           common thc_peir_l2, thc_peir_ind, thc_peir_dat, thc_peir_vatt
           If(is_struct(thc_peir_dat)) Then Begin
              all_dat = thc_peir_dat & get_ind = thc_peir_ind
           Endif Else all_dat = -1
        End
        'peib': Begin
           common thc_peib_l2, thc_peib_ind, thc_peib_dat, thc_peib_vatt
           If(is_struct(thc_peib_dat)) Then Begin
              all_dat = thc_peib_dat & get_ind = thc_peib_ind
           Endif Else all_dat = -1
        End
        'peef': Begin
           common thc_peef_l2, thc_peef_ind, thc_peef_dat, thc_peef_vatt
           If(is_struct(thc_peef_dat)) Then Begin
              all_dat = thc_peef_dat & get_ind = thc_peef_ind
           Endif Else all_dat = -1
        End
        'peer': Begin
           common thc_peer_l2, thc_peer_ind, thc_peer_dat, thc_peer_vatt
           If(is_struct(thc_peer_dat)) Then Begin
              all_dat = thc_peer_dat & get_ind = thc_peer_ind
           Endif Else all_dat = -1
        End
        'peeb': Begin
           common thc_peeb_l2, thc_peeb_ind, thc_peeb_dat, thc_peeb_vatt
           If(is_struct(thc_peeb_dat)) Then Begin
              all_dat = thc_peeb_dat & get_ind = thc_peeb_ind
           Endif Else all_dat = -1
        End
        Else: all_dat = -1
     Endcase
  Endif Else If(probe Eq 'd') Then Begin
     Case datatype of
        'peif': Begin
           common thd_peif_l2, thd_peif_ind, thd_peif_dat, thd_peif_vatt
           If(is_struct(thd_peif_dat)) Then Begin
              all_dat = thd_peif_dat & get_ind = thd_peif_ind
           Endif Else all_dat = -1
        End
        'peir': Begin
           common thd_peir_l2, thd_peir_ind, thd_peir_dat, thd_peir_vatt
           If(is_struct(thd_peir_dat)) Then Begin
              all_dat = thd_peir_dat & get_ind = thd_peir_ind
           Endif Else all_dat = -1
        End
        'peib': Begin
           common thd_peib_l2, thd_peib_ind, thd_peib_dat, thd_peib_vatt
           If(is_struct(thd_peib_dat)) Then Begin
              all_dat = thd_peib_dat & get_ind = thd_peib_ind
           Endif Else all_dat = -1
        End
        'peef': Begin
           common thd_peef_l2, thd_peef_ind, thd_peef_dat, thd_peef_vatt
           If(is_struct(thd_peef_dat)) Then Begin
              all_dat = thd_peef_dat & get_ind = thd_peef_ind
           Endif Else all_dat = -1
        End
        'peer': Begin
           common thd_peer_l2, thd_peer_ind, thd_peer_dat, thd_peer_vatt
           If(is_struct(thd_peer_dat)) Then Begin
              all_dat = thd_peer_dat & get_ind = thd_peer_ind
           Endif Else all_dat = -1
        End
        'peeb': Begin
           common thd_peeb_l2, thd_peeb_ind, thd_peeb_dat, thd_peeb_vatt
           If(is_struct(thd_peeb_dat)) Then Begin
              all_dat = thd_peeb_dat & get_ind = thd_peeb_ind
           Endif Else all_dat = -1
        End
        Else: all_dat = -1
     Endcase
  Endif Else If(probe Eq 'e') Then Begin
     Case datatype of
        'peif': Begin
           common the_peif_l2, the_peif_ind, the_peif_dat, the_peif_vatt
           If(is_struct(the_peif_dat)) Then Begin
              all_dat = the_peif_dat & get_ind = the_peif_ind
           Endif Else all_dat = -1
        End
        'peir': Begin
           common the_peir_l2, the_peir_ind, the_peir_dat, the_peir_vatt
           If(is_struct(the_peir_dat)) Then Begin
              all_dat = the_peir_dat & get_ind = the_peir_ind
           Endif Else all_dat = -1
        End
        'peib': Begin
           common the_peib_l2, the_peib_ind, the_peib_dat, the_peib_vatt
           If(is_struct(the_peib_dat)) Then Begin
              all_dat = the_peib_dat & get_ind = the_peib_ind
           Endif Else all_dat = -1
        End
        'peef': Begin
           common the_peef_l2, the_peef_ind, the_peef_dat, the_peef_vatt
           If(is_struct(the_peef_dat)) Then Begin
              all_dat = the_peef_dat & get_ind = the_peef_ind
           Endif Else all_dat = -1
        End
        'peer': Begin
           common the_peer_l2, the_peer_ind, the_peer_dat, the_peer_vatt
           If(is_struct(the_peer_dat)) Then Begin
              all_dat = the_peer_dat & get_ind = the_peer_ind
           Endif Else all_dat = -1
        End
        'peeb': Begin
           common the_peeb_l2, the_peeb_ind, the_peeb_dat, the_peeb_vatt
           If(is_struct(the_peeb_dat)) Then Begin
              all_dat = the_peeb_dat & get_ind = the_peeb_ind
           Endif Else all_dat = -1
        End
        Else: all_dat = -1
     Endcase
  Endif Else all_dat = -1
  If(~is_struct(all_dat)) Then Begin
     dat = {project_name:'THEMIS',valid:0}
     dprint, 'Datatype '+datatype0+$
             ' is not loaded or unavailable for probe '+probe0
     Return, dat
  Endif
;Keyword inputs override time input, but maybe
;return the time array if times is set
  If(keyword_set(times)) Then Begin
     dat = (all_dat.time+all_dat.end_time)/2.0
     Return, dat
  Endif
  ndset = n_elements(all_dat.time)
  If(keyword_set(st)) Then Begin
     index_out = 0
  Endif Else If(keyword_set(en)) Then Begin
     index_out = ndset-1
  Endif Else If(keyword_set(adv)) Then Begin
     index_out = get_ind+1
  Endif Else If(keyword_set(ret)) Then Begin
     index_out = get_ind-1
  Endif Else If(keyword_set(ind)) Then Begin
     index_out = ind[0]
  Endif Else Begin              ;find nearest time
     tt = time_double(time)
     tmpmin = min(abs(all_dat.time-tt),index_out)
  Endelse
  ind = index_out
  If((ind lt 0) Or (ind Ge ndset)) Then Begin
     dat = {project_name: all_dat.project_name, $
            spacecraft:	all_dat.spacecraft, $
            data_name: all_dat.data_name, $
            apid: all_dat.apid, $
            valid: 0}
  Endif Else Begin 
;step to next ok data point
     While ((all_dat.valid[ind] Eq 0) And (ind+1 Lt ndset)) Do ind++
;fill the output structure
     config1=all_dat.config1[ind]
     config2=all_dat.config2[ind]
     an_ind=all_dat.an_ind[ind]
     en_ind=all_dat.en_ind[ind]
     mode=all_dat.md_ind[ind]
     cs_ptr=all_dat.cs_ptr[ind]
     nenergy=all_dat.nenergy[en_ind]
     nbins=all_dat.nbins[an_ind]
;     bins=intarr(nenergy,nbins) & bins[1:nenergy-1,*]=1
     bins = reform(all_dat.bins[ind,0:nenergy-1,0:nbins-1])
     energy = reform(all_dat.energy[0:nenergy-1,en_ind])#replicate(1.,nbins)
     denergy = reform(all_dat.denergy[0:nenergy-1,en_ind])#replicate(1.,nbins)
     an_eff = total(all_dat.an_eff#replicate(1.,nbins)*all_dat.an_map[*,0:nbins-1,an_ind],1)
;Special an_en_eff for electrons, reduces eff values for low energy, 2023-08-09, jmm
     If(datatype Eq 'peef' Or datatype eq 'peer' Or datatype Eq 'peeb') Then Begin
	an_en_eff = fltarr(nenergy,nbins) & an_en_eff[*,*]=1.
        an_en =	reform(all_dat.an_en_eff#replicate(1.,nbins),8,8,nbins)
        map = reform(replicate(1.,8)#reform(all_dat.an_map[*,0:nbins-1,an_ind],8*nbins),8,8,nbins)
        an_en_tmp=total(an_en*map,2)
        an_en_all = fltarr(32,nbins) & an_en_all[*,*]=1. & an_en_all[24:31,*]=an_en_tmp
        en_lnk = (interp(findgen(32),reform(all_dat.energy[*,1]),reform(energy[*,0])) <31.)>0 ;removed no_extrapolate, jmm, 2016-03-30
        en_int = fix(en_lnk) & en_plu = en_lnk-en_int & en_min = 1.-en_plu 
        en_map1 = fltarr(nenergy,32) & en_map2 = fltarr(nenergy,32) 
        en_map1[indgen(nenergy),(en_int+1)<31]=en_plu
        en_map2[indgen(nenergy),en_int<31]=en_min
        en_map=en_map1+en_map2
        an_en_eff=total(reform(reform(en_map,nenergy*32)#replicate(1.,nbins),nenergy,32,nbins)*reform(replicate(1.,nenergy)#reform(an_en_all,32*nbins),nenergy,32,nbins),2)
	eff    =reform( all_dat.en_eff[0:nenergy-1,en_ind])#an_eff*all_dat.rel_gf[ind]*an_en_eff
     Endif Else eff = reform(all_dat.en_eff[0:nenergy-1,en_ind])#an_eff*all_dat.rel_gf[ind]
     theta = reform(all_dat.theta[0:nenergy-1,0:nbins-1,an_ind])
     dtheta = reform(all_dat.dtheta[0:nenergy-1,0:nbins-1,an_ind])
     phi = reform(all_dat.phi[0:nenergy-1,0:nbins-1,an_ind])+all_dat.phi_offset[ind]
     dphi = reform(all_dat.dphi[0:nenergy-1,0:nbins-1,an_ind])
     domega = reform(all_dat.domega[0:nenergy-1,0:nbins-1,an_ind])
     gf = reform(all_dat.gf[0:nenergy-1,0:nbins-1,an_ind])
     dt_arr = reform(all_dat.dt_arr[0:nenergy-1,0:nbins-1,an_ind])
     bkg = reform(all_dat.bkg_arr[0:nenergy-1,0:nbins-1,an_ind])*all_dat.bkg[ind]
     eflux = reform(all_dat.eflux[ind, 0:nenergy-1, 0:nbins-1])
     valid = all_dat.valid[ind]
     dat = {project_name: all_dat.project_name, $
            spacecraft: all_dat.spacecraft, $
            data_name: all_dat.data_name, $
            apid: all_dat.apid, $
            units_name: all_dat.units_name, $
            units_procedure: all_dat.units_procedure, $
            valid: valid, $
            time: all_dat.time[ind], $
            end_time: all_dat.end_time[ind], $
            delta_t: all_dat.delta_t[ind], $
            integ_t: all_dat.integ_t[ind], $
            dt_arr: dt_arr, $
            config1: config1, $
            config2: config2, $
            an_ind: an_ind, $
            en_ind: en_ind, $
            mode: mode, $
            nenergy: nenergy, $
            energy: energy, $
            denergy: denergy, $
            eff: eff, $
            bins: bins, $
            nbins: nbins, $
            theta: theta, $
            dtheta: dtheta, $
            phi: phi, $
            dphi: dphi, $
            domega: domega, $
            gf: gf, $
            geom_factor: all_dat.geom_factor, $
            dead: all_dat.dead, $
            mass: all_dat.mass, $
            charge: all_dat.charge, $
            sc_pot: all_dat.sc_pot[ind], $
            eclipse_dphi: all_dat.eclipse_dphi[ind], $
            magf: reform(all_dat.magf[ind,*]), $
            bkg: bkg, $
            data: eflux}
;Reset index in common block
     get_ind = ind
     If(probe Eq 'a') Then Begin
        Case datatype of
           'peif': tha_peif_ind = get_ind
           'peir': tha_peir_ind = get_ind
           'peib': tha_peib_ind = get_ind
           'peef': tha_peef_ind = get_ind
           'peer': tha_peer_ind = get_ind
           'peeb': tha_peeb_ind = get_ind
        Endcase
     Endif Else If(probe Eq 'b') Then Begin
        Case datatype of
           'peif': thb_peif_ind = get_ind
           'peir': thb_peir_ind = get_ind
           'peib': thb_peib_ind = get_ind
           'peef': thb_peef_ind = get_ind
           'peer': thb_peer_ind = get_ind
           'peeb': thb_peeb_ind = get_ind
        Endcase
     Endif Else If(probe Eq 'c') Then Begin
        Case datatype of
           'peif': thc_peif_ind = get_ind
           'peir': thc_peir_ind = get_ind
           'peib': thc_peib_ind = get_ind
           'peef': thc_peef_ind = get_ind
           'peer': thc_peer_ind = get_ind
           'peeb': thc_peeb_ind = get_ind
        Endcase
     Endif Else If(probe Eq 'd') Then Begin
        Case datatype of
           'peif': thd_peif_ind = get_ind
           'peir': thd_peir_ind = get_ind
           'peib': thd_peib_ind = get_ind
           'peef': thd_peef_ind = get_ind
           'peer': thd_peer_ind = get_ind
           'peeb': thd_peeb_ind = get_ind
        Endcase
     Endif Else If(probe Eq 'e') Then Begin
        Case datatype of
           'peif': the_peif_ind = get_ind
           'peir': the_peir_ind = get_ind
           'peib': the_peib_ind = get_ind
           'peef': the_peef_ind = get_ind
           'peer': the_peer_ind = get_ind
           'peeb': the_peeb_ind = get_ind
        Endcase
     Endif
  Endelse
  Return, dat
End
