clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g

use "zillowCA_data.dta", clear

keep if dist<=5000

gen treat = 0
replace treat = 1 if dist <= 2200
gen D = treat * post 

gen pscore = .
forvalues year=2012/2021 {
    logit treat buildingage totalbedrooms lotsizesquarefeet building_area if year == `year' 
    predict temp_pscore if year == `year', pr
    replace pscore = temp_pscore if year == `year'
    drop temp_pscore
}
gen matched=.
gen newtreated = .
gen newsupport = .
gen newpscore = .
gen newweight = .
global xlist buildingage totalbedrooms lotsizesquarefeet building_area
forvalues year=2012/2021 {
    psmatch2 treat $xlist if year == `year', neighbor(5) ate logit common out(lhprice)	
	replace matched=1 if _weight!=.
	replace newtreated = _treated if newtreated == .
	replace newsupport = _support if newsupport == .
	replace newpscore = _pscore if newpscore == .
	replace newweight = _weight if newweight == .
}
save "$path\psm_matched.dta", replace

use "$path\psm_matched.dta", clear
drop D
gen D = post * treat
egen month_year = group(month year)

******************************************************************************* Table S6
xtset importparcelid year
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc hispanicshare whiteshare blackshare"

xtreg lhprice D $control_variables i.year if matched == 1, fe robust cluster(importparcelid) level(95)

matrix results = J(2, 8, .)

xtreg lhprice D i.year if matched ==1, fe robust cluster(importparcelid) level(95)
	matrix results[1,1] = _b[D]
	matrix results[2,1] = _se[D]
	matrix results[1,5] = 2 * (1 - normal(abs(_b[D]/_se[D])))

xtreg lhprice D i.year i.propertyzip if matched ==1, fe robust cluster(importparcelid) level(95)
	matrix results[1,2] = _b[D]
	matrix results[2,2] = _se[D]
	matrix results[1,6] = 2 * (1 - normal(abs(_b[D]/_se[D])))

xtreg lhprice D $control_variables i.year i.propertyzip if matched ==1, fe robust cluster(importparcelid) level(95)
	matrix results[1,3] = _b[D]
	matrix results[2,3] = _se[D]
	matrix results[1,7] = 2 * (1 - normal(abs(_b[D]/_se[D])))
xtreg lhprice D $control_variables i.year i.propertyzip propertyzip#c.year if matched ==1, fe robust cluster(importparcelid) level(95)
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

export excel c1 c2 c3 c4 stars_c5 stars_c6 stars_c7 stars_c8 using "C:\Users\lubin\OneDrive\Hy_Housing\results\Robust_PSM_TWFEregression_results.xlsx", replace
drop c1-stars_c8


******************************************************************************* Fig. S10
psgraph, treated(newtreated) support(newsupport) pscore(newpscore) subtitle("Common support") name(commonsupport_SFR_APT, replace) 
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\common_support_SFR_APT.gph", replace


