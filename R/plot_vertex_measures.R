#' Plot vertex-level graph measures at a single density or threshold
#'
#' Creates boxplots of a single vertex-level graph measure at a single density
#' or threshold, grouped by the variable specified by \code{group.by} and
#' optionally faceted by another variable (e.g., \emph{lobe} or \emph{network}).
#'
#' @param measure A character string of the graph measure to plot
#' @param facet.by Character string indicating the variable to facet by (if
#'   any). Default: \code{NULL}
#' @param group.by Character string indicating which variable to group the data
#'   by. Default: \code{getOption('bg.group')}
#' @param type Character string indicating the plot type. Default:
#'   \code{'violin'}
#' @param show.points Logical indicating whether or not to show individual data
#'   points (default: FALSE)
#' @param ylabel A character string for the y-axis label
#' @param ... Arguments passed to \code{geom_boxplot} or \code{geom_violin}
#' @inheritParams plot_brainGraph_multi
#' @export
#'
#' @return A \code{trellis} or \code{ggplot} object
#'
#' @author Christopher G. Watson, \email{cgwatson@@bu.edu}
#' @examples
#' \dontrun{
#' p.deg <- plot_vertex_measures(g[[1]], facet.by='network', measure='degree')
#' }

plot_vertex_measures <- function(g.list, measure, facet.by=NULL, group.by=getOption('bg.group'),
                                 type=c('violin', 'boxplot'),
                                 show.points=FALSE, ylabel=measure, ...) {
  variable <- value <- NULL
  gID <- getOption('bg.group')

  if (!is.brainGraphList(g.list)) try(g.list <- as_brainGraphList(g.list))
  DT <- vertex_attr_dt(g.list)
  stopifnot(all(hasName(DT, c(measure, group.by))))
  idvars <- c('atlas', 'modality', 'weighting', getOption('bg.subject_id'), gID, 'threshold',
              'density', 'region', 'lobe', 'hemi', 'class', 'network')
  idvars <- idvars[which(hasName(DT, idvars))]
  DT.m <- melt(DT, id.vars=idvars)
  setnames(DT.m, group.by, 'group.by')

  type <- match.arg(type)

  # 'base' plotting
  if (!requireNamespace('ggplot2', quietly=TRUE)) {
    panelfun <- if (type == 'violin') panel.violin else panel.bwplot
    p <- bwplot(value ~ group.by | get(facet.by), data=DT.m[variable == measure],
                panel=panelfun,
                xlab=group.by, ylab=ylabel)

  # 'ggplot2' plotting
  } else {
    p <- ggplot2::ggplot(DT.m[variable == measure], ggplot2::aes(x=group.by, y=value, fill=group.by))
    p <- if (type == 'violin') p + ggplot2::geom_violin(...) else p + ggplot2::geom_boxplot(...)

    if (!is.null(facet.by)) {
      stopifnot(hasName(DT, facet.by))
      p <- p + ggplot2::facet_wrap(as.formula(paste('~', facet.by)), scales='free_y')
    }
    if (isTRUE(show.points)) {
      p <- p + ggplot2::geom_jitter(position=ggplot2::position_jitter(width=0.1, height=0))
    }
    p <- p + ggplot2::labs(x=group.by, y=ylabel) + ggplot2::theme(legend.position='none')
  }

  return(p)
}
