
<!-- README.md is generated from README.Rmd. Please edit that file -->

# photoTransfer

<!-- badges: start -->
<!-- badges: end -->

The goal of photoTransfer is to 简化照片数据的传输。

- 计算照片的 md5sum 值，得到一个列表；
- 比较 md5sum 值，将两个电脑上同一照片联系起来，记录下照片的文件名；
- 将 md5sum 值不同的部分创建成一个压缩包以供传输。

## Installation

You can install the development version of photoTransfer like so:

``` r
install.packages("pak")
pak::pak("gaospecial/photoTransfer")
```

## Example

安装完成后，在 R
终端里面运行下面的代码，可以分析电脑中的文件，自动把那些老师电脑中没有的文件打包压缩。并把老师和你电脑中都有的文件的文件名写入到一个
CSV 文件中。届时，只需要把压缩包和 CSV 文件发给我即可。

``` r
library(photoTransfer)
setwd("~/Downloads")
results = compare_with_remote(".")
#> Zipping 18 files...
#> Done! Please check the file at: files.zip.
write.csv(results, file = "results.csv")
```
