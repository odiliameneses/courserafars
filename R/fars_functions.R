

#' Read FARS filename into a tibble
#'
#' This function takes the filename as the only argument, checks if the file exists in the current working directory and returns a tibble (dataframe).
#' If the filename does not exist in the current working directory, an error message is printed.
#'
#' @param filename A string. Must be the name of the file saved on the current working directory.
#'
#'
#' @return A tibble() if the file exists. Otherwise, an error message.
#'
#' @importFrom readr read_csv
#' @examples
#' #File saved in current working directory:
#' \dontrun{fars_read('accident_2014.csv.bz2')
#' }
#' @export
#'
fars_read <- function(filename) {
  if(!file.exists(filename))
    stop("file '", filename, "' does not exist")
  data <- suppressMessages({
    readr::read_csv(filename, progress = FALSE)
  })
  dplyr::tbl_df(data)
}

#' Create standard FARS filename
#'
#' User enters the year (YYYY) to retrieve the standard filename for FARS data.
#' The output is a string that forms the name of the file as "accident_YYYY.csv.bz".
#'
#' @param year (YYYY) either character or integer.
#'
#' @return Returns a string: the filename with specified year and format(csv.bz2).
#'
#' @examples
#' \dontrun{make_filename(2020)
#' make_filename("2020")}
#'
#' @export
make_filename <- function(year) {
  year <- as.integer(year)
  sprintf("accident_%d.csv.bz2", year)
}

#' List of month/year by FARS filename
#'
#' This functions takes the years as a numeric vector,
#' checks if the fars data for the given years exists
#' in the current working directory and returns a list
#' of the same length as the input vector. Each element of the list
#' returns a tibble with 2 columns: the columns MONTH and YEAR from the filename.
#
#' If the filename is not found, the function returns an error message.
#'
#' @param years A numeric vector containing four-digit (YYYY) numeric values.
#'
#' @return A list with length equal to the length of numeric vector \code{years}
#' in case year are correctly provided and files exist in current working directory.
#' Elements of the list are
#' tibbles containing 2 columns, month and year from each filename.
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr select
#' @importFrom dplyr select
#' @importFrom magrittr %>%
#'
#' @examples
#' \dontrun{
#' fars_read_years(2013:2015)
#' }
fars_read_years <- function(years) {
  lapply(years, function(year) {
    file <- make_filename(year)
    tryCatch({
      dat <- fars_read(file)
      dplyr::mutate(dat, year = year) %>%
        dplyr::select(MONTH, year)
    }, error = function(e) {
      warning("invalid year: ", year)
      return(NULL)
    })
  })
}

#' Count observation grouped by month and year
#'
#' This function gathers the data from the FARS files for the \code{years} entered.
#' and provides the count of observations by month and year.
#' If the filename is not found, the function returns an error message.
#'
#' @param years A numeric vector containing four-digit (YYYY) numeric values.
#'
#' @return A tibble with the number of observation by month and year.
#'
#' @importFrom dplyr bind_rows
#' @importFrom dplyr group_by
#' @importFrom dplyr summarize
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @importFrom tidyr spread
#' @examples
#' \dontrun{
#' fars_summarize_years(2013:2015)
#' }
#'
#' @export
#'
fars_summarize_years <- function(years) {
  dat_list <- fars_read_years(years)
  dplyr::bind_rows(dat_list) %>%
    dplyr::group_by(year, MONTH) %>%
    dplyr::summarize(n = n()) %>%
    tidyr::spread(year, n)
}

#' Plot accidents' location by state and year
#'
#' This function gathers the localization of the accidents from the FARS files for the \code{year} and \code{state.num}entered.
#' and provides the count of observations by month and year.
#' The data must be saved on the current working directory as specified in \code{make_filename}
#' If the filename or the state number is not found, the function returns an error message.
#'
#'
#' @param state.num An integer: State number
#' @param year An integer: YEAR (YYYY)
#'
#' @return If state number and filename exists, a plot is made
#' where the state map is drawn and the accidents' location shown using points.
#'
#' @importFrom dplyr filter
#' @importFrom maps map
#' @importFrom graphics points
#' @importFrom rlang .data
#'
#'
#' @examples
#' \dontrun{fars_map_state(1,2013)}
#' @export
fars_map_state <- function(state.num, year) {
  filename <- make_filename(year)
  data <- fars_read(filename)
  state.num <- as.integer(state.num)

  if(!(state.num %in% unique(data$STATE)))
    stop("invalid STATE number: ", state.num)
  data.sub <- dplyr::filter(data, STATE == state.num)
  if(nrow(data.sub) == 0L) {
    message("no accidents to plot")
    return(invisible(NULL))
  }
  is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
  is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
  with(data.sub, {
    maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
              xlim = range(LONGITUD, na.rm = TRUE))
    graphics::points(LONGITUD, LATITUDE, pch = 46)
  })
}

