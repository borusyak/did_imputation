# did_imputation
Event studies: robust and efficient estimation, testing, and plotting

This is a Stata package for Borusyak, Jaravel, and Spiess (2023), "Revisiting Event Study Designs: Robust and Efficient Estimation"

The package includes:
1) *did_imputation* command: for estimating causal effects & testing for pre-trends with the imputation method of Borusyak et al.
2) *event_plot* command: for plotting event study graphs after did_imputation, other robust estimators
(by de Chaisemartin and D'Haultfoeuille, Callaway and Sant'Anna, and Sun and Abraham), and conventional event study OLS
3) an example of using all five estimators in a simulated dataset and plotting the coefficients & confidence intervals for all of them at once.

Please contact Kirill Borusyak at k.borusyak@berkeley.edu with any questions.
