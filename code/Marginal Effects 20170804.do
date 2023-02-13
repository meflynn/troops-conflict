

	clear
	use "~/Dropbox/Projects/Troops and Conflict/Data/DATA_20170919.dta"
	cd "~/Dropbox/Projects/Troops and Conflict/Figures/"
	
	
	* Level equation
		xtset ccode year
	
		hetreg F.conflict c.lntroops##c.w_lntroops usally gdp polity2 lntpop cinc borderstates, het(c.lntroops##c.w_lntroops cinc borderstates) twostep

		sum w_lntroops if e(sample)
		local min = r(min)
		local max = r(max)
		local interval = ((`max'-`min')/10)
		margins,  dydx(lntroops) at(w_lntroops=(`min'(`interval')`max') (means) _all ) vsquish post

		#delimit ;
		marginsplot, xlabel(`min'(`interval')`max') recastci(rarea) recast(line) 
		ci1opts(color(%50) lcolor(%0) fintensity(100))   
		plot1opts(lwidth(.25)) 
		yline(0)
		xlabel(, format(%9.0fc)) 
		xdimension(w_lntroops)
		ylabel(, format(%9.2fc))
		ytitle("Marginal Effect")
		legend(off)
		title("")
		subtitle("")
		scale(.9)
		name(panela, replace)
		;
		#delimit cr
		graph export "Marginal effect level.pdf", replace 

		* Evaluation differences in marginal effects
			contrast rb1._at, effects
	
	
	* Variance equation
		xtset ccode year
	
		hetreg F.conflict c.lntroops##c.w_lntroops usally gdp polity2 lntpop cinc borderstates, het(c.lntroops##c.w_lntroops cinc borderstates) twostep

		sum w_lntroops if e(sample)
		local min = r(min)
		local max = r(max)
		local interval = ((`max'-`min')/10)
		margins,  dydx(lntroops) at(w_lntroops=(`min'(`interval')`max') (means) _all ) predict(equation(lnsigma2))  vsquish post

		#delimit ;
		marginsplot, xlabel(`min'(`interval')`max') recastci(rarea) recast(line) 
		ci1opts(color(%50) lcolor(%0) fintensity(100))   
		plot1opts(lwidth(.25)) 
		yline(0)
		xlabel(, format(%9.0fc)) 
		xdimension(w_lntroops)
		ylabel(, format(%9.2fc))
		ytitle("Marginal Effect")
		legend(off)
		title("")
		subtitle("")
		scale(.9)
		name(panela, replace)
		;
		#delimit cr
		graph export "Marginal effect variance.pdf", replace 

		* Evaluation differences in marginal effects
			contrast rb1._at, effects
			
		
		gen inter = lntroops*w_lntroops

		estsimp nbreg F.mids_initiate lntroops w_lntroops inter gdp polity2 defenseburden, cluster(ccode)
		
		setx mean

		setx lntroops 2 w_lntroops 2 inter 4
		simqi, ev genev(predicted_count0) msims(10000)

		setx lntroops 8 w_lntroops 8 inter 64
		simqi, ev genev(predicted_count1) msims(10000)

	
		/*foreach var of varlist predicted_count0-predicted_count1 {
		_pctile `var', p(2.5,97.5)
		replace `var' = . if `var' < r(r1) | `var' > r(r2)
		}
		*/
		twoway hist predicted_count0,  color(black%60) ///
		|| hist predicted_count1,  color(sky%60) ///
		xlab() ///
		legend(lab(1 "Low Troops") lab(2 "High Troops"))
