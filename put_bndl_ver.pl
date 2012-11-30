# Xcode auto-versioning script for Subversion by Axel Andersson
# Updated for git by Marcus S. Zarra and Matt Long
# Modified by Makoto Yamashita
 
use strict;
 
# Get the current git commit hash and use it to set the CFBundleVersion value
my $GITBIN;
my @GITPATHS = ("/usr/local/git/bin/git", "/opt/local/bin/git", "/usr/bin/git", "/usr/local/bin/git");
SEARCHGIT: foreach my $GITCAND(@GITPATHS) {
	if (-e $GITCAND) {
		$GITBIN = $GITCAND;
		last SEARCHGIT;
	}
}
my $REV;
if ($GITBIN && -e "$ENV{PWD}/.git") {
	$REV = `$GITBIN show --abbrev-commit | grep "^commit"`;
} else {
	$REV = "commit dummy-version";
}

my $INFO = "$ENV{BUILT_PRODUCTS_DIR}/$ENV{WRAPPER_NAME}/Contents/Info.plist";
my $ELEM = "$ENV{BUILT_PRODUCTS_DIR}/$ENV{WRAPPER_NAME}/Contents/Resources/element.xml";

my $version = $REV;
if( $version =~ /^commit\s+([^.]+)$/ )
{ 
	$version = $1;
	chomp $version;
}
else
{
	$version = undef;
}
die "$0: No Git revision found: $REV" unless $version;
 
open(FH, "$INFO") or die "$0: $INFO: $!";
my $info = join("", <FH>);
close(FH);
 
$info =~ s/([\t ]+<key>CFBundleVersion<\/key>\n[\t ]+<string>).*?(<\/string>)/$1$version$2/;
 
open(FH, ">$INFO") or die "$0: $INFO: $!";
print FH $info;
close(FH);

open(FH2, "$ELEM") or die "$0: $ELEM: $!";
my $elem = join("", <FH2>);
close(FH2);
 
$elem =~ s/([\t ]*<element [^>]+version=\").*?(\".*?>)/$1$version$2/;
 
open(FH2, ">$ELEM") or die "$0: $ELEM: $!";
print FH2 $elem;
close(FH2);

