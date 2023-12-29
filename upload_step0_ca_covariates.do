// covariates
****************************************
{*** covariates
** income and population data
* income

cd "C:\Users\lubin\OneDrive\Hy_Housing\data\CAincome_ACSDP03_2012_2021"
local filenames: dir . files "*.csv"

foreach i of local filenames{

import delimited using `i', encoding(utf8) clear varnames(1)
        
keep if labelgrouping == "    Per capita income (dollars)"
drop *percent
rename zcta5*estimate zcta*
reshape long zcta, i(labelgrouping) j(zip)
destring zcta, gen(per_inc) ignore(",-N")

gen year = substr("`i'", 8,4)
drop labelgrouping

local filename = "incY" + year
save "`filename'.dta", replace
}

* merge all dta
filesearch incY*.dta
append using `r(filenames)'
destring year, replace
sort zip year
duplicates drop
save "incYall.dta", replace

*******************************************************************************
* population

cd "C:\Users\lubin\OneDrive\Hy_Housing\data\CApop_ACSDP05_2012_2021"
local filenames: dir . files "*.csv"

foreach i of local filenames{

import delimited using `i', encoding(utf8) clear varnames(1)
        
keep if labelgrouping == "    Total population"
keep in 1
drop *percent
rename zcta5*estimate zcta*
destring zcta*, replace ignore(",-N")
reshape long zcta, i(labelgrouping) j(zip)
rename zcta population

gen year = substr("`i'", 8,4)
drop labelgrouping

local filename = "popY" + year
save "`filename'.dta", replace
}

* merge all dta
filesearch popY*.dta
append using `r(filenames)'
destring year, replace
sort zip year
duplicates drop
save "popYall.dta", replace

*******************************************************************************
** white(%)
cd "C:\Users\lubin\OneDrive\Hy_Housing\data\CApop_ACSDP05_2012_2021"
local filenames: dir . files "*.csv"

foreach i of local filenames{

import delimited using `i', encoding(utf8) clear varnames(1)
        
keep if labelgrouping == "        White"
drop *estimate
rename zcta5*percent zcta*
reshape long zcta, i(labelgrouping) j(zip)
destring zcta, gen(whiteshare) ignore(",-N%")

gen year = substr("`i'", 8,4)
drop labelgrouping zcta

local filename = "whiteshareY" + year
save "`filename'.dta", replace
}

* merge all dta
filesearch whiteshareY*.dta
append using `r(filenames)'
destring year, replace
sort zip year
duplicates drop
save "whiteshareYall.dta", replace

*******************************************************************************
** black(%)
cd "C:\Users\lubin\OneDrive\Hy_Housing\data\CApop_ACSDP05_2012_2021"
local filenames: dir . files "*.csv"

foreach i of local filenames{

import delimited using `i', encoding(utf8) clear varnames(1)
        
keep if labelgrouping == "        Black or African American"
drop *estimate
rename zcta5*percent zcta*
reshape long zcta, i(labelgrouping) j(zip)
destring zcta, gen(blackshare) ignore(",-N%")

gen year = substr("`i'", 8,4)
drop labelgrouping zcta

local filename = "blackshareY" + year
save "`filename'.dta", replace
}

* merge all dta
filesearch blackshareY*.dta
append using `r(filenames)'
destring year, replace
sort zip year
duplicates drop
save "blackshareYall.dta", replace

*******************************************************************************
** hispanic_share (%)
cd "C:\Users\lubin\OneDrive\Hy_Housing\data\CApop_ACSDP05_2012_2021"
local filenames: dir . files "*.csv"

foreach i of local filenames{

import delimited using `i', encoding(utf8) clear varnames(1)
        
keep if labelgrouping == "        Hispanic or Latino (of any race)"
drop *estimate
rename zcta5*percent zcta*
reshape long zcta, i(labelgrouping) j(zip)
destring zcta, gen(hispanicshare) ignore(",-N%")

gen year = substr("`i'", 8,4)
drop labelgrouping zcta

local filename = "hispanicshareY" + year
save "`filename'.dta", replace
}

* merge all dta
filesearch hispanicshareY*.dta
append using `r(filenames)'
destring year, replace
sort zip year
duplicates drop
save "hispanicshareYall.dta", replace
}
*******************
*"incYall.dta"+"popYall.dta"+"whiteshareYall.dta"+"blackshareYall.dta"+"hispanicshareYall.dta"

cd "C:\Users\lubin\OneDrive\Hy_Housing\data\CApop_ACSDP05_2012_2021"
mergemany 1:1 "popYall" "whiteshareYall" "blackshareYall" "hispanicshareYall" "C:\Users\lubin\OneDrive\Hy_Housing\data\CAincome_ACSDP03_2012_2021/incYall", match(zip year) 
sort zip year
drop zcta

bysort zip: egen zipcount=count(zip)
drop if zipcount< 10
keep if zip >90000
tab year
save "C:\Users\lubin\Desktop\Hy_housing\data\ca_covariates.dta", replace
