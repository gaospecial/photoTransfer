#' calculation of multiple files in a directory
#'
#' @param path path to the directory
#' @param pattern file pattern
#' @param threads number of core used
#'
#' @return a tibble
#' @export
#' @name md5sum
md5sum = function(path, pattern = "*.jpg", threads = round(parallel::detectCores() * 0.8)){
  files = list.files(path = path, pattern = pattern, recursive = TRUE, full.names = TRUE)
  cl = parallel::makeCluster(threads)
  md5_values = pbapply::pblapply(files, digest::digest, algo = 'md5', file = TRUE, cl = cl)
  parallel::stopCluster(cl)
  tbl = tibble::tibble(
    filename = files,
    md5sum = unlist(md5_values)
  )
  colnames(tbl) = c(paste("filename", Sys.getenv("USER"), sep = "_"), "md5sum")
  return(tbl)
}

#' @name md5sum
#' @param zipfile zip file for storage
#' @export
compare_with_remote = function(path, pattern = "*.jpg", zipfile = "files.zip"){
  local_file_info = md5sum(path, pattern)
  remote_file_info = gaoch_photo
  shared_file_md5sum = intersect(local_file_info[["md5sum"]], remote_file_info[["md5sum"]])
  all_file_info = dplyr::full_join(local_file_info, remote_file_info, by = "md5sum")
  local_only = local_file_info |> dplyr::filter(!.data[["md5sum"]] %in% shared_file_md5sum)
  message("Zipping ", nrow(local_only), " files...")
  utils::zip(zipfile = zipfile, files = local_only[[1]])
  message("Done! Please check the file at: ", zipfile, ".")
  invisible(all_file_info)
}
