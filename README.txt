Natural Language Licenses to RDF
--------------------------------

Text clasification tool for transforming natural language licenses to ODRL RDF
data.

NLL2RDF Active Learner Copyright (C) 2014 Cristian A. Cardellino This program
comes with ABSOLUTELY NO WARRANTY. 
This is free software, and you are welcome to redistribute it under certain
conditions. See LICENSE for details, or visit
<http://www.gnu.org/licenses/gpl.html>.


Requirements:
-------------

- Java JRE 1.7
- Unix OS (Linux or OSX): This program uses many scripts with access
  to many unix programs and functions and is not suitable for a
  Windows environment.
- Perl 5.18.4 or above with the following modules:
  - List::MoreUtils
  - String::Util


Perl:
-----

For the perl version and the String module I advice the installation of
perlbrew and cpanm. Visit <http://perlbrew.pl/> for information on this
installation. You can follow the steps descriptive above, or you can run
`config.sh` (provided the necessary permissions) to do it automatically (only
tested on Linux, should also work on OSX).

$ \curl -L http://install.perlbrew.pl | bash # Installation of perlbrew

After the installation add: `source ~/perl5/perlbrew/etc/bashrc`
to your ~/.bashrc or ~/.bash_profile file.

Install an available version of `perl-5.18` (for example perl-5.18.4) with:
`perlbrew install perl-5.18.4`.

When installation is complete, select the installed perl version with
`perlbrew use perl-5.18.4`.

Install cpanm with: `perlbrew install-cpanm`.

Install the modules: `cpanm List::MoreUtils String::Util`.


Usage:
------

To start the learning process give execution permissions to the `learner` file
or use `perl learner`:

`./learner -t <TAGGED_DIR> -u <UNTAGGED_DIR> -o <OUTPUT_DIR> [-q <NUMBER_OF_QUERIES>] [-f <FILTER_TAGGED_CORPUS>] [-g <FILTER_UNTAGGED_CORPUS>] [--passive]`


Options:
--------

  -t <TAGGED_DIR>
    Required. TAGGED_DIR must be the path (absolute or relative) to the
    directory where the initial annotated corpus is stored in conll IOB format in
    the different subdirectories. The corpus can be obtained in the following
    link <http://www.cs.famaf.unc.edu.ar/~ccardellino/resources/licensescorpus/licenses_annotated.tar.bz2>.
    By decompressing the tar file, the needed directory is listed as:
    "licenses-conll-format".

  -u UNTAGGED_DIR
    Required. Directory containing the unannotated corpus, tagged in conll 
    format. The unannotated corpus can be obtained by following the link:
    <http://www.cs.famaf.unc.edu.ar/~ccardellino/resources/licensescorpus/licenses_unannotated_conll.tar.bz2>.
    The directory "conll-corpus" is the target directory.

  -o OUTPUT_DIR
    Required. Directory that will storage the data, results and models
    of each iteration. Should be an emtpy directory.

  -q NUMBER_OF_QUERIES
    Optional. A number indicating the number of queries the oracle will
    annotate manually in each iteration of the algorithm. If not provided
    it's default value is 5.

  -f FILTER_TAGGED_CORPUS
    Optional. A number that indicates a filter for the times a feature
    in the annotated corpus shall occur to be taken in consideration for
    building the model. If not provided it's default value is 0 (all
    features are considered).

  -g FILTER_UNTAGGED_CORPUS
    Optional. A number that indicates a filter for the times a feature
    shall occur in the unannotated corpus to be taken in consideration for
    building the unannotated corpus model. If not provided the default
    value is 10.
    NOTE: This number directly affect on the overall performance of the
    learner. The smaller it is, the slower the algorithm becomes. On
    bigger numbers, the performance improve but the queries are less
    useful. On initial experiments, a number between 10 and 20 is the
    best option.

  -passive
    Optional. A flag that, if present, will do a Passive Learning approach,
    that is, will randomly select the instances from the pool of unlabeled
    instances, instead of using Uncertainty Sampling to select the instances
    to annotate by the oracle.


Program Execution:
------------------

The program will run on a loop. The first time, the classifier will learn from
the initial annotated corpus.

In this each iteration, the algorithm learn one classifier for each possible
class of the corpus. Each classifier is binary and is tested over a 10-fold
cross-validation of the annotated corpus.

In the active learning approach, on each iteration after the initial, all the
unannotated corpus will be classified with every one of the possible
classifiers. Those instances with the worst classification results are selected
for querying.

In the query phase of the iteration, you will be prompted with a sentence (or
part of a sentence), representing a possible instance to annotate. You'll have
14 available options, one for each possible class and an extra option if the
instance do not satisfy any of the possible option ("no class"). Please,
annotate the instance enumerating every suitable class separated by a comma.

Once you end the query annotation phase the algorithm will retrain the corpus
and show the new results with colors, every red item represents a lower value
than the previous step, green items represent a higher value and blue items
represents an equal value than the previous step.

Finally the program will prompt with a question if you want to have a new
iteration or finish the iteration in that step. Any value besides "yes" or "y"
(even a blank value) will end the program execution.


Results Directory Structure:
----------------------------

The results directory (OUTPUT_DIR option in the console command) will create a
directory structured like so:

- iteration*/
  - data/
    - binary/
  - features/
  - instances/
    - tagged/
  - models/
  - results/

Where each of these directories contain the following information:
  - data/ This directory stores the arff file for a unique multiclass
    classifier of the annotated corpus as well as the csv file with the
    instances information of the unannotated corpus
  - data/binary/ This directory contains the arff files for each of the
    possible classes of the annotated corpus, thus used for the creation of the
    binary classifiers
  - features/ This directory contains information on the selected features for
    each of the models of the binary classifiers
  - instances/ This directory (not presented in the iteration 0) is use for
    storing of all the readable versions of instances extracted from the
    unannotated corpus and works in the annotation of the queried instances
    both in active learning and passive learning methodologies.
  - instances/tagged/ This directory contains the tagged instances that were
    obtained in the process of querying.
  - models/ This directory contains a serialized version of the models of the
    iteration, this are binary files readable as Java objects.
  - results/ This directory contains the results of evaluating each of the
    classifiers with a 10-fold cross-validation evaluation, as well as a file
    (showed on each iteration of the learner) containing the general results
    for each class of the Kappa, Precision, Recall and F-Score, as well as
    general statistics of these values (Weighted Mean, Median, Mean and
    Standard Deviation)
