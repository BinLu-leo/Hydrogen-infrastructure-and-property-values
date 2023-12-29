clear all
set maxvar 120000
set matsize 11000
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
set more off

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

* 使用fips-county级别的控制变量
import excel "C:\Users\lubin\Desktop\Hy_housing\data\ZIP-COUNTY-FIPS_2017-06.xlsx", sheet("ZIP-COUNTY-FIPS_2017-06") firstrow clear
rename *, lower
rename stcountyfp fips
rename zip propertyzip
keep if state == "CA"
* keep only one zip matched fips
sort propertyzip
by propertyzip: gen filter = _n
keep if filter == 1
save ZIPFIPS.dta, replace

*use ZIPFIPS.dta, clear
use "zillowCA_nocleaned.dta", clear
set more off

rename infozip propertyzip
merge m:1 propertyzip using ZIPFIPS.dta
keep if _merge ==3
drop _merge

* merge covariates
merge m:1 fips year using hetero_covariates.dta
keep if _merge ==3
drop _merge

* merge establishment
merge m:1 zip year using business_establishments.dta
drop if _merge == 2
drop _merge

save "zillowCA_nocleaned_control_county.dta", replace


*Dealing with houses in the zip area after 2012 where the treatment group had transaction records after the hydrogen refueling station was built but had no previous transaction records
use zillowCA_nocleaned_control_county.dta, clear

*drop if samples with a price difference greater than 10 times before and after the sale transaction
bys importparcelid: egen min = min(hp)
bys importparcelid: egen max = max(hp)
gen gap = (max/min >= 10)
drop if hp== min & gap == 1 
drop min max gap

gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post

keep  if dist < 5000
keep if year > 2011
keep if treat == 1
collapse (mean) hp, by (year propertyzip post)
reshape wide hp, i(year propertyzip) j(post)
keep if hp0 == .
keep propertyzip year
duplicates drop propertyzip year, force
gen treat_nomatch = 1
save "treat_nomatch.dta", replace


*Dealing with houses in the zip area after 2012 where the control group had transaction records after the hydrogen refueling station was built but had no previous transaction records.
use zillowCA_nocleaned_control_county.dta, clear

*drop if samples with a price difference greater than 10 times before and after the sale transaction
bys importparcelid: egen min = min(hp)
bys importparcelid: egen max = max(hp)
gen gap = (max/min >= 10)
drop if hp== min & gap == 1 			
drop min max gap

gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post

keep if dist < 5000
keep if year > 2011
keep if treat == 0
collapse (mean) hp, by (year propertyzip post)
reshape wide hp, i(year propertyzip) j(post)
keep if hp0 == .
keep propertyzip year
duplicates drop propertyzip year, force
gen control_nomatch = 1
save "control_nomatch.dta", replace

*After merging, remove samples that cannot correspond at the zip level.
use "zillowCA_nocleaned_control_county.dta", clear

*drop if samples with a price difference greater than 10 times before and after the sale transaction
bys importparcelid: egen min = min(hp)
bys importparcelid: egen max = max(hp)
gen gap = (max/min >= 10)
drop if hp== min & gap == 1
drop min max gap

gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post

merge m:1 propertyzip year using treat_nomatch.dta
drop if treat_nomatch == 1
drop _merge
merge m:1 propertyzip year using control_nomatch.dta
drop if control_nomatch == 1
drop _merge

save "zillowCA_nocleaned_control_filter.dta", replace

* repeated sales sample
bys importparcelid: gen repeatsale = _N
keep if repeatsale>1
drop repeatsale

rename incp per_inc
rename pop population
rename hispanic_share hispanicshare

save "zillowCA_cleaned_control_DID_county.dta", replace
