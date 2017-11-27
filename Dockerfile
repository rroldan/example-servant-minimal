FROM heroku/heroku:16

ENV LANG C.UTF-8

# Install required packages.
RUN apt-get update
RUN apt-get upgrade -y --assume-yes
# Install packages for stack and ghc.
RUN apt-get install -y --assume-yes xz-utils gcc libgmp-dev zlib1g-dev
# Install packages needed for libraries used by our app.
RUN apt-get install -y --assume-yes libpq-dev
# Install convenience utilities, like tree, ping, and vim.
RUN apt-get install -y --assume-yes tree iputils-ping vim-nox

# Remove apt caches to reduce the size of our container.
RUN rm -rf /var/lib/apt/lists/*

# Install stack to /opt/stack/bin.
RUN mkdir -p /opt/stack/bin
RUN curl -L https://www.stackage.org/stack/linux-x86_64 | tar xz --wildcards --strip-components=1 -C /opt/stack/bin '*/stack'

# Create /opt/example-servant-minimal/bin and /opt/example-servant-minimal/src.  Set
# /opt/example-servant-minimal/src as the working directory.
RUN mkdir -p /opt/example-servant-minimal/src
RUN mkdir -p /opt/example-servant-minimal/bin
WORKDIR /opt/example-servant-minimal/src

# Set the PATH for the root user so they can use stack.
ENV PATH "$PATH:/opt/stack/bin:/opt/example-servant-minimal/bin"

# Install GHC using stack, based on your app's stack.yaml file.
COPY ./stack.yaml /opt/example-servant-minimal/src/stack.yaml
RUN stack --no-terminal setup

# Install all dependencies in app's .cabal file.
COPY ./example-servant-minimal.cabal /opt/example-servant-minimal/src/example-servant-minimal.cabal
RUN stack --no-terminal test --only-dependencies

# Build application.
COPY . /opt/example-servant-minimal/src
RUN stack --no-terminal build

# Install application binaries to /opt/example-servant-minimal/bin.
RUN stack --no-terminal --local-bin-path /opt/example-servant-minimal/bin install

# Remove source code.
#RUN rm -rf /opt/example-servant-minimal/src

# Add the apiuser and setup their PATH.
#RUN useradd -ms /bin/bash apiuser
#RUN chown -R apiuser:apiuser /opt/example-servant-minimal
#USER apiuser
#ENV PATH "$PATH:/opt/stack/bin:/opt/example-servant-minimal/bin"

# Set the working directory as /opt/example-servant-minimal/.
WORKDIR /opt/example-servant-minimal

#CMD /opt/example-servant-minimal/bin/example-servant-minimal-api
CMD /opt/example-servant-minimal/bin/example-servant-minimal
