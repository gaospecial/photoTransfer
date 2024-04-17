common_path = function(file_paths = c("/path/to/file1.txt", "/path/to/file2.txt", "/path/to/file3.txt")){

  directories <- sapply(file_paths, function(path) dirname(path))
  common_directory <- Reduce(intersect, strsplit(directories, .Platform$file.sep))
  common_directory_path <- paste(common_directory, collapse = .Platform$file.sep)

  return(common_directory_path)

}
