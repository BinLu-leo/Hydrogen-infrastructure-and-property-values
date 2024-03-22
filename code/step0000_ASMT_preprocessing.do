global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
set more off

clear all
import delimited "$path\ZAsmt\Main.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v95) (rowid importparcelid asmtfips state county valuecertdate extractdate edition zvendorstndcode assessorparcelnumber dupapn unformattedassessorparcelnumber parcelsequencenumber alternateparcelnumber oldparcelnumber parcelnumbertypestndcode recordsourcestndcode recordtypestndcode confidentialrecordflag propertyaddresssourcestndcode propertyhousenumber propertyhousenumberext propertystreetpredirectional propertystreetname propertystreetsuffix propertystreetpostdirectional propertyfullstreetaddress propertycity propertystate asmtzip propertyzip4 originalpropertyfulladdress originalpropertyaddresslastline propertybuildingnumber propertyzoningdescription propertyzoningsourcecode censustract taxidnumber taxamount taxyear taxdelinquencyflag taxdelinquencyamount taxdelinquencyyear taxratecodearea legallot legallotstndcode legalotherlot legalblock legalsubdivisioncode legalsubdivisionname legalcondoprojectpuddevname legalbuildingnumber legalunit legalsection legalphase legaltract legaldistrict legalmunicipality legalcity legaltownship legalstrsection legalstrtownship legalstrrange legalstrmeridian legalsectwnrngmer legalrecordersmapreference legaldescription legalneighborhoodsourcecode noofbuildings lotsizeacres lotsizesquarefeet lotsizefrontagefeet lotsizedepthfeet lotsizeirr lotsitetopographystndcode loadid propertyaddressmatchcode propertyaddressunitdesignator propertyaddressunitnumber propertyaddresscarrierroute propertyaddressgeocode latitude longitude censustractandblock confidencescore cbsacode cbsadivisioncode matchtype propertyaddressdpv geocodequalitycode propertyaddressqualitycode subedition batchid bkfspid sourcechksum)

keep rowid importparcelid asmtfips state asmtzip lotsizeacres lotsizesquarefeet
save main.dta, replace

clear all
import delimited "$path\ZAsmt\Value.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v15) (rowid landassessedvalue improvementassessedvalue totalassessedvalue assessmentyear landmarketvalue improvementmarketvalue totalmarketvalue marketvalueyear landappraisalvalue improvementappraisalvalue totalappraisalvalue appraisalvalueyear fips batchid)

keep rowid landassessedvalue landmarketvalue
save value.dta, replace

clear all
import delimited "$path\ZAsmt\Building.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v47) (rowid noofunits occupancystatusstndcode propertycountylandusedescription propertycountylandusecode propertylandusestndcode propertystatelandusedescription propertystatelandusecode buildingorimprovementnumber buildingclassstndcode buildingqualitystndcode buildingqualitystndcodeoriginal buildingconditionstndcode architecturalstylestndcode yearbuilt effectiveyearbuilt yearremodeled noofstories totalrooms totalbedrooms totalkitchens fullbath threequarterbath halfbath quarterbath totalcalculatedbathcount totalactualbathcount bathsourcestndcode totalbathplumbingfixtures roofcoverstndcode roofstructuretypecode heatingtypeorsystemcode airconditioningtypecode foundationtypecode elevatorcode fireplaceflag fireplacetypecode fireplacenumber waterstndcode sewerstndcode mortgagelendername timesharestndcode comments loadid storytypestndcode fips batchid)

keep rowid propertycountylandusedescription propertylandusestndcode buildingorimprovementnumber yearbuilt yearremodeled noofstories totalrooms totalbedrooms
* some number of stories have digits
replace noofstories = round(noofstories)
save building.dta, replace


clear all
import delimited "$path\ZAsmt\BuildingAreas.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v7) (rowid buildingorimprovementnumber buildingareasequencenumber buildingareastndcode buildingareasqft fips batchid)

bysort rowid buildingorimprovementnumber: egen building_area=total(buildingareasqft)
keep if buildingareasequencenumber==1
keep rowid buildingorimprovementnumber building_area
* some building area is negative
replace building_area = . if building_area < 0
save area.dta, replace

clear all
import delimited "$path\ZAsmt\Garage.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v8) (rowid buildingorimprovementnumber garagesequencenumber garagestndcode garageareasqft garagenoofcars fips batchid)

bysort rowid buildingorimprovementnumber: egen garage_area=total(garageareasqft)
keep if garagesequencenumber==1
keep rowid buildingorimprovementnumber garage_area
save garage.dta, replace

clear all
import delimited "$path\ZAsmt\Pool.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v6) (rowid buildingorimprovementnumber poolstndcode poolsize fips batchid)

keep rowid buildingorimprovementnumber poolsize
save pool.dta, replace

clear all
import delimited "$path\ZAsmt\LotSiteAppeal.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v4) (rowid lotsiteappealstndcode fips batchid)

keep rowid lotsiteappealstndcode
gen goodview=1 if lotsiteappealstndcode=="AIR"|lotsiteappealstndcode=="FWY"|lotsiteappealstndcode=="GBL"|lotsiteappealstndcode=="GLF"|lotsiteappealstndcode=="HST"|lotsiteappealstndcode=="OMS"|lotsiteappealstndcode=="SCH"|lotsiteappealstndcode=="VWL"|lotsiteappealstndcode=="VWM"|lotsiteappealstndcode=="VWO"|lotsiteappealstndcode=="VWR"|lotsiteappealstndcode=="WFB"|lotsiteappealstndcode=="WFC"|lotsiteappealstndcode=="WFS"

save lotsiteappeal.dta, replace


use "main.dta", clear

merge 1:m rowid using value
drop _merge

merge 1:m rowid using building
drop _merge

*merge 1:m rowid using lotsiteappeal
*drop _merge

merge 1:m rowid buildingorimprovementnumber using area
drop _merge

merge 1:m rowid buildingorimprovementnumber using garage
drop _merge

merge 1:m rowid buildingorimprovementnumber using pool
drop _merge

* variable importparcelid does not uniquely identify observations in the using data
sort importparcelid
quietly by importparcelid: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

save asmtCA.dta, replace
