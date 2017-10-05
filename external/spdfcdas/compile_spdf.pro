;
; IDL_PATH needs to include the CDFX/CDAWlib source code.
;
@compile_cdfx

.compile spdfauthenticator__define.pro
.compile spdfcdas__define.pro
.compile spdfcdawebchooser.pro
.compile spdfcdawebchooserauthenticator__define.pro
.compile spdfcdfrequest__define.pro
.compile spdfcdasdatarequest__define.pro
.compile spdfcdasdataresult__define.pro
.compile spdfdatasetdescription__define.pro
.compile spdfdatasetlink__define.pro
.compile spdfdatasetrequest__define.pro
.compile spdfdataviewdescription__define.pro
.compile spdffiledescription__define.pro
.compile spdfgetdata.pro
.compile spdfgraphrequest__define.pro
.compile spdfhttperrordialog__define.pro
.compile spdfhttperrorreporter__define.pro
.compile spdfinstrumenttypedescription__define.pro
.compile spdfinventorydescription__define.pro
.compile spdfobservatorygroupdescription__define.pro
.compile spdftextrequest__define.pro
.compile spdfthumbnaildescription__define.pro
.compile spdftimeinterval__define.pro
.compile spdfvariabledescription__define.pro
.compile spdfcdaswsexample.pro

resolve_all, skip_routines=['NWIN', 'TVIMAGE', 'TWINSCOLORBAR']
save, /compress, description='CDFx with WSs', filename='cdfx.sav', /routines
exit

