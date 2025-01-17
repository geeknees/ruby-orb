#!/usr/bin/env bash

# Disable IPv6
mkdir -p ~/.gnupg/
find ~/.gnupg -type d -exec chmod 700 {} \;
echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf

count=0
until gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
do
    count=$((count+1)); sleep 10;
    if [ $count -gt 2 ]; then
        echo "Unable to receive GPG keys, FAILING";
        exit 1;
    fi;
    echo "Network error: Unable to receive GPG keys. Will attempt again ($count/3)";
done;
## Update if RVM is installed and exit
if [ -x "$(command -v rvm -v)" ]; then
    rvm get stable
    exit 0
fi

curl -sSL "https://get.rvm.io" | bash -s stable

# check for machine image specific path
if [ -d /opt/circleci/.rvm ]; then
  echo "Setting PATH up for system install"
  # this should be what needs to be added to that $BASH_ENV since this is what's in bash_profile - i dont know when $HOME is set
  echo 'export PATH=$PATH:/opt/circleci/.rvm/bin' >> $BASH_ENV
  echo "source /opt/circleci/.rvm/scripts/rvm" >> $BASH_ENV
  # this will source if anyone logs in noninteractively, nvm setup only adds nvm to the path, to get the rubygems later you need to source this again
  echo "source /opt/circleci/.rvm/scripts/rvm" >> ~/.bashrc
  echo "export RVM_HOME=/opt/circleci/.rvm" >> $BASH_ENV
else
  # Most circle builds run as a root user, in which case rvm gets installed in /usr/local/rvm instead of $HOME/.rvm
  RVM_HOME=$HOME/.rvm
  if [ -f "$RVM_HOME/scripts/rvm" ]; then
    echo "Using $RVM_HOME"
  else
    RVM_HOME=/usr/local/rvm
    echo "Using $RVM_HOME"
  fi
  echo "export RVM_HOME=$RVM_HOME" >> $BASH_ENV

  echo "Setting PATH up for local install"
  # this should be what needs to be added to that $BASH_ENV since this is what's in bash_profile - i dont know when $HOME is set
  echo 'export PATH=$PATH:$RVM_HOME/bin' >> $BASH_ENV
  echo "source $RVM_HOME/scripts/rvm" >> $BASH_ENV
  # this will source if anyone logs in noninteractively, nvm setup only adds nvm to the path, to get the rubygems later you need to source this again
  echo "source $RVM_HOME/scripts/rvm" >> ~/.bashrc
fi

# check if it seems like they're using rbenv already
if command -v rbenv &> /dev/null && [ -f ".ruby-version" ]
then
    echo -e "\e[91m"
    cat <<'SUGGESTION'

#######################################################################
# WARNING
#######################################################################

We've detected that you're running on a system that has the rbenv ruby
version manager already installed, and you have a .ruby-version file in
the current working directory.

The circleci/ruby orb (that's currently executing) uses RVM to install
ruby.  Using more than one ruby version manager at once can, depending
on the configuration of your system, cause issues.

To install ruby with rbenv without using the circleci/ruby's "install"
command, you can simply run a step that executes:

  rbenv install

Which will install the version of ruby that is specified in the
.ruby-version file.

#######################################################################

SUGGESTION
    echo -e "\e[0m"
fi
