# TeX Live docker image

This repository provides dockerfiles for [TeX Live](http://tug.org/texlive/)
repositories (full installation with all packages but without documentation).
It also provides the necessary tooling to execute common helper tools (e.g.
Java for arara, Perl for Biber and Xindy, Python for Pygments).

Please note that we only provide selected historical releases and one image
corresponding to the latest release of TeX Live (tagged latest).

### Why this fork?

This fork build historic releases of TeX Live against stable and old versions of Debian.  Only the latest TeX Live is build against the tesing branch of Debian (hopefully it will be identical to the official image.)

## Usage

To use one of these images in your projects, simply lookup the name of the
image on GitHub Packages and use

    FROM ghcr.io/omnicortex/texlive:2022

or any other tag.

If you want to pull these images GitHub, simply use

    FROM ghcr.io/omnicortex/texlive:2022

or any other tag.

For some tutorials on using these images within a Docker workflow, have a look
at the posts listed on our [wiki page](https://gitlab.com/islandoftex/images/texlive/-/wikis/home).

> These images are provided by the Island of TeX. Please use the images'
> [repo](https://gitlab.com/islandoftex/images/texlive) to report issues or
> feature request. We are not active on the TeX Live mailing list.

## Flavors we provide

For every release `X` (e.g. `latest`) we are providing the following flavors:

* `X`: A "minimal" TeX Live installation without documentation and source
  files. However, all tools mentioned above will work without problems.
* `X-full`: `X` with documentation and source files.

If in doubt, choose `X` and only pull the larger images if you have to.
Especially documentation files do add a significant payload.

## The `latest` release

Our continuous integration is scheduled to rebuild all Docker images monthly.
Hence, pulling the `latest` image will provide you with an at most one month old
snapshot of TeX Live including all packages. You can manually update within the
container by running `tlmgr update --self --all`.


*Note for users of schemes other than `full`*: if you `tlmgr install` another
binary they are not added to the `PATH` automatically because they are not
respected by `tlmgr path add` while building the image. Use `tlmgr install
binary && tlmgr path add` to install new executables.


## Licensing

The software in terms of the MIT license are the Dockerfiles and test files
provided. This does not include the pre-built Docker images we provide. They
follow the redistribution conditions of the bundled software.
