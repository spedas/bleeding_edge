;+
; NAME: rbsp_load_mageis_l2
;
; SYNTAX:
;
; PURPOSE: Fetches/loads RBSP ECT MagEIS L2 data
;
; INPUT: N/A
;
; OUTPUT: N/A
;
; KEYWORDS:
;	probe=probe
;	/get_mag_ephem - save the ECT mag ephemeris vars
;	/get_support_data - save CDF support data to TPLOT
;
; HISTORY:
;	Created Jan 2013, Kris Kersten, kris.kersten@gmail.com
;
; NOTES:
;	Bins are labeled for the energy as listed in the CDF file.  This looks like
;	the bottom energy for each bin.  This should probably be changed to reflect
;	the center energy of each bin.
;
;	There is overlap between the LOW, M35/75, and HIGH MagEIS FEDO energy
;	channels that are used to construct the full L2 spectrum.  Overlapping bins
;	are skipped to present a continuous energy spectrum.  This may need to be
;	tweaked in the future, to average/weight overlapping bins, etc.
;	See additional comments beginning at line ~70.
;
;
; VERSION:
;   $LastChangedBy: jimm $
;   $LastChangedDate: 2020-04-13 13:25:55 -0700 (Mon, 13 Apr 2020) $
;   $LastChangedRevision: 28568 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/ect/rbsp_load_mageis_l2.pro $
;
;-


pro rbsp_load_mageis_l2,probe=probe,get_mag_ephem=get_mag_ephem, $
  get_support_data=get_support_data

  rbsp_ect_init

  mag_ephem_names=['Position','B_Eq','B_Calc','L','L_star','I','MLT']

  if keyword_set(probe) then p_var=probe else p_var='*'
  vprobes = ['a','b']
  p_var = strfilter(vprobes, p_var ,delimiter=' ',/string)

  level=2
  slevel=string(level,format='(I0)')

  for p=0,size(p_var,/n_elements)-1 do begin

    rbspx = 'rbsp'+ p_var[p]

    tr = timerange()
    date = time_string(tr[0],/date_only,tformat='YYYYMMDD')
    yyyy = strmid(date,0,4)

    ;!rbsp_ect.remote_data_dir = 'https://rbsp-ect.newmexicoconsortium.org/data_pub/'
    prefix=rbspx+'_ect_mageis_L'+slevel+'_'


    dprint,dlevel=3,verbose=verbose,relpathnames,/phelp


    rp = !rbsp_ect.remote_data_dir + rbspx+'/mageis/level2/sectors/'+yyyy+'/'
    rf = rbspx+'_rel0?_ect-mageis-L2_'+date+'_v*.cdf'
    files = spd_download(remote_path=rp,remote_file=rf,$
    local_path=!rbsp_ect.local_data_dir+'mageis/L2/',$
    /last_version)




    spd_cdf2tplot,file=files,varformat=varformat,all=0,prefix=prefix,suffix=suf,verbose=vb, $
    tplotnames=tns,/convert_int1_to_int2,get_support_data=1 ; load data into tplot variables

    ; format L2 TPLOT vars
    ;tags=['FEDO','FPDO','FPDU'] ; what is FPDU?
    tags=['FESA','FPSA']

    for i=0,n_elements(tags)-1 do begin
      tn=prefix+tags[i]
      get_data,tn,data=d,limits=l,dlimits=dl

      case tags[i] of
        'FESA':begin
        ; L2 FEDO energy channels overlap between LOW, M35/75, and HIGH
        ; skip overlapping energy bins
        ; RBSPA FEDO energy bins (keV)
        ; 0   1    2    3    4    5     6     7     8     9     10    11    12    13    14    15    16    17     18    19     20     21     22     23     24
        ; 0.0 22.1 37.3 56.7 80.4 110.9 145.9 184.9 221.1 211.3 237.1 317.4 349.1 455.9 582.7 730.2 884.6 1056.6 846.0 1253.0 1535.0 1942.0 2521.0 3156.0 3869.0
        ; OVERLAPPING BINS TO REMOVE: 9,10,18

        ; RBSPB FEDO energy bins (keV)
        ; 0   1    2    3    4    5     6     7     8     9   10    11    12    13    14    15    16    17     18    19     20     21     22     23     24
        ; 0.0 23.0 36.0 54.0 76.0 103.0 134.0 168.0 198.0 0.0 161.4 250.7 352.6 469.2 595.9 738.9 886.0 1054.9 888.0 1362.0 1666.0 2065.0 2615.0 3257.0 3893.0
        ; OVERLAPPING BINS TO REMOVE: 9,10,18
        goodbins=[lindgen(9),lindgen(7)+11,lindgen(6)+19]
        str_element,d,'y',d.y[*,goodbins],/add_replace
        newv=dblarr(n_elements(goodbins))
        for i=0,n_elements(goodbins)-1 do $
          ;newv[i]=median(d.v[*,goodbins[i]])
;          newv[i]=median(d.v[goodbins[i]])
          newv[i]=d.v[goodbins[i]]
          str_element,d,'v',newv,/add_replace

        tyrange=[17.,4.e3]
      end
      'FPSA':tyrange=[60.,1400.]
      else:tyrange=[0,0]
    endcase

    labels=string(d.v,format='(F0.1)')+' keV'
    str_element,l,'labels',labels,/add_replace
    str_element,l,'yrange',tyrange,/add_replace
    str_element,l,'ylog',1,/add_replace
    str_element,l,'ystyle',1,/add_replace
    str_element,l,'zstyle',0,/add_replace
    str_element,l,'zrange',[0,0],/add_replace
    str_element,l,'zlog',1,/add_replace
    ; move (cm^2 s^-1 keV^-1) label to z axis, energy to y axis
    str_element,dl,'ztitle',dl.ysubtitle,/add_replace
    str_element,dl,'ysubtitle','Energy [keV]',/add_replace

    store_data,tn,data=d,limits=l,dlimits=dl

  endfor

  if ~keyword_set(get_support_data) then begin
    support_data_keep=['NONE!']
    for i = 0, n_elements(tns) - 1 do begin
      if strfilter(tns[i],'*'+support_data_keep) eq '' then begin
        get_data,tns[i],dlimits=thisdlimits
        cdf_str = 0
        str_element,thisdlimits,'cdf',cdf_str
        if keyword_set(cdf_str) then if cdf_str.vatt.var_type eq 'support_data' then $
        store_data,tns[i],/delete,verbose=0
      endif
    endfor
  endif

  if ~keyword_set(get_mag_ephem) then $
  store_data,prefix+mag_ephem_names,/delete,verbose=1

endfor

end
