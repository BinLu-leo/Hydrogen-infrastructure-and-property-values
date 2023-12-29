clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID.dta", clear
keep latitude longitude importparcelid propertyzip
duplicates drop
gen id = _n
order id importparcelid propertyzip latitude longitude
export delimited using "C:\Users\lubin\Desktop\Hy_housing\data\CA_house.csv", replace

import delimited "C:\Users\lubin\Desktop\AltFuels_rounds.csv", clear
keep id state hy_round hy hydrogen
keep if state == "CA"
drop if hy_round == 0
duplicates drop
sort id
rename id near_fid
save AltFuels_rounds.dta,replace

import delimited "C:\Users\lubin\Desktop\CA_house_AltFuels.csv", clear
rename from_x longitude
rename from_y latitude
drop near_x near_y oid in_fid
merge m:m near_fid using AltFuels_rounds.dta
drop if _merge == 2
drop state _merge
gen round_year = .
replace round_year = 2016 if hy_round == 1
replace round_year = 2017 if hy_round == 2
replace round_year = 2018 if hy_round == 3
replace round_year = 2019 if hy_round == 4
replace round_year = 2020 if hy_round == 5
replace round_year = 2021 if hy_round == 6
save CA_house_AltFuels.dta,replace

import delimited "C:\Users\lubin\Desktop\NatureGasgeodist.csv", clear
rename from_x longitude
rename from_y latitude
drop near_x near_y oid in_fid near_fid
save NatureGasgeodist.dta,replace

import delimited "C:\Users\lubin\Desktop\ProductionFacilitiesgeodist.csv", clear
rename from_x longitude
rename from_y latitude
drop near_x near_y oid in_fid near_fid
save ProductionFacilitiesgeodist.dta,replace


*******************************************************************************DistanceBin_lhprice_results_Production***
use "zillowCA_cleaned_control_DID.dta", clear
merge m:m longitude latitude using ProductionFacilitiesgeodist.dta

keep if _merge == 3
drop _merge
duplicates drop importparcelid date, force

keep if near_dist<=20000

xtset importparcelid date
egen month_year = group(month year)

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

forval i=500(500)15000 {
local j=`i'-500
gen byte vicinity_`i'=1 if near_dist <= `i' & near_dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}

drop post
gen post = 0
replace post = 1 if date >= open 

forval i=500(500)15000 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .
xtreg lhprice vicinitypost* post $control_variables i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(500 m/15000 with FE )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.5" 2 "1" 3 "1.5" 4 "2" 5 "2.5" 6 "3" 7 "3.5" 8 "4" 9 "4.5" 10 "5" 11 "5.5" 12 "6" 13 "6.5" 14 "7" 15 "7.5" 16 "8" 17 "8.5" 18 "9" 19 "9.5" 20 "10" 21 "10.5" 22 "11" 23 "11.5" 24 "12" 25 "12.5" 26 "13" 27 "13.5" 28 "14" 29 "14.5" 30 "15") ///
ytitle("Housing price (%)") xtitle("Distance from HPF (kilometers)") title("Change in housing prices with Hydrogen Production Facilities",size(medium)) subtitle("(with fixed effects)")
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\a_HydrogenProductionFacilities_distinceBin.gph", replace

xtreg lhprice vicinitypost* post $control_variables est i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(500 m/15000 with FE and est )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.5" 2 "1" 3 "1.5" 4 "2" 5 "2.5" 6 "3" 7 "3.5" 8 "4" 9 "4.5" 10 "5" 11 "5.5" 12 "6" 13 "6.5" 14 "7" 15 "7.5" 16 "8" 17 "8.5" 18 "9" 19 "9.5" 20 "10" 21 "10.5" 22 "11" 23 "11.5" 24 "12" 25 "12.5" 26 "13" 27 "13.5" 28 "14" 29 "14.5" 30 "15") ///
ytitle("Housing price (%)") xtitle("Distance from HPF (kilometers)") title("Change in housing prices with Hydrogen Production Facilities",size(medium)) subtitle("(with fixed effects and business patterns)")
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\b_HydrogenProductionFacilities_distinceBin.gph"

*combine graph
graph use "C:\Users\lubin\OneDrive\Hy_Housing\results\a_HydrogenProductionFacilities_distinceBin.gph"
graph combine "C:\Users\lubin\OneDrive\Hy_Housing\results\a_HydrogenProductionFacilities_distinceBin.gph" "C:\Users\lubin\OneDrive\Hy_Housing\results\b_HydrogenProductionFacilities_distinceBin.gph", ///
ycommon xsize(11) ysize(4) graphregion(color(white) icolor(white))
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\combine_HydrogenProductionFacilities_distinceBin.gph", replace

******************************************DID************************************
use "zillowCA_cleaned_control_DID.dta", clear
merge m:m longitude latitude using ProductionFacilitiesgeodist.dta

keep if _merge == 3
drop _merge
duplicates drop importparcelid date, force

keep if near_dist<=15000
xtset importparcelid date

egen month_year = group(month year)

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop treat post D
gen post = 0
replace post = 1 if date >= open
gen treat = 0
replace treat = 1 if near_dist <= 4500
gen D = treat*post

drop if est == .
xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(4500 m/15000 with FE and est )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DIDbuffer_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


drop treat post D
gen post = 0
replace post = 1 if date >= open
gen treat = 0
replace treat = 1 if near_dist <= 1500
gen D = treat*post

xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(1500 m/15000 with FE and est )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DIDbuffer_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


drop treat post D
gen post = 0
replace post = 1 if date >= open
gen treat = 0
replace treat = 1 if near_dist <= 2500
gen D = treat*post

xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(2500 m/15000 with FE and est )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DIDbuffer_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

drop treat post D
gen post = 0
replace post = 1 if date >= open
gen treat = 0
replace treat = 1 if near_dist <= 3500
gen D = treat*post

xtreg lhprice D treat post $control_variables est i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(3500 m/15000 with FE and est )
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DIDbuffer_lhprice_results_Production.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


*******************************************************************************DistanceBin_lhprice_results_Production***

*******************************************************************************DistanceBin_lhprice_results_AltFuels************
use "zillowCA_cleaned_control_DID.dta", clear
merge m:m longitude latitude using CA_house_AltFuels.dta
drop if _merge == 2

keep if near_dist<=2500

duplicates drop importparcelid date, force

xtset importparcelid date
egen month_year = group(month year)

drop post

forval i=100(100)2500 {
local j=`i'-100
gen byte vicinity_`i'=1 if near_dist <= `i' & near_dist>`j'
replace vicinity_`i'=0 if missing(vicinity_`i')
}

gen post = 0
replace post = 1 if date >= round_year 

forval i=100(100)2500 {
gen  vicinitypost`i'=vicinity_`i'*post 
}   

global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .
xtreg lhprice vicinitypost* post $control_variables i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(100 m/2500 with FE)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_HCP.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1.0" 11 "1.1" 12 "1.2" 13 "1.3" 14 "1.4" 15 "1.5" 16 "1.6" 17 "1.7" 18 "1.8" 19 "1.9" 20 "2.0" 21 "2.1" 22 "2.2" 23 "2.3" 24 "2.4" 25 "2.5") ///
ytitle("Housing price %") xtitle("kilometers") title("Change in housing prices with Alternative Fuel Corridors (Hydrogen)",size(medium)) subtitle("(with fixed effects)")
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\a_HCP_distinceBin.gph"


xtreg lhprice vicinitypost* post $control_variables est i.year i.month_year, fe robust cluster(fips) level(90)
eststo, title(100 m/2500 with FE and est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\DistanceBin_lhprice_results_HCP.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2*) nogaps line long r2 noomitted nonumbers noparentheses mtitles
coefplot, vertical keep(vicinitypost* )  yline(0)  xlabel(1 "0.1" 2 "0.2" 3 "0.3" 4 "0.4" 5 "0.5" 6 "0.6" 7 "0.7" 8 "0.8" 9 "0.9" 10 "1.0" 11 "1.1" 12 "1.2" 13 "1.3" 14 "1.4" 15 "1.5" 16 "1.6" 17 "1.7" 18 "1.8" 19 "1.9" 20 "2.0" 21 "2.1" 22 "2.2" 23 "2.3" 24 "2.4" 25 "2.5") ///
ytitle("Housing price %") xtitle("kilometers") title("Change in housing prices with Alternative Fuel Corridors (Hydrogen)",size(medium)) subtitle("(with fixed effects and business patterns)")
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\b_HCP_distinceBin.gph"

*combine graph
graph use "C:\Users\lubin\OneDrive\Hy_Housing\results\a_HCP_distinceBin.gph"
graph combine "C:\Users\lubin\OneDrive\Hy_Housing\results\a_HCP_distinceBin.gph" "C:\Users\lubin\OneDrive\Hy_Housing\results\b_HCP_distinceBin.gph", ///
ycommon xsize(11) ysize(4) graphregion(color(white) icolor(white))
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\combine_HCP_distinceBin.gph", replace

