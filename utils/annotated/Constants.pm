use strict;
use warnings;

package Constants;

use parent("Exporter");

my %classes = (
  "DUTY" => "REQ",
  "PERMISSION" => "PER",
  "PERMITS" => "PER",
  "PROHIBITION" => "PRO",
  "PROHIBITS" => "PRO",
  "REQUIRES" => "REQ"
);

my %rules = (
  "ATTACHPOLICY" => "ATTACHPOLICY",
  "ATTACHSOURCE" => "ATTACHSOURCE",
  "ATTRIBUTE" => "ATTRIBUTE",
  "ATTRIBUTION" => "ATTRIBUTE",
  "COMMERCIALIZE" => "COMMERCIALIZE",
  "COMMERCIALUSE" => "COMMERCIALIZE",
  "COPY" => "REPRODUCE",
  "DERIVATIVEWORKS" => "DERIVE",
  "DERIVE" => "DERIVE",
  "DISTRIBUTE" => "DISTRIBUTE",
  "DISTRIBUTION" => "DISTRIBUTE",
  "MODIFY" => "DERIVE",
  "NOTICE" => "ATTACHPOLICY",
  "READ" => "READ",
  "REPRODUCE" => "REPRODUCE",
  "REPRODUCTION" => "REPRODUCE",
  "SELL" => "SELL",
  "SHARE" => "DISTRIBUTE",
  "SHAREALIKE" => "SHAREALIKE",
  "SHARING" => "DISTRIBUTE"
);

sub get_class {
  my $class = shift @_;
  
  return $classes{$class};
}

sub get_rule {
  my $rule = shift @_;
  
  return $rules{$rule};
}

our @EXPORT = ("get_class", "get_rule");

return 1;