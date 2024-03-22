clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

import delimited "C:\Users\lubin\Desktop\AltFuels_rounds.csv", clear
keep id state hy_round hy hydrogen
keep if state == "CA"
drop if hy_round == 0
duplicates drop
sort id
rename id near_fid
drop in 2
drop in 42
save AltFuels_rounds.dta,replace

import delimited "C:\Users\lubin\Desktop\Hy_housing\data\CA_house_GenerateNear_Geodist.csv", clear
rename from_x longitude
rename from_y latitude
drop near_x near_y oid in_fid
merge n:1 near_fid using AltFuels_rounds.dta
drop if _merge == 2
drop _merge
gen round_year = .
replace round_year = 2016 if hy_round == 1
replace round_year = 2017 if hy_round == 2
replace round_year = 2018 if hy_round == 3
replace round_year = 2019 if hy_round == 4
replace round_year = 2020 if hy_round == 5
replace round_year = 2021 if hy_round == 6
save CA_house_AltFuels.dta,replace

import delimited "C:\Users\lubin\Desktop\ProductionFacilitiesgeodist.csv", clear
rename from_x longitude
rename from_y latitude
drop near_x near_y oid in_fid near_fid
save ProductionFacilitiesgeodist.dta,replace


******************************************************************************* Fig. 3
use "zillowCA.dta", clear

merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)

merge m:m longitude latitude using ProductionFacilitiesgeodist.dta
keep if _merge == 3
drop _merge
duplicates drop importparcelid date, force

gen post = 0
replace post = 1 if date >= open 

keep if near_dist<=10000
//drop vicinity*
forval i=1000(1000)10000 {
local j=`i'-1000
gen byte vicinity_`i'=1 if near_dist <= `i' & near_dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}
forval i=1000(1000)10000 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   
xtreg lhprice vicinitypost* post $control_variables i.year, fe robust cluster(importparcelid) level(95)
#delimit ;
	coefplot, vertical keep(vicinitypost*)  
	graphregion(color(white))
    yline(0, lp(dot) lc(gs0) lw(thin)) 
	xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10", labsize(medsmall) nogrid) 
	ylabel(-0.2(0.1)0.1, nogrid) 
	ytitle("Housing price (%)") 
	xtitle("Distance from HPFs (Kilometers)") 
	title("Change in housing prices with hydrogen production facilities", size(medium) color(black)) 
	subtitle("(with fixed effects)")
;
#delimit cr
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\Figure3.gph", replace

******************************************************************************* Table S3
xtreg lhprice vicinitypost* post i.year, fe robust cluster(importparcelid) level(95)
eststo, title((1))
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(post 2*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice vicinitypost* post i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
eststo, title(+ zip FEs)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(post 2* 9*) nogaps line long r2 nonumbers noparentheses mtitles

xtreg lhprice vicinitypost* post $control_variables i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
eststo, title(+ covariates)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(post 2* 9*) nogaps line long r2 nonumbers noparentheses mtitles

******************************************************************************* Figure S4
drop vicinity*
forval i=500(500)10000 {
local j=`i'-500
gen byte vicinity_`i'=1 if near_dist <= `i' & near_dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}
forval i=500(500)10000 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   
xtreg lhprice vicinitypost* post $control_variables i.year, fe robust cluster(importparcelid) level(95)
eststo, title(500m/10000 with FE )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(95) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
#delimit ;
	coefplot, vertical keep(vicinitypost*)  
	graphregion(color(white))
    yline(0, lp(dot) lc(gs0) lw(thin)) 
	xlabel(1 "0.5" 2 "1" 3 "1.5" 4 "2" 5 "2.5" 6 "3" 7 "3.5" 8 "4" 9 "4.5" 
	10 "5" 11 "5.5" 12 "6" 13 "6.5" 14 "7" 15 "7.5" 16 "8" 17 "8.5" 18 "9" 
	19 "9.5" 20 "10", labsize(medsmall) nogrid) 
	ylabel(-0.2(0.1)0.1, nogrid) 
	ytitle("Housing price (%)") 
	xtitle("Distance from HPFs (Kilometers)") 
	title("Change in housing prices with hydrogen production facilities", size(medium) color(black)) 
	subtitle("(with fixed effects)")
;
#delimit cr
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\FigureS4.gph", replace

******************************************************************************* Table S4
drop treat D
gen treat =0
replace treat =1 if near_dist <= 4000
gen D = treat * post 

gen other_race = 100 - whiteshare - hispanicshare - blackshare
sum hp lhprice year buildingage population per_inc whiteshare hispanicshare blackshare other_race if treat == 0
sum hp lhprice year buildingage population per_inc whiteshare hispanicshare blackshare other_race if treat == 1
sum hp lhprice year buildingage population per_inc whiteshare hispanicshare blackshare other_race

*************************************************************** Table 1
xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"


matrix results = J(2, 8, .)
sum lhprice

qui xtreg lhprice D i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.propertyzip propertyzip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[D]
	matrix results[2,4] = _se[D]
	matrix results[1,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))

matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1  
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionProduction_results.xlsx", replace
drop c1-stars_c8

******************************************************************************* Table S15
use "zillowCA.dta", clear
merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)
merge m:m longitude latitude using ProductionFacilitiesgeodist.dta
keep if _merge == 3
drop _merge
duplicates drop importparcelid date, force

gen post = 0
replace post = 1 if date >= open 
keep if near_dist<=10000

drop treat D
gen treat =0
replace treat =1 if near_dist <= 4000
gen D = treat * post 

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if date > date("2020-03-11", "YMD")

matrix results = J(2, 8, .)
sum lhprice

qui xtreg lhprice D i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.propertyzip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.propertyzip propertyzip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[D]
	matrix results[2,4] = _se[D]
	matrix results[1,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))

matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1  
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionProduction_results_dropCovid19.xlsx", replace
drop c1-stars_c8


******************************************************************************* Table 2
use "zillowCA.dta", clear
merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)
merge m:m longitude latitude using ProductionFacilitiesgeodist.dta
keep if _merge == 3
drop _merge
duplicates drop importparcelid date, force

gen HPFpost = 0
replace HPFpost = 1 if date >= open 
gen HPFtreat =0
replace HPFtreat = 1 if near_dist <= 3000
gen explosion = "20190601"
gen explosiondate=date(explosion, "YMD") 
format explosiondate %td
gen explosion_post = 0
replace explosion_post = 1 if date >= explosiondate

gen D = HPFtreat * HPFpost
gen D1 = HPFtreat * explosion_post
gen D2 = HPFpost * explosion_post
gen DDD = explosion_post * HPFpost * HPFtreat

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc hispanicshare whiteshare blackshare"

matrix results = J(4, 8, .)
sum lhprice
sum lhprice if near_dist <= 1000
sum lhprice if near_dist <= 4000

qui xtreg lhprice DDD D1 D2 D HPFtreat HPFpost explosion_post i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[DDD]
	matrix results[2,1] = _se[DDD]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[DDD]/_se[DDD])))	
	matrix results[3,1] = _b[D]
	matrix results[4,1] = _se[D]
	matrix results[3,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))	

qui xtreg lhprice DDD D1 D2 D HPFtreat HPFpost explosion_post i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[DDD]
	matrix results[2,2] = _se[DDD]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[DDD]/_se[DDD])))
	matrix results[3,2] = _b[D]
	matrix results[4,2] = _se[D]
	matrix results[3,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice DDD D1 D2 D HPFtreat HPFpost explosion_post $control_variables i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[DDD]
	matrix results[2,3] = _se[DDD]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[DDD]/_se[DDD])))
	matrix results[3,3] = _b[D]
	matrix results[4,3] = _se[D]
	matrix results[3,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))	

qui xtreg lhprice DDD D1 D2 D HPFtreat HPFpost explosion_post $control_variables i.year i.zip zip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[DDD]
	matrix results[2,4] = _se[DDD]
	matrix results[1,8] = 2 * (1 - normal(abs(_b[DDD]/_se[DDD])))
	matrix results[3,4] = _b[D]
	matrix results[4,4] = _se[D]
	matrix results[3,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))	

matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1  
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionDDD_explosion_HPFs_results.xlsx", replace
drop c1-stars_c8


*******************************************************************************DistanceBin_lhprice_results_AltFuels************
use "zillowCA.dta", clear
merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)
merge m:m longitude latitude using CA_house_AltFuels.dta
drop if _merge == 2
duplicates drop importparcelid date, force

keep if near_dist<=3000

drop post
gen post = 0
replace post = 1 if date >= round_year 

******************************************************************************* Fig. S9
drop vicinity*
forval i=200(200)3000 {
local j=`i'-200
gen byte vicinity_`i'=1 if near_dist <= `i' & near_dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}
forval i=200(200)3000 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

xtreg lhprice vicinitypost* post $control_variables i.year, fe robust cluster(importparcelid) level(95)
#delimit ;
	coefplot, vertical keep(vicinitypost*)  
	graphregion(color(white))
    yline(0, lp(dot) lc(gs0) lw(thin)) 
	xlabel(1 "0.2" 2 "0.4" 3 "0.6" 4 "0.8" 5 "1.0" 6 "1.2" 7 "1.4" 8 "1.6" 
		9 "1.8" 10 "2.0" 11 "2.2" 12 "2.4" 13 "2.6" 14 "2.8" 15 "3.0", labsize(medsmall) nogrid) 
	ylabel(-1.5(0.5)1.5, nogrid) 
	ytitle("Housing price (%)") 
	xtitle("Distance from HCPs (Kilometers)") 
	title("Change in housing prices with Alternative Fuel Corridors (Hydrogen)", size(medium) color(black)) 
	subtitle("(with fixed effects)")
;
#delimit cr
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\HydrogenCorridorsPipelines_distinceBin.gph", replace


******************************************************************************* Table S4
gen treat =0
replace treat =1 if near_dist <= 1400
gen D = treat * post 

gen other_race = 100 - whiteshare - hispanicshare - blackshare
sum hp lhprice year buildingage population per_inc whiteshare hispanicshare blackshare other_race if treat == 0
sum hp lhprice year buildingage population per_inc whiteshare hispanicshare blackshare other_race if treat == 1
sum hp lhprice year buildingage population per_inc whiteshare hispanicshare blackshare other_race

******************************************************************************* Table 1
matrix results = J(2, 8, .)
sum lhprice

qui xtreg lhprice D i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.zip zip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[D]
	matrix results[2,4] = _se[D]
	matrix results[1,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))
	
matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1 
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionPipeline_results.xlsx", replace
drop c1-c4


******************************************************************************* Table S15
use "zillowCA.dta", clear
merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)
merge m:m longitude latitude using CA_house_AltFuels.dta
drop if _merge == 2
duplicates drop importparcelid date, force

keep if near_dist<=3000

gen treat =0
replace treat =1 if near_dist <= 1400
gen D = treat * post 
drop post
gen post = 0
replace post = 1 if date >= round_year 

drop if date > date("2020-03-11", "YMD")

matrix results = J(2, 8, .)
sum lhprice

qui xtreg lhprice D i.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.zip, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))

qui xtreg lhprice D $control_variables i.year i.zip zip#c.year, fe robust cluster(importparcelid) level(95)
	matrix results[1,4] = _b[D]
	matrix results[2,4] = _se[D]
	matrix results[1,8] = 2 * (1 - normal(abs(_b[D]/_se[D])))

matrix list results

svmat results, names(col)

foreach var in c5 c6 c7 c8 {
    local v `var'
    gen pval = `v'
    gen stars = ""
    replace stars = "***" if pval < 0.01
    replace stars = "**" if pval >= 0.01 & pval < 0.05
    replace stars = "*" if pval >= 0.05 & pval < 0.1
    drop pval
    replace `v' = . if `v' >= 0.1  
    rename stars stars_`v'
}

export excel c1 c2 c3 c4 using "C:\Users\lubin\OneDrive\Hy_Housing\results\TWFEregressionPipeline_results_dropCovid19.xlsx", replace
drop c1-c4