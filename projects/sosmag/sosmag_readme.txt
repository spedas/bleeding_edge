This plugin can access SOSMAG data using the ESA HAPI server https://swe.ssa.esa.int/hapi/
Requires IDL 8.5 or later.

Each user needs to register on the above web site and create a username and a password. 
The username and password should be saved in the file sosmag_password.txt as clear text like this:

username=spedas
password=aGb4kg65pGf9Bh2

It also requires write access to the file session_cookies.txt in this directory. This file
will receive the responses from the ESA web server. 

Then the data can be accessed either using the SPEDAS GUI or using the command line function:

sosmag_hapi_load_data, trange=trange, dataset=dataset, recalib=recalib, tplotnames=tplotvars, prefix=prefix

All the keywords for the above function have default values, 
so it can be tested by simply typing the name of the function without any keywords:

sosmag_hapi_load_data



For more information about SOSMAG, see:
https://swe.ssa.esa.int/sosmag
https://link.springer.com/article/10.1007/s11214-020-00742-2
