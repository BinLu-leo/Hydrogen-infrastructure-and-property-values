clear all
global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
set more off

set maxvar 10000
set matsize 11000

use transCA.dta, clear //

* drop missing
drop if salespriceamount == . 
drop if importparcelid == .	

drop if missing(latitude) 
drop if missing(recordingdate)
				
* drop repeated transid 
sort transid importparcelid
quietly by transid: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

* convert date format
gen date=date(recordingdate, "YMD") 
format date %td
gen year=year(date)
gen month=month(date)
tab year, m
drop if year < 1980 

*Check to see if there are multiple transactions on the same day with different prices? And drop.
duplicates tag importparcelid date, gen(propdaytag)
tab propdaytag
gen okflag = (propdaytag==0)
egen stdprice = sd(salesprice), by(importparcelid date)
drop if stdprice > 0 & okflag == 0
duplicates drop importparcelid date, force
drop propdaytag okflag stdprice

*We don't want to include properties sold more than 1 time in a year
bysort importparcelid year: gen st=_N
drop if st>1
drop st

merge m:1 importparcelid using asmtCA.dta
drop if _merge != 3
drop _merge 

*Check if they are just land sales, and don't include: 
format yearbuilt %ty
gen land=(year < yearbuilt & yearbuilt!=.)
drop if land==1		
drop land

gen buildingage = year - yearbuilt
gen sold_in_yr_blt = (buildingage == 0)
drop if sold_in_yr_blt == 1	
drop documentdate signaturedate

* generate adjusted log housing price (base year = 2022; use salesprice*buyingpower, meaning: $1 in a given year equals to how much money in 2022)
merge m:1 year using cpi
drop if _merge != 3	
drop _merge
gen hp = salesprice*buyingpower
gen lhprice = ln(hp)

tab year, m


* drop outliers of salesprice
egen meanhp=mean(salesprice)
egen sdhp=sd(salesprice)
gen hp1=meanhp-2*sdhp
gen hp2=meanhp+2*sdhp
drop if salesprice >hp2 | salesprice <hp1
drop meanhp sdhp hp1 hp2


* 1. properties that have been sold more than once
/*bys importparcelid: gen n_import = _N
bys importparcelid transid: gen n_trans = _N
keep if n_import > n_trans
drop n_import n_trans */

sort importparcelid transid
quietly by importparcelid: gen dup = cond(_N==1,0,_n)
drop if dup == 0 					
drop dup 

drop recordingdate pricefips state infofips rowid asmtfips landmarketvalue propertycountylandusedescription buildingorimprovementnumber yearremodeled poolsize sold_in_yr_blt
save trans_asmt.dta, replace

*keep propertylandusestndcode propertycountylandusedescription
*duplicates drop propertylandusestndcode propertycountylandusedescription, force
*save house_type.dta, replace
