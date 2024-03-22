clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"

set maxvar 120000
set matsize 11000
set max_memory 16g

******************************************************************************* Fig. S2
use "zillowCA_data.dta", clear
merge n:1 propertyzip year using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", nogen ///
keep(match) keepusing(whiteshare blackshare hispanicshare per_inc population)

keep if dist<=5000

gen treat = 0
replace treat =1 if dist <= 2200
gen D = treat * post 

* Aggregate the number of transactions per year
egen transactions_per_year = count(transid), by(year)
* Ensure there's only one row per year for plotting
bysort year (transactions_per_year): gen year_row = _n
keep if year_row == 1
drop year_row
* Sort the data by year to ensure it plots correctly
sort year
* Plot the bar chart
graph bar transactions_per_year, over(year) ///
    title("Annual Transactions") ///
    ylabel(#10, angle(horizontal)) ///
    ytitle("Number of Transactions") ///
    blabel(bar, format(%9.0g)) ///
    legend(off)
graph save "Graph" "C:\Users\lubin\OneDrive\Hy_Housing\results\FigureS2.gph"


******************************************************************************* Fig. S3
* use pre-clean data, generated in "step0_DID_data.do"
use zillowCA_nocleaned_control.dta, clear

gen post = 0
replace post = 1 if date >= open 
gen treat =0
replace treat =1 if dist <= 2200
gen D = treat * post   

*keep propertyzip importparcelid year dist hp lhprice treat post D
keep if dist<=5000
keep if year > 2011

collapse (count) importparcelid, by (treat post year propertyzip)
*reshape wide importparcelid, i(propertyzip) j(year)
rename importparcelid count_id

//post == 0
	twoway (scatter propertyzip year if post == 0 & year < 2022 [aw=count_id], msize(tiny)),  ///
    xtitle("Year", size(small)) ytitle("Property ZIP", size(small)) ///
    title("Sample distribution in Zip area by year (Before HRSs installation)", size(median))
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\SampleDistributionBefore.gph", replace
//post == 1
	twoway (scatter propertyzip year if post == 1 & year < 2022 [aw=count_id], msize(tiny)),  ///
    xtitle("Year", size(small)) ytitle("Property ZIP", size(small)) ///
    title("Sample distribution in Zip area by year (After HRSs installation)", size(median))	
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\SampleDistributionAfter.gph", replace


//treat == 1 & post == 0
	twoway (scatter propertyzip year if treat == 1 & post == 0 & year < 2022 [aw=count_id], msize(tiny)), ///
    xtitle("Year", size(small)) ytitle("Property ZIP", size(small)) ///
    title("Before HRSs installation, Distance<2.2km", size(median))	
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\SampleDistribution_1.gph", replace
	
//keep if treat == 1 & post == 1
	twoway (scatter propertyzip year if treat == 1 & post == 1 & year < 2022 [aw=count_id], msize(tiny)),  ///
    xtitle("Year", size(small)) ytitle("Property ZIP", size(small)) ///
    title("After HRSs installation, Distance<=2.2km", size(median))	
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\SampleDistribution_2.gph", replace
			
//keep if treat == 0 & post == 0
	twoway (scatter propertyzip year if treat == 0 & post == 0 & year < 2022 [aw=count_id], msize(tiny)),  ///
    xtitle("Year", size(small)) ytitle("Property ZIP", size(small)) ///
    title("Before HRSs installation, Distance>2.2km", size(median))	
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\SampleDistribution_3.gph", replace		
		
//keep if treat == 0 & post == 1
	twoway (scatter propertyzip year if treat == 0 & post == 1 & year < 2022 [aw=count_id], msize(tiny)),  ///
    xtitle("Year", size(small)) ytitle("Property ZIP", size(small)) ///
    title("After HRSs installation, Distance>2.2km", size(median))	
graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\SampleDistribution_4.gph", replace		
	
//gr combine SampleDistribution_1 SampleDistribution_2 SampleDistribution_3 SampleDistribution_4
//graph save "C:\Users\lubin\OneDrive\Hy_Housing\results\FigureS3.gph", replace


******************************************************************************* Fig. S11
use "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates.dta", clear
drop zipcount
replace population = . if population == 0
replace per_inc = . if per_inc == 0
replace blackshare = . if blackshare == 0
replace hispanicshare = . if hispanicshare == 0
replace whiteshare = . if whiteshare == 0
keep if year == 2021
save "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates2021.dta", replace

insheet using "alt_fuel_stations_03022023_hydro.csv", clear // raw 140
set more off
keep if state == "CA" // keep 116
rename id station_id
rename zip propertyzip
rename latitude latitude2
rename longitude longitude2
* convert date format
gen open=date(opendate, "YMD") 
format open %td
gen openyear=year(open)
gen openmonth=month(open)
//tab openyear, m
keep propertyzip statuscode expecteddate latitude2 longitude2 station_id opendate accesscode open openyear openmonth

merge n:1 propertyzip using "C:\Users\lubin\OneDrive\Hy_Housing\data\ca_covariates2021.dta", nogen keepusing(whiteshare blackshare hispanicshare per_inc population)
drop if station_id == .
replace statuscode = "E" if statuscode == "T"

//distinct propertyzip
sort statuscode open propertyzip
replace blackshare = 0 if blackshare == .
gen other = 100 - whiteshare - blackshare - hispanicshare

//count
distinct station_id if whiteshare >= 51.6 //median
distinct station_id if blackshare >= 2.6 //median

* Reshape the data to long format for stacking
rename whiteshare share_white
rename blackshare share_black
rename hispanicshare share_hispanic
rename other share_other
reshape long share_, i(station_id) j(race) string

// Create a numeric variable to sort the race categories in the desired order
gen racenum = cond(race == "black", 1, ///
                   cond(race == "white", 2, ///
                   cond(race == "hispanic", 3, 4)))
// Sort the data by the numeric race category
sort statuscode open station_id racenum
				   
* Generate the stacked bar chart
global pct `" 0 "0%" 25 "25%" 50 "50%" 75 "75%" 100 "100%" "'
preserve
	keep in 1/92
	graph hbar (sum) share if statuscode == "E", over(racenum) over(station_id, gap(*0.5) label(labsize(2))) stack asyvars ///
		bar(1, fcolor(green*0.4) lcolor(green) lwidth(0.1)) ///
		bar(2, fcolor(orange*0.4) lcolor(orange) lwidth(0.1)) ///
		bar(3, fcolor(blue*0.4) lcolor(blue) lwidth(0.1)) ///
		bar(4, fcolor(black*0) lcolor(black) lwidth(0.06)) ///
		legend(order(1 "Non-Hispanic Blacks" 2 "Non-Hispanic Whites" 3 "Hispanics" 4 "Other races") cols(4) rows(1) ///
			size(2) symxsize(8) textwidth(18)) subtitle("(open stations, 2000-2016)", size(4)) ///
		title("Racial share in ZIP-code areas with hydrogen refueling stations", size(4) color(black)) ///
		ytitle("Share", size(3))  ylabel($pct, labsize(3)  valuelabel nogrid) ///
		yscale(lcolor(white)) ///
		graphregion(color(white)) ///
		plotregion(color(white))
		graph export "C:\Users\lubin\OneDrive\Hy_Housing\results\HRSzipRacial1.png", as(png) name("Graph") replace
restore

preserve
	keep in 93/184
	graph hbar (sum) share if statuscode == "E", over(racenum) over(station_id, gap(*0.5) label(labsize(2))) stack asyvars ///
		bar(1, fcolor(green*0.4) lcolor(green) lwidth(0.1)) ///
		bar(2, fcolor(orange*0.4) lcolor(orange) lwidth(0.1)) ///
		bar(3, fcolor(blue*0.4) lcolor(blue) lwidth(0.1)) ///
		bar(4, fcolor(black*0) lcolor(black) lwidth(0.06)) ///
		legend(order(1 "Non-Hispanic Blacks" 2 "Non-Hispanic Whites" 3 "Hispanics" 4 "Other races") cols(4) rows(1) ///
			size(2) symxsize(8) textwidth(18)) subtitle("(open stations, 2016-2019)", size(4)) ///
		title("Racial share in ZIP-code areas with hydrogen refueling stations", size(4) color(black)) ///
		ytitle("Share", size(3))  ylabel($pct, labsize(3)  valuelabel nogrid) ///
		yscale(lcolor(white)) ///
		graphregion(color(white)) ///
		plotregion(color(white))
		graph export "C:\Users\lubin\OneDrive\Hy_Housing\results\HRSzipRacial2.png", as(png) name("Graph") replace
restore

preserve
	keep in 185/284
	graph hbar (sum) share if statuscode == "E", over(racenum) over(station_id, gap(*0.5) label(labsize(2))) stack asyvars ///
		bar(1, fcolor(green*0.4) lcolor(green) lwidth(0.1)) ///
		bar(2, fcolor(orange*0.4) lcolor(orange) lwidth(0.1)) ///
		bar(3, fcolor(blue*0.4) lcolor(blue) lwidth(0.1)) ///
		bar(4, fcolor(black*0) lcolor(black) lwidth(0.06)) ///
		legend(order(1 "Non-Hispanic Blacks" 2 "Non-Hispanic Whites" 3 "Hispanics" 4 "Other races") cols(4) rows(1) ///
			size(2) symxsize(8) textwidth(18)) subtitle("(open stations, 2019-2022)", size(4)) ///
		title("Racial share in ZIP-code areas with hydrogen refueling stations", size(4) color(black)) ///
		ytitle("Share", size(3))  ylabel($pct, labsize(3)  valuelabel nogrid) ///
		yscale(lcolor(white)) ///
		graphregion(color(white)) ///
		plotregion(color(white))
		graph export "C:\Users\lubin\OneDrive\Hy_Housing\results\HRSzipRacial3.png", as(png) name("Graph") replace
restore

preserve
	keep in 285/372
	graph hbar (sum) share if statuscode == "P", over(racenum) over(station_id, gap(*0.5) label(labsize(2))) stack asyvars ///
		bar(1, fcolor(green*0.4) lcolor(green) lwidth(0.1)) ///
		bar(2, fcolor(orange*0.4) lcolor(orange) lwidth(0.1)) ///
		bar(3, fcolor(blue*0.4) lcolor(blue) lwidth(0.1)) ///
		bar(4, fcolor(black*0) lcolor(black) lwidth(0.06)) ///
		legend(order(1 "Non-Hispanic Blacks" 2 "Non-Hispanic Whites" 3 "Hispanics" 4 "Other races") cols(4) rows(1) ///
			size(2) symxsize(8) textwidth(18)) subtitle("(planned stations, 2023-)", size(4)) ///
		title("Racial share in ZIP-code areas with hydrogen refueling stations", size(4) color(black)) ///
		ytitle("Share", size(3))  ylabel($pct, labsize(3)  valuelabel nogrid) ///
		yscale(lcolor(white)) ///
		graphregion(color(white)) ///
		plotregion(color(white))
		graph export "C:\Users\lubin\OneDrive\Hy_Housing\results\HRSzipRacial4.png", as(png) name("Graph") replace
restore

preserve
	keep in 373/464
	graph hbar (sum) share if statuscode == "P", over(racenum) over(station_id, gap(*0.5) label(labsize(2))) stack asyvars ///
		bar(1, fcolor(green*0.4) lcolor(green) lwidth(0.1)) ///
		bar(2, fcolor(orange*0.4) lcolor(orange) lwidth(0.1)) ///
		bar(3, fcolor(blue*0.4) lcolor(blue) lwidth(0.1)) ///
		bar(4, fcolor(black*0) lcolor(black) lwidth(0.06)) ///
		legend(order(1 "Non-Hispanic Blacks" 2 "Non-Hispanic Whites" 3 "Hispanics" 4 "Other races") cols(4) rows(1) ///
			size(2) symxsize(8) textwidth(18)) subtitle("(planned stations, 2023-)", size(4)) ///
		title("Racial share in ZIP-code areas with hydrogen refueling stations", size(4) color(black)) ///
		ytitle("Share", size(3))  ylabel($pct, labsize(3)  valuelabel nogrid) ///
		yscale(lcolor(white)) ///
		graphregion(color(white)) ///
		plotregion(color(white))
		graph export "C:\Users\lubin\OneDrive\Hy_Housing\results\HRSzipRacial5.png", as(png) name("Graph") replace
restore





