clear all
set maxvar 120000
set matsize 11000
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
set more off

***** preprocess est data
use business_establishments.dta, clear
rename zip propertyzip
save business_establishments_zip.dta, replace

***** preprocess zillow data
use trans_asmt.dta, clear

*keep if strmatch(propertylandusestndcode, "*RI*") | strmatch(propertylandusestndcode, "*RR*")
keep if strmatch(propertylandusestndcode, "RR101")

destring, replace
rename *, lower

* locate the nearest hydro station for each home
geonear transid latitude longitude using "hydrostation.dta", n(station_id latitude2 longitude2)
rename nid station_id
rename km_to_nid dist
replace dist = dist*1000 //convert unit to meter
tabstat dist, statistics(mean n sd min q p90 max)

* merge station characteristics based on station_id
merge m:1 station_id using hydrostation
drop if _merge != 3
drop _merge
save zillowCA_nocleaned.dta, replace

use zillowCA_nocleaned.dta, clear
* merge covariates
merge m:1 zip year using ca_all_covariates
drop if _merge == 2
drop _merge

rename infozip propertyzip
save "zillowCA_nocleaned_control.dta", replace

* Processing of houses in the zip area that have transaction records after the construction of the hydrogen refueling station but no previous transaction records
use zillowCA_nocleaned_control_county.dta, clear  

*drop if samples with a price difference greater than 10 times before and after the sale transaction
bys importparcelid: egen min = min(hp)
bys importparcelid: egen max = max(hp)
gen gap = (max/min >= 10)
drop if hp== min & gap == 1
drop min max gap

gen post = 0
replace post = 1 if date >= open 

keep  if dist < 5000
keep if year > 2011
keep if treat == 1
collapse (mean) hp, by (year propertyzip post)
reshape wide hp, i(year propertyzip) j(post)
keep if hp0 == .
keep propertyzip year
duplicates drop propertyzip year, force
gen nomatch = 1
save "nomatch.dta", replace

*Remove samples that cannot be matched at the zip level after merging
use "zillowCA_nocleaned_control_county.dta", clear
*drop if samples with a price difference greater than 10 times before and after the sale transaction
bys importparcelid: egen min = min(hp)
bys importparcelid: egen max = max(hp)
gen gap = (max/min >= 10)
drop if hp== min & gap == 1
drop min max gap

gen post = 0
replace post = 1 if date >= open 

merge m:1 propertyzip year using nomatch.dta
drop if nomatch == 1
drop _merge

* repeated sales sample
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1
drop repeatsale

save "zillowCA_data.dta", replace