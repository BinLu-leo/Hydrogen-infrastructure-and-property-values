clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g

use zillowCA_cleaned_control_DID_county.dta, clear

keep if dist <= 5000
drop if year < 1998
drop treat
gen treat =0
replace treat =1 if dist <= 2200

*Period-by-period matching
gen pscore = .
forvalues year=1998/2021 {
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

forvalues year=1998/2021 {
    psmatch2 treat $xlist if year == `year', neighbor(5) ate logit common out(lhprice)
	
	replace matched=1 if _weight!=.
	replace newtreated = _treated if newtreated == .
	replace newsupport = _support if newsupport == .
	replace newpscore = _pscore if newpscore == .
	replace newweight = _weight if newweight == .
}

save "$path\psm_matched.dta", replace


use "$path\psm_matched.dta", clear
gen D = post * treat
egen month_year = group(month year)

xtset importparcelid date
global control_variables "lotsizeacres lotsizesquarefeet landassessedvalue totalbedrooms building_area buildingage per_inc population hispanicshare whiteshare blackshare"

drop if est == .
xtreg lhprice D post $control_variables i.year i.month_year if matched ==1, fe robust cluster(importparcelid) level(90)
eststo, title(psm without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\psm_DID.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg lhprice D post $control_variables est i.year i.month_year if matched ==1, fe robust cluster(importparcelid) level(90)
eststo, title(psm with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\psm_DID.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D post $control_variables i.year i.month_year if matched ==1, fe robust cluster(importparcelid) level(90)
eststo, title(hp psm without est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\psm_DID.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles

xtreg hp D post $control_variables est i.year i.month_year if matched ==1, fe robust cluster(importparcelid) level(90)
eststo, title(hp psm with est)
esttab using "C:\Users\lubin\OneDrive\Hy_Housing\results\psm_DID.rtf", cells(b(star fmt(4)) se(fmt(4))) level(90) starlevels(* 0.1 ** 0.05 *** 0.01) replace drop(1* 2* 3* 4* 5* 6* 7* 8* 9*) nogaps line long r2 noomitted nonumbers noparentheses mtitles


*common support sample
drop if est == .
psgraph, treated(newtreated) support(newsupport) pscore(newpscore) subtitle("Common support") name(commonsupport_SFR_APT, replace) 
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\common_support_SFR_APT.gph", replace

drop if est == .
tabstat hp year $control_variables if matched == 1, stat(n mean sd min max) column(stat) format(%16.4f)
tabstat hp year $control_variables if matched == ., stat(n mean sd min max) column(stat) format(%16.4f) 


// Before matching
twoway (kdensity newpscore if treat==0, lp(solid) lw(*2.5) legend(label(1 "Control"))) /// 
       (kdensity newpscore if treat==1, lp(dash) lw(*2.5) legend(label(2 "Treated"))), /// 
       ytitle("") xtitle("Before matching") ///
	   xscale(titlegap(2)) ///
	   legend(order(1 "Treatment" 2 "Control")) ///
	   title("Kernel Density Before Matching") ///
	   scheme(s1mono) name(Before, replace)
	   
// After matching
replace treat=. if matched==.
twoway (kdensity newpscore if treat==0, lp(solid) lw(*2.5) legend(label(1 "Control"))) /// 
       (kdensity newpscore if treat==1, lp(dash) lw(*2.5) legend(label(2 "Treated"))), /// 
       ytitle("") xtitle("After matching") ///
	   xscale(titlegap(2)) ///
	   legend(order(1 "Treatment" 2 "Control")) ///
	   title("Kernel Density After Matching") ///
	   scheme(s1mono) name(After, replace)

grc1leg fips`f'_1 fips`f'_2, cols(2) subtitle("`f'") legendfrom(fips`f'_1) scheme(s1mono) name(compare`f'_SFR_APT, replace)

