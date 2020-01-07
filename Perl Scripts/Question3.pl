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
my $sorted_file = $EMPTY;
my $output_file = $EMPTY;
my $census_file_name = $EMPTY;
my @census_records = $EMPTY;
my $sorted_record_count = -1;
my $output_record_count = -1;
my $census_record_count = -1;
my @provinces = ("Ontario", "Quebec", "Saskatchewan", "British Columbia", "Alberta", "Nova Scotia", "Manitoba", "New Brunswick", "Newfoundland and Labrador", "Prince Edward Island");
my @edited_provinces = ("ON", "QC", "SK", "BC", "AB", "NS", "MN", "NB", "NFL", "PEI");
my $answer_validator;
my $answer_province;
my $csv          = Text::CSV->new({ sep_char => $COMMA });
my @prescribed_medicine_per_year_sum = 0;
my @household_spending_per_year_sum = 0;
my @output_records = $EMPTY;
my $increment = -1;
my $newline;


#
#	Saves the name of the file to be used
#

$sorted_file = "CPIOutput.txt";
$census_file_name = "Consensus_Data.csv";


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
	print "You entered ${answer_province} and thus you wanted ".$provinces[$answer_province - 1]."\n";

	# Do - while loop to check if they entered the correct answer
	do {
		print "Is this the province you wanted? [Answer with Y or N]: ";
		$answer_validator = <STDIN>;
		chomp $answer_validator;
	} while ($answer_validator !~ m/^[y|Y|n|N]$/);

} while(lc($answer_validator) ne "y");

$output_file = "Q3".$provinces[$answer_province - 1].".txt";


#
#	Open the processed CPI file
#
open my $file_in_use, '<', $sorted_file
    or die "Unable to open file: $sorted_file\n";

#	Goes through each csv record in the file and collects only the necessary data
while (my $text_file_record = <$file_in_use>){
	my @master_fields = split "," , $text_file_record;

	#	Taking out only the relevant info into an array (Prescribed medicines for the selected province)
	if(($master_fields[1] eq $provinces[$answer_province - 1]) && ($master_fields[4] =~ m/^(\d*.205)$/) ){
		$sorted_record_count++;

		#	Changes the index for the arrays every 12 months which indicates a new year.
		if (($sorted_record_count) % 12 == 0) {
			$increment++; #Changes the index for prescribed_medicine_per_year_sum every 12 months which indicates a new year.
		}

		#	Each index for each array holds the total sum values for each year which can then be divided by 12 for avg in the year.
		if($master_fields[4] =~ m/^(\d*.205)$/){
			$prescribed_medicine_per_year_sum[$increment] +=  $master_fields[5];
		}
	}
}

#
#	Closing the processed CPI file
#
close $file_in_use or
    die "Unable to close: $ARGV[0]\n";

#
#	Opening the Census file and loading its contents in an array then closing it
#
open my $census_file_fh, '<', $census_file_name
	or die "Unable to open file: $census_file_name\n";

@census_records = <$census_file_fh>;

close $census_file_fh or
	die "Unable to close: $ARGV[1]\n";

#	Goes through each record in the census file and collects only the necessary data
foreach my $census_record (@census_records){
	if ( $csv->parse($census_record) ) {
    	my @master_fields = $csv->fields();

    	# Takes out only the relevan information into an array (houshold spendings on prescription drugs after tax for the years 2000 - 2008)
    	if(($master_fields[0] >= 2000 && $master_fields[0] <= 2008 ) && ($master_fields[1] eq $provinces[$answer_province - 1]) && ($master_fields[10] =~ m/^(\d*.1.1)$/) ){
    		$census_record_count++;
    		$household_spending_per_year_sum[$census_record_count] = $master_fields[11];
		}


   }
}

#
#	Calculating the average values for each year of the product for the years 2000-2008 only
#
for my $i (0..$census_record_count){
			$prescribed_medicine_per_year_sum[$i] = $prescribed_medicine_per_year_sum[$i] / 12;
}

#
#	Writing to array the fields and values which will be used to graph the output
#
for my $i (2000..2008){
			#Format: Product name, year, value
			$output_record_count++;
			$newline = "Prescribed Medication Price Change,".$i.",".$prescribed_medicine_per_year_sum[$i - 2000]."\n";
			$output_records[$output_record_count] = $newline;

			$output_record_count++;
			$newline = "Spending on Prescription Drugs per Households (After tax),".$i.",".$household_spending_per_year_sum[$i - 2000]."\n";
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
$pdffilename = "Q3".$provinces[$answer_province - 1].".pdf";
print "output graph file = $pdffilename\n";

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

# Set up the PDF file for plots
$R->run(qq`pdf("$pdffilename" , paper = "letter")`);

# Load the plotting library
$R->run(q`library(ggplot2)`);

# read in data from a CSV file
$R->run(qq`data <- read.csv("$output_file")`);

# Saves the title of the pdf file
$R->run(qq`graph_title <- substitute(paste("Comparing CPI and spending per households on Prescription drugs for ", ${edited_provinces[$answer_province - 1]}))`);

# plot the data as a line plot with each point outlined
$R->run(q`ggplot(data, aes(x=Year, y=Value, colour=Product, group=Product)) + geom_line() + geom_point(size=2) + ggtitle(graph_title) + scale_y_continuous(
    "Changes in Average CPI",
    sec.axis = sec_axis(~ . * 1.0, name = "Percentage Spending per Household")
  )`);
# close down the PDF device
$R->run(q`dev.off()`);

$R->stop();
