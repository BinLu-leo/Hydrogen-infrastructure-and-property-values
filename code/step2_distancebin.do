clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g
set more off

use "zillowCA_data.dta", clear
merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)
keep if dist<=5000

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop post
gen post = 0
replace post = 1 if date >= open 

//drop vicinity*
gen vicinity = 0
forval i=200(400)5400 {
local j=`i'-400 
gen byte vicinity_`i'=1 if dist <= `i' & dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}
forval i=200(400)5400 {
gen  vicinitypost`i'=vicinity_`i'*post 
}
xtreg lhprice_update vicinitypost* post $control_variables i.year, fe robust cluster(importparcelid) level(95)
#delimit ;
	coefplot, vertical keep(vicinitypost*)  
	graphregion(color(white))
    yline(0, lp(dot) lc(gs0) lw(thin)) 
	xlabel(1 "0.2"  2 "0.6"  3 "1.0"  4 "1.4"  5 "1.8"  6 "2.2"  7 "2.6"  
	8 "3.0"  9 "3.4"  10 "3.8"  11 "4.2"  12 "4.6"  13 "5.0", labsize(medsmall) nogrid) 
	ylabel(-0.15(0.05)0.1, nogrid) 
	ytitle("Housing price (%)") 
	xtitle("Distance from HRSs (Kilometers)") 
	title("Change in housing prices with hydrogen refueling stations", size(medium) color(black)) 
	subtitle("(with fixed effects)")
;
#delimit cr
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\Figure3_vicinity5000a.gph", replace

drop vicinity*
gen vicinity = 0
forval i=200(200)5000 {
local j=`i'-200 
gen byte vicinity_`i'=1 if dist <= `i' & dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}
forval i=200(200)5000 {
gen  vicinitypost`i'=vicinity_`i'*post 
}

xtreg lhprice_update vicinitypost* post $control_variables i.year, fe robust cluster(importparcelid) level(95)
#delimit ;
	coefplot, vertical keep(vicinitypost*)  
	graphregion(color(white))
    yline(0, lp(dot) lc(gs0) lw(thin)) 
	xlabel(1 "0.2" 2 "0.4" 3 "0.6" 4 "0.8" 5 "1.0" 6 "1.2" 7 "1.4" 8 "1.6" 
	9 "1.8" 10 "2.0" 11 "2.2" 12 "2.4" 13 "2.6" 14 "2.8" 15 "3.0" 16 "3.2" 
	17 "3.4" 18 "3.6" 19 "3.8" 20 "4.0" 21 "4.2" 22 "4.4" 23 "4.6" 24 "4.8" 
	25 "5.0", labsize(small) nogrid) 
	ylabel(-0.15(0.05)0.1, nogrid) 
	ytitle("Housing price (%)") 
	xtitle("Distance from HRSs (Kilometers)") 
	title("Change in housing prices with hydrogen refueling stations", size(medium) color(black)) 
	subtitle("(with fixed effects)")
;
#delimit cr
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\update_vicinity5000b.gph", replace

**Table S2
xtreg lhprice_update vicinitypost* post i.year, fe robust cluster(importparcelid) level(95)
eststo, title((1))
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(post 2*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice_update vicinitypost* post i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
eststo, title(+ zip FEs)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\update_distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(post 2* 9*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice_update vicinitypost* post $control_variables i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
eststo, title(+ covariates)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\update_distance5000.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(post 2* 9*) nogaps line long r2 nonumbers noparentheses mtitles



