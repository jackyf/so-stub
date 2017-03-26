#!/usr/bin/perl

use strict;
use warnings;

my $obj_file = $ARGV[0];
my $symbol_table = `nm $obj_file --dynamic --defined-only --print-size`;

my @dynamic_symbols;
for my $line (split /\n/, $symbol_table) {
	chomp($line);
	my @parts = split / /, $line;
	if (scalar(@parts) == 4) {
		my $name = $parts[3];
		push @dynamic_symbols, $name;
	}
}
if (scalar(@dynamic_symbols) == 0) {
	die("no dynamic symbols found");
}

my $output_path = 'stubs.so';

my $ld_args = join(' ', map { "-Wl,--defsym=$_=exception_thrower" } @dynamic_symbols);
system("g++ -shared -Wall -fPIC stubs.cpp $ld_args -o $output_path") == 0
		or die("compiling failed: $!");
system("strip $output_path") == 0
		or die("strip failed: $!");

