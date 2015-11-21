source("utils.R")

#' Aggregate data by state
#' @param loans The loans data frame
#' @param col The name of the column of data you want to aggregate by state
#' @param func The function to apply during the aggregation of data
aggregate_by_state <- function(loans, col, func) {
    # Remove duplicate LoanKeys (presumably info about the same loan). There
    # are 871 duplicates out of 113,937 rows total. Should be Ok to throw away.
    dupes <- duplicated(loans[, "LoanKey"])
    l <- loans[!dupes, ]

    # Get just the relevant column and aggregate
    l <- loans[, c("BorrowerState", col)]
    dat <- aggregate(l, by=list(l[, "BorrowerState"]), FUN=func, simplify=TRUE)
    names(dat) <- c("State", "BorrowerState", col)

    dat
}


#' Plot a map of loan orignations by state
plot_loans_by_state <- function() {
    load_package("ggplot2")
    load_package("maps")

    # Get the number of loans by state by summing length of each BorrowerState
    l <- load_loans()
    l_by_state <- aggregate_by_state(l, "BorrowerState", length)
    # Convert state abbreviations to lowercase state names to match how ggplot2
    # references states in its map_data polygons (i.e. florida, virginia, etc).
    l_states <- l_by_state[, "State"]
    state.name <- c(state.name, "District of Columbia")  # Need to add in DC
    state_names <- state.name[match(l_states, c(state.abb, "DC"))]  # Add DC
    state_names_lower <- tolower(state_names)
    # Replace state abbreviations with state names and remove extra column
    l_by_state[, "State"] <- state_names_lower
    l_by_state <- l_by_state[, 1:2]

    # Merge our data with ggplot2's state polygons
    all_states <- map_data("state")  # From ggplot2
    states <- merge(all_states, l_by_state, by.x="region", by.y="State")

    # Need to capture environment since aes doesn't look in function environ
    .e <- environment()

    p <-
        ggplot(states, environment=.e) +  # Pass local environment to ggplot
            geom_polygon(
                aes(
                    x=long,
                    y=lat,
                    group=group,
                    fill=states[, "BorrowerState"]
                    ),
                colour="white"
            ) +
            scale_fill_continuous(
                low="thistle2",
                high="darkred",
                guide="colourbar"
            ) +
            theme_bw() +
            labs(
                fill="Loan Originations",
                title="",
                x="",
                y=""
            ) +
            scale_y_continuous(
                breaks=c()
            ) +
            scale_x_continuous(
                breaks=c()
            ) +
            theme(
                panel.border=element_blank()
            )
    print(p)
    ggsave("loan-originations-by-state.png")
}


#' Plot loan defaults by state
plot_state_defaults <- function() {
    load_package("ggplot2")
    load_package("maps")

    # Subset the data by Defaulted loans
    l <- load_loans()
    l <- subset(l, LoanStatus == "Defaulted")
    l_by_state <- aggregate_by_state(l, "BorrowerState", length)
    # Convert state abbreviations to lowercase state names to match how ggplot2
    # references states in its map_data polygons (i.e. florida, virginia, etc).
    l_states <- l_by_state[, "State"]
    state.name <- c(state.name, "District of Columbia")  # Need to add in DC
    state_names <- state.name[match(l_states, c(state.abb, "DC"))]  # Add DC
    state_names_lower <- tolower(state_names)
    # Replace state abbreviations with state names and remove extra column
    l_by_state[, "State"] <- state_names_lower
    l_by_state <- l_by_state[, 1:2]

    # Merge our data with ggplot2's state polygons
    all_states <- map_data("state")  # From ggplot2
    states <- merge(all_states, l_by_state, by.x="region", by.y="State")

    # Need to capture environment since aes doesn't look in function environ
    .e <- environment()

    p <-
        ggplot(states, environment=.e) +  # Pass local environment to ggplot
            geom_polygon(
                aes(
                    x=long,
                    y=lat,
                    group=group,
                    fill=states[, "BorrowerState"]
                    ),
                colour="white"
            ) +
            scale_fill_continuous(
                low="thistle2",
                high="darkred",
                guide="colourbar"
            ) +
            theme_bw() +
            labs(
                fill="Defaults",
                title="",
                x="",
                y=""
            ) +
            scale_y_continuous(
                breaks=c()
            ) +
            scale_x_continuous(
                breaks=c()
            ) +
            theme(
                panel.border=element_blank()
            )
    print(p)
    ggsave("loan-defaults-by-state.png")
}


#' Plot change in originations over time by state
plot_state_trends <- function() {
    load_package("ggplot2")
    load_package("maps")

    # Compare 2010-2011 and 2012-2013
    l <- load_loans()
    # Subset the data by date: call 2010-2011 'initial' and 2012-2013 'final'
    l_2010_2011 <- subset(l, LoanOriginationDate > as.Date("2009-12-31") &
                             LoanOriginationDate < as.Date("2012-01-01"))

    l_2012_2013 <- subset(l, LoanOriginationDate > as.Date("2011-12-31") &
                             LoanOriginationDate < as.Date("2014-01-01"))
    # Aggregate final and inital by state
    l_2010_2011_by_state <- aggregate_by_state(l_2010_2011, "BorrowerState",
                                               length)
    l_2012_2013_by_state <- aggregate_by_state(l_2012_2013, "BorrowerState",
                                               length)
    # Sort the data (you checked that the same states exist in both)
    l_2010_2011_by_state <- l_2010_2011_by_state[base::order(
        l_2010_2011_by_state[, "State"]), ]
    l_2012_2013_by_state <- l_2012_2013_by_state[base::order(
        l_2012_2013_by_state[, "State"]), ]
    # Calculate change by state
    initial <- l_2010_2011_by_state[, "BorrowerState"]
    final <- l_2012_2013_by_state[, "BorrowerState"]
    states_change <- (final - initial) / initial
    # Make new data frame to hold just the states and the change
    my_states <- l_2010_2011_by_state[, "State"]
    states_change <- data.frame(list(State=my_states, Change=states_change))

    # Convert state abbreviations to lowercase state names to match how ggplot2
    # references states in its map_data polygons (i.e. florida, virginia, etc).
    state.name <- c(state.name, "District of Columbia")  # Need to add in DC
    state_names <- state.name[match(my_states, c(state.abb, "DC"))]  # Add DC
    state_names_lower <- tolower(state_names)
    # Replace state abbreviations with state names and remove extra column
    states_change[, "State"] <- state_names_lower

    # Merge our data with ggplot2's state polygons
    all_states <- map_data("state")  # From ggplot2
    states <- merge(all_states, states_change, by.x="region", by.y="State",
                    all.x=TRUE)

    # Need to capture environment since aes doesn't look in function environ
    .e <- environment()

    p <-
        ggplot(environment=.e) +  # Pass local environment to ggplot
        # Plot differently (by adding layers to the map of the US) since not
        # all the states are present in this data set.
        geom_map(
            data=all_states,
            map=all_states,
            aes(x=long,
                y=lat,
                map_id=region
            ),
            colour="white",
            fill="white"
        ) +
        geom_map(
            data=states,
            map=all_states,
            aes(
                fill=Change,
                map_id=region
            ),
            color="#ffffff"
        ) +
        scale_fill_continuous(
            low="royalblue4",
            high="seagreen1",
            guide="colourbar"
        ) +
        theme_bw() +
        labs(
            fill="% Change in Originations\n(2010-11 to 2012-13)",
            title="",
            x="",
            y=""
        ) +
        scale_y_continuous(
            breaks=c()
        ) +
        scale_x_continuous(
            breaks=c()
        ) +
        theme(
            panel.border=element_blank()
        )
    print(p)
    ggsave("loan-changes-by-state.png")
}
