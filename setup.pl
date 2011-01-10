use lib qw(/home/data2/modperl/scenarios-windy);

# Go go coverage testing
#use Devel::Cover;

use Carp ();
$SIG{__WARN__} = \&Carp::cluck;

use CGI ('-compile');

use Fcntl ();
use File::Slurp ();
use Exporter ();
use Digest::MD5 ();
use POSIX ();
use Text::CSV_XS ();
use Geo::Proj4 ();

use Apache2::Const ();
use APR::URI ();
use Apache2::Util ();
use Apache2::RequestRec ();

use CICS::Helpers ();

use CICS::FormHandler::Checkbox ();
use CICS::FormHandler::Textfield ();
use CICS::FormHandler::Textbox ();
use CICS::FormHandler::Hiddenfield ();
use CICS::FormHandler::Selectfield ();
use CICS::FormHandler::Submitbutton ();
use CICS::FormHandler::Radiobutton ();
use CICS::FormHandler::PointList ();

use CICS::FormHandler::Form ();
use CICS::FormHandler::FormBit ();

use CICS::Scenario::Helpers ();
use CICS::Scenario::Data ();
use CICS::Scenario::Config ();
use CICS::Scenario::Cache ();
use CICS::Scenario::MainForm ();
use CICS::Scenario::Regions ();
use CICS::Scenario::Displayer ();

return 1;
