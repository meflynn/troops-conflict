

	clear all
	cd "~/Dropbox/Projects/Troops and Conflict/Data"

/* Data sets and Stata commands required.
	
	Data:
	1. Polity IV Data version 2014 release
	2. Gleditsch's expanded trade and GDP data version 5.0
	3. Infant mortality data by Abouharb and Kimball
	4. COW National Material Capabilities data version 4.0
	5. COW Direct Contiguity data version 3.1
	6. Bureau of labor statistics Consumer Price Index (1914-2015)
	7. Tim Kane's US Troop data
	8. COW Interstate War data version 4.0
	9. COW Intrastate War data version 4.1
	10. COW Militarized Interstate Dispute (MIDB) version 4.1
	11. ATOP yearly directed dyad (atop3_o_ddyrNNA.dta) version 3.0
	
	Commands:
	1. "ddyad" command to construct directed dyads
		Note that the ddyad command requires the COW system membership 2011 data file to run
	2. "scompute" by Sweeney and Keshk to construct S scores for threat environment.

*/

tempfile clear

* Create directed dyads base data for various spatial and relational measures
	clear
		ddyad 1947 2016
		sort ccode1 ccode2 year
		
		tempfile ddyads
		
	save `ddyads', replace

	
* Create country year data set
		keep ccode1 ccode2 year
		
		collapse (mean) ccode2, by(ccode1 year)
			drop ccode2
			rename ccode1 ccode
			sort ccode year
		
		tempfile countrylist
		
	save `countrylist', replace

	
* Create directed dyad data that includes i to i dyads for S score computation
	clear
		use `ddyads'
		keep ccode1 year
		gen ccode2 = ccode1
		order ccode1 ccode2 year
		
		collapse (mean) ccode2, by(ccode1 year)
			sort ccode1 ccode2 year
			
		tempfile iidyads
			
	save `iidyads', replace


* COW Trade Data
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/Dyadic_COW_4.0.csv"
		keep if  year >= 1947
		keep if ccode1 == 2
		sort ccode1 ccode2 year
		* flow1 = exports from US to country b
		* flow2 = imports to US from country b
		rename flow1 exports
		rename flow2 imports
		keep ccode1 ccode2 year exports imports
		replace exports = . if exports == -9
		replace imports = . if imports == -9
		merge m:1 year using "/Users/michaelflynn/Dropbox/Data Files/US Government Files/BLS/cpi_1913_2015.dta", nogen
		keep if year>=1947 & year <=2016
		* Convert to 2016 Dollars
		sum cpi if year == 1983, d
		local cpimean = r(mean)
		replace cpi = (cpi/`cpimean')
		sum cpi if year == 2000, d
		local cpimean = r(mean)
		replace cpi = cpi/`cpimean'
		replace exports = exports/cpi
		replace imports = imports/cpi
		drop cpi
		drop ccode1
		rename ccode2 ccode
		sort ccode year
		
		tempfile trade1 
		
	save `trade1', replace
	
		rename ccode ccode2
		sort ccode2 year
		
		tempfile trade2
		
	save `trade2', replace
		
	
	
	
* Polity IV Data
	clear
		import excel "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/p4v2014.xls", sheet("p4v2014") firstrow case(lower)
		keep ccode country year polity2
		sort ccode year
		keep if year >= 1947 & year<= 2016
		* Adjusting codes for Russia and Yugoslavia/Serbia. note that Yemen codes are correct.
		* Vietnam/North Vietnam code needs to be changed to 816 as Polity has separate entries for unified Vietnam and North Vietnam.
		replace ccode = 345 if ccode == 347
		replace ccode = 365 if ccode == 364
		replace ccode = 816 if ccode == 818
		
		collapse (max) polity2, by(ccode year)
			sort ccode year
		
		tempfile polity
		
	save `polity', replace


* GDP Data (Using real gdp per capita figures. Constant 2000 Dollars.)
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/expgdp_v5.0.asc", delimiter(space) varnames(1) encoding(UTF-8)
		rename statenum ccode
		drop origin
		* Change Yemen country code. Begins in 1990, but we make the entry year 1991.
		* Vietnam is ok.
		replace ccode = 679 if ccode == 678 & year > 1990
		replace ccode = 255 if ccode == 260 & year > 1990
		gen realgdp = rgdpch*(pop*1000)
		keep if year >= 1947 & year <= 2016
		
		tempfile gdp
	
	save `gdp', replace


* IMR Data
	clear
		use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/A_KIMRJPRDataSet2007.dta"
		* All country codes ok.
		keep ccode year IMR
		keep if year >= 1947
		sort ccode year
		
		tempfile IMR
		
	save `IMR', replace


* COW capabilities data
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/NMC_5_0.csv", delimiter(comma) 
		* All countries codes ok.
		sort ccode year
		keep if year >= 1947 & year <= 2016
		mvdecode irst milex milper pec tpop upop cinc, mv(-9)
	
			collapse (max) milex-version, by(ccode year)
		
		tempfile capabilities

	save `capabilities', replace


* Contiguity Data Indicator
* Note that there are some duplicates in the contiguity data. We keep the observation with the lowest contiguity value.
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/contdird.csv", delimiter(comma) encoding(ISO-8859-1)
		* All country codes ok.
		rename state1no ccode1
		rename state2no ccode2 
		keep if year >= 1947 & year <= 2016
		sort ccode1 ccode2 year
		duplicates tag ccode1 ccode2 year, gen(dup) 
		sort ccode1 ccode2 conttype
		
		collapse (min) conttype, by(ccode1 ccode2 year)
			sort ccode1 year
			by ccode1 year: egen borderstates = count(ccode2) if conttype == 1
			sort ccode1 year ccode2
			carryforward borderstates, gen(borderstates2)
			replace borderstates = borderstates2
			by ccode1 year: egen neighborhoodsize = count(ccode2)  
			sort ccode1 year ccode2
			carryforward neighborhoodsize, gen(neighbors)
			replace neighborhoodsize = neighbors
			drop neighbors
			drop borderstates2
			gen contiguity = 1
			sort ccode1 ccode2 year
			merge 1:1 ccode1 ccode2 year using `ddyads', nogen
			replace contiguity = 0 if contiguity == .
			
		tempfile contiguity
		
	save `contiguity', replace

	

* Generate borderstate counter
		keep ccode1 year borderstates
		
		collapse (max) borderstates, by(ccode year)
			replace borderstates = 0 if borderstates == .
			rename ccode1 ccode
			sort ccode year
			
		tempfile borderstates
		
	save `borderstates', replace



* Generate defense burden dependent variable
	clear
		use `capabilities'
		keep ccode year milex
		sort ccode year
		merge m:1 year using "/Users/michaelflynn/Dropbox/Data Files/US Government Files/BLS/cpi_1913_2015.dta", nogen
		keep if year>=1947 & year <=2016
		* Convert to 2016 Dollars
		sum cpi if year == 1983, d
		local cpimean = r(mean)
		replace cpi = (cpi/`cpimean')
		sum cpi if year == 2000, d
		local cpimean = r(mean)
		replace cpi = cpi/`cpimean'
		replace milex = . if milex <0
		replace milex = (milex*1000)/cpi
		sort ccode year
		merge 1:1 ccode year using `gdp', nogen
		keep if year >= 1947 & year <= 2016
		gen defenseburden = (milex/realgdp)*100
		
		tempfile defburden
		
	save `defburden', replace
		gen ccode2 = ccode
		sort ccode2 year
		
		tempfile defburden2
		
	save `defburden2', replace 

	

* Host-state troops data
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/troopMarch2005.txt", delimiter(tab) encoding(ISO-8859-1)
		drop v1
		rename v2 country
			local i = 1950
			foreach var of varlist v3-v58 {
				rename `var' y_`i'
				local i = `i'+1
				}
		drop in 1
		drop v59-v76
		drop in 1/9
		drop in 2/21
		drop in 188/190
		destring y_1950-y_2005, ignore("," " -   " "unknown") replace
		mvencode y_1950-y_2005, mv(.=0)
		replace country = "United States" if country == "Continental U.S."
		replace country = "North Korea" if country == "Korea, Democratic Peoples Republic of"
		replace country = "Bahrain" if country == "Bahrein / Bahrain"
		replace country = "Sri Lanka" if country == "Sri Lanka / Ceylon"
		replace country = "Democratic Republic of Congo" if country == "Congo - Democratic Republic "
		replace country = "Ivory Coast" if country == "Ivory Coast (Cote d'Ivorie)"
		replace country = "Cuba" if country == "Cuba / Guantanamo"
		replace country = "Somalia" if country == "Somali Republic"
		kountry country, from(other) marker stuck
		rename _ISO3N_ cnum
		kountry cnum, from(iso3n) to(cown)
		rename _COWN_ ccode
		order ccode, after(country)
		replace ccode = 713 if country == "Taiwan"
		replace ccode = 315 if country == "Czechoslovakia"
		replace ccode = 817 if country == "Vietnam"
		sort ccode
		drop if ccode == .
		
		* Collapse to combine Yugoslavia and Serbia and Montenegro
		collapse (max) y_1950-y_2005, by(ccode)
			reshape long y_, i(ccode) j(year)
			rename y_ troops
			* Change German and Yemen country code.
			replace ccode = 260 if ccode == 255 & year <= 1990
			replace ccode = 678 if ccode == 679 & year <= 1990
			replace ccode = 316 if ccode == 315 & year >= 1993
			merge 1:1 ccode year using `countrylist', gen(merge)
			replace troops = 0 if troops == .
			gen lntroops = ln(troops+1)
			gen troops20 = troops
			replace troops20 = 0 if troops<20
			gen troops100 = troops
			replace troops100 = 0 if troops<100
			gen lntroops20 = ln(troops20+1)
			gen lntroops100 = ln(troops100+1)
			gen ccode2 = ccode
			sort ccode2 year

		tempfile troops
	
	save `troops', replace
	

* Generate hierarchy variable
		merge 1:1 ccode year using `capabilities', gen(merge2)
		drop if ccode == 2
		gen hierarchy = troops/(tpop*1000)
		sum hierarchy if year == 1995
		local max = r(max)
		replace hierarchy = hierarchy/`max'
		keep ccode year hierarchy
		gen ccode2 = ccode
		sort ccode year 
		
		tempfile hierarchy
		
		save `hierarchy', replace	
		
		



* Generate COW war measure
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/Inter-StateWarData_v4.0.csv", delimiter(comma) encoding(ISO-8859-1)
		keep warnum ccode statename startyear1 endyear1 startyear2 endyear2 
		gen startyear = startyear1
		gen endyear = endyear1
		replace endyear = endyear2 if endyear2>0
		drop startyear1 endyear1 startyear2 endyear2
		gen duration = (endyear-startyear)+1
		
		expand duration
			sort ccode warnum startyear
			by ccode warnum: egen count = seq()
			replace count = (startyear+count)-1
			rename count year
			gen interstatewar = 1
			drop warnum
			rename interstatewar war
		
			collapse (mean) war, by(ccode year)
				keep if year >= 1947
			
		tempfile interstatewar
		
	save `interstatewar', replace
	
		rename ccode ccode2
		sort ccode2 year
		
		tempfile interstatewar2
		
	save `interstatewar2', replace


* Generate COW civil war measure
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/Intra-StateWarData_v4.1.csv", delimiter(comma) encoding(ISO-8859-1)
		gen ccode = ccodea if ccodea > 0 
		replace ccode = ccodeb if ccodeb > 0
		keep warnum ccode startyear1 endyear1 startyear2 endyear2
		drop if ccode == .
		gen startyear = startyear1
		gen endyear = endyear1
		replace endyear = endyear2 if endyear2>0
		drop startyear1 endyear1 startyear2 endyear2
		gen duration = (endyear-startyear)+1
		
		expand duration
			sort ccode warnum startyear
			by ccode warnum: egen count = seq()
			replace count = (startyear+count)-1
			rename count year
			keep if year >= 1947
			gen civilwar = 1
			
				collapse (mean) civilwar, by(ccode year)
		
		tempfile civilwar
		
	save `civilwar', replace
	
		rename ccode ccode2
		sort ccode2 year
		
		tempfile civilwar2
		
	save `civilwar2', replace


* Generate MID count by year
* Note that the data do not include years for which no MIDs were observed. Moving average must be constructed later in full data.
* First generating a blank year dataset so we can account for years in which some states have 0 MIDs
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/MIDB_4.01.csv", delimiter(comma) encoding(ISO-8859-1)
		keep dispnum3 ccode styear endyear hostlev fatality
		drop if hostlev==5
		replace fatality = . if fatality == -9
		sort ccode dispnum styear
		gen duration = (endyear-styear)+1
		
		expand duration
			sort ccode dispnum styear
			by ccode dispnum: egen count = seq()
			replace count = (styear+count)-1
			rename count year
			keep if year >= 1945
			gen mids_total = 1
			
			collapse (count) mids (mean) hostlev fatality, by(ccode year)
				tsset ccode year
		
		tempfile MIDs
		
	save `MIDs', replace
	
		rename ccode ccode2
		sort ccode2 year
		
		tempfile MIDs2
		
	save `MIDs2', replace

	
* Generate MID initiation count by year
* Note that the data do not include years for which no MIDs were observed. Moving average must be constructed later in full data.
* First generating a blank year dataset so we can account for years in which some states have 0 MIDs
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/MIDB_4.01.csv", delimiter(comma) encoding(ISO-8859-1)
		keep dispnum3 ccode styear endyear hostlev sidea orig
		drop if hostlev==5
		drop hostlev
		keep if orig == 1
		sort ccode dispnum styear
		gen duration = (endyear-styear)+1
		
		expand duration
			sort ccode dispnum styear
			by ccode dispnum: egen count = seq()
			replace count = (styear+count)-1
			rename count year
			keep if year >= 1945
			gen mids_initiate = 1
			
			collapse (count) mids_initiate, by(ccode year)
				tsset ccode year
		
		tempfile MIDs_in
		
	save `MIDs_in', replace
	
		rename ccode ccode2
		sort ccode2 year
		
		tempfile MIDs2_in
		
	save `MIDs2_in', replace	
	
	
* Generate MID target count by year
* Note that the data do not include years for which no MIDs were observed. Moving average must be constructed later in full data.
* First generating a blank year dataset so we can account for years in which some states have 0 MIDs
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/MIDB_4.01.csv", delimiter(comma) encoding(ISO-8859-1)
		keep dispnum3 ccode styear endyear hostlev sidea
		drop if hostlev==5
		drop hostlev
		keep if sidea == 0
		sort ccode dispnum styear
		gen duration = (endyear-styear)+1
		
		expand duration
			sort ccode dispnum styear
			by ccode dispnum: egen count = seq()
			replace count = (styear+count)-1
			rename count year
			keep if year >= 1945
			gen mids_target = 1
			
			collapse (count) mids_target, by(ccode year)
				tsset ccode year
		
		tempfile MIDs_ta
		
	save `MIDs_ta', replace
	
		rename ccode ccode2
		sort ccode2 year
		
		tempfile MIDs2_ta
		
	save `MIDs2_ta', replace		
	
	
* Generate events data conflict and cooperation for monadic models
	clear
		do "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/COPDAB/COPDAB Setup.do"		drop if TARGET == 4
		rename actor ccode
		drop if ccode == 2
		drop if target == 4
		collapse (sum) conflict wscale cooperative, by(ccode year)
		
		sort ccode year 
		
		tempfile copdab
		
	save `copdab', replace
		

* Generate alliance indicators using COW data
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/alliance_v4.1_by_directed_yearly.csv"
		keep if year >= 1947 & year <= 2016
		sort ccode1 ccode2 year
		keep ccode1 ccode2 defense year
		
		collapse (max) defense, by(ccode1 ccode2 year)
			rename defense ally
			sort ccode1 ccode2 year
		
		tempfile allies
		
	save `allies', replace



* Generating Warsaw Pact Variable
	clear
		use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/atop3_0ddyrNNA.dta"
		keep if year >= 1947 & year <= 2016
		rename stateA ccode1
		rename stateB ccode2
		sort ccode1 ccode2 year
		keep if atopid1 == 3285 | atopid2 == 3285
		keep ccode1 year
		gen warsawpact = 1
		
		collapse (mean) warsawpact, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
		
		tempfile warsawpact
		
	save `warsawpact', replace


* Generate specific file for US allies only
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/alliance_v4.1_by_directed_yearly.csv"
		keep if year >= 1947 & year<=2016
		sort ccode1 ccode2 year
		keep ccode1 ccode2 defense year
		keep if ccode2 == 2
		gen usally = 0
		replace usally = 1 if ccode2 == 2 & defense == 1
		
		collapse (max) usally, by (ccode1 year)
			keep if usally == 1
			gen ccode2 = ccode1
			rename ccode1 ccode
			sort ccode2 year
		
		tempfile usally
		
	save `usally', replace


* UN Voting Data
	clear
		use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/Dyadic13undirected.dta"
		keep if ccode1 == 2
		drop ccode1 
		rename ccode2 ccode
		sort ccode year
		keep ccode year ideal1 ideal2 absidealdiff s2un s3un agree2un agree3un
		destring s2un agree2un, ignore("NA") replace
		sort ccode year
		
		tempfile unvoting
		
	save `unvoting', replace


*Generate NATO indicator
	clear
		use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/atop3_0ddyrNNA.dta"
		rename stateA ccode1
		rename stateB ccode2
		keep if year >=1947
		gen NATO = 0
			foreach var of varlist atopid1-atopid5 {
			replace NATO = 1 if `var' == 3180
			}
		keep ccode1 year NATO 
		sort ccode1 year
		
		collapse (max) NATO, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
		
		tempfile NATO
		
	save `NATO', replace


* Inverse Distance Weighted Measures
* Read in Minimum Distance Data from R CShapes Package
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/cshapes_0.4-2_mindist_COW.csv", delimiter(space) encoding(ISO-8859-1)
		tempfile mindist
		keep if year >= 1950
		gen mindist2 = mindist+1
		replace mindist2 = 0 if mindist2>451
		replace mindist2 = . if ccode1 == ccode2
		replace mindist2 = 1/mindist2 
		sort ccode1 ccode2 year
		
	save `mindist', replace

	
* Inverse Distance Troops Spatial Measure (not row standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `troops', nogen
		sort ccode1 ccode2 year

		spmon troops, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_troops) file(w_troops) 
		
		collapse (mean) w_troops, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_troops
		
	save `w_troops', replace	
	

* Inverse Distance Hierarchy Spatial Measure (not row standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `hierarchy', nogen
		sort ccode1 ccode2 year

		spmon hierarchy, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_hierarchy) file(w_hierarchy) 
		
		collapse (mean) w_hierarchy, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_hierarchy
		
	save `w_hierarchy', replace
	
	
* Inverse Distance US Exports Spatial Measure (Not Row Standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `trade2', nogen
		sort ccode1 ccode2 year

		spmon exports, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_exports) file(w_exports) 
		
		collapse (mean) w_exports, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_exports
		
	save `w_exports', replace

	
* Inverse Distance US Imports Spatial Measure (Not Row Standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `trade2', nogen
		sort ccode1 ccode2 year

		spmon imports, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_imports) file(w_imports) 
		
		collapse (mean) w_imports, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_imports
		
	save `w_imports', replace	
	
	
* Inverse Distance Spatial Lag of Defense Burden (Not Row Standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `defburden2', nogen
		sort ccode1 ccode2 year

		spmon defenseburden, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_defburden) file(w_defburden) 
		
		collapse (mean) w_defburden, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
		
		tempfile w_defburden
		
	save `w_defburden', replace


* Inverse Distance Spatial Ally Variable
	clear
		use `mindist', replace
		merge 1:1 ccode1 ccode2 year using `allies', nogen
		sort ccode1 ccode2 year
		replace ally = 0 if ally == .

		spmon ally, i(ccode1) k(ccode2) weightvar(mindist2) time(year) sename(w_allies) file(w_allies) 
		
		collapse (mean) w_allies, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_allies
		
	save `w_allies', replace
	
	
* Inverse Distance Spatial US Ally Variable
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `usally', nogen
		replace usally = 0 if usally == .
		sort ccode1 ccode2 year
		
		spmon usally, i(ccode1) k(ccode2) weightvar(mindist2) time(year) sename(w_usally) file(w_usally) 
		
		collapse (mean) w_usally, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_usally
		
	save `w_usally', replace	
	

* Inverse Distance Spatial MID total count (not row standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `MIDs2', nogen
		replace mids = 0 if mids == .
		sort ccode1 ccode2 year
		
		spmon mids, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_mids) file(w_mids) 
		
		collapse (mean) w_mids, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_mids
		
	save `w_mids', replace		
	
	
* Inverse Distance Spatial MID initiation count (not row standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `MIDs2_in', nogen
		replace mids_initiate = 0 if mids_initiate == .
		sort ccode1 ccode2 year
		
		spmon mids_initiate, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_mids_initiate) file(w_mids_initiate) 
		
		collapse (mean) w_mids_initiate, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_mids_initiate
		
	save `w_mids_initiate', replace		
	
	
* Inverse Distance Spatial MID targeted count (not row standardized)
	clear
		use `mindist', replace
		merge m:1 ccode2 year using `MIDs2_ta', nogen
		replace mids_target = 0 if mids_target == .
		sort ccode1 ccode2 year
		
		spmon mids_target, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_mids_target) file(w_mids_target) 
		
		collapse (mean) w_mids_target, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
			
		tempfile w_mids_target
		
	save `w_mids_target', replace		
		
	
	
* PRIO Conflict Data (Not Row Standardized)
	clear
		use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/124920_1ucdp-prio-_2015.dta"
		keep if year >= 1950
		keep conflictid year sidea location intensity type startdate ependdate 
			* Conflict Type
			* 1. Extrasystemic
			* 2. Interstate
			* 3. Internal
			* 4. Internationalized internal conflict
		* Keeps internal and internationalized internal conflicts only
		egen match = anymatch(type), values(3)
		keep if match
		kountry location, from(other) stuck
		rename _ISO3N_ ccode
		kountry ccode, from(iso3n) to(cown)
		drop ccode
		rename _COWN_ ccode
		sort ccode year conflictid
		replace ccode = 365 if location == "Russia (Soviet Union)"
		replace ccode = 490 if location == "DR Congo (Zaire)"
		replace ccode = 345 if location == "Serbia (Yugoslavia)"
		replace ccode = 678 if location == "Yemen (North Yemen)"
		replace ccode = 626 if location == "South Sudan"
		replace ccode = 580 if location == "Madagascar (Malagasy)"
		collapse (max) intensity, by(ccode year) 
			sort ccode year
			rename intensity civilconflict
			
			tempfile prioconflict
			
		save `prioconflict', replace
		
			rename ccode ccode2
			sort ccode2 year
		
		tempfile prioconflict2
		
	save `prioconflict2', replace

	clear
		use `mindist'
		merge m:1 ccode2 year using `prioconflict2', nogen
		replace civilconflict = 0 if civilconflict == .
		sort ccode1 ccode2 year

		spmon civilconflict, i(ccode1) k(ccode2) weightvar(mindist2) norowst time(year) sename(w_civilconflict) file(w_civilconflict)
		
		collapse (mean) w_civilconflict, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
		
		tempfile w_prioconflict
		
	save `w_prioconflict', replace	
		

* Creating Spatial Marxist Regime Variable
* Merge Distance Data and Military Aid Data
	clear
		use `mindist'
		sort ccode1 ccode2 year
		* Marxist Leninist regime identifier. Based on Clark, Fordham, and Nordstrom 2011.
		gen marxist = 0
		* Cuba
		replace marxist = 1 if ccode2 == 40 & year >= 1961
		* East Germany 
		replace marxist = 1 if ccode2 == 265 & year >= 1949 & year <= 1990
		* Poland 
		replace marxist = 1 if ccode2 == 290 & year >= 1945 & year <= 1989
		* Hungary 
		replace marxist = 1 if ccode2 == 310 & year >= 1949 & year <= 1989
		* Czechoslovakia 
		replace marxist = 1 if ccode2 == 315 & year >= 1948 & year <= 1990
		* Albania
		replace marxist = 1 if ccode2 == 339 & year >= 1944 & year <= 1992
		* Yugoslavia 
		replace marxist = 1 if ccode2 == 345 & year >= 1943 & year <= 1992
		* Bulgaria
		replace marxist = 1 if ccode2 == 355 & year >= 1946 & year <= 1990
		* Romania 
		replace marxist = 1 if ccode2 == 360 & year >= 1947 & year <= 1989
		* Russia/USSR 
		replace marxist = 1 if ccode2 == 365 & year >= 1922 & year <= 1991
		* Benin
		replace marxist = 1 if ccode2 == 434 & year >= 1975 & year <= 1990
		* Congo-Brazzaville
		replace marxist = 1 if ccode2 == 484 & year >= 1970 & year <= 1992
		* Somalia 
		replace marxist = 1 if ccode2 == 520 & year >= 1976 & year <= 1991
		* Ethiopia 
		replace marxist = 1 if ccode2 == 530 & year >= 1974 & year <= 1991
		* Angola
		replace marxist = 1 if ccode2 == 540 & year >= 1975 & year <= 1992
		* Mozambique 
		replace marxist = 1 if ccode2 == 541 & year >= 1975 & year <= 1990
		* South Yemen 
		replace marxist = 1 if ccode2 == 680 & year >= 1967 & year <= 1990
		* Afghanistan
		replace marxist = 1 if ccode2 == 700 & year >= 1978 & year <= 1992
		* China
		replace marxist = 1 if ccode2 == 710 & year >= 1949
		* Mongolia 
		replace marxist = 1 if ccode2 == 712 & year >= 1924 & year <= 1992
		* North Korea 
		replace marxist = 1 if ccode2 == 731 & year >= 1948 & year <= 1992
		* Cambodia
		replace marxist = 1 if ccode2 == 811 & year >= 1975 & year <= 1989
		* Laos
		replace marxist = 1 if ccode2 == 812 & year >= 1975
		* Vietnam
		replace marxist = 1 if ccode2 == 816 & year >= 1976
		
		label var marxist "Marxist/Leninist Regime" 
		
		sort ccode1 ccode2 year
		
		spmon marxist, i(ccode1) k(ccode2) weightvar(mindist2) time(year) sename(w_marxist) file(w_marxist)
		
		collapse (mean) w_marxist, by(ccode1 year)
			rename ccode1 ccode
			sort ccode year
		
	save w_marxist.dta, replace
	

	
* US Government Partisan Composition
	clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/party_control.csv", encoding(ISO-8859-1)
		gen percent_dem = ((house_dems+senate_dems)/(total_senate+total_house))*100
		format percent_dem %9.1fc
		sort year
		
		tempfile party_control
		
	save `party_control', replace
	

* Start building data using polity as base
	clear
		use `polity'
		merge 1:1 ccode year using `gdp', gen(merge_gdp)
		merge 1:1 ccode year using `IMR', gen(merge_imr)
		merge 1:1 ccode year using `capabilities', gen(merge_cap)
		merge 1:1 ccode year using `borderstates', gen(merge_borderstates)
		replace borderstates = 0 if borderstates == . * merge_borderstates < 3
		merge 1:1 ccode year using `defburden', gen(merge_defburden)
		merge 1:1 ccode year using `w_defburden', gen(merge_wdefburden)
		merge 1:1 ccode year using `troops', gen(merge_troops)
		merge 1:1 ccode year using `hierarchy', gen(merge_hierarchy)
		merge 1:1 ccode year using `interstatewar', gen(merge_interstatewar)
		merge 1:1 ccode year using `civilwar', gen(merge_civilwar)
		merge 1:1 ccode year using `MIDs', gen(merge_mids)
		merge 1:1 ccode year using `MIDs_in', gen(merge_midsin)
		merge 1:1 ccode year using `MIDs_ta', gen(merge_midsta)
		merge 1:1 ccode year using `w_mids', gen(merge_wmids)
		merge 1:1 ccode year using `w_mids_initiate', gen(merge_wmidsin)
		merge 1:1 ccode year using `w_mids_target', gen(merge_wmidsta)
		merge 1:1 ccode year using `usally', gen(merge_usallies)
		merge 1:1 ccode year using `w_allies', gen(merge_wallies)
		merge 1:1 ccode year using `w_usally', gen(merge_wusally)
		merge 1:1 ccode year using `w_troops', gen(merge_wtroops)
		merge 1:1 ccode year using `w_hierarchy', gen(merge_w_hierarchy)		
		*merge 1:1 ccode year using `threat_environment', gen(merge_threatenv)
		merge 1:1 ccode year using `NATO', gen(merge_NATO)
		merge 1:1 ccode  year using `unvoting', gen(merge_unvoting)
		merge 1:1 ccode year using `warsawpact', gen(merge_warsawpact)
		merge 1:1 ccode year using `w_imports', gen(merge_imports)
		merge 1:1 ccode year using `w_exports', gen(merge_exports)
		merge 1:1 ccode year using `trade1', gen(merge_trade)
		merge 1:1 ccode year using `prioconflict', gen(merge_conflict)
		merge 1:1 ccode year using `w_prioconflict', gen(merge_w_conflict)
		merge 1:1 ccode year using w_marxist.dta, gen(merge_marxist)
		merge m:1 year using `party_control', gen(merge_partycontrol)
		merge 1:1 ccode year using `copdab', gen(merge_copdab)

		
* Generating Marxist regime variable
		gen marxist = 0
		* Cuba
		replace marxist = 1 if ccode == 40 & year >= 1961
		* East Germany 
		replace marxist = 1 if ccode == 265 & year >= 1949 & year <= 1990
		* Poland 
		replace marxist = 1 if ccode == 290 & year >= 1945 & year <= 1989
		* Hungary 
		replace marxist = 1 if ccode == 310 & year >= 1949 & year <= 1989
		* Czechoslovakia 
		replace marxist = 1 if ccode == 315 & year >= 1948 & year <= 1990
		* Albania
		replace marxist = 1 if ccode == 339 & year >= 1944 & year <= 1992
		* Yugoslavia 
		replace marxist = 1 if ccode == 345 & year >= 1943 & year <= 1992
		* Bulgaria
		replace marxist = 1 if ccode == 355 & year >= 1946 & year <= 1990
		* Romania 
		replace marxist = 1 if ccode == 360 & year >= 1947 & year <= 1989
		* Russia/USSR 
		replace marxist = 1 if ccode == 365 & year >= 1922 & year <= 1991
		* Benin
		replace marxist = 1 if ccode == 434 & year >= 1975 & year <= 1990
		* Congo-Brazzaville
		replace marxist = 1 if ccode == 484 & year >= 1970 & year <= 1992
		* Somalia 
		replace marxist = 1 if ccode == 520 & year >= 1976 & year <= 1991
		* Ethiopia 
		replace marxist = 1 if ccode == 530 & year >= 1974 & year <= 1991
		* Angola
		replace marxist = 1 if ccode == 540 & year >= 1975 & year <= 1992
		* Mozambique 
		replace marxist = 1 if ccode == 541 & year >= 1975 & year <= 1990
		* South Yemen 
		replace marxist = 1 if ccode == 680 & year >= 1967 & year <= 1990
		* Afghanistan
		replace marxist = 1 if ccode == 700 & year >= 1978 & year <= 1992
		* China
		replace marxist = 1 if ccode == 710 & year >= 1949
		* Mongolia 
		replace marxist = 1 if ccode == 712 & year >= 1924 & year <= 1992
		* North Korea 
		replace marxist = 1 if ccode == 731 & year >= 1948 & year <= 1992
		* Cambodia
		replace marxist = 1 if ccode == 811 & year >= 1975 & year <= 1989
		* Laos
		replace marxist = 1 if ccode == 812 & year >= 1975
		* Vietnam
		replace marxist = 1 if ccode == 816 & year >= 1976
		
		label var marxist "Marxist/Leninist Regime"	

		
		xtset ccode year
		gen lntpop = ln(tpop)
		replace mids_total = 0 if mids_total == .
		replace mids_initiate = 0 if mids_initiate == .
		replace mids_target = 0 if mids_target == .
		*gen movav3 = (l.mids+l2.mids+l3.mids)/3
		*gen w_movav3 = (l.w_mids+l2.w_mids+l3.w_mids)/3
		gen growth = ((realgdp-l.realgdp)/l.realgdp)*100
		replace war = 0 if war == .
		replace civilwar = 0 if civilwar == .
		replace NATO = 0 if NATO == .
		replace usally = 0 if usally == .
		gen w_lntroops = ln(w_troops+1)
		gen w_lndefburden = ln(w_defburden+1)
		gen w_lnallies = ln(w_allies+1)
		gen w_lnusally = ln(w_usally+1)
		replace warsawpact = 0 if warsawpact == .
		gen deploy_dummy = 0
		replace deploy_dummy = 1 if troops > 0 & troops != .
		gen deploy_new = 0
		replace deploy_new = 1 if troops > 0 & l.troops == 0 & l.troops != .
		gen lnexports = ln(exports+1)
		gen lnimports = ln(imports+1)
		gen trade_balance = exports-imports
		gen coldwar = 0
		replace coldwar = 1 if year <= 1988
		

		drop if ccode==2
		label var polity2 "Polity"
		label var growth "Growth"
		label var IMR "Infant Mortality Rate"
		label var borderstates "\# Border States"
		label var defenseburden "Defense Burden"
		label var lntroops "ln (Troops)"
		label var civilwar "Civil War"
		label var war "Interstate War"
		label var usally "US Ally"
		*label var threat_environment "Threat Environment"
		label var lntpop "ln (Population)"
		*label var movav3 "MIDs"
		label var w_lntroops "Spatial Troops"
		label var w_lndefburden "Spatial Lag"
		label var w_lnallies "Spatial Allies"
		label var w_lnusally "Spatial US Allies"
		label var warsawpact "Warsaw Pact Member"
		label var exports "US Exports to B"
		label var imports "US Imports from B"
		label var w_exports "Spatial US Exports"
		label var w_imports "Spatial US Imports"
		label var deploy_dummy "Deployment Dummy"
		label var deploy_new "New Deployment Dummy"
		label var lnexports "ln(Exports to B)"
		label var lnimports "ln(Imports from B)"
		label var trade_balance "Balance of Trade"

		order merge_*, last

	save "~/Dropbox/Projects/Troops and Conflict/Data/DATA_20170919.dta", replace

