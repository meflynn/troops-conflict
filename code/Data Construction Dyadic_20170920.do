

	clear all
	cd "~/Dropbox/Projects/Troops and Conflict/Data"

		tempfile clear

		* Create directed dyads base data 
		clear
		ddyad 1946 2016
		sort ccode1 ccode2 year
		gen dyadid = (ccode1*1000)+ccode2
		sort dyadid year
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


		* Generate COW trade data (Trade values converted to constant 2005 US dollars)
		clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/Dyadic_COW_4.0.csv"
		keep if year >= 1950 & year<= 2016
		sort ccode1 ccode2 year
		mvdecode flow1 flow2, mv(-9)
		rename flow1 imports
		rename flow2 exports
		label var imports "From B to A"
		label var exports "From A to B"
		merge m:1 year using "/Users/michaelflynn/Dropbox/Data Files/US Government Files/BLS/cpi_1913_2015.dta", nogen
		keep if year >= 1950 & year<= 2016
		sum cpi if year == 2005, d 
		local cpi = r(mean)
		replace cpi = cpi/`cpi'
		replace imports = (imports*1000000)/cpi
		replace exports = (exports*1000000)/cpi
		replace imports = imports/1000000
		replace exports = exports/1000000
		sort year ccode1 ccode2
		keep ccode1 ccode2 year imports exports
		gen dyadid = (ccode1*1000)+ccode2
		rename imports imports_c
		rename exports exports_c
		keep if year >= 1950 & year<= 2005
		sort dyadid year
		tempfile trade_cow1
		save `trade_cow1', replace
		rename ccode1 ccode
		rename ccode2 ccode1
		rename ccode ccode2
		rename imports_c exports
		rename exports_c imports
		rename exports exports_c
		rename imports imports_c
		drop dyadid
		gen dyadid = (ccode1*1000)+ccode2
		sort dyadid year
		tempfile trade_cow2
		save `trade_cow2', replace
		append using `trade_cow1'
		sort dyadid year
		tempfile trade
		save `trade', replace
		
		
		* GDP Data (Constant 2005 Dollars.)
		clear
		import delimited "/Users/michaelflynn/Google Drive/US Security Commitments and Economic Gains/Data Files/Raw Data/expgdpv6.0/gdpv6.txt", delimiter(tab) varnames(1) encoding(ISO-8859-1)
		rename statenum ccode
		drop origin
		* Change Yemen country code. Begins in 1990, but we make the entry year 1991.
		* Vietnam is ok.
		replace ccode = 679 if ccode == 678 & year > 1990
		replace ccode = 255 if ccode == 260 & year > 1990
		keep if year >= 1945 & year<= 2005
		rename ccode ccode1
		rename realgdp realgdp_i
		rename pop pop_i
		sort ccode1 year
		tempfile gdp_i
		save `gdp_i', replace
		rename ccode1 ccode2
		rename realgdp_i realgdp_j
		rename pop_i pop_j
		tempfile gdp_j
		save `gdp_j', replace
		
		
		* COW capabilities data
		clear
			import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/NMC_5_0.csv", delimiter(comma) 
			* All countries codes ok.
			sort ccode year
			keep if year >= 1947 & year <= 2016
			mvdecode irst milex milper pec tpop upop cinc, mv(-9)
		
				collapse (max) milex-version, by(ccode year)
				
				tempfile capabilitiesbase
				
			save `capabilitiesbase'
			
				rename ccode ccode1
				foreach var of varlist milex milper pec tpop  upop cinc {
				rename `var' `var'_i
				}
				sort ccode1 year
			
			tempfile capabilities_i

		save `capabilities_i', replace
		
		use `capabilitiesbase', clear
		
			rename ccode ccode2
				foreach var of varlist milex milper pec tpop  upop cinc {
				rename `var' `var'_j
				}
				sort ccode2 year
			
			tempfile capabilities_j

		save `capabilities_j', replace 
		
		
		* Generate defense burden dependent variable
		clear
			use `capabilitiesbase'
			rename ccode ccode1
			keep ccode1 year milex
			sort ccode1 year
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
			sort ccode1 year
			merge 1:1 ccode1 year using `gdp_i', nogen
			keep if year >= 1947 & year <= 2016
			gen defenseburden = (milex/realgdp)*100
			sort ccode1 year
			tempfile defburden
			
		save `defburden', replace
		
			rename defenseburden defenseburden_i
			
			sort ccode1 year
			
			tempfile defburden_i
			
		save `defburden_i', replace
		
		use `defburden', clear
		
			rename defenseburden defenseburden_j
			rename ccode1 ccode2 
			
			sort ccode2 year
			
			tempfile defburden_j
			
		save `defburden_j', replace


		* Troops data
		clear
		import delimited "/Users/michaelflynn/Google Drive/US Security Commitments and Economic Gains/Data Files/Raw Data/troopMarch2005.txt", delimiter(tab) varnames(1) encoding(ISO-8859-1)
		drop region
		local i = 1950
		foreach var of varlist v3-v58 {
		rename `var' y_`i'
		local i = `i'+1
		}
		drop s-avg19962000
		drop in 1/30
		drop in 187/189
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
		xtset ccode year
		gen lntroops_ma = (lntroops+l.lntroops+l2.lntroops+l3.lntroops+l4.lntroops)/5
		label var lntroops_ma "Troops (Moving Average)"
		rename ccode ccode1
		sort ccode1 year
		rename troops troops_i
		rename lntroops lntroops_i
		rename lntroops_ma lntroops_ma_i
		tempfile troops_i
		save `troops_i', replace
		rename ccode1 ccode2
		rename troops_i troops_j
		rename lntroops_i lntroops_j
		rename lntroops_ma_i lntroops_ma_j
		tempfile troops_j
		save `troops_j', replace


		* Polity IV Data
		clear
		import excel "/Users/michaelflynn/Google Drive/US Security Commitments and Economic Gains/Data Files/Raw Data/p4v2014.xls", sheet("p4v2014") firstrow
		keep ccode country year polity2
		sort ccode year
		keep if year >= 1945 & year<= 2005
		* Adjusting codes for Russia and Yugoslavia/Serbia. note that Yemen codes are correct.
		* Vietnam/North Vietnam code needs to be changed to 816 as Polity has separate entries for unified Vietnam and North Vietnam.
		replace ccode = 345 if ccode == 347
		replace ccode = 365 if ccode == 364
		replace ccode = 816 if ccode == 818
		collapse (max) polity2, by(ccode year)
		rename ccode ccode1
		sort ccode1 year
		rename polity2 polity_i
		tempfile polity_i
		save `polity_i', replace
		rename polity_i polity_j
		rename ccode1 ccode2
		sort ccode2 year
		tempfile polity_j
		save `polity_j', replace

		
		
		* MID Data
		* Note these data were generated using NewGene software.
		* Excludes MIDs directly involving US.
		
		clear
			import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/MID_Dyad_Data.csv"
			sort cwkeynum ccode1 ccode2 year
			gen usmid = 1 if ccode1 == 2 & cwkeynum > 0 | ccode2 == 2 & cwkeynum > 0
			by cwkeynum: carryforward usmid, replace
			drop if usmid == 1
			
			gen dyadid = (ccode1*1000)+ccode2
			sort dyadid year
			
			tempfile MIDs
			
		save `MIDs', replace


		* Generate alliance indicators using COW data
		clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/alliance_v4.1_by_directed_yearly.csv"
		sort ccode1 ccode2 year
		keep if defense == 1
		keep ccode1 ccode2 defense year
		gen dyadid = (ccode1*1000)+ccode2
		sort dyadid year
		collapse (max) defense, by(dyadid year)
		sort dyadid year
		tempfile alliances
		save `alliances', replace


		* Generate US alliance indicators using COW data
		clear
		import delimited "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/alliance_v4.1_by_directed_yearly.csv"
		sort ccode1 ccode2 year
		keep if defense == 1
		keep if ccode1 == 2
		keep ccode2 defense year
		rename defense usally
		rename ccode2 ccode
		collapse (max) usally, by(ccode year)
		sort ccode year
		merge 1:1 ccode year using `countrylist', nogen
		replace usally = 0 if usally != 1
		drop if ccode == 2
		drop if year < 1950
		rename ccode ccode1
		rename usally usally_i
		sort ccode1 year
		tempfile usallies_i
		save `usallies_i', replace
		rename ccode1 ccode2
		rename usally_i usally_j
		sort ccode2 year
		tempfile usallies_j
		save `usallies_j', replace


		* Distance variable
		clear
		import delimited "/Users/michaelflynn/Google Drive/US Security Commitments and Economic Gains/Data Files/Raw Data/cshapes_0.4-2_mindist_COW.csv", delimiter(space) encoding(ISO-8859-1)
		gen dyadid = (ccode1*1000)+ccode2
		keep if year >= 1950 & year <= 2005
		sort dyadid year
		tempfile distance
		save `distance', replace


		* Ideal point distance variable
		clear
		use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/Dyadic13undirected.dta"
		keep ccode1 ccode2 year absidealdiff
		rename absidealdiff idealpointdistance
		keep if year >= 1950 & year <= 2016
		sort ccode1 ccode2 year
		gen dyadid = (ccode1*1000)+ccode2
		sort dyadid year		
		tempfile idealpointdistance
		save `idealpointdistance', replace


		* Generate events data conflict and cooperation for monadic models
		clear
		do "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/COPDAB/COPDAB Setup.do"		drop if TARGET == 4
		rename actor ccode1
		rename target ccode2
		drop if ccode1 == 2
		drop if ccode2 == 4
		gen dyadid = (ccode1*1000)+ccode2
		sort dyadid year 
		
		tempfile copdab
		
		save `copdab', replace
		

		

		* Merge files
		clear
		use `ddyads'
		sort dyadid year
		merge 1:1 dyadid year using `distance', gen(merge_distance)
		merge 1:1 dyadid year using `trade', gen(merge_trade)
		merge 1:1 dyadid year using `alliances', gen(merge_alliances)
		merge 1:1 dyadid year using `idealpointdistance', gen(merge_ideal)
		merge 1:1 dyadid year using `copdab', gen(merge_copdab)
		merge 1:1 dyadid year using `MIDs', gen(merge_mids)
		sort ccode1 year
		merge m:1 ccode1 year using `troops_i', gen(merge_troopsi)
		sort ccode2 year
		merge m:1 ccode2 year using `troops_j', gen(merge_troopsj)
		sort ccode1 year
		merge m:1 ccode1 year using `usallies_i', gen(merge_usalliesi)
		sort ccode2 year
		merge m:1 ccode2 year using `usallies_j', gen(merge_usalliesj)
		sort ccode1 year
		merge m:1 ccode1 year using `gdp_i', gen(merge_gdpi)
		sort ccode2 year
		merge m:1 ccode2 year using `gdp_j', gen(merge_gdpj)
		sort ccode1 year
		merge m:1 ccode1 year using `polity_i', gen(merge_polityi)
		sort ccode2 year
		merge m:1 ccode2 year using `polity_j', gen(merge_polityj)
		sort ccode1 year
		merge m:1 ccode1 year using `defburden_i', gen(merge_defburdeni)
		sort ccode2 year
		merge m:1 ccode2 year using `defburden_j', gen(merge_defburdenj)
		sort ccode1 year
		merge m:1 ccode1 year using `capabilities_i', gen(merge_capi)
		sort ccode2 year
		merge m:1 ccode2 year using `capabilities_j', gen(merge_capj)



		* marxist_i Leninist regime identifier. Based on Clark, Fordham, and Nordstrom 2011.
		sort ccode1 year
		gen marxist_i = 0
		* Cuba
		replace marxist_i = 1 if ccode1 == 40 & year >= 1961
		* East Germany 
		replace marxist_i = 1 if ccode1 == 265 & year >= 1949 & year <= 1990
		* Poland 
		replace marxist_i = 1 if ccode1 == 290 & year >= 1945 & year <= 1989
		* Hungary 
		replace marxist_i = 1 if ccode1 == 310 & year >= 1949 & year <= 1989
		* Czechoslovakia 
		replace marxist_i = 1 if ccode1 == 315 & year >= 1948 & year <= 1990
		* Albania
		replace marxist_i = 1 if ccode1 == 339 & year >= 1944 & year <= 1992
		* Yugoslavia 
		replace marxist_i = 1 if ccode1 == 345 & year >= 1943 & year <= 1992
		* Bulgaria
		replace marxist_i = 1 if ccode1 == 355 & year >= 1946 & year <= 1990
		* Romania 
		replace marxist_i = 1 if ccode1 == 360 & year >= 1947 & year <= 1989
		* Russia/USSR 
		replace marxist_i = 1 if ccode1 == 365 & year >= 1922 & year <= 1991
		* Benin
		replace marxist_i = 1 if ccode1 == 434 & year >= 1975 & year <= 1990
		* Congo-Brazzaville
		replace marxist_i = 1 if ccode1 == 484 & year >= 1970 & year <= 1992
		* Somalia 
		replace marxist_i = 1 if ccode1 == 520 & year >= 1976 & year <= 1991
		* Ethiopia 
		replace marxist_i = 1 if ccode1 == 530 & year >= 1974 & year <= 1991
		* Angola
		replace marxist_i = 1 if ccode1 == 540 & year >= 1975 & year <= 1992
		* Mozambique 
		replace marxist_i = 1 if ccode1 == 541 & year >= 1975 & year <= 1990
		* South Yemen 
		replace marxist_i = 1 if ccode1 == 680 & year >= 1967 & year <= 1990
		* Afghanistan
		replace marxist_i = 1 if ccode1 == 700 & year >= 1978 & year <= 1992
		* China
		replace marxist_i = 1 if ccode1 == 710 & year >= 1949
		* Mongolia 
		replace marxist_i = 1 if ccode1 == 712 & year >= 1924 & year <= 1992
		* North Korea 
		replace marxist_i = 1 if ccode1 == 731 & year >= 1948 & year <= 1992
		* Cambodia
		replace marxist_i = 1 if ccode1 == 811 & year >= 1975 & year <= 1989
		* Laos
		replace marxist_i = 1 if ccode1 == 812 & year >= 1975
		* Vietnam
		replace marxist_i = 1 if ccode1 == 816 & year >= 1976
		label var marxist_i "marxist_i/Leninist Regime"


		* marxist_j Leninist regime identifier. Based on Clark, Fordham, and Nordstrom 2011.
		sort ccode2 year
		gen marxist_j = 0
		* Cuba
		replace marxist_j = 1 if ccode2 == 40 & year >= 1961
		* East Germany 
		replace marxist_j = 1 if ccode2 == 265 & year >= 1949 & year <= 1990
		* Poland 
		replace marxist_j = 1 if ccode2 == 290 & year >= 1945 & year <= 1989
		* Hungary 
		replace marxist_j = 1 if ccode2 == 310 & year >= 1949 & year <= 1989
		* Czechoslovakia 
		replace marxist_j = 1 if ccode2 == 315 & year >= 1948 & year <= 1990
		* Albania
		replace marxist_j = 1 if ccode2 == 339 & year >= 1944 & year <= 1992
		* Yugoslavia 
		replace marxist_j = 1 if ccode2 == 345 & year >= 1943 & year <= 1992
		* Bulgaria
		replace marxist_j = 1 if ccode2 == 355 & year >= 1946 & year <= 1990
		* Romania 
		replace marxist_j = 1 if ccode2 == 360 & year >= 1947 & year <= 1989
		* Russia/USSR 
		replace marxist_j = 1 if ccode2 == 365 & year >= 1922 & year <= 1991
		* Benin
		replace marxist_j = 1 if ccode2 == 434 & year >= 1975 & year <= 1990
		* Congo-Brazzaville
		replace marxist_j = 1 if ccode2 == 484 & year >= 1970 & year <= 1992
		* Somalia 
		replace marxist_j = 1 if ccode2 == 520 & year >= 1976 & year <= 1991
		* Ethiopia 
		replace marxist_j = 1 if ccode2 == 530 & year >= 1974 & year <= 1991
		* Angola
		replace marxist_j = 1 if ccode2 == 540 & year >= 1975 & year <= 1992
		* Mozambique 
		replace marxist_j = 1 if ccode2 == 541 & year >= 1975 & year <= 1990
		* South Yemen 
		replace marxist_j = 1 if ccode2 == 680 & year >= 1967 & year <= 1990
		* Afghanistan
		replace marxist_j = 1 if ccode2 == 700 & year >= 1978 & year <= 1992
		* China
		replace marxist_j = 1 if ccode2 == 710 & year >= 1949
		* Mongolia 
		replace marxist_j = 1 if ccode2 == 712 & year >= 1924 & year <= 1992
		* North Korea 
		replace marxist_j = 1 if ccode2 == 731 & year >= 1948 & year <= 1992
		* Cambodia
		replace marxist_j = 1 if ccode2 == 811 & year >= 1975 & year <= 1989
		* Laos
		replace marxist_j = 1 if ccode2 == 812 & year >= 1975
		* Vietnam
		replace marxist_j = 1 if ccode2 == 816 & year >= 1976
		label var marxist_j "marxist_j/Leninist Regime"


		* Note: OECD officially forms in 1961. Pre-1961 coding is for OEEC.
		sort ccode1 year
		gen oecd_i = 0
		replace oecd_i = 1 if ccode1 == 900 & year >= 1971
		replace oecd_i = 1 if ccode1 == 305 & year >= 1948
		replace oecd_i = 1 if ccode1 == 211 & year >= 1948
		replace oecd_i = 1 if ccode1 == 20 & year >= 1961
		replace oecd_i = 1 if ccode1 == 155 & year >= 2010
		replace oecd_i = 1 if ccode1 == 316 & year >= 1995 
		replace oecd_i = 1 if ccode1 == 390 & year >= 1948
		replace oecd_i = 1 if ccode1 == 366 & year >= 2010
		replace oecd_i = 1 if ccode1 == 375 & year >= 1969
		replace oecd_i = 1 if ccode1 == 220 & year >= 1948
		replace oecd_i = 1 if ccode1 == 255 | ccode1 == 260 & year >= 1949
		replace oecd_i = 1 if ccode1 == 350 & year >= 1948
		replace oecd_i = 1 if ccode1 == 310 & year >= 1996
		replace oecd_i = 1 if ccode1 == 395 & year >= 1948
		replace oecd_i = 1 if ccode1 == 205 & year >= 1948
		replace oecd_i = 1 if ccode1 == 666 & year >= 2010
		replace oecd_i = 1 if ccode1 == 325 & year >= 1948
		replace oecd_i = 1 if ccode1 == 740 & year >= 1964
		replace oecd_i = 1 if ccode1 == 732 & year >= 1996
		replace oecd_i = 1 if ccode1 == 212 & year >= 1948
		replace oecd_i = 1 if ccode1 == 70 & year >= 1994
		replace oecd_i = 1 if ccode1 == 210 & year >= 1948
		replace oecd_i = 1 if ccode1 == 920 & year >= 1973
		replace oecd_i = 1 if ccode1 == 385 & year >= 1948
		replace oecd_i = 1 if ccode1 == 290 & year >= 1961
		replace oecd_i = 1 if ccode1 == 235 & year >= 1948
		replace oecd_i = 1 if ccode1 == 317 & year >= 2000
		replace oecd_i = 1 if ccode1 == 349 & year >= 2010
		replace oecd_i = 1 if ccode1 == 230 & year >= 1958
		replace oecd_i = 1 if ccode1 == 380 & year >= 1948
		replace oecd_i = 1 if ccode1 == 225 & year >= 1948
		replace oecd_i = 1 if ccode1 == 640 & year >= 1948
		replace oecd_i = 1 if ccode1 == 200 & year >= 1948
		replace oecd_i = 1 if ccode1 == 2 & year >= 1961
		label var oecd_i "OECD Member"


		* Note: OECD officially forms in 1961. Pre-1961 coding is for OEEC.
		sort ccode2 year
		gen oecd_j = 0
		replace oecd_j = 1 if ccode2 == 900 & year >= 1971
		replace oecd_j = 1 if ccode2 == 305 & year >= 1948
		replace oecd_j = 1 if ccode2 == 211 & year >= 1948
		replace oecd_j = 1 if ccode2 == 20 & year >= 1961
		replace oecd_j = 1 if ccode2 == 155 & year >= 2010
		replace oecd_j = 1 if ccode2 == 316 & year >= 1995 
		replace oecd_j = 1 if ccode2 == 390 & year >= 1948
		replace oecd_j = 1 if ccode2 == 366 & year >= 2010
		replace oecd_j = 1 if ccode2 == 375 & year >= 1969
		replace oecd_j = 1 if ccode2 == 220 & year >= 1948
		replace oecd_j = 1 if ccode2 == 255 | ccode2 == 260 & year >= 1949
		replace oecd_j = 1 if ccode2 == 350 & year >= 1948
		replace oecd_j = 1 if ccode2 == 310 & year >= 1996
		replace oecd_j = 1 if ccode2 == 395 & year >= 1948
		replace oecd_j = 1 if ccode2 == 205 & year >= 1948
		replace oecd_j = 1 if ccode2 == 666 & year >= 2010
		replace oecd_j = 1 if ccode2 == 325 & year >= 1948
		replace oecd_j = 1 if ccode2 == 740 & year >= 1964
		replace oecd_j = 1 if ccode2 == 732 & year >= 1996
		replace oecd_j = 1 if ccode2 == 212 & year >= 1948
		replace oecd_j = 1 if ccode2 == 70 & year >= 1994
		replace oecd_j = 1 if ccode2 == 210 & year >= 1948
		replace oecd_j = 1 if ccode2 == 920 & year >= 1973
		replace oecd_j = 1 if ccode2 == 385 & year >= 1948
		replace oecd_j = 1 if ccode2 == 290 & year >= 1961
		replace oecd_j = 1 if ccode2 == 235 & year >= 1948
		replace oecd_j = 1 if ccode2 == 317 & year >= 2000
		replace oecd_j = 1 if ccode2 == 349 & year >= 2010
		replace oecd_j = 1 if ccode2 == 230 & year >= 1958
		replace oecd_j = 1 if ccode2 == 380 & year >= 1948
		replace oecd_j = 1 if ccode2 == 225 & year >= 1948
		replace oecd_j = 1 if ccode2 == 640 & year >= 1948
		replace oecd_j = 1 if ccode2 == 200 & year >= 1948
		replace oecd_j = 1 if ccode2 == 2 & year >= 1961
		label var oecd_j "OECD Member"

		gen lnexports = ln(exports+1)
		gen lnimports = ln(imports+1)
		gen lngdp_i = ln(realgdp_i)
		gen lngdp_j = ln(realgdp_j)
		gen lnpop_i = ln(pop_i)
		gen lnpop_j = ln(pop_j)
		gen lndistance = ln(mindist+1) 
		egen politymin = rowmin(polity_i polity_j)
		egen troops_min_ma = rowmin(lntroops_ma_i lntroops_ma_j)
		gen troops_ma_inter = lntroops_ma_i*lntroops_ma_j
		gen jointusallies = 0
		replace jointusallies = 1 if usally_i == 1 & usally_j == 1
		gen importance_trade = (((imports*1000000)+(exports*1000000))/(realgdp_i*1000000))*100
		gen importance_exports = ((exports*1000000)/(realgdp_i*1000000))*100
		gen importance_imports = ((imports*1000000)/(realgdp_i*1000000))*100
		gen marxistdyad = 0
		replace marxistdyad = 1 if marxist_i == 1 | marxist_j == 1
		gen oecddyad = 0
		replace oecddyad = 1 if oecd_i == 1 | oecd_j == 1
		gen year2 = year^2
		gen year3 = year^3
		note: Suffixes on trade variables represent the source (Gleditsch and COW). Import and export variables without suffixes are the composite variables we use for the analaysis.

		drop if ccode1 == 2
		drop if ccode2 == 2
		drop if year < 1950
		drop if dyadid <=2999
		replace defense = 0 if defense == .
		drop merge*
		*drop cpi
		drop stateid
		drop if year>2005
		drop if ccode1 == . & ccode2 == .
		drop if dyadid == .
		order dyadid ccode1 ccode2 year imports* importance* exports* defense* usally* jointusallies troops* lntroops* pop* lnpop* realgdp* lngdp* mindist lndistance polity*
		label var imports "Imports"
		label var exports "Exports"
		label var importance_trade "Trade/GDP"
		label var importance_exports "Exports/GDP"
		label var importance_imports "Imports/GDP"
		label var jointusallies "Joint US Allies"
		label var troops_i "Troops$ _i$"
		label var troops_j "Troops$ _j$"
		label var lntroops_i "ln(Troops$ _{i}$)"
		label var lntroops_j "ln(Troops$ _{j}$)"
		label var lntroops_ma_i "ln(Troops$ _{i}$) Moving Average"
		label var lntroops_ma_j "ln(Troops$ _{j}$) Moving Average"
		label var troops_ma_inter "Troops$ _i$ $\times$ Troops$ _j$"
		label var usally_i "US Ally$ _i$"
		label var usally_j "US Ally$ _j$"
		label var defense "Allies"
		label var troops_min_ma "Smallest Deployment"
		label var pop_i "Population$ _i$"
		label var pop_j "Population$ _j$"
		label var lnpop_i "ln(Population$ _i$)"
		label var lnpop_j "ln(Population$ _j$)"
		label var realgdp_i "GDP$ _i$"
		label var realgdp_j "GDP$ _j$"
		label var lngdp_i "ln(GDP$ _i$)"
		label var lngdp_j "ln(GDP$ _{j}$)"
		label var mindist "Distance"
		label var lndistance "ln(Distance)"
		label var polity_i "Polity$ _i$"
		label var polity_j "Polity$ _j$"
		label var politymin "Low Polity Score"
		label var marxist_i "Marxist/Leninist Regime$ _i$"
		label var marxist_j "Marxist/Leninist Regime$ _j$"
		label var marxistdyad "Marxist/Leninist Partner"
		label var oecd_i "OECD Member$ _i$"
		label var oecd_j "OECD Member$ _j$"
		label var oecddyad "OECD Partner"
		label var year "Year"
		label var idealpointdistance "Ideal Point Distance"


	save "~/Dropbox/Projects/Troops and Conflict/Data/Data_Dyadic_20171006.dta", replace


