clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
set more off

set maxvar 120000
set matsize 11000

use trans_asmt.dta, clear
*keep if strmatch(propertylandusestndcode, "*RI*") | strmatch(propertylandusestndcode, "*RR*")
keep if strmatch(propertylandusestndcode, "RR101")
gen n = _n

tab year, m
* 1. properties that have been sold more than once
bys importparcelid: gen n_import = _N
bys importparcelid transid: gen n_trans = _N
keep if n_import > n_trans
drop n_import n_trans

///sample is too large, so cut it to subsample
savesome if n<=1000000 using RR101_1.dta, replace
savesome if n>1000000 & n<=2000000 using RR101_2.dta, replace
savesome if n>2000000 & n<=3000000 using RR101_3.dta, replace
savesome if n>3000000 & n<=4000000 using RR101_4.dta, replace
savesome if n>4000000 & n<=5000000 using RR101_5.dta, replace
savesome if n>6000000 using RR101_6.dta, replace

* 2. with at least one sale starting after the open date of only one station within `n' km
** 2.1 properties that have only one hydro station within `n' km
*** 2.1.1 obtain coordinates of hydro stations
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

local filenames: dir . files "RR101_*.dta"

foreach i of local filenames{
	use `i', clear
	drop n
	
	merge m:1 state using hydrostation_coor
	keep if _merge ==3
	drop _merge
	
	keep transid latitude longitude latitude221796-longitude2224715
	
	*** 2.1.2 convert to desired data pattern--one transid with all sites info
	reshape long latitude2 longitude2, i(transid) j(station_id)
	local filename1 = "step0_buffer_reshape" + "`i'"
	save `filename1', replace //it takes a lof of time
	
	*** 2.1.3 calculate distance between houses and each hycs facilities
	geodist latitude longitude latitude2 longitude2, gen(dist)
	local filename2 = "step0_buffer_reshape_geodist" + "`i'"
	save `filename2', replace //it takes a lof of time
}

clear
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
* merge all dta
filesearch step0_buffer_reshape_geodist*.dta
append using `r(filenames)'
save "step0_buffer_reshape_geodist_only.dta", replace

use "step0_buffer_reshape_geodist_only.dta", clear
merge m:1 transid using trans_asmt
drop if _merge != 3
drop _merge
save "step0_buffer_reshape_geodist.dta", replace

/*
bys importparcelid: egen min = min(hp)
bys importparcelid: egen max = max(hp)
gen gap = (max/min >= 10)
drop if hp== min & gap == 1
drop min max gap
*/

clear
foreach n in 1 2 3 4 5 6{
use "C:\Users\lubin\Desktop\Hy_housing\data\step0_buffer_reshape_geodist.dta", clear
replace dist = dist*1000 //convert unit to meter	
	
*** 2.1.4 keep properties that have only one hydro station within `n' km
gen v`n' = (dist <= `n'000)
bys transid: egen sum`n' = sum(v`n') 
*sum`n'=1 meaning there is only one hydro station within `n' km 
keep if sum`n'==1 & v`n' == 1
drop v`n' sum`n'

* merge station characteristics based on station_id
merge m:1 station_id using hydrostation
drop if _merge != 3
drop _merge

** 2.2 properties with at least one sale after the open date of hydro station
gen post = 0
replace post = 1 if date >= open 
bys importparcelid: egen sumpost = sum(post)
drop if sumpost < 1
drop sumpost

rename infozip propertyzip
gen str5 zipcode = string(propertyzip,"%05.0f")

tabstat dist, statistics(mean n sd min q p90 max)

save buffer`n'000.dta, replace
}

