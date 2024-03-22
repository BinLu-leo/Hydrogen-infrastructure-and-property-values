clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

**** preprocess hydrostation data
insheet using "alt_fuel_stations_03022023_hydro.csv", clear
set more off

keep if state == "CA" // keep 116
rename id station_id
rename latitude latitude2
rename longitude longitude2

* convert date format
gen open=date(opendate, "YMD") 
format open %td
gen openyear=year(open)
gen openmonth=month(open)
tab openyear, m
drop if missing(open)			//keep 69
keep state zip station_id latitude2 longitude2 open openyear openmonth opendate

save hydrostation.dta, replace

keep state station_id latitude2 longitude2
reshape wide latitude2 longitude2, i(state) j(station_id)

save hydrostation_coor.dta, replace

**** preprocess elecstation data
insheet using "alt_fuel_stations_03022023_all.csv", clear
set more off

keep if state == "CA"
rename *, lower
tab fueltypecode
keep if fueltypecode == "ELEC"
rename id elecstation_id
rename latitude latitude3
rename longitude longitude3

* convert date format
rename opendate elecopendate
gen elecopen=date(elecopendate, "YMD") 
format elecopen %td
gen elecopenyear=year(elecopen)
gen elecopenmonth=month(elecopen)
tab elecopenyear, m
drop if missing(elecopen)
rename zip geozip
keep state geozip elecstation_id latitude3 longitude3 elecopen elecopenyear elecopenmonth elecopendate

save elecstation.dta, replace

**** preprocess sales number of hydrogen car at the zip-code level
insheet using sales_zip.csv, clear
rename *, lower
rename datayear year
rename zip geozip
gen str5 zipcode = string(geozip,"%05.0f")

save sales.dta, replace

**** preprocess the number of hydrogen station at the zip-code level
use hydrostation.dta, clear
rename zip geozip
gen str5 zipcode = string(geozip,"%05.0f")
gen n = 1
collapse (sum)n, by(geozip zipcode openyear)
rename openyear year
rename n hycs_num
xtset geozip year

save hycs.dta, replace

**** preprocess business establishments
use business_establishments.dta
drop zip
destring zipcode, gen(zip)
destring zipcode, gen(geozip)
keep if statename == "CA"
save CA_BE.dta, replace

**** preprocess CA covariates
use "ca_covariates.dta", clear
merge m:1 zip year using CA_BE
keep if _merge == 3
drop _merge

save ca_all_covariates.dta, replace

