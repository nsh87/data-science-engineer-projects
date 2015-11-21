source("utils.R")

# All the numeric columns from the loans data
numeric_cols <- c("BorrowerRate",
                  "LenderYield",
                  "EstimatedLoss",
                  "EstimatedReturn",
                  "ProsperRating..numeric.",
                  "ProsperScore",
                  "ListingCategory..numeric.",
                  "EmploymentStatusDuration",
                  "CreditScoreRangeLower",
                  "CreditScoreRangeUpper",
                  "CurrentCreditLines",
                  "OpenCreditLines",
                  "TotalCreditLinespast7years",
                  "OpenRevolvingAccounts",
                  "OpenRevolvingMonthlyPayment",
                  "InquiriesLast6Months",
                  "TotalInquiries",
                  "CurrentDelinquencies",
                  "AmountDelinquent",
                  "DelinquenciesLast7Years",
                  "PublicRecordsLast10Years",
                  "PublicRecordsLast12Months",
                  "RevolvingCreditBalance",
                  "BankcardUtilization",
                  "AvailableBankcardCredit",
                  "TotalTrades",
                  "TradesNeverDelinquent..percentage.",
                  "TradesOpenedLast6Months",
                  "DebtToIncomeRatio",
                  "StatedMonthlyIncome",
                  "LoanCurrentDaysDelinquent",
                  "LoanCurrentDaysDelinquent",
                  "LoanMonthsSinceOrigination",
                  "MonthlyLoanPayment",
                  "LP_CustomerPayments",
                  "LP_CustomerPrincipalPayments",
                  "LP_InterestandFees",
                  "LP_ServiceFees",
                  "LP_CollectionFees",
                  "LP_GrossPrincipalLoss",
                  "LP_NetPrincipalLoss",
                  "LP_NonPrincipalRecoverypayments",
                  "Investors"
)


#' Pull out just the numeric data columns for comparison
#' @return The loans data with just the numeric columns, as numerics
load_loans_numeric <- function() {
    l <- load_loans()
    desired_cols <- numeric_cols
    return(l[, desired_cols])
}


#' Scale all columns between 0 and 1
scale_data <- function(dat) {
    maxs <- apply(dat, 2, max, na.rm=TRUE)
    mins <- apply(dat, 2, min, na.rm=TRUE)
    scaled <- scale(dat, center=mins, scale=maxs-mins)
}

#' Scatter plot high credit score against other variables
plot_against_credit_score <- function() {
    load_package("reshape2")
    load_package("ggplot2")

    # Get only the numeric columns from the loans data and scale cols to 0-1
    l <- load_loans_numeric()
    # Remove rows where CreditScoreRangeUpper (which we'll plot by) is NA
    na_rows <- is.na(l[, "CreditScoreRangeUpper"])
    l <- l[!na_rows, ]
    # Remove credit scores below 200 (minimum credit score possible)
    l <- subset(l, CreditScoreRangeUpper >= 200)

    # Scale standard normal (between 0 and 1)
    scaled <- scale_data(l)
    # Put back absolute values for Credit Score (not scaled) to improve plot
    scaled[, "CreditScoreRangeUpper"] <- l[, "CreditScoreRangeUpper"]

    # Pull out specific columns that we want to explore
    cols <- c("CreditScoreRangeUpper",
              "LenderYield",
              "EstimatedLoss",
              "EstimatedReturn",
              "BorrowerRate",
              "ProsperScore",
              "ListingCategory..numeric.",
              "EmploymentStatusDuration",
              "CurrentCreditLines",
              "OpenCreditLines",
              "InquiriesLast6Months",
              "CurrentDelinquencies",
              "DelinquenciesLast7Years",
              "RevolvingCreditBalance",
              "BankcardUtilization",
              "AvailableBankcardCredit",
              "AmountDelinquent",
              "PublicRecordsLast12Months",
              "DebtToIncomeRatio",
              "StatedMonthlyIncome",
              "Investors"
    )
    scaled <- scaled[, cols]


    # Transform the data to long format for facet wrap plotting with ggplot2
    scaled_long <- melt(
        data.frame(scaled), id.vars=c("CreditScoreRangeUpper"),
        variable.name="comparison",
        value.name="values",
        na.rm=TRUE
    )

    # ggplot2 can't do density plot with data that is <= 0, so fix that
    small <- scaled_long[, "values"] <= 0
    scaled_long[small, "values"] <- 0.00001

    # Need to capture environment since aes doesn't look in function environ
    .e <- environment()

    # Plot all data
    p <-
        ggplot(scaled_long, environment=.e) +
        stat_density2d(
            aes(
                x=CreditScoreRangeUpper,
                y=values,
                fill=..level..,
                alpha=..level..
            ),
            geom="polygon"
        ) +
        geom_point(
            aes(
                x=CreditScoreRangeUpper,
                y=values,
                alpha=0.2,
                color=comparison
            ),
            size=1
        ) +
        facet_wrap(~comparison, ncol=4) +
        labs(
            title="Comparison of Credit Score by Measure (Standard Normalized)",
            x="Upper Range Credit Score",
            y="Measure"
        ) +
        theme(
            legend.position='none',
            strip.text=element_text(size=8)
        )
    print(p)
    ggsave("compare-credit-score.png")
}

