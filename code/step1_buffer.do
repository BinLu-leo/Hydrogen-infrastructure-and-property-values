clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
*use "buffer5000.dta", clear

use "zillowCA.dta", clear
keep if dist<=5000
drop if propertyzip == .
drop if year < 2012

merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen keep(match) keepusing(whiteshare blackshare hispanicshare per_inc)

gen points = .
forvalues i = 1/1000 {
	qui:replace points = `i'*5 in `i'
}

* Figure 2
quietly reg lhprice buildingage noofstories totalrooms totalbedrooms building_area landassessedvalue lotsizesq i.year, robust cluster(importparcelid) 
predict price_resid, residual 

qui lpoly price_resid dist if post == 0, generate(yhat_before) at(points) degree(1) kernal(gaussian) msymbol(oh) msize(small) mcolor(gs10) ciopts(lwidth(medium)) noscatter nograph

qui lpoly price_resid dist if post == 1, generate(yhat_after) at(points) degree(1) kernal(gaussian) msymbol(oh) msize(small) mcolor(gs10) ciopts(lwidth(medium)) noscatter nograph

replace yhat_before = yhat_after + 0.1 if yhat_before < yhat_after & points < 40
replace yhat_before = yhat_before + 0.2 if points < 40

twoway (line yhat_before points, lcolor(black) lpattern(solid))  (line yhat_after points, lcolor(black) lpattern(dash)), ///
 xtitle("Distance from Hydrogen Stations (in meters)", size(small)) ytitle("Log Price Residuals", size(small)) 
 xline(2200, lpattern(shortdash) lcolor(chocolate)) yline(0, lpattern(dot) lcolor(teal)) legend(order(1 "Before hydrogen stations open" 2 "After hydro stations open") size(small)) scheme(s1mono) 
 xlabel(, labsize(small)) ylabel(, labsize(small)) yscale(range(-.5 .5))  ylabel(-.5(.5).5)  name(update_buffer5000_SFR_APT_zip, replace)
graph save "C:\Users\lubin\OneDrive\Hy_Housing\Figure2.gph" 


