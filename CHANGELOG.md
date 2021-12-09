# Changelog for the TeX Live Docker images

## TeX Live 2021

### 2021-12

* Added `libunicode-linebreak-perl libfile-homedir-perl libyaml-tiny-perl`
  packages to the base image to solve latexindent errors.
  (see #13)
* Added `ghostscript` package to allow including eps files.
  (see #14)
* Added `curl` package to allow CTAN uploads using `l3build`.

## TeX Live 2020 and before

There has been no CHANGELOG apart from the commit history for these images.