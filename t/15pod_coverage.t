# $Id: 15pod_coverage.t,v 1.1.1.1 2006/02/20 00:35:57 toni Exp $
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok(  );
