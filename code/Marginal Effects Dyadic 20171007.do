

	clear
	use "~/Dropbox/Projects/Troops and Conflict/Data/Data_Dyadic_20171006.dta"
	cd "~/Dropbox/Projects/Troops and Conflict/Figures/"
	
	
	* Level equation
		xtset dyadid year
	
		hetreg conflict c.lntroops_i##c.lntroops_j usally_i##usally_j defense cinc_i cinc_j lndistance c.polity_i##c.polity_j idealpointdistance, het(c.lntroops_i##c.lntroops_j) twostep

		sum lntroops_j if e(sample)
		local min = r(min)
		local max = r(max)
		local interval = ((`max'-`min')/10)
		margins,  dydx(lntroops_i) at(lntroops_j=(`min'(`interval')`max') (means) _all ) vsquish post

		#delimit ;
		marginsplot, xlabel(`min'(`interval')`max') recastci(rarea) recast(line) 
		ci1opts(color(%50) lcolor(%0) fintensity(100))   
		plot1opts(lwidth(.25)) 
		yline(0)
		xlabel(, format(%9.0fc)) 
		xdimension(lntroops_j)
		ylabel(, format(%9.2fc))
		ytitle("Marginal Effect")
		legend(off)
		title("")
		subtitle("")
		scale(.9)
		name(panela, replace)
		;
		#delimit cr
		graph export "Marginal effect level dyad.pdf", replace 

		* Evaluation differences in marginal effects
			contrast rb1._at, effects
	
	
	* Variance equation
		xtset dyadid year
	
		hetreg conflict c.lntroops_i##c.lntroops_j usally_i##usally_j defense cinc_i cinc_j lndistance c.polity_i##c.polity_j idealpointdistance, het(c.lntroops_i##c.lntroops_j) twostep

		sum lntroops_j if e(sample)
		local min = r(min)
		local max = r(max)
		local interval = ((`max'-`min')/10)
		margins,  dydx(lntroops_i) at(lntroops_j=(`min'(`interval')`max') (means) _all ) predict(equation(lnsigma2)) vsquish post

		#delimit ;
		marginsplot, xlabel(`min'(`interval')`max') recastci(rarea) recast(line) 
		ci1opts(color(%50) lcolor(%0) fintensity(100))   
		plot1opts(lwidth(.25)) 
		yline(0)
		xlabel(, format(%9.0fc)) 
		xdimension(lntroops_j)
		ylabel(, format(%9.2fc))
		ytitle("Marginal Effect")
		legend(off)
		title("")
		subtitle("")
		scale(.9)
		name(panela, replace)
		;
		#delimit cr
		graph export "Marginal effect variance dyad.pdf", replace 

		* Evaluation differences in marginal effects
			contrast rb1._at, effects
			
		
		gen inter = lntroops_i*lntroops_j

		estsimp reg conflict lntroops_i lntroops_j inter  defense cinc_i cinc_j lndistance polity_i polity_j idealpointdistance
		
		setx mean

		setx lntroops_i 2 lntroops_j 2 inter 4
		simqi, ev genev(predicted_count0) msims(10000)

		setx lntroops_i 8 lntroops_j 8 inter 64
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
