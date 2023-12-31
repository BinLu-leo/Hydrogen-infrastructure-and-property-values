set maxvar 10000
set matsize 11000

global path "C:\Users\lubin\Desktop\Hy_housing\data"
cd "$path"
set more off
clear all
import delimited "$path\ZTrans\Main.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v131) (transid pricefips state county dataclassstndcode recordtypestndcode recordingdate recordingdocumentnumber recordingbooknumber recordingpagenumber rerecordedcorrectionstndcode priorrecordingdate priordocumentdate priordocumentnumber priorbooknumber priorpagenumber documenttypestndcode documentdate signaturedate effectivedate buyervestingstndcode buyermultivestingflag partialinteresttransferstndcode partialinteresttransferpercent salespriceamount salespriceamountstndcode citytransfertax countytransfertax statetransfertax totaltransfertax intrafamilytransferflag transfertaxexemptflag propertyusestndcode assessmentlandusestndcode occupancystatusstndcode legalstndcode borrowervestingstndcode lendername lendertypestndcode lenderidstndcode lenderdbaname dbalendertypestndcode dbalenderidstndcode lendermailcareofname lendermailhousenumber lendermailhousenumberext lendermailstreetpredirectional lendermailstreetname lendermailstreetsuffix lendermailstreetpostdirectional lendermailfullstreetaddress lendermailbuildingname lendermailbuildingnumber lendermailunitdesignator lendermailunit lendermailcity lendermailstate lendermailzip lendermailzip4 loanamount loanamountstndcode maximumloanamount loantypestndcode loantypeclosedopenendstndcode loantypefutureadvanceflag loantypeprogramstndcode loanratetypestndcode loanduedate loantermmonths loantermyears initialinterestrate armfirstadjustmentdate armfirstadjustmentmaxrate armfirstadjustmentminrate armindexstndcode armadjustmentfrequencystndcode armmargin arminitialcap armperiodiccap armlifetimecap armmaxinterestrate armmininterestrate interestonlyflag interestonlyterm prepaymentpenaltyflag prepaymentpenaltyterm biweeklypaymentflag assumabilityriderflag balloonriderflag condominiumriderflag plannedunitdevelopmentriderflag secondhomeriderflag onetofourfamilyriderflag concurrentmtgedocorbkpg loannumber mersminnumber casenumber mersflag titlecompanyname titlecompanyidstndcode accommodationrecordingflag unpaidbalance installmentamount installmentduedate totaldelinquentamount delinquentasofdate currentlender currentlendertypestndcode currentlenderidstndcode trusteesalenumber attorneyfilenumber auctiondate auctiontime auctionfullstreetaddress auctioncityname startingbid keyeddate keyerid subvendorstndcode imagefilename builderflag matchstndcode reostndcode updateownershipflag loadid statusind transactiontypestndcode batchid bkfspid zvendorstndcode sourcechksum)

keep transid state pricefips recordingdate documentdate signaturedate salespriceamount 
save price.dta, replace

clear all
import delimited "$path\ZTrans\PropertyInfo.txt", delimiter("|") bindquote(nobind) clear

rename (v1-v68) (transid assessorparcelnumber apnindicatorstndcode taxidnumber taxidindicatorstndcode unformattedassessorparcelnumber alternateparcelnumber hawaiicondocprcode propertyhousenumber propertyhousenumberext streetpredirectional propertystreetname propertystreetsuffix propertystreetpostdirectional propertybuildingnumber fullstreetaddress propertycity propertystate infozip propertyzip4 originalfullstreetaddress originaladdresslastline addressstndcode legallot legalotherlot legallotcode legalblock legalsubdivisionname legalcondoprojectpuddevname legalbuildingnumber legalunit legalsection legalphase legaltract legaldistrict legalmunicipality legalcity legaltownship legalstrsection legalstrtownship legalstrrange legalstrmeridian legalsectwnrngmer legalrecordersmapreference legaldescription legallotsize sequencenumber propertyaddressmatchcode addressunitdesignator addressunitnumber addresscarrierroute addressgeocodematchcode latitude longitude addresscensustractandblock addressconfidencescore addresscbsacode addresscbsadivisioncode addressmatchtype propertyaddressdpv geocodequalitycode addressqualitycode infofips loadid importparcelid bkfspid assessmentmatchflag batchid)

keep transid importparcelid infofips infozip latitude longitude
save info.dta, replace

use "price.dta", clear

merge 1:m transid using info
keep if _merge==3
drop _merge

save transCA.dta, replace


