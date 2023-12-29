clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000

use "zillowCA_cleaned_control_DID.dta", clear
keep if dist < 5000

collapse dist hp (first)open, by (geozip year month date)
*rename propertyzip geozip

gen lhprice = ln(hp)
merge m:1 geozip year using ca_all_covariates
keep if _merge == 3
drop _merge

xtset geozip date
tsfill, full
gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post 

tab year,gen(yr)
tab month,gen(mth)

save "hetero_zip_date.dta", replace

* per_inc
clear all
use "hetero_zip_date.dta", clear

sum per_inc
sum per_inc, detail
xtplfc lhprice population est whiteshare yr1-mth12, zvars(D) uvars(per_inc) gen(coef)

bysort per_inc:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save per_inc.dta,replace

use per_inc.dta, clear
twoway (rarea h95ci l95ci per_inc, sort color(gs15)) line coef_1 per_inc, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Income Per Capita ($)") yline(0, lpattern(solid) lcolor(teal)) ///
xline(43499.5, lpattern(dash) lcolor(gray)) ///
text(.5 61000 "Sample median: 43499.5",size(Small)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
scheme(s1mono) name(per_inc, replace)
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\per_inc.gph", replace
*graph export "C:/phd4/CAhydro/results/per_inc.svg", as(svg) name("per_inc") replace

* population
clear all
use "hetero_zip_date.dta", clear

sum population
xtplfc lhprice per_inc est whiteshare yr1-mth12, zvars(D) uvars(population) gen(coef)

bysort population:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save population.dta,replace

use population.dta, clear
twoway (rarea h95ci l95ci population, sort color(gs15)) line coef_1 population, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Population") yline(0, lpattern(solid) lcolor(teal)) ///
xline(38609.6, lpattern(dash) lcolor(gray)) ///
text(.2 60000 "Sample mean: 38609.6",size(Small)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
scheme(s1mono) name(population, replace)
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\population.gph", replace
*graph export "C:/phd4/CAhydro/results/population.svg", as(svg) name("population") replace

* whiteshare
clear all
use "hetero_zip_date.dta", clear

sum whiteshare
xtplfc lhprice population est per_inc yr1-mth12, zvars(D) uvars(whiteshare) gen(coef)

bysort whiteshare:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save whiteshare.dta,replace

use whiteshare.dta, clear
twoway (rarea h95ci l95ci whiteshare, sort color(gs15)) line coef_1 whiteshare, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("White share (%)") yline(0, lpattern(solid) lcolor(teal)) ///
xline(61.34, lpattern(dash) lcolor(gray)) ///
text(-.05 80 "Sample mean: 61.34",size(Small)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
scheme(s1mono) name(whiteshare, replace)
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\whiteshare.gph", replace
*graph export "C:/phd4/CAhydro/results/whiteshare.svg", as(svg) name("whiteshare") replace

* est
clear all
use "hetero_zip_date.dta", clear

sum est
xtplfc lhprice population per_inc whiteshare yr1-mth12, zvars(D) uvars(est) gen(coef)

bysort est:gen n=_n
keep if n==1
gen h95ci= coef_1 +1.96*coef_1_sd
gen l95ci= coef_1 -1.96*coef_1_sd
save est.dta,replace

use est.dta, clear
twoway (rarea h95ci l95ci est, sort color(gs15)) line coef_1 est, lpattern(solid) lcolor(gray)  ///
ytitle("Housing price %") xtitle("Business establishments") yline(0, lpattern(solid) lcolor(teal)) ///
xline(1282.74, lpattern(dash) lcolor(gray)) ///
text(.5 2100 "Sample mean: 1282.74",size(Small)) ///
legend(size(vsmall) order(2 "Point estimates" 1 "95% CI")) ///
scheme(s1mono) name(est, replace)
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\est.gph", replace
*graph export "C:/phd4/CAhydro/results/est.svg", as(svg) name("est") replace

cd "C:\Users\lubin\OneDrive\Hy_Housing\results"
grc1leg per_inc.gph population.gph whiteshare.gph est.gph, legendfrom(per_inc.gph)
graph save "hetero_all.gph", replace
*graph export "hetero_all.svg", as(svg) name("Graph") replace
