% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/slide.R
\name{epi_slide}
\alias{epi_slide}
\title{Slide a function over variables in an \code{epi_df} object}
\usage{
epi_slide(
  x,
  f,
  ...,
  before,
  after,
  ref_time_values,
  time_step,
  new_col_name = "slide_value",
  as_list_col = FALSE,
  names_sep = "_",
  all_rows = FALSE
)
}
\arguments{
\item{x}{The \code{epi_df} object under consideration, \link[dplyr:group_by]{grouped}
or ungrouped. If ungrouped, all data in \code{x} will be treated as part of a
single data group.}

\item{f}{Function, formula, or missing; together with \code{...} specifies the
computation to slide. To "slide" means to apply a computation within a
sliding (a.k.a. "rolling") time window for each data group. The window is
determined by the \code{before} and \code{after} parameters described below. One time
step is typically one day or one week; see details for more explanation. If
a function, \code{f} must take a data frame with the same column names as
the original object, minus any grouping variables, containing the time
window data for one group-\code{ref_time_value} combination; followed by a
one-row tibble containing the values of the grouping variables for the
associated group; followed by any number of named arguments. If a formula,
\code{f} can operate directly on columns accessed via \code{.x$var} or \code{.$var}, as
in \code{~mean(.x$var)} to compute a mean of a column \code{var} for each
\code{ref_time_value}-group combination. The group key can be accessed via \code{.y}.
If \code{f} is missing, then \code{...} will specify the computation.}

\item{...}{Additional arguments to pass to the function or formula specified
via \code{f}. Alternatively, if \code{f} is missing, then the \code{...} is interpreted as
an expression for tidy evaluation; in addition to referring to columns
directly by name, the expression has access to \code{.data} and \code{.env} pronouns
as in \code{dplyr} verbs, and can also refer to \code{.x}, \code{.group_key}, and
\code{.ref_time_value}. See details.}

\item{before, after}{How far \code{before} and \code{after} each \code{ref_time_value} should
the sliding window extend? At least one of these two arguments must be
provided; the other's default will be 0. Any value provided for either
argument must be a single, non-\code{NA}, non-negative,
\link[vctrs:vec_cast]{integer-compatible} number of time steps. Endpoints of
the window are inclusive. Common settings: * For trailing/right-aligned
windows from \code{ref_time_value - time_step(k)} to \code{ref_time_value}: either
pass \code{before=k} by itself, or pass \verb{before=k, after=0}. * For
center-aligned windows from \code{ref_time_value - time_step(k)} to
\code{ref_time_value + time_step(k)}: pass \verb{before=k, after=k}. * For
leading/left-aligned windows from \code{ref_time_value} to \code{ref_time_value + time_step(k)}: either pass pass \code{after=k} by itself, or pass \verb{before=0, after=k}. See "Details:" about the definition of a time step,
(non)treatment of missing rows within the window, and avoiding warnings
about \code{before}&\code{after} settings for a certain uncommon use case.}

\item{ref_time_values}{Time values for sliding computations, meaning, each
element of this vector serves as the reference time point for one sliding
window. If missing, then this will be set to all unique time values in the
underlying data table, by default.}

\item{time_step}{Optional function used to define the meaning of one time
step, which if specified, overrides the default choice based on the
\code{time_value} column. This function must take a non-negative integer and
return an object of class \code{lubridate::period}. For example, we can use
\code{time_step = lubridate::hours} in order to set the time step to be one hour
(this would only be meaningful if \code{time_value} is of class \code{POSIXct}).}

\item{new_col_name}{String indicating the name of the new column that will
contain the derivative values. Default is "slide_value"; note that setting
\code{new_col_name} equal to an existing column name will overwrite this column.}

\item{as_list_col}{Should the slide results be held in a list column, or be
\link[tidyr:chop]{unchopped}/\link[tidyr:unnest]{unnested}? Default is \code{FALSE},
in which case a list object returned by \code{f} would be unnested (using
\code{\link[tidyr:unnest]{tidyr::unnest()}}), and, if the slide computations output data frames,
the names of the resulting columns are given by prepending \code{new_col_name}
to the names of the list elements.}

\item{names_sep}{String specifying the separator to use in \code{tidyr::unnest()}
when \code{as_list_col = FALSE}. Default is "_". Using \code{NULL} drops the prefix
from \code{new_col_name} entirely.}

\item{all_rows}{If \code{all_rows = TRUE}, then all rows of \code{x} will be kept in
the output even with \code{ref_time_values} provided, with some type of missing
value marker for the slide computation output column(s) for \code{time_value}s
outside \code{ref_time_values}; otherwise, there will be one row for each row in
\code{x} that had a \code{time_value} in \code{ref_time_values}. Default is \code{FALSE}. The
missing value marker is the result of \code{vctrs::vec_cast}ing \code{NA} to the type
of the slide computation output. If using \code{as_list_col = TRUE}, note that
the missing marker is a \code{NULL} entry in the list column; for certain
operations, you might want to replace these \code{NULL} entries with a different
\code{NA} marker.}
}
\value{
An \code{epi_df} object given by appending a new column to \code{x}, named
according to the \code{new_col_name} argument.
}
\description{
Slides a given function over variables in an \code{epi_df} object. See the \href{https://cmu-delphi.github.io/epiprocess/articles/slide.html}{slide vignette} for
examples.
}
\details{
To "slide" means to apply a function or formula over a rolling
window of time steps for each data group, where the window is entered at a
reference time and left and right endpoints are given by the \code{before} and
\code{after} arguments. The unit (the meaning of one time step) is implicitly
defined by the way the \code{time_value} column treats addition and subtraction;
for example, if the time values are coded as \code{Date} objects, then one time
step is one day, since \code{as.Date("2022-01-01") + 1} equals
\code{as.Date("2022-01-02")}. Alternatively, the time step can be set explicitly
using the \code{time_step} argument (which if specified would override the
default choice based on \code{time_value} column). If there are not enough time
steps available to complete the window at any given reference time, then
\code{epi_slide()} still attempts to perform the computation anyway (it does not
require a complete window). The issue of what to do with partial
computations (those run on incomplete windows) is therefore left up to the
user, either through the specified function or formula \code{f}, or through
post-processing. For a centrally-aligned slide of \code{n} \code{time_value}s in a
sliding window, set \code{before = (n-1)/2} and \code{after = (n-1)/2} when the
number of \code{time_value}s in a sliding window is odd and \code{before = n/2-1} and
\code{after = n/2} when \code{n} is even.

Sometimes, we want to experiment with various trailing or leading window
widths and compare the slide outputs. In the (uncommon) case where
zero-width windows are considered, manually pass both the \code{before} and
\code{after} arguments in order to prevent potential warnings. (E.g., \code{before=k}
with \code{k=0} and \code{after} missing may produce a warning. To avoid warnings,
use \verb{before=k, after=0} instead; otherwise, it looks too much like a
leading window was intended, but the \code{after} argument was forgotten or
misspelled.)

If \code{f} is missing, then an expression for tidy evaluation can be specified,
for example, as in:

\if{html}{\out{<div class="sourceCode">}}\preformatted{epi_slide(x, cases_7dav = mean(cases), before = 6)
}\if{html}{\out{</div>}}

which would be equivalent to:

\if{html}{\out{<div class="sourceCode">}}\preformatted{epi_slide(x, function(x, g) mean(x$cases), before = 6,
          new_col_name = "cases_7dav")
}\if{html}{\out{</div>}}

Thus, to be clear, when the computation is specified via an expression for
tidy evaluation (first example, above), then the name for the new column is
inferred from the given expression and overrides any name passed explicitly
through the \code{new_col_name} argument.
}
\examples{
# slide a 7-day trailing average formula on cases
jhu_csse_daily_subset \%>\%
  group_by(geo_value) \%>\%
  epi_slide(cases_7dav = mean(cases), before = 6) \%>\% 
  # rmv a nonessential var. to ensure new col is printed
  dplyr::select(-death_rate_7d_av) 

# slide a 7-day leading average
jhu_csse_daily_subset \%>\%
  group_by(geo_value) \%>\%
  epi_slide(cases_7dav = mean(cases), after = 6) \%>\%
  # rmv a nonessential var. to ensure new col is printed
  dplyr::select(-death_rate_7d_av)

# slide a 7-day centre-aligned average
jhu_csse_daily_subset \%>\%
  group_by(geo_value) \%>\%
  epi_slide(cases_7dav = mean(cases), before = 3, after = 3) \%>\% 
  # rmv a nonessential var. to ensure new col is printed
  dplyr::select(-death_rate_7d_av) 

# slide a 14-day centre-aligned average
jhu_csse_daily_subset \%>\%
  group_by(geo_value) \%>\%
  epi_slide(cases_7dav = mean(cases), before = 6, after = 7) \%>\% 
  # rmv a nonessential var. to ensure new col is printed
  dplyr::select(-death_rate_7d_av) 

# nested new columns
jhu_csse_daily_subset \%>\%
  group_by(geo_value) \%>\%
  epi_slide(a = data.frame(cases_2dav = mean(cases),
                           cases_2dma = mad(cases)),
            before = 1, as_list_col = TRUE)
}
