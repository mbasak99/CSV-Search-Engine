#!/usr/bin/perl
#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');   # This is the version of Perl to be used
use Text::CSV  1.32;   # We will be using the CSV module (version 1.32 or higher)
# to parse each line

#
#   Variables to be used
#
my $EMPTY = q{};
my $SPACE = q{ };
my $COMMA = q{,};

my $csv_input_file = $EMPTY; #File variable input
my $sorted_records_count = -1;
my @sorted_records;
my $line;
my $year;
my $csv          = Text::CSV->new({ sep_char => $COMMA });


#
# Checking that the number of arguments is correct
#

if ($#ARGV != 0 ) {
   print "Usage: preprocessingFile.pl <CPI File.csv> > <Output File.txt>\n" or
      die "Print failure\n";
   exit;
} else {
   $csv_input_file = $ARGV[0];
}

#
# Opens the file
#

open my $current_csv_file, '<:encoding(UTF-8)', $csv_input_file
    or die "Unable to open file: $csv_input_file\n";



# Parses through each line of the file and saves only the ones which will be used in an array in csv format
while (my $csv_record = <$current_csv_file>){
  if ($csv->parse($csv_record)){
    my @csv_fields = $csv->fields();

    $year = substr ($csv_fields[0], 0, 4);
    if($year =~ m/^20(1[0-6]|0[0-9])/){ #Only looks for years between and including 2000 and 2016

      if(contains_product(@csv_fields) == 1){
        $sorted_records_count++;

        #taking in year, geo, product and product groups, UoM, coordinate, value
        $line = $csv_fields[0].",".$csv_fields[1].",".$csv_fields[3].",".$csv_fields[4].",".$csv_fields[9].",".$csv_fields[10];
        $sorted_records[$sorted_records_count] = $line;
      }
    }
  }
}

#
# Closes the file
#
close $current_csv_file or
    die "Unable to close: $ARGV[0]\n";

#
# Prints all records to the output file
#
foreach my $sorted_record_output (@sorted_records) {
    print $sorted_record_output."\n";
}

#
# Subroutine which checks whether the record is a record we need
#

sub contains_product {
 my $validator = 0;
 my ($input_coordinate) = $_[9];

 if ($input_coordinate =~ m/^((2|3|5|7|9|11|14|18|20|23|26).24)$/) { #Butter
   $validator = 1;
 }
 if ($input_coordinate =~ m/^((2|3|5|7|9|11|14|18|20|23|26).25)$/ ) { #Cheese
   $validator = 1;
 }
 if ($input_coordinate =~ m/^((2|3|5|7|9|11|14|18|20|23|26).249)$/) { #Tuition fees
   $validator = 1;
 }
 if ($input_coordinate =~ m/^(2.250)$/) { #School textbooks and supplies
   $validator = 1;
 }
 if ($input_coordinate =~ m/^((2|3|5|7|9|11|14|18|20|23|26).80)$/){ #Rented Accomodation
   $validator = 1;
 }
 if ($input_coordinate =~ m/^((2|3|5|7|9|11|14|18|20|23|26).84)$/) { #Owned Accomodation
   $validator = 1;
 }
 if ($input_coordinate =~ m/^((2|3|5|7|9|11|14|18|20|23|26).205)$/ ) { #Prescribed medicines (excluding medicinal cannabis)
   $validator = 1;
 }
 return ($validator);
}
# GEO Codes
# Canada 2
# NFL 3
# PEI 5
# NS 7
# NB 9
# QC 11
# ON 14
# MB 18
# SK 20
# AB 23
# BC 26

# Product Coordinates
# Butter *.24
# Cheese *.25
# School textbook supplies *.250
# Tuition fees *.249
# Rented Accommodations *.80
# Owned Accommodations *.84
# Prescribed medicines *.205
