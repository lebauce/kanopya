#!/usr/bin/perl -w

# -----------------------------------------------------------------------
# perlmod2www.pl - convert Perl mdoules tree to equivalent www tree with HTML format documentation.
# 
# Use -h for help.
# 
# Copyright (c) 2000-2006 Raphael Leplae raphael@scmbb.ulb.ac.be
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
# -----------------------------------------------------------------------

# Add the path where the Pdoc directory is located here, if needed.
# use lib '/some/where';

use strict;
use FileHandle;
use Carp qw(cluck confess);

# Need a Perl module parser
use Pdoc::Parsers::Files::PerlModule;
# A Tree
use Pdoc::Tree;
# Some renderers
use Pdoc::Html::Renderers::TreeFilesIndexer;
use Pdoc::Html::Renderers::TreeNodesIndexer;
use Pdoc::Html::Renderers::PerlModule;
use Pdoc::Html::Renderers::PerlToc;

# Need the document parser + modules
use Pdoc::Parsers::Documents::Parser;
use Pdoc::Parsers::Documents::Modules::WebCvs;

# Extra converters might required
use Pdoc::Html::Converters::Modules::WebCvs;
use Pdoc::Html::Converters::Modules::RawContent;
use Pdoc::Html::Tools::UrlMgr;

# Need highlighters
use Pdoc::Html::Tools::PerlHighlight;
use Pdoc::Html::Tools::PodHighlight;
use Pdoc::Html::Tools::PageHighlight;

# For config object
use Pdoc::Config;

# Define default global variables & values
use vars qw( $VERSION $RELEASE $_pdocUrl $psep $config 
    	     $_authorName $_authorEmail );

# Init globals
$VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
$RELEASE = '1.1';
$_pdocUrl = 'http://sourceforge.net/projects/pdoc';
$_authorName = 'Raphael Leplae';
$_authorEmail = 'raphael@scmbb.ulb.ac.be';

# Do not buffer
$| = 1;

# Global variables

# Holds comand line argument data
my $params = {};

# Source path, default to pwd
$params->{'source'} = $ENV{'PWD'};

# Sort flag, if 1 do not sort methods in perl module doc page
$params->{'no_sort'} = 0;

# Flag to add Document parser or not
$params->{'parseDoc'} = 0;

# Define default dir(s) to skip
$params->{'to_skip'} = 'CVS,blib';

# Flag to check ISA modules
$params->{'isa_check'} = 0;

# Flag to add file raw content
$params->{'use_raw'} = 0;

# Rendering style
$params->{'render_style'} = 'css';

# Cross links (-xl or -xltable)
my @xl = ();

# Cross linked tree objects
my $xtrees;

# Parse passed args
getArgs();

# Assign render style
Pdoc::Html::Tools::PerlHighlight::style($params->{'render_style'});
Pdoc::Html::Tools::PodHighlight::style($params->{'render_style'});
Pdoc::Html::Tools::PageHighlight::style($params->{'render_style'});

# Need config object
$config = Pdoc::Config->new();

# Now create documentation for each module:
# Need the Perl module parser
my $mod_parser = Pdoc::Parsers::Files::PerlModule->new();

# Need the Perl module renderer
my $mod_renderer = Pdoc::Html::Renderers::PerlModule->new();

# Get doc converter
my $mod_converter = $mod_renderer->getConverter();

# If config file, load it now:
if ($params->{'config_file'}) {
    # Try to load config file
    if (! $config->load($params->{'config_file'})) {
    	cluck("Failed to load config file: ", $params->{'config_file'}, " !\n");
    } else {
    	# Assign config to various modules
	Pdoc::Html::Tools::PerlHighlight::config($config);
	
	$mod_renderer->config($config);
    }
}

# Check target path now
unless (-d $params->{'target'}) {
    print "Target dir ", $params->{'target'}, " is not a directory.\n";
    exit;
}

# Get doc head and foot
exit unless (getHeadFoot());

# Clean root url
if ($params->{'wroot'} && $params->{'wroot'} =~ /.+\/$/) {
    chop $params->{'wroot'}; }

# Get the tree
print "Getting tree from ", $params->{'source'}, " ...\n";
my $tree = extractTree($params->{'source'},$params->{'wroot'});
my $targetTree;
# If relative urls, use separate tree with target as path for proper linking
unless ($params->{'wroot'}) {
    $targetTree = Pdoc::Tree->new();
    $targetTree->name('Perl modules documentation.');
    $targetTree->path($params->{'target'});
    $targetTree->root($tree->root());
    
    push (@{$xtrees}, $targetTree);
} else {
    push (@{$xtrees}, $tree);
}

# Extract cross ref trees
if (@xl) {
    print "Getting trees for cross-linking:\n";
    foreach my $parts (@xl) {
    	print "Extra tree from ", $parts->[0], "\n";
	my $extra = extractTree($parts->[0],$parts->[1]);
	
	# If relative paths, redef path with path to Doc tree
	$extra->path($parts->[1]) unless ($params->{'wroot'});
	push (@{$xtrees}, $extra);
    }
}

# Define target path correctly
$psep = $tree->path_separator();
$params->{'target'} =~ s/[\/\\:]/$psep/g;
$params->{'target'} =~ s/$psep$//;

# Define CSS file if required
if ($params->{'render_style'} eq 'css') {
    if ($params->{'css_url'}) {
    	$tree->set('perl_css_url', $params->{'css_url'});
    } else {
	# Define css file if required
	unless ($params->{'css_source'}) {
    	    $params->{'css_source'} = $config->libRootPath() . $tree->path_separator() . 'Pdoc' . $tree->path_separator() . 'Html' . $tree->path_separator() . 'Data' . $tree->path_separator() . 'perl.css';
	}

	unless (-e $params->{'css_source'}) {
    	    print "\nWarning: failed to find source CSS file defined as ", $params->{'css_source'}, ".\nThe web pages won't be properly viewed.\n\n";
	}

	$params->{'css_target'} = $params->{'target'} . $tree->path_separator() . 'perl.css';
    }
}

# Renderer for TOC
my $tocRenderer = Pdoc::Html::Renderers::PerlToc->new();

# Assign config if present
$tocRenderer->config($config) if $config->loaded();

# Generate all index files
if (! Generate_indexes($tree)) {
    print "Failed generating indexes.\n";
    exit;
}

# Add extra trees to renderer
$mod_renderer->trees($xtrees);

# If no sorting of method names
if ($params->{'no_sort'}) {
    $mod_renderer->sortMethods(0); }

# Converter configuration:

# Assign check flag for isa modules
$mod_converter->checkIsa($params->{'isa_check'});

# Add raw content convertr if needed
if ($params->{'use_raw'}) {
    print "Raw content files will be added to the HTML tree.\n";
    my $rawConverter = Pdoc::Html::Converters::Modules::RawContent->new();
    $rawConverter->matchType('PerlPackage');
    $mod_converter->add($rawConverter);
}

# Create a document parser if needed
my $doc_parser;
if ($params->{'parseDoc'} == 1) {
    $doc_parser = Pdoc::Parsers::Documents::Parser->new();

    # and add document parser + corresponding converter
    if (defined $params->{'webCvs'}) {
	print "Including WebCvs crosslink to ", $params->{'webCvs'}, ".\n";

	my $wcvs_pars = Pdoc::Parsers::Documents::Modules::WebCvs->new();
	# Set doc entry to match
	$wcvs_pars->matchType('PerlPackage');
	$doc_parser->add($wcvs_pars);

	my $wcvs_conv = Pdoc::Html::Converters::Modules::WebCvs->new();
	# Assign url and config
	$wcvs_conv->set('webcvs', $params->{'webCvs'});
	
	$wcvs_conv->config($config) if $config->loaded();
	$mod_converter->add($wcvs_conv);
    }
}

my $tocAllDoc = Pdoc::Document->new();
$tocAllDoc->name('TOC for all levels');
$tocAllDoc->set('title', 'TOC for all levels');

#initTocAll();

# Start the convertion!
generateDoc($tree->root());

generateTocAll($tree, $tocAllDoc);

# Generate initial main frame
generateMainFrame($tree);

# 5) Generate final index file
generateFrames();

print "Completed Perl modules documentation.\n";

exit;

# generateTocAll: generate the tocAll.html file in the root html dir tree. The file contains the TOC of all perl packages in the library.

sub generateTocAll {
    my $tree = shift;
    my $tocDoc = shift;
    
    my $fname = $params->{'target'} . $tree->path_separator() . 'tocAll.html';
    my $tocAllFpt = FileHandle->new(">$fname");
    confess("Can't create $fname!") unless ($tocAllFpt);
    
    # Create temp document to define paths in html file
    my $doc = Pdoc::Document->new();
    $doc->name('TOC all levels');
    $doc->node($tree->root());
    
    my $initStyle = $mod_renderer->htmlHead($tree, $doc);
    
    # Write page header
    print $tocAllFpt <<XXX;
<html>
<head>
<!-- Generated by perlmod2www.pl -->
<title>
TOC for all levels
</title>
$initStyle
</head>
<body bgcolor="#ffffff">
<a name="TOP"></a>
XXX

    # Store TOC for this node
    $tocRenderer->render($tocAllFpt,$tocDoc);
    
    # Finish page
    print $tocAllFpt '</body></html>', "\n";
    
    $tocAllFpt->close();
    
    return 1;
}

# checkDir: get a path and create all necessary directories

sub checkDir {
    my $path = shift;
    
    my $sep = quotemeta $tree->path_separator();
    my @dirs = split (/$sep/, $path);
    my $pcheck = "";
    $pcheck = $tree->path_separator() if( $path =~ /^$sep/ );
    
    foreach my $dir (@dirs) {
	next if (! defined $dir || $dir eq "" || $dir eq '.');
    	$pcheck .= $dir . $tree->path_separator();
	if (! -d $pcheck) {
	    unless (mkdir ($pcheck, 0755)) {
	    	print "Error: failed to create directory $pcheck\n";
		exit;
	    }
	}
    }
}

# Generate_indexes: generate index files for all the directories

sub Generate_indexes {
    my $tree = shift;
    
    print "Generating indexes...\n";

    # 1st, index for Perl levels
    return 0 if (! generateLevels($tree));
    
     # 2nd, index for Perl modules in each level
     return generateAllModulesIndex($tree);
}

# generateLevels: create index file with all "Perl levels" (directories in the tree).

sub generateLevels {
    my $tree = shift;
        
    # Need the renderer
    my $indexer = Pdoc::Html::Renderers::TreeNodesIndexer->new();
    # Set some params
    $indexer->target('modules');
    $indexer->index('modules.html');
    $indexer->url($tree->url);
    $indexer->name_transform(\&pathToLevel);
    $indexer->config($config) if $config->loaded();
    
    # Create index file now
    my $html_file = $params->{'target'} . $tree->path_separator() . 'all_packages.html';
    
    print "Creating levels index file $html_file\n";
    
    my $fpt = FileHandle->new(">$html_file");
    if (! defined $fpt) {
	print "Unable to create $html_file!\n";
	return 0;
    }
    
    my $doc = Pdoc::Document->new();
    $doc->name('Perl levels');
    $doc->node($tree->root());

    my $initStyle = $mod_renderer->htmlHead($tree, $doc);
    
    # Store index now
    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
Perl levels
</title>
$initStyle
</head>
<body bgcolor="#ffffff">
XXX
    
    # Set tree title to be rendered
    $tree->set('title', '<a href="all_modules.html" target="modules">All Modules</a> <a href="tocAll.html" target="main">TOC All</a>');

#    # Is there a better name than "Perl levels"?
#    print $fpt "<BR><B>Perl levels</B><BR>\n";
    
    # Render index now
    $indexer->render($fpt, $tree);
    
    print $fpt '</body></html>', "\n";

    $fpt->close();

    return 1;
}

# generateAllModulesIndex: generate big index with all Perl modules in all directories
# then index for each directory.

sub generateAllModulesIndex {
    my $tree = shift;
    
    # Create renderer
    my $renderer = Pdoc::Html::Renderers::TreeFilesIndexer->new();
    # Set some params
    # Set the url
    $renderer->url($tree->url());
    $renderer->target('main');
    $renderer->name_transform(\&rmExt);
    $renderer->file_transform(\&rmExt);
    $renderer->usePath(1);
    $renderer->config($config) if $config->loaded();

    # Full indexing => need recursive flag on
    $renderer->set('recursive', 1);
    
    # Create index file now
    my $html_file = $params->{'target'} . $tree->path_separator() . 'all_modules.html';
    print "Creating global Perl modules index file $html_file\n";
    
    my $fpt = FileHandle->new(">$html_file");
    if (! defined $fpt) {
	print "Unable to create $html_file!\n";
	return 0;
    }
    
    my $doc = Pdoc::Document->new();
    $doc->name('All Perl Modules');
    $doc->node($tree->root());
    
    my $initStyle = $mod_renderer->htmlHead($tree, $doc);
    
    # Set root node title to be rendered
    $tree->root()->set('title', 'All Perl modules');
    
    # Store main index now
    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
All Perl Modules
</title>
$initStyle
</head>
<body bgcolor="#ffffff">
XXX

    # Generate full index
    $renderer->render($fpt, $tree->root());

    print $fpt '</body></html>', "\n";
    
    $fpt->close();

    # Now generate index for individual directory
    # => recursive flag off
    $renderer->set('recursive', 0);
    # Do not use paths in url now
    $renderer->usePath(0);

    if (! generateModulesIndex($tree->root(), $renderer)) {
	return 0; }
	
    return 1;
}

# generateModulesIndex: generate Perl modules index in a specific directory

sub generateModulesIndex {
    my $node = shift;
    my $renderer = shift;

    # Define local url for the renderer
    $renderer->url($tree->url());

    # Define www dir path
    my $path = $params->{'target'} . $tree->path_separator();
    $path .= $node->path() if ($node->path());

    checkDir($path);

    # Create index file now
    my $html_file = $path . $tree->path_separator() . 'modules.html';
    print "Creating Perl modules index file $html_file\n";
    
    my $fpt = FileHandle->new(">$html_file");
    if (! defined $fpt) {
	print "Unable to create $html_file!\n";
	return 0;
    }

    my $doc = Pdoc::Document->new();
    $doc->name('Perl Modules');
    $doc->node($node);
    
    my $initStyle = $mod_renderer->htmlHead($tree, $doc);
    
    # Store main index now
    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
Perl Modules
</title>
$initStyle
</head>
<body bgcolor="#ffffff">
XXX

    my $level = pathToLevel($node);
    $node->set('title', '<a href="toc.html" target="main">' . $level .'</a>');
    
    if (! $renderer->render($fpt, $node)) {
	print $fpt "<B>No modules in this level.</B>\n"; }
    
    print $fpt '</body></html>', "\n";

    $fpt->close();
    
    # Process sub directories
    my $iter = $node->nodeIterator();
    my $sub_node;
    while ($sub_node = $iter->()) {
    	last if (! generateModulesIndex($sub_node,$renderer)); }
	
    return 1;
}

sub generateMainFrame {
    my $tree = shift;
    
    print "Creating main frame.\n";
    
    # Define file name
    my $html_file = $params->{'target'} . $tree->path_separator() . 'main_index.html';
    
    my $fpt = FileHandle->new(">$html_file");
    if (! defined $fpt) {
	print "Unable to create $html_file!\n";
	return 0;
    }

    # Store main index now
    # Now make a nice web page!
    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
Perl Modules
</title>
</head>
<body bgcolor="#ffffff">
XXX
    
    print $fpt "<H1>Perl modules documentation for ", $tree->root_name(), "</H1>\n";
    
    print $fpt <<XXX;
<table><tr><td>
These pages have been automatically generated by perlmod2www.pl release $RELEASE. For any problem or suggestion, please contact $_authorName <A HREF="mailto:$_authorEmail">$_authorEmail</A>. <br>
</td><td>
See also<br><a href="$_pdocUrl" target="SF"><img src="http://sourceforge.net/sflogo.php?group_id=33199" alt="SourceForge" border="0" align="absmiddle"></a><br>for more information.
</td></tr></table>
<hr>
<h3>Navigation</h3>
<b>Top left frame</b> displays the directory tree with the Perl modules using &quot;Perl syntax&quot; for the paths. Click on one path to display in the bottom left frame the Perl modules available. 
The <b>All modules</b> link displays all the modules available in the bottom left frame (shown by default). 
The <b>TOC All</b> link displays the table of contents for the whole library in this frame. 
<p>
<b>Bottom left frame</b> displays the modules available in a particular directory level or all the modules available (shown by default). Click on one of the modules to display the documentation in the main (this) frame. Clicking on the library level name will display in the main frame the table of content for the level.
<p>
<b>Main frame</b> is used to display documentation about a particular Perl module. The documentation is subdivided in several parts (may vary) presenting the POD found in the file, information about included packages, inheritance, subroutines code, etc...<p>
<hr>
<b>Warning</b> : the content presented in these pages might not be 100% accurate! Some data might be missing, in particular in the Perl source code which is presented only as a complement to the POD. Better access the original source code either through the "Raw content" link in the documentation page if available or directly through the Perl module file.
<hr>
</body>
</html>
XXX

    $fpt->close();

    return 1;
}

# generateFrames: creates the initial page with the frames definition
sub generateFrames {
    print "Creating main page.\n";
    
    if ($params->{'render_style'} eq 'css' && ! $params->{'css_url'}) {
	print "Creating CSS file ", $params->{'css_target'}, " from ", $params->{'css_source'}, " ...\n";
	my $in = FileHandle->new($params->{'css_source'});
	unless ($in) {
	    print "Error: failed to open ", $params->{'css_source'}, " !\nThe web pages won't be properly viewed.\n";
	} else {
	    my $out = FileHandle->new('>' . $params->{'css_target'});
	    unless ($out) {
	    	print "Error: failed to create file ", $params->{'css_target'}, " !\nThe web pages won't be properly viewed.\n";
	    } else {
	    	while (<$in>) { print $out $_; }
		$out->close();
		$in->close();
	    }
	}
    }
    
    # Define file name
    my $html_file = $params->{'target'} . $tree->path_separator() . 'index.html';
    
    my $fpt = FileHandle->new(">$html_file");
    if (! defined $fpt) {
	print "Unable to create $html_file!\n";
	return 0;
    }

    # Store main index now
    # Now make a nice web page!
    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
XXX

    print $fpt "Perl modules documentation for ", $tree->root_name(), "\n";
    
    print $fpt <<XXX;
</title>
</head>
<frameset cols="30%,70%">
<frameset rows="30%,70%">
<frame src="all_packages.html" name="packages">
<frame src="all_modules.html" name="modules">
</frameset>
<frame src="main_index.html" name="main">
</frameset>
</body>
</html>
XXX

    $fpt->close();

    return 1;
}

# generateDoc: generate Perl module documentation

sub generateDoc {
    my $node = shift;
    
    my $fullPath = $tree->path() . $tree->path_separator();
    $fullPath .= $node->path() . $tree->path_separator() if ($node->path());
    
    print "Generating documentation from ", $fullPath, "\n";
    
    # Init toc
    my $title = pathToLevel($node);
    
    # Document for TOC
    my $nodeToc = Pdoc::Document->new();
    $nodeToc->name('TOC');
    $nodeToc->node($node);
    $nodeToc->set('title', 'TOC for ' . $title);
    
    my $fname = $params->{'target'} . $tree->path_separator();
    $fname .= $node->path() . $tree->path_separator() if ($node->path());
    $fname .= 'toc.html';
    
    my $tocFpt = FileHandle->new(">$fname");
    confess("Can't create $fname!") if (! $tocFpt);
    
    my $initStyle = $mod_renderer->htmlHead($tree, $nodeToc);

    print $tocFpt <<XXX;
<html>
<head>
<!-- Generated by perlmod2www.pl -->
<title>
TOC for $title
</title>
$initStyle
</head>
<body bgcolor="#ffffff">
XXX

    my $fpt;
    my $file;
    # Iterate on files in the tree node
    my $iter = $node->fileIterator();    
    while ($file = $iter->()) {
    	my $fname = $tree->path() . $tree->path_separator();
	$fname .= $node->path() . $tree->path_separator() if (defined $node->path());
	$fname .= $file->name();
    	
	print "# File $fname\n";
    	$fpt = FileHandle->new($fname);
	if (! defined $fpt) {
	    print "Failed opening $fname, skipped.\n";
	    next;
	}
    	
	# Let the file parser do the job
	my $parsed;
	my $count = 0;
	
	# Parse file and collect document(s)
	$mod_parser->stream($fpt);
	my $parsedDocs = {};
	while ($parsed = $mod_parser->nextDocument($node)) {
	    push (@{$parsedDocs->{'docs'}}, $parsed);

	    # Several packages in 1 module?
	    my $pmFile = $file->name();
	    
	    if ($count > 0) {
	    	$pmFile =~ s/\.([^\.]+)$/.$count.$1/;
	    }
    	    
	    # Define html file
	    my $baseUrl = rmExt($pmFile);
	    my $htmlFile = $params->{'target'} . $tree->path_separator();
	    $htmlFile .= $node->path() . $tree->path_separator() if (defined $node->path());
	    $htmlFile .= $baseUrl . '.html';
	    
	    push (@{$parsedDocs->{'links'}}, $baseUrl . '.html');
	    push (@{$parsedDocs->{'files'}}, $htmlFile);
	    push (@{$parsedDocs->{'names'}}, $parsed->name());
	    
	    # Build Toc
	    my $perlPack = $parsed->fetch('PerlPackage')->[0];
	    my $podName = $parsed->fetch('PodHead', 'NAME');
	    if ($perlPack) {
		my $tocEntry = Pdoc::DocEntry->new();
		$tocEntry->type('toc');
		$tocEntry->name($parsed->name());
		$tocEntry->content($podName->content()) if ($podName);
		$tocEntry->set('link', $baseUrl . '.html');
		
		addTocEntry($tocEntry, $nodeToc, $baseUrl);
	    }

	    $count++;
	}
	
	# If several packages in 1 module, need to keep track
	$parsedDocs->{'pos'} = 0;
	foreach $parsed (@{$parsedDocs->{'docs'}}) {
	    # Set some values to the document
    	    $parsed->file($file->name());
	    
	    # Go through the document parser for eventual
	    # extra work if needed
	    $doc_parser->parse($parsed) if ($params->{'parseDoc'});
	    
    	    # Render document to an HTML page
	    renderDoc($node, $parsedDocs, $parsed);
	    
	    $parsedDocs->{'pos'}++;
	}
	
	$fpt->close();
	
	# Warning if something wrong
	if (! $count) {
	    print "Warning: failed to parse and/or convert file $fname!\n";
	    print "Check if package name definition is correct ('package' line)\n";
	    print "File skipped.\n";
	    next;
	}
    }
    
    # Store TOC for this node
    $tocRenderer->render($tocFpt,$nodeToc);
    
    print $tocFpt '</body></html>', "\n";

    $tocFpt->close();
    
    # Add the TOC elements to the main TOC
    # Add index first
    my $tocEntry = Pdoc::DocEntry->new();
    $tocEntry->type('tocIndex');
    $tocEntry->name($title);
    $tocEntry->content('<a href="#' . $title . '">' . $title . '</a>');
    
    $tocAllDoc->add($tocEntry);
    
    # Add section header
    $tocEntry = Pdoc::DocEntry->new();
    $tocEntry->type('tocHead');
    $tocEntry->name($title);
    $tocEntry->content('<a name="' . $title . '"></a>' . $title);
    
    $tocAllDoc->add($tocEntry);
    
    # Update urls and add TOC elements to the main TOC
    $iter = $nodeToc->iterator();
    my $entry;
    while ($entry = $iter->()) {
	$entry->set('url', $node->path() . '/' . $entry->get('link'));
	$tocAllDoc->add($entry);
    }

    # Descend tree
    $iter = $node->nodeIterator();
    my $sub_node;
    while ($sub_node = $iter->()) {
	generateDoc($sub_node); }

    return 1;
}

# renderDoc: transform a parsed Perl module to a web page

sub renderDoc {
    my $node = shift;
    my $parsedDocs = shift;
    my $document = shift;
    
    my $htmlFile = $parsedDocs->{'files'}->[$parsedDocs->{'pos'}];

    # Fname for raw data
    my $rawFile;
    
    # Get document name
    my $name = $document->name();
    
    if (! defined $name) {
    	print "No document name, not converted!\n";
	return 0;
    }

    # Get Perl level and module name
#    my $level = $tree->root_name;
    my $level;
    if ($name =~ /::/) {
	$name =~ /^(.*)::(.+)$/;
	$level = $1 if ($1 ne "");
	$name = $2;
    }
    
    $level = $tree->root_name() if (! defined $level || $level eq "");
    
    # Handle raw format
    if ($params->{'use_raw'}) {
    	$rawFile = rmExt($htmlFile);
    	$rawFile .= '_raw.html';
    }
        
    print "-> Rendering ", $document->name(), " in\n   $htmlFile\n";
    
    # Dissociate convertion and rendition
    unless ($mod_converter->convert($document)) {
    	print "Error: failed to convert the document!\n";
    	return 0;
    }
    
    if ($params->{'use_raw'}) {
    	return 0 unless addRawContent($rawFile, $document);	
    }
    
    # Write HTML file now
    my $fpt = FileHandle->new(">$htmlFile");
    if (! defined $fpt) {
    	print "Unable to create $htmlFile!\n";
	return 0;
    }
    
    my $initStyle = $mod_renderer->htmlHead($tree, $document);

    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
$name documentation.
</title>
$initStyle
</head>
<body bgcolor="white">
XXX
    print $fpt $params->{'doc_head'} if (defined $params->{'doc_head'});
    
    # Write page title
    print $fpt Pdoc::Html::Tools::PageHighlight::markup($level, 'MOD_ROOT_PATH'), "\n",
    	       Pdoc::Html::Tools::PageHighlight::markup($name, 'MOD_NAME'), "\n",
	       Pdoc::Html::Tools::PageHighlight::markup('', 'SEPARATOR'), "\n";
    
    # If more than one package in the module
    if (@{$parsedDocs->{'links'}} > 1) {
    	my $str = 'Other packages in the module: ';
	my $pos = 0;
	foreach my $link (@{$parsedDocs->{'links'}}) {
	    next if ($link eq $parsedDocs->{'links'}->[$parsedDocs->{'pos'}]);
	    $str .= '<a href="' . $link . '">' . $parsedDocs->{'names'}->[$pos]. '</a> ';
	    $pos++;
	}
	print $fpt Pdoc::Html::Tools::PageHighlight::markup($str, 'DESC_AREA'), "\n",
	    	   Pdoc::Html::Tools::PageHighlight::markup('', 'SEPARATOR'), "\n";
    }
    
    # Just delegate the job to the renderer
    $mod_renderer->render($fpt, $document);
    
    print $fpt $params->{'doc_foot'} if (defined $params->{'doc_foot'});
    
    print $fpt <<XXX;
</body>
</html>
XXX
    $fpt->close();
    
    return 1;
}

sub addRawContent {
    my $rawFile = shift;
    my $document = shift;
        
    # Check if raw content available
    my $rawEntry = $document->fetch('RawContent');
        
    # Stop here if nothing
    return 1 unless $rawEntry;
    
    print "Adding raw content in $rawFile\n";
    
    my $fpt = FileHandle->new(">$rawFile");
    if (! defined $fpt) {
    	print "Unable to create $rawFile!\n";
	return 0;
    }
    
    my $title = 'Raw content of ' . $document->name();
    
    print $fpt <<XXX;
<head>
<!-- Generated by perlmod2www.pl -->
<title>
$title.
</title>
</head>
<body bgcolor="#ffffff">
<b>$title</b>
XXX
    
    # Add content (of 1st and unique element of returned list)
    print $fpt $rawEntry->[0]->converted();

    print $fpt <<XXX;
</body>
</html>
XXX
    
    $fpt->close();
    
    # Change entry converted content with proper url
    my $sep = $tree->path_separator();
    $rawFile =~ /([^$sep]+)$/;
    $rawEntry->[0]->converted('<a href="' . $1 . '">Raw content</a>');
    
    return 1;
}

# pathToLevel: convert dir path to Perl level name

sub pathToLevel {
    my $obj = shift;
    
    # First get root name of the tree
    my $ret = $tree->root_name();
    
    # Get path of the passed obj file
    my $name = $obj->path();
        
    # Return root name if no path in file object
    return $ret if (! defined $name || $name eq "");
    
    # Use path separator defined from tree
    my $sep = quotemeta $tree->path_separator();
        
    # Replace separator with Perl style
    $name =~ s/^$sep//;
    $name =~ s/$sep/::/g;
    
    $ret .= '::' . $name;
    
    return $ret;
}

# rmExt: Just remove the extension from a Pdoc::DocEntry object related to a file.

sub rmExt {
    my $name = shift;
    $name =~ s/\.[^\.]+$//;
    return $name;
}

sub getHeadFoot {
    local (*FPT);
    my $line;
    if (defined $params->{'doc_head'}) {
    	if (! open (FPT, $params->{'doc_head'})) {
	    print "Failed opening documentation header file ", $params->{'doc_head'}, ".\n";
	    return 0;
	    }
	$params->{'doc_head'} = "";
	while ($line = <FPT>){
	    $params->{'doc_head'} .= $line; }
	close FPT;
    }
    
    if (defined $params->{'doc_foot'}) {
    	if (! open (FPT, $params->{'doc_foot'})) {
	    print "Failed opening documentation footer file ", $params->{'doc_foot'}, ".\n";
	    return 0;
	}
	
	$params->{'doc_foot'} = "";
	while ($line = <FPT>) {
	    $params->{'doc_foot'} .= $line; }
	close FPT;
    }
    
    return 1;
}

sub loadXl {
    my $file = shift;
    
    if (! -e $file) {
    	print "Cross link table file $file doesn't exists!\n";
	exit;
    }
    
    # Open file and start to extract lines
    my $fpt = FileHandle->new($file);
    my $line;
    while ($line = <$fpt>) {
    	chomp($line);
	next if ($line eq "");
	
	# Extract XL definition
	my @parts = split(/\s+/,$line);
	if (scalar(@parts) != 2) {
	    print "Invalid cross link reference for $line in file $file!\n";
	    $fpt->close();
	    Help();
	    exit;
	}
	
	print "Cross-link source: $parts[0] - $parts[1]\n";
	# Keep cross link
	push(@xl,\@parts);
    }
    
    $fpt->close();
}

sub extractTree {
    my $path = shift;
    my $url = shift;
    
    my $ntree = Pdoc::Tree->new();
    $ntree->name('Perl modules documentation.');
    $ntree->path($path);
    
    # Define directories to exclude
    my @skip = split(',',$params->{'to_skip'});
    foreach my $dir (@skip) {
	$ntree->exclude($dir); }

    # Get only .pm files
    $ntree->add_filter('.pm$');

    # Get tree and check if successful
    if (! defined $ntree->root()) {
	print "Failed parsing tree.\n";
	exit;
    }
    
    # Define url or redefined path - as necessary
    if (defined $url && $url =~ /^http:\/\//) {
	$ntree->url($url); }
    return $ntree;
}

sub addTocEntry {
    my $entry = shift;
    my $doc = shift;
    my $baseUrl = shift;
    
    # Clean stuff
    my $name = $entry->name();
    
    $name =~ /([^\:]+)$/;
    $name = $1;
    $entry->name($name);
    
    my $content = $entry->content();
    if ($content) {
	$content =~ s/\s*[^ ]+\s+-?\s*(.*)/$1/;
	$entry->content($content);
    }
    
    $entry->set('url', $baseUrl . '.html');
    
    $doc->add($entry);
}

# getArgs: process the arguments passed to the script.

sub getArgs {
    my $arg;
    
    while ($arg = shift (@ARGV)) {
	if ($arg eq "-h" || $arg eq "-help") {
	    Help ();
	    exit;
	}
	
	if ($arg eq '-source') {
	    $params->{'source'} = shift (@ARGV); }
	elsif ($arg eq '-target') {
	    $params->{'target'} = shift (@ARGV); }
	elsif ($arg eq '-wroot') {
	    $params->{'wroot'} = shift (@ARGV); }
	elsif ($arg eq '-skip') {
	    $params->{'to_skip'} .= ',' . shift (@ARGV); }
	elsif ($arg eq '-doc_header') {
	    $params->{'doc_head'} = shift (@ARGV); }
	elsif ($arg eq '-doc_footer') {
	    $params->{'doc_foot'} = shift (@ARGV); }
	elsif ($arg eq '-nosort') {
	    $params->{'no_sort'} = 1; }
	elsif ($arg eq '-conf') {
	    $params->{'config_file'} = shift (@ARGV); }
	elsif ($arg eq '-style') {
	    $params->{'render_style'} = shift (@ARGV); }
	elsif ($arg eq '-css') {
	    $params->{'css_source'} = shift (@ARGV); }
	elsif ($arg eq '-css_url') {
	    $params->{'css_url'} = shift (@ARGV); }
	elsif ($arg eq '-isa') {
	    $params->{'isa_check'} = 1; }
	elsif ($arg eq '-webcvs') {
	    $params->{'webCvs'} = shift (@ARGV);
	    $params->{'parseDoc'} = 1;
	} elsif ($arg eq '-raw') {
	    $params->{'use_raw'} = 1;
	} elsif ($arg eq '-xl') {
	    my $tmp = shift (@ARGV);
	    my @parts = split(',',$tmp);
	    if (scalar(@parts) != 2) {
	    	print "Invalid cross link reference for $tmp!\n";
		Help();
		exit;
	    }
	    
	    push(@xl,\@parts);
	} elsif ($arg eq '-xltable') {
	    my $file = shift(@ARGV);
	    loadXl($file);
	}
    }
}

# Help: -h

sub Help {
    print <<XXX;
perlmod2www.pl - a Perl modules tree documentation generator.

Mandatory arguments:
    -source <path>: Directory location of the tree with the Perl modules, must be existing.
    -target <path>: Directory location on the server side where the documentation tree will be generated, must be existing.
Optional arguments:
    -wroot <http>:  Url corresponding to the target directory.
    -style <css|html>: Defines the rendering style. Default set to 'css'. If set to 'html', basic html rendering will be used but this won't be supported anymore in the future!
    -css <CSS file>: defines the path to the CSS file with the styles definition. If not set, it will be automatically defined based on the Pdoc lib installation path but this is not trustable. Better define the path to the pdoc 'data' sub-directory obtained with the download or cvs checkout operation.
    -css_url <url with the perl.css file>: if set, the url will be used to specify the perl.css file location and the -css will be ignored.
    -skip dir1,dir2,dir3,...: skip the directory names separated by a comma (,). By default CVS directories are skipped.
    -doc_header <file name>: file with piece of HTML code that will be placed on top of every Perl module documentation (after <BODY>!).
    -doc_footer <file name>: file with piece of HTML code that will be placed at the end of every Perl module documentation (before </BODY>!).
    -xl <path>,<url>: used to cross linking documentation trees. Requires the root path and the root url of a second tree to cross link separated by a comma (,). Multiple instances are allowed (-xl <path1>,<url1> -xl <path2>,<url2> ...).
    -xltable <file>: refers to a file with a list of cross link definitions. The file must contain one line by cross link definition and the definition is composed of the root path and the root url separated by space(s).
    -webcvs <url>: allows to add cross link to webcvs in the toolbar area of the doc page.
    Note that the relative path of the modules will be appended to this url with modules in the root tree defined as /<module file name>.
    -nosort: disable the automatic sorting of the documented methods in the html page.
    -raw: use this argument to include a 'Raw content' link in the toolbar (to access file raw content in the documentation pages).
    -isa: will activate ISA modules check. When an inherited Perl module is not
    found, a warning will be issued.
XXX
}
