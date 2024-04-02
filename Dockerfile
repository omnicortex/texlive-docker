# This image is based on Debian instead of e.g. Alpine as at the time of its
# creation there were binaries (e.g. biber) that were not distributed for the
# Linux/MUSL platform (at least not via default TeX Live). Now downstream
# images rely on this, so do not change the base OS without good reason.

# the current release needed to determine which way to
# verify files
ARG CURRENTRELEASE
# the documentation or source suffix ("-doc" etc.)
ARG SUFFIX=""

FROM registry.gitlab.com/islandoftex/images/texlive:TL$CURRENTRELEASE-historic-tree$SUFFIX AS tree

FROM debian:12-slim AS base

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    # ConTeXt cache can be created on runtime and does not need to
    # increase image size
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
    # As we will not install regular documentation why would we want to
    # install perl docs…
    NOPERLDOC=1

RUN apt-get update && \
  # basic utilities for TeX Live installation
  apt-get install -qy --no-install-recommends curl git unzip \
  # miscellaneous dependencies for TeX Live tools
  make fontconfig perl default-jre libgetopt-long-descriptive-perl \
  libdigest-perl-md5-perl libncurses6 \
  # for latexindent (see #13)
  libunicode-linebreak-perl libfile-homedir-perl libyaml-tiny-perl \
  # for eps conversion (see #14)
  ghostscript \
  # for metafont (see #24)
  libsm6 \
  # for syntax highlighting
  python3 python3-pygments \
  # for gnuplot backend of pgfplots (see !13)
  gnuplot-nox && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/apt/ && \
  # bad fix for python handling
  ln -s /usr/bin/python3 /usr/bin/python

FROM base AS release
# the current release needed to determine which way to
# verify files
ARG CURRENTRELEASE
# the documentation or source suffix ("-doc" etc.)
ARG SUFFIX=""

# whether to create font and ConTeXt caches
ARG GENERATE_CACHES=yes

ARG DOCFILES
ARG SRCFILES

WORKDIR /tmp

RUN echo "deb http://ftp.de.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
  apt-get update && \
  # The line above adds the Debian main mirror which is only required to
  # fetch libncurses5 from Debian package repositories. Xindy requires
  # libncurses5.
  apt-get install -qy --no-install-recommends libncurses5 && \
  # Mark all texlive packages as installed. This enables installing
  # latex-related packges in child images.
  # Inspired by https://tex.stackexchange.com/a/95373/9075.
  apt-get install -qy --no-install-recommends equivs && \
  # download equivs file for dummy package
  curl https://tug.org/texlive/files/debian-equivs-$CURRENTRELEASE-ex.txt --output texlive-local && \
  sed -i "s/2022/9999/" texlive-local && \
  # freeglut3 does not ship with debian testing, so we remove it because there
  # is no GUI need in the container anyway (see #28)
  sed -i "/Depends: freeglut3/d" texlive-local && \
  # we need to change into tl-equivs to get it working
  equivs-build texlive-local && \
  dpkg -i texlive-local_9999.99999999-1_all.deb && \
  apt-get install -qyf --no-install-recommends && \
  # reverse the cd command from above and cleanup
  rm -rf ./* && \
  # save some space
  apt-get remove -y --purge equivs && \
  apt-get autoremove -qy --purge && \
  rm -rf /var/lib/apt/lists/* && \
  apt-get clean && \
  rm -rf /var/cache/apt/

COPY --from=tree /usr/local/texlive /usr/local/texlive

# add all relevant binaries to the PATH and set TEXMF for ConTeXt
ENV PATH=/usr/local/texlive/$CURRENTRELEASE/bin/x86_64-linux:$PATH \
    MANPATH=/usr/local/texlive/$CURRENTRELEASE/texmf-dist/doc/man:$MANPATH \
    INFOPATH=/usr/local/texlive/$CURRENTRELEASE/texmf-dist/doc/info:$INFOPATH

WORKDIR /
RUN echo "Set PATH to $PATH" && \
  # pregenerate caches as per #3; overhead is < 5 MB which does not really
  # matter for images in the sizes of GBs
  if [ "$GENERATE_CACHES" = "yes" ]; then \
    echo "Generating caches" && \
    luaotfload-tool -u && \
    mtxrun --generate && \
    # also generate fontconfig cache as per #18 which is approx. 20 MB but
    # benefits XeLaTeX user to load fonts from the TL tree by font name
    cp "$(find /usr/local/texlive -name texlive-fontconfig.conf)" /etc/fonts/conf.d/09-texlive-fonts.conf && \
    fc-cache -fsv; \
  else \
    echo "Not generating caches"; \
  fi

RUN \
  # test the installation
  latex --version && printf '\n' && \
  biber --version && printf '\n' && \
  xindy --version && printf '\n' && \
  arara --version && printf '\n' && \
  python --version && printf '\n' && \
  pygmentize -V && printf '\n' && \
  if [ "$DOCFILES" = "yes" ]; then texdoc -l geometry; fi && \
  if [ "$SRCFILES" = "yes" ]; then kpsewhich amsmath.dtx; fi

