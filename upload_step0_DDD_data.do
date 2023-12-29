clear all
set maxvar 120000
set matsize 11000
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

***** DDD
use "zillowCA_cleaned_control_DID.dta", clear
keep if dist<=5000
* locate the nearest electric station for each home
geonear transid latitude longitude using "elecstation.dta", n(elecstation_id latitude3 longitude3)
rename nid elecstation_id
rename km_to_nid elecdist
replace elecdist = elecdist*1000 //convert unit to meter
tabstat elecdist, statistics(mean n sd min q p90 max)

* merge station characteristics based on station_id
merge m:1 elecstation_id using elecstation, force
drop if _merge != 3
drop _merge

merge m:1 zip year using ca_all_covariates
drop if _merge == 2
drop _merge

save DDDdata_SFR_APT.dta, replace

***** DDD
use "zillowCA_cleaned_control_DID_county.dta", clear
keep if dist<=5000
* locate the nearest electric station for each home
geonear transid latitude longitude using "elecstation.dta", n(elecstation_id latitude3 longitude3)
rename nid elecstation_id
rename km_to_nid elecdist
replace elecdist = elecdist*1000 //convert unit to meter
tabstat elecdist, statistics(mean n sd min q p90 max)

* merge station characteristics based on station_id
merge m:1 elecstation_id using elecstation, force
drop if _merge != 3
drop _merge

merge m:1 fips year using hetero_covariates
drop if _merge == 2
drop _merge

save DDDdata_SFR_APT_county.dta, replace
