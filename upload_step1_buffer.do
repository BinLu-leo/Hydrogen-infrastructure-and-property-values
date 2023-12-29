clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
*use "buffer1000.dta", clear
*use "zillowCA_cleaned_control_DID_zip.dta", clear
use "zillowCA_cleaned_control_DID_county.dta", clear

keep if dist<=5000

set more off

tab openyear, m
tab year, m

drop if propertyzip == .
drop if year < 1989

egen zip_year = group(propertyzip year)
egen month_year = group(month year)

*rename building_area buildingareasqft
foreach n in yearbuilt buildingareasqft lotsizesquarefeet{
replace `n'=. if `n'==0
}

gen points = .
forvalues i = 1/1000 {
	qui:replace points = `i'*5 in `i'
}

* 1. buffer

quietly reg lhprice buildingage noofstories totalrooms totalbedrooms building_area landassessedvalue lotsizesq i.year, robust cluster(importparcelid) 
predict price_resid, residual 

qui lpoly price_resid dist if post == 0, generate(yhat_before) at(points) degree(1) kernal(gaussian) msymbol(oh) msize(small) mcolor(gs10) ciopts(lwidth(medium)) noscatter nograph

qui lpoly price_resid dist if post == 1, generate(yhat_after) at(points) degree(1) kernal(gaussian) msymbol(oh) msize(small) mcolor(gs10) ciopts(lwidth(medium)) noscatter nograph

twoway (line yhat_before points, lcolor(black) lpattern(solid))  (line yhat_after points, lcolor(black) lpattern(dash)), /*
*/ xtitle("Distance from Hydrogen Stations (in meters)", size(small)) ytitle("Log Price Residuals", size(small)) /*
*/ xline(2200, lpattern(shortdash) lcolor(chocolate)) yline(0, lpattern(dot) lcolor(teal)) legend(order(1 "Before hydrogen stations open" 2 "After hydro stations open") size(small)) scheme(s1mono) /*
*/ xlabel(, labsize(small)) ylabel(, labsize(small)) yscale(range(-.5 .5))  ylabel(-.5(.5).5)  name(buffer5000_SFR_APT_county, replace)
graph save "buffer5000_SFR_APT_county" 

"C:\Users\lubin\OneDrive\Hy_Housing\results\buffer5000_SFR_APT_county.gph"
