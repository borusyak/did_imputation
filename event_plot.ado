*! event_plot: Plot coefficients from a staggered adoption event study analysis
*! Version: June 1, 2021
*! Author: Kirill Borusyak
*! Please check the latest version at https://github.com/borusyak/did_imputation/
*! Citation: Borusyak, Jaravel, and Spiess, "Revisiting Event Study Designs: Robust and Efficient Estimation" (2021)

cap program drop event_plot
program define event_plot
syntax [anything(name=eqlist)] [, trimlag(numlist integer) trimlead(numlist integer) default_look stub_lag(string) stub_lead(string) plottype(string) ciplottype(string) together ///
		graph_opt(string asis) noautolegend legend_opt(string) perturb(numlist) shift(numlist integer) ///
		lag_opt(string) lag_ci_opt(string) lead_opt(string) lead_ci_opt(string) ///
		lag_opt1(string) lag_ci_opt1(string) lead_opt1(string) lead_ci_opt1(string) ///
		lag_opt2(string) lag_ci_opt2(string) lead_opt2(string) lead_ci_opt2(string) ///
		lag_opt3(string) lag_ci_opt3(string) lead_opt3(string) lead_ci_opt3(string) ///
		lag_opt4(string) lag_ci_opt4(string) lead_opt4(string) lead_ci_opt4(string) ///
		lag_opt5(string) lag_ci_opt5(string) lead_opt5(string) lead_ci_opt5(string) ///
		lag_opt6(string) lag_ci_opt6(string) lead_opt6(string) lead_ci_opt6(string) ///
		lag_opt7(string) lag_ci_opt7(string) lead_opt7(string) lead_ci_opt7(string) ///
		lag_opt8(string) lag_ci_opt8(string) lead_opt8(string) lead_ci_opt8(string) ///
		savecoef reportcommand noplot verbose alpha(real 0.05)]
qui {	
	// to-do: read dcdh or K_95; compatibility with the code from Goodman-Bacon, eventdd(?), did_multiplegt; use eventstudy_siegloch on options for many graphs; Burtch: ib4.rel_period_pos
	// Part 1: Initialize
	local verbose = ("`verbose'"=="verbose")
	if ("`plottype'"=="") local plottype connected
	if ("`ciplottype'"=="" & ("`plottype'"=="connected" | "`plottype'"=="line")) local ciplottype rarea
	if ("`ciplottype'"=="" & "`plottype'"=="scatter") local ciplottype rcap
	if (`verbose') noi di "#1"
	if ("`eqlist'"=="") local eqlist .
	if ("`shift'"=="") local shift 0
	if ("`savecoef'"=="savecoef") cap drop __event*

	tempname dot bmat Vmat bmat_current Vmat_current
	cap estimates store `dot' // cap in case there are no current estimate (but plotting is done based on previously saved ones)
		local rc_current = _rc
	local eq_n : word count `eqlist'
	if (`eq_n'>8) {
	    di as error "Combining at most 8 graphs are currently supported"
		error 198
	}
	
	if ("`perturb'"=="") {
	    local perturb 0
		if (`eq_n'>1) forvalues eq=1/`eq_n' {
			local perturb `perturb' `=0.2*`eq'/`eq_n''
		}
	}
	
	tokenize `eqlist'
	forvalues eq = 1/`eq_n' {
		local hashpos = strpos("``eq''","#")
	    if (`hashpos'==0) {  // e() syntax
			if ("``eq''"==".") {
				if (`rc_current'==0) estimates restore `dot'
					else error 301
			}
			else estimates restore ``eq''
			
			matrix `bmat' = e(b)
			cap matrix `Vmat' = e(V)
			if (_rc==0) local vregime = "matrix"
				else local vregime = "none"
		}
		else { // bmat#Vmat syntax
			matrix `bmat' = `=substr("``eq''",1,`hashpos'-1)'
			if (colsof(`bmat')==1) matrix `bmat' = `bmat''
			
			cap matrix `Vmat' = `=substr("``eq''",`hashpos'+1,.)'
			if (_rc==0) {
				if (rowsof(`Vmat')==1) local vregime = "row"
				else if (colsof(`Vmat')==1) {
					matrix `Vmat' = `Vmat''
					local vregime = "row"
				}
				else if (rowsof(`Vmat')==colsof(`Vmat')) local vregime = "matrix"
				else {
					di as error "The variance matrix " substr("``eq''",`hashpos'+1,.) " does not have an expected format in model `eq'"
					error 198
				}
			}
			else local vregime = "none"
		}
			
		* extract prefix and suffix
		foreach o in lag lead {
		    local currstub_`o' : word `eq' of `stub_`o''
			if ("`currstub_`o''"=="") local currstub_`o' : word 1 of `stub_`o''
			if ("`currstub_`o''"=="" & e(cmd)=="did_imputation" & "`o'"=="lag") local currstub_`o' tau#
			if ("`currstub_`o''"=="" & e(cmd)=="did_imputation" & "`o'"=="lead") local currstub_`o' pre#
			
			if ("`currstub_`o''"!="") {
				local hashpos = strpos("`currstub_`o''","#")
				if (`hashpos'==0) {
					di as error "stub_`o' is incorrectly specified for model `eq'"
					error 198
				}
				local prefix_`o' = substr("`currstub_`o''",1,`hashpos'-1)
				local postfix_`o' = substr("`currstub_`o''",`hashpos'+1,.)
				local lprefix_`o' = length("`prefix_`o''")
				local lpostfix_`o' = length("`postfix_`o''")
				local have_`o' = 1
			}
			else local have_`o' = 0
		}
		if (`have_lag'==0 & `have_lead'==0) {
			di as error "At least one of stub_lag and stub_lead has to be specified for model `eq'"
			error 198
		}
		if ("`currstub_lag'"=="`currstub_lead'") {
			di as error "stub_lag and stub_lead have to be different for model `eq'"
			error 198
		}
		
		// Part 2: Compute the number of available lags&leads
		local maxlag = -1
		local maxlead = 0 // zero leads = nothing since they start from 1, while lags start from 0
		local allvars : colnames `bmat'
		foreach v of local allvars {
			if (`have_lag') {
				if (substr("`v'",1,`lprefix_lag')=="`prefix_lag'" & substr("`v'",-`lpostfix_lag',.)=="`postfix_lag'") {
					if !mi(real(substr("`v'",`lprefix_lag'+1,length("`v'")-`lprefix_lag'-`lpostfix_lag'))) {
						local maxlag = max(`maxlag',real(substr("`v'",`lprefix_lag'+1,length("`v'")-`lprefix_lag'-`lpostfix_lag')))
					}
				}
			}
			if (`have_lead') {
				if (substr("`v'",1,`lprefix_lead')=="`prefix_lead'" & substr("`v'",-`lpostfix_lead',.)=="`postfix_lead'") {
					if !mi(real(substr("`v'",`lprefix_lead'+1,length("`v'")-`lprefix_lead'-`lpostfix_lead'))) {
						local maxlead = max(`maxlead',real(substr("`v'",`lprefix_lead'+1,length("`v'")-`lprefix_lead'-`lpostfix_lead')))
					}
				}
			}
		}
		
		local curr_trimlag : word `eq' of `trimlag'
			if mi("`curr_trimlag'") local curr_trimlag : word 1 of `trimlag'
			if mi("`curr_trimlag'") local curr_trimlag = -2
		local curr_trimlead : word `eq' of `trimlead'
			if mi("`curr_trimlead'") local curr_trimlead : word 1 of `trimlead'
			if mi("`curr_trimlead'") local curr_trimlead = -1
		
		local maxlag = cond(`curr_trimlag'>=-1, min(`maxlag',`curr_trimlag'), `maxlag') 
		local maxlead = cond(`curr_trimlead'>=0, min(`maxlead',`curr_trimlead'), `maxlead')
		if (_N<`maxlag'+`maxlead'+1) {
			di as err "Not enough observations to store `=`maxlag'+`maxlead'+1' coefficient estimates for model `eq'"
			error 198
		}
		if (`verbose') noi di "#2 Model `eq': `maxlag' lags, `maxlead' leads"

		// Part 3: Fill in coefs & CIs
		if ("`savecoef'"=="") tempvar H`eq' pos`eq' coef`eq' hi`eq' lo`eq'
		else {
			local H`eq' __event_H`eq'
			local pos`eq' __event_pos`eq'
			local coef`eq' __event_coef`eq'
			local hi`eq' __event_hi`eq'
			local lo`eq' __event_lo`eq'
		}
		
		local shift`eq' : word `eq' of `shift'
		if ("`shift`eq''"=="") local shift`eq' 0
		
		gen `H`eq'' = _n-1-`maxlead' if _n<=`maxlag'+`maxlead'+1
		gen `coef`eq'' = .
		gen `hi`eq'' = .
		gen `lo`eq'' = .
		label var `H`eq'' "Periods since treatment"
		if (`maxlag'>=0) forvalues h=0/`maxlag' {
			matrix `bmat_current' = J(1,1,.)
			cap matrix `bmat_current' = `bmat'[1,"`prefix_lag'`h'`postfix_lag'"]
			cap replace `coef`eq'' = `bmat_current'[1,1] if `H`eq''==`h' // because `bmat'[1,"`prefix_lag'`h'`postfix_lag'"] is only a matrix expression on macs			
			
			if ("`ciplottype'"!="none" & "`vregime'"!="none") {
				matrix `Vmat_current' = J(1,1,.)
				if ("`vregime'"=="matrix") cap matrix `Vmat_current' = `Vmat'["`prefix_lag'`h'`postfix_lag'","`prefix_lag'`h'`postfix_lag'"]
					else cap matrix `Vmat_current' = `Vmat'[1,"`prefix_lag'`h'`postfix_lag'"]
				local se = `Vmat_current'[1,1]^0.5
				cap replace `hi`eq'' = `bmat_current'[1,1]+invnorm(1-`alpha'/2)*`se' if `H`eq''==`h'
				cap replace `lo`eq'' = `bmat_current'[1,1]-invnorm(1-`alpha'/2)*`se' if `H`eq''==`h'
			}
		}
		if (`maxlead'>0) forvalues h=1/`maxlead' {
			matrix `bmat_current' = J(1,1,.)
			cap matrix `bmat_current' = `bmat'[1,"`prefix_lead'`h'`postfix_lead'"]
			cap replace `coef`eq'' = `bmat_current'[1,1] if `H`eq''==-`h'
			
			if ("`ciplottype'"!="none" & "`vregime'"!="none") {
				matrix `Vmat_current' = J(1,1,.)
				if ("`vregime'"=="matrix") cap matrix `Vmat_current' = `Vmat'["`prefix_lead'`h'`postfix_lead'","`prefix_lead'`h'`postfix_lead'"]
					else cap matrix `Vmat_current' = `Vmat'[1,"`prefix_lead'`h'`postfix_lead'"]
				local se = `Vmat_current'[1,1]^0.5
				cap replace `hi`eq'' = `bmat_current'[1,1]+invnorm(1-`alpha'/2)*`se' if `H`eq''==-`h'
				cap replace `lo`eq'' = `bmat_current'[1,1]-invnorm(1-`alpha'/2)*`se' if `H`eq''==-`h'
			}
		}
		count if !mi(`coef`eq'')
		if (r(N)==0) {
			if (`eq_n'==1) noi di as error `"No estimates found. Make sure you have specified stub_lag and stub_lead correctly."'
				else noi di as error `"No estimates found for the model "``eq''". Make sure you have specified stub_lag and stub_lead correctly."'
			error 498
		}
		if (`verbose') noi di "#3 `perturb'"
		
		local perturb_now : word `eq' of `perturb'
		if ("`perturb_now'"=="") local perturb_now = 0
		if (`verbose') noi di "#3A gen `pos`eq''=`H`eq''+`perturb_now'-`shift`eq''"
		gen `pos`eq''=`H`eq''+`perturb_now'-`shift`eq''
		if (`verbose') noi di "#3B"

	}
	cap estimates restore `dot'
	cap estimates drop `dot'
	
	// Part 4: Prepare graphs
	if ("`default_look'"!="") {
		local graph_opt xline(0, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)) `graph_opt'
		if (`eq_n'==1) {
			local lag_opt color(navy) `lag_opt'
			local lead_opt color(maroon) msymbol(S) `lead_opt'
			local lag_ci_opt color(navy%45 navy%45) `lag_ci_opt' // color repeated twice only for connected/scatter, o/w doesn't matter
			local lead_ci_opt color(maroon%45 maroon%45) `lead_ci_opt'
		}
		else {
			local lag_opt1 color(navy) `lag_opt1'
			local lag_opt2 color(maroon) `lag_opt2'
			local lag_opt3 color(forest_green) `lag_opt3'
			local lag_opt4 color(dkorange) `lag_opt4'
			local lag_opt5 color(teal) `lag_opt5'
			local lag_opt6 color(cranberry) `lag_opt6'
			local lag_opt7 color(lavender) `lag_opt7'
			local lag_opt8 color(khaki) `lag_opt8'
			local lead_opt1 color(navy) `lead_opt1'
			local lead_opt2 color(maroon) `lead_opt2'
			local lead_opt3 color(forest_green) `lead_opt3'
			local lead_opt4 color(dkorange) `lead_opt4'
			local lead_opt5 color(teal) `lead_opt5'
			local lead_opt6 color(cranberry) `lead_opt6'
			local lead_opt7 color(lavender) `lead_opt7'
			local lead_opt8 color(khaki) `lead_opt8'
			local lag_ci_opt1 color(navy%45 navy%45) `lag_ci_opt1'
			local lag_ci_opt2 color(maroon%45 maroon%45) `lag_ci_opt2'
			local lag_ci_opt3 color(forest_green%45 forest_green%45) `lag_ci_opt3'
			local lag_ci_opt4 color(dkorange%45 dkorange%45) `lag_ci_opt4'
			local lag_ci_opt5 color(teal%45 teal%45) `lag_ci_opt5'
			local lag_ci_opt6 color(cranberry%45 cranberry%45) `lag_ci_opt6'
			local lag_ci_opt7 color(lavender%45 lavender%45) `lag_ci_opt7'
			local lag_ci_opt8 color(khaki%45 khaki%45) `lag_ci_opt8'
			local lead_ci_opt1 color(navy%45 navy%45) `lead_ci_opt1'
			local lead_ci_opt2 color(maroon%45 maroon%45) `lead_ci_opt2'
			local lead_ci_opt3 color(forest_green%45 forest_green%45) `lead_ci_opt3'
			local lead_ci_opt4 color(dkorange%45 dkorange%45) `lead_ci_opt4'
			local lead_ci_opt5 color(teal%45 teal%45) `lead_ci_opt5'
			local lead_ci_opt6 color(cranberry%45 cranberry%45) `lead_ci_opt6'
			local lead_ci_opt7 color(lavender%45 lavender%45) `lead_ci_opt7'
			local lead_ci_opt8 color(khaki%45 khaki%45) `lead_ci_opt8'
		}
		local legend_opt region(lstyle(none)) `legend_opt'
	}
	
	local plotindex = 0
	local legend_order

	forvalues eq = 1/`eq_n' {
	    local lead_cmd
		local leadci_cmd
		local lag_cmd
		local lagci_cmd
		
		if ("`together'"=="") { // lead graph commands only when they are separate from lags
			count if !mi(`coef`eq'') & `H`eq''<0
			if (r(N)>0) {
				local ++plotindex
				local lead_cmd (`plottype' `coef`eq'' `pos`eq'' if !mi(`coef`eq'') & `H`eq''<0, `lead_opt' `lead_opt`eq'')
				local legend_order = `"`legend_order' `plotindex' "Pre-trend coefficients""'
			}

			count if !mi(`hi`eq'') & `H`eq''<0
			if (r(N)>0) {
				local ++plotindex
				local leadci_cmd (`ciplottype' `hi`eq'' `lo`eq'' `pos`eq'' if !mi(`hi`eq'') & `H`eq''<0, `lead_ci_opt' `lead_ci_opt`eq'')
			}
		}
		
		local lag_filter = cond("`together'"=="", "`H`eq''>=0", "1") 
		count if !mi(`coef') & `lag_filter'
		if (r(N)>0) {
			local ++plotindex
			local lag_cmd (`plottype' `coef`eq'' `pos`eq'' if !mi(`coef`eq'') & `lag_filter', `lag_opt' `lag_opt`eq'')
			if ("`together'"=="") local legend_order = `"`legend_order' `plotindex' "Treatment effects""'
		}

		count if !mi(`hi`eq'') & `lag_filter'
		if (r(N)>0) {
			local ++plotindex
			local lagci_cmd (`ciplottype' `hi`eq'' `lo`eq'' `pos`eq'' if !mi(`hi`eq'') & `lag_filter', `lag_ci_opt' `lag_ci_opt`eq'')
		}
		if ("`autolegend'"=="noautolegend") local legend = "" 
			else if ("`together'"=="together") local legend = "legend(off)" // show auto legend only for separate, o/w just one item
			else local legend legend(order(`legend_order') `legend_opt')
		local maincmd `maincmd' `lead_cmd' `leadci_cmd' `lag_cmd' `lagci_cmd'
		if (`verbose') noi di `"#4a ``eq'': `lead_cmd' `leadci_cmd' `lag_cmd' `lagci_cmd'"'
	}
	if (`verbose' | "`reportcommand'"!="") noi di `"twoway `maincmd' , `legend' `graph_opt'"'
	if ("`plot'"!="noplot") twoway `maincmd', `legend' `graph_opt'
}
end
