clear
	cd "~/Dropbox/Projects/Troops and Conflict/Data/"
	shp2dta using "~/Dropbox/Projects/Troops and Conflict/Data/Raw Data Files/ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp", data(mapdata) coordinates(mapcoord) replace
	use "~/Dropbox/Projects/Troops and Conflict/Data/mapdata.dta"
	
	rename GEOUNIT country
	do "~/Dropbox/Projects/Troops and Conflict/Data/COW code generator 20170809.do"
	rename cowcode ccode
	sort ccode 
	replace ccode = 255 if ccode == 260
		
		egen COWCODESUB = seq() 
		replace ccode = (COWCODESUB+1000) if ccode == .
		
	tempfile clear
	tempfile map_temp
	save `map_temp', replace
	
	
	clear
	*use "/Users/michaelflynn/Dropbox/Projects/Troops and Conflict/Data/Data_20151029.dta"
	use "~/Dropbox/Projects/Troops and Conflict/Data/DATA_20170804.dta"
	replace ccode = 255 if ccode == 260
	collapse (mean) mids troops, by(ccode)
	duplicates tag ccode, gen(tag)
	*drop if ccode == 255 & troops == .
	drop if ccode == .
	sort ccode 

	tempfile troops
	save `troops', replace

	merge 1:1 ccode using `map_temp', nogen
	*drop if _ID == .
	replace troops = . if troops == 0
	*replace troops = ln(troops+1)
	drop if country == "Antarctica"	
	
	* Map of MIDs 
	spmap mids using mapcoord, id(_ID) fcolor(Heat) ndocolor(black) ocolor(black) ndfcolor(gs14) ///
	legtitle("MIDs") legend(label(1 "0") pos(7) ring(0)) legstyle(2) clmethod(custom) clbreaks(0 1 2 3 4) gsize(6) ///
	plotregion(margin(-1 -1 0 0)) graphregion(margin(0 0 -20 -10)) xsize(7) ysize(4) ndsize(.05) osize(.04 .04 .04 .04 .04 .04) mosize(.05) ///
	name(UN, replace) 
	 
	graph export "~/Dropbox/Projects/Troops and Conflict/Figures/Map MIDs.pdf", replace

	
	
