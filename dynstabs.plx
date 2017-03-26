#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

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

my $output_file = basename($obj_file);
(my $lib_id = $output_file) =~ s/[^0-9a-z]+//gi;
my $function_name = "elfstub_for_$lib_id"; 
my $output_path = $output_file;

my $defines = "-DLNAME=\\\"$output_file\\\" -DFNAME=$function_name";
my $ld_args = join(' ', map { "-Wl,--defsym=$_=$function_name" } @dynamic_symbols);
system("g++ -shared -Wall -fPIC $defines stubs.cpp $ld_args -o $output_path") == 0
		or die("compiling failed: $!");
system("strip $output_path") == 0
		or die("strip failed: $!");

