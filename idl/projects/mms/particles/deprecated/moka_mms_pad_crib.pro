;+
;Procedure:
;  moka_mms_pad_crib
;
;Purpose:
;  Demonstrates usage of 'moka_mms_pad' (a program for Pitch Angle Distribution (PAD)).
;  
;History:
;  Created by Mitsuo Oka on 2017-01-05
;
;$LastChangedBy: moka $
;$LastChangedDate: 2017-10-19 12:43:56 -0700 (Thu, 19 Oct 2017) $
;$LastChangedRevision: 24187 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/deprecated/moka_mms_pad_crib.pro $
;-
PRO moka_mms_pad_crib
  compile_opt idl2
  tic
  
  ;///// USER SETTING ///////////
  RESTORE  = 0  ; (0) load from CDF (1) restore from .tplot (2) already loaded in IDL 
  trange   = '2015-10-22/06:03:57'+['.114','.264']; Fig.1l of Phan et al. GRL 2016
  prb      = '1'
  species  = 'i' ; 'i' for ions and 'e' for electrons
  filename = 'data_for_pad_crib'
  subtract_bulk = 0
  ;//////////////////////////////
  
  ;------------------------
  ; INITIALIZE
  ;------------------------
  mms_init
  sc = 'mms'+prb
  trange = time_double(trange)
  
  ;------------------------
  ; LOAD
  ;------------------------
  case RESTORE of
    0:begin
      timespan, trange[0], trange[1]-trange[0], /seconds
      mms_load_fgm,probe=prb, data_rate='brst',/get_fgm_ephemeris
      mms_load_fpi,probe=prb,data_rate='brst',level='l2', datatype=['des-dist','dis-dist','dis-moms','des-moms']
      tplot_save,'*',filename=filename
      end
    1:begin
      tplot_restore, filename=filename+'.tplot'
      end
    else:   ;do nothing (data must be already loaded into the IDL session)
  endcase
  tname = sc+'_d'+species+'s_dist_brst'
  bname = sc+'_fgm_b_dmpa_brst_l2_bvec'
  ename = sc+'_d'+species+'s_disterr_brst'
  vname = sc+'_d'+species+'s_bulkv_dbcs_brst'
  
  ;------------  
  ; GET PAD
  ;------------
  pad = moka_mms_pad(bname, tname, trange, ename=ename, vname=vname, subtract_bulk=subtract_bulk)
  title = time_string(pad.trange[0],prec=4)+' --- '+time_string(pad.trange[1],prec=4)


  ;----------------------------
  ; Energy Spectra (1D Cuts)
  ;----------------------------

  yrange = [1e+1, 1e+10]
      
  plot, pad.EGY, pad.SPEC_OMN,color=0,title=title, $
    /xlog,xstyle=1,$;xrange=[10,30000],$
    /ylog,ystyle=1,yrange=yrange
  oplot, pad.EGY, pad.SPEC___0,color=2
  oplot, pad.EGY, pad.SPEC__90,color=4
  oplot, pad.EGY, pad.SPEC_180,color=6
  
  oplot, pad.EGY, pad.OCLV_OMN,color=0, linestyle=3; OCLV = one-count-level
  oplot, pad.EGY, pad.OCLV___0,color=2, linestyle=3
  oplot, pad.EGY, pad.OCLV__90,color=4, linestyle=3
  oplot, pad.EGY, pad.OCLV_180,color=6, linestyle=3
  
  xlblpos = 10000.
  xyouts, xlblpos, yrange[1]*0.1, 'omni',color=0,/data
  xyouts, xlblpos, yrange[1]*0.03,'para',color=2,/data
  xyouts, xlblpos, yrange[1]*0.01,'perp',color=4,/data
  xyouts, xlblpos, yrange[1]*0.003,'anti-para',color=6,/data
  stop
  
  ;---------------------------------------
  ; Pitch-Angle vs Energy Plot (2D PAD)
  ;---------------------------------------
  erange = [8,27000]
  zrange = [1e+5, 2e+8]
  
  PAD_ROTATE = 0
  
  if PAD_ROTATE then begin
    plotxyz,pad.PA, pad.EGY, pad.DATA,/noisotropic,ylog=0,zlog=1,$
      xrange=[180,0],xtitle='pitch angle',ytitle='energy',yrange=erange,$
      xtickinterval=30,ztitle=pad.UNITS,title=title,zrange=zrange
  endif else begin
    plotxyz,pad.EGY, pad.PA, transpose(pad.DATA),/noisotropic,/xlog,ylog=0,zlog=1,$
      yrange=[0,180],ytitle='pitch angle',xtitle='energy',xrange=erange,$
      ytickinterval=30,ztitle=pad.UNITS,title=title,zrange=zrange
  endelse
    
  
  toc
END
