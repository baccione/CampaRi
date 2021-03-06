#' @title Basin optimization of the SBR
#' @description
#'     \code{basin_optimization} uses the information provided by the SAPPHIRE basin recognition in order to define the optimal partition of the data (uses in 
#'     particulare the number of bins as a tuning variable).
#'     
#' @param the_sap Name of the PROGIDX_<...>.dat or REPIX_<...>.dat file or Data frame with three columns containing, in order, the (sorted) progress index,
#'  the relative time indices and the cut function. 
#' @param basin_optimization_method Method name for the selection of precise basin. This is a costly procedure which is based on an heuristical obj function w
#' with the following subgroups.
#' \itemize{
#'    \item "\code{uniformity}" not available
#'    \item "\code{MI_barrier_weighting}" not available yet (the description)
#' }
#' @param how_fine_search This variable define the length of the vector of bins in which is splitted the 7-nbins_x interval. As the algorithm undergo binary 
#' search this is a fundamental variable to define the sensitivity of the search.
#' @param plot_basin_identification A logical value indicating whether to display the SAPPHIRE plot with the resulting partitions or not. 
#' Black partitions are the matched ones, blue ones derive only from the dynamic analysis and orange ones only from the kinetic analysis. 
#' The green curve is the kinetic annotation (black curve) where the parabolic shape has been subtracted, i.e. the actual curve used for 
#' the peaks identification. Default value is \code{FALSE}.
#' @param nbins_x Number of bins on  x-axis of the 2-D histogram. Default to sqrt(nrow(the_sap)).
#' @param nbins_y Number of bins on the y-axis of the 2-D histogram. Default to sqrt(nrow(the_sap)).
#' @param merge_cluster Logical that allow clusters to be merged automatically if consecutives
#' @param number_of_clusters if basin_optimization_method is active accordingly this must be set to integer.
#' @param force_matching Please refer to \code{\link{basin_recognition}} for further details about the match option.
#' @param silent A logical value indicating whether the function has to remain silent or not. Default value is \code{FALSE}.
#'      
#' @return A list containing
#'       \itemize{
#'         \item "\code{Optimal_nbins}" The found number of bins.
#'         \item "\code{bas}" Output of the final basin recognition run.
#'         \item "\code{ncl}" Number of clusters finally found.
#'       }   
#' @examples
#' 
#' adjl <- mst_from_trj(trj = matrix(rnorm(1000), nrow = 100, ncol = 10))
#' ret<-gen_progindex(adjl = adjl)
#' gen_annotation(ret_data = ret, local_cut_width = 10)
#' \dontrun{
#' score_sapphire(the_sap = "PROGIDX_000000000001.dat", ann = rnorm(100))
#' CampaRi::basin_optimization(the_sap = "PROGIDX_000000000001.dat",  how_fine_search = 10, number_of_clusters = 2, force_matching = T, silent = F)
#' }
#' 
#' @details For details regarding the SAPPHIRE plot, please refer to the relative publications \url{http://www.nature.com/articles/srep06264}. 
#' Main documentation of the original campari software \url{http://campari.sourceforge.net/documentation.html}.
#' 
#' @importFrom data.table fread
#' @importFrom data.table rbindlist
#' @importFrom parallel parLapply
#' @importFrom parallel stopCluster
#' @importFrom parallel makeCluster
#' @export basin_optimization

basin_optimization <- function(the_sap, basin_optimization_method = NULL, how_fine_search = 100,
                               plot_basin_identification = FALSE, nbins_x = NULL, nbins_y = nbins_x,
                               number_of_clusters = NULL, force_matching = FALSE, silent = FALSE){
  # general input checking
  if(!is.character(the_sap) && !is.data.frame(the_sap)) stop("the_sap must be a string or a data frame")
  if(is.character(the_sap) && (!all(grepl("PROGIDX", the_sap)) && !all(grepl("REPIX", the_sap)))) stop("Please provide a data name starting with 'PROGIDX' or 'REPIX'" )
  if(!is.null(basin_optimization_method) && !is.character(basin_optimization_method)) stop('basin_optimization_method must be a character')
  if(!is.null(nbins_x) && !.isSingleInteger(nbins_x)) stop('nbins_x must be a single integer')
  if(!is.null(nbins_y) && !.isSingleInteger(nbins_x)) stop('nbins_y must be a single integer')
  if(!.isSingleInteger(how_fine_search)) stop('how_fine_search must be a single integer')
  if(!is.null(number_of_clusters) && !.isSingleInteger(number_of_clusters)) stop('number_of_clusters must be a single integer')
  if(!is.logical(silent)) stop('silent must be a logical')
  if(!is.logical(plot_basin_identification)) stop('plot_basin_identification must be a logical')
  if(!is.logical(force_matching)) stop('force_matching must be a logical')
  
  # methods input check
  basin_optimization.opt <- c("uniformity", "MI_barrier_weighting")
  if(!is.null(basin_optimization_method) && !(basin_optimization_method[1] %in% basin_optimization.opt)) 
    stop("basin_optimization_method method option not valid.")
  
  # sapphire table loading
  if(!is.data.frame(the_sap))
    st <- as.data.frame(data.table::fread(the_sap, data.table = F))
  else
    st <- the_sap
  
  # checking the number of bins inserted
  if(is.null(nbins_x)) nbins_x <- round(sqrt(nrow(st)*10))
  if(is.null(nbins_y)) nbins_y <- round(sqrt(nrow(st)*10))
  if(nbins_x != nbins_y) {
    if(!silent) cat('For simplicity we do not allow yet to use different number of nx and ny (bins for x and y).')
    nbins_x <- nbins_y <- max(nbins_x, nbins_y)
  }
  
  
  # -------------------------------------------------------------------------------------------------------- number of clusters
  # If the number of clusters is inserted this method consist only into finding the right number of clusters 
  # without splitting the possible subdivision (of the same number of clustering)
  # and afterwards it is possible to score them per their relevance (e.g. uniformity or minimal entropy).
  #
  if(!is.null(number_of_clusters)){
    
    # checks
    if(!silent) cat('Automatic optimization of basins based on number of cluster inserted... \n')
    if(number_of_clusters < 2 && number_of_clusters >= nrow(st)) stop('Number of cluster too high or too low.')
    if(number_of_clusters > nbins_x) stop('Please set the number of clusters lower than the number of initial nbins (nbins_x).')
    if(number_of_clusters > nbins_y) stop('Please set the number of clusters lower than the number of initial nbins (nbins_y).')
    # init
    lin_scale <- unique(round(seq(7, nbins_x, length.out = how_fine_search)))
    if(!silent) cat('Selected a convergence step of', how_fine_search, 'subdivisions, ranging from', nbins_x, 'to 7. \n')
    bisbr.out <- .BiSBR(st = st, ncl_found = 1, ncl_teo = number_of_clusters, start.idx = 1,
                        end.idx = length(lin_scale), lin_scale =  lin_scale, force_matching = force_matching, silent = silent, barriers = F)
    
    # if not found some handling - stop for now
    if(!bisbr.out$found) stop('We could not find optimal separation for the number of selected clusters. Try to put force_matching = F or more how_fine_search.')
    
    # final plot and saving results
    if(!is.null(basin_optimization_method)) {pp <- FALSE; ss <- FALSE} else {pp <- TRUE; ss <- TRUE}
    bas <- CampaRi::basins_recognition(st, nx = bisbr.out$nbins, new.dev = F, out.file = F, match = force_matching, plot = pp, silent = ss,
                                       cluster.statistics.weight.barriers = T, plot.cluster.statistics = pp)
    if(!silent) cat('Number of (automatically) selected bins for the basin recognition step is', bisbr.out$nbins, '\n')
  }else{
    # initial linear scale for the basin_optimization_method
    lin_scale <- unique(round(seq(7, nbins_x, length.out = how_fine_search)))
  }
  
  # -------------------------------------------------------------------------------------------------------- optimization of basins
  if(!is.null(basin_optimization_method)){
    # browser()
    if(!is.null(number_of_clusters)){
      if(!silent) cat('Looking for plateu around', bisbr.out$nbins, 'nbins. In this way we can optimize even for identical number of clusters.\n')
      # splitting the binary search untill you have a consecutive difference 
      # RIGHT split - change the condition!!
      if(number_of_clusters <= 2) cat('NB: you selected 2 cluster for optimization. This will skip the search of the left plateau.')
      if(!silent) cat('Now looking at the right split from found partition... \n')
      basRight <- .BiSBR(st = st, ncl_found = number_of_clusters, ncl_teo = number_of_clusters + 1L, start.idx = bisbr.out$idx + 1L,
                         end.idx = length(lin_scale), lin_scale =  lin_scale, force_matching = force_matching, silent = silent, barriers = T)
      # LEFT split
      if(!(number_of_clusters <= 2)){
        if(!silent) cat('Now looking at the left split from found partition... \n')
        basLeft <- .BiSBR(st = st, ncl_found = 1, ncl_teo = number_of_clusters - 1L, start.idx = 1L,
                          end.idx = bisbr.out$idx - 1L, lin_scale =  lin_scale, force_matching = force_matching, silent = silent, barriers = T) 
        basFin <- c(basLeft$searched_hist, list(c(bisbr.out, list(bas = bas))), basRight$searched_hist)
      }else{
        basFin <- c(list(c(bisbr.out, list(bas = bas))), basRight$searched_hist) 
      }
      ncl <- unlist(lapply(basFin, FUN = function(x) return(x$ncl)))
      which_to_keep <- which(ncl == number_of_clusters)
      bw <- lapply(basFin, FUN = function(x) return(x$bas$tab.st$barWeight[-1]))[which_to_keep]
      idx <- sort(unlist(lapply(basFin, FUN = function(x) return(x$idx)))[which_to_keep])
      nbb <- sort(unlist(lapply(basFin, FUN = function(x) return(x$nbins)))[which_to_keep])
      if(!silent) cat('We found', .lt(which_to_keep), 'possible values from the following bins (i.e. partitions with the desired # of clu): \n', nbb,'\n')
      bw_ini <- data.frame('bins' = nbb, 'bweights' = unlist(lapply(bw, mean)), 
                           'nbarr' = unlist(lapply(bw, .lt)), 
                           'nbar_not_empty' = unlist(lapply(bw, function(x) sum(x!=0))))
      bw_ini <- bw_ini[which(bw_ini[,3] != 0),] # selecting the not empty barriers
      bw_ini <- bw_ini[order(bw_ini[,4], bw_ini[,2], decreasing = T),] # sorting for the most not empty and the higher MI-ratio
      to_search_finer <- c(min(nbb), max(nbb))
    }
    ################################ uniformity
    if(basin_optimization_method[1] == 'uniformity') stop('uniformity basin_optimization_method option not yet ready.')
    ################################ MI_barrier_weighting
    if(basin_optimization_method[1] == 'MI_barrier_weighting'){
      search_method <- 'exaustive'
      if(is.null(number_of_clusters)) {
        bin_search_space <- lin_scale
      }else {
        bin_search_space <- unique(round(seq(to_search_finer[1], to_search_finer[2], length.out = how_fine_search)))
        bin_search_space <- setdiff(bin_search_space, nbb)
      }
      # n_cores <- parallel::detectCores()
      # cl <- parallel::makeCluster(n_cores, type = 'FORK')
      if(search_method == 'exaustive'){ # I search completely over the possible bins
        if(!silent) cat('We will use exaustive search of the best barrier using the following bins: \n')
        # mean_bar_weights <- parallel::parLapply(cl = cl, x = as.list(bin_search_space), fun = function(bl){
        mean_bar_weights <- lapply(as.list(bin_search_space), function(bl){
          cat(bl, ' ')
          if(bl == bin_search_space[.lt(bin_search_space)]) cat('\n')
          bout <- CampaRi::basins_recognition(st, nx = bl, plot = F, match = force_matching, out.file = F, new.dev = F, silent = T,
                                              cluster.statistics.weight.barriers = T)
          if(!is.null(bout$statistics) && !bout$statistics) {
            bw <- NA
            b_n_empty <- NA
          }else {
            bw <- mean(bout$tab.st$barWeight[-1])
            b_n_empty <- sum(bout$tab.st$barWeight[-1] > .Machine$double.eps ^ 0.5)
          }
          outing <- list('bins' = bl, 'bweights' = bw, 'nbarr' = nrow(bout$tab.st) - 1, 'nbar_not_empty' = b_n_empty)
          return(outing)
        })
        # parallel::stopCluster(cl)
        
        bw_tot <- data.table::rbindlist(mean_bar_weights) # they say it is slow (better rbindlist)
        # FILTERS
        if(!is.null(number_of_clusters)) bw_tot <- rbind(bw_tot, bw_ini)
        if(!is.null(number_of_clusters)) bw_tot <- bw_tot[which(bw_tot[,3] == number_of_clusters-1),]
        bw_tot <- bw_tot[which(bw_tot[,3] != 0),] # selecting the not empty barriers
        if(!is.null(number_of_clusters)) bw_tot <- bw_tot[order(bw_tot[,4], bw_tot[,2], decreasing = T),] # sorting for the most not empty and the higher MI-ratio
        else bw_tot <- bw_tot[order(bw_tot[,2], decreasing = T),] # sorting for the most not empty and the higher MI-ratio

        if(nrow(bw_tot) < 1) stop('We were not able to find a convenient partitioning.')
        if(!silent) cat('In the following we will plot the best 5 divisions (if presents): \n')
        if(nrow(bw_tot) > 5) to_show <- 5 else to_show <- nrow(bw_tot)
        if(!silent) print(bw_tot[1:to_show,])
        bas <- CampaRi::basins_recognition(st, nx = bw_tot$bins[1], new.dev = F, out.file = F, match = force_matching, plot = plot_basin_identification, silent = silent,
                                           cluster.statistics.weight.barriers = T, plot.cluster.statistics = plot_basin_identification)
        
      }else if(search_method == 'binary_search'){ # broken
        bisbr.out <- .BiSBRstat(st = st, previous_score = 0, start.idx = 1,
                            end.idx = length(lin_scale), lin_scale =  lin_scale, force_matching = force_matching, silent = silent)
        if(!bisbr.out$found) stop('We could not find optimal separation for the number of selected clusters. Try to put force_matching = F or more how_fine_search.')
        # final plot and saving results
        bas <- CampaRi::basins_recognition(st, nx = bisbr.out$nbins, new.dev = F, out.file = F, match = force_matching, plot = plot_basin_identification, silent = silent)
      }
    }
  }else{
    if(is.null(number_of_clusters)) stop('One between number_of_clusters and basin_optimization_method must be active to optimize the number of bins.')
  }
  
  # -------------------------------------------------------------------------------------------------------- final return
  invisible(list('Optimal_nbins' = bas$nbins, 'bas' = bas, 'ncl' = nrow(bas$tab.st)))
}


# abba <- unique(round(seq(2, nbinsxy, length.out = 100)))
# .BiSBR(st = st, ncl_found = 1, ncl_teo = 3, start.idx = 1, end.idx = length(abba), lin_scale =  abba, force_matching = F, silent = F)
# .BiSBR(st = st, ncl_found = 1, ncl_teo = 3, start.idx = 1, end.idx = length(abba), lin_scale =  abba, force_matching = T, silent = F)
# # testing for minimum number of bins without crashing
# CampaRi::basins_recognition(st[1:1000,], nx = 4, new.dev = F, out.file = F, plot = T)
# CampaRi::basins_recognition(st, nx = 12, new.dev = F, out.file = F, plot = T)
# CampaRi::basins_recognition(st, nx = 88, new.dev = F, out.file = F, plot = T, match = T)
# CampaRi::basins_recognition(st, nx = 97, new.dev = F, out.file = F, plot = T, match = T)
# CampaRi::basins_recognition(st, nx = 343, new.dev = F, out.file = F, plot = T, match = T)
# alu <- CampaRi::basins_recognition(st, nx = 905, new.dev = F, out.file = F, plot = T, match = T)


############### BISBR         (1)
# help function for binary search on sapphire basin recognition
.BiSBR <- function(st, ncl_found, ncl_teo, start.idx = 1, end.idx = NULL, lin_scale = NULL, 
                   force_matching = FALSE, tol = .Machine$double.eps ^ 0.5, check = TRUE, silent = TRUE,
                   searched_hist = NULL, barriers = TRUE) {
  # Takes sorted (in ascending order) vectors
  # if (check) stopifnot(is.vector(table), is.numeric(table))
  if(check) stopifnot(!is.null(end.idx))
  m <- as.integer(ceiling((end.idx + start.idx) / 2)) # Midpoint
  if(!is.null(lin_scale)) nbins <- lin_scale[m] else nbins <- m
  if(is.na(nbins)) return(list('found' = FALSE, 'ncl' = ncl_found,
                               'start.idx' = start.idx - 1, 'nbins' = lin_scale[start.idx-1],
                               'searched_hist' = searched_hist))
  if(!silent) cat('Looking for right divisions using', nbins, 'nbins...')
  bas <- CampaRi::basins_recognition(st, nx = nbins, plot = F, match = force_matching, out.file = F, new.dev = F, silent = T, 
                                     cluster.statistics.weight.barriers = barriers)
  ncl_found <- nrow(bas$tab.st)
  if(!silent) cat(' found', ncl_found,'clusters. \n')
  if(barriers){
    if(is.null(searched_hist)) searched_hist <- list()
    searched_hist[[.lt(searched_hist) + 1]] <- list('bas' = bas, 'ncl' = ncl_found, 
                                'idx' = m, 'nbins' = lin_scale[m])
  }
  
  # more clusters than needed
  if (ncl_found > ncl_teo + tol) {
    if (start.idx == end.idx) return(list('found' = FALSE, 'ncl' = ncl_found,
                                          'start.idx' = start.idx, 'nbins' = lin_scale[start.idx], 
                                          'searched_hist' = searched_hist))
    Recall(st, ncl_found, ncl_teo, start.idx = start.idx, end.idx = m - 1L, lin_scale = lin_scale,
           force_matching = force_matching, tol = tol, check = FALSE, silent = silent, searched_hist = searched_hist)
    
  # less clusters than needed
  } else if (ncl_found < ncl_teo - tol) {
    if (start.idx == end.idx) return(list('found' = FALSE, 'ncl' = ncl_found, 
                                          'start.idx' = start.idx, 'nbins' = lin_scale[start.idx], 
                                          'searched_hist' = searched_hist))
    Recall(st, ncl_found, ncl_teo, start.idx = m + 1L, end.idx = end.idx, lin_scale = lin_scale,
           force_matching = force_matching, tol = tol, check = FALSE, silent = silent, searched_hist = searched_hist)
  # exactly what we need
  } else return(list('found' = TRUE, 'ncl' = ncl_found, 'idx' = m, 'nbins' = lin_scale[m], 'searched_hist' = searched_hist))
}

############### BISBRstat      (2)
# help function for the score statistic
.BiSBRstat <- function(st, previous_score, start.idx = 1, end.idx = NULL, lin_scale = NULL, 
                   force_matching = FALSE, tol = .Machine$double.eps ^ 0.5, check = TRUE, silent = TRUE) {
  # Takes sorted (in ascending order) vectors
  # if (check) stopifnot(is.vector(table), is.numeric(table))
  if(check) stopifnot(!is.null(end.idx))
  m <- as.integer(ceiling((end.idx + start.idx) / 2)) # Midpoint
  if(!is.null(lin_scale)) nbins <- lin_scale[m] else nbins <- m
  if(!silent) cat('Looking for best average score using', nbins, 'nbins...')
  bas <- CampaRi::basins_recognition(st, nx = nbins, plot = F, match = force_matching, out.file = F, new.dev = F, silent = T, 
                                     cluster.statistics.weight.barriers = T)
  bweights <- bas$tab.st$barWeight[-1]
  if(!silent) cat(' found', .lt(bweights),'barriers with an average MI ratio of ', mean(bweights), '. \n')
  # NB: this function follow the assumption that the score, being a mean, it is optimizing for the optimal number of bins. 
  #     There is no guarantee of convergence, neither of optimal score.
  if (mean(bweights) > previous_score + tol) { # score is higher (it must mean it has less barriers or they are better. -> I reduce still the number)
    if (start.idx == end.idx) return(list('found' = FALSE, 'ncl' = ncl_found, 'start.idx' = start.idx, 'nbins' = lin_scale[start.idx]))
    Recall(st, previous_score = mean(bweights), start.idx = start.idx, end.idx = m - 1L, lin_scale = lin_scale,
           force_matching = force_matching, tol = tol, check = FALSE, silent = silent)
  } else if (mean(bweights) < previous_score - tol) {
    if (start.idx == end.idx) return(list('found' = FALSE, 'ncl' = ncl_found, 'start.idx' = start.idx, 'nbins' = lin_scale[start.idx]))
    Recall(st, previous_score = mean(bweights), start.idx = m + 1L, end.idx = end.idx, lin_scale = lin_scale,
           force_matching = force_matching, tol = tol, check = FALSE, silent = silent)
  } else return(list('found' = TRUE, 'ncl' = ncl_found, 'idx' = m, 'nbins' = lin_scale[m]))
}

