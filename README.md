# sge-monitor

Simple web-based application to monitor SGE activity

## About

This project exists because I wanted a simple way of browsing activity on our local HPC cluster (running SGE)
without having to do lots of typing (and scrolling through `qstat` output). There are undoubtably far more sophisticated and interactive tools to monitor SGE usage/activity - this is essentially just a wrapper around `qstat`.

## Requirements

 * Perl
 * Perl modules (Dancer2, XML::Simple, ... see Makefile.PL)
 * `qstat`

## Install

The following will try to install Perl modules from the CPAN (see note below).

    $ ssh username@yoursgehost
    $ git clone https://github.com/sillitoe/sge-monitor
    $ cd sge-monitor
    $ perl Makefile.PL
    $ make test && make install

Note: I highly recommend using [perlbrew](http://perlbrew.pl) to maintain your own Perl binaries/libraries and avoid messing about with system Perl. An alternative is to use [local::lib](http://stackoverflow.com/questions/2980297/how-can-i-use-cpan-as-a-non-root-user "StackOverflow: how-can-i-use-cpan-as-a-non-root-user") to install Perl libraries as non-root user.

## Run

Start the server...

    $ plackup -r bin/app.psgi
    HTTP::Server::PSGI: Accepting connections at http://0:5000/

Direct your browser to:

  http://yoursgehost:5000

## Screenshots


