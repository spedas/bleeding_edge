This is a plugin for the GEO-KOMPSAT-2A satellite (geostationary orbit at 128.2 East).

It can download data from the ESA HAPI server. Four datasets are available:

1. recalib (recalibrated data from the SOSMAG magnetometer)
2. 1m (1minute real-time data from the SOSMAG magnetometer)
3. p (proton flux from the KSEM particle detector)
4. e (electron flux from the KSEM particle detector)

For more information about SOSMAG, see:
https://swe.ssa.esa.int/sosmag
https://link.springer.com/article/10.1007/s11214-020-00742-2

For summary plots, see:
https://themis.ssl.berkeley.edu/summary.php?year=2022&month=01&day=01&hour=0024&sumType=kompsat&type=kompsat



Update 2026-01-07:
Particle data is now available starting from 2021-02-01.
Magnetometer data is available starting from 2020-01-01.

Update 2026-03-19:
The ESA HAPI server requires registration.
To use KOMPSAT data from the ESA HAPI server, the user must do the following:

1. The user should register at: https://swe.ssa.esa.int/registration/
2. Then, the user should request an M2M client profile at the OIDC console: https://sso.s2p.esa.int/oidc-console/swe/
3. The user will receive a "Client ID" and a "secret key". 
	These should replace the temporary values of the variables "client_id" and "client_secret" 
	in the function get_esa_hapi_connection (file: check_esa_hapi_connection.pro).
	 

