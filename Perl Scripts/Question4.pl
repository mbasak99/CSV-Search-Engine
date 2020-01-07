#!/usr/bin/perl
#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');   # This is the version of Perl to be used
use Text::CSV  1.32;   # We will be using the CSV module (version 1.32 or higher)
use Statistics::R;

#Authors: Darren Chay Loong, Monark Basak

#
#   Variables to be used
#
my $EMPTY = q{};
my $SPACE = q{ };
my $COMMA = q{,};

my $pdffilename = $EMPTY;
my $input_file = $EMPTY;
my $output_file = $EMPTY;
my $sorted_record_count = -1;
my $output_record_count = -1;
my @provinces = ("Ontario", "Quebec", "Saskatchewan", "British Columbia", "Alberta", "Nova Scotia", "Manitoba", "New Brunswick", "Newfoundland and Labrador", "Prince Edward Island");
my @edited_provinces = ("ON", "QC", "SK", "BC", "AB", "NS", "MN", "NB", "NFL", "PEI");
my $answer_validator;
my $answer_province;
my $csv          = Text::CSV->new({ sep_char => $COMMA });
my @rent_per_year_sum = 0;
my @owned_per_year_sum = 0;
my @output_records = $EMPTY;
my $increment = -1;
my $newline;

#
#	Saves the name of the file to be used
#

$input_file = "CPIOutput.txt";


#
#	Prompts user to choose which province they wish to analyze by entering the associated number of the province
#
print "Number\tProvince\n";

for my $i (0..9){
	my $j = $i + 1;
	print $j."\t".$provinces[$i]." (${edited_provinces[$i]})"."\n";
}

# Do - while loop which checks whether the user has input the right province
do{

	# User is prompted to enter the province they want and their answer is checked to see if its in the appropriate format
	do{
		print "Enter the number of the province you want to graph\n";
		$answer_province = <STDIN>;
		chomp $answer_province;

	} while($answer_province !~ m/^([1-9]|10)$/); #Makes sure only 1-10 are entered

 	#	prints which province they selected and ask whether this was the one they wanted
	print "You entered ${answer_province} and thus you wanted ".$provinces[$answer_province - 1]."."."\n";

	# Do - while loop to check if they entered the correct answer
	do {
		print "Is this the province you wanted? [Answer with Y or N]: ";
		$answer_validator = <STDIN>;
		chomp $answer_validator;

	} while ($answer_validator !~ m/^[y|Y|n|N]$/);

} while(lc($answer_validator) ne "y");


$output_file = "Q4".$provinces[$answer_province - 1].".txt";


#
#	Open the processed CPI file
#
open my $file_in_use, '<', $input_file
    or die "Unable to open file: $input_file\n";

#	Goes through each csv record in the file and collects only the necessary data
while (my $text_file_record = <$file_in_use>){
	my @master_fields = split "," , $text_file_record;

	#	Taking out only the relevant info into an array (Rented and Owned Accomodation for the selected province)
	if(($master_fields[1] eq $provinces[$answer_province - 1]) && ($master_fields[4] =~ m/^(\d*.80)$/ || $master_fields[4] =~ m/^(\d*.84)$/)) {
		$sorted_record_count++;

		#	Changes the index for the arrays every 12 months which indicates a new year.
		if (($sorted_record_count) % 24 == 0) {
			$increment++;
		}

		#	Each index for each array holds the total sum values for each year which can then be divided by 12 for avg in the year.
		if($master_fields[4] =~ m/^(\d*.80)$/){
			$rent_per_year_sum[$increment] +=  $master_fields[5];
		}
		if($master_fields[4] =~ m/^(\d*.84)$/){
			$owned_per_year_sum[$increment] +=  $master_fields[5];
		}
	}
}

#
#	Closing the processed CPI file
#
close $file_in_use or
    die "Unable to close: $ARGV[0]\n";

#
#	Calculating the average values for each year of the products
#
for my $i (0..$increment){
			$rent_per_year_sum[$i] = $rent_per_year_sum[$i] / 12;
}

for my $i (0..$increment){
			$owned_per_year_sum[$i] = $owned_per_year_sum[$i] / 12;
}

#
#	Writing to array the fields and values which will be used to graph the output
#
for my $i (2000..2016) {
			#Format: Product name, year, value
			$output_record_count++;
			$newline = "Rented Accomodation,".$i.",".$rent_per_year_sum[$i - 2000]."\n";
			$output_records[$output_record_count] = $newline;

			$output_record_count++;
			$newline = "Owned Accomodation,".$i.",".$owned_per_year_sum[$i - 2000]."\n";
			$output_records[$output_record_count] = $newline;
}

#
#	Opening the output file
#
open my $output_file_fh, '>', $output_file
    or die "Unable to open file: $output_file\n";

#	Writes out the headers in the file
print $output_file_fh '"Product","Year","Value"'."\n";

#	Writes the information to be plotted into the file
foreach my $output_record (@output_records){
	print $output_file_fh $output_record;
}

#
#	Closing the output file
#
close $output_file_fh or
    die "Unable to close: $ARGV[1]\n";


############################
#						   #
# Start of graphing script #
#						   #
############################

# Saves the name of the output file and prints it along with the txt file
print "output text file = $output_file\n";
$pdffilename = "Q4".$provinces[$answer_province - 1].".pdf";
print "output graph file = $pdffilename\n";

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

# Set up the PDF file for plots
$R->run(qq`pdf("$pdffilename" , paper="letter")`);

# Load the plotting library
$R->run(q`library(ggplot2)`);

# read in data from a CSV file
$R->run(qq`data <- read.csv("$output_file")`);

# Saves the title of the pdf file
$R->run(qq`graph_title <- substitute(paste("Comparing Rented and Owned Accomodation for ", ${edited_provinces[$answer_province - 1]}))`);

# plot the data as a line plot with each point outlined
$R->run(q`ggplot(data, aes(x=Year, y=Value, colour=Product, group=Product)) + geom_line() + geom_point(size=2) + ggtitle(graph_title) + ylab("Changes in Average CPI")`);
# close down the PDF device
$R->run(q`dev.off()`);

$R->stop();
