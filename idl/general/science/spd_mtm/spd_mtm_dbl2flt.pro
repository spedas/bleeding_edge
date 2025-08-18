;+
; :Description:
;   Turn the double precision outputs in single precision (float).
;
; :Params:
;   INPUTS:
;        spec - structure with results of the spectral analysis
;               (as defined in spd_mtm.pro)
;         par - properties of the time series and parameters defining
;               the spectral analysis (as defined in spd_mtm.pro)
;        peak - identified signals (as defined in spd_mtm.pro)
;     rshspec - spectral analysis results for the reshaped PSD
;               (same structure as spec)
;     rshpeak - signals identified with the reshaped PSD
;               (same structure as peak)
;
; :Author:
;     Simone Di Matteo, Ph.D.
;     8800 Greenbelt Rd
;     Greenbelt, MD 20771 USA
;     E-mail: simone.dimatteo@nasa.gov
;-
;*****************************************************************************;
;                                                                             ;
;   Copyright (c) 2020, by Simone Di Matteo                                   ;
;                                                                             ;
;   Licensed under the Apache License, Version 2.0 (the "License");           ;
;   you may not use this file except in compliance with the License.          ;
;   See the NOTICE file distributed with this work for additional             ;
;   information regarding copyright ownership.                                ;
;   You may obtain a copy of the License at                                   ;
;                                                                             ;
;       http://www.apache.org/licenses/LICENSE-2.0                            ;
;                                                                             ;
;   Unless required by applicable law or agreed to in writing, software       ;
;   distributed under the License is distributed on an "AS IS" BASIS,         ;
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  ;
;   See the License for the specific language governing permissions and       ;
;   limitations under the License.                                            ;
;                                                                             ;
;*****************************************************************************;
;
pro spd_mtm_dbl2flt, spec=spec, par=par, peak=peak, $
  rshspec=rshspec, rshpeak=rshpeak

if isa(par, /array) then begin
  ;
  fpar = { $
    npts:par.npts.convert(/float), $
    dt:par.dt.convert(/float), $
    dtsig:par.dtsig.convert(/float), $
    datavar:par.datavar.convert(/float), $
    fray:par.fray.convert(/float), $
    fny:par.fny.convert(/float), $
    npad:par.npad.convert(/float), $
    nfreq:par.nfreq.convert(/float), $
    df:par.df.convert(/float), $
    fbeg:par.fbeg.convert(/float), $
    fend:par.fend.convert(/float), $
    psmooth:par.psmooth.convert(/float), $
    conf:par.conf.convert(/float), $
    NW:par.NW.convert(/float), $
    Ktpr:par.Ktpr.convert(/float), $
    tprs:par.tprs, $
    V:par.V}
  ;
  par = fpar
  ;
endif

if isa(spec, /array) then begin
  ;
  fspec = { $
    ff:spec.ff.convert(/float), $
    raw:spec.raw.convert(/float), $
    back:spec.back.convert(/float), $
    ftest:spec.ftest.convert(/float), $
    resh:spec.resh.convert(/float), $
    dof:spec.dof.convert(/float), $
    fbin:spec.fbin.convert(/float), $
    smth:spec.smth.convert(/float), $
    modl:spec.modl.convert(/float), $
    frpr:spec.frpr.convert(/float), $
    conf:spec.conf.convert(/float), $
    fconf:spec.fconf.convert(/float), $
    CKS:spec.CKS.convert(/float), $
    AIC:spec.AIC.convert(/float), $
    MERIT:spec.MERIT.convert(/float), $
    Ryk:spec.Ryk.convert(/float), $
    IyK:spec.Iyk.convert(/float), $
    psmooth:spec.psmooth.convert(/float), $
    muf:spec.muf.convert(/complex), $
    indback:spec.indback, $
    poor_MTM:spec.poor_MTM}
  ;
  spec = fspec
endif

if isa(peak, /array) then begin
  ;
  fpeak={ $
    ff:peak.ff.convert(/float), $
    pkdf:peak.pkdf.convert(/float)}
  ;
  peak = fpeak
  ;
endif

if isa(rshspec, /array) then begin
  ;
  fspec = { $
    ff:rshspec.ff.convert(/float), $
    raw:rshspec.raw.convert(/float), $
    back:rshspec.back.convert(/float), $
    ftest:rshspec.ftest.convert(/float), $
    resh:rshspec.resh.convert(/float), $
    dof:rshspec.dof.convert(/float), $
    fbin:rshspec.fbin.convert(/float), $
    smth:rshspec.smth.convert(/float), $
    modl:rshspec.modl.convert(/float), $
    frpr:rshspec.frpr.convert(/float), $
    conf:rshspec.conf.convert(/float), $
    fconf:rshspec.fconf.convert(/float), $
    CKS:rshspec.CKS.convert(/float), $
    AIC:rshspec.AIC.convert(/float), $
    MERIT:rshspec.MERIT.convert(/float), $
    Ryk:rshspec.Ryk.convert(/float), $
    IyK:rshspec.Iyk.convert(/float), $
    psmooth:rshspec.psmooth.convert(/float), $
    muf:rshspec.muf.convert(/complex), $
    indback:rshspec.indback, $
    poor_MTM:rshspec.poor_MTM}
  ;
  rshspec = fspec
endif

if isa(rshpeak, 'dblpeak') then begin
  ;
  fpeak={ $
    ff:rshpeak.ff.convert(/float), $
    pkdf:rshpeak.pkdf.convert(/float)}
  ;
  rshpeak = fpeak
  ;
endif

end