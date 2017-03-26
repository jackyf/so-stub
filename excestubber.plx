#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);

use File::Basename;

sub mlog {
	my $what = shift;
	say $what . ' ...';
}

sub ilog {
	my $what = shift;
	say $what;
}

sub process_symbol_table {
	my $path = shift;
	my $mode = shift;
	my $callback = shift;

	mlog("Reading symbol table of $path");

	my $nm_opt_args = ($mode eq 'caller' ? '--undefined-only' : '--defined-only --print-size');
	my $symbol_table = `nm $path --dynamic $nm_opt_args`;

	for my $line (split /\n/, $symbol_table) {
		chomp($line);
		my @parts = split / /, $line;
		if ($mode eq 'caller' or (scalar(@parts) == 4)) {
			$callback->($parts[-1]);
		}
	}
}

sub process_ldd {
	my ($caller_path, $lib_file) = @_;

	mlog("Processing dynamic dependencies of $caller_path");
	my $caller_ldd_ouptut = `ldd $caller_path`;
	($caller_ldd_ouptut =~ m/$lib_file => (.*?) /) 
			or die("could not find $lib_file in dynamic dependencies for $caller_path");
	return $1;
}

my ($caller_path, $lib_file) = @ARGV;

my $lib_path = process_ldd($caller_path, $lib_file);

my %caller_symbol_set;
process_symbol_table($caller_path, 'caller', sub {
	my $symbol = shift;
	$caller_symbol_set{$symbol} = 1;
});

my @used_symbols;
my $unused_symbol_count = 0;
process_symbol_table($lib_path, 'lib', sub {
	my $symbol = shift;
	if (defined $caller_symbol_set{$symbol}) {
		push @used_symbols, $symbol;
	} else {
		++$unused_symbol_count;
	}
});
my $used_symbol_count = scalar(@used_symbols);
ilog("Used symbols: $used_symbol_count, unused symbols: $unused_symbol_count");
if ($used_symbol_count == 0) {
	die("no dynamic symbols found in $lib_path");
}

my $output_file = basename($lib_file);
ilog("Output file: $output_file");
(my $lib_id = $output_file) =~ s/[^0-9a-z]+//gi;
ilog("Lib ID: $lib_id");
my $function_name = "excestub_for_$lib_id";
ilog("Stub function name: $function_name");
my $output_path = $output_file;

mlog("Compiling");
my $defines = "-DLNAME=\\\"$output_file\\\" -DFNAME=$function_name";
my $ld_args = join(' ', map { "-Wl,--defsym=$_=$function_name" } @used_symbols);
system("g++ -shared -Wall -fPIC $defines stubs.cpp $ld_args -o $output_path") == 0
		or die("compiling failed: $!");

mlog("Stripping");
system("strip $output_path") == 0
		or die("strip failed: $!");

ilog("Done");

